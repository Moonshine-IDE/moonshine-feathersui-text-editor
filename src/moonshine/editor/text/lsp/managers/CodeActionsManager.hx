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

package moonshine.editor.text.lsp.managers;

import feathers.core.PopUpManager;
import feathers.events.ScrollEvent;
import moonshine.editor.text.events.TextEditorEvent;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageRequestEvent;
import moonshine.editor.text.lsp.views.CodeActionsView;
import moonshine.editor.text.utils.LspTextEditorUtil;
import moonshine.lsp.CodeAction;
import moonshine.lsp.CodeActionKind;
import moonshine.lsp.CodeActionParams;
import moonshine.lsp.Range;
import moonshine.lsp.utils.RangeUtil;
import openfl.Lib;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.geom.Rectangle;
import openfl.ui.Keyboard;

class CodeActionsManager {
	public function new(textEditor:LspTextEditor, codeActionCallback:(CodeAction) -> Void) {
		_textEditor = textEditor;

		_codeActionsView = new CodeActionsView();
		_codeActionsView.codeActionCallback = codeActionCallback;

		_textEditor.addEventListener(Event.REMOVED_FROM_STAGE, codeActionsManager_textEditor_removedFromStageHandler, false, 0, true);
		_textEditor.addEventListener(KeyboardEvent.KEY_DOWN, codeActionsManager_textEditor_keyDownHandler, false, 0, true);
		_textEditor.addEventListener(TextEditorEvent.SELECTION_CHANGE, codeActionsManager_textEditor_selectionChangeHandler, false, 0, true);
		_textEditor.addEventListener(FocusEvent.FOCUS_IN, codeActionsManager_textEditor_focusInHandler, false, 0, true);
		_textEditor.addEventListener(ScrollEvent.SCROLL, codeActionsManager_textEditor_scrollHandler, false, 0, true);
	}

	public var shortcutRequiresCtrl:Bool = true;
	public var shortcutRequiresAlt:Bool = false;
	public var shortcutRequiresShift:Bool = false;
	public var shortcutRequiresCommand:Bool = false;
	public var shortcutRequiresControl:Bool = false;
	public var shortcutKey:UInt = Keyboard.PERIOD;

	private var _textEditor:LspTextEditor;
	private var _currentRequestID:Int = -1;
	private var _currentRequestParams:CodeActionParams;
	private var _currentOpenOnResponse:Bool = false;
	private var _requestTimeoutID:Int = -1;
	private var _codeActionsView:CodeActionsView;

	public function clear():Void {
		_currentRequestID = -1;
		closeCodeActionsView();
	}

	private function handleCodeActions(requestID:Int, result:Array<CodeAction>):Void {
		if (requestID != _currentRequestID) {
			// a newer request has taken precedence over this request
			return;
		}
		if (_textEditor.stage == null) {
			// a request could have been sent before removal that hadn't yet
			// received a response
			return;
		}
		// this shouldn't happen, but clean things up... just in case
		closeCodeActionsView();

		if (_currentRequestParams == null) {
			// current request cancelled before a response was received
			return;
		}

		var pos = _currentRequestParams.range.start;
		if (pos.line < 0 || pos.line >= _textEditor.lines.length) {
			// just in case we get a result that is out of range
			return;
		}

		if (result == null || result.length == 0) {
			return;
		}

		result = result.filter(codeAction -> {
			// we don't display this one in the light bulb
			return codeAction.kind != CodeActionKind.SourceOrganizeImports;
		});
		if (result.length == 0) {
			// we filtered out everything
			return;
		}

		if (_currentOpenOnResponse) {
			_codeActionsView.visible = false;
			_codeActionsView.height = 0;
		} else {
			_codeActionsView.visible = true;
			_codeActionsView.resetHeight();
		}

		_codeActionsView.codeActions = result;
		PopUpManager.addPopUp(_codeActionsView, _textEditor, false, false);
		_codeActionsView.validateNow();

		positionCodeActionsView();

		if (_currentOpenOnResponse) {
			_codeActionsView.openList();
		}
	}

