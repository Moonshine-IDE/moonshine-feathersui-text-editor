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

package moonshine.editor.text.managers;

import haxe.ds.ArraySort;
import moonshine.editor.text.changes.TextEditorChange;
import moonshine.editor.text.events.TextEditorChangeEvent;
import moonshine.editor.text.events.TextEditorEvent;
import moonshine.editor.text.lines.TextLineModel;
import moonshine.editor.text.utils.AutoClosingPair;
import moonshine.editor.text.utils.TextEditorUtil;
import moonshine.editor.text.utils.TextUtil;
import openfl.errors.ArgumentError;
import openfl.errors.RangeError;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.TextEvent;
import openfl.ui.Keyboard;

/**
	Used internally by `TextEditor` to manage text edits.
**/
class EditManager {
	/**
		Creates a new `EditManager` object.
	**/
	public function new(textEditor:TextEditor) {
		_textEditor = textEditor;
		_textEditor.addEventListener(KeyboardEvent.KEY_DOWN, editManager_textEditor_keyDownHandler, false, 0, true);
		_textEditor.addEventListener(TextEvent.TEXT_INPUT, editManager_textEditor_textInputHandler, false, 0, true);
		_textEditor.addEventListener(TextEditorChangeEvent.TEXT_CHANGE, editManager_textEditor_textChangePriorityHandler, false, 100, true);
		_textEditor.addEventListener(TextEditorChangeEvent.TEXT_CHANGE, editManager_textEditor_textChangeHandler, false, 0, true);
		_textEditor.addEventListener(TextEditorEvent.SELECTION_CHANGE, editManager_textEditor_selectionChangeHandler, false, 0, true);
		_textEditor.addEventListener(Event.CLEAR, editManager_textEditor_clearHandler, false, 0, true);
	}

	private var _textEditor:TextEditor;
	private var _activeAutoClosingPair:AutoClosingPair;
	private var _activeAutoClosingPairLineIndex:Int = -1;
	private var _activeAutoClosingPairStartCharIndex:Int = -1;
	private var _activeAutoClosingPairEndCharIndex:Int = -1;

	/**
		Toggles a line comment at the current caret position.
	**/
	public function toggleLineComment():Void {
		var lineComment = _textEditor.lineComment;
		if (lineComment == null || lineComment.length == 0) {
			return;
		}

		var startLine = _textEditor.caretLineIndex;
		var endLine = startLine;
		if (_textEditor.selectionStartLineIndex != _textEditor.selectionEndLineIndex) {
			startLine = _textEditor.selectionStartLineIndex;
			endLine = _textEditor.selectionEndLineIndex;
		}
		if (endLine < startLine) {
			var temp = startLine;
			startLine = endLine;
			endLine = temp;
		}

		var removeComment = true;
		var startsWithComment = new EReg('^\\s*${EReg.escape(lineComment)}', "");
		for (i in startLine...(endLine + 1)) {
			var lineText = _textEditor.lines.get(i).text;
			if (!startsWithComment.match(lineText)) {
				removeComment = false;
			}
		}

		var newSelectionStartLineIndex = _textEditor.selectionStartLineIndex;
		var newSelectionStartCharIndex = _textEditor.selectionStartCharIndex;
		var newSelectionEndLineIndex = _textEditor.selectionEndLineIndex;
		var newSelectionEndCharIndex = _textEditor.selectionEndCharIndex;
		if (newSelectionStartCharIndex == -1) {
			newSelectionStartLineIndex = _textEditor.caretLineIndex;
			newSelectionStartCharIndex = _textEditor.caretCharIndex;
			newSelectionEndLineIndex = newSelectionStartLineIndex;
			newSelectionEndCharIndex = newSelectionStartCharIndex;
		}
		var changes:Array<TextEditorChange> = [];
		for (i in startLine...(endLine + 1)) {
			var startingWhitespace = ~/^\s*/;
			var lineText = _textEditor.lines.get(i).text;
			if (!startingWhitespace.match(lineText)) {
				continue;
			}
			var whitespaceSize = startingWhitespace.matched(0).length;
			if (removeComment) {
				var commentSize = lineComment.length;
				if (lineText.charAt(whitespaceSize + commentSize) == " ") {
					commentSize++;
				}
				changes.push(new TextEditorChange(i, whitespaceSize, i, whitespaceSize + commentSize));
				if (i == newSelectionStartLineIndex) {
					newSelectionStartCharIndex -= commentSize;
				}
				if (i == newSelectionEndLineIndex) {
					newSelectionEndCharIndex -= commentSize;
				}
			} else {
				changes.push(new TextEditorChange(i, whitespaceSize, i, whitespaceSize, lineComment + " "));
				var commentSize = lineComment.length + 1;
				if (i == newSelectionStartLineIndex) {
					newSelectionStartCharIndex += commentSize;
				}
				if (i == newSelectionEndLineIndex) {
					newSelectionEndCharIndex += commentSize;
				}
			}
		}
		dispatchChanges(changes);
		_textEditor.setSelection(newSelectionStartLineIndex, newSelectionStartCharIndex, newSelectionEndLineIndex, newSelectionEndCharIndex);
	}

