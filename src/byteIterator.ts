import * as vs from 'vscode';

// NOTE: Memory view is readonly, so position logic can be simplified to use constant values
const BYTES_START_INDEX = 10;
const BYTES_END_INDEX = 57;


function isValidByte (byte: string) {
	return /[0-9A-F]{2}/.test(byte);
}

export class ByteIterator {
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
    
    static positionIsByte(position: vs.Position): boolean {
        // The memory view (read only) is of the following format
        // 01234567: 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F   ....õ.....
        // We exclude the first line, as it is just "Offset: 00 ..."
        return position.line > 0 && BYTES_START_INDEX <= position.character && position.character <= BYTES_END_INDEX;
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