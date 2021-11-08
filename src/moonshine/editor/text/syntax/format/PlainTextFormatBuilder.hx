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

package moonshine.editor.text.syntax.format;

import moonshine.editor.text.syntax.parser.PlainTextLineParser;
import openfl.text.TextFormat;

/**
	Builds the set of text styles for plain text.
**/
class PlainTextFormatBuilder {
	private var _colorSettings:SyntaxColorSettings;
	private var _fontSettings:SyntaxFontSettings;

	/**
		Creates a new `PlainTextFormatBuilder` object.
	**/
	public function new() {}

	/**
		Specifies the `SyntaxColorSettings` to use when creating the
		`TextFormat` objects.
	**/
	public function setColorSettings(settings:SyntaxColorSettings):PlainTextFormatBuilder {
		_colorSettings = settings;
		return this;
	}

	/**
		Specifies the `SyntaxFontSettings` to use when creating the
		`TextFormat` objects.
	**/
	public function setFontSettings(settings:SyntaxFontSettings):PlainTextFormatBuilder {
		_fontSettings = settings;
		return this;
	}

	/**
		Creates a mapping of language text styles to `TextFormat` objects.
	**/
	public function build():Map<Int, TextFormat> {
		if (_colorSettings == null) {
			_colorSettings = new SyntaxColorSettings();
		}
		if (_fontSettings == null) {
			_fontSettings = new SyntaxFontSettings();
		}
		var formats:Map<Int, TextFormat> = [];
		formats.set(PlainTextLineParser.TEXT, getTextFormat(_colorSettings.foregroundColor));
		return formats;
	}

	private function getTextFormat(fontColor:UInt):TextFormat {
		var format = new TextFormat(_fontSettings.fontFamily, _fontSettings.fontSize, fontColor);
		format.tabStops = _fontSettings.tabStops;
		return format;
	}
}
