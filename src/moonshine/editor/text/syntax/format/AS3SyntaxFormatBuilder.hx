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

import moonshine.editor.text.syntax.parser.AS3LineParser;
import openfl.text.TextFormat;

/**
	Builds the set of text styles for the ActionScript 3.0 (AS3) language.
**/
class AS3SyntaxFormatBuilder {
	private var _colorSettings:SyntaxColorSettings;
	private var _fontSettings:SyntaxFontSettings;

	/**
		Creates a new `AS3SyntaxFormatBuilder` object.
	**/
	public function new() {}

	/**
		Specifies the `SyntaxColorSettings` to use when creating the
		`TextFormat` objects.
	**/
	public function setColorSettings(settings:SyntaxColorSettings):AS3SyntaxFormatBuilder {
		_colorSettings = settings;
		return this;
	}

	/**
		Specifies the `SyntaxFontSettings` to use when creating the
		`TextFormat` objects.
	**/
	public function setFontSettings(settings:SyntaxFontSettings):AS3SyntaxFormatBuilder {
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
		formats.set(0 /* default, parser fault */, getTextFormat(_colorSettings.invalidColor));
		formats.set(AS3LineParser.AS_CODE, getTextFormat(_colorSettings.foregroundColor));
		formats.set(AS3LineParser.AS_STRING1, getTextFormat(_colorSettings.stringColor));
		formats.set(AS3LineParser.AS_STRING2, getTextFormat(_colorSettings.stringColor));
		formats.set(AS3LineParser.AS_COMMENT, getTextFormat(_colorSettings.commentColor));
		formats.set(AS3LineParser.AS_MULTILINE_COMMENT, getTextFormat(_colorSettings.commentColor));
		formats.set(AS3LineParser.AS_REGULAR_EXPRESSION, getTextFormat(_colorSettings.regExpColor));
		formats.set(AS3LineParser.AS_KEYWORD, getTextFormat(_colorSettings.keywordColor));
		formats.set(AS3LineParser.AS_VAR_KEYWORD, getTextFormat(_colorSettings.fieldKeywordColor));
		formats.set(AS3LineParser.AS_FUNCTION_KEYWORD, getTextFormat(_colorSettings.methodKeywordColor));
		formats.set(AS3LineParser.AS_PACKAGE_KEYWORD, getTextFormat(_colorSettings.moduleKeywordColor));
		formats.set(AS3LineParser.AS_TYPE_KEYWORD, getTextFormat(_colorSettings.typeKeywordColor));
		formats.set(AS3LineParser.AS_METADATA, getTextFormat(_colorSettings.annotationColor));
		formats.set(AS3LineParser.AS_FIELD, getTextFormat(_colorSettings.fieldNameColor));
		formats.set(AS3LineParser.AS_FUNCTIONS, getTextFormat(_colorSettings.methodNameColor));
		formats.set(AS3LineParser.AS_SELF_KEYWORDS, getTextFormat(_colorSettings.thisSelfKeywordColor));
		formats.set(AS3LineParser.AS_VALUE_KEYWORDS, getTextFormat(_colorSettings.valueColor));
		return formats;
	}

	private function getTextFormat(fontColor:UInt):TextFormat {
		var format = new TextFormat(_fontSettings.fontFamily, _fontSettings.fontSize, fontColor);
		format.tabStops = _fontSettings.tabStops;
		return format;
	}
}
