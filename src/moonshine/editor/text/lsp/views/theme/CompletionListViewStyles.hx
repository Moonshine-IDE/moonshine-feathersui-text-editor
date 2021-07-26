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

import feathers.controls.ListView;
import feathers.layout.VerticalListLayout;
import feathers.skins.RectangleSkin;
import feathers.style.Theme;
import feathers.themes.steel.BaseSteelTheme;
import moonshine.editor.text.lsp.managers.CompletionManager;

@:dox(hide)
@:access(feathers.themes.steel.BaseSteelTheme)
class CompletionListViewStyles {
	public static function initialize(?theme:BaseSteelTheme):Void {
		if (theme == null) {
			theme = Std.downcast(Theme.fallbackTheme, BaseSteelTheme);
		}
		if (theme == null) {
			return;
		}

		var styleProvider = theme.styleProvider;
		if (styleProvider.getStyleFunction(CompletionItemRenderer, null) == null) {
			styleProvider.setStyleFunction(ListView, CompletionManager.VARIANT_COMPLETION_LIST_VIEW, function(listView:ListView):Void {
				setCompletionListViewStyles(listView, theme);
			});
		}
	}

	private static function setCompletionListViewStyles(listView:ListView, theme:BaseSteelTheme):Void {
		if (listView.layout == null) {
			var layout = new VerticalListLayout();
			layout.requestedMaxRowCount = 12.0;
			listView.layout = layout;
		}

		if (listView.backgroundSkin == null) {
			var backgroundSkin = new RectangleSkin();
			backgroundSkin.fill = theme.getContainerFill();
			backgroundSkin.border = theme.getContainerBorder();
			backgroundSkin.width = 10.0;
			backgroundSkin.height = 10.0;
			backgroundSkin.maxWidth = 450.0;
			listView.backgroundSkin = backgroundSkin;
		}

		// use defaults for everything else
		theme.styleProvider.getStyleFunction(ListView, ListView.VARIANT_POP_UP)(listView);
	}
}
