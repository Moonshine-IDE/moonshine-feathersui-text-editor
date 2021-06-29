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

class FindReplaceManager {
	public function new(textEditor:TextEditor) {
		_textEditor = textEditor;

		_textEditor.addEventListener(TextEditorChangeEvent.TEXT_CHANGE, findReplaceManager_textEditor_textChangeHandler);
	}

	private var _textEditor:TextEditor;

	private var _findResult:TextEditorSearchResult;

	public function find(search:Any /* EReg | String */, backwards:Bool = false, allowWrap:Bool = true, updateSelection:Bool = true):TextEditorSearchResult {
		// Get string once (it's built dynamically)
		var str = _textEditor.text;

		var searchRegExp = (search is EReg) ? (search : EReg) : null;
		if (searchRegExp == null && search != null) {
			var searchStr = Std.string(search);
			if (searchStr.length > 0) {
				searchRegExp = new EReg(EReg.escape(searchStr), "i");
			}
		}

		var results = findInternal(str, searchRegExp);
		_findResult = new TextEditorSearchResult(searchRegExp, backwards, allowWrap, results);
		if (results.length == 0) {
			if (updateSelection) {
				_textEditor.removeSelection();
			}
			return _findResult;
		}

		_findResult = findNextInternal(_findResult, backwards, true, allowWrap);
		if (updateSelection) {
			applySearch(_findResult);
		}
		return _findResult;
	}

	public function findNext(backwards:Bool = false, allowWrap:Bool = true):TextEditorSearchResult {
		if (_findResult == null) {
			return new TextEditorSearchResult(null, backwards, allowWrap);
		}
		_findResult = findNextInternal(_findResult, backwards, false, allowWrap);
		applySearch(_findResult);
		return _findResult;
	}

	public function replace(replaceText:String, all:Bool = false, backwards:Bool = false, allowWrap:Bool = true):TextEditorSearchResult {
		if (_findResult == null) {
			return new TextEditorSearchResult(null, backwards, allowWrap);
		}
		var str = _textEditor.text;

		var changes:Array<TextEditorChange> = [];
		if (all) {
			for (result in _findResult.results) {
				addChangesForReplace(str, replaceText, result, changes);
			}
			_findResult.replaced = _findResult.results.copy();
			_findResult.results.resize(0);
		} else {
			var replaced = _findResult.results.splice(_findResult.selectedIndex, 1);
			_findResult.replaced = replaced;
			addChangesForReplace(str, replaceText, replaced[0], changes);
		}
		_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, changes));
		return _findResult;
	}

	private function findInternal(str:String, searchRegExp:EReg, posOffset:Int = 0):Array<{pos:Int, len:Int}> {
		var results:Array<{pos:Int, len:Int}> = [];
		if (searchRegExp != null) {
			// Find all occurances
			var startIndex = 0;
			while (searchRegExp.matchSub(str, startIndex)) {
				if (searchRegExp.matched(0) != null) { // match return infinite string for somekind of regexp like /L*/ /?*/
					var match = searchRegExp.matchedPos();
					startIndex = match.pos + match.len;
					match.pos += posOffset;
					results.push(match);
				} else {
					break;
				}
			}
		}
		return results;
	}

	private function findNextInternal(res:TextEditorSearchResult, backwards:Bool = false, includeCurrent:Bool = false,
			allowWrap:Bool = true):TextEditorSearchResult {
		var str = _textEditor.text;

		// Starting point for search
		var startLine = _textEditor.hasSelection ? _textEditor.selectionStartLineIndex : _textEditor.caretLineIndex;
		var startChar = _textEditor.hasSelection ? _textEditor.selectionStartCharIndex : _textEditor.caretCharIndex;
		var startPos = TextUtil.lineCharIdx2charIdx(str, startLine, startChar, _textEditor.lineDelimiter);

		var results = res.results;
		var newSelectedIndex = -1;
		var wrapped = false;

		// Figure out which one we want to select
		if (backwards) {
			var i = Std.int(Math.min(results.length - 1, res.selectedIndex - 1));
			while (i >= 0) {
				var current = results[i];
				if (current.pos < startPos) {
					newSelectedIndex = i;
					break;
				}
				i--;
			}
		} else {
			for (i in (res.selectedIndex + 1)...results.length) {
				var current = results[i];
				if (includeCurrent) {
					if (current.pos >= startPos) {
						newSelectedIndex = i;
						break;
					}
				} else {
					if (current.pos > startPos) {
						newSelectedIndex = i;
						break;
					}
				}
			}
		}

		if (allowWrap) {
			// No match, wrap search
			if (newSelectedIndex == -1 && results.length != 0) {
				if (backwards) {
					newSelectedIndex = results.length - 1;
				} else {
					newSelectedIndex = 0;
				}
				wrapped = true;
			}
		}

		res.replaced.resize(0);
		if (newSelectedIndex == -1) {
			return res;
		}
		res.selectedIndex = newSelectedIndex;
		updatePositionFromSelectedIndex(res);
		return res;
	}

	private function addChangesForReplace(str:String, replace:String, result:{pos:Int, len:Int}, changes:Array<TextEditorChange>):Void {
		// Map to 2D
		var lc = TextUtil.charIdx2LineCharIdx(str, result.pos, _textEditor.lineDelimiter);
		var lineIndex = Std.int(lc.x);
		var startCharIndex = Std.int(lc.y);
		var endCharIndex = Std.int(lc.y) + result.len;

		changes.push(new TextEditorChange(lineIndex, startCharIndex, lineIndex, endCharIndex, replace));
	}

	// Map to TextEditor internal representation
	private function applySearch(s:TextEditorSearchResult):Void {
		_textEditor.setSelection(s.startLineIndex, s.startCharIndex, s.endLineIndex, s.endCharIndex);

		_textEditor.scrollViewIfNeeded();
		_textEditor.lines.updateAll();
	}

	private function updatePositionFromSelectedIndex(res:TextEditorSearchResult):Void {
		if (res.selectedIndex == -1) {
			res.startLineIndex = -1;
			res.startCharIndex = -1;
			res.endLineIndex = -1;
			res.endCharIndex = -1;
			return;
		}
		var match = res.results[res.selectedIndex];
		var lc = TextUtil.charIdx2LineCharIdx(_textEditor.text, match.pos, _textEditor.lineDelimiter);
		res.startLineIndex = Std.int(lc.x);
		res.endLineIndex = Std.int(lc.x);
		res.startCharIndex = Std.int(lc.y);
		res.endCharIndex = Std.int(lc.y) + match.len;
	}

	private function findReplaceManager_textEditor_textChangeHandler(event:TextEditorChangeEvent):Void {
		if (_findResult == null) {
			return;
		}
		find(_findResult.search, _findResult.backwards, _findResult.allowWrap, false);
	}
}
