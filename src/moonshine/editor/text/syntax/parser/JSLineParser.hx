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

/**
	Parses lines of JavaScript (JS) code to determine how the syntax is
	highlighted.
**/
class JSLineParser extends LineParser {
	public static final JS_CODE:Int = 0x1;
	public static final JS_STRING1:Int = 0x2;
	public static final JS_STRING2:Int = 0x3;
	public static final JS_COMMENT:Int = 0x4;
	public static final JS_MULTILINE_COMMENT:Int = 0x5;
	public static final JS_REGULAR_EXPRESSION:Int = 0x6;
	public static final JS_NULL_KEYWORD:Int = 0x7;
	public static final JS_UNDEFINED_KEYWORD:Int = 0x8;
	public static final JS_BOOLEAN_KEYWORD:Int = 0x7;
	public static final JS_KEYWORD:Int = 0xA;
	public static final JS_VAR_KEYWORD:Int = 0xB;
	public static final JS_FUNCTION_KEYWORD:Int = 0xC;
	public static final JS_TYPE_KEYWORD:Int = 0xD;

	/**
		Creates a new `JSLineParser` object.
	**/
	public function new() {
		super();

		context = JS_CODE;
		_defaultContext = JS_CODE;

		wordBoundaries = ~/([\s,(){}\[\]\-+*%\/="'~!&|<>?:;.]+)/g;

		// order matters
		patterns = [
			// "
			new LineParserPattern(JS_STRING1, ~/^"(?:\\\\|\\"|[^\n])*?(?:"|\\\n|(?=\n))/),
			// '
			new LineParserPattern(JS_STRING2, ~/^'(?:\\\\|\\'|[^\n])*?(?:'|\\\n|(?=\n))/),
			// //
			new LineParserPattern(JS_COMMENT, ~/^\/\/.*/),
			// /*
			new LineParserPattern(JS_MULTILINE_COMMENT, ~/^\/\*.*?(?:\*\/|\n)/),
			// /pattern/
			new LineParserPattern(JS_REGULAR_EXPRESSION, ~/^\/(?:\\\\|\\\/|\[(?:\\\\|\\\]|.)+?\]|[^*\/])(?:\\\\|\\\/|\[(?:\\\\|\\\]|.)+?\]|.)*?\/[gismx]*/),
		];

		endPatterns = [
			// "
			new LineParserPattern(JS_STRING1, ~/(?:^|[^\\])("|(?=\n))/),
			// '
			new LineParserPattern(JS_STRING2, ~/(?:^|[^\\])('|(?=\n))/),
			// */
			new LineParserPattern(JS_MULTILINE_COMMENT, ~/\*\//),
		];

		keywords = [
			JS_NULL_KEYWORD => ['null'],
			JS_UNDEFINED_KEYWORD => ['undefined'],
			JS_BOOLEAN_KEYWORD => ['true', 'false'],
			JS_VAR_KEYWORD => ['var', 'const', 'let'],
			JS_FUNCTION_KEYWORD => ['function'],
			JS_TYPE_KEYWORD => ['class'],

			JS_KEYWORD => [
				'break',
				'case',
				'catch',
				'continue',
				'debugger',
				'default',
				'delete',
				'do',
				'else',
				'export',
				'extends',
				'finally',
				'for',
				'if',
				'import',
				'in',
				'instanceof',
				'new',
				'return',
				'super',
				'switch',
				'this',
				'throw',
				'try',
				'typeof',
				'void',
				'while',
				'with',
				'yield',

				// future reserved words
				'enum',
				'implements',
				'interface',
				'package',
				'private',
				'protected',
				'public',
				'static'
			],
		];
	}
}
