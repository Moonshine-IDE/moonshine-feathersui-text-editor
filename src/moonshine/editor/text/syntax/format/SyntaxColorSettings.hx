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
	/**
		Creates a new `SyntaxColorSettings` object.
	**/
	public function new() {}

	public var backgroundColor:UInt = 0xffffff;
	public var foregroundColor:UInt = 0x000000;
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
	public var preprocessorColor:UInt = 0x0000ff;
}
