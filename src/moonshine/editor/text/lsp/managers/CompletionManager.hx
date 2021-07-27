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
import feathers.controls.ListView;
import feathers.core.PopUpManager;
import feathers.data.ArrayCollection;
import feathers.events.ListViewEvent;
import feathers.events.ScrollEvent;
import feathers.utils.DisplayObjectRecycler;
import moonshine.editor.text.changes.TextEditorChange;
import moonshine.editor.text.events.TextEditorChangeEvent;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageActionEvent;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageRequestEvent;
import moonshine.editor.text.lsp.views.CompletionItemRenderer;
import moonshine.editor.text.lsp.views.theme.CompletionListViewStyles;
import moonshine.editor.text.utils.LspTextEditorUtil;
import moonshine.editor.text.utils.TextUtil;
import moonshine.lsp.CompletionItem;
import moonshine.lsp.CompletionList;
import moonshine.lsp.CompletionParams;
import moonshine.lsp.CompletionTriggerKind;
import moonshine.lsp.Position;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.TextEvent;
import openfl.geom.Point;
import openfl.ui.Keyboard;

class CompletionManager {
	public static final VARIANT_COMPLETION_LIST_VIEW:String = "completionManager_completionListView";

	public function new(textEditor:LspTextEditor) {
		CompletionListViewStyles.initialize();

		_textEditor = textEditor;

		_completionListView = new ListView();
		_completionListView.tabEnabled = false;
		_completionListView.variant = VARIANT_COMPLETION_LIST_VIEW;
		_completionListView.itemToText = (item:CompletionItem) -> item.label;
		_completionListView.itemRendererRecycler = DisplayObjectRecycler.withClass(CompletionItemRenderer);
		_completionListView.addEventListener(ListViewEvent.ITEM_TRIGGER, completionManager_completionListView_itemTriggerHandler);
		_completionListView.addEventListener(Event.RESIZE, completionManager_completionListview_resizeHandler);
		_completionListView.addEventListener(FocusEvent.FOCUS_OUT, completionManager_completionListView_focusOutHandler);

		_textEditor.addEventListener(Event.REMOVED_FROM_STAGE, completionManager_textEditor_removedFromStageHandler, false, 0, true);
		_textEditor.addEventListener(ScrollEvent.SCROLL, completionManager_textEditor_scrollHandler, false, 0, true);
		_textEditor.addEventListener(KeyboardEvent.KEY_DOWN, completionManager_textEditor_keyDownHandler, false, 0, true);
		// need to use capture for the navigation keys because the internal
		// container might try to cancel them before our listener is called
		_textEditor.addEventListener(KeyboardEvent.KEY_DOWN, completionManager_textEditor_keyDownCaptureHandler, true, 10, true);
		_textEditor.addEventListener(TextEvent.TEXT_INPUT, completionManager_textEditor_textInputHandler, false, 0, true);
		_textEditor.addEventListener(FocusEvent.FOCUS_OUT, completionManager_textEditor_focusOutHandler, false, 0, true);
	}

	public var shortcutRequiresCtrl:Bool = true;
	public var shortcutRequiresAlt:Bool = false;
	public var shortcutRequiresShift:Bool = false;
	public var shortcutRequiresCommand:Bool = false;
	public var shortcutRequiresControl:Bool = false;
	public var shortcutKey:UInt = Keyboard.SPACE;

	private var _textEditor:LspTextEditor;
	private var _currentRequestID:Int = -1;
	private var _currentRequestParams:CompletionParams;
	private var _completionListView:ListView;
	private var _filterText:String = "";
	private var _initialFilterTextLength:Int = 0;
	private var _isIncomplete:Bool = false;
	private var _prevSelectedIndex:Int = -1;

	public function clear():Void {
		_currentRequestID = -1;
		closeCompletionListView();
	}

	private function handleResolveCompletion(requestID:Int, index:Int, result:CompletionItem):Void {
		if (requestID != _currentRequestID) {
			// a newer request has taken precedence over this request
			return;
		}
		if (_textEditor.stage == null) {
			// a request could have been sent before removal that hadn't yet
			// received a response
			return;
		}
		_completionListView.dataProvider.set(index, result);
		// if it's the same object, be sure that the change is noticed
		_completionListView.dataProvider.updateAt(index);
	}

