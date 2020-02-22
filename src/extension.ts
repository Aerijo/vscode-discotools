import * as vs from "vscode";
import { ByteIterator } from "./byteIterator";
import * as dd from "disco-disassembler";
import { Encoding } from "disco-disassembler/dist/src/instructions/encodings";

import * as cp from "child_process";

const EXPECTED_MIN_LINE_LENGTH = 58; // last line may have fewer bytes, so the ASCII stops sooner

export function isStartWideInstruction(hword: number) {
	return (hword & 0xE000) === 0xE000 && (hword & 0x1800) > 0; // first 3 bits are high && 4th or 5th is high
}

enum Type {
	HWORD,
	WORD,
	CUTOFF_WORD,
	CUTOFF_HWORD,
}


type HoverInfo = {
	type: Type;
	range: vs.Range;
	bits: number;
	startAddress: string;
};


function isValidHword (byte: string) {
	return /[0-9A-F]{4}/.test(byte);
}


function getHoverContext(position: vs.Position, document: vs.TextDocument): HoverInfo | null {
	if (!ByteIterator.positionIsByte(position)) { return null; }

	const lineText = document.lineAt(position).text;
	if (lineText.length < EXPECTED_MIN_LINE_LENGTH) { return null; }

	const iterator = new ByteIterator(position, lineText, document);

	const lineMemoryAddress = lineText.slice(0, 7);	// cuts off last '0'; actual line index added in next step
	const startAddress = lineMemoryAddress + iterator.getAddressOffset();

	const hword1 = iterator.getNextHword();
	if (hword1.length === 0 || hword1.length === 2) {
		return { type: Type.CUTOFF_HWORD, range: iterator.getRange(), bits: parseInt(hword1, 16), startAddress };
	}
	if (!isValidHword(hword1)) { return null; }

	let instruction = hword1;
	let wide = false;
	if (isStartWideInstruction(parseInt(hword1, 16))) {
		wide = true;
		const hword2 = iterator.getNextHword();
		instruction += hword2;
		if (!isValidHword(hword2)) { return { type: Type.CUTOFF_WORD, range: iterator.getRange(), bits: parseInt(instruction, 16), startAddress }; }
	}

	return {
		type: wide ? Type.WORD : Type.HWORD,
		bits: parseInt(instruction, 16),
		range: iterator.getRange(),
		startAddress: lineMemoryAddress
	};
}


