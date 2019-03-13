import * as vs from 'vscode';
import { identifyWideInstruction } from "./disassembly/wide";
import { identifyNarrowInstruction } from "./disassembly/narrow";
import { INSTRUCTION } from "./disassembly/instructions";

// NOTE: Memory view is readonly, so position logic can be simplified to use constant values
const EXPECTED_MIN_LINE_LENGTH = 58; // last line may have fewer bytes, so the ASCII stops sooner
const BYTES_START_INDEX = 10;
const BYTES_END_INDEX = 57;

class ByteIterator {
	index: number; // always aligns with the start of a byte
	line: number;
	lineText: string;
	document: vs.TextDocument;

	readonly startIndex: number;
	readonly startLine: number;
	readonly lastLine: number;

	constructor (position: vs.Position, lineText: string, document: vs.TextDocument) {
		const startIndex = position.character - ((position.character + 2) % 3); // aligns us with the start of a byte

		this.index = startIndex;
		this.line = position.line;
		this.lineText = lineText;
		this.document = document;

		this.startIndex = this.index;
		this.startLine = this.line;
		this.lastLine = this.document.lineCount - 2; // very last line is empty (trailing newline)
	}

	getNextByte (): string {
		let byte;
		if (this.index === BYTES_END_INDEX + 1) {
			if (this.line === this.lastLine) { return ""; }
			this.lineText = this.document.lineAt(++this.line).text;
			this.index = 13;
			return this.lineText.slice(10, 12);
		} else {
			byte = this.lineText.slice(this.index, this.index + 2);
			this.index += 3;
		}

		if (this.line === this.lastLine && !isValidByte(byte)) {
			// backtrack so the range is normal
			if (this.index === 13) {
				this.line--;
				this.index = BYTES_END_INDEX + 1;
			} else {
				this.index -= 3;
			}
			return "";	
		}
	
		return byte;
	}

	getNextHword (): string {
		const byte1 = this.getNextByte();
		const byte2 = this.getNextByte();
		return byte2 + byte1; // account for little endian
	}

	getRange (): vs.Range {
		return new vs.Range(this.startLine, this.startIndex, this.line, this.index - 1);
	}

	getAddressOffset (): string {
		return ((this.index - 10) / 3).toString(16).toUpperCase();
	}
}

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

function positionIsByte(position: vs.Position): boolean {
	// The memory view (read only) is of the following format
	// 01234567: 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F   ....õ.....
	// We exclude the first line, as it is just "Offset: 00 ..."
	return position.line > 0 && BYTES_START_INDEX <= position.character && position.character <= BYTES_END_INDEX;
}

function isValidByte (byte: string) {
	return /[0-9A-F]{2}/.test(byte);
}

function isValidHword (byte: string) {
	return /[0-9A-F]{4}/.test(byte);
}

function lineIndexToAddressIndex (alignedIndex: number): string {
	return ((alignedIndex - 10) / 3).toString(16).toUpperCase();
}

function getHoverContext(position: vs.Position, document: vs.TextDocument): HoverInfo | null {
	if (!positionIsByte(position)) { return null; }

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
			let type: string = "";

			switch (context.type) {
				case Type.HWORD: type = INSTRUCTION[identifyNarrowInstruction(context.bits)]; break;
				case Type.WORD: type = INSTRUCTION[identifyWideInstruction(context.bits)]; break;
				case Type.CUTOFF_WORD: type = "[cutoff word]"; break;
				case Type.CUTOFF_HWORD: type = "[cutoff hword]"; break;
			}

			msg += `${type}\n\n0b${context.bits.toString(2).padStart(16, '0')}\n\n0x${context.bits.toString(16).toUpperCase().padStart(4, '0')}`;
			return new vs.Hover(msg, context.range);
		}
	});
}

export function deactivate() { }
