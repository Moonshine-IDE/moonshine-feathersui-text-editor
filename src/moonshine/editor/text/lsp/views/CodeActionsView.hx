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

package moonshine.editor.text.lsp.views;

import feathers.controls.Button;
import feathers.controls.ListView;
import feathers.controls.popups.DropDownPopUpAdapter;
import feathers.data.ArrayCollection;
import feathers.events.ListViewEvent;
import feathers.events.TriggerEvent;
import moonshine.editor.text.lsp.views.theme.CodeActionsViewStyles;
import moonshine.lsp.CodeAction;
import openfl.events.Event;
import openfl.events.MouseEvent;

/**
	A view to display code actions data.

	@see `moonshine.lsp.CodeAction`
**/
@:styleContext
class CodeActionsView extends Button {
	/**
		Creates a new `CodeActionsView` object.
	**/
	public function new() {
		CodeActionsViewStyles.initialize();
		super();

		addEventListener(TriggerEvent.TRIGGER, codeActionsView_triggerHandler);
	}

	private var _popUpAdapter:DropDownPopUpAdapter = new DropDownPopUpAdapter();
	private var _popUpListView:ListView;

	private var _codeActions:Array<CodeAction>;

	/**
		The code actions to display.
	**/
	@:flash.property
	public var codeActions(get, set):Array<CodeAction>;

	private function get_codeActions():Array<CodeAction> {
		return _codeActions;
	}

	private function set_codeActions(value:Array<CodeAction>):Array<CodeAction> {
		if (_codeActions == value) {
			return _codeActions;
		}
		_codeActions = value;
		setInvalid(DATA);
		return _codeActions;
	}

	/**
		A function that is called when a code action is triggered.
	**/
	public var codeActionCallback:(CodeAction) -> Void;

	/**
		Opens the pop-up list.
	**/
	public function openList():Void {
		if (_popUpAdapter.active) {
			return;
		}
		if (_popUpListView == null) {
			_popUpListView = new ListView();
			_popUpListView.variant = ListView.VARIANT_POP_UP;
			_popUpListView.itemToText = (codeAction:CodeAction) -> codeAction.title;
			_popUpListView.addEventListener(ListViewEvent.ITEM_TRIGGER, codeActionsView_popUpListView_itemTriggerHandler);
		}
		_popUpListView.dataProvider = new ArrayCollection(_codeActions);
		_popUpListView.addEventListener(Event.REMOVED_FROM_STAGE, codeActionsView_popUpListView_removedFromStageHandler);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, codeActionsView_stage_mouseDownHandler, false, 0, true);
		_popUpAdapter.open(_popUpListView, this);
	}

	private function codeActionsView_triggerHandler(event:TriggerEvent):Void {
		if (_popUpAdapter.active) {
			_popUpAdapter.close();
			return;
		}
		openList();
	}

	private function codeActionsView_popUpListView_removedFromStageHandler(event:Event):Void {
		_popUpListView.removeEventListener(Event.REMOVED_FROM_STAGE, codeActionsView_popUpListView_removedFromStageHandler);
		_popUpListView.stage.removeEventListener(MouseEvent.MOUSE_DOWN, codeActionsView_stage_mouseDownHandler);
	}

	private function codeActionsView_popUpListView_itemTriggerHandler(event:ListViewEvent):Void {
		_popUpAdapter.close();

		var codeAction = cast(event.state.data, CodeAction);
		codeActionCallback(codeAction);
	}

	private function codeActionsView_stage_mouseDownHandler(event:MouseEvent):Void {
		if (hitTestPoint(event.stageX, event.stageY) || _popUpListView.hitTestPoint(event.stageX, event.stageY)) {
			return;
		}
		_popUpAdapter.close();
	}
}
