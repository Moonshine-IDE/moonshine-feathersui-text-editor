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
import moonshine.editor.text.syntax.parser.context.ContextSwitchManager;
import moonshine.editor.text.syntax.parser.context.ContextSwitchLineParser;

/**
	Parses lines of Cascading Style Sheets (CSS) to determine how the syntax is
	highlighted.
**/
class CSSLineParser extends ContextSwitchLineParser {
	public static final CSS_TEXT:Int = 0x0;
	public static final CSS_PROPERTY:Int = 0x1;
	public static final CSS_VALUE:Int = 0x2;
	public static final CSS_STRING1:Int = 0x3;
	public static final CSS_STRING2:Int = 0x4;
	public static final CSS_STRING3:Int = 0x5;
	public static final CSS_STRING4:Int = 0x6;
	public static final CSS_COMMENT1:Int = 0x7;
	public static final CSS_COMMENT2:Int = 0x8;
	public static final CSS_COMMENT3:Int = 0x9;
	public static final CSS_MEDIA:Int = 0xA;
	public static final CSS_BRACEOPEN:Int = 0xB;
	public static final CSS_BRACECLOSE:Int = 0xC;
	public static final CSS_COLON1:Int = 0xD;
	public static final CSS_COLON2:Int = 0xE;
	public static final CSS_COLON3:Int = 0xF;
	public static final CSS_COLOR:Int = 0x10;
	public static final CSS_NUMBER:Int = 0x11;

	/**
		Creates a new `CSSLineParser` object.
	**/
	public function new() {
		super();

		context = CSS_TEXT;
		_defaultContext = CSS_TEXT;

		// Context switches, order matters
		switchManager = new ContextSwitchManager([

			// Comments
			new ContextSwitch([CSS_TEXT], CSS_COMMENT1, ~/\/\*/),
			new ContextSwitch([CSS_COMMENT1], CSS_TEXT, ~/\*\//, true),
			new ContextSwitch([CSS_PROPERTY], CSS_COMMENT2, ~/\/\*/),
			new ContextSwitch([CSS_COMMENT2], CSS_PROPERTY, ~/\*\//, true),
			new ContextSwitch([CSS_VALUE], CSS_COMMENT3, ~/\/\*/),
			new ContextSwitch([CSS_COMMENT3], CSS_VALUE, ~/\*\//, true),
			// Media rules
			new ContextSwitch([CSS_TEXT], CSS_MEDIA, ~/@media(?=[;{\s])/, true),
			new ContextSwitch([CSS_MEDIA], CSS_TEXT, ~/[{\r\n]/),
			// Semi-colons
			new ContextSwitch([CSS_TEXT, CSS_MEDIA], CSS_COLON1, ~/;/),
			new ContextSwitch([CSS_COLON1], CSS_TEXT),
			// Selectors
			new ContextSwitch([CSS_TEXT], CSS_BRACEOPEN, ~/\{/),
			new ContextSwitch([CSS_BRACEOPEN], CSS_PROPERTY),
			new ContextSwitch([CSS_PROPERTY, CSS_VALUE], CSS_BRACECLOSE, ~/\}/),
			new ContextSwitch([CSS_BRACECLOSE], CSS_TEXT, ~/(?=.)/),
			// Values
			new ContextSwitch([CSS_PROPERTY], CSS_COLON2, ~/:/),
			new ContextSwitch([CSS_COLON2], CSS_VALUE),
			new ContextSwitch([CSS_VALUE], CSS_PROPERTY, ~/[\r\n]/),
			new ContextSwitch([CSS_VALUE], CSS_COLON3, ~/;/),
			new ContextSwitch([CSS_COLON3], CSS_PROPERTY),
			// Color
			new ContextSwitch([CSS_VALUE], CSS_COLOR, ~/#[0-9a-fA-F]{3,8}/),
			new ContextSwitch([CSS_COLOR], CSS_VALUE),
			// Number
			new ContextSwitch([CSS_VALUE], CSS_NUMBER, ~/\-?((\.[0-9]+)|([0-9]+(\.[0-9]+)?))/),
			new ContextSwitch([CSS_NUMBER], CSS_VALUE),
			// Strings
			new ContextSwitch([CSS_TEXT], CSS_STRING1, ~/"/),
			new ContextSwitch([CSS_TEXT], CSS_STRING2, ~/'/),
			new ContextSwitch([CSS_STRING1], CSS_STRING1, ~/\\["\r\n]/),
			new ContextSwitch([CSS_STRING2], CSS_STRING2, ~/\\['\r\n]/),
			new ContextSwitch([CSS_STRING1], CSS_TEXT, ~/"|(?=[\r\n])/, true),
			new ContextSwitch([CSS_STRING2], CSS_TEXT, ~/'|(?=[\r\n])/, true),
			new ContextSwitch([CSS_VALUE], CSS_STRING3, ~/"/),
			new ContextSwitch([CSS_VALUE], CSS_STRING4, ~/'/),
			new ContextSwitch([CSS_STRING3], CSS_STRING3, ~/\\["\r\n]/),
			new ContextSwitch([CSS_STRING4], CSS_STRING4, ~/\\['\r\n]/),
			new ContextSwitch([CSS_STRING3], CSS_VALUE, ~/"|(?=[\r\n])/, true),
			new ContextSwitch([CSS_STRING4], CSS_VALUE, ~/'|(?=[\r\n])/, true)
		]);
	}
}
