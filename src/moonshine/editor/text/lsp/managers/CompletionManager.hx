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
import feathers.data.ListViewItemState;
import feathers.events.ListViewEvent;
import feathers.events.ScrollEvent;
import feathers.utils.DisplayObjectRecycler;
import moonshine.editor.text.changes.TextEditorChange;
import moonshine.editor.text.events.TextEditorChangeEvent;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageActionEvent;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageRequestEvent;
import moonshine.editor.text.lsp.views.CompletionItemRenderer;
import moonshine.editor.text.lsp.views.HoverView;
import moonshine.editor.text.lsp.views.events.CompletionItemRendererEvent;
import moonshine.editor.text.lsp.views.theme.CompletionListViewStyles;
import moonshine.editor.text.utils.LspTextEditorUtil;
import moonshine.editor.text.utils.TextUtil;
import moonshine.lsp.CompletionItem;
import moonshine.lsp.CompletionList;
import moonshine.lsp.CompletionParams;
import moonshine.lsp.CompletionTriggerKind;
import moonshine.lsp.MarkupContent;
import moonshine.lsp.Position;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.TextEvent;
import openfl.geom.Point;
import openfl.net.SharedObject;
import openfl.ui.Keyboard;

/**
	Used internally by `LspTextEditor` to manage completion requests.
**/
class CompletionManager {
	public static final VARIANT_COMPLETION_LIST_VIEW:String = "completionManager_completionListView";

	/**
		Creates a new `CompletionManager` object.
	**/
	public function new(textEditor:LspTextEditor) {
		CompletionListViewStyles.initialize();

		_textEditor = textEditor;

		_completionListView = new ListView();
		_completionListView.tabEnabled = false;
		_completionListView.variant = VARIANT_COMPLETION_LIST_VIEW;
		_completionListView.itemToText = (item:CompletionItem) -> item.label;
		_completionListView.itemRendererRecycler = DisplayObjectRecycler.withFunction(createCompletionItemRenderer, updateCompletionItemRenderer, null,
			destroyCompletionItemRenderer);
		_completionListView.addEventListener(Event.CHANGE, completionManager_completionListView_changeHandler);
		_completionListView.addEventListener(ListViewEvent.ITEM_TRIGGER, completionManager_completionListView_itemTriggerHandler);
		_completionListView.addEventListener(Event.RESIZE, completionManager_completionListView_resizeHandler);
		_completionListView.addEventListener(FocusEvent.FOCUS_OUT, completionManager_completionListView_focusOutHandler);

		_completionDetailView = new HoverView();
		_completionDetailView.addEventListener(Event.RESIZE, completionManager_completionDetailView_resizeHandler);
		_completionDetailView.addEventListener(FocusEvent.FOCUS_OUT, completionManager_completionDetailView_focusOutHandler);

		_textEditor.addEventListener(Event.REMOVED_FROM_STAGE, completionManager_textEditor_removedFromStageHandler, false, 0, true);
		_textEditor.addEventListener(ScrollEvent.SCROLL, completionManager_textEditor_scrollHandler, false, 0, true);
		_textEditor.addEventListener(KeyboardEvent.KEY_DOWN, completionManager_textEditor_keyDownHandler, false, 0, true);
		// need to use capture for the navigation keys because the internal
		// container might try to cancel them before our listener is called
		_textEditor.addEventListener(KeyboardEvent.KEY_DOWN, completionManager_textEditor_keyDownCaptureHandler, true, 10, true);
		_textEditor.addEventListener(TextEvent.TEXT_INPUT, completionManager_textEditor_textInputHandler, false, 0, true);
		_textEditor.addEventListener(FocusEvent.FOCUS_OUT, completionManager_textEditor_focusOutHandler, false, 0, true);
		_textEditor.addEventListener(Event.RESIZE, completionManager_textEditor_resizeHandler, false, 0, true);

		_sharedObject = SharedObject.getLocal("CompletionManager");
		if (_sharedObject.data.showDetail == null) {
			_sharedObject.data.showDetail = false;
		}
		if (_sharedObject.data.listWidth == null) {
			_sharedObject.data.listWidth = 450.0;
		}
		_sharedObject.flush();
	}

