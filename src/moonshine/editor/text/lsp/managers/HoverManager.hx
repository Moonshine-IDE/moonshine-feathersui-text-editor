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
import moonshine.editor.text.lsp.views.HoverView;
import moonshine.editor.text.utils.LspTextEditorUtil;
import moonshine.lsp.Hover;
import moonshine.lsp.HoverParams;
import moonshine.lsp.MarkupContent;
import moonshine.lsp.Position;
import openfl.Lib;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;

class HoverManager {
	public function new(textEditor:LspTextEditor) {
		_textEditor = textEditor;

		_hoverView = new HoverView();
		_hoverView.addEventListener(MouseEvent.ROLL_OUT, hoverManager_hoverView_rollOutHandler);

		_textEditor.addEventListener(Event.REMOVED_FROM_STAGE, hoverManager_textEditor_removedFromStageHandler, false, 0, true);
		_textEditor.addEventListener(ScrollEvent.SCROLL, hoverManager_textEditor_scrollHandler, false, 0, true);
		_textEditor.addEventListener(MouseEvent.MOUSE_MOVE, hoverManager_textEditor_mouseMoveHandler, false, 0, true);
		_textEditor.addEventListener(MouseEvent.ROLL_OVER, hoverManager_textEditor_onRollOver, false, 0, true);
		_textEditor.addEventListener(MouseEvent.ROLL_OUT, hoverManager_textEditor_onRollOut, false, 0, true);
	}

	private var _textEditor:LspTextEditor;
	private var _currentRequestID:Int = -1;
	private var _currentRequestParams:HoverParams;
	private var _requestTimeoutID:Int = -1;
	private var _hoverView:HoverView;
	private var _isOver = false;

	public function clear():Void {
		_currentRequestID = -1;
		closeHoverView();
	}

	private function handleHover(requestID:Int, result:Hover):Void {
		if (requestID != _currentRequestID) {
			// a newer request has taken precedence over this request
			return;
		}
		if (_textEditor.stage == null) {
			// a request could have been sent before removal that hadn't yet
			// received a response
			return;
		}

		showHoverWithResult(result);
	}

	private function showHoverWithResult(result:Hover):Void {
		// this shouldn't happen, but clean things up... just in case
		closeHoverView();

		if (_currentRequestParams == null) {
			// current request cancelled before a response was received
			return;
		}

		var markdown = null;
		if (result != null && result.contents != null) {
			if ((result.contents is Array)) {
				var contents = (result.contents : Array<Any>);
				markdown = "";
				for (i in 0...contents.length) {
					var item = contents[i];
					var itemMarkdown = parseHoverContents(item);
					if (itemMarkdown != null) {
						if (i > 0) {
							markdown += "\n\n";
						}
						markdown += itemMarkdown;
					}
				}
			} else {
				markdown = parseHoverContents(result.contents);
			}
		}

		var diagnostics = _textEditor.diagnostics;
		if (diagnostics != null && diagnostics.length > 0) {
			if (markdown == null) {
				markdown = "";
			}
			var validDiagnosticCount = 0;
			for (diagnostic in diagnostics) {
				if (diagnostic.severity == Hint) {
					// skip hints because they are not meant to be displayed
					// to the user like regular problems. they're used
					// internally by the language server or the editor for
					// other types of things, such as code actions.
					continue;
				}
				var range = diagnostic.range;
				var start = range.start;
				var end = range.end;
				var pos = _currentRequestParams.position;
				if (pos.line < start.line || pos.line > end.line) {
					continue;
				}
				if (pos.line == start.line && pos.character < start.character) {
					continue;
				}
				if (pos.line == end.line && pos.character >= end.character) {
					continue;
				}

				if (validDiagnosticCount > 0 || markdown.length > 0) {
					markdown += "\n\n-----\n\n";
				}
				markdown += diagnostic.message;
				validDiagnosticCount++;
			}
		}

		if (markdown == null || markdown.length == 0) {
			return;
		}

		var htmlText = null;
		try {
			htmlText = TextFieldMarkdown.markdownToHtml(StringTools.trim(markdown));
		} catch (e:Any) {
			return;
		}
		if (htmlText == null || htmlText.length == 0) {
			return;
		}

		_hoverView.htmlText = StringTools.trim(htmlText);
		_textEditor.stage.addEventListener(MouseEvent.MOUSE_DOWN, hoverManager_textEditor_stage_mouseDownHandler, false, 0, true);
		PopUpManager.addPopUp(_hoverView, _textEditor, false, false);

		positionHoverView();
	}

