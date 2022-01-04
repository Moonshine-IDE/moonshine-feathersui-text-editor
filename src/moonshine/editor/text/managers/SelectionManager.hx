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
import moonshine.editor.text.utils.TextUtil;
import openfl.Lib;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.TimerEvent;
import openfl.geom.Point;
import openfl.ui.Keyboard;
import openfl.utils.Timer;

/**
	Used internally by `TextEditor` to manage selection.
**/
class SelectionManager {
	private static final SCROLL_THRESHOLD:Int = 10;
	private static final SCROLL_INTERVAL:Int = 60;

	/**
		Creates a new `SelectionManager` object.
	**/
	public function new(textEditor:TextEditor) {
		_textEditor = textEditor;

		_textEditor.addEventListener(KeyboardEvent.KEY_DOWN, selectionManager_textEditor_keyDownHandler, false, 0, true);
		// need to use capture for the navigation keys because the internal
		// container might try to cancel them before our listener is called
		_textEditor.addEventListener(KeyboardEvent.KEY_DOWN, selectionManager_textEditor_keyDownCaptureHandler, true, 0, true);
		_textEditor.addEventListener(TextEditorChangeEvent.TEXT_CHANGE, selectionManager_textEditor_textChangePriorityHandler, false, 100, true);
		_textEditor.addEventListener(TextEditorChangeEvent.TEXT_CHANGE, selectionManager_textEditor_textChangeHandler, false, 0, true);
		_textEditor.addEventListener(Event.SELECT_ALL, selectionManager_textEditor_selectAllHandler, false, 0, true);
		_textEditor.addEventListener(MouseEvent.MOUSE_DOWN, selectionManager_textEditor_mouseDownHandler, false, 0, true);
	}

	private var _textEditor:TextEditor;

	private var _savedCaretLineIndex:Int = -1;
	private var _savedCaretCharIndex:Int = -1;
	private var _dragStartLine:Int = -1;
	private var _dragStartChar:Int = -1;
	private var _dragEndChar:Int = -1;
	private var _dragScrollDelta:Int = 0;
	private var _dragLocalPoint:Point;
	private var _dragScrollTimer:Timer;

	private function applyChanges(changes:Array<TextEditorChange>):Void {
		var line = _savedCaretLineIndex;
		var char = _savedCaretCharIndex;

		for (change in changes) {
			if ((line > change.startLine && line < change.endLine)
				|| (line == change.startLine && char >= change.startChar)
				|| (line == change.endLine && char <= change.endChar)) {
				line = change.endLine;
				char = change.endChar;
			}

			if (change.endLine == line && change.endChar <= char) {
				char -= change.endChar;
			}

			if (line >= change.endLine) {
				line -= (change.endLine - change.startLine);
				if (line == change.startLine) {
					char += change.startChar;
				}
			}

			var newText:String = change.newText;
			if (newText != null && newText.length > 0) {
				var insertedLines = ~/\r?\n|\r/g.split(newText);
				if (line == change.startLine && char >= change.startChar) {
					if (insertedLines.length > 1) {
						char -= change.startChar;
					}
					char += insertedLines[insertedLines.length - 1].length;
				}
				if (line >= change.startLine) {
					line += (insertedLines.length - 1);
				}
			}
		}
		_textEditor.setSelection(line, char, line, char);
	}

	private function focusSelectionStart():Void {
		var newLineIndex = _textEditor.selectionStartLineIndex;
		var newCharIndex = _textEditor.selectionStartCharIndex;
		_textEditor.setSelection(newLineIndex, newCharIndex, newLineIndex, newCharIndex);
	}