	/**
		Specifies the value of `KeyboardEvent.ctrlKey` that is required to
		trigger completion.

		@see `CompletionManager.shortcutKey`
	**/
	public var shortcutRequiresCtrl:Bool = true;

	/**
		Specifies the value of `KeyboardEvent.altKey` that is required to
		trigger completion.

		@see `CompletionManager.shortcutKey`
	**/
	public var shortcutRequiresAlt:Bool = false;

	/**
		Specifies the value of `KeyboardEvent.shiftKey` that is required to
		trigger completion.

		@see `CompletionManager.shortcutKey`
	**/
	public var shortcutRequiresShift:Bool = false;

	/**
		Specifies the value of `KeyboardEvent.commandKey` that is required to
		trigger completion.

		@see `CompletionManager.shortcutKey`
	**/
	public var shortcutRequiresCommand:Bool = false;

	/**
		Specifies the value of `KeyboardEvent.controlKey` that is required to
		trigger completion.

		@see `CompletionManager.shortcutKey`
	**/
	public var shortcutRequiresControl:Bool = false;

	/**
		The key used to trigger completion, along with the specified modifiers.

		@see `CompletionManager.shortcutRequiresCtrl`
		@see `CompletionManager.shortcutRequiresAlt`
		@see `CompletionManager.shortcutRequiresShift`
		@see `CompletionManager.shortcutRequiresCommand`
		@see `CompletionManager.shortcutRequiresControl`
	**/
	public var shortcutKey:UInt = Keyboard.SPACE;

	private var _textEditor:LspTextEditor;
	private var _currentRequestID:Int = -1;
	private var _currentRequestParams:CompletionParams;
	private var _completionListView:ListView;
	private var _completionDetailView:HoverView;
	private var _filterText:String = "";
	private var _initialFilterTextLength:Int = 0;
	private var _isIncomplete:Bool = false;
	private var _prevSelectedIndex:Int = -1;
	private var _prevSelectedItem:Dynamic = null;
	private var _sharedObject:SharedObject;
	private var _ignoreCompletionListViewResize:Bool = false;
	private var _ignoreCompletionDetailViewResize:Bool = false;
	private var _ignoreCompletionListViewChange:Bool = false;

	/**
		Aborts current request, if any, and closes the completion list view.
	**/
	public function clear():Void {
		incrementRequestID();
		closeCompletionListView();
	}