	private function positionCodeActionsView():Void {
		var pos = _currentRequestParams.range.start;
		var indexToProtect = pos.character;
		var line = _textEditor.lines.get(pos.line);
		var text = line.text;
		var charBounds:Rectangle;

		if (_currentOpenOnResponse) {
			charBounds = _textEditor.getTextEditorPositionBoundaries(new TextEditorPosition(pos.line, pos.character));
		} else {
			charBounds = _textEditor.getTextEditorPositionBoundaries(new TextEditorPosition(pos.line, 0));
			var nonWhitespaceRegex = ~/\S/;
			if (nonWhitespaceRegex.match(text)) {
				var firstNonWhitepaceIndex = nonWhitespaceRegex.matchedPos().pos;
				if (indexToProtect > firstNonWhitepaceIndex) {
					indexToProtect = firstNonWhitepaceIndex;
				}
			}
		}
		var point = charBounds.topLeft;
		if (_currentOpenOnResponse) {
			point.y += charBounds.height;
		} else {
			var indexToProtectBounds:Rectangle = null;
			if (indexToProtect < text.length) {
				indexToProtectBounds = _textEditor.getTextEditorPositionBoundaries(new TextEditorPosition(pos.line, indexToProtect));
			} else if (indexToProtect == 0) {
				indexToProtectBounds = new Rectangle(0.0, 0.0, 0.0, charBounds.height);
			}
			if (indexToProtectBounds != null && (indexToProtectBounds.x - charBounds.x) < _codeActionsView.width) {
				// don't cover any text that appears at the beginning of
				// the line. if it overlaps, move to previous line.
				point.y -= charBounds.height;
				if (point.y < 0.0) {
					point.y += charBounds.height * 2.0;
				}
			}
		}

		var visible = true;
		if (point.y < 0.0) {
			visible = point.y > -(charBounds.height / 2.0);
			point.y = 0.0;
		} else if ((point.y + _codeActionsView.height) > _textEditor.height) {
			visible = point.y < (_textEditor.height - charBounds.height / 2.0);
			point.y = _textEditor.height - _codeActionsView.height;
		}
		point = _textEditor.localToGlobal(point);
		var popUpRoot = (_textEditor.stage != null) ? PopUpManager.forStage(_textEditor.stage).root : null;
		if (popUpRoot != null) {
			point = popUpRoot.globalToLocal(point);
		}
		_codeActionsView.x = point.x;
		_codeActionsView.y = point.y;
		_codeActionsView.visible = visible;
	}

	private function stopRequestTimer():Void {
		if (_requestTimeoutID == -1) {
			return;
		}
		Lib.clearTimeout(_requestTimeoutID);
		_requestTimeoutID = -1;
	}

	private function startOrResetRequestTimer(pos:TextEditorPosition):Void {
		// we want to "debounce" this event, so reset the timer, if necessary
		stopRequestTimer();
		_requestTimeoutID = Lib.setTimeout(() -> {
			dispatchCodeActionsEventForPosition(pos);
		}, 250);
	}

	private function dispatchCodeActionsEventForPosition(pos:TextEditorPosition, open:Bool = false):Void {
		var lspPos = LspTextEditorUtil.textEditorPositionToLspPosition(pos);
		var lspRange = new Range(lspPos, lspPos);
		var params:CodeActionParams = {
			textDocument: _textEditor.textDocument,
			range: lspRange,
			context: {
				diagnostics: (_textEditor.diagnostics != null) ? _textEditor.diagnostics.filter(diagnostic -> {
					return RangeUtil.rangesIntersect(lspRange, diagnostic.range);
				}) : []
			}
		};
		dispatchCodeActionsEvent(params, open);
	}

	public function dispatchCodeActionsEvent(params:CodeActionParams, open:Bool = false):Void {
		_requestTimeoutID = -1;
		if (params == null) {
			_currentRequestParams = null;
			closeCodeActionsView();
			return;
		}
		if (_currentRequestID == 10000) {
			// we don't want the counter to overflow into negative numbers
			// this should be a reasonable time to reset it
			_currentRequestID = -1;
		}
		_currentRequestID++;
		var requestID = _currentRequestID;
		_currentRequestParams = params;
		_currentOpenOnResponse = open;
		_textEditor.dispatchEvent(new LspTextEditorLanguageRequestEvent(LspTextEditorLanguageRequestEvent.REQUEST_CODE_ACTIONS, params, result -> {
			handleCodeActions(requestID, result);
		}));
	}

	private function closeCodeActionsView():Void {
		if (!PopUpManager.isTopLevelPopUp(_codeActionsView)) {
			return;
		}
		PopUpManager.removePopUp(_codeActionsView);
	}

	private function newRequest():Void {
		if (_textEditor.hasSelection) {
			_currentRequestParams = null;
			stopRequestTimer();
			closeCodeActionsView();
			return;
		}
		var pos = new TextEditorPosition(_textEditor.caretLineIndex, _textEditor.caretCharIndex);
		startOrResetRequestTimer(pos);
		closeCodeActionsView();
	}

	private function codeActionsManager_textEditor_removedFromStageHandler(event:Event):Void {
		closeCodeActionsView();
	}

	private function codeActionsManager_textEditor_selectionChangeHandler(event:TextEditorEvent):Void {
		newRequest();
	}

	private function codeActionsManager_textEditor_focusInHandler(event:FocusEvent):Void {
		newRequest();
	}

	private function codeActionsManager_textEditor_keyDownHandler(event:KeyboardEvent):Void {
		if (event.isDefaultPrevented()) {
			return;
		}

		if (event.keyCode != shortcutKey
			|| (shortcutRequiresCtrl && !event.ctrlKey)
			|| (shortcutRequiresShift && !event.shiftKey)
			|| (!shortcutRequiresShift && event.shiftKey)
			|| (shortcutRequiresAlt && !event.altKey)
			|| (!shortcutRequiresAlt && event.altKey)
			|| (shortcutRequiresCommand && !event.commandKey)
			|| (shortcutRequiresControl && !event.controlKey)) {
			return;
		}
		event.preventDefault();
		var pos = new TextEditorPosition(_textEditor.caretLineIndex, _textEditor.caretCharIndex);
		dispatchCodeActionsEventForPosition(pos, true);
	}

	private function codeActionsManager_textEditor_scrollHandler(event:ScrollEvent):Void {
		if (!PopUpManager.isTopLevelPopUp(_codeActionsView)) {
			return;
		}
		positionCodeActionsView();
	}
}
