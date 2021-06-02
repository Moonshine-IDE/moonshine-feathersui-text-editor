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

class PythonLineParser extends LineParser {
	public static final PY_CODE:Int = 0x1;
	public static final PY_STRING1:Int = 0x2;
	public static final PY_STRING2:Int = 0x3;
	public static final PY_MULTILINE_STRING:Int = 0x4;
	public static final PY_COMMENT:Int = 0x5;
	public static final PY_KEYWORD:Int = 0x6;
	public static final PY_FUNCTION_KEYWORD:Int = 0xA;
	public static final PY_PACKAGE_CLASS_KEYWORDS:Int = 0xB;

	public function new() {
		super();

		context = PY_CODE;
		_defaultContext = PY_CODE;

		wordBoundaries = ~/([\s,(){}\[\]\-+*%\/="'~!&|<>?:;.]+)/g;

		// order matters
		patterns = [
			new LineParserPattern(PY_MULTILINE_STRING, ~/^""".*?(?:"""|\n)/),
			new LineParserPattern(PY_STRING1, ~/^"(?:\\\\|\\"|[^\n])*?(?:"|\\\n|(?=\n))/),
			new LineParserPattern(PY_STRING2, ~/^'(?:\\\\|\\'|[^\n])*?(?:'|\\\n|(?=\n))/),
			new LineParserPattern(PY_COMMENT, ~/^#.*/),
		];

		endPatterns = [
			// "
			new LineParserPattern(PY_STRING1, ~/(?:^|[^\\])("|(?=\n))/),
			// '
			new LineParserPattern(PY_STRING2, ~/(?:^|[^\\])('|(?=\n))/),
			// """
			new LineParserPattern(PY_MULTILINE_STRING, ~/"""/),
		];

		keywords = [
			PY_KEYWORD => [
				'and', 'del', 'for', 'is', 'raise', 'assert', 'elif', 'from', 'lambda', 'return', 'break', 'else', 'global', 'not', 'try', 'except', 'if', 'or',
				'while', 'continue', 'exec', 'import', 'pass', 'yield', 'finally', 'in', 'print'
			],
			PY_FUNCTION_KEYWORD => ['def'],
			PY_PACKAGE_CLASS_KEYWORDS => ['class']
		];
	}
}
