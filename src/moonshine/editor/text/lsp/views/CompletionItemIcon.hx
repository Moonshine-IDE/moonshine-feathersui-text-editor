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

import feathers.core.FeathersControl;
import feathers.skins.CircleSkin;
import feathers.text.TextFormat;
import moonshine.editor.text.lsp.views.theme.CompletionItemIconStyles;
import moonshine.lsp.CompletionItem;
import moonshine.lsp.CompletionItemKind;
import openfl.text.TextField;

/**
	Displays an icon for the "kind" of a completion item.
**/
@:styleContext
class CompletionItemIcon extends FeathersControl {
	private static final TEXT_MAP:Map<CompletionItemKind, String> = [
		CompletionItemKind.Function => "F",
		CompletionItemKind.Keyword => "K",
		CompletionItemKind.Interface => "I",
		CompletionItemKind.Class => "C",
		CompletionItemKind.Variable => "V",
		CompletionItemKind.Field => "F",
		CompletionItemKind.Event => "E",
		CompletionItemKind.Property => "P",
		CompletionItemKind.Method => "M",
	];

	/**
		Creates a new `CompletionItemIcon` object.
	**/
	public function new() {
		CompletionItemIconStyles.initialize();
		super();
	}

	private var _textField:TextField;
	private var _backgroundSkin:CircleSkin;

	private var _data:CompletionItem;

	/**
		The completion item associated with this icon.
	**/
	@:flash.property
	public var data(get, set):CompletionItem;

	private function get_data():CompletionItem {
		return _data;
	}

	private function set_data(value:CompletionItem):CompletionItem {
		if (_data == value) {
			return _data;
		}
		_data = value;
		setInvalid(DATA);
		return _data;
	}

	/**
		The text format of the icon character.
	**/
	@:style
	public var textFormat:AbstractTextFormat = null;

	/**
		A mapping of completion item kinds to background colors.
	**/
	@:style
	public var colorMap:Map<CompletionItemKind, UInt> = null;

	override private function initialize():Void {
		super.initialize();

		if (_backgroundSkin == null) {
			_backgroundSkin = new CircleSkin();
			addChild(_backgroundSkin);
		}

		if (_textField == null) {
			_textField = new TextField();
			_textField.autoSize = LEFT;
			_textField.mouseEnabled = false;
			_textField.selectable = false;
			addChild(_textField);
		}
	}

	override private function update():Void {
		var dataInvalid = isInvalid(DATA);
		var stylesInvalid = isInvalid(STYLES);

		if (dataInvalid || stylesInvalid) {
			_textField.defaultTextFormat = textFormat;
			if (_data != null) {
				var fillColor = colorMap.exists(_data.kind) ? colorMap.get(_data.kind) : 0x000000;
				_backgroundSkin.fill = SolidColor(fillColor);
				_textField.text = TEXT_MAP.exists(_data.kind) ? TEXT_MAP.get(_data.kind) : "";
			} else {
				_backgroundSkin.fill = SolidColor(0x000000);
				_textField.text = "";
			}
		}

		measure();

		layoutContent();
	}

	private function measure():Void {
		saveMeasurements(16.0, 16.0, 16.0, 16.0);
	}

	private function layoutContent():Void {
		_backgroundSkin.x = 0.0;
		_backgroundSkin.y = 0.0;
		_backgroundSkin.width = actualWidth;
		_backgroundSkin.height = actualHeight;

		_textField.x = (actualWidth - _textField.width) / 2.0;
		_textField.y = (actualHeight - _textField.height) / 2.0;
	}
}