	/**
		Toggles a block comment at the current caret position.
	**/
	public function toggleBlockComment():Void {
		var blockComment = _textEditor.blockComment;
		if (blockComment == null || blockComment.length < 2) {
			return;
		}

		var startLine = _textEditor.caretLineIndex;
		var startChar = _textEditor.caretCharIndex;
		var endLine = startLine;
		var endChar = startChar;
		if (_textEditor.selectionStartLineIndex != _textEditor.selectionEndLineIndex
			|| _textEditor.selectionStartCharIndex != _textEditor.selectionEndCharIndex) {
			startLine = _textEditor.selectionStartLineIndex;
			startChar = _textEditor.selectionStartCharIndex;
			endLine = _textEditor.selectionEndLineIndex;
			endChar = _textEditor.selectionEndCharIndex;
		}
		if (endLine < startLine) {
			var temp = startLine;
			startLine = endLine;
			endLine = temp;
			temp = startChar;
			startChar = endChar;
			endChar = temp;
		}

		var blockStart = blockComment[0];
		var blockEnd = blockComment[1];

		var removeStartChar = -1;
		var removeEndChar = -1;
		var startLineText = _textEditor.lines.get(startLine).text;
		var endLineText = _textEditor.lines.get(endLine).text;
		var startIndex = startLineText.lastIndexOf(blockStart, startChar);
		if (startIndex != -1) {
			var endIndex = endLineText.indexOf(blockEnd, endChar);
			if (endIndex != -1) {
				removeStartChar = startIndex;
				removeEndChar = endIndex + blockEnd.length;
			}
		}

		var newSelectionStartChar = startChar;
		var newSelectionEndChar = endChar;
		var changes:Array<TextEditorChange> = [];
		if (removeStartChar != -1 && removeEndChar != -1) {
			var endCommentSize = blockEnd.length;
			if (endLineText.charAt(removeEndChar - blockEnd.length - 1) == " ") {
				endCommentSize++;
			}
			changes.push(new TextEditorChange(endLine, removeEndChar - endCommentSize, endLine, removeEndChar));
			var startCommentSize = blockStart.length;
			if (startLineText.charAt(removeStartChar + blockEnd.length) == " ") {
				startCommentSize++;
			}
			changes.push(new TextEditorChange(startLine, removeStartChar, startLine, removeStartChar + startCommentSize));
			newSelectionStartChar -= startCommentSize;
			if (startLine == endLine) {
				newSelectionEndChar -= startCommentSize;
			}
		} else {
			newSelectionStartChar += blockStart.length + 1;
			newSelectionEndChar += blockStart.length + 1;
			if (startLine == endLine && startChar == endChar) {
				changes.push(new TextEditorChange(startLine, startChar, startLine, startChar, blockStart + "  " + blockEnd));
			} else {
				changes.push(new TextEditorChange(endLine, endChar, endLine, endChar, " " + blockEnd));
				changes.push(new TextEditorChange(startLine, startChar, startLine, startChar, blockStart + " "));
			}
		}
		dispatchChanges(changes);
		_textEditor.setSelection(startLine, newSelectionStartChar, endLine, newSelectionEndChar);
	}

