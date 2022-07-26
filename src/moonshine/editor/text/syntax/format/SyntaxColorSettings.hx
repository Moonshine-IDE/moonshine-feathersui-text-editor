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

/**
	Default colors to use for all languages.
**/
class SyntaxColorSettings {
	public static function monokai():SyntaxColorSettings {
		var settings = new SyntaxColorSettings();

		settings.backgroundColor = 0x272822;
		settings.foregroundColor = 0xf8f8f2;
		settings.invalidColor = 0xF44747;

		settings.stringColor = 0xE6DB74;
		settings.numberColor = 0xAE81FF;
		settings.commentColor = 0x88846f;
		settings.regExpColor = 0xAE81FF;
		settings.colorColor = 0xAE81FF;
		settings.valueColor = 0xAE81FF;

		settings.keywordColor = 0xF92672;
		settings.fieldKeywordColor = 0x66D9EF;
		settings.methodKeywordColor = 0x66D9EF;
		settings.typeKeywordColor = 0x66D9EF;
		settings.moduleKeywordColor = 0xF92672;
		settings.thisSelfKeywordColor = 0xFD971F;

		settings.fieldNameColor = 0xf8f8f2;
		settings.methodNameColor = 0xA6E22E;
		settings.parameterNameColor = 0xFD971F;
		settings.typeNameColor = 0x66D9EF;
		settings.languageConstantNameColor = 0x267f99;

		settings.tagNameColor = 0xF92672;
		settings.tagAttributeNameColor = 0xA6E22E;
		settings.punctuationTagBrackets = 0xf8f8f2;

		settings.annotationColor = 0xa8a8a2;
		settings.preprocessorColor = 0xa8a8a2;

		settings.selectionBackgroundColor = 0x878b91;
		settings.selectionBackgroundAlpha = 0x80 / 0xFF;
		settings.selectionUnfocusedBackgroundColor = 0x878b91;
		settings.selectionUnfocusedBackgroundAlpha = 0x80 / 0xFF;

		settings.focusedLineBackgroundColor = 0x37352D;
		settings.debuggerStoppedLineBackgroundColor = 0x67654D;

		settings.searchResultBackgroundColor = 0x515C6A;

		settings.breakpointColor = 0xE51400;
		settings.unverifiedBreakpointColor = 0x848484;

		return settings;
	}

	public static function defaultDark():SyntaxColorSettings {
		var settings = new SyntaxColorSettings();

		settings.backgroundColor = 0x1E1E1E;
		settings.foregroundColor = 0xBBBBBB;
		settings.invalidColor = 0xf44747;

		settings.stringColor = 0xce9178;
		settings.numberColor = 0xb5cea8;
		settings.commentColor = 0x6A9955;
		settings.regExpColor = 0x646695;
		settings.colorColor = 0xCE9178;
		settings.valueColor = 0xCE9178;

		settings.keywordColor = 0x569cd6;
		settings.fieldKeywordColor = 0x569cd6;
		settings.methodKeywordColor = 0x569cd6;
		settings.typeKeywordColor = 0x569cd6;
		settings.moduleKeywordColor = 0x569cd6;
		settings.thisSelfKeywordColor = 0x569cd6;

		settings.fieldNameColor = 0x8CD8FC;
		settings.methodNameColor = 0xD9D7A4;
		settings.parameterNameColor = 0x9CDCFE;
		settings.typeNameColor = 0x4EC9B0;
		settings.languageConstantNameColor = 0x267f99;

		settings.tagNameColor = 0x569cd6;
		settings.tagAttributeNameColor = 0x8CD8FC;
		settings.punctuationTagBrackets = 0x808080;

		settings.annotationColor = 0xa0a040;
		settings.preprocessorColor = 0x7f7f7f;

		settings.selectionBackgroundColor = 0x264F78;
		settings.selectionBackgroundAlpha = 1.0;
		settings.selectionUnfocusedBackgroundColor = 0x264F78;
		settings.selectionUnfocusedBackgroundAlpha = 0.5;

		settings.focusedLineBackgroundColor = 0x243030;
		settings.debuggerStoppedLineBackgroundColor = 0x555040;

		settings.searchResultBackgroundColor = 0x515C6A;

		settings.breakpointColor = 0xE51400;
		settings.unverifiedBreakpointColor = 0x848484;

		return settings;
	}

	public static function defaultLight():SyntaxColorSettings {
		return new SyntaxColorSettings();
	}

	/**
		Creates a new `SyntaxColorSettings` object.
	**/
	public function new() {}

	public var backgroundColor:UInt = 0xfffffe;
	public var foregroundColor:UInt = 0x131313;
	public var invalidColor:UInt = 0xcd3131;

	public var stringColor:UInt = 0xa31515;
	public var numberColor:UInt = 0x098658;
	public var commentColor:UInt = 0x008000;
	public var regExpColor:UInt = 0x811f3f;
	public var colorColor:UInt = 0x0451a5;
	public var valueColor:UInt = 0x0451a5;

	public var keywordColor:UInt = 0x0000ff;
	public var fieldKeywordColor:UInt = 0x0000ff;
	public var methodKeywordColor:UInt = 0x0000ff;
	public var typeKeywordColor:UInt = 0x0000ff;
	public var moduleKeywordColor:UInt = 0x0000ff;
	public var thisSelfKeywordColor:UInt = 0x0000ff;

	public var fieldNameColor:UInt = 0x001080;
	public var methodNameColor:UInt = 0x795E26;
	public var parameterNameColor:UInt = 0x001080;
	public var typeNameColor:UInt = 0x267f99;
	public var languageConstantNameColor:UInt = 0x267f99;

	public var tagNameColor:UInt = 0x800000;
	public var tagAttributeNameColor:UInt = 0xff0000;
	public var punctuationTagBrackets:UInt = 0x800000;

	public var annotationColor:UInt = 0x808000;
	public var preprocessorColor:UInt = 0xa31515;

	public var selectionBackgroundColor:UInt = 0xADD6FF;
	public var selectionBackgroundAlpha:Float = 1.0;
	public var selectionUnfocusedBackgroundColor:UInt = 0xADD6FF;
	public var selectionUnfocusedBackgroundAlpha:Float = 0.5;

	public var focusedLineBackgroundColor:UInt = 0xedfbfb;
	public var debuggerStoppedLineBackgroundColor:UInt = 0xffffcc;

	public var searchResultBackgroundColor:UInt = 0xA8AC94;

	public var breakpointColor:UInt = 0xE51400;
	public var unverifiedBreakpointColor:UInt = 0x848484;
}
