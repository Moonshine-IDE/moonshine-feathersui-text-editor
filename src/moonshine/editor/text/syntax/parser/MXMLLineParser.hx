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

package moonshine.editor.text.syntax.parser;

import moonshine.editor.text.syntax.parser.XMLLineParser;
import moonshine.editor.text.syntax.parser.context.InlineParserManager;
import moonshine.editor.text.syntax.parser.context.ContextSwitch;

class MXMLLineParser extends XMLLineParser {
	public static final SCRIPT_MASK:Int = 0x1000;
	public static final BIND1_MASK:Int = 0x2000;
	public static final BIND2_MASK:Int = 0x3000;
	public static final BIND3_MASK:Int = 0x4000;

	public static final STYLE_MASK:Int = 0x5000;
	public static final STYLE_OPEN_TAG:Int = 0x11;
	public static final STYLE_CLOSE_TAG:Int = 0x12;

	public function new() {
		super();
		// Add inline parsers

		parserManager = new InlineParserManager([
			new InlineParser(SCRIPT_MASK, new AS3LineParser()),
			new InlineParser(BIND1_MASK, new AS3LineParser()),
			new InlineParser(BIND2_MASK, new AS3LineParser()),
			new InlineParser(BIND3_MASK, new AS3LineParser()),
			new InlineParser(STYLE_MASK, new CSSLineParser())
		]);
		// Add context switches for inline AS3 parsing
		switchManager.addSwitch(new ContextSwitch([XMLLineParser.XML_CDATA], SCRIPT_MASK));
		switchManager.addSwitch(new ContextSwitch([SCRIPT_MASK], XMLLineParser.XML_CDATA, ~/(?=\]\]>)/));
		// Inline parsing for data binding
		switchManager.addSwitch(new ContextSwitch([XMLLineParser.XML_ATTR_VAL1], BIND1_MASK, ~/\{/, true));
		switchManager.addSwitch(new ContextSwitch([BIND1_MASK], XMLLineParser.XML_ATTR_VAL1, ~/(?=\})/));
		switchManager.addSwitch(new ContextSwitch([XMLLineParser.XML_ATTR_VAL2], BIND2_MASK, ~/\{/, true));
		switchManager.addSwitch(new ContextSwitch([BIND2_MASK], XMLLineParser.XML_ATTR_VAL2, ~/(?=\})/));
		switchManager.addSwitch(new ContextSwitch([XMLLineParser.XML_TEXT], BIND3_MASK, ~/\{/, true));
		switchManager.addSwitch(new ContextSwitch([BIND3_MASK], XMLLineParser.XML_TEXT, ~/(?=\})/));
		// Inline style context switches
		switchManager.addSwitch(new ContextSwitch([XMLLineParser.XML_TEXT], STYLE_OPEN_TAG,
			~/<(?:[^\x00-\x39\x3A-\x40\x5B-\x5E\x60\x7B-\xBF\xD7\xF7][^\x00-\x2C\x2F\x3A-\x40\x5B-\x5E\x60\x7B-\xB6\xB8-\xBF\xD7\xF7]*:)?style(?:>|\s>|\s[^>]*[^>\/]>)/i),
			true);
		switchManager.addSwitch(new ContextSwitch([STYLE_OPEN_TAG], STYLE_MASK));
		switchManager.addSwitch(new ContextSwitch([STYLE_MASK], STYLE_CLOSE_TAG,
			~/<\/(?:[^\x00-\x39\x3A-\x40\x5B-\x5E\x60\x7B-\xBF\xD7\xF7][^\x00-\x2C\x2F\x3A-\x40\x5B-\x5E\x60\x7B-\xB6\xB8-\xBF\xD7\xF7]*:)?style\s*>/i));
		switchManager.addSwitch(new ContextSwitch([STYLE_CLOSE_TAG], XMLLineParser.XML_TEXT));
	}
}