	private function indent(reverse:Bool):Void {
		if (_textEditor.selectionStartLineIndex != _textEditor.selectionEndLineIndex) {
			var changes:Array<TextEditorChange> = [];
			var startLine:Int;
			var endLine:Int;
			var startChar:Int;
			var endChar:Int;

			if (_textEditor.selectionStartLineIndex < _textEditor.caretLineIndex) {
				startLine = _textEditor.selectionStartLineIndex;
				endLine = _textEditor.caretLineIndex;
				startChar = _textEditor.selectionStartCharIndex;
				endChar = _textEditor.caretCharIndex;
			} else {
				startLine = _textEditor.caretLineIndex;
				endLine = _textEditor.selectionStartLineIndex;
				startChar = _textEditor.caretCharIndex;
				endChar = _textEditor.selectionStartCharIndex;
			}

			if (startChar == _textEditor.lines.get(startLine).text.length) {
				startLine++;
			}
			if (endChar == 0) {
				endLine--;
			}

			var newSelectedStartCharIndex = startChar;
			var newSelectedEndCharIndex = endChar;
			var line = startLine;
			while (line <= endLine) {
				if (reverse) {
					var currentIndent = TextUtil.getIndentAtStartOfLine(_textEditor.lines.get(line).text, _textEditor.tabWidth);
					var currentIndentSize = getIndentCountAtStartOfLine(currentIndent, _textEditor.tabWidth);
					var newIndentSize = Math.floor(currentIndentSize);
					if (newIndentSize == currentIndentSize) {
						newIndentSize--;
					}
					if (currentIndentSize > 0) {
						// the current indent may be a mix of spaces and tabs
						// we convert the current indent to all spaces or all tabs
						var indentString = getIndentString();
						var newIndent = "";
						for (i in 0...newIndentSize) {
							newIndent += indentString;
						}
						changes.push(new TextEditorChange(line, 0, line, currentIndent.length, newIndent));
						if (line == startLine) {
							newSelectedStartCharIndex -= currentIndent.length;
							if (newSelectedStartCharIndex < 0) {
								newSelectedStartCharIndex = 0;
							}
							newSelectedStartCharIndex += newIndent.length;
						}
						if (line == endLine) {
							newSelectedEndCharIndex -= currentIndent.length;
							if (newSelectedEndCharIndex < 0) {
								newSelectedEndCharIndex = 0;
							}
							newSelectedEndCharIndex += newIndent.length;
						}
					}
				} else {
					var currentIndent = TextUtil.getIndentAtStartOfLine(_textEditor.lines.get(line).text, _textEditor.tabWidth);
					var currentIndentSize = getIndentCountAtStartOfLine(currentIndent, _textEditor.tabWidth);
					var newIndentSize = Math.ceil(currentIndentSize);
					if (newIndentSize == currentIndentSize) {
						newIndentSize++;
					}
					// the current indent may be a mix of spaces and tabs
					// we convert the current indent to all spaces or all tabs
					var indentString = getIndentString();
					var newIndent = "";
					for (i in 0...newIndentSize) {
						newIndent += indentString;
					}
					changes.push(new TextEditorChange(line, 0, line, currentIndent.length, newIndent));
					if (line == startLine) {
						newSelectedStartCharIndex -= currentIndent.length;
						if (newSelectedStartCharIndex < 0) {
							newSelectedStartCharIndex = 0;
						}
						newSelectedStartCharIndex += newIndent.length;
					}
					if (line == endLine) {
						newSelectedEndCharIndex -= currentIndent.length;
						if (newSelectedEndCharIndex < 0) {
							newSelectedEndCharIndex = 0;
						}
						newSelectedEndCharIndex += newIndent.length;
					}
				}
				line++;
			}
			if (changes.length > 0) {
				dispatchChanges(changes);
				_textEditor.setSelection(startLine, newSelectedStartCharIndex, endLine, newSelectedEndCharIndex);
			}
		} else if (reverse) {
			var lineIndex = _textEditor.caretLineIndex;
			var newSelectionStartCharIndex = _textEditor.selectionStartCharIndex;
			var newSelectionEndCharIndex = _textEditor.selectionEndCharIndex;
			if (newSelectionStartCharIndex == -1) {
				newSelectionStartCharIndex = _textEditor.caretCharIndex;
				newSelectionEndCharIndex = _textEditor.caretCharIndex;
			}
			var reverseChange = createDecreaseIndentTextEditorChange(lineIndex);
			if (reverseChange != null) {
				var difference = reverseChange.endChar - reverseChange.startChar;
				newSelectionStartCharIndex -= difference;
				newSelectionEndCharIndex -= difference;
				if (newSelectionStartCharIndex < 0) {
					newSelectionStartCharIndex = 0;
				}
				if (newSelectionEndCharIndex < 0) {
					newSelectionEndCharIndex = 0;
				}
				dispatchChanges([reverseChange]);
				_textEditor.setSelection(lineIndex, newSelectionStartCharIndex, lineIndex, newSelectionEndCharIndex);
			}
		} else {
			insertText(getIndentString());
		}
	}