export function activate(context: vs.ExtensionContext) {
	const hoverProvider = {
		provideHover(document: vs.TextDocument, position: vs.Position): vs.ProviderResult<vs.Hover> {
			const context = getHoverContext(position, document);
			if (context === null) { return null; }

			let msg = ""; // TODO: Allow user provided templates for value (like snippet variables)
			let displayName: string = "";

			let encoding: Encoding | undefined;

			switch (context.type) {
				case Type.HWORD: 
				case Type.WORD:
					encoding = dd.bitsToEncoding(context.bits);
					displayName = encoding.getDisplayName();
					break;
				case Type.CUTOFF_WORD: displayName = "[cutoff word]"; break;
				case Type.CUTOFF_HWORD: displayName = "[cutoff hword]"; break;
			}

			if (!encoding) {
				return new vs.Hover(displayName, context.range);
			}

			if (encoding.invalid) {
				return new vs.Hover(encoding.name, context.range);
			}

			const config = vs.workspace.getConfiguration("discotools");

			msg += displayName;
			
			if (config.get("pdfViewer") !== "none") {
				msg += ` [[p${encoding.page}](command:discotools.openManualPage?${encoding.page})]`;
			} else {
				msg += ` [p${encoding.page}]`;
			}
			
			if (config.get("showBinaryAndHexValues")) {
				msg += `\n\n0b${context.bits.toString(2)}\n\n0x${context.bits.toString(16).toUpperCase()}`;
			}
			
			if (config.get("showVariables")) {
				const vars = encoding.extractVariableValues(context.bits);
				msg += "\n\n";
				for (const [name, resolved] of Object.entries(vars)) {
					msg += `${name}=${resolved.value}, `;
				}
				msg = msg.substring(0, msg.length - 2);
			}
			
			const markedString = new vs.MarkdownString(msg);
			markedString.isTrusted = true;

			return new vs.Hover(markedString, context.range);
		}
	};

	vs.languages.registerHoverProvider("platformio-debug.memoryview", hoverProvider);
	vs.languages.registerHoverProvider("cortex-debug.memoryview", hoverProvider);

	vs.commands.registerCommand("discotools.openManualPage", (page: number | undefined) => {
		if (page === undefined) {
			vs.window.showInformationMessage(`No page to open`);
			return;
		}

		const config = vs.workspace.getConfiguration("discotools");

		const manPath: string | null = config.get("armManualAbsolutePath", null);
		const viewer: string | null = config.get("pdfViewer", null);

		if (viewer === null || manPath === null) {
			vs.window.showInformationMessage(`Cannot open ${manPath} in ${viewer}`);
			return;
		}

		let cmd: string;
		switch (viewer) {
			case "okular": cmd = `${viewer} "${manPath}" -p ${page} --unique`; break;
			case "evince": cmd = `${viewer} "${manPath}" -i ${page}`; break;
			default: return;	
		}

		cp.exec(cmd);
	});

	vs.commands.registerCommand("discotools.logEncodingDetails", (bits: number) => {
		vs.window.showInformationMessage(`0b${bits.toString(2)}\n\n\n\n0x${bits.toString(16)}`);
	});

	vs.commands.registerTextEditorCommand("discotools.toggleDocComment", (editor: vs.TextEditor, edit: vs.TextEditorEdit) => {
		const selection = editor.selection;
		const document = editor.document;

		const activeLine = selection.active.line;
		const startLine = document.lineAt(activeLine).text;
		const inlineMatch = /(\s*)(?:@|\/\/)/.exec(startLine);
		if (inlineMatch) {
			const indent = inlineMatch[1];
			// @ lines -> /** */
			let multiline = false;
			if (activeLine > 0 && /\s*(@|\/\/)/.test(document.lineAt(activeLine - 1).text)) {
				multiline = true;
			} else if (activeLine < document.lineCount - 1 && /\s*(@|\/\/)/.test(document.lineAt(activeLine + 1).text)) {
				multiline = true;
			}
			makeDocComment(edit, document, selection, multiline, indent);
		} else if (/\s*\*/.test(startLine)) {
			// /** */ -> @ lines (TODO)
		} else {
			// No comment -> /** */ on selected lines (TODO)
		}
	});
}


function makeDocComment(edit: vs.TextEditorEdit, document: vs.TextDocument, selection: vs.Selection, multiline: boolean, indent: string): void {
	if (!multiline) {
		const i = selection.active.line;
		const line = document.lineAt(i).text;
		const match = /(\s*)(?:@|\/\/)/.exec(line);
		if (!match) { return; }
		const replacement = indent + "/**"; 
		edit.replace(new vs.Range(i, 0, i, match[0].length), replacement);
		edit.insert(new vs.Position(i, line.length), " */");
		return;
	}

	let setStart = false;
	let setEnd = false;

	for (let i = selection.start.line; i > 0; i--) {
		const line = document.lineAt(i).text;
		const match = /\s*(?:@|\/\/)/.exec(line);
		if (!match) {
			edit.insert(new vs.Position(i, line.length), "\n" + indent + "/**"); // TODO: Indent with rest of code
			setStart = true;
			break;
		}
		edit.replace(new vs.Range(i, 0, i, match[0].length), indent + " *");
	}

	if (!setStart) {
		edit.insert(new vs.Position(0, 0), indent + "/**\n");
	}

	for (let i = selection.start.line + 1; i < document.lineCount; i++) {
		const line = document.lineAt(i).text;
		const match = /\s*(?:@|\/\/)/.exec(line);
		if (!match) { 
			edit.insert(new vs.Position(i, 0), indent + " */\n");
			setEnd = true;
			break;
		}
		edit.replace(new vs.Range(i, 0, i, match[0].length), indent + " *");
	}

	if (!setEnd) {
		edit.insert(new vs.Position(document.lineCount, 0), "\n" + indent + " */");
	}
}


export function deactivate() { }