	/**
		Sends a completion request.
	**/
	public function dispatchCompletionEvent(params:CompletionParams):Void {
		// if the completion list is already open, close it before making a new request
		closeCompletionListView();

		// make sure that the current caret position is visible
		_textEditor.scrollToCaret();

		if (params.context == null
			|| params.context.triggerKind != CompletionTriggerKind.TriggerCharacter
			|| params.context.triggerCharacter == null) {
			var line = _textEditor.lines.get(_textEditor.caretLineIndex);
			var startIndex = _textEditor.caretCharIndex - 1;
			if (startIndex >= 0 && TextUtil.isWordCharacter(line.text.charAt(startIndex))) {
				startIndex = TextUtil.startOfWord(line.text, startIndex);
			} else {
				startIndex = -1;
			}
			if (startIndex >= 0) {
				_filterText = StringTools.trim(line.text.substr(startIndex, Std.int(Math.max(0, _textEditor.caretCharIndex - startIndex))).toLowerCase());
			} else {
				_filterText = "";
			}
		} else {
			_filterText = "";
		}
		_initialFilterTextLength = _filterText.length;
		_isIncomplete = false;
		incrementRequestID();
		var requestID = _currentRequestID;
		_currentRequestParams = params;
		_textEditor.dispatchEvent(new LspTextEditorLanguageRequestEvent(LspTextEditorLanguageRequestEvent.REQUEST_COMPLETION, params, result -> {
			handleCompletion(requestID, result);
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
		var oldIgnoreCompletionListViewChange = _ignoreCompletionListViewChange;
		_ignoreCompletionListViewChange = true;
		_completionListView.dataProvider.set(index, result);
		// if it's the same object, be sure that the change is noticed
		_completionListView.dataProvider.updateAt(index);
		_ignoreCompletionListViewChange = oldIgnoreCompletionListViewChange;
		var selectedItem = cast(_completionListView.selectedItem, CompletionItem);
		updateDetail();
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
		_prevSelectedIndex = -1;
		_prevSelectedItem = null;
		if (items.length > 0) {
			_completionListView.selectedIndex = 0;
		}
		if (_sharedObject.data.showDetail) {
			PopUpManager.addPopUp(_completionDetailView, _textEditor, false, false);
		}

		positionCompletionListView();
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
		var itemText = item.label;
		if (item.filterText != null) {
			itemText = item.filterText;
		}
		return StringTools.startsWith(itemText.toLowerCase(), _filterText);
	}

	private function refreshAfterFilterUpdate():Void {
		// ignore any active requests because completion resolve responses may
		// not be accurate anymore
		incrementRequestID();
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
		var oldIgnoreCompletionListViewResize = _ignoreCompletionListViewResize;
		_ignoreCompletionListViewResize = true;
		_completionListView.width = Math.min(_sharedObject.data.listWidth, _textEditor.width);
		_completionListView.validateNow();
		_ignoreCompletionListViewResize = oldIgnoreCompletionListViewResize;

		var bounds = _textEditor.getTextEditorPositionBoundaries(LspTextEditorUtil.lspPositionToTextEditorPosition(_currentRequestParams.position));
		if (bounds == null) {
			closeCompletionListView();
			return;
		}

		var oldIgnoreCompletionDetailViewResize = _ignoreCompletionDetailViewResize;
		_ignoreCompletionDetailViewResize = true;
		var showDetail = _sharedObject.data.showDetail;
		if (showDetail) {
			_completionDetailView.resetWidth();
			_completionDetailView.resetMaxHeight();
			_completionDetailView.validateNow();
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

		var maxAppListX = maxAppX - _completionListView.width;
		var maxAppListY = maxAppY - _completionListView.height;

		var canPositionListBelow = true;
		var canPositionDetailOnSide = true;
		var minListX = Math.max(0.0, viewPortTopLeft.x - _completionListView.width);
		var maxListX = Math.min(viewPortBottomRight.x, maxAppListX);
		// when positioned below, don't let it go past the top of the editor
		var minListY = viewPortTopLeft.y;
		// and don't let it go past the bottom of the app
		var maxListY = maxAppListY;

		var maxAppDetailX = maxAppX - _completionDetailView.width;
		var maxAppDetailY = maxAppY - _completionDetailView.height;

		var listX = Math.max(minListX, Math.min(maxListX, xy.x));

		// check if we can position the detail view on the left or right
		var detailX = listX + _completionListView.width;
		if (detailX > maxAppDetailX) {
			detailX = listX - _completionDetailView.width;
			if (detailX < 0.0) {
				canPositionDetailOnSide = false;
			}
		}

		// start by trying to position it below the current line
		var listY = xy.y + _textEditor.lineHeight;
		var notEnoughRoomForList = listY > maxAppListY;
		var notEnoughRoomForListAndDetail = showDetail
			&& !canPositionDetailOnSide
			&& canPositionListBelow
			&& (listY + _completionListView.height + _completionDetailView.height) > maxAppY;
		if (notEnoughRoomForList || notEnoughRoomForListAndDetail) {
			// if it doesn't fit below, try positioning it above
			canPositionListBelow = false;
			listY = xy.y - _completionListView.height;
			// when positioned above, don't let it go past to the top of the app
			minListY = 0.0;
			// and don't let it go past the bottom of the editor
			maxListY = viewPortBottomRight.y - _completionListView.height;
		}

		if (listY > maxListY) {
			listY = maxListY;
		}
		if (listY < minListY) {
			listY = minListY;
		}

		_completionListView.x = listX;
		_completionListView.y = listY;

		if (showDetail) {
			var detailY = _completionListView.y;
			if (canPositionDetailOnSide) {
				// prefer to position aligned to the top
				if (detailY > maxAppDetailY) {
					var bottomOutOfBounds = detailY - maxAppDetailY;
					// fall back to aligning to the bottom
					detailY = listY - _completionDetailView.height;
					if (detailY < 0.0) {
						// if neither works, choose the one with more space
						var topOutOfBounds = -detailY;
						if (bottomOutOfBounds < topOutOfBounds) {
							// below has more space
							detailY = listY;
							_completionDetailView.maxHeight = maxAppDetailY - detailY;
						} else {
							// above has more space
							detailY = 0.0;
							_completionDetailView.maxHeight = listY + _completionListView.height;
						}
					}
				}
			} else {
				// not enough room on the sides, so position above or below
				detailX = listX;
				// match the width of the list, even if the content is smaller
				_completionDetailView.width = _completionListView.width;
				if (canPositionListBelow) {
					detailY = listY + _completionListView.height;
					if (detailY > maxAppDetailY) {
						_completionDetailView.maxHeight = maxAppY - detailY;
					}
				} else {
					detailY = listY - _completionDetailView.height;
					if (detailY < 0.0) {
						detailY = 0.0;
						_completionDetailView.maxHeight = listY;
					}
				}
			}

			_completionDetailView.x = detailX;
			_completionDetailView.y = detailY;
		}
		_ignoreCompletionDetailViewResize = oldIgnoreCompletionDetailViewResize;
	}

	private function closeCompletionListView():Void {
		if (_textEditor.stage != null) {
			_textEditor.stage.removeEventListener(MouseEvent.MOUSE_DOWN, completionManager_textEditor_stage_mouseDownHandler);
		}
		if (PopUpManager.isPopUp(_completionDetailView)) {
			PopUpManager.removePopUp(_completionDetailView);
		}
		if (!PopUpManager.isPopUp(_completionListView)) {
			return;
		}
		PopUpManager.removePopUp(_completionListView);
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

	private function dispatchResolveCompletionEvent(index:Int):Void {
		incrementRequestID();
		var requestID = _currentRequestID;
		var item = cast(_completionListView.dataProvider.get(index), CompletionItem);
		_textEditor.dispatchEvent(new LspTextEditorLanguageRequestEvent(LspTextEditorLanguageRequestEvent.REQUEST_RESOLVE_COMPLETION, item, result -> {
			handleResolveCompletion(requestID, index, result);
		}));
	}

	private function resolveSnippet(text:String):Snippet {
		var resolvedText = text;
		var newCaretLineOffset = -1;
		var newCaretCharOffset = -1;
		var lines = resolvedText.split("\n");
		for (i in 0...lines.length) {
			var snippetMatcher = ~/\$(\d+)/g;
			lines[i] = snippetMatcher.map(lines[i], f -> {
				var matchedIndexString = snippetMatcher.matched(1);
				var result = "";
				if (matchedIndexString == null) {
					matchedIndexString = snippetMatcher.matched(2);
					result = snippetMatcher.matched(3);
				}
				var matchedIndex = Std.parseInt(matchedIndexString);
				if (matchedIndex == 0) {
					newCaretLineOffset = i;
					newCaretCharOffset = snippetMatcher.matchedPos().pos;
				}
				return result;
			});
		}
		resolvedText = lines.join("\n");
		return new Snippet(resolvedText, newCaretLineOffset, newCaretCharOffset);
	}

	private function applyCompletionItem(item:CompletionItem):Void {
		var change:TextEditorChange = null;
		var newCaretLineIndex = -1;
		var newCaretCharIndex = -1;
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
		if (item.insertTextFormat == Snippet) {
			var snippet = resolveSnippet(change.newText);
			if (snippet.newCaretLineOffset != -1 && snippet.newCaretCharOffset != -1) {
				if (snippet.newCaretLineOffset > 0) {
					newCaretLineIndex = change.startLine + snippet.newCaretLineOffset;
					newCaretCharIndex = snippet.newCaretCharOffset;
				} else {
					newCaretLineIndex = change.startLine;
					newCaretCharIndex = change.startChar + snippet.newCaretCharOffset;
				}
			}
			change = new TextEditorChange(change.startLine, change.startChar, change.endLine, change.endChar, snippet.text);
		}
		var changes = [change];
		if (item.additionalTextEdits != null) {
			changes = changes.concat(item.additionalTextEdits.map(textEdit -> LspTextEditorUtil.lspTextEditToTextEditorChange(textEdit)));
		}
		_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, changes));
		if (newCaretLineIndex != -1 && newCaretCharIndex != -1) {
			_textEditor.setSelection(newCaretLineIndex, newCaretCharIndex, newCaretLineIndex, newCaretCharIndex);
		}
		if (item.command != null) {
			_textEditor.runCommand(item.command);
		}
		_filterText = "";
		if (_textEditor.focusManager != null) {
			_textEditor.focusManager.focus = _textEditor;
		} else if (_textEditor.stage != null) {
			_textEditor.stage.focus = _textEditor;
		}
		closeCompletionListView();
	}

	private function createCompletionItemRenderer():CompletionItemRenderer {
		var itemRenderer = new CompletionItemRenderer();
		itemRenderer.addEventListener(CompletionItemRendererEvent.SHOW_DETAIL, completionManager_completionItemRenderer_showDetailHandler);
		itemRenderer.addEventListener(CompletionItemRendererEvent.HIDE_DETAIL, completionManager_completionItemRenderer_hideDetailHandler);
		return itemRenderer;
	}

	private function updateCompletionItemRenderer(itemRenderer:CompletionItemRenderer, state:ListViewItemState):Void {
		itemRenderer.showDetailExternally = _sharedObject.data.showDetail;
	}

	private function destroyCompletionItemRenderer(itemRenderer:CompletionItemRenderer):Void {
		itemRenderer.removeEventListener(CompletionItemRendererEvent.SHOW_DETAIL, completionManager_completionItemRenderer_showDetailHandler);
		itemRenderer.removeEventListener(CompletionItemRendererEvent.HIDE_DETAIL, completionManager_completionItemRenderer_hideDetailHandler);
	}

	private function updateDetail():Void {
		var selectedItem = cast(_completionListView.selectedItem, CompletionItem);
		if (selectedItem == null) {
			_completionDetailView.htmlText = null;
			_completionDetailView.visible = false;
			return;
		}
		var detail = selectedItem.detail;
		var documentation = parseDocumentation(selectedItem.documentation);
		var hasContent = selectedItem != null
			&& ((detail != null && detail.length > 0) || (documentation != null && documentation.length > 0));
		if (!hasContent) {
			_completionDetailView.htmlText = null;
			_completionDetailView.visible = false;
			return;
		}
		var markdown = "";
		if (detail != null && detail.length > 0) {
			markdown += "```\n";
			markdown += StringTools.trim(detail);
			markdown += "\n```";
		}
		if (documentation != null && documentation.length > 0) {
			markdown += "\n\n-----\n\n";
			markdown += StringTools.trim(documentation);
		}
		var htmlText = TextFieldMarkdown.markdownToHtml(StringTools.trim(markdown));
		_completionDetailView.htmlText = StringTools.trim(htmlText);
		_completionDetailView.visible = true;
	}

	private function parseDocumentation(original:Any):String {
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
		// some kind of content that we don't understand
		// to be safe, show nothing
		return null;
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
					if (_isIncomplete) {
						dispatchCompletionEventForCurrentPosition();
						return;
					}
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
		if (_isIncomplete) {
			var triggerChar = (_textEditor.completionTriggerCharacters.indexOf(event.text) != -1) ? event.text : null;
			dispatchCompletionEventForCurrentPosition(triggerChar);
			return;
		}
		_filterText += event.text.toLowerCase();
		_currentRequestParams.position.character += event.text.length;
		refreshAfterFilterUpdate();
	}

	private function checkForFocusOut(event:FocusEvent):Void {
		var newFocus = event.relatedObject;
		if (newFocus != null) {
			if (newFocus == _textEditor
				|| _textEditor.contains(newFocus)
				|| newFocus == _completionListView
				|| _completionListView.contains(newFocus)
				|| newFocus == _completionDetailView
				|| _completionDetailView.contains(newFocus)) {
				return;
			}
		}
		closeCompletionListView();
	}

	private function completionManager_textEditor_focusOutHandler(event:FocusEvent):Void {
		checkForFocusOut(event);
	}

	private function completionManager_completionListView_focusOutHandler(event:FocusEvent):Void {
		checkForFocusOut(event);
	}

	private function completionManager_completionDetailView_focusOutHandler(event:FocusEvent):Void {
		checkForFocusOut(event);
	}

	private function completionManager_completionListView_itemTriggerHandler(event:ListViewEvent):Void {
		applyCompletionItem(event.state.data);
	}

	private function completionManager_completionListView_resizeHandler(event:Event):Void {
		if (_ignoreCompletionListViewResize) {
			return;
		}
		if (!PopUpManager.isTopLevelPopUp(_completionListView)) {
			return;
		}
		positionCompletionListView();
	}

	private function completionManager_textEditor_resizeHandler(event:Event):Void {
		if (!PopUpManager.isTopLevelPopUp(_completionListView)) {
			return;
		}
		positionCompletionListView();
	}

	private function completionManager_completionDetailView_resizeHandler(event:Event):Void {
		if (_ignoreCompletionDetailViewResize) {
			return;
		}
		if (!PopUpManager.isTopLevelPopUp(_completionListView)) {
			return;
		}
		positionCompletionListView();
	}

	private function completionManager_completionListView_changeHandler(event:Event):Void {
		updateDetail();

		if (_ignoreCompletionListViewChange) {
			return;
		}
		var selectedIndex = _completionListView.selectedIndex;
		if (selectedIndex == -1) {
			return;
		}
		var selectedItem = _completionListView.selectedItem;
		if (selectedIndex == _prevSelectedIndex && selectedItem == _prevSelectedItem) {
			return;
		}
		_prevSelectedIndex = selectedIndex;
		_prevSelectedItem = selectedItem;
		var selectedItem = cast(_completionListView.selectedItem, CompletionItem);
		var needsResolve = selectedItem != null && (selectedItem.documentation == null || selectedItem.detail == null);
		if (!needsResolve) {
			return;
		}
		dispatchResolveCompletionEvent(selectedIndex);
	}

	private function completionManager_textEditor_stage_mouseDownHandler(event:MouseEvent):Void {
		if (_completionListView == event.target
			|| _completionListView.contains(event.target)
			|| _completionDetailView == event.target
			|| _completionDetailView.contains(event.target)) {
			return;
		}
		closeCompletionListView();
	}

	private function completionManager_completionItemRenderer_showDetailHandler(event:CompletionItemRendererEvent):Void {
		_sharedObject.data.showDetail = true;
		PopUpManager.addPopUp(_completionDetailView, _textEditor, false, false);
		positionCompletionListView();
	}

	private function completionManager_completionItemRenderer_hideDetailHandler(event:CompletionItemRendererEvent):Void {
		_sharedObject.data.showDetail = false;
		PopUpManager.removePopUp(_completionDetailView);
	}
}

private class Snippet {
	public function new(text:String, newCaretLineOffset:Int, newCaretCharOffset:Int) {
		this.text = text;
		this.newCaretLineOffset = newCaretLineOffset;
		this.newCaretCharOffset = newCaretCharOffset;
	}

	public var text:String;
	public var newCaretLineOffset:Int;
	public var newCaretCharOffset:Int;
}
