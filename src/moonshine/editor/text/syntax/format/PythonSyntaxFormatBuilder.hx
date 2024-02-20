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

import moonshine.editor.text.syntax.parser.PythonLineParser;
import openfl.text.TextFormat;

/**
	Builds the set of text styles for the Python language.
**/
class PythonSyntaxFormatBuilder {
	private var _colorSettings:SyntaxColorSettings;
	private var _fontSettings:SyntaxFontSettings;

	/**
		Creates a new `PythonSyntaxFormatBuilder` object.
	**/
	public function new() {}

	/**
		Specifies the `SyntaxColorSettings` to use when creating the
		`TextFormat` objects.
	**/
	public function setColorSettings(settings:SyntaxColorSettings):PythonSyntaxFormatBuilder {
		_colorSettings = settings;
		return this;
	}

	/**
		Specifies the `SyntaxFontSettings` to use when creating the
		`TextFormat` objects.
	**/
	public function setFontSettings(settings:SyntaxFontSettings):PythonSyntaxFormatBuilder {
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
		formats.set(PythonLineParser.PY_CODE, getTextFormat(_colorSettings.foregroundColor));
		formats.set(PythonLineParser.PY_STRING1, getTextFormat(_colorSettings.stringColor));
		formats.set(PythonLineParser.PY_STRING2, getTextFormat(_colorSettings.stringColor));
		formats.set(PythonLineParser.PY_MULTILINE_STRING, getTextFormat(_colorSettings.stringColor));
		formats.set(PythonLineParser.PY_COMMENT, getTextFormat(_colorSettings.commentColor));
		formats.set(PythonLineParser.PY_KEYWORD, getTextFormat(_colorSettings.keywordColor));
		formats.set(PythonLineParser.PY_FUNCTION_KEYWORD, getTextFormat(_colorSettings.methodKeywordColor));
		formats.set(PythonLineParser.PY_PACKAGE_CLASS_KEYWORDS, getTextFormat(_colorSettings.typeKeywordColor));
		return formats;
	}

	private function getTextFormat(fontColor:UInt):TextFormat {
		var format = new TextFormat(_fontSettings.fontFamily, _fontSettings.fontSize, fontColor);
		format.tabStops = _fontSettings.tabStops;
		return format;
	}
}