	private function updateDragSelect():Void {
		var localPoint = _dragLocalPoint;

		var startLine:Int = _dragStartLine;
		var startChar:Int = _dragEndChar;
		var endLine:Int = _dragStartLine;
		var endChar:Int = _dragEndChar;

		_textEditor.validateNow();
		var textEditorPosition = _textEditor.localToTextEditorPosition(localPoint, true);
		if (textEditorPosition == null) {
			return;
		}

		var newCaretPosition = textEditorPosition.character;

		if (newCaretPosition < _dragStartChar && textEditorPosition.line <= _dragStartLine) {
			startChar = _dragEndChar;
		} else if (newCaretPosition > _dragEndChar && textEditorPosition.line >= _dragStartLine) {
			startChar = _dragStartChar;
		} else if (textEditorPosition.line < _dragStartLine) {
			startChar = _dragEndChar;
		} else if (textEditorPosition.line > _dragStartLine) {
			startChar = _dragStartChar;
		}

		if (newCaretPosition != -1) {
			if (_clickCount == 1) {
				endLine = textEditorPosition.line;
				endChar = newCaretPosition;
			} else if (_clickCount == 2) {
				endLine = textEditorPosition.line;
				endChar = newCaretPosition + TextUtil.wordBoundaryForward(_textEditor.lines.get(endLine).text.substring(newCaretPosition));
			} else if (_clickCount == 3) {
				endLine = textEditorPosition.line;
				endChar = _textEditor.lines.get(endLine).text.length;
			}
		} else if (localPoint.x < _textEditor.gutterWidth) {
			endLine = textEditorPosition.line + (startLine > textEditorPosition.line
				|| startLine == textEditorPosition.line
				&& startChar > 0 ? 0 : 1);
			endChar = 0;

			if (endLine >= _textEditor.lines.length) {
				endLine = _textEditor.lines.length - 1;
				endChar = _textEditor.lines.get(endLine).text.length;
			}
		} else {
			return;
		}

		_textEditor.setSelection(startLine, startChar, endLine, endChar);
	}

	private function startDragScroll():Void {
		_dragScrollTimer = new Timer(SCROLL_INTERVAL);
		_dragScrollTimer.addEventListener(TimerEvent.TIMER, selectionManager_dragScrollTimer_timerHandler);
		_dragScrollTimer.start();
	}

	private function stopDragScroll():Void {
		if (_dragScrollTimer != null) {
			_dragScrollTimer.stop();
			_dragScrollTimer = null;
		}
	}

