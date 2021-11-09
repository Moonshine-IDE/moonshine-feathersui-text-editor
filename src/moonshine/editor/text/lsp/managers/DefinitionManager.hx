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

import moonshine.editor.text.events.TextEditorChangeEvent;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageRequestEvent;
import moonshine.editor.text.utils.LspTextEditorUtil;
import moonshine.lsp.DefinitionParams;
import moonshine.lsp.Location;
import moonshine.lsp.LocationLink;
import moonshine.lsp.Position;
import openfl.Lib;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.ui.Keyboard;

/**
	Used internally by `LspTextEditor` to manage definition requests.
**/
class DefinitionManager {
	/**
		Creates a new `DefinitionManager` object.
	**/
	public function new(textEditor:LspTextEditor, definitionCallback:(Position, Array<LocationLink>) -> Void,
			definitionLinkCallback:(Position, Array<LocationLink>) -> Void) {
		_textEditor = textEditor;
		_definitionCallback = definitionCallback;
		_definitionLinkCallback = definitionLinkCallback;

		_textEditor.addEventListener(Event.REMOVED_FROM_STAGE, definitionManager_textEditor_removedFromStageHandler, false, 0, true);
		_textEditor.addEventListener(MouseEvent.MOUSE_MOVE, definitionManager_textEditor_mouseMoveHandler, false, 0, true);
		_textEditor.addEventListener(MouseEvent.ROLL_OVER, definitionManager_textEditor_onRollOver, false, 0, true);
		_textEditor.addEventListener(MouseEvent.ROLL_OUT, definitionManager_textEditor_onRollOut, false, 0, true);
		_textEditor.addEventListener(TextEditorChangeEvent.TEXT_CHANGE, definitionManager_textEditor_textChangeHandler, false, 0, true);
	}

	private var _textEditor:LspTextEditor;
	private var _currentRequestID:Int = -1;
	private var _currentRequestParams:DefinitionParams;
	private var _requestTimeoutID:Int = -1;
	private var _definitionCallback:(Position, Array<LocationLink>) -> Void;
	private var _definitionLinkCallback:(Position, Array<LocationLink>) -> Void;
	private var _isOver = false;
	private var _ctrlKey = false;

	/**
		Sends a definition request.
	**/
	public function dispatchDefinitionEvent(params:DefinitionParams, link:Bool = false):Void {
		_requestTimeoutID = -1;
		if (params == null) {
			_currentRequestParams = null;
			clearDefinition();
			return;
		}
		incrementRequestID();
		var requestID = _currentRequestID;
		_currentRequestParams = params;
		_textEditor.dispatchEvent(new LspTextEditorLanguageRequestEvent(LspTextEditorLanguageRequestEvent.REQUEST_DEFINITION, params, result -> {
			handleDefinition(requestID, result, link);
		}));
	}

	private function incrementRequestID():Void {
		if (_currentRequestID == 10000) {
			// we don't want the counter to overflow into negative numbers
			// this should be a reasonable time to reset it
			_currentRequestID = -1;
		}
		_currentRequestID++;
	}

	private function handleDefinition(requestID:Int, result:Array<Any> /* Array<Location | LocationLink> */, link:Bool):Void {
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
		clearDefinition();

		if (_currentRequestParams == null) {
			// current request cancelled before a response was received
			return;
		}

		if (result == null || result.length == 0) {
			if (!link) {
				_definitionCallback(_currentRequestParams.position, []);
			}
			return;
		}

		var links:Array<LocationLink> = null;
		if (result != null) {
			links = result.map(item -> {
				if ((item is Location)) {
					var location = (item : Location);
					return new LocationLink(location.uri, location.range, location.range);
				}
				return cast(item, LocationLink);
			});
		}
		if (link) {
			_definitionLinkCallback(_currentRequestParams.position, links);
		} else {
			_definitionCallback(_currentRequestParams.position, links);
		}
	}

	private function stopRequestTimer():Void {
		if (_requestTimeoutID == -1) {
			return;
		}
		Lib.clearTimeout(_requestTimeoutID);
		_requestTimeoutID = -1;
	}