	private function isBetweenBrackets():Bool {
		if (_textEditor.brackets == null) {
			return false;
		}
		var line = _textEditor.lines.get(_textEditor.caretLineIndex);
		var charIndex = _textEditor.caretCharIndex;
		if (charIndex == 0 || charIndex >= line.text.length) {
			return false;
		}
		var prevChar = line.text.charAt(charIndex - 1);
		for (brackets in _textEditor.brackets) {
			if (brackets[0] == prevChar) {
				var nextChar = line.text.charAt(charIndex);
				if (brackets[1] == nextChar) {
					return true;
				}
			}
		}
		return false;
	}

	private function findFullIndentForNewLine(currentLineIndex:Int):String {
		var findFullIndent = ~/^\s*/;
		var i = currentLineIndex;
		while (i >= 0) {
			var line = _textEditor.lines.get(i);
			var lineText = line.text;
			if (!findFullIndent.match(lineText)) {
				// this shouldn't happen, but just in case
				continue;
			}
			var indent = findFullIndent.matched(0);
			// accept 0 indent only if the line contains non-whitepace
			// if it contains only whitespace, keep searching (unless we reached
			// the first line)
			if (StringTools.trim(lineText).length > 0 || i == 0) {
				if (_textEditor.brackets != null) {
					for (brackets in _textEditor.brackets) {
						var open = brackets[0];
						var openIndex = lineText.lastIndexOf(open);
						if (openIndex != -1) {
							var close = brackets[1];
							var closeIndex = lineText.lastIndexOf(close);
							// if the last open bracket appears after the last close
							// bracket (or if there is no close bracket), then
							// automatically increase the indent
							if (closeIndex == -1 || closeIndex < openIndex) {
								indent = indent + getIndentString();
								break;
							}
						}
					}
				}
				return indent;
			}
			i--;
		}
		return "";
	}

	private function getIndentString():String {
		if (_textEditor.insertSpacesForTabs) {
			return TextUtil.repeatStr(" ", _textEditor.tabWidth);
		}
		return "\t";
	}

	private function getIndentCountAtStartOfLine(line:String, tabWidth:Int):Float {
		var indentCount = 0.0;
		var spaceCount = 0;
		for (i in 0...line.length) {
			var char = line.charAt(i);
			if (char == " ") {
				spaceCount++;
				if (spaceCount == tabWidth) {
					indentCount++;
					spaceCount = 0;
				}
			} else if (char == "\t") {
				indentCount++;
			} else {
				break;
			}
		}
		if (spaceCount > 0) {
			indentCount += spaceCount / tabWidth;
		}
		return indentCount;
	}

