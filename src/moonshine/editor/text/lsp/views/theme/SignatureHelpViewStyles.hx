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
	}

	private static function setSignatureHelpViewStyles(view:SignatureHelpView, theme:BaseSteelTheme):Void {
		if (view.backgroundSkin == null) {
			var skin = new RectangleSkin();
			skin.fill = SolidColor(theme.darkMode ? 0x000000 : 0xeeeeee);
			skin.border = SolidColor(1.0, 0x333333);
			view.backgroundSkin = skin;
		}
	}
}
