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

package moonshine.editor.text.theme;

import feathers.controls.ListView;
import feathers.skins.RectangleSkin;
import feathers.style.Theme;
import feathers.themes.steel.BaseSteelTheme;

/**
	The default styles for the `TextEditor` component.
**/
@:dox(hide)
@:access(feathers.themes.steel.BaseSteelTheme)
class TextEditorStyles {
	public static function initialize(?theme:BaseSteelTheme):Void {
		if (theme == null) {
			theme = Std.downcast(Theme.fallbackTheme, BaseSteelTheme);
		}
		if (theme == null) {
			return;
		}

		var styleProvider = theme.styleProvider;
		if (styleProvider.getStyleFunction(TextEditor, null) == null) {
			styleProvider.setStyleFunction(TextEditor, null, function(textEditor:TextEditor):Void {
				var darkMode = theme.darkMode;
				if (textEditor.backgroundSkin == null) {
					var backgroundSkin = new RectangleSkin(SolidColor(darkMode ? 0x1E1E1E : 0xfffffe));
					backgroundSkin.width = 10.0;
					backgroundSkin.height = 10.0;
					textEditor.backgroundSkin = backgroundSkin;
				}
			});
		}
		if (styleProvider.getStyleFunction(ListView, TextEditor.CHILD_VARIANT_LIST_VIEW) == null) {
			styleProvider.setStyleFunction(ListView, TextEditor.CHILD_VARIANT_LIST_VIEW, function(listView:ListView):Void {
				styleProvider.getStyleFunction(ListView, null)(listView);
			});
		}
	}
}
