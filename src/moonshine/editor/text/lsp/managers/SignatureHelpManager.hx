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

import feathers.controls.Application;
import feathers.core.PopUpManager;
import feathers.events.ScrollEvent;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageRequestEvent;
import moonshine.editor.text.lsp.views.SignatureHelpView;
import moonshine.editor.text.utils.LspTextEditorUtil;
import moonshine.lsp.Position;
import moonshine.lsp.SignatureHelp;
import moonshine.lsp.SignatureHelpParams;
import moonshine.lsp.SignatureHelpTriggerKind;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.TextEvent;
import openfl.geom.Point;
import openfl.ui.Keyboard;

class SignatureHelpManager {
	public function new(textEditor:LspTextEditor) {
		_textEditor = textEditor;

		_signatureHelpView = new SignatureHelpView();

		_textEditor.addEventListener(Event.REMOVED_FROM_STAGE, signatureHelpManager_textEditor_removedFromStageHandler, false, 0, true);
		_textEditor.addEventListener(ScrollEvent.SCROLL, signatureHelpManager_textEditor_scrollHandler, false, 0, true);
		_textEditor.addEventListener(KeyboardEvent.KEY_DOWN, signatureHelpManager_textEditor_keyDownHandler, false, 0, true);
		_textEditor.addEventListener(TextEvent.TEXT_INPUT, signatureHelpManager_textEditor_textInputHandler, false, 0, true);
		_textEditor.addEventListener(FocusEvent.FOCUS_OUT, signatureHelpManager_textEditor_focusOutHandler, false, 0, true);
	}

	public var shortcutRequiresCtrl:Bool = true;
	public var shortcutRequiresAlt:Bool = false;
	public var shortcutRequiresShift:Bool = true;
	public var shortcutRequiresCommand:Bool = false;
	public var shortcutRequiresControl:Bool = false;
	public var shortcutKey:UInt = Keyboard.SPACE;

	private var _textEditor:LspTextEditor;
	private var _currentRequestID:Int = -1;
	private var _currentRequestParams:SignatureHelpParams;
	private var _signatureHelpView:SignatureHelpView;

	public function clear():Void {
		_currentRequestID = -1;
		closeSignatureHelpView();
	}

	private function handleSignatureHelp(requestID:Int, result:SignatureHelp):Void {
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
		closeSignatureHelpView();

		if (_currentRequestParams == null) {
			// current request cancelled before a response was received
			return;
		}

		if (result == null || result.signatures == null || result.signatures.length == 0) {
			return;
		}

		_signatureHelpView.signatureHelp = result;
		_textEditor.stage.addEventListener(MouseEvent.MOUSE_DOWN, signatureHelpManager_textEditor_stage_mouseDownHandler, false, 0, true);
		PopUpManager.addPopUp(_signatureHelpView, _textEditor, false, false);

		positionSignatureHelpView();
	}

	private function dispatchSignatureHelpEventForCurrentPosition(?triggerChar:String):Void {
		var params:SignatureHelpParams = {
			textDocument: _textEditor.textDocument,
			position: new Position(_textEditor.caretLineIndex, _textEditor.caretCharIndex)
		}
		if (triggerChar != null) {
			params.context = {
				isRetrigger: false,
				triggerKind: SignatureHelpTriggerKind.TriggerCharacter,
				triggerCharacter: triggerChar
			};
		}
		dispatchSignatureHelpEvent(params);
	}

	public function dispatchSignatureHelpEvent(params:SignatureHelpParams):Void {
		if (_currentRequestID == 10000) {
			// we don't want the counter to overflow into negative numbers
			// this should be a reasonable time to reset it
			_currentRequestID = -1;
		}
		_currentRequestID++;
		var requestID = _currentRequestID;
		_currentRequestParams = params;
		_textEditor.dispatchEvent(new LspTextEditorLanguageRequestEvent(LspTextEditorLanguageRequestEvent.REQUEST_SIGNATURE_HELP, params, result -> {
			handleSignatureHelp(requestID, result);
		}));
	}

