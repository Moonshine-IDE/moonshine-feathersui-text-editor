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

import moonshine.editor.text.syntax.parser.context.ContextSwitch;
import moonshine.editor.text.syntax.parser.context.InlineParserManager;

class HTMLLineParser extends XMLLineParser {
	public static final SCRIPT_MASK:Int = 0x1000;
	public static final SCRIPT_OPEN_TAG:Int = 0x11;
	public static final SCRIPT_CLOSE_TAG:Int = 0x12;

	public static final STYLE_MASK:Int = 0x2000;
	public static final STYLE_OPEN_TAG:Int = 0x21;
	public static final STYLE_CLOSE_TAG:Int = 0x22;

	public function new() {
		super();

		// Add inline parsers
		parserManager = new InlineParserManager([
			new InlineParser(SCRIPT_MASK, new JSLineParser()),
			new InlineParser(STYLE_MASK, new CSSLineParser())
		]);

		// Inline script context switches
		switchManager.addSwitch(new ContextSwitch([XMLLineParser.XML_TEXT], SCRIPT_OPEN_TAG, ~/<script(?:>|\s>|\s[^>]*[^>\/]>)/i), true);
		switchManager.addSwitch(new ContextSwitch([SCRIPT_OPEN_TAG], SCRIPT_MASK));
		switchManager.addSwitch(new ContextSwitch([SCRIPT_MASK], SCRIPT_CLOSE_TAG, ~/<\/script\s*>/i));
		switchManager.addSwitch(new ContextSwitch([SCRIPT_CLOSE_TAG], XMLLineParser.XML_TEXT));
		// Inline style context switches
		switchManager.addSwitch(new ContextSwitch([XMLLineParser.XML_TEXT], STYLE_OPEN_TAG, ~/<style(?:>|\s>|\s[^>]*[^>\/]>)/i), true);
		switchManager.addSwitch(new ContextSwitch([STYLE_OPEN_TAG], STYLE_MASK));
		switchManager.addSwitch(new ContextSwitch([STYLE_MASK], STYLE_CLOSE_TAG, ~/<\/style\s*>/i));
		switchManager.addSwitch(new ContextSwitch([STYLE_CLOSE_TAG], XMLLineParser.XML_TEXT));
	}
}