	private function positionHoverView():Void {
		_hoverView.validateNow();

		var xy = _textEditor.textEditorPositionToLocal(LspTextEditorUtil.lspPositionToTextEditorPosition(_currentRequestParams.position));
		if (xy == null) {
			closeHoverView();
			return;
		}
		xy = _textEditor.localToGlobal(xy);

		var maxAppX:Float = _textEditor.stage.stageWidth;
		var maxAppY:Float = _textEditor.stage.stageHeight;
		if (Application.topLevelApplication != null) {
			xy = Application.topLevelApplication.globalToLocal(xy);
			maxAppX = Application.topLevelApplication.width;
			maxAppY = Application.topLevelApplication.height;
		}
		maxAppX -= _hoverView.width;
		maxAppY -= _hoverView.height;

		var xPosition = xy.x;
		if (xPosition > maxAppX) {
			xPosition = Math.max(0.0, maxAppX);
		}
		_hoverView.x = xPosition;

		// start by trying to position it above the current line
		var yPosition = xy.y - _hoverView.height + 2.0;
		var minY = 0.0;
		var maxY = maxAppY;
		if (yPosition < minY) {
			// if it doesn't fit above, try positioning it below
			yPosition = xy.y + _textEditor.lineHeight - 2.0;
		}
		if (yPosition > maxY) {
			yPosition = maxY;
		}
		if (yPosition < minY) {
			yPosition = minY;
		}
		_hoverView.y = yPosition;
	}

	private function parseHoverContents(original:Any):String {
		if (original == null) {
			return null;
		}
		if ((original is String)) {
			return (original : String);
		}
		if ((original is MarkupContent)) {
			var markupContent = (original : MarkupContent);
			return markupContent.value;
		}
		// MarkedString
		return Reflect.field(original, "value");
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
			var params:HoverParams = {
				textDocument: _textEditor.textDocument,
				position: LspTextEditorUtil.textEditorPositionToLspPosition(pos),
			};
			dispatchHoverEvent(params);
		}, 250);
	}

	public function dispatchHoverEvent(params:HoverParams):Void {
		_requestTimeoutID = -1;
		if (params == null) {
			_currentRequestParams = null;
			closeHoverView();
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
		// show hover immediately because there may be diagnostics, and we'll
		// update it if we get a result later
		showHoverWithResult(null);
		_textEditor.dispatchEvent(new LspTextEditorLanguageRequestEvent(LspTextEditorLanguageRequestEvent.REQUEST_HOVER, params, result -> {
			handleHover(requestID, result);
		}));
	}

	private function closeHoverView():Void {
		if (!PopUpManager.isTopLevelPopUp(_hoverView)) {
			return;
		}
		PopUpManager.removePopUp(_hoverView);
		_textEditor.stage.removeEventListener(MouseEvent.MOUSE_DOWN, hoverManager_textEditor_stage_mouseDownHandler);
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

	private function handleNewHover():Void {
		var localXY = new Point(_textEditor.mouseX, _textEditor.mouseY);
		var pos = _textEditor.localToTextEditorPosition(localXY);
		if (pos == null) {
			_currentRequestParams = null;
			stopRequestTimer();
			closeHoverView();
			return;
		}
		if (_currentRequestParams != null && isInsideSameWord(_currentRequestParams.position, pos)) {
			// same word as before, so keep the previous request
			return;
		}
		_currentRequestParams = null;
		startOrResetRequestTimer(pos);
		closeHoverView();
	}

	private function hoverManager_textEditor_removedFromStageHandler(event:Event):Void {
		closeHoverView();
	}

	private function hoverManager_textEditor_scrollHandler(event:ScrollEvent):Void {
		if (!_isOver) {
			return;
		}
		handleNewHover();
	}

	private function hoverManager_textEditor_mouseMoveHandler(event:MouseEvent):Void {
		handleNewHover();
	}

	private function hoverManager_textEditor_onRollOver(event:MouseEvent):Void {
		_isOver = true;
		handleNewHover();
	}

	private function hoverManager_textEditor_onRollOut(event:MouseEvent):Void {
		_isOver = false;
		if (event.relatedObject != null && (event.relatedObject == _hoverView || _hoverView.contains(event.relatedObject))) {
			return;
		}
		_currentRequestParams = null;
		stopRequestTimer();
		closeHoverView();
	}

	private function hoverManager_hoverView_rollOutHandler(event:MouseEvent):Void {
		if (event.relatedObject != null && (_textEditor == event.relatedObject || _textEditor.contains(event.relatedObject))) {
			return;
		}
		_currentRequestParams = null;
		stopRequestTimer();
		closeHoverView();
	}

	private function hoverManager_textEditor_stage_mouseDownHandler(event:MouseEvent):Void {
		if (_hoverView == event.target || _hoverView.contains(event.target)) {
			return;
		}
		closeHoverView();
	}
}
