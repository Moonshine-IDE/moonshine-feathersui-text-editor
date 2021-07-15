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

import feathers.text.TextFormat;
import feathers.style.Theme;
import feathers.themes.steel.BaseSteelTheme;
import moonshine.lsp.CompletionItemKind;

@:dox(hide)
@:access(feathers.themes.steel.BaseSteelTheme)
class CompletionItemIconStyles {
	private static final COLOR_MAP:Map<CompletionItemKind, UInt> = [
		CompletionItemKind.Function => 0x3382dd,
		CompletionItemKind.Keyword => 0x6d5a9c,
		CompletionItemKind.Interface => 0x5B4AE4,
		CompletionItemKind.Class => 0xa848da,
		CompletionItemKind.Variable => 0x6d5a9c,
		CompletionItemKind.Field => 0x6d5a1b,
		CompletionItemKind.Event => 0xC28627,
		CompletionItemKind.Property => 0x3E8854,
		CompletionItemKind.Method => 0x3382dd,
	];

	public static function initialize(?theme:BaseSteelTheme):Void {
		if (theme == null) {
			theme = Std.downcast(Theme.fallbackTheme, BaseSteelTheme);
		}
		if (theme == null) {
			return;
		}

		var styleProvider = theme.styleProvider;
		if (styleProvider.getStyleFunction(CompletionItemIcon, null) == null) {
			styleProvider.setStyleFunction(CompletionItemIcon, null, function(icon:CompletionItemIcon):Void {
				setCompletionItemIconStyles(icon, theme);
			});
		}
	}

	private static function setCompletionItemIconStyles(icon:CompletionItemIcon, theme:BaseSteelTheme):Void {
		if (icon.colorMap == null) {
			icon.colorMap = COLOR_MAP;
		}

		icon.textFormat = new TextFormat("_sans", 12, 0x000000, true);
	}
}