	private function textEndsInUnterminatedStringOrComment(text:String):Bool {
		var lineComment = _textEditor.lineComment;
		var blockCommentStart = _textEditor.blockComment != null ? _textEditor.blockComment[0] : null;
		var blockCommentEnd = _textEditor.blockComment != null ? _textEditor.blockComment[1] : null;
		var stringTerminators = ["'", "\""];
		var stringStart = null;
		var pendingLineComment:String = "";
		var pendingBlockComment:String = "";
		var i = 0;
		while (i < text.length) {
			var char = text.charAt(i);
			if (stringStart != null) {
				// inside a string
				if (char == stringStart) {
					stringStart = null;
				}
			} else {
				// not inside a string
				if (stringTerminators.contains(char)) {
					stringStart = char;
					pendingLineComment = "";
					pendingBlockComment = "";
				} else {
					if (lineComment != null) {
						var lineCommentChar = lineComment.charAt(pendingLineComment.length);
						if (char == lineCommentChar) {
							pendingLineComment += char;
							if (pendingLineComment == lineComment) {
								// this is a line comment!
								return true;
							}
						} else {
							pendingLineComment = "";
						}
					}
					if (blockCommentStart != null) {
						var blockCommentChar = blockCommentStart.charAt(pendingBlockComment.length);
						if (char == blockCommentChar) {
							pendingBlockComment += char;
							if (pendingBlockComment == blockCommentStart) {
								// this is a block comment!
								var blockCommentEndIndex = text.indexOf(blockCommentEnd, i + blockCommentStart.length);
								if (blockCommentEndIndex == -1) {
									return true;
								}
								i += blockCommentEndIndex + blockCommentEnd.length;
								pendingLineComment = "";
								pendingBlockComment = "";
							}
						} else {
							pendingBlockComment = "";
						}
					}
				}
			}
			i++;
		}
		return stringStart != null;
	}

	private function insertText(text:String):Void {
		if (_textEditor.hasSelection) {
			var change = TextEditorUtil.deleteSelection(_textEditor, text);
			if (change != null) {
				dispatchChanges([change]);
			}
			return;
		}
		if (_textEditor.autoClosingPairs != null) {
			for (autoClosingPair in _textEditor.autoClosingPairs) {
				var lineIndex = _textEditor.caretLineIndex;
				var charIndex = _textEditor.caretCharIndex;
				if (_activeAutoClosingPair != null
					&& charIndex == _activeAutoClosingPairEndCharIndex
					&& _activeAutoClosingPair.open == autoClosingPair.open
					&& autoClosingPair.close == text) {
					var newCaretCharIndex = charIndex + autoClosingPair.open.length;
					_textEditor.setSelection(lineIndex, newCaretCharIndex, lineIndex, newCaretCharIndex);
					return;
				}
				var expandedText = text;
				if (autoClosingPair.open.length > 1) {
					var lineText = _textEditor.caretLine.text;
					var numChars = autoClosingPair.open.length - expandedText.length;
					if (numChars > 0 && charIndex >= numChars) {
						expandedText = lineText.substr(charIndex - numChars, numChars) + expandedText;
					}
				}
				if (autoClosingPair.open == expandedText) {
					var startLineText = _textEditor.caretLine.text.substr(0, charIndex);
					var needsClose = !textEndsInUnterminatedStringOrComment(startLineText);
					if (needsClose) {
						text += autoClosingPair.close;
						dispatchChanges([new TextEditorChange(lineIndex, charIndex, lineIndex, charIndex, text)]);
						var newCaretCharIndex = charIndex + text.length - autoClosingPair.close.length;
						_textEditor.setSelection(lineIndex, newCaretCharIndex, lineIndex, newCaretCharIndex);
						_activeAutoClosingPair = autoClosingPair;
						_activeAutoClosingPairLineIndex = lineIndex;
						_activeAutoClosingPairStartCharIndex = newCaretCharIndex;
						_activeAutoClosingPairEndCharIndex = newCaretCharIndex;
						return;
					}
				}
			}
		}
		var decreaseIndent:TextEditorChange = null;
		if (_textEditor.brackets != null) {
			var trimmed = StringTools.trim(_textEditor.caretLine.text);
			if (trimmed.length == 0) {
				for (brackets in _textEditor.brackets) {
					var close = brackets[1];
					if (text == close) {
						decreaseIndent = createDecreaseIndentTextEditorChange(_textEditor.caretLineIndex);
					}
				}
			}
		}
		if (decreaseIndent != null) {
			if (_textEditor.caretCharIndex == decreaseIndent.endChar) {
				// if possible, merge the two changes into one
				dispatchChanges([
					new TextEditorChange(decreaseIndent.startLine, decreaseIndent.startChar, decreaseIndent.endLine, decreaseIndent.endChar, text)
				]);
				return;
			}
			// otherwise, do two separate changes. this isn't ideal for
			// undo/redo, but we don't really have any choice. this should be
			// relatively rare, though.
			dispatchChanges([decreaseIndent]);
		}
		var line = _textEditor.caretLineIndex;
		var char = _textEditor.caretCharIndex;
		dispatchChanges([new TextEditorChange(line, char, line, char, text)]);
	}