	private function startOrResetRequestTimer(pos:TextEditorPosition):Void {
		// the first time, do it quick
		var timeout = _requestTimeoutID == -1 ? 1 : 200;
		stopRequestTimer();
		_requestTimeoutID = Lib.setTimeout(() -> {
			var params:DefinitionParams = {
				textDocument: _textEditor.textDocument,
				position: LspTextEditorUtil.textEditorPositionToLspPosition(pos),
			};
			dispatchDefinitionEvent(params, true);
		}, timeout);
	}

	private function clearDefinition():Void {
		_definitionLinkCallback(null, null);
	}

	private function isInsideSameWord(cl1:Position, cl2:TextEditorPosition):Bool {
		if (cl1 == null || cl2 == null) {
			return false;
		}
		var line1 = cl1.line;
		var line2 = cl2.line;
		if (line1 != line2) {
			// can't be the same word on different lines
			return false;
		}
		var char1 = cl1.character;
		var char2 = cl2.character;
		if (char1 == char2) {
			// must be the same word when the character hasn't changed
			return true;
		}
		var line = _textEditor.lines.get(line1);
		var startIndex = char1;
		var endIndex = char2;
		if (startIndex > endIndex) {
			startIndex = char2;
			endIndex = char1;
		}
		if ((endIndex + 1) < line.text.length) {
			// include the later character when possible
			endIndex++;
		}
		// look for non-word characters between the two
		var substr = line.text.substr(startIndex, endIndex - startIndex);
		return ~/^\w+$/g.match(substr);
	}

	private function handleNewDefinitionLink():Void {
		if (!_ctrlKey) {
			_currentRequestParams = null;
			stopRequestTimer();
			clearDefinition();
			return;
		}
		var localXY = new Point(_textEditor.mouseX, _textEditor.mouseY);
		var pos = _textEditor.localToTextEditorPosition(localXY);
		if (pos == null) {
			_currentRequestParams = null;
			stopRequestTimer();
			clearDefinition();
			return;
		}
		if (_currentRequestParams != null && isInsideSameWord(_currentRequestParams.position, pos)) {
			// same word as before, so keep the previous request
			return;
		}
		_currentRequestParams = null;
		startOrResetRequestTimer(pos);
		clearDefinition();
	}

	private function definitionManager_textEditor_removedFromStageHandler(event:Event):Void {
		clearDefinition();
	}

	private function definitionManager_textEditor_mouseMoveHandler(event:MouseEvent):Void {
		_ctrlKey = event.ctrlKey;
		handleNewDefinitionLink();
	}

	private function definitionManager_textEditor_onRollOver(event:MouseEvent):Void {
		_isOver = true;
		_ctrlKey = event.ctrlKey;
		_textEditor.stage.addEventListener(KeyboardEvent.KEY_DOWN, definitionManager_textEditor_stage_keyDownHandler, false, 0, true);
		_textEditor.stage.addEventListener(KeyboardEvent.KEY_UP, definitionManager_textEditor_stage_keyUpHandler, false, 0, true);
		handleNewDefinitionLink();
	}

	private function definitionManager_textEditor_onRollOut(event:MouseEvent):Void {
		_textEditor.stage.removeEventListener(KeyboardEvent.KEY_DOWN, definitionManager_textEditor_stage_keyDownHandler);
		_textEditor.stage.removeEventListener(KeyboardEvent.KEY_UP, definitionManager_textEditor_stage_keyUpHandler);
		_isOver = false;
		_currentRequestParams = null;
		stopRequestTimer();
		clearDefinition();
	}

	private function definitionManager_textEditor_stage_keyDownHandler(event:KeyboardEvent):Void {
		if (!_isOver) {
			return;
		}
		if (event.keyCode != Keyboard.CONTROL && event.keyCode != Keyboard.COMMAND) {
			return;
		}
		var oldCtrlKey = _ctrlKey;
		_ctrlKey = true;
		if (oldCtrlKey == _ctrlKey) {
			return;
		}
		handleNewDefinitionLink();
	}

	private function definitionManager_textEditor_stage_keyUpHandler(event:KeyboardEvent):Void {
		if (!_isOver) {
			return;
		}
		if (event.keyCode != Keyboard.CONTROL && event.keyCode != Keyboard.COMMAND) {
			return;
		}
		var oldCtrlKey = _ctrlKey;
		_ctrlKey = false;
		if (oldCtrlKey == _ctrlKey) {
			return;
		}
		clearDefinition();
	}

	private function definitionManager_textEditor_textChangeHandler(event:TextEditorChangeEvent):Void {
		clearDefinition();
	}
}
