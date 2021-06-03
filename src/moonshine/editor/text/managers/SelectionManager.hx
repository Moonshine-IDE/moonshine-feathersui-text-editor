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
import moonshine.editor.text.lines.TextLineRenderer;
import moonshine.editor.text.utils.TextUtil;
import openfl.Lib;
import openfl.display.DisplayObject;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.TimerEvent;
import openfl.geom.Point;
import openfl.ui.Keyboard;
import openfl.utils.Timer;

class SelectionManager {
	private static final SCROLL_THRESHOLD:Int = 10;
	private static final SCROLL_INTERVAL:Int = 60;

	public function new(textEditor:TextEditor) {
		_textEditor = textEditor;

		_textEditor.addEventListener(KeyboardEvent.KEY_DOWN, selectionManager_textEditor_keyDownHandler, false, 0, true);
		// need to use capture for the navigation keys because the internal
		// container might try to cancel them before our listener is called
		_textEditor.addEventListener(KeyboardEvent.KEY_DOWN, selectionManager_textEditor_keyDownCaptureHandler, true, 0, true);
		_textEditor.addEventListener(TextEditorChangeEvent.TEXT_CHANGE, selectionManager_textEditor_textChangeHandler, false, 0, true);
		_textEditor.addEventListener(Event.SELECT_ALL, selectionManager_textEditor_selectAllHandler, false, 0, true);
		_textEditor.addEventListener(MouseEvent.MOUSE_DOWN, selectionManager_textEditor_mouseDownHandler, false, 0, true);
	}

	private var _textEditor:TextEditor;

	private var _dragStartLine:Int = -1;
	private var _dragStartChar:Int = -1;
	private var _dragEndChar:Int = -1;
	private var _dragScrollDelta:Int = 0;
	private var _dragLocalPoint:Point;
	private var _dragScrollTimer:Timer;