	private function createRemoveAtCursorTextEditorChange(afterCaret:Bool, isWord:Bool):Null<TextEditorChange> {
		if (_textEditor.hasSelection) {
			return TextEditorUtil.deleteSelection(_textEditor);
		}

		var startLine = _textEditor.caretLineIndex;
		var endLine = startLine;
		var startChar = _textEditor.caretCharIndex;
		var endChar = startChar;

		// Backspace remove line & append to line above it
		if (startChar == 0 && !afterCaret) {
			// Can't remove first line with backspace
			if (startLine == 0) {
				return null;
			}

			startLine--;
			startChar = _textEditor.lines.get(startLine).text.length;
			endChar = 0;
		}
		// Delete remove linebreak & append to line below it
		else if (startChar == _textEditor.lines.get(startLine).text.length && afterCaret) {
			if (startLine == _textEditor.lines.length - 1) {
				return null;
			}

			endLine++;
			startChar = _textEditor.lines.get(startLine).text.length;
			endChar = 0;
		} else if (afterCaret) { // Delete
			endChar += isWord ? TextUtil.wordBoundaryForward(_textEditor.lines.get(startLine).text.substring(startChar)) : 1;
		} else { // Backspace
			startChar -= isWord ? TextUtil.wordBoundaryBackward(_textEditor.lines.get(startLine).text.substring(0, endChar)) : 1;
		}

		return new TextEditorChange(startLine, startChar, endLine, endChar);
	}

	private function createDecreaseIndentTextEditorChange(lineIndex:Int):Null<TextEditorChange> {
		var indent = TextUtil.getFirstIndentAtStartOfLine(_textEditor.lines.get(lineIndex).text, _textEditor.tabWidth);
		if (indent.length == 0) {
			return null;
		}
		return new TextEditorChange(lineIndex, 0, lineIndex, indent.length);
	}

