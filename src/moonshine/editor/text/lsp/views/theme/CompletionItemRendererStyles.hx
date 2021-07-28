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

package moonshine.editor.text.lsp.views.theme;

import feathers.skins.TriangleSkin;
import feathers.controls.Label;
import feathers.controls.ToggleButton;
import feathers.controls.ToggleButtonState;
import feathers.skins.RectangleSkin;
import feathers.skins.UnderlineSkin;
import feathers.style.Theme;
import feathers.themes.steel.BaseSteelTheme;

@:dox(hide)
@:access(feathers.themes.steel.BaseSteelTheme)
class CompletionItemRendererStyles {
	public static function initialize(?theme:BaseSteelTheme):Void {
		if (theme == null) {
			theme = Std.downcast(Theme.fallbackTheme, BaseSteelTheme);
		}
		if (theme == null) {
			return;
		}

		var styleProvider = theme.styleProvider;
		if (styleProvider.getStyleFunction(CompletionItemRenderer, null) == null) {
			styleProvider.setStyleFunction(CompletionItemRenderer, null, function(itemRenderer:CompletionItemRenderer):Void {
				setCompletionItemRendererStyles(itemRenderer, theme);
			});
		}
		if (styleProvider.getStyleFunction(Label, CompletionItemRenderer.CHILD_VARIANT_DETAIL_TEXT) == null) {
			styleProvider.setStyleFunction(Label, CompletionItemRenderer.CHILD_VARIANT_DETAIL_TEXT, function(label:Label):Void {
				setCompletionItemRendererDetailLabelStyles(label, theme);
			});
		}
		if (styleProvider.getStyleFunction(ToggleButton, CompletionItemRenderer.CHILD_VARIANT_DETAIL_TOGGLE_BUTTON) == null) {
			styleProvider.setStyleFunction(ToggleButton, CompletionItemRenderer.CHILD_VARIANT_DETAIL_TOGGLE_BUTTON, function(button:ToggleButton):Void {
				setCompletionItemRendererDetailToggleButtonStyles(button, theme);
			});
		}
	}

	private static function setCompletionItemRendererStyles(itemRenderer:CompletionItemRenderer, theme:BaseSteelTheme):Void {
		if (itemRenderer.backgroundSkin == null) {
			var skin = new UnderlineSkin();
			skin.fill = theme.getContainerFill();
			skin.border = theme.getDividerBorder();
			skin.selectedFill = theme.getActiveThemeFill();
			skin.setFillForState(ToggleButtonState.DOWN(false), theme.getActiveThemeFill());
			skin.width = 4.0;
			skin.height = 4.0;
			skin.minWidth = 4.0;
			skin.minHeight = 4.0;
			itemRenderer.backgroundSkin = skin;
		}

		if (itemRenderer.textFormat == null) {
			var textFormat = theme.getTextFormat();
			textFormat.font = "_typewriter";
			itemRenderer.textFormat = textFormat;
		}
		if (itemRenderer.disabledTextFormat == null) {
			var disabledTextFormat = theme.getDisabledTextFormat();
			disabledTextFormat.font = "_typewriter";
			itemRenderer.disabledTextFormat = disabledTextFormat;
		}
		if (itemRenderer.secondaryTextFormat == null) {
			var secondaryTextFormat = theme.getDetailTextFormat();
			secondaryTextFormat.font = "_typewriter";
			itemRenderer.secondaryTextFormat = secondaryTextFormat;
		}
		if (itemRenderer.disabledSecondaryTextFormat == null) {
			var disabledSecondaryTextFormat = theme.getDisabledDetailTextFormat();
			disabledSecondaryTextFormat.font = "_typewriter";
			itemRenderer.disabledSecondaryTextFormat = disabledSecondaryTextFormat;
		}

		itemRenderer.paddingTop = 2.0;
		itemRenderer.paddingRight = 4.0;
		itemRenderer.paddingBottom = 2.0;
		itemRenderer.paddingLeft = 4.0;
		itemRenderer.gap = 4.0;

		itemRenderer.horizontalAlign = LEFT;
	}

	private static function setCompletionItemRendererDetailLabelStyles(label:Label, theme:BaseSteelTheme):Void {
		// var backgroundSkin = new RectangleSkin();
		// backgroundSkin.fill = SolidColor(0xffffff, 0.0);
		// backgroundSkin.border = None;
		// backgroundSkin.maxWidth = 250.0;
		// label.backgroundSkin = backgroundSkin;

		var textFormat = theme.getDetailTextFormat();
		textFormat.font = "_typewriter";
		label.textFormat = textFormat;
		var disabledTextFormat = theme.getDisabledDetailTextFormat();
		disabledTextFormat.font = "_typewriter";
		label.disabledTextFormat = disabledTextFormat;
	}

	private static function setCompletionItemRendererDetailToggleButtonStyles(button:ToggleButton, theme:BaseSteelTheme):Void {
		button.showText = false;

		var backgroundSkin = new RectangleSkin();
		backgroundSkin.border = None;
		backgroundSkin.fill = theme.getContainerFill();
		backgroundSkin.width = 12.0;
		backgroundSkin.height = 12.0;
		button.backgroundSkin = backgroundSkin;

		var icon = new TriangleSkin();
		icon.pointPosition = RIGHT;
		icon.drawBaseBorder = false;
		icon.border = SolidColor(2.0, theme.textColor);
		icon.width = 4.0;
		icon.height = 8.0;
		button.icon = icon;
	}
}
