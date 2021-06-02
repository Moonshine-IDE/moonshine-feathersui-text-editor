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

import moonshine.editor.text.syntax.parser.CSSLineParser;
import openfl.text.TextFormat;

class CSSSyntaxFormatBuilder {
	private var _colorSettings:SyntaxColorSettings;
	private var _fontSettings:SyntaxFontSettings;

	public function new() {}

	public function setColorSettings(settings:SyntaxColorSettings):CSSSyntaxFormatBuilder {
		_colorSettings = settings;
		return this;
	}

	public function setFontSettings(settings:SyntaxFontSettings):CSSSyntaxFormatBuilder {
		_fontSettings = settings;
		return this;
	}

	public function build():Map<Int, TextFormat> {
		var formats:Map<Int, TextFormat> = [];
		formats.set(CSSLineParser.CSS_TEXT, getTextFormat(_colorSettings.typeNameColor));
		formats.set(CSSLineParser.CSS_PROPERTY, getTextFormat(_colorSettings.fieldNameColor));
		formats.set(CSSLineParser.CSS_VALUE, getTextFormat(_colorSettings.valueColor));
		formats.set(CSSLineParser.CSS_COLOR, getTextFormat(_colorSettings.colorColor));
		formats.set(CSSLineParser.CSS_NUMBER, getTextFormat(_colorSettings.numberColor));
		formats.set(CSSLineParser.CSS_MEDIA, getTextFormat(_colorSettings.keywordColor));
		formats.set(CSSLineParser.CSS_BRACEOPEN, getTextFormat(_colorSettings.foregroundColor));
		formats.set(CSSLineParser.CSS_BRACECLOSE, getTextFormat(_colorSettings.foregroundColor));
		formats.set(CSSLineParser.CSS_COLON1, getTextFormat(_colorSettings.foregroundColor));
		formats.set(CSSLineParser.CSS_COLON2, getTextFormat(_colorSettings.foregroundColor));
		formats.set(CSSLineParser.CSS_COLON3, getTextFormat(_colorSettings.foregroundColor));
		formats.set(CSSLineParser.CSS_STRING1, getTextFormat(_colorSettings.stringColor));
		formats.set(CSSLineParser.CSS_STRING2, getTextFormat(_colorSettings.stringColor));
		formats.set(CSSLineParser.CSS_STRING3, getTextFormat(_colorSettings.stringColor));
		formats.set(CSSLineParser.CSS_STRING4, getTextFormat(_colorSettings.stringColor));
		formats.set(CSSLineParser.CSS_COMMENT1, getTextFormat(_colorSettings.commentColor));
		formats.set(CSSLineParser.CSS_COMMENT2, getTextFormat(_colorSettings.commentColor));
		formats.set(CSSLineParser.CSS_COMMENT3, getTextFormat(_colorSettings.commentColor));

		return formats;
	}

	private function getTextFormat(fontColor:UInt):TextFormat {
		var format = new TextFormat(_fontSettings.fontFamily, _fontSettings.fontSize, fontColor);
		format.tabStops = _fontSettings.tabStops;
		return format;
	}
}
