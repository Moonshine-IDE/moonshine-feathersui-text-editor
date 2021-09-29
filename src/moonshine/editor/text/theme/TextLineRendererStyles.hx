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

import feathers.skins.CircleSkin;
import feathers.skins.RectangleSkin;
import feathers.style.Theme;
import feathers.themes.steel.BaseSteelTheme;
import moonshine.editor.text.lines.TextLineRenderer;

@:dox(hide)
@:access(feathers.themes.steel.BaseSteelTheme)
class TextLineRendererStyles {
	public static function initialize(?theme:BaseSteelTheme):Void {
		if (theme == null) {
			theme = Std.downcast(Theme.fallbackTheme, BaseSteelTheme);
		}
		if (theme == null) {
			return;
		}

		var styleProvider = theme.styleProvider;
		if (styleProvider.getStyleFunction(TextLineRenderer, null) == null) {
			styleProvider.setStyleFunction(TextLineRenderer, null, function(view:TextLineRenderer):Void {
				view.gutterPaddingLeft = 6.0;
				view.gutterPaddingRight = 8.0;
				view.gutterGap = 2.0;
				if (view.backgroundSkin == null) {
					var backgroundSkin = new RectangleSkin(SolidColor(0xfdfdfd));
					backgroundSkin.height = 16.0;
					view.backgroundSkin = backgroundSkin;
				}
				if (view.focusedBackgroundSkin == null) {
					view.focusedBackgroundSkin = new RectangleSkin(SolidColor(0xedfbfb));
				}
				if (view.debuggerStoppedBackgroundSkin == null) {
					view.debuggerStoppedBackgroundSkin = new RectangleSkin(SolidColor(0xffffcc));
				}
				if (view.selectedTextBackgroundSkin == null) {
					view.selectedTextBackgroundSkin = new RectangleSkin(SolidColor(0xd1e3f9));
				}
				if (view.selectedTextUnfocusedBackgroundSkin == null) {
					view.selectedTextUnfocusedBackgroundSkin = new RectangleSkin(SolidColor(0xd1d3d9));
				}
				if (view.searchResultBackgroundSkinFactory == null) {
					view.searchResultBackgroundSkinFactory = () -> {
						return new RectangleSkin(SolidColor(0xffb2ff));
					};
				}
				if (view.breakpointSkin == null) {
					var breakpointSkin = new CircleSkin(SolidColor(0xE51400));
					breakpointSkin.width = 10.0;
					breakpointSkin.height = 10.0;
					view.breakpointSkin = breakpointSkin;
				}
				if (view.unverifiedBreakpointSkin == null) {
					var unverifiedBreakpointSkin = new CircleSkin(SolidColor(0x848484));
					unverifiedBreakpointSkin.width = 10.0;
					unverifiedBreakpointSkin.height = 10.0;
					view.unverifiedBreakpointSkin = unverifiedBreakpointSkin;
				}
			});
		}
	}
}