	private function handleCompletion(requestID:Int, result:CompletionList):Void {
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
		closeCompletionListView();

		if (_currentRequestParams == null) {
			// current request cancelled before a response was received
			return;
		}

		if (result == null || result.items == null || result.items.length == 0) {
			return;
		}

		var items = new ArrayCollection(result.items);
		items.filterFunction = completionItemFilterFunction;
		items.sortCompareFunction = completionItemSortCompareFunction;
		if (items.length == 0) {
			return;
		}

		_isIncomplete = result.isIncomplete;
		_completionListView.dataProvider = items;
		_textEditor.stage.addEventListener(MouseEvent.MOUSE_DOWN, completionManager_textEditor_stage_mouseDownHandler, false, 0, true);
		PopUpManager.addPopUp(_completionListView, _textEditor, false, false);
		if (items.length > 0) {
			_completionListView.selectedIndex = 0;
		}
		_prevSelectedIndex = _completionListView.selectedIndex;
		_completionListView.addEventListener(Event.CHANGE, completionManager_completionListView_changeHandler);

		positionCompletionListView();

		if (_isIncomplete && items.length > 0) {
			dispatchResolveCompletionEvent(0);
		}
	}

	private function completionItemSortCompareFunction(item1:CompletionItem, item2:CompletionItem):Int {
		var text1 = (item1.sortText != null) ? item1.sortText : item1.label;
		text1 = text1.toLowerCase();
		var text2 = (item2.sortText != null) ? item2.sortText : item2.label;
		text2 = text2.toLowerCase();
		if (text1 < text2) {
			return -1;
		}
		if (text1 > text2) {
			return 1;
		}
		return 0;
	}

	private function completionItemFilterFunction(item:CompletionItem):Bool {
		if (_filterText == null || _filterText.length == 0) {
			return true;
		}
		return StringTools.startsWith(item.label.toLowerCase(), _filterText);
	}

	private function refreshAfterFilterUpdate():Void {
		_completionListView.dataProvider.refresh();
		_completionListView.scrollY = 0.0;
		if (_completionListView.dataProvider.length > 0) {
			_completionListView.selectedIndex = 0;
			positionCompletionListView();
		} else {
			// we've filtered everything! nothing to display
			closeCompletionListView();
		}
	}

	private function positionCompletionListView():Void {
		_completionListView.validateNow();

		var bounds = _textEditor.getTextEditorPositionBoundaries(LspTextEditorUtil.lspPositionToTextEditorPosition(_currentRequestParams.position));
		if (bounds == null) {
			closeCompletionListView();
			return;
		}
		var xy = new Point(bounds.x, bounds.y);
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
		maxAppX -= _completionListView.width;
		maxAppY -= _completionListView.height;

		var minX = Math.max(0.0, viewPortTopLeft.x - _completionListView.width);
		var maxX = Math.min(viewPortBottomRight.x, maxAppX);
		_completionListView.x = Math.max(minX, Math.min(maxX, xy.x));

		// start by trying to position it below the current line
		var yPosition = xy.y + _textEditor.lineHeight;
		// when positioned below, don't let it go past the top of the editor
		var minY = viewPortTopLeft.y;
		// and don't let it go past the bottom of the app
		var maxY = maxAppY;
		if (yPosition > maxAppY) {
			// if it doesn't fit below, try positioning it above
			yPosition = xy.y - _completionListView.height;
			// when positioned above, don't let it go past to the top of the app
			minY = 0.0;
			// and don't let it go past the bottom of the editor
			maxY = viewPortBottomRight.y - _completionListView.height;
		}
		if (yPosition > maxY) {
			yPosition = maxY;
		}
		if (yPosition < minY) {
			yPosition = minY;
		}
		_completionListView.y = yPosition;
	}

	private function closeCompletionListView():Void {
		if (!PopUpManager.isPopUp(_completionListView)) {
			return;
		}
		PopUpManager.removePopUp(_completionListView);
		_completionListView.removeEventListener(Event.CHANGE, completionManager_completionListView_changeHandler);
		_textEditor.stage.removeEventListener(MouseEvent.MOUSE_DOWN, completionManager_textEditor_stage_mouseDownHandler);
	}

	private function dispatchCompletionEventForCurrentPosition(?triggerChar:String):Void {
		var params:CompletionParams = {
			textDocument: _textEditor.textDocument,
			position: new Position(_textEditor.caretLineIndex, _textEditor.caretCharIndex)
		}
		if (triggerChar != null) {
			params.context = {
				triggerKind: CompletionTriggerKind.TriggerCharacter,
				triggerCharacter: triggerChar
			};
		}
		dispatchCompletionEvent(params);
	}

