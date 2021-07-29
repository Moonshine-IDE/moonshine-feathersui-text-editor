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
import feathers.controls.Button;
import feathers.controls.ScrollContainer;
import feathers.skins.RectangleSkin;
import feathers.style.Theme;
import feathers.themes.steel.BaseSteelTheme;

@:dox(hide)
@:access(feathers.themes.steel.BaseSteelTheme)
class SignatureHelpViewStyles {
	public static function initialize(?theme:BaseSteelTheme):Void {
		if (theme == null) {
			theme = Std.downcast(Theme.fallbackTheme, BaseSteelTheme);
		}
		if (theme == null) {
			return;
		}

		var styleProvider = theme.styleProvider;
		if (styleProvider.getStyleFunction(SignatureHelpView, null) == null) {
			styleProvider.setStyleFunction(SignatureHelpView, null, function(view:SignatureHelpView):Void {
				setSignatureHelpViewStyles(view, theme);
			});
		}
		if (styleProvider.getStyleFunction(Button, null) == null) {
			styleProvider.setStyleFunction(Button, SignatureHelpView.CHILD_VARIANT_PREVIOUS_SIGNATURE_BUTTON, function(button:Button):Void {
				setSignatureHelpViewPreviousSignatureButtonStyles(button, theme);
			});
		}
		if (styleProvider.getStyleFunction(Button, null) == null) {
			styleProvider.setStyleFunction(Button, SignatureHelpView.CHILD_VARIANT_NEXT_SIGNATURE_BUTTON, function(button:Button):Void {
				setSignatureHelpViewNextSignatureButtonStyles(button, theme);
			});
		}
	}

	private static function setSignatureHelpViewStyles(view:SignatureHelpView, theme:BaseSteelTheme):Void {
		if (view.backgroundSkin == null) {
			var skin = new RectangleSkin();
			skin.fill = SolidColor(theme.darkMode ? 0x000000 : 0xeeeeee);
			skin.border = SolidColor(1.0, 0x333333);
			skin.maxWidth = 450.0;
			skin.maxHeight = 450.0;
			view.backgroundSkin = skin;
		}

		if (view.textFormat == null) {
			view.textFormat = theme.getTextFormat();
		}

		view.setPadding(1.0);

		theme.styleProvider.getStyleFunction(ScrollContainer, null)(view);
	}

	private static function setSignatureHelpViewPreviousSignatureButtonStyles(button:Button, theme:BaseSteelTheme):Void {
		button.showText = false;

		var icon = new TriangleSkin();
		icon.pointPosition = LEFT;
		icon.fill = SolidColor(theme.textColor);
		icon.disabledFill = SolidColor(theme.disabledTextColor);
		icon.width = 8.0;
		icon.height = 8.0;
		button.icon = icon;

		theme.styleProvider.getStyleFunction(Button, null)(button);
		button.setPadding(4.0);
	}

	private static function setSignatureHelpViewNextSignatureButtonStyles(button:Button, theme:BaseSteelTheme):Void {
		button.showText = false;

		var icon = new TriangleSkin();
		icon.pointPosition = RIGHT;
		icon.fill = SolidColor(theme.textColor);
		icon.disabledFill = SolidColor(theme.disabledTextColor);
		icon.width = 8.0;
		icon.height = 8.0;
		button.icon = icon;

		theme.styleProvider.getStyleFunction(Button, null)(button);
		button.setPadding(4.0);
	}
}
