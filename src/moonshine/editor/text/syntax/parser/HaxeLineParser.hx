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
	Parses lines of Haxe code to determine how the syntax is highlighted.
**/
class HaxeLineParser extends LineParser {
	public static final HX_CODE:Int = 0x1;
	public static final HX_STRING1:Int = 0x2;
	public static final HX_STRING2:Int = 0x3;
	public static final HX_COMMENT:Int = 0x4;
	public static final HX_MULTILINE_COMMENT:Int = 0x5;
	public static final HX_REGULAR_EXPRESSION:Int = 0x6;
	public static final HX_KEYWORD:Int = 0xA;
	public static final HX_VAR_KEYWORD:Int = 0xB;
	public static final HX_FUNCTION_KEYWORD:Int = 0xC;
	public static final HX_TYPE_KEYWORDS:Int = 0xD;
	public static final HX_METADATA:Int = 0xE;
	public static final HX_FIELD:Int = 0xF;
	public static final HX_FUNCTIONS:Int = 0x11;
	public static final HX_CONDITIONAL:Int = 0x12;
	public static final HX_SELF_KEYWORDS:Int = 0x13;
	public static final HX_VALUE_KEYWORDS:Int = 0x14;
	public static final HX_PACKAGE_KEYWORD:Int = 0x15;

	/**
		Creates a new `HaxeLineParser` object.
	**/
	public function new() {
		super();

		context = HX_CODE;
		_defaultContext = HX_CODE;

		wordBoundaries = ~/([\s,(){}\[\]\-+*%\/="'~!&|<>?:;.]+)/;

		// order matters
		patterns = [
			// #conditional
			new LineParserPattern(HX_CONDITIONAL,
				~/#(((if|elseif)((\s?\(.*?\))|(\s[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)*)?))|else|end|error|line)/),
			// "
			new LineParserPattern(HX_STRING1, ~/^"(?:\\\\|\\"|[^\n])*?(?:"|\\\n|(?=\n))/),
			// '
			new LineParserPattern(HX_STRING2, ~/^'(?:\\\\|\\'|[^\n])*?(?:'|\\\n|(?=\n))/),
			// //
			new LineParserPattern(HX_COMMENT, ~/^\/\/.*/),
			// /*
			new LineParserPattern(HX_MULTILINE_COMMENT, ~/^\/\*.*?(?:\*\/|\n)/),
			// ~/pattern/
			new LineParserPattern(HX_REGULAR_EXPRESSION, ~/^\/(?:\\\\|\\\/|\[(?:\\\\|\\\]|.)+?\]|[^*\/])(?:\\\\|\\\/|\[(?:\\\\|\\\]|.)+?\]|.)*?\/[gismx]*/),
			// @:metadata
			new LineParserPattern(HX_METADATA,
				~/^@:(?:(abi|abstract|access|allow|analyzer|annotation|arrayAccess|astSource|autoBuild|bind|bitmap|bridgeProperties|build|buildXml|bypassAccessor|callable|classCode|commutative|compilerGenerated|const|coreApi|coreType|cppFileCode|cppInclude|cppNamespaceCode|cs.assemblyMeta|cs.assemblyStrict|cs.using|dce|debug|decl|delegate|depend|deprecated|eager|enum|event|expose|extern|file|fileXml|final|fixed|flash.property|font|forward.new|forward.variance|forward|forwardStatics|from|functionCode|functionTailCode|generic|genericBuild|genericClassPerMethod|getter|hack|headerClassCode|headerCode|headerInclude|headerNamespaceCode|hlNative|hxGen|ifFeature|include|inheritDoc|inline|internal|isVar|java.native|javaCanonical|jsRequire|jvm.synthetic|keep|keepInit|keepSub|luaDotMethod|luaRequire|macro|markup|mergeBlock|meta|multiReturn|multiType|native|nativeChildren|nativeGen|nativeProperty|nativeStaticExtension|noClosure|noCompletion|noDebug|noDoc|noImportGlobal|noPrivateAccess|noStack|noUsing|nonVirtual|notNull|nullSafety|objc|objcProtocol|op|optional|overload|persistent|phpClassConst|phpGlobal|phpMagic|phpNoConstructor|pos|private|privateAccess|property|protected|publicFields|pure|pythonImport|readOnly|remove|require|resolve|rtti|runtimeValue|scalar|selfCall|semantics|setter|sound|sourceFile|stackOnly|strict|struct|structAccess|structInit|suppressWarnings|templatedCall|throws|to|transient|transitive|unifyMinDynamic|unreflective|unsafe|using|void|volatile))/),
			// fieldName(get, set):Type;
			new LineParserPattern(HX_FIELD, ~/^\s+\w+(?=(\((default|get|never|null),\s*(default|set|never|null)\))?:\w+(<[\w\s,]+>)?(\s*=\s*[^;]+)?;$)/),
			// methodName():Type
			new LineParserPattern(HX_FUNCTIONS, ~/^\s+\w+(?=\((\s*|.+)\):([^:]+)$)/),
		];

		endPatterns = [
			new LineParserPattern(HX_STRING1, ~/(?:^|[^\\])("|(?=\n))/),
			new LineParserPattern(HX_STRING2, ~/(?:^|[^\\])('|(?=\n))/),
			new LineParserPattern(HX_MULTILINE_COMMENT, ~/\*\//),
		];

		keywords = [
			HX_KEYWORD => [
				'abstract', 'break', 'case', 'cast', 'catch', 'continue', 'default', 'do', 'dynamic', 'else', 'extends', 'extern', 'final', 'for', 'if',
				'implements', 'import', 'in', 'inline', 'macro', 'new', 'overload', 'override', 'private', 'public', 'return', 'static', 'switch', 'throw',
				'try',
				'typedef', 'untyped', 'using', 'while', 'get', 'set', 'never'
			],
			HX_VAR_KEYWORD => ['var'],
			HX_FUNCTION_KEYWORD => ['function'],
			HX_PACKAGE_KEYWORD => ['package'],
			HX_TYPE_KEYWORDS => ['class', 'interface', 'enum'],
			HX_SELF_KEYWORDS => ['this', 'super'],
			HX_VALUE_KEYWORDS => ['true', 'false', 'null']
		];
	}
}
