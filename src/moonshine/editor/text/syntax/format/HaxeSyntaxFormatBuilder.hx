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

import moonshine.editor.text.syntax.parser.HaxeLineParser;
import openfl.text.TextFormat;

/**
	Builds the set of text styles for the Haxe language.
**/
class HaxeSyntaxFormatBuilder {
	private var _colorSettings:SyntaxColorSettings;
	private var _fontSettings:SyntaxFontSettings;

	/**
		Creates a new `HaxeSyntaxFormatBuilder` object.
	**/
	public function new() {}

	/**
		Specifies the `SyntaxColorSettings` to use when creating the
		`TextFormat` objects.
	**/
	public function setColorSettings(settings:SyntaxColorSettings):HaxeSyntaxFormatBuilder {
		_colorSettings = settings;
		return this;
	}

	/**
		Specifies the `SyntaxFontSettings` to use when creating the
		`TextFormat` objects.
	**/
	public function setFontSettings(settings:SyntaxFontSettings):HaxeSyntaxFormatBuilder {
		_fontSettings = settings;
		return this;
	}

	/**
		Creates a mapping of language text styles to `TextFormat` objects.
	**/
	public function build():Map<Int, TextFormat> {
		var formats:Map<Int, TextFormat> = [];
		formats.set(0 /* default, parser fault */, getTextFormat(_colorSettings.invalidColor));
		formats.set(HaxeLineParser.HX_CODE, getTextFormat(_colorSettings.foregroundColor));
		formats.set(HaxeLineParser.HX_STRING1, getTextFormat(_colorSettings.stringColor));
		formats.set(HaxeLineParser.HX_STRING2, getTextFormat(_colorSettings.stringColor));
		formats.set(HaxeLineParser.HX_COMMENT, getTextFormat(_colorSettings.commentColor));
		formats.set(HaxeLineParser.HX_MULTILINE_COMMENT, getTextFormat(_colorSettings.commentColor));
		formats.set(HaxeLineParser.HX_REGULAR_EXPRESSION, getTextFormat(_colorSettings.regExpColor));
		formats.set(HaxeLineParser.HX_KEYWORD, getTextFormat(_colorSettings.keywordColor));
		formats.set(HaxeLineParser.HX_VAR_KEYWORD, getTextFormat(_colorSettings.fieldKeywordColor));
		formats.set(HaxeLineParser.HX_FUNCTION_KEYWORD, getTextFormat(_colorSettings.methodKeywordColor));
		formats.set(HaxeLineParser.HX_TYPE_KEYWORDS, getTextFormat(_colorSettings.typeKeywordColor));
		formats.set(HaxeLineParser.HX_PACKAGE_KEYWORD, getTextFormat(_colorSettings.moduleKeywordColor));
		formats.set(HaxeLineParser.HX_METADATA, getTextFormat(_colorSettings.annotationColor));
		formats.set(HaxeLineParser.HX_FIELD, getTextFormat(_colorSettings.fieldNameColor));
		formats.set(HaxeLineParser.HX_FUNCTIONS, getTextFormat(_colorSettings.methodNameColor));
		formats.set(HaxeLineParser.HX_CONDITIONAL, getTextFormat(_colorSettings.preprocessorColor));
		formats.set(HaxeLineParser.HX_SELF_KEYWORDS, getTextFormat(_colorSettings.thisSelfKeywordColor));
		formats.set(HaxeLineParser.HX_VALUE_KEYWORDS, getTextFormat(_colorSettings.valueColor));
		return formats;
	}

	private function getTextFormat(fontColor:UInt):TextFormat {
		var format = new TextFormat(_fontSettings.fontFamily, _fontSettings.fontSize, fontColor);
		format.tabStops = _fontSettings.tabStops;
		return format;
	}
}
