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

import openfl.display.Shape;
import feathers.skins.RectangleSkin;
import feathers.style.Theme;
import feathers.themes.steel.BaseSteelTheme;

@:dox(hide)
@:access(feathers.themes.steel.BaseSteelTheme)
class CodeActionsViewStyles {
	public static function initialize(?theme:BaseSteelTheme):Void {
		if (theme == null) {
			theme = Std.downcast(Theme.fallbackTheme, BaseSteelTheme);
		}
		if (theme == null) {
			return;
		}

		var styleProvider = theme.styleProvider;
		if (styleProvider.getStyleFunction(CodeActionsView, null) == null) {
			styleProvider.setStyleFunction(CodeActionsView, null, function(view:CodeActionsView):Void {
				if (view.backgroundSkin == null) {
					var skin = new RectangleSkin();
					skin.fill = SolidColor(theme.darkMode ? 0x000000 : 0xffffff, 0.8);
					skin.border = SolidColor(1.0, theme.darkMode ? 0x080808 : 0xacacac);
					skin.width = 20.0;
					skin.height = 20.0;
					view.backgroundSkin = skin;
				}

				if (view.icon == null) {
					var bulbColor = 0xeeaa00;
					var icon = new Shape();

					icon.graphics.beginFill(bulbColor);
					icon.graphics.drawCircle(4.0, 4.0, 4.0);
					icon.graphics.endFill();
					icon.graphics.beginFill(bulbColor);
					icon.graphics.drawRoundRect(2.0, 7.0, 4.0, 4.0, 3.0);
					icon.graphics.endFill();
					icon.graphics.lineStyle(1.0, theme.darkMode ? 0x282828 : 0x000000);
					icon.graphics.moveTo(2.0, 10.0);
					icon.graphics.lineTo(6.0, 10.0);
					view.icon = icon;
				}
			});
		}
	}
}
