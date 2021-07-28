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

import feathers.controls.Label;
import feathers.controls.ToggleButton;
import feathers.controls.ToggleButtonState;
import feathers.controls.dataRenderers.ItemRenderer;
import feathers.core.IValidating;
import feathers.layout.AnchorLayoutData;
import moonshine.editor.text.lsp.views.events.CompletionItemRendererEvent;
import moonshine.editor.text.lsp.views.theme.CompletionItemRendererStyles;
import moonshine.lsp.CompletionItem;
import openfl.events.Event;

@:styleContext
class CompletionItemRenderer extends ItemRenderer {
	public static final CHILD_VARIANT_DETAIL_TEXT = "completionItemRenderer_detailText";
	public static final CHILD_VARIANT_DETAIL_TOGGLE_BUTTON = "completionItemRenderer_detailToggleButton";

	public function new() {
		CompletionItemRendererStyles.initialize();
		super();
	}

	private var _completionIcon:CompletionItemIcon;
	private var _detailText:Label;
	private var _detailToggle:ToggleButton;

	private var _ignoreDetailToggleChange:Bool = false;
	private var _showDetailExternally:Bool = false;

	@:flash.property
	public var showDetailExternally(get, set):Bool;

	private function get_showDetailExternally():Bool {
		return _showDetailExternally;
	}

	private function set_showDetailExternally(value:Bool):Bool {
		if (_showDetailExternally == value) {
			return _showDetailExternally;
		}
		_showDetailExternally = value;
		setInvalid(DATA);
		return _showDetailExternally;
	}

	override private function initialize():Void {
		super.initialize();

		_completionIcon = new CompletionItemIcon();
		icon = _completionIcon;

		_detailText = new Label();
		_detailText.variant = CHILD_VARIANT_DETAIL_TEXT;
		// ensures that the width of the text doesn't affect the minWidth, which
		// takes precedence over maxWidth. we're okay with text being truncated.
		_detailText.minWidth = 0.0;
		addChild(_detailText);

		_detailToggle = new ToggleButton();
		_detailToggle.variant = CHILD_VARIANT_DETAIL_TOGGLE_BUTTON;
		_detailToggle.layoutData = AnchorLayoutData.middleRight();
		_detailToggle.tabEnabled = false;
		_detailToggle.addEventListener(Event.CHANGE, completionItemRenderer_detailToggle_changeHandler);
	}

	override private function update():Void {
		var dataInvalid = isInvalid(DATA);
		var selectionInvalid = isInvalid(SELECTION);
		var stateInvalid = isInvalid(STATE);

		if (dataInvalid) {
			var item = cast(data, CompletionItem);
			if (item != null) {
				text = item.label;
				_detailText.text = item.detail;
			} else {
				text = null;
				_detailText.text = null;
			}
			_completionIcon.data = item;

			var oldIgnoreDetailToggleChange = _ignoreDetailToggleChange;
			_ignoreDetailToggleChange = true;
			_detailToggle.selected = _showDetailExternally;
			_ignoreDetailToggleChange = oldIgnoreDetailToggleChange;
		}

		if (dataInvalid || selectionInvalid) {
			var item = Std.downcast(data, CompletionItem);
			var hasDetail = item != null && item.detail != null && item.detail.length > 0;
			_detailText.visible = _selected && hasDetail && !_showDetailExternally;
		}

		if (selectionInvalid || stateInvalid) {
			var showToggle = _selected
				&& (cast(currentState, ToggleButtonState).match(ToggleButtonState.HOVER(true))
					|| cast(currentState, ToggleButtonState).match(ToggleButtonState.DOWN(true)));
			if (!showToggle && stage != null && stage.focus == _detailToggle) {
				stage.focus = this;
			}
			accessoryView = showToggle ? _detailToggle : null;
		}

		super.update();
	}

	override private function layoutChildren():Void {
		var adjustedGap = gap;
		// Math.POSITIVE_INFINITY bug workaround
		if (adjustedGap == (1.0 / 0.0)) {
			adjustedGap = minGap;
		}
		var detailMaxWidth = actualWidth - paddingLeft - paddingRight - _textMeasuredWidth - adjustedGap;
		if (_currentIcon != null && (iconPosition == LEFT || iconPosition == RIGHT)) {
			if ((_currentIcon is IValidating)) {
				cast(_currentIcon, IValidating).validateNow();
			}
			detailMaxWidth -= (_currentIcon.width + adjustedGap);
		}
		if (detailMaxWidth < 0.0) {
			detailMaxWidth = 0.0;
		}
		_detailText.maxWidth = detailMaxWidth;
		_detailText.validateNow();
		_detailText.x = actualWidth - _detailText.width - paddingRight;
		_detailText.y = (actualHeight - _detailText.height) / 2.0;

		super.layoutChildren();
	}

	private function completionItemRenderer_detailToggle_changeHandler(event:Event):Void {
		if (_ignoreDetailToggleChange) {
			return;
		}
		if (_detailToggle.selected) {
			_showDetailExternally = true;
			dispatchEvent(new CompletionItemRendererEvent(CompletionItemRendererEvent.SHOW_DETAIL));
		} else {
			_showDetailExternally = false;
			dispatchEvent(new CompletionItemRendererEvent(CompletionItemRendererEvent.HIDE_DETAIL));
		}
		setInvalid(DATA);
	}
}
