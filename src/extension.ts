import * as vs from 'vscode';
import { identifyWideInstruction } from "./disassembly/wide";
import { identifyNarrowInstruction } from "./disassembly/narrow";
import { INSTRUCTION } from "./disassembly/instructions";


// NOTE: Memory view is readonly, so position logic can be simplified to use constant values

const characterLeftOfIndex = (i: number, line: string) => i === 0 ? line.charAt(0) : line.charAt(i - 1);
const characterRightOfIndex = (i: number, line: string) => line.charAt(i);

export function isWideInstruction (halfWord: number) {
	return (halfWord & 0xE000) === 0xE000 && (halfWord & 0x1800) > 0; // first 3 bits are high && 4th or 5th is high
}

function getByteAndStartIndex (line: string, index: number): [string, number] | null {
	let byte: string;
	let startIndex: number;

	const leftChar = characterLeftOfIndex(index, line);
	const rightChar = characterRightOfIndex(index, line);

	if (leftChar === " ") { // " |ab "
		byte = line.substring(index, index + 2);
		startIndex = index;
	} else if (rightChar === " ") { // " ab| "
		if (index <= 1) { return null; }
		byte = line.substring(index - 2, index);
		startIndex = index - 2;
	} else { // " a|b "
		if (index === 0) { return null; }
		byte = line.substring(index - 1, index + 1);
		startIndex = index - 1;
	}
	if (/[^0-9A-F]/.test(byte)) { return null; }

	return [byte, startIndex];
}

enum Type {
	HWORD,
	WORD,
	CUTOFF_WORD,
}

type HoverInfo = {
	type: Type;
	range: vs.Range;
	bits: number;
};

function positionIsValidByte (line: string, index: number): boolean {
	const match = /^\s*(?:(.*?):)?\s*((?:[0-9A-F]{2}\s*)*)/.exec(line)!;
	return !(
		(match[0].length < index) || // we are past the end, into the ASCII view
		(match[1] && /[^0-9A-F]/i.test(match[1])) || // is not an address; likely Offset
		(match[1] && match[1].length >= index) // in the address
	);
}

function getFirstHWordOnLine (line: string): string | null {
	const match = /^\s*(?:.*?:)?\s*([0-9A-F]{2})\s*([0-9A-F]{2})/.exec(line);
	return match ? match[2] + match[1] : null;
}

function getHoverContext (position: vs.Position, document: vs.TextDocument): HoverInfo | null {
	const line = document.lineAt(position).text;

	if (!positionIsValidByte(line, position.character)) { return null; }

	const positionContext = getByteAndStartIndex(line, position.character);
	if (positionContext === null) { return null; }

	const [byteString, startIndex] = positionContext;

	let width = 2;
	let bits: number;

	{ // get the second half of this hword
		const match = line.slice(startIndex + 2).match(/\s*([0-9A-F]{2})/);
		if (!match) { return null; } // don't bother trying on unaligned hwords
		bits = parseInt(match[1] + byteString, 16);
		width += match[0].length;
	}

	let range = new vs.Range(position.line, startIndex, position.line, startIndex + width);

	let wide = false;
	if (isWideInstruction(bits)) {
		wide = true;
		{
			const match = line.slice(startIndex + width).match(/\s*([0-9A-F]{2})\s*([0-9A-F]{2})/);
			if (match) {
				bits = bits * (2 ** 16) + parseInt(match[2] + match[1], 16);
				range = range.with(undefined, range.end.translate(0, match[0].length));
			} else {
				if (position.line === document.lineCount) { return { bits, type: Type.CUTOFF_WORD, range }; }
				const nextLine = document.lineAt(position.line + 1).text;
				const hword = getFirstHWordOnLine(nextLine);
				if (hword === null) { return { bits, type: Type.CUTOFF_WORD, range }; }
				bits = bits * (2 ** 16) + parseInt(hword, 16);
			}
		}
	}

	return {
		type: wide ? Type.WORD : Type.HWORD,
		bits,
		range,
	};
}


export function activate (context: vs.ExtensionContext) {
	vs.languages.registerHoverProvider("cortex-debug.memoryview", {
		provideHover (document: vs.TextDocument, position: vs.Position): vs.ProviderResult<vs.Hover> {
			
			const context = getHoverContext(position, document);
			if (context === null) { return null; }
			let type: string = "";

			switch (context.type) {
				case Type.HWORD: type = INSTRUCTION[identifyNarrowInstruction(context.bits)]; break;
				case Type.WORD: type = INSTRUCTION[identifyWideInstruction(context.bits)]; break;
				case Type.CUTOFF_WORD: type = "[cutoff word]"; break;
			}

			const msg = `${type}\n\n0b${context.bits.toString(2).padStart(16, '0')}\n\n0x${context.bits.toString(16).toUpperCase().padStart(4, '0')}`;
			return new vs.Hover(msg, context.range);
		}
	});
}

export function deactivate () {}
