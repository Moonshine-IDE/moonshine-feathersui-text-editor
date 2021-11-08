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
	Parses lines of plain text to determine how the syntax is highlighted.
**/
class PlainTextLineParser implements ILineParser {
	public static final TEXT:Int = 0x0;

	/**
		Creates a new `PlainTextLineParser` object.
	**/
	public function new() {}

	/**
		@see `ILineParser.defaultContext`
	**/
	@:flash.property
	public var defaultContext(get, never):Int;

	private function get_defaultContext():Int {
		return 0x0;
	}

	/**
		@see `ILineParser.setContext()`
	**/
	public function setContext(newContext:Int):Void {}

	/**
		@see `ILineParser.parse()`
	**/
	public function parse(sourceCode:String):Array<Int> {
		return [0, 0, sourceCode.length];
	}
}
