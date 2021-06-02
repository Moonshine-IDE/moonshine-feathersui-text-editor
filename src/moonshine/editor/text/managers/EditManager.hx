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

import moonshine.editor.text.changes.TextEditorChange;
import moonshine.editor.text.events.TextEditorChangeEvent;
import moonshine.editor.text.lines.TextLineModel;
import moonshine.editor.text.utils.TextUtil;
import openfl.desktop.Clipboard;
import openfl.desktop.ClipboardFormats;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.TextEvent;
import openfl.ui.Keyboard;

class EditManager {
	public function new(textEditor:TextEditor) {
		_textEditor = textEditor;
		_textEditor.addEventListener(Event.PASTE, editManager_textEditor_pasteHandler, false, 0, true);
		_textEditor.addEventListener(KeyboardEvent.KEY_DOWN, editManager_textEditor_keyDownHandler, false, 0, true);
		_textEditor.addEventListener(TextEvent.TEXT_INPUT, editManager_textEditor_textInputHandler, false, 0, true);
		_textEditor.addEventListener(TextEditorChangeEvent.TEXT_CHANGE, editManager_textEditor_textChangeHandler, false, 0, true);
	}

	private var _textEditor:TextEditor;

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

			var line = startLine;
			while (line <= endLine) {
				if (reverse) {
					var indent = TextUtil.getIndentAtStartOfLine(_textEditor.lines.get(line).text, _textEditor.tabWidth);
					if (indent.length > 0) {
						changes.push(new TextEditorChange(line, 0, line, indent.length));
					}
				} else {
					changes.push(new TextEditorChange(line, 0, line, 0, getTabString()));
				}
				line++;
			}

			if (changes.length > 0) {
				dispatchChanges(changes);

				_textEditor.setSelection(startLine, 0, endLine + 1, 0);
			}
		} else if (reverse) {
			var lineIndex = _textEditor.caretLineIndex;
			var indent = TextUtil.getIndentAtStartOfLine(_textEditor.lines.get(lineIndex).text, _textEditor.tabWidth);
			if (indent.length > 0) {
				dispatchChanges([new TextEditorChange(lineIndex, 0, lineIndex, indent.length)]);
			}
		} else {
			insertText(getTabString());
		}
	}

	private function getTabString():String {
		if (_textEditor.insertSpacesForTabs) {
			return TextUtil.repeatStr(" ", _textEditor.tabWidth);
		}
		return "\t";
	}

	private function insertText(text:String):Void {
		if (_textEditor.hasSelection) {
			dispatchChanges([removeSelection(text)]);
			return;
		}
		var line = _textEditor.caretLineIndex;
		var char = _textEditor.caretCharIndex;
		dispatchChanges([new TextEditorChange(line, char, line, char, text)]);
	}

	private function removeAtCursor(afterCaret:Bool, isWord:Bool):Void {
		if (_textEditor.hasSelection) {
			dispatchChanges([removeSelection()]);
			return;
		}

		var startLine = _textEditor.caretLineIndex;
		var endLine = startLine;
		var startChar = _textEditor.caretCharIndex;
		var endChar = startChar;

		// Backspace remove line & append to line above it
		if (startChar == 0 && !afterCaret) {
			// Can't remove first line with backspace
			if (startLine == 0)
				return;

			startLine--;
			startChar = _textEditor.lines.get(startLine).text.length;
			endChar = 0;
		}
		// Delete remove linebreak & append to line below it
		else if (startChar == _textEditor.lines.get(startLine).text.length && afterCaret) {
			if (startLine == _textEditor.lines.length - 1)
				return;

			endLine++;
			startChar = _textEditor.lines.get(startLine).text.length;
			endChar = 0;
		} else if (afterCaret) { // Delete
			endChar += isWord ? TextUtil.wordBoundaryForward(_textEditor.lines.get(startLine).text.substring(startChar)) : 1;
		} else { // Backspace
			startChar -= isWord ? TextUtil.wordBoundaryBackward(_textEditor.lines.get(startLine).text.substring(0, endChar)) : 1;
		}

		dispatchChanges([new TextEditorChange(startLine, startChar, endLine, endChar)]);
	}

	private function removeSelection(?newText:String):TextEditorChange {
		var startChar:Int;
		var endChar:Int;
		var startLine:Int;
		var endLine:Int;

		if (_textEditor.hasSelection && _textEditor.selectionStartLineIndex != _textEditor.selectionEndLineIndex) {
			if (_textEditor.selectionStartLineIndex < _textEditor.caretLineIndex) {
				startLine = _textEditor.selectionStartLineIndex;
				startChar = _textEditor.selectionStartCharIndex;
				endLine = _textEditor.caretLineIndex;
				endChar = _textEditor.caretCharIndex;
			} else {
				startLine = _textEditor.caretLineIndex;
				startChar = _textEditor.caretCharIndex;
				endLine = _textEditor.selectionStartLineIndex;
				endChar = _textEditor.selectionStartCharIndex;
			}
		} else {
			startLine = _textEditor.caretLineIndex;
			endLine = startLine;
			startChar = Std.int(Math.min(_textEditor.selectionStartCharIndex, _textEditor.caretCharIndex));
			endChar = Std.int(Math.max(_textEditor.selectionStartCharIndex, _textEditor.caretCharIndex));
		}

		return new TextEditorChange(startLine, startChar, endLine, endChar, newText);
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
				insertText(_textEditor.lineDelimiter);
			case Keyboard.BACKSPACE:
				removeAtCursor(false, event.altKey);
			case Keyboard.DELETE:
				removeAtCursor(true, event.altKey);
			case Keyboard.TAB:
				indent(event.shiftKey);
				event.preventDefault();
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

	private function editManager_textEditor_pasteHandler(event:Event):Void {
		if (event.isDefaultPrevented()) {
			return;
		}
		if (!Clipboard.generalClipboard.hasFormat(ClipboardFormats.TEXT_FORMAT)) {
			return;
		}
		var newText = Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT);
		insertText(newText);
	}

	private function applyChange(change:TextEditorChange):Void {
		var startLine = change.startLine;
		var startChar = change.startChar;
		var endLine = change.endLine;
		var endChar = change.endChar;

		var newText = change.newText;
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

	private function editManager_textEditor_textChangeHandler(event:TextEditorChangeEvent):Void {
		var changes = event.changes.copy();
		// sort from end to start so that we don't have to handle any offsets
		// since the changes will not overlap, it's okay to sort them
		changes.sort(sortTextChanges);
		for (change in changes) {
			applyChange(change);
		}
	}
}