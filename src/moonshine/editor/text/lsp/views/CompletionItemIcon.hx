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

import feathers.skins.CircleSkin;
import feathers.controls.Label;
import moonshine.lsp.CompletionItemKind;
import moonshine.lsp.CompletionItem;
import feathers.core.FeathersControl;

class CompletionItemIcon extends FeathersControl {
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

	public function new() {
		super();
	}

	private var _label:Label;
	private var _backgroundSkin:CircleSkin;

	private var _data:CompletionItem;

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

	override private function initialize():Void {
		super.initialize();

		if (_label == null) {
			_backgroundSkin = new CircleSkin();
			addChild(_backgroundSkin);
		}

		if (_label == null) {
			_label = new Label();
			addChild(_label);
		}
	}

	override private function update():Void {
		var dataInvalid = isInvalid(DATA);

		if (dataInvalid) {
			if (_data != null) {
				var fillColor = COLOR_MAP.exists(_data.kind) ? COLOR_MAP.get(_data.kind) : 0x000000;
				_backgroundSkin.fill = SolidColor(fillColor);
				_label.text = TEXT_MAP.exists(_data.kind) ? TEXT_MAP.get(_data.kind) : "";
			} else {
				_backgroundSkin.fill = SolidColor(0x000000);
				_label.text = "";
			}
		}

		measure();

		layoutContent();
	}

	private function measure():Void {
		saveMeasurements(20.0, 20.0, 20.0, 20.0);
	}

	private function layoutContent():Void {
		_backgroundSkin.x = 0.0;
		_backgroundSkin.y = 0.0;
		_backgroundSkin.width = actualWidth;
		_backgroundSkin.height = actualHeight;

		_label.validateNow();
		_label.x = (actualWidth - _label.width) / 2.0;
		_label.y = (actualHeight - _label.height) / 2.0;
	}
}