	private function positionSignatureHelpView():Void {
		_signatureHelpView.validateNow();

		var xy = _textEditor.textEditorPositionToLocal(LspTextEditorUtil.lspPositionToTextEditorPosition(_currentRequestParams.position));
		if (xy == null) {
			closeSignatureHelpView();
			return;
		}

		xy = _textEditor.localToGlobal(xy);
		var viewPortBounds = _textEditor.getViewPortVisibleBounds();
		var viewPortTopLeft = new Point(viewPortBounds.x, viewPortBounds.y);
		viewPortTopLeft = _textEditor.localToGlobal(viewPortTopLeft);
		var viewPortBottomRight = new Point(viewPortBounds.x + viewPortBounds.width, viewPortBounds.y + viewPortBounds.height);
		viewPortBottomRight = _textEditor.localToGlobal(viewPortBottomRight);
		var popUpRoot = (_textEditor.stage != null) ? PopUpManager.forStage(_textEditor.stage).root : null;
		if (popUpRoot != null) {
			xy = popUpRoot.globalToLocal(xy);
			viewPortTopLeft = popUpRoot.globalToLocal(viewPortTopLeft);
			viewPortBottomRight = popUpRoot.globalToLocal(viewPortBottomRight);
		}

		var maxAppX:Float = _textEditor.stage.stageWidth;
		var maxAppY:Float = _textEditor.stage.stageHeight;
		if (Application.topLevelApplication != null) {
			maxAppX = Application.topLevelApplication.width;
			maxAppY = Application.topLevelApplication.height;
		}
		maxAppX -= _signatureHelpView.width;
		maxAppY -= _signatureHelpView.height;

		_signatureHelpView.x = Math.max(Math.max(viewPortTopLeft.x, 0.0), Math.min(Math.min(viewPortBottomRight.x, maxAppX), xy.x));

		// start by trying to position it above the current line
		var yPosition = xy.y - _signatureHelpView.height;
		// when positioned above, don't let it go past the top of the app
		var minY = 0.0;
		// and don't let it go past the bottom of the editor
		var maxY = viewPortBottomRight.y - _signatureHelpView.height;
		if (yPosition < minY) {
			// if it doesn't fit above, try positioning it below
			yPosition = xy.y + _textEditor.lineHeight;
			// when positioned below, don't let it go past the top of the editor
			minY = viewPortTopLeft.y;
			// and don't let it go past the bottom of the app
			maxY = maxAppY;
		}
		if (yPosition > maxY) {
			yPosition = maxY;
		}
		if (yPosition < minY) {
			yPosition = minY;
		}
		_signatureHelpView.y = yPosition;
	}

	private function closeSignatureHelpView():Void {
		if (!PopUpManager.isTopLevelPopUp(_signatureHelpView)) {
			return;
		}
		PopUpManager.removePopUp(_signatureHelpView);
		_textEditor.stage.removeEventListener(MouseEvent.MOUSE_DOWN, signatureHelpManager_textEditor_stage_mouseDownHandler);
	}

	private function signatureHelpManager_textEditor_removedFromStageHandler(event:Event):Void {
		closeSignatureHelpView();
	}

	private function signatureHelpManager_textEditor_scrollHandler(event:ScrollEvent):Void {
		if (!PopUpManager.isTopLevelPopUp(_signatureHelpView)) {
			return;
		}
		positionSignatureHelpView();
	}

	private function signatureHelpManager_textEditor_keyDownHandler(event:KeyboardEvent):Void {
		if (event.isDefaultPrevented()) {
			return;
		}

		if (PopUpManager.isPopUp(_signatureHelpView)) {
			switch (event.keyCode) {
				case Keyboard.ESCAPE:
					closeSignatureHelpView();
					return;
				case Keyboard.BACKSPACE:
					dispatchSignatureHelpEventForCurrentPosition();
					return;
			}
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
		dispatchSignatureHelpEventForCurrentPosition();
	}

	private function signatureHelpManager_textEditor_textInputHandler(event:TextEvent):Void {
		if (event.isDefaultPrevented()) {
			return;
		}

		if (_textEditor.signatureHelpTriggerCharacters.indexOf(event.text) != -1) {
			dispatchSignatureHelpEventForCurrentPosition(event.text);
			return;
		}
		if (PopUpManager.isPopUp(_signatureHelpView)) {
			dispatchSignatureHelpEventForCurrentPosition();
		}
	}

	private function signatureHelpManager_textEditor_focusOutHandler(event:FocusEvent):Void {
		if (event.relatedObject != null && _textEditor.contains(event.relatedObject)) {
			return;
		}
		closeSignatureHelpView();
	}

	private function signatureHelpManager_textEditor_stage_mouseDownHandler(event:MouseEvent):Void {
		if (_signatureHelpView == event.target || _signatureHelpView.contains(event.target)) {
			return;
		}
		closeSignatureHelpView();
	}
}
