/*
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License

	No warranty of merchantability or fitness of any kind.
	Use this software at your own risk.
 */

package moonshine.editor.text.utils;

import openfl.errors.ArgumentError;

/**
	Utility functions for manipulating text in a code editor.
**/
class TextUtil {
	private static final DEFAULT_NON_WORD_CHARACTERS:Array<String> = [
		" ", "\t", ".", ":", ";", ",", "?", "+", "-", "*", "/", "%", "=", "!", "&", "|", "(", ")", "[", "]", "{", "}", "<", ">"
	];

	/**
		Determines if a character is a word character or not.
	**/
	public static function isWordCharacter(char:String, ?nonWordCharacters:Array<String>):Bool {
		if (char.length != 1) {
			throw new ArgumentError("Length of character must be 1");
		}
		if (nonWordCharacters == null) {
			nonWordCharacters = DEFAULT_NON_WORD_CHARACTERS;
		}
		return nonWordCharacters.indexOf(char) == -1;
	}

	/**
		Returns the character index of the beginning of the current word
		(inclusive).
	**/
	public static function startOfWord(line:String, charIndex:Int, ?nonWordCharacters:Array<String>):Int {
		if (nonWordCharacters == null) {
			nonWordCharacters = DEFAULT_NON_WORD_CHARACTERS;
		}
		var i = charIndex;
		while (i >= 0) {
			var char = line.charAt(i);
			if (nonWordCharacters.indexOf(char) != -1) {
				if (i == charIndex) {
					// if the first character that we check is not a word
					// character, include it as part of the word
					return i;
				}
				// otherwise, the previous valid character is the start
				return i + 1;
			}
			i--;
		}
		return 0;
	}

	/**
		Returns the character index of the end of the current word (exclusive).
	**/
	public static function endOfWord(line:String, charIndex:Int, ?nonWordCharacters:Array<String>):Int {
		if (nonWordCharacters == null) {
			nonWordCharacters = DEFAULT_NON_WORD_CHARACTERS;
		}
		for (i in charIndex...line.length) {
			var char = line.charAt(i);
			if (nonWordCharacters.indexOf(char) != -1) {
				if (i == charIndex) {
					// if the first character that we check is not a word
					// character, return the next character so that the length
					// of the word is at least 1
					return i + 1;
				}
				// otherwise, this character is the end of the word
				return i;
			}
		}
		return line.length;
	}

	/**
		Finds a word boundary from the beginning of a line.
	**/
	public static function wordBoundaryForward(line:String):Int {
		return line.length - ~/^(?:\s+|[^\s,(){}\[\]\-+*%\/="'~!&|<>?:;.]+\s*|[,(){}\[\]\-+*%\/="'~!&|<>?:;.]+\s*)/.replace(line, "").length;
	}

	/**
		Finds a word boundary from the end of a line.
	**/
	public static function wordBoundaryBackward(line:String):Int {
		return line.length - ~/(?:\s+|[^\s,(){}\[\]\-+*%\/="'~!&|<>?:;.]+\s*|[,(){}\[\]\-+*%\/="'~!&|<>?:;.]+\s*)$/.replace(line, "").length;
	}

	/**
		Determines the amount of tabs at the start of a line.
	**/
	public static function indentAmount(line:String):Int {
		var indent = line.length - ~/^\t+/.replace(line, "").length;
		if (indent > 0) {
			return indent;
		}
		return 0;
	}

	/**
		Determines the amount of indentation combining space and tabs on a line.
	**/
	public static function indentAmountBySpaceAndTab(line:String):Dynamic {
		var tmpLine = ~/^(\s+).*$/.replace(line, "$1");
		var num_spaces = tmpLine.length - ~/[ ]/g.replace(tmpLine, "").length;
		var num_tabs = tmpLine.length - ~/\t/g.replace(tmpLine, "").length;

		return {space: num_spaces, tab: num_tabs};
	}

	/**
		Repeats a string N times.
	**/
	public static function repeatStr(str:String, count:UInt):String {
		var array = [];
		array.resize(count + 1);
		return array.join(str);
	}

	/**
		Return line and character index from absolute character index.
	**/
	public static function charIdx2LineCharIdx(str:String, charIdx:Int, lineDelim:String):TextEditorPosition {
		var line = str.substr(0, charIdx).split(lineDelim).length - 1;
		var chr = line > 0 ? charIdx - str.lastIndexOf(lineDelim, charIdx - 1) - lineDelim.length : charIdx;
		return new TextEditorPosition(line, chr);
	}

	/**
		Return absolute character index from line and character index.
	**/
	public static function lineCharIdx2charIdx(str:String, lineIdx:Int, charIdx:Int, lineDelim:String):Int {
		return (str.split(lineDelim).slice(0, lineIdx).join("").length // Predecing lines' lengths
			+ lineIdx * lineDelim.length // Preceding delimiters' lengths
			+ charIdx // Current line's length
		);
	}

	/**
		Return the first indent (either a tab or a set of spaces with the
		specified tab size) at the start of a line.
	**/
	public static function getFirstIndentAtStartOfLine(line:String, tabSize:Int):String {
		var firstChar = line.charAt(0);
		if (firstChar == "\t") {
			return firstChar;
		}
		if (firstChar == " ") {
			var indent = firstChar;
			for (i in 1...tabSize) {
				var char = line.charAt(i);
				if (char != " ") {
					return "";
				}
				indent += char;
			}
			return indent;
		}
		return "";
	}

	/**
		Gets the full set of whitespace at the start of a line.
	**/
	public static function getIndentAtStartOfLine(line:String, tabSize:Int):String {
		var indentPattern = ~/^[ \t]+/;
		if (indentPattern.match(line)) {
			return indentPattern.matched(0);
		}
		return "";
	}
}
