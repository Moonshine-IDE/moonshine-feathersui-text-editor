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

import moonshine.editor.text.syntax.parser.MXMLLineParser;
import moonshine.editor.text.syntax.parser.XMLLineParser;
import openfl.text.TextFormat;

/**
	Builds the set of text styles for the MXML language.
**/
class MXMLSyntaxFormatBuilder {
	private static final SCRIPT_MASKS:Array<Int> = [
		MXMLLineParser.SCRIPT_MASK,
		MXMLLineParser.BIND1_MASK,
		MXMLLineParser.BIND2_MASK,
		MXMLLineParser.BIND3_MASK
	];

	private var _colorSettings:SyntaxColorSettings;
	private var _fontSettings:SyntaxFontSettings;

	/**
		Creates a new `MXMLSyntaxFormatBuilder` object.
	**/
	public function new() {}

	/**
		Specifies the `SyntaxColorSettings` to use when creating the
		`TextFormat` objects.
	**/
	public function setColorSettings(settings:SyntaxColorSettings):MXMLSyntaxFormatBuilder {
		_colorSettings = settings;
		return this;
	}

	/**
		Specifies the `SyntaxFontSettings` to use when creating the
		`TextFormat` objects.
	**/
	public function setFontSettings(settings:SyntaxFontSettings):MXMLSyntaxFormatBuilder {
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
		formats.set(XMLLineParser.XML_TEXT, getTextFormat(_colorSettings.foregroundColor));
		formats.set(XMLLineParser.XML_TAG, getTextFormat(_colorSettings.tagNameColor));
		formats.set(MXMLLineParser.STYLE_OPEN_TAG, getTextFormat(_colorSettings.tagNameColor));
		formats.set(MXMLLineParser.STYLE_CLOSE_TAG, getTextFormat(_colorSettings.tagNameColor));
		formats.set(XMLLineParser.XML_COMMENT, getTextFormat(_colorSettings.commentColor));
		formats.set(XMLLineParser.XML_CDATA, getTextFormat(_colorSettings.foregroundColor));
		formats.set(XMLLineParser.XML_ATTR_NAME, getTextFormat(_colorSettings.tagAttributeNameColor));
		formats.set(XMLLineParser.XML_ATTR_VAL1, getTextFormat(_colorSettings.stringColor));
		formats.set(XMLLineParser.XML_ATTR_VAL2, getTextFormat(_colorSettings.stringColor));
		formats.set(XMLLineParser.XML_ATTR_OPER, getTextFormat(_colorSettings.foregroundColor));
		formats.set(XMLLineParser.XML_BRACKETOPEN, getTextFormat(_colorSettings.punctuationTagBrackets));
		formats.set(XMLLineParser.XML_BRACKETCLOSE, getTextFormat(_colorSettings.punctuationTagBrackets));

		var as3Builder = new AS3SyntaxFormatBuilder().setColorSettings(_colorSettings).setFontSettings(_fontSettings);
		for (key => format in as3Builder.build()) {
			for (mask in SCRIPT_MASKS) {
				formats.set(mask | key, format);
			}
		}

		var cssBuilder = new CSSSyntaxFormatBuilder().setColorSettings(_colorSettings).setFontSettings(_fontSettings);
		for (key => format in cssBuilder.build()) {
			formats.set(MXMLLineParser.STYLE_MASK | key, format);
		}
		return formats;
	}

	private function getTextFormat(fontColor:UInt):TextFormat {
		var format = new TextFormat(_fontSettings.fontFamily, _fontSettings.fontSize, fontColor);
		format.tabStops = _fontSettings.tabStops;
		return format;
	}
}