	public function dispatchCompletionEvent(params:CompletionParams):Void {
		// if the completion list is already open, close it before making a new request
		closeCompletionListView();

		if (params.context == null
			|| params.context.triggerKind != CompletionTriggerKind.TriggerCharacter
			|| params.context.triggerCharacter == null) {
			var line = _textEditor.lines.get(_textEditor.caretLineIndex);
			var startIndex = TextUtil.startOfWord(line.text, _textEditor.caretCharIndex);
			if (startIndex >= 0) {
				_filterText = line.text.substr(startIndex, Std.int(Math.max(0, _textEditor.caretCharIndex - startIndex))).toLowerCase();
			} else {
				_filterText = "";
			}
		} else {
			_filterText = "";
		}
		_initialFilterTextLength = _filterText.length;
		_isIncomplete = false;
		if (_currentRequestID == 10000) {
			// we don't want the counter to overflow into negative numbers
			// this should be a reasonable time to reset it
			_currentRequestID = -1;
		}
		_currentRequestID++;
		var requestID = _currentRequestID;
		_currentRequestParams = params;
		_textEditor.dispatchEvent(new LspTextEditorLanguageRequestEvent(LspTextEditorLanguageRequestEvent.REQUEST_COMPLETION, params, result -> {
			handleCompletion(requestID, result);
		}));
	}

	private function dispatchResolveCompletionEvent(index:Int):Void {
		if (_currentRequestID == 10000) {
			// we don't want the counter to overflow into negative numbers
			// this should be a reasonable time to reset it
			_currentRequestID = -1;
		}
		_currentRequestID++;
		var requestID = _currentRequestID;
		var item = _completionListView.dataProvider.get(index);
		_textEditor.dispatchEvent(new LspTextEditorLanguageRequestEvent(LspTextEditorLanguageRequestEvent.REQUEST_RESOLVE_COMPLETION, item, result -> {
			handleResolveCompletion(requestID, index, result);
		}));
	}

