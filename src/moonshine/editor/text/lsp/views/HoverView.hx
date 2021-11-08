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
import feathers.controls.ScrollContainer;
import feathers.layout.VerticalLayout;
import feathers.text.TextFormat;
import moonshine.editor.text.lsp.views.theme.HoverViewStyles;

/**
	A view to display hover data.

	@see `moonshine.lsp.Hover`
**/
@:styleContext
class HoverView extends ScrollContainer {
	/**
		Creates a new `HoverView` object.
	**/
	public function new() {
		HoverViewStyles.initialize();
		super();

		tabEnabled = false;
	}

	private var label:Label;

	private var _htmlText:String = null;

	/**
		The HTML-formatted text to display.
	**/
	@:flash.property
	public var htmlText(get, set):String;

	private function get_htmlText():String {
		return _htmlText;
	}

	private function set_htmlText(value:String):String {
		if (_htmlText == value) {
			return _htmlText;
		}
		_htmlText = value;
		setInvalid(DATA);
		return _htmlText;
	}

	/**
		The font styles used to display the text.
	**/
	@:style
	public var textFormat:TextFormat = null;

	override private function initialize():Void {
		super.initialize();

		var viewLayout = new VerticalLayout();
		viewLayout.horizontalAlign = JUSTIFY;
		viewLayout.justifyResetEnabled = true;
		viewLayout.setPadding(10.0);
		layout = viewLayout;

		label = new Label();
		label.themeEnabled = false;
		label.selectable = true;
		label.wordWrap = true;
		addChild(label);
	}

	override private function update():Void {
		var dataInvalid = isInvalid(DATA);
		var stylesInvalid = isInvalid(STYLES);

		if (dataInvalid) {
			label.htmlText = _htmlText;
		}

		if (stylesInvalid) {
			label.textFormat = textFormat;
		}

		super.update();
	}
}