	private function dispatchChanges(changes:Array<TextEditorChange>):Void {
		_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, changes));
	}

	private function editManager_textEditor_keyDownHandler(event:KeyboardEvent):Void {
		if (event.isDefaultPrevented()) {
			return;
		}
		switch (event.keyCode) {
			case Keyboard.ENTER:
				var indent = findFullIndentForNewLine(_textEditor.caretLineIndex);
				if (isBetweenBrackets()) {
					var extendedIndent = indent + getIndentString();
					var newCaretLineIndex = _textEditor.caretLineIndex + 1;
					var newCaretCharIndex = extendedIndent.length;
					insertText(_textEditor.lineDelimiter + extendedIndent + _textEditor.lineDelimiter + indent);
					_textEditor.setSelection(newCaretLineIndex, newCaretCharIndex, newCaretLineIndex, newCaretCharIndex);
				} else {
					insertText(_textEditor.lineDelimiter + indent);
				}
			case Keyboard.BACKSPACE:
				var change = createRemoveAtCursorTextEditorChange(false, event.altKey);
				if (change != null) {
					if (_activeAutoClosingPair != null
						&& change.startLine == _activeAutoClosingPairLineIndex
						&& change.endChar == _activeAutoClosingPairEndCharIndex
						&& _activeAutoClosingPairStartCharIndex == _activeAutoClosingPairEndCharIndex) {
						change = new TextEditorChange(change.startLine, change.startChar, change.endLine,
							change.endChar + _activeAutoClosingPair.close.length);
					}
					dispatchChanges([change]);
				}
			case Keyboard.DELETE:
				var change = createRemoveAtCursorTextEditorChange(true, event.altKey);
				if (change != null) {
					// normally, we check if the active auto-closing pair should
					// be cleared whenever the selection changes, but when we
					// press the delete key, and there's no selection, it might
					// not move the caret, so we check here instead.
					if (!_textEditor.hasSelection) {
						checkForClearActiveAutoClosingPair(change.startLine, change.startChar);
						checkForClearActiveAutoClosingPair(change.endLine, change.endChar);
					}
					dispatchChanges([change]);
				}
			case Keyboard.TAB:
				indent(event.shiftKey);
				event.preventDefault();
			case Keyboard.SLASH:
				if (event.ctrlKey && event.altKey) {
					toggleBlockComment();
					event.preventDefault();
				} else if (event.ctrlKey) {
					toggleLineComment();
					event.preventDefault();
				}
		}
		// Prevent COMMAND key combinations from ever triggering text input
		// CHECK COMMAND KEY VALUE FOR MAC
		if (event.keyCode == 25) {
			event.preventDefault();
		}
	}

	private function editManager_textEditor_textInputHandler(event:TextEvent):Void {
		var newText = event.text;
		// Insert text only if it contains non-control characters (via http://www.fileformat.info/info/unicode/category/Cc/list.htm)
		if (!~/[^\x00-\x1F\x7F\x80-\x9F]/.match(newText)) {
			return;
		}
		insertText(newText);
	}

	private function applyChange(change:TextEditorChange):Void {
		var startLine = change.startLine;
		var startChar = change.startChar;
		var endLine = change.endLine;
		var endChar = change.endChar;
		var newText = change.newText;

		if (_activeAutoClosingPair != null) {
			if (startChar <= _activeAutoClosingPairEndCharIndex && endChar <= _activeAutoClosingPairEndCharIndex) {
				_activeAutoClosingPairEndCharIndex -= (endChar - startChar);
				if (newText != null) {
					_activeAutoClosingPairEndCharIndex += newText.length;
				}
			}
		}

		var insertedLines:Array<String> = null;
		if (newText != null && newText.length > 0) {
			insertedLines = ~/\r?\n|\r/g.split(newText);
		}

		var targetStartLine = _textEditor.lines.get(startLine);
		var targetEndLine = _textEditor.lines.get(endLine);
		var startTextToKeep = targetStartLine.text.substring(0, startChar);
		var endTextToKeep = targetEndLine.text.substring(endChar);

		// Remove all lines after the first
		if (startLine != endLine) {
			var removeFrom = startLine + 1;
			var removeOffset = startLine - endLine;
			for (_ in removeOffset...0) {
				_textEditor.lines.removeAt(removeFrom);
			}
			updateLineIndices(_textEditor, removeFrom, removeOffset);
		}

		if (insertedLines == null) {
			// remove only
			targetStartLine.text = startTextToKeep + endTextToKeep;
			_textEditor.lines.updateAt(startLine);
		} else {
			if (insertedLines.length > 1) {
				updateLineIndices(_textEditor, startLine + 1, insertedLines.length - 1);
			}
			for (i in 0...insertedLines.length) {
				var updatedText = "";
				if (i == 0) {
					updatedText = startTextToKeep;
				}
				updatedText += insertedLines[i];
				if (i == (insertedLines.length - 1)) {
					updatedText += endTextToKeep;
				}
				var lineIndex = startLine + i;
				if (lineIndex == startLine) {
					targetStartLine.text = updatedText;
					_textEditor.lines.updateAt(lineIndex);
				} else {
					_textEditor.lines.addAt(new TextLineModel(updatedText, lineIndex), lineIndex);
				}
			}
		}
	}

	private function updateLineIndices(textEditor:TextEditor, startIndex:Int, offset:Int):Void {
		var lines = textEditor.lines;
		for (i in startIndex...lines.length) {
			var line = lines.get(i);
			line.lineIndex += offset;
			lines.updateAt(i);
		}
	}

	private function sortTextChanges(change1:TextEditorChange, change2:TextEditorChange):Int {
		if (change1.startLine < change2.startLine) {
			return 1;
		}
		if (change2.startLine < change1.startLine) {
			return -1;
		}
		if (change1.startChar < change2.startChar) {
			return 1;
		}
		if (change2.startChar < change1.startChar) {
			return -1;
		}
		return 0;
	}

	private function mergeChanges(changes:Array<TextEditorChange>):Void {
		var i = 0;
		var prevChange:TextEditorChange = null;
		while (i < changes.length) {
			var change = changes[i];
			if (change.startLine == change.endLine
				&& change.startChar == change.endChar
				&& (change.newText == null || change.newText.length == 0)) {
				// there is no actual change, so skip it
				changes.splice(i, 1);
				continue;
			}
			if (change.startLine < 0
				|| change.startChar < 0
				|| change.endLine < 0
				|| change.endChar < 0
				|| change.startLine > change.endLine
				|| (change.startLine == change.endLine && change.startChar > change.endChar)) {
				throw new RangeError('Invalid text editor change. Start: (${change.startLine}, ${change.startChar}), End: (${change.endLine}, ${change.endChar})');
			}
			if (prevChange == null) {
				prevChange = change;
				i++;
				continue;
			}

			var changesOverlap = change.endLine > prevChange.startLine
				|| (change.endLine == prevChange.startLine
					&& (change.endChar > prevChange.startChar || change.startChar == prevChange.startChar));
			if (changesOverlap) {
				var prevIsInsertOnly = prevChange.startLine == prevChange.endLine
					&& prevChange.startChar == prevChange.endChar
					&& prevChange.newText != null;
				var canMerge = prevIsInsertOnly && prevChange.startLine == change.startLine && prevChange.startChar == change.startChar;
				if (canMerge) {
					var combinedText = "";
					if (prevChange.newText != null) {
						combinedText += prevChange.newText;
					}
					if (change.newText != null) {
						combinedText += change.newText;
					}
					prevChange = new TextEditorChange(change.startLine, change.startChar, change.endLine, change.endChar, combinedText);
					changes[i - 1] = prevChange;
					changes.splice(i, 1);
					continue;
				}
				throw new ArgumentError('TextEditorChanges must not overlap. { startLine: ${prevChange.startLine}, startChar: ${prevChange.startChar}, endLine: ${prevChange.endLine}, endChar: ${prevChange.endChar} } overlaps with { startLine: ${change.startLine}, startChar: ${change.startChar}, endLine: ${change.endLine}, endChar: ${change.endChar}}.');
			}
			i++;
		}
	}

	private function editManager_textEditor_textChangePriorityHandler(event:TextEditorChangeEvent):Void {
		/*
			we've designed the TextEditorChange behavior to match the behavior
			of the language server protocol, which describes the following
			restriction:

			> Text edits ranges must never overlap, that means no part of the
			> original document must be manipulated by more than one edit.
			> However, it is possible that multiple edits have the same start
			> position: multiple inserts, or any number of inserts followed by a
			> single remove or replace edit. If multiple inserts have the same
			> position, the order in the array defines the order in which the
			> inserted strings appear in the resulting text.

			Source: https://microsoft.github.io/language-server-protocol/specifications/specification-current/#textEditArray
		 */

		// sort from end to start so that we don't have to handle any offsets
		// since the changes will not overlap, it's okay to sort them.
		// use ArraySort.sort() instead of changes.sort() because we don't want
		// equal edits to be out of order.

		if (event.origin != TextEditorChangeEvent.ORIGIN_UNDO) {
			ArraySort.sort(event.changes, sortTextChanges);
			mergeChanges(event.changes);
		}
	}

	private function editManager_textEditor_textChangeHandler(event:TextEditorChangeEvent):Void {
		for (change in event.changes) {
			applyChange(change);
		}
	}

	private function checkForClearActiveAutoClosingPair(line:Int, char:Int):Void {
		if (_activeAutoClosingPair == null) {
			return;
		}
		var clearActivePair = false;
		if (line != _activeAutoClosingPairLineIndex) {
			clearActivePair = true;
		} else if (char < _activeAutoClosingPairStartCharIndex || char > _activeAutoClosingPairEndCharIndex) {
			clearActivePair = true;
		}
		if (!clearActivePair) {
			return;
		}
		_activeAutoClosingPair = null;
		_activeAutoClosingPairLineIndex = -1;
		_activeAutoClosingPairStartCharIndex = -1;
		_activeAutoClosingPairEndCharIndex = -1;
	}

	private function editManager_textEditor_selectionChangeHandler(event:TextEditorEvent):Void {
		checkForClearActiveAutoClosingPair(_textEditor.caretLineIndex, _textEditor.caretCharIndex);
	}

	private function editManager_textEditor_clearHandler(event:Event):Void {
		var change = TextEditorUtil.deleteSelection(_textEditor);
		if (change != null) {
			_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, [change]));
		}
	}
}