	private function keyboardHome(event:KeyboardEvent):Void {
		var selectionStartLineIndex = _textEditor.hasSelection ? _textEditor.selectionStartLineIndex : _textEditor.caretLineIndex;
		var selectionStartCharIndex = _textEditor.hasSelection ? _textEditor.selectionStartCharIndex : _textEditor.caretCharIndex;

		if (_textEditor.hasSelection && !event.shiftKey) {
			_textEditor.removeSelection();
		}

		if (event.ctrlKey) {
			var newLineIndex = 0;
			var newCaretIndex = 0;
			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, newLineIndex, newCaretIndex);
			} else {
				_textEditor.setSelection(0, 0, 0, 0);
			}
			_textEditor.lineScrollY = 0;
		} else {
			var caretLine = _textEditor.lines.get(_textEditor.caretLineIndex);
			var tabIndex = TextUtil.indentAmount(caretLine.text);
			var newCaretIndex = (_textEditor.caretCharIndex == tabIndex) ? 0 : tabIndex;

			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, _textEditor.caretLineIndex, newCaretIndex);
			} else {
				_textEditor.setSelection(_textEditor.caretLineIndex, newCaretIndex, _textEditor.caretLineIndex, newCaretIndex);
			}
		}
	}

	private function keyboardEnd(event:KeyboardEvent):Void {
		var selectionStartLineIndex = _textEditor.hasSelection ? _textEditor.selectionStartLineIndex : _textEditor.caretLineIndex;
		var selectionStartCharIndex = _textEditor.hasSelection ? _textEditor.selectionStartCharIndex : _textEditor.caretCharIndex;

		if (_textEditor.hasSelection && !event.shiftKey) {
			_textEditor.removeSelection();
		}

		if (event.ctrlKey) {
			var newLineIndex = _textEditor.lines.length - 1;
			var newCaretIndex = _textEditor.lines.get(newLineIndex).text.length;
			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, newLineIndex, newCaretIndex);
			} else {
				_textEditor.setSelection(newLineIndex, newCaretIndex, newLineIndex, newCaretIndex);
			}
			_textEditor.lineScrollY = _textEditor.maxLineScrollY;
		} else {
			var caretLine = _textEditor.lines.get(_textEditor.caretLineIndex);
			var newCaretIndex = caretLine.text.length;
			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, _textEditor.caretLineIndex, newCaretIndex);
			} else {
				_textEditor.setSelection(_textEditor.caretLineIndex, newCaretIndex, _textEditor.caretLineIndex, newCaretIndex);
			}
		}
	}

	private function keyboardPageUp(event:KeyboardEvent):Void {
		var selectionStartLineIndex = _textEditor.hasSelection ? _textEditor.selectionStartLineIndex : _textEditor.caretLineIndex;
		var selectionStartCharIndex = _textEditor.hasSelection ? _textEditor.selectionStartCharIndex : _textEditor.caretCharIndex;

		if (_textEditor.hasSelection && !event.shiftKey) {
			_textEditor.removeSelection();
		}

		if (event.ctrlKey) {
			var newLineIndex = _textEditor.lineScrollY;
			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, newLineIndex, _textEditor.caretCharIndex);
			} else {
				_textEditor.setSelectionAdvanced(newLineIndex, _textEditor.expandedCaretCharIndex, newLineIndex, _textEditor.expandedCaretCharIndex, false);
			}
		} else {
			var newLineIndex = Std.int(Math.max(_textEditor.caretLineIndex - _textEditor.visibleLines, 0));
			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, newLineIndex, _textEditor.caretCharIndex);
			} else {
				_textEditor.setSelectionAdvanced(newLineIndex, _textEditor.expandedCaretCharIndex, newLineIndex, _textEditor.expandedCaretCharIndex, false);
			}
			_textEditor.lineScrollY = _textEditor.lineScrollY - _textEditor.visibleLines;
		}
	}

	private function keyboardPageDown(event:KeyboardEvent):Void {
		var selectionStartLineIndex = _textEditor.hasSelection ? _textEditor.selectionStartLineIndex : _textEditor.caretLineIndex;
		var selectionStartCharIndex = _textEditor.hasSelection ? _textEditor.selectionStartCharIndex : _textEditor.caretCharIndex;

		if (_textEditor.hasSelection && !event.shiftKey) {
			_textEditor.removeSelection();
		}

		if (event.ctrlKey) {
			var newLineIndex = _textEditor.lineScrollY + _textEditor.visibleLines - 2;
			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, newLineIndex, _textEditor.caretCharIndex);
			} else {
				_textEditor.setSelectionAdvanced(newLineIndex, _textEditor.expandedCaretCharIndex, newLineIndex, _textEditor.expandedCaretCharIndex, false);
			}
		} else {
			var newLineIndex = Std.int(Math.min(_textEditor.caretLineIndex + _textEditor.visibleLines, _textEditor.lines.length - 1));
			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, newLineIndex, _textEditor.caretCharIndex);
			} else {
				_textEditor.setSelectionAdvanced(newLineIndex, _textEditor.expandedCaretCharIndex, newLineIndex, _textEditor.expandedCaretCharIndex, false);
			}
			_textEditor.lineScrollY += _textEditor.visibleLines;
		}
	}

	private function keyboardLeft(event:KeyboardEvent):Void {
		var selectionStartLineIndex = _textEditor.hasSelection ? _textEditor.selectionStartLineIndex : _textEditor.caretLineIndex;
		var selectionStartCharIndex = _textEditor.hasSelection ? _textEditor.selectionStartCharIndex : _textEditor.caretCharIndex;
		var chars = 1;

		var caretLine = _textEditor.lines.get(_textEditor.caretLineIndex);
		if (event.commandKey) // Mac specific text editing functionality
		{
			if (!event.shiftKey && _textEditor.hasSelection) {
				_textEditor.removeSelection();
			}

			var tabIndex = TextUtil.indentAmount(caretLine.text);
			var newCaretIndex = (_textEditor.caretCharIndex == tabIndex) ? 0 : tabIndex;

			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, _textEditor.caretLineIndex, newCaretIndex);
			} else {
				_textEditor.setSelection(_textEditor.caretLineIndex, newCaretIndex, _textEditor.caretLineIndex, newCaretIndex);
			}
		} else if (_textEditor.hasSelection && !event.shiftKey) {
			if (_textEditor.caretLineIndex > _textEditor.selectionStartLineIndex
				|| _textEditor.caretCharIndex > _textEditor.selectionStartCharIndex) {
				focusSelectionStart();
			}

			_textEditor.removeSelection();
		} else if (_textEditor.caretCharIndex > 0) {
			if (event.altKey) {
				chars = TextUtil.wordBoundaryBackward(caretLine.text.substring(0, _textEditor.caretCharIndex));
			}
			var newCaretIndex = _textEditor.caretCharIndex - chars;
			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, _textEditor.caretLineIndex, newCaretIndex);
			} else {
				_textEditor.setSelection(_textEditor.caretLineIndex, newCaretIndex, _textEditor.caretLineIndex, newCaretIndex);
			}
		} else {
			if (_textEditor.caretLineIndex == 0) {
				return;
			}
			var newLineIndex = _textEditor.caretLineIndex - 1;
			if (newLineIndex >= 0) {
				var newCaretIndex = _textEditor.lines.get(newLineIndex).text.length;
				if (event.shiftKey) {
					_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, newLineIndex, newCaretIndex);
				} else {
					_textEditor.setSelection(newLineIndex, newCaretIndex, newLineIndex, newCaretIndex);
				}
			}
		}
	}

	private function keyboardRight(event:KeyboardEvent):Void {
		var selectionStartLineIndex = _textEditor.hasSelection ? _textEditor.selectionStartLineIndex : _textEditor.caretLineIndex;
		var selectionStartCharIndex = _textEditor.hasSelection ? _textEditor.selectionStartCharIndex : _textEditor.caretCharIndex;
		var chars = 1;

		var caretLine = _textEditor.lines.get(_textEditor.caretLineIndex);
		if (event.commandKey) // Mac specific text editing functionality
		{
			if (!event.shiftKey && _textEditor.hasSelection) {
				_textEditor.removeSelection();
			}

			var newCaretIndex = caretLine.text.length;
			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, _textEditor.caretLineIndex, newCaretIndex);
			} else {
				_textEditor.setSelection(_textEditor.caretLineIndex, newCaretIndex, _textEditor.caretLineIndex, newCaretIndex);
			}
		} else if (_textEditor.hasSelection && !event.shiftKey) {
			if (_textEditor.caretLineIndex < _textEditor.selectionStartLineIndex
				|| _textEditor.caretCharIndex < _textEditor.selectionStartCharIndex) {
				focusSelectionStart();
			}
			_textEditor.removeSelection();
		} else if (_textEditor.caretCharIndex < caretLine.text.length) {
			if (event.altKey) {
				chars = TextUtil.wordBoundaryForward(caretLine.text.substring(_textEditor.caretCharIndex));
			}

			var newCaretIndex = _textEditor.caretCharIndex + chars;
			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, _textEditor.caretLineIndex, newCaretIndex);
			} else {
				_textEditor.setSelection(_textEditor.caretLineIndex, newCaretIndex, _textEditor.caretLineIndex, newCaretIndex);
			}
		} else {
			if (_textEditor.caretLineIndex < _textEditor.lines.length - 1) {
				return;
			}

			var newLineIndex = _textEditor.caretLineIndex + 1;
			if (newLineIndex < _textEditor.lines.length) {
				var newCaretIndex = 0;
				if (event.shiftKey) {
					_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, newLineIndex, newCaretIndex);
				} else {
					_textEditor.setSelection(newLineIndex, newCaretIndex, newLineIndex, newCaretIndex);
				}
			}
		}
	}

	private function keyboardUp(event:KeyboardEvent):Void {
		var selectionStartLineIndex = _textEditor.hasSelection ? _textEditor.selectionStartLineIndex : _textEditor.caretLineIndex;
		var selectionStartCharIndex = _textEditor.hasSelection ? _textEditor.selectionStartCharIndex : _textEditor.caretCharIndex;

		if (event.commandKey) // Mac specific text editing functionality
		{
			if (!event.shiftKey && _textEditor.hasSelection) {
				_textEditor.removeSelection();
			}

			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, 0, 0);
			} else {
				_textEditor.setSelection(0, 0, 0, 0);
			}
		} else if (event.ctrlKey) {
			if (_textEditor.lineScrollY > 0) {
				// Ensure the caret stays in view (unless there's active selection)
				if (!_textEditor.hasSelection && _textEditor.caretLineIndex > (_textEditor.lineScrollY + _textEditor.visibleLines - 2)) {
					var newLineIndex = _textEditor.lineScrollY + _textEditor.visibleLines - 2;
					_textEditor.setSelectionAdvanced(newLineIndex, _textEditor.expandedCaretCharIndex, newLineIndex, _textEditor.expandedCaretCharIndex,
						false);
				}
				_textEditor.lineScrollY = _textEditor.lineScrollY - 1;
			}
		} else {
			if (_textEditor.hasSelection && !event.shiftKey) {
				_textEditor.removeSelection();
			}
			var newLineIndex = _textEditor.caretLineIndex - 1;
			var newCaretIndex = event.shiftKey ? _textEditor.caretCharIndex : _textEditor.expandedCaretCharIndex;
			if (newLineIndex < 0) {
				newLineIndex = 0;
				newCaretIndex = 0;
			}
			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, newLineIndex, newCaretIndex);
			} else {
				_textEditor.setSelectionAdvanced(newLineIndex, newCaretIndex, newLineIndex, newCaretIndex, false);
			}
		}
	}

	private function keyboardDown(event:KeyboardEvent):Void {
		var selectionStartLineIndex = _textEditor.hasSelection ? _textEditor.selectionStartLineIndex : _textEditor.caretLineIndex;
		var selectionStartCharIndex = _textEditor.hasSelection ? _textEditor.selectionStartCharIndex : _textEditor.caretCharIndex;

		if (event.commandKey) // Mac specific text editing functionality
		{
			if (!event.shiftKey && _textEditor.hasSelection) {
				_textEditor.removeSelection();
			}

			var newLineIndex = _textEditor.lines.length - 1;
			var newCaretIndex = _textEditor.lines.get(newLineIndex).text.length;
			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, newLineIndex, newCaretIndex);
			} else {
				_textEditor.setSelection(newLineIndex, newCaretIndex, newLineIndex, newCaretIndex);
			}
		} else if (event.ctrlKey) {
			if (_textEditor.lineScrollY < _textEditor.maxLineScrollY) {
				// Ensure the caret stays in view (unless there's active selection)
				if (!_textEditor.hasSelection && _textEditor.caretLineIndex < _textEditor.lineScrollY + 1) {
					var newLineIndex = _textEditor.lineScrollY + 1;
					_textEditor.setSelectionAdvanced(newLineIndex, _textEditor.expandedCaretCharIndex, newLineIndex, _textEditor.expandedCaretCharIndex,
						false);
				}
				_textEditor.lineScrollY = _textEditor.lineScrollY + 1;
			}
		} else {
			if (_textEditor.hasSelection && !event.shiftKey) {
				_textEditor.removeSelection();
			}
			var newLineIndex = _textEditor.caretLineIndex + 1;
			var newCaretIndex = event.shiftKey ? _textEditor.caretCharIndex : _textEditor.expandedCaretCharIndex;
			if (newLineIndex >= _textEditor.lines.length) {
				newLineIndex = _textEditor.lines.length - 1;
				newCaretIndex = _textEditor.lines.get(_textEditor.lines.length - 1).text.length;
			}
			if (event.shiftKey) {
				_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, newLineIndex, newCaretIndex);
			} else {
				_textEditor.setSelectionAdvanced(newLineIndex, newCaretIndex, newLineIndex, newCaretIndex, false);
			}
		}
	}

	private function selectionManager_textEditor_keyDownHandler(event:KeyboardEvent):Void {
		if (event.isDefaultPrevented()) {
			return;
		}
		switch (event.keyCode) {
			case Keyboard.A:
				if (event.ctrlKey && !event.altKey) {
					var lastLineIndex = _textEditor.lines.length - 1;
					_textEditor.setSelection(0, 0, lastLineIndex, _textEditor.lines.get(lastLineIndex).text.length);
					_textEditor.scrollViewIfNeeded();
					event.preventDefault();
				}
		}
	}

	private function selectionManager_textEditor_keyDownCaptureHandler(event:KeyboardEvent):Void {
		if (event.isDefaultPrevented()) {
			return;
		}
		var processed = true;
		switch (event.keyCode) {
			case Keyboard.LEFT:
				keyboardLeft(event);
			case Keyboard.RIGHT:
				keyboardRight(event);
			case Keyboard.UP:
				keyboardUp(event);
			case Keyboard.DOWN:
				keyboardDown(event);
			case Keyboard.PAGE_DOWN:
				keyboardPageDown(event);
			case Keyboard.PAGE_UP:
				keyboardPageUp(event);
			case Keyboard.HOME:
				keyboardHome(event);
			case Keyboard.END:
				keyboardEnd(event);
			default:
				// Unflag as processed if nothing matched
				processed = false;
		}
		if (processed) {
			event.preventDefault();
			_textEditor.scrollViewIfNeeded();
		}
	}

	private function selectionManager_textEditor_textChangePriorityHandler(event:TextEditorChangeEvent):Void {
		if (event.origin == TextEditorChangeEvent.ORIGIN_REMOTE) {
			return;
		}
		_savedCaretLineIndex = _textEditor.caretLineIndex;
		_savedCaretCharIndex = _textEditor.caretCharIndex;
	}

	private function selectionManager_textEditor_textChangeHandler(event:TextEditorChangeEvent):Void {
		if (event.origin == TextEditorChangeEvent.ORIGIN_REMOTE) {
			return;
		}

		_textEditor.removeSelection();

		applyChanges(event.changes);

		_textEditor.scrollViewIfNeeded();
	}

	private function selectionManager_textEditor_selectAllHandler(event:Event):Void {
		var lastLineIndex = _textEditor.lines.length - 1;
		_textEditor.setSelection(0, 0, lastLineIndex, _textEditor.lines.get(lastLineIndex).text.length);
		_textEditor.scrollViewIfNeeded();
	}

	private var _clickCount:Int = 0;
	private var _lastClickTime:Int = 0;
	private var _lastClickPos:Point;

	private function selectionManager_textEditor_mouseDownHandler(event:MouseEvent):Void {
		var localPoint = new Point(_textEditor.mouseX, _textEditor.mouseY);

		var viewPortVisibleBounds = _textEditor.getViewPortVisibleBounds();
		if (!viewPortVisibleBounds.containsPoint(localPoint)) {
			return;
		}

		// Double click?
		if (_clickCount > 0 && Lib.getTimer() - _lastClickTime < 300 && Point.distance(localPoint, _lastClickPos) < 10) {
			_clickCount = _clickCount % 3 + 1;
		} else {
			_clickCount = 1;
		}

		var startLine = 0;
		var startChar = 0;
		var endLine = 0;
		var endChar = 0;

		var pos = _textEditor.localToTextEditorPosition(localPoint, true);
		if (pos == null) {
			return;
		}
		if (pos.character != -1) {
			var updateSelection = true;
			if (localPoint.x < _textEditor.gutterWidth) {
				if (_textEditor.selectionStartLineIndex != pos.line && _textEditor.selectionEndLineIndex != pos.line) {
					return;
				}
				startLine = _textEditor.selectionStartLineIndex;
				startChar = _textEditor.selectionStartCharIndex;
				endLine = _textEditor.selectionEndLineIndex;
				endChar = _textEditor.selectionEndCharIndex;
				updateSelection = false;
			} else if (_clickCount == 1) {
				startLine = event.shiftKey ? _textEditor.hasSelection ? _textEditor.selectionStartLineIndex : _textEditor.caretLineIndex : pos.line;
				startChar = event.shiftKey ? _textEditor.hasSelection ? _textEditor.selectionStartCharIndex : _textEditor.caretCharIndex : pos.character;

				endLine = pos.line;
				endChar = pos.character;
			} else if (_clickCount == 2) {
				startLine = endLine = pos.line;

				startChar = pos.character - TextUtil.wordBoundaryBackward(_textEditor.lines.get(startLine).text.substring(0, pos.character));
				endChar = pos.character + TextUtil.wordBoundaryForward(_textEditor.lines.get(endLine).text.substring(pos.character));
				if (_textEditor.lines.get(endLine).text.charAt(endChar - 1) == " ") {
					endChar--;
				}
			} else if (_clickCount == 3) {
				startLine = endLine = pos.line;

				startChar = 0;
				endChar = _textEditor.lines.get(startLine).text.length;
			} else {
				return;
			}

			if (updateSelection) {
				_textEditor.setSelection(startLine, startChar, endLine, endChar);
			}
		} else {
			return;
		}

		_dragStartLine = startLine;
		_dragStartChar = startChar;
		_dragEndChar = endChar;
		_dragLocalPoint = localPoint;
		_textEditor.stage.addEventListener(MouseEvent.MOUSE_MOVE, selectionManager_stage_mouseMoveHandler, false, 0, true);
		_textEditor.stage.addEventListener(MouseEvent.MOUSE_UP, selectionManager_stage_mouseUpHandler, false, 0, true);

		_lastClickPos = localPoint;
		_lastClickTime = Lib.getTimer();
	}

	private function selectionManager_stage_mouseMoveHandler(event:MouseEvent):Void {
		var localPoint = new Point(_textEditor.mouseX, _textEditor.mouseY);
		_dragLocalPoint = localPoint;
		_dragScrollDelta = 0;

		var bounds = _textEditor.getViewPortVisibleBounds();
		var maxY = bounds.y + bounds.height;
		if (localPoint.y <= SCROLL_THRESHOLD) {
			_dragScrollDelta = Math.ceil((localPoint.y - SCROLL_THRESHOLD) / SCROLL_THRESHOLD);
		} else if (localPoint.y >= (maxY - SCROLL_THRESHOLD)) {
			_dragScrollDelta = Math.ceil((localPoint.y - (maxY - SCROLL_THRESHOLD)) / SCROLL_THRESHOLD);
		}
		if (_dragScrollDelta == 0) {
			stopDragScroll();
			updateDragSelect();
		} else if (_dragScrollTimer == null) {
			startDragScroll();
		}
	}

	private function selectionManager_stage_mouseUpHandler(event:MouseEvent):Void {
		var stage = cast(event.currentTarget, Stage);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, selectionManager_stage_mouseMoveHandler);
		stage.removeEventListener(MouseEvent.MOUSE_UP, selectionManager_stage_mouseUpHandler);

		stopDragScroll();
		_dragStartLine = -1;
		_dragStartChar = -1;
		_dragEndChar = -1;
	}

	private function selectionManager_dragScrollTimer_timerHandler(event:TimerEvent):Void {
		var newLineScrollY = _textEditor.lineScrollY + _dragScrollDelta;
		if (newLineScrollY < 0) {
			newLineScrollY = 0;
		} else if (newLineScrollY > _textEditor.maxLineScrollY) {
			newLineScrollY = _textEditor.maxLineScrollY;
		}
		_textEditor.lineScrollY = newLineScrollY;

		updateDragSelect();
	}
}
