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
	Interface for line parsers.
**/
interface ILineParser {
	/**
		The default context that this line parser uses when a more specific
		context isn't required.
	**/
	@:flash.property
	public var defaultContext(get, never):Int;

	/**
		Sets the parser's current context.
	**/
	function setContext(newContext:Int):Void;

	/**
		Parses the source code and returns an array of positions and contexts.
	**/
	function parse(sourceCode:String, startLine:Int, startChar:Int, endLine:Int, endChar:Int):Array<Int>;
}
