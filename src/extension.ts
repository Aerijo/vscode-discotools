import * as vs from "vscode";
import { ByteIterator } from "./byteIterator";
import * as dd from "disco-disassembler";
import { Encoding } from "disco-disassembler/dist/src/instructions/encodings";

import * as cp from "child_process";
import { print } from "util";

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

function lineIndexToAddressIndex (alignedIndex: number): string {
	return ((alignedIndex - 10) / 3).toString(16).toUpperCase();
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
	vs.languages.registerHoverProvider("cortex-debug.memoryview", {
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
	});

	// vs.languages.registerDefinitionProvider("arm", {
	// 	provideDefinition(document, position, token) {

	// 		const range = document.getWordRangeAtPosition(position);

	// 		console.log(range);

	// 		const word = document.getText(range);

	// 		console.log(word);
			
	// 		const uri = vs.Uri.parse("file:///home/benjamin/university/2019-S1/2300/ARMv7-M-architecture-reference-manual.pdf");
	// 		return new vs.Location(uri, new vs.Position(0,0));
	// 	}
	// });

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
}

export function deactivate() { }