	private function applyCompletionItem(item:CompletionItem):Void {
		var change:TextEditorChange = null;
		if (item.textEdit != null) {
			change = LspTextEditorUtil.lspTextEditToTextEditorChange(item.textEdit);
			if (change.endChar < _textEditor.caretCharIndex) {
				// account for the user typing more since the initial
				// completion request
				change = new TextEditorChange(change.startLine, change.startChar, change.endLine, _textEditor.caretCharIndex, change.newText);
			}
		} else {
			var text = item.label;
			if (item.insertText != null) {
				text = item.insertText;
			}
			var pos = _currentRequestParams.position;
			change = new TextEditorChange(pos.line, pos.character - _filterText.length, pos.line, pos.character, text);
		}
		var changes = [change];
		if (item.additionalTextEdits != null) {
			changes = changes.concat(item.additionalTextEdits.map(textEdit -> LspTextEditorUtil.lspTextEditToTextEditorChange(textEdit)));
		}
		_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, changes));
		if (item.command != null) {
			_textEditor.dispatchEvent(new LspTextEditorLanguageActionEvent(LspTextEditorLanguageActionEvent.RUN_COMMAND, item.command));
		}
		_filterText = "";
		if (_textEditor.focusManager != null) {
			_textEditor.focusManager.focus = _textEditor;
		} else if (_textEditor.stage != null) {
			_textEditor.stage.focus = _textEditor;
		}
		closeCompletionListView();
	}

	private function completionManager_textEditor_removedFromStageHandler(event:Event):Void {
		closeCompletionListView();
	}

	private function completionManager_textEditor_scrollHandler(event:ScrollEvent):Void {
		if (!PopUpManager.isTopLevelPopUp(_completionListView)) {
			return;
		}
		positionCompletionListView();
	}

	private function completionManager_textEditor_keyDownHandler(event:KeyboardEvent):Void {
		if (event.isDefaultPrevented()) {
			return;
		}
		if (PopUpManager.isPopUp(_completionListView)) {
			// these keys will be handled after the TextEditor makes any changes to
			// its text. if you are adding a new key here, and it should be handled
			// before the text is modified, put it in the other listener
			switch (event.keyCode) {
				case Keyboard.ESCAPE:
					closeCompletionListView();
					return;
				case Keyboard.BACKSPACE:
					var newLength = _filterText.length - 1;
					if (newLength < _initialFilterTextLength) {
						// if we've gone before the position where the request was
						// made, the data is no longer valid, and we need to make a
						// new request
						dispatchCompletionEventForCurrentPosition();
						return;
					}
					// otherwise, update the filter based on the current request
					_filterText = _filterText.substr(0, newLength);
					_currentRequestParams.position.character--;
					refreshAfterFilterUpdate();
					return;
			}
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
		dispatchCompletionEventForCurrentPosition();
	}

	private function completionManager_textEditor_keyDownCaptureHandler(event:KeyboardEvent):Void {
		if (event.isDefaultPrevented()) {
			return;
		}

		if (!PopUpManager.isPopUp(_completionListView)) {
			return;
		}
		var newSelectedIndex = _completionListView.selectedIndex;

		// these keys will be handled before the TextEditor makes any changes to
		// its text. if you are adding a new key here, and it should be handled
		// after the text is modified, put it in the other listener
		switch (event.keyCode) {
			case Keyboard.BACKSPACE:
				if (_textEditor.caretCharIndex == 0) {
					// if we're at the beginning of the line, close the
					// completion list instead of updating it
					closeCompletionListView();
					return;
				}
			case Keyboard.ENTER:
				event.preventDefault();
				applyCompletionItem(cast(_completionListView.selectedItem : CompletionItem));
				return;
			case Keyboard.TAB:
				event.preventDefault();
				applyCompletionItem(cast(_completionListView.selectedItem : CompletionItem));
				return;
			case Keyboard.LEFT:
				closeCompletionListView();
				return;
			case Keyboard.RIGHT:
				closeCompletionListView();
				return;
			case Keyboard.HOME:
				closeCompletionListView();
				return;
			case Keyboard.END:
				closeCompletionListView();
				return;
			case Keyboard.UP:
				event.preventDefault();
				newSelectedIndex--;
				if (newSelectedIndex < 0) {
					newSelectedIndex = _completionListView.dataProvider.length - 1;
				}
			case Keyboard.DOWN:
				event.preventDefault();
				newSelectedIndex++;
				if (newSelectedIndex >= _completionListView.dataProvider.length) {
					newSelectedIndex = 0;
				}
			case Keyboard.PAGE_UP:
				event.preventDefault();
				newSelectedIndex--;
				if (newSelectedIndex < 0) {
					newSelectedIndex = _completionListView.dataProvider.length - 1;
				}
			case Keyboard.PAGE_DOWN:
				event.preventDefault();
				newSelectedIndex++;
				if (newSelectedIndex >= _completionListView.dataProvider.length) {
					newSelectedIndex = 0;
				}
		}
		if (newSelectedIndex != _completionListView.selectedIndex) {
			_completionListView.selectedIndex = newSelectedIndex;
			_completionListView.scrollToIndex(newSelectedIndex);
		}
	}

	private function completionManager_textEditor_textInputHandler(event:TextEvent):Void {
		if (event.isDefaultPrevented()) {
			return;
		}
		if (event.text == " " || _textEditor.completionTriggerCharacters.indexOf(event.text) != -1) {
			dispatchCompletionEventForCurrentPosition(event.text);
			return;
		}
		if (!PopUpManager.isPopUp(_completionListView)) {
			return;
		}
		_filterText += event.text.toLowerCase();
		_currentRequestParams.position.character += event.text.length;
		refreshAfterFilterUpdate();
	}

	private function completionManager_textEditor_focusOutHandler(event:FocusEvent):Void {
		var newFocus = event.relatedObject;
		if (newFocus != null) {
			if (newFocus == _textEditor || _textEditor.contains(newFocus) || newFocus == _completionListView || _completionListView.contains(newFocus)) {
				return;
			}
		}
		closeCompletionListView();
	}

	private function completionManager_completionListView_focusOutHandler(event:FocusEvent):Void {
		var newFocus = event.relatedObject;
		if (newFocus != null) {
			if (newFocus == _textEditor || _textEditor.contains(newFocus) || newFocus == _completionListView || _completionListView.contains(newFocus)) {
				return;
			}
		}
		closeCompletionListView();
	}

	private function completionManager_completionListView_itemTriggerHandler(event:ListViewEvent):Void {
		applyCompletionItem(event.state.data);
	}

	private function completionManager_completionListview_resizeHandler(event:Event):Void {
		if (!PopUpManager.isTopLevelPopUp(_completionListView)) {
			return;
		}
		positionCompletionListView();
	}

	private function completionManager_completionListView_changeHandler(event:Event):Void {
		if (!_isIncomplete) {
			return;
		}
		if (_completionListView.selectedIndex == -1) {
			return;
		}
		if (_completionListView.selectedIndex == _prevSelectedIndex) {
			return;
		}
		_prevSelectedIndex = _completionListView.selectedIndex;
		dispatchResolveCompletionEvent(_completionListView.selectedIndex);
	}

	private function completionManager_textEditor_stage_mouseDownHandler(event:MouseEvent):Void {
		if (_completionListView == event.target || _completionListView.contains(event.target)) {
			return;
		}
		closeCompletionListView();
	}
}
