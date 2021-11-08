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
	Parses lines of Java code to determine how the syntax is highlighted.
**/
class JavaLineParser extends LineParser {
	public static final JAVA_CODE:Int = 0x1;
	public static final JAVA_STRING1:Int = 0x2;
	public static final JAVA_STRING2:Int = 0x3;
	public static final JAVA_COMMENT:Int = 0x4;
	public static final JAVA_MULTILINE_COMMENT:Int = 0x5;
	public static final JAVA_KEYWORD:Int = 0xA;
	public static final JAVA_PACKAGE_CLASS_KEYWORDS:Int = 0xD;
	public static final JAVA_ANNOTATION:Int = 0xE;

	/**
		Creates a new `JavaLineParser` object.
	**/
	public function new() {
		super();

		context = JAVA_CODE;
		_defaultContext = JAVA_CODE;

		wordBoundaries = ~/([\s,(){}\[\]\-+*%\/="'~!&|<>?:;.]+)/g;

		// order matters
		patterns = [
			// "
			new LineParserPattern(JAVA_STRING1, ~/^"(?:\\\\|\\"|[^\n])*?(?:"|\\\n|(?=\n))/),
			// '
			new LineParserPattern(JAVA_STRING2, ~/^'(?:\\\\|\\'|[^\n])*?(?:'|\\\n|(?=\n))/),
			// //
			new LineParserPattern(JAVA_COMMENT, ~/^\/\/.*/),
			// /*
			new LineParserPattern(JAVA_MULTILINE_COMMENT, ~/^\/\*.*?(?:\*\/|\n)/),
			// @Annotation
			new LineParserPattern(JAVA_ANNOTATION, ~/^@\w+(\(((["']\w+["'])|({(["']\w+["'])(,\s+(["']\w+["']))+}))\))?/),
		];

		endPatterns = [
			// "
			new LineParserPattern(JAVA_STRING1, ~/(?:^|[^\\])("|(?=\n))/),
			// '
			new LineParserPattern(JAVA_STRING2, ~/(?:^|[^\\])('|(?=\n))/),
			// */
			new LineParserPattern(JAVA_MULTILINE_COMMENT, ~/\*\//),
		];

		keywords = [
			JAVA_KEYWORD => [
				'abstract', 'continue', 'for', 'new', 'switch', 'assert', 'default', 'goto', 'synchronized', 'boolean', 'do', 'if', 'private', 'this', 'break',
				'double', 'implements', 'protected', 'throw', 'byte', 'else', 'import', 'public', 'throws', 'case', 'enum', 'instanceof', 'return', 'transient',
				'catch', 'extends', 'int', 'short', 'try', 'char', 'final', 'static', 'void', 'finally', 'long', 'strictfp', 'volatile', 'const', 'float',
				'native', 'super', 'while'
			],
			JAVA_PACKAGE_CLASS_KEYWORDS => ['package', 'class', 'interface']
		];
	}
}
