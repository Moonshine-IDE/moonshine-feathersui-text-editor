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
import moonshine.editor.text.syntax.parser.ILineParser;
import openfl.Lib;
import openfl.events.Event;

/**
	Used internally by `TextEditor` to manage syntax highlighting for the
	language of the currently displayed file.
**/
class ColorManager {
	private static final CHUNK_TIMESPAN:Int = 16;

	/**
		Creates a new `ColorManager` object.
	**/
	public function new(textEditor:TextEditor) {
		_textEditor = textEditor;

		_textEditor.addEventListener(TextEditorChangeEvent.TEXT_CHANGE, colorManager_textEditor_textChangeHandler, false, 0, true);
	}

	private var _textEditor:TextEditor;

	private var _parser:ILineParser;

	/**
		The parser used to determine text styles for the current file.
	**/
	@:flash.property
	public var parser(get, set):ILineParser;

	private function get_parser():ILineParser {
		return _parser;
	}

	private function set_parser(value:ILineParser):ILineParser {
		if (_parser == value) {
			return _parser;
		}
		_parser = value;
		reset();
		return _parser;
	}

	private var _ranges:Array<LineRange> = [];
	private var _listening = false;

	/**
		Clears all syntax highlighting in the current file and recalculates.
	**/
	public function reset():Void {
		_ranges.resize(0);
		invalidate(0, _textEditor.lines.length - 1);
	}

	private function invalidate(line:Int, addCount:Int = 0, silent:Bool = false):Void {
		var merged = false;

		var r = _ranges.length - 1;
		while (r >= 0) {
			var range = _ranges[r];

			if (range.end < line) {
				break;
			}

			if (range.start > line) {
				range.start += addCount;
				range.end += addCount;
			} else {
				merged = true;
				range.end += addCount;
				break;
			}
			r--;
		}

		if (!merged) {
			_ranges.insert(r + 1, new LineRange(line, line + addCount));
		}

		if (!_listening && !silent) {
			startListening();
			process();
		}
	}

	private function process():Void {
		var count = _textEditor.lines.length;
		var timeLimit = Lib.getTimer() + CHUNK_TIMESPAN;

		while (_ranges.length > 0) {
			var range = _ranges[0];
			var rangeStart = range.start;
			var rangeEnd = range.end;

			if (_parser != null) {
				var prevLine = (rangeStart > 0) ? _textEditor.lines.get(rangeStart - 1) : null;
				var prevEndContext = getEndContext((prevLine != null) ? prevLine.styleRanges : null);
				_parser.setContext(prevEndContext);
			}

			for (i in rangeStart...(rangeEnd + 1)) {
				var line = _textEditor.lines.get(i);

				// Parse file for coloring
				var oldMeta = line.styleRanges;
				// the actual line delimiter doesn't matter here and it won't
				// affect the contents of the file
				var newMeta = (_parser != null) ? _parser.parse(line.text + "\n", i, 0, i, line.text.length) : null;

				// Notify the editor of change, to invalidate lines if needed
				if (oldMeta == null || newMeta == null || oldMeta.join(",") != newMeta.join(",")) {
					line.styleRanges = newMeta;
					#if (feathersui >= "1.2.0")
					_textEditor.lines.updateAt(i);
					#end
				}

				if (i == rangeEnd && i < (count - 1)) {
					// Invalidate next line if its start context doesn't match up with this one's end context
					var endContext = getEndContext(line.styleRanges);
					var nextLine = _textEditor.lines.get(i + 1);
					var startContext = getStartContext(nextLine.styleRanges);
					if (endContext != startContext) {
						invalidate(i + 1);
					}
				}

				if (Lib.getTimer() > timeLimit) {
					if (i == rangeEnd) {
						_ranges.shift();
					} else {
						range.start = i + 1;
					}

					return;
				}
			}

			_ranges.shift();
		}

		#if (feathersui < "1.2.0")
		@:privateAccess _textEditor.invalidateVisibleLines();
		#end
		stopListening();
	}

	private function getStartContext(styleRanges:Array<Int>):Int {
		if (styleRanges != null && styleRanges.length > 1) {
			return styleRanges[1];
		}
		if (_parser != null) {
			return _parser.defaultContext;
		}
		return 0;
	}

	private function getEndContext(styleRanges:Array<Int>):Int {
		if (styleRanges != null && styleRanges.length > 1) {
			return styleRanges[styleRanges.length - 1];
		}
		if (_parser != null) {
			return _parser.defaultContext;
		}
		return 0;
	}

	private function applyChange(change:TextEditorChange):Void {
		applyChangeRemove(change);
		if (change.newText != null) {
			applyChangeInsert(change);
		}
		if (_ranges.length == 0) {
			stopListening();
		} else if (!_listening) {
			startListening();
			process();
		}
	}

	private function applyChangeInsert(change:TextEditorChange):Void {
		var numLines = ~/\r?\n|\r/g.split(change.newText).length;
		invalidate(change.startLine, numLines - 1, true);
	}

	private function applyChangeRemove(change:TextEditorChange):Void {
		var r = _ranges.length - 1;
		while (r >= 0) {
			var range = _ranges[r];

			if (change.startLine > range.end) {
				break;
			} else {
				var lines = Std.int(Math.min(change.endLine, range.end)) - change.startLine;

				range.start = Std.int(Math.min(range.start, change.startLine));
				range.end -= lines;

				if (range.end < range.start) {
					_ranges.splice(r, 1);
				}
			}
			r--;
		}

		if (change.startLine != change.endLine || change.startChar != change.endChar) {
			invalidate(change.startLine, 0, true);
		}
	}

	private function startListening():Void {
		if (_listening) {
			return;
		}
		_listening = true;
		_textEditor.addEventListener(Event.ENTER_FRAME, colorManager_textEditor_enterFrameHandler, false, 0, true);
	}

	private function stopListening():Void {
		if (!_listening) {
			return;
		}
		_listening = false;
		_textEditor.removeEventListener(Event.ENTER_FRAME, colorManager_textEditor_enterFrameHandler);
	}

	private function colorManager_textEditor_textChangeHandler(event:TextEditorChangeEvent):Void {
		if (_ranges.length == 0) {
			stopListening();
		} else if (!_listening) {
			startListening();
			process();
		}
		for (change in event.changes) {
			applyChange(change);
		}
	}

	private function colorManager_textEditor_enterFrameHandler(event:Event):Void {
		process();
	}
}

private class LineRange {
	public var start:Int;
	public var end:Int;

	public function new(start:Int, end:Int) {
		this.start = start;
		this.end = end;
	}
}
