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
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

class UndoManager {
	public function new(textEditor:TextEditor) {
		_textEditor = textEditor;
		_textEditor.addEventListener(KeyboardEvent.KEY_DOWN, undoManager_textEditor_keyDownHandler, false, 0, true);
		// needs to be called before the changes are applied to the text editor
		_textEditor.addEventListener(TextEditorChangeEvent.TEXT_CHANGE, undoManager_textEditor_textChangeHandler, false, 10, true);
	}

	private var _undoStack:Array<UndoRedoChanges> = [];
	private var _redoStack:Array<UndoRedoChanges> = [];

	private var _textEditor:TextEditor;

	private var _savedAt:Int = 0;

	@:flash.property
	public var edited(get, never):Bool;

	private function get_edited():Bool {
		return _savedAt != _undoStack.length;
	}

	public function save():Void {
		_savedAt = _undoStack.length;
	}

	public function clear():Void {
		_undoStack.resize(0);
		_redoStack.resize(0);
		_savedAt = 0;
	}

	private function isOneLineRemoveOnly(changes:Array<TextEditorChange>):Bool {
		if (changes.length != 1) {
			return false;
		}
		var change = changes[0];
		return (change.newText == null || change.newText.length == 0)
			&& change.startLine == change.endLine
			&& change.startChar != change.endChar;
	}

	private function isOneLineInsertOnly(changes:Array<TextEditorChange>):Bool {
		if (changes.length != 1) {
			return false;
		}
		var change = changes[0];
		return change.startLine == change.endLine && change.startChar == change.endChar && isOneLineOfNotEmptyText(change.newText);
	}

	private function isOneLineOfNotEmptyText(text:String):Bool {
		if (text == null || text.length == 0) {
			return false;
		}
		return !~/\r?\n|\r/g.match(text);
	}

	private function collectChanges(changes:Array<TextEditorChange>):Void {
		// don't change the original array because it may not be handled yet
		var redoChanges = changes.copy();

		// Check if change can be merged into last change
		if (_undoStack.length > 0 && _undoStack.length != _savedAt) {
			var previousRedoChanges = _undoStack[_undoStack.length - 1].redo;
			if (isOneLineInsertOnly(redoChanges) && isOneLineInsertOnly(previousRedoChanges)) {
				var newChangeInsert = redoChanges[0];
				var previousChangeInsert = previousRedoChanges[0];

				// Merge if the last change was on the same line, and ended where this change starts
				if (newChangeInsert.startLine == previousChangeInsert.startLine
					&& newChangeInsert.startChar == (previousChangeInsert.startChar + previousChangeInsert.newText.length)) {
					var newText = previousChangeInsert.newText + newChangeInsert.newText;

					redoChanges[0] = new TextEditorChange(previousChangeInsert.startLine, previousChangeInsert.startChar, previousChangeInsert.endLine,
						previousChangeInsert.endChar, newText);

					// Remove last change from history because we're replacing it
					_undoStack.pop();
				}
			}
		}

		var reversedRedoChanges = redoChanges.copy();
		reversedRedoChanges.reverse();
		var undoChanges:Array<TextEditorChange> = reversedRedoChanges.map(change -> {
			var oldText:String = null;
			var oldLinesCount = 1;
			if (change.startLine != change.endLine || change.startChar != change.endChar) {
				oldText = "";
				for (i in change.startLine...(change.endLine + 1)) {
					var line = _textEditor.lines.get(i);
					var startChar = (i == change.startLine) ? change.startChar : 0;
					var endChar = (i == change.endLine) ? change.endChar : line.text.length;
					if (i > change.startLine) {
						oldText += "\n";
						oldLinesCount++;
					}
					oldText += line.text.substring(startChar, endChar);
				}
			}

			var startLine = change.startLine;
			var startChar = change.startChar;
			var endLine = change.endLine;
			var endChar = change.endChar;

			var newLines = (change.newText != null) ? ~/\r?\n|\r/g.split(change.newText) : [""];

			if (oldText != null) {
				if (oldLinesCount == 1) {
					endChar -= oldText.length;
				} else {
					endLine -= (oldLinesCount - newLines.length);
				}
			}
			if (newLines.length > 0) {
				endLine = startLine + newLines.length - 1;
				endChar = newLines[newLines.length - 1].length;
				if (endLine == startLine) {
					endChar += startChar;
				}
			}
			return new TextEditorChange(startLine, startChar, endLine, endChar, oldText);
		});

		if (_undoStack.length < _savedAt) {
			// the save point has been lost from the history
			_savedAt = -1;
		}
		_redoStack.resize(0);
		_undoStack.push(new UndoRedoChanges(undoChanges, redoChanges));
	}

	public function undo():Void {
		if (_undoStack.length == 0) {
			return;
		}
		var changes = _undoStack.pop();
		_redoStack.push(changes);
		_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, changes.undo, TextEditorChangeEvent.ORIGIN_UNDO));
	}

	public function redo():Void {
		if (_redoStack.length == 0) {
			return;
		}
		var changes = _redoStack.pop();
		_undoStack.push(changes);
		_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, changes.redo, TextEditorChangeEvent.ORIGIN_UNDO));
	}

	private function undoManager_textEditor_keyDownHandler(event:KeyboardEvent):Void {
		if (event.ctrlKey && !event.altKey) {
			switch (event.keyCode) {
				case Keyboard.Y:
					if (event.isDefaultPrevented()) {
						return;
					}
					event.preventDefault();
					redo();
				case Keyboard.Z:
					if (event.isDefaultPrevented()) {
						return;
					}
					event.preventDefault();
					if (event.shiftKey) {
						redo();
					} else {
						undo();
					}
			}
		}
	}

	private function undoManager_textEditor_textChangeHandler(event:TextEditorChangeEvent):Void {
		if (event.changes == null || event.changes.length == 0 || event.origin != TextEditorChangeEvent.ORIGIN_LOCAL) {
			return;
		}

		collectChanges(event.changes);
	}
}

private class UndoRedoChanges {
	public var undo:Array<TextEditorChange>;
	public var redo:Array<TextEditorChange>;

	public function new(undo:Array<TextEditorChange>, redo:Array<TextEditorChange>) {
		this.undo = undo;
		this.redo = redo;
	}
}
