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
	Parses lines of ActionScript 3.0 (AS3) code to determine how the syntax is
	highlighted.
**/
class AS3LineParser extends LineParser {
	public static final AS_CODE:Int = 0x1;
	public static final AS_STRING1:Int = 0x2;
	public static final AS_STRING2:Int = 0x3;
	public static final AS_COMMENT:Int = 0x4;
	public static final AS_MULTILINE_COMMENT:Int = 0x5;
	public static final AS_REGULAR_EXPRESSION:Int = 0x6;
	public static final AS_KEYWORD:Int = 0xA;
	public static final AS_VAR_KEYWORD:Int = 0xB;
	public static final AS_FUNCTION_KEYWORD:Int = 0xC;
	public static final AS_PACKAGE_KEYWORD:Int = 0xD;
	public static final AS_TYPE_KEYWORD:Int = 0xE;
	public static final AS_METADATA:Int = 0xF;
	public static final AS_FIELD:Int = 0x10;
	public static final AS_FUNCTIONS:Int = 0x11;

	/**
		Creates a new `AS3LineParser` object.
	**/
	public function new() {
		super();

		context = AS_CODE;
		_defaultContext = AS_CODE;

		wordBoundaries = ~/([\s,(){}\[\]\-+*%\/="'~!&|<>?:;.]+)/g;

		// order matters
		patterns = [
			// "
			new LineParserPattern(AS_STRING1, ~/^"(?:\\\\|\\"|[^\n])*?(?:"|\\\n|(?=\n))/),
			// '
			new LineParserPattern(AS_STRING2, ~/^'(?:\\\\|\\'|[^\n])*?(?:'|\\\n|(?=\n))/),
			// //
			new LineParserPattern(AS_COMMENT, ~/^\/\/.*/),
			// /*
			new LineParserPattern(AS_MULTILINE_COMMENT, ~/^\/\*.*?(?:\*\/|\n)/),
			// /pattern/
			new LineParserPattern(AS_REGULAR_EXPRESSION, ~/^\/(?:\\\\|\\\/|\[(?:\\\\|\\\]|.)+?\]|[^*\/])(?:\\\\|\\\/|\[(?:\\\\|\\\]|.)+?\]|.)*?\/[gismx]*/),
			// [Metadata()]
			new LineParserPattern(AS_METADATA,
				~/^\[(?:(Bindable|Event|Exclude|Style|ResourceBundle|IconFile|DefaultProperty|Inspectable|SkinState|Effect|SkinPart)(?:\([^\)]*\))?)\]/),
			// fieldName:Type = value
			new LineParserPattern(AS_FIELD, ~/^\s+\w+(?=:\w+(\s*=\s*[^;]+)?;)/),
			// methodName():Type
			new LineParserPattern(AS_FUNCTIONS, ~/^\s+\w+(?=\((\s*|.+)\):([^:]+)$)/),
		];

		endPatterns = [
			new LineParserPattern(AS_STRING1, ~/(?:^|[^\\])("|(?=\n))/),
			new LineParserPattern(AS_STRING2, ~/(?:^|[^\\])('|(?=\n))/),
			new LineParserPattern(AS_MULTILINE_COMMENT, ~/\*\//),
		];

		keywords = [
			AS_VAR_KEYWORD => ['var', 'const'],
			AS_FUNCTION_KEYWORD => ['function'],
			AS_PACKAGE_KEYWORD => ['package'],
			AS_TYPE_KEYWORD => ['class', 'interface'],
			AS_KEYWORD => [
				'is', 'if', 'in', 'as', 'new', 'for', 'use', 'set', 'get', 'try', 'null', 'true', 'void', 'else', 'each', 'case', 'this', 'break', 'false',
				'final', 'catch', 'class', 'return', 'switch', 'static', 'import', 'private', 'public', 'extends', 'override', 'inherits', 'internal',
				'implements', 'package', 'protected', 'namespace', 'final', 'native', 'dynamic', 'delete', 'throw', 'finally', 'super'
			],
		];
	}
}
