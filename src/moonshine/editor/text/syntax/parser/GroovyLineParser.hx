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

class GroovyLineParser extends LineParser {
	public static final GROOVY_CODE:Int = 0x1;
	public static final GROOVY_STRING1:Int = 0x2;
	public static final GROOVY_STRING2:Int = 0x3;
	public static final GROOVY_STRING3:Int = 0x4;
	public static final GROOVY_COMMENT:Int = 0x5;
	public static final GROOVY_MULTILINE_COMMENT:Int = 0x6;
	public static final GROOVY_KEYWORD:Int = 0xA;
	public static final GROOVY_PACKAGE_CLASS_KEYWORDS:Int = 0xD;
	public static final GROOVY_ANNOTATION:Int = 0xE;

	public function new() {
		super();

		context = GROOVY_CODE;
		_defaultContext = GROOVY_CODE;

		wordBoundaries = ~/([\s,(){}\[\]\-+*%\/="'~!&|<>?:;.]+)/g;

		// order matters
		patterns = [
			// "
			new LineParserPattern(GROOVY_STRING1, ~/^"(?:\\\\|\\"|[^\n])*?(?:"|\\\n|(?=\n))/),
			// '''
			new LineParserPattern(GROOVY_STRING2, ~/^'''.*?(?:'''|\n)/),
			// '
			new LineParserPattern(GROOVY_STRING3, ~/^'(?:\\\\|\\'|[^\n])*?(?:'|\\\n|(?=\n))/),
			// //
			new LineParserPattern(GROOVY_COMMENT, ~/^\/\/.*/),
			// /*
			new LineParserPattern(GROOVY_MULTILINE_COMMENT, ~/^\/\*.*?(?:\*\/|\n)/),
			// @Annotation()
			new LineParserPattern(GROOVY_ANNOTATION, ~/^@\w+(\(((["']\w+["'])|(\[(["']\w+["'])(,\s+(["']\w+["']))+\]))\))?/),
		];

		endPatterns = [
			// "
			new LineParserPattern(GROOVY_STRING1, ~/(?:^|[^\\])("|(?=\n))/),
			// '''
			new LineParserPattern(GROOVY_STRING2, ~/'''/),
			// '
			new LineParserPattern(GROOVY_STRING3, ~/(?:^|[^\\])('|(?=\n))/),
			// */
			new LineParserPattern(GROOVY_MULTILINE_COMMENT, ~/\*\//),
		];

		keywords = [
			GROOVY_KEYWORD => [
				'as', 'assert', 'boolean', 'break', 'byte', 'case', 'catch', 'char', 'const', 'continue', 'def', 'default', 'do', 'double', 'else', 'enum',
				'extends', 'false', 'finally', 'float', 'for', 'goto', 'if', 'implements', 'import', 'in', 'int', 'instanceof', 'long', 'new', 'null',
				'private',
				'protected', 'public', 'return', 'short', 'static', 'super', 'switch', 'this', 'throw', 'throws', 'trait', 'true', 'try', 'void', 'while'
			],
			GROOVY_PACKAGE_CLASS_KEYWORDS => ['package', 'class', 'interface']
		];
	}
}