	private function applyChanges(changes:Array<TextEditorChange>):Void {
		for (change in changes) {
			var newLineIndex = change.startLine;
			var newCharIndex = change.startChar;
			if (change.newText != null) {
				var insertedLines = ~/\r?\n|\r/g.split(change.newText);
				// set caret to the end of the text change
				newLineIndex = change.startLine + insertedLines.length - 1;
				newCharIndex = (insertedLines.length == 1 ? change.startChar : 0) + insertedLines[insertedLines.length - 1].length;
			}
			_textEditor.setSelection(newLineIndex, newCharIndex, newLineIndex, newCharIndex);
		}
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

		if (newCaretPosition > -1) {
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
		} else if (localPoint.x < _textEditor.lineNumberWidth) {
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

		if (startChar != endChar) {
			_textEditor.setSelection(startLine, startChar, endLine, endChar);
		}
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
		var chars = 1;
		var word = event.altKey;

		var selectionStartLineIndex = _textEditor.hasSelection ? _textEditor.selectionStartLineIndex : _textEditor.caretLineIndex;
		var selectionStartCharIndex = _textEditor.hasSelection ? _textEditor.selectionStartCharIndex : _textEditor.caretCharIndex;

		switch (event.keyCode) {
			case Keyboard.LEFT:
				var caretLine = _textEditor.lines.get(_textEditor.caretLineIndex);
				if (event.commandKey) // CHECK COMMAND KEY VALUE // Mac specific text editing functionality
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
					if (word) {
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
			case Keyboard.RIGHT:
				var caretLine = _textEditor.lines.get(_textEditor.caretLineIndex);
				if (event.commandKey) // CHECK COMMAND KEY VALUE // Mac specific text editing functionality
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
					if (word) {
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
			case Keyboard.UP:
				if (event.ctrlKey) {
					if (_textEditor.lineScrollY > 0) {
						// Ensure the caret stays in view (unless there's active selection)
						if (!_textEditor.hasSelection
							&& _textEditor.caretLineIndex > (_textEditor.lineScrollY + _textEditor.visibleLines - 2)) {
							var newLineIndex = _textEditor.lineScrollY + _textEditor.visibleLines - 2;
							_textEditor.setSelectionAdvanced(newLineIndex, _textEditor.expandedCaretCharIndex, newLineIndex,
								_textEditor.expandedCaretCharIndex, false);
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
			case Keyboard.DOWN:
				if (event.ctrlKey) {
					if (_textEditor.lineScrollY < _textEditor.maxLineScrollY) {
						// Ensure the caret stays in view (unless there's active selection)
						if (!_textEditor.hasSelection && _textEditor.caretLineIndex < _textEditor.lineScrollY + 1) {
							var newLineIndex = _textEditor.lineScrollY + 1;
							_textEditor.setSelectionAdvanced(newLineIndex, _textEditor.expandedCaretCharIndex, newLineIndex,
								_textEditor.expandedCaretCharIndex, false);
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
			case Keyboard.PAGE_DOWN:
				if (_textEditor.hasSelection && !event.shiftKey) {
					_textEditor.removeSelection();
				}

				if (event.ctrlKey) {
					var newLineIndex = _textEditor.lineScrollY + _textEditor.visibleLines - 2;
					if (event.shiftKey) {
						_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, newLineIndex, _textEditor.caretCharIndex);
					} else {
						_textEditor.setSelectionAdvanced(newLineIndex, _textEditor.expandedCaretCharIndex, newLineIndex, _textEditor.expandedCaretCharIndex,
							false);
					}
				} else {
					var newLineIndex = Std.int(Math.min(_textEditor.caretLineIndex + _textEditor.visibleLines, _textEditor.lines.length - 1));
					if (event.shiftKey) {
						_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, newLineIndex, _textEditor.caretCharIndex);
					} else {
						_textEditor.setSelectionAdvanced(newLineIndex, _textEditor.expandedCaretCharIndex, newLineIndex, _textEditor.expandedCaretCharIndex,
							false);
					}
					_textEditor.lineScrollY += _textEditor.visibleLines;
				}

			case Keyboard.PAGE_UP:
				if (_textEditor.hasSelection && !event.shiftKey) {
					_textEditor.removeSelection();
				}

				if (event.ctrlKey) {
					var newLineIndex = _textEditor.lineScrollY;
					if (event.shiftKey) {
						_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, newLineIndex, _textEditor.caretCharIndex);
					} else {
						_textEditor.setSelectionAdvanced(newLineIndex, _textEditor.expandedCaretCharIndex, newLineIndex, _textEditor.expandedCaretCharIndex,
							false);
					}
				} else {
					var newLineIndex = Std.int(Math.max(_textEditor.caretLineIndex - _textEditor.visibleLines, 0));
					if (event.shiftKey) {
						_textEditor.setSelection(selectionStartLineIndex, selectionStartCharIndex, newLineIndex, _textEditor.caretCharIndex);
					} else {
						_textEditor.setSelectionAdvanced(newLineIndex, _textEditor.expandedCaretCharIndex, newLineIndex, _textEditor.expandedCaretCharIndex,
							false);
					}
					_textEditor.lineScrollY = _textEditor.lineScrollY - _textEditor.visibleLines;
				}

			case Keyboard.HOME:
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
			case Keyboard.END:
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
			default:
				// Unflag as processed if nothing matched
				processed = false;
		}
		if (processed) {
			event.preventDefault();
			_textEditor.scrollViewIfNeeded();
		}
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

		var rdr:TextLineRenderer = null;
		var current = cast(event.target, DisplayObject);
		while (current != null) {
			if ((current is TextLineRenderer)) {
				rdr = cast(current, TextLineRenderer);
				break;
			}
			current = current.parent;
		}
		if (rdr == null) {
			return;
		}

		var newCaretPosition = rdr.getSelectionCharIndexAtPoint(rdr.mouseX, rdr.mouseY);
		var safeBreakpointHitAreaSize = _textEditor.lineNumberWidth - 4.0;
		if (newCaretPosition != -1) {
			if (_clickCount == 1) {
				startLine = event.shiftKey ? _textEditor.hasSelection ? _textEditor.selectionStartLineIndex : _textEditor.caretLineIndex : rdr.lineIndex;
				startChar = event.shiftKey ? _textEditor.hasSelection ? _textEditor.selectionStartCharIndex : _textEditor.caretCharIndex : newCaretPosition;

				endLine = rdr.lineIndex;
				endChar = newCaretPosition;
			} else if (_clickCount == 2) {
				startLine = endLine = rdr.lineIndex;

				startChar = newCaretPosition - TextUtil.wordBoundaryBackward(_textEditor.lines.get(startLine).text.substring(0, newCaretPosition));
				endChar = newCaretPosition + TextUtil.wordBoundaryForward(_textEditor.lines.get(endLine).text.substring(newCaretPosition));
				if (_textEditor.lines.get(endLine).text.charAt(endChar - 1) == " ") {
					endChar--;
				}
			} else if (_clickCount == 3) {
				startLine = endLine = rdr.lineIndex;

				startChar = 0;
				endChar = _textEditor.lines.get(startLine).text.length;
			}
		} else if (localPoint.x < safeBreakpointHitAreaSize && localPoint.x > 16.0) {
			startLine = event.shiftKey ? _textEditor.hasSelection ? _textEditor.selectionStartLineIndex : _textEditor.caretLineIndex : rdr.lineIndex;
			startChar = event.shiftKey ? _textEditor.hasSelection ? _textEditor.selectionStartCharIndex : _textEditor.caretCharIndex : 0;

			endLine = rdr.lineIndex + (event.shiftKey
				&& (startLine > rdr.lineIndex || startLine == rdr.lineIndex && startChar > 0) ? 0 : 1);
			endChar = 0;

			if (endLine >= _textEditor.lines.length) {
				endLine = _textEditor.lines.length - 1;
				endChar = _textEditor.lines.get(endLine).text.length;
			}
		} else {
			return;
		}

		_textEditor.setSelection(startLine, startChar, endLine, endChar);

		_dragStartLine = startLine;
		_dragStartChar = startChar;
		_dragEndChar = endChar;
		_dragLocalPoint = localPoint;
		_textEditor.stage.addEventListener(MouseEvent.MOUSE_MOVE, selectionManager_stage_mouseMoveHandler, false, 0, true);
		_textEditor.stage.addEventListener(MouseEvent.MOUSE_UP, selectionManager_stage_mouseUpHandler, false, 0, true);
		// editor.addEventListener(LayoutEvent.LAYOUT, handleEditorLayout);
		// dispatcher.addEventListener(OpenFileEvent.OPEN_FILE, handleOpenFile);

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
		/*editor.removeEventListener(LayoutEvent.LAYOUT, handleEditorLayout);
			dispatcher.removeEventListener(OpenFileEvent.OPEN_FILE, handleOpenFile); */
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
