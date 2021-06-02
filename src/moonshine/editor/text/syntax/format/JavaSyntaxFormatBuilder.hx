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

import moonshine.editor.text.syntax.parser.JavaLineParser;
import openfl.text.TextFormat;

class JavaSyntaxFormatBuilder {
	private var _colorSettings:SyntaxColorSettings;
	private var _fontSettings:SyntaxFontSettings;

	public function new() {}

	public function setColorSettings(settings:SyntaxColorSettings):JavaSyntaxFormatBuilder {
		_colorSettings = settings;
		return this;
	}

	public function setFontSettings(settings:SyntaxFontSettings):JavaSyntaxFormatBuilder {
		_fontSettings = settings;
		return this;
	}

	public function build():Map<Int, TextFormat> {
		var formats:Map<Int, TextFormat> = [];
		formats.set(0 /* default, parser fault */, getTextFormat(_colorSettings.invalidColor));
		formats.set(JavaLineParser.JAVA_CODE, getTextFormat(_colorSettings.foregroundColor));
		formats.set(JavaLineParser.JAVA_STRING1, getTextFormat(_colorSettings.stringColor));
		formats.set(JavaLineParser.JAVA_STRING2, getTextFormat(_colorSettings.stringColor));
		formats.set(JavaLineParser.JAVA_COMMENT, getTextFormat(_colorSettings.commentColor));
		formats.set(JavaLineParser.JAVA_MULTILINE_COMMENT, getTextFormat(_colorSettings.commentColor));
		formats.set(JavaLineParser.JAVA_KEYWORD, getTextFormat(_colorSettings.keywordColor));
		formats.set(JavaLineParser.JAVA_PACKAGE_CLASS_KEYWORDS, getTextFormat(_colorSettings.typeKeywordColor));
		formats.set(JavaLineParser.JAVA_ANNOTATION, getTextFormat(_colorSettings.annotationColor));
		return formats;
	}

	private function getTextFormat(fontColor:UInt):TextFormat {
		var format = new TextFormat(_fontSettings.fontFamily, _fontSettings.fontSize, fontColor);
		format.tabStops = _fontSettings.tabStops;
		return format;
	}
}
