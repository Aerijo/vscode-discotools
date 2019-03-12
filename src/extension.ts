import * as vscode from 'vscode';
import { identifyWideInstruction } from "./disassembly/wide";
import { identifyNarrowInstruction } from "./disassembly/narrow";
import { INSTRUCTION } from "./disassembly/instructions";

export function isWideInstruction (halfWord: number) {
	return (halfWord & 0xE000) === 0xE000 && (halfWord & 0x1800) > 0; // first 3 bits are high && 4th or 5th is high
}

function getBitsAndRangeForPosition (position: vscode.Position, line: string): [number, number, number, boolean] | null {

	const characterLeftOfIndex = (i: number) => i === 0 ? line.charAt(0) : line.charAt(i - 1);
	const characterRightOfIndex = (i: number) => line.charAt(i);

	{
		const match = /^\s*(?:(.*?):)?\s*((?:[0-9A-F]{2}\s?)*)/.exec(line)!;
		if (match[0].length < position.character) { return null; } // we are past the end, into the ASCII view
		if (match[1] && /[^0-9A-F]/i.test(match[1])) { return null; } // is not an address; likely Offset
		if (match[1] && match[1].length >= position.character) { return null; } // in the address
	}

	let byte: string = "";
	let startIndex;
	let width = 2;

	const leftChar = characterLeftOfIndex(position.character);
	const rightChar = characterRightOfIndex(position.character);

	if (leftChar === " ") {
		byte = line.substring(position.character, position.character + 2);
		startIndex = position.character;
	} else if (rightChar === " ") {
		if (position.character <= 1) { return null; }
		byte = line.substring(position.character - 2, position.character);
		startIndex = position.character - 2;
	} else {
		if (position.character === 0) { return null; }
		byte = line.substring(position.character - 1, position.character + 1);
		startIndex = position.character - 1;
	}

	if (/[^0-9A-F]/.test(byte)) { return null; }

	let bits: number;
	{
		const match = line.slice(startIndex).match(/([0-9A-F]{2})\s*([0-9A-F]{2})/);
		if (!match) { return null; }
		bits = parseInt(match[2] + match[1], 16); // swap for little endian
		width = match[0].length;
	}

	let wide = false;
	if (isWideInstruction(bits)) {
		wide = true;
		{
			const match = line.slice(startIndex + width).match(/\s*([0-9A-F]{2})\s*([0-9A-F]{2})/);
			if (!match) { return null; }
			bits = bits * (2 **16) + parseInt(match[2] + match[1], 16); // swap for little endian
			width += match[0].length;
		}
	}

	return [startIndex, startIndex + width, bits, wide];
}


export function activate (context: vscode.ExtensionContext) {
	vscode.languages.registerHoverProvider("cortex-debug.memoryview", {
		provideHover (document: vscode.TextDocument, position: vscode.Position): vscode.ProviderResult<vscode.Hover> {
			const line = document.lineAt(position);
			const bytes = getBitsAndRangeForPosition(position, line.text);
			if (bytes === null) { return null; }
			let type: string;
			if (bytes[3]) {
				type = INSTRUCTION[identifyWideInstruction(bytes[2])];
			} else {
				type = INSTRUCTION[identifyNarrowInstruction(bytes[2])];
			}

			const msg = `${type}\n\n0b${bytes[2].toString(2).padStart(16, '0')}\n\n0x${bytes[2].toString(16).toUpperCase().padStart(4, '0')}`;
			return new vscode.Hover(msg, new vscode.Range(
				new vscode.Position(position.line, bytes[0]), 
				new vscode.Position(position.line, bytes[1])
			));
		}
	});
}

export function deactivate () {}
