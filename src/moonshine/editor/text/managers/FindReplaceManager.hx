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

import moonshine.editor.text.TextEditorSearchResult.SearchResultItem;
import moonshine.editor.text.changes.TextEditorChange;
import moonshine.editor.text.events.TextEditorChangeEvent;
import moonshine.editor.text.utils.TextUtil;

/**
	Used internally by `TextEditor` to manage find and replace actions.
**/
class FindReplaceManager {
	/**
		Creates a new `FindReplaceManager` object.
	**/
	public function new(textEditor:TextEditor) {
		_textEditor = textEditor;

		_textEditor.addEventListener(TextEditorChangeEvent.TEXT_CHANGE, findReplaceManager_textEditor_textChangeHandler);
	}

	private var _textEditor:TextEditor;

	private var _findResult:TextEditorSearchResult;

	/**
		Performs a find action.
	**/
	public function find(search:Any /* EReg | String */, backwards:Bool = false, allowWrap:Bool = true, updateSelection:Bool = true):TextEditorSearchResult {
		// Get string once (it's built dynamically)
		var str = _textEditor.text;

		#if flash
		if ((search is flash.utils.RegExp)) {
			var r = Std.string(search);
			var endIndex = r.lastIndexOf("/");
			var opt = r.substr(endIndex + 1);
			r = r.substr(1, endIndex - 1);
			search = new EReg(r, opt);
		}
		#end
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

	/**
		Performs a find next action. Must call `find()` first.
	**/
	public function findNext(backwards:Bool = false, allowWrap:Bool = true):TextEditorSearchResult {
		if (_findResult == null) {
			return new TextEditorSearchResult(null, backwards, allowWrap);
		}
		_findResult = findNextInternal(_findResult, backwards, false, allowWrap);
		applySearch(_findResult);
		return _findResult;
	}

	/**
		Performs a replace (one or all) action. Must call `find()` first.
	**/
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
		applySearch(_findResult);
		return _findResult;
	}

	private function findInternal(str:String, searchRegExp:EReg):Array<SearchResultItem> {
		var results:Array<SearchResultItem> = [];
		if (searchRegExp != null) {
			// Find all occurances
			var startIndex = 0;
			while (searchRegExp.matchSub(str, startIndex)) {
				if (searchRegExp.matched(0) != null) { // match return infinite string for somekind of regexp like /L*/ /?*/
					var match = searchRegExp.matchedPos();
					startIndex = match.pos + match.len;
					var start = TextUtil.charIdx2LineCharIdx(str, match.pos, _textEditor.lineDelimiter);
					results.push({
						index: match.pos,
						length: match.len,
						startLine: start.line,
						startChar: start.character,
						endLine: start.line,
						endChar: start.character + match.len
					});
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
				if (current.index < startPos) {
					newSelectedIndex = i;
					break;
				}
				i--;
			}
		} else {
			for (i in (res.selectedIndex + 1)...results.length) {
				var current = results[i];
				if (includeCurrent) {
					if (current.index >= startPos) {
						newSelectedIndex = i;
						break;
					}
				} else {
					if (current.index > startPos) {
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
		if (res.selectedIndex == -1) {
			res.current = null;
		} else {
			res.current = res.results[res.selectedIndex];
		}
		return res;
	}

	private function addChangesForReplace(str:String, replace:String, result:SearchResultItem, changes:Array<TextEditorChange>):Void {
		changes.push(new TextEditorChange(result.startLine, result.startChar, result.endLine, result.endChar, replace));
	}

	// Map to TextEditor internal representation
	private function applySearch(result:TextEditorSearchResult):Void {
		var startLine = -1;
		var startChar = -1;
		var endLine = -1;
		var endChar = -1;
		var current = result.current;
		if (current != null) {
			startLine = current.startLine;
			startChar = current.startChar;
			endLine = current.endLine;
			endChar = current.endChar;
		}
		_textEditor.setSelection(startLine, startChar, endLine, endChar);
		_textEditor.scrollToCaret();
	}

	private function findReplaceManager_textEditor_textChangeHandler(event:TextEditorChangeEvent):Void {
		if (_findResult == null) {
			return;
		}
		find(_findResult.search, _findResult.backwards, _findResult.allowWrap, false);
	}
}
