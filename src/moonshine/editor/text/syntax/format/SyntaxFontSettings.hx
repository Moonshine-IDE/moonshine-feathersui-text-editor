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
	Default font styles to use for all languages.
**/
class SyntaxFontSettings {
	/**
		Creates a new `SyntaxFontSettings` object.
	**/
	public function new(fontFamily:String = "_typewriter", fontSize:Int = 14) {
		this.fontFamily = fontFamily;
		this.fontSize = fontSize;
	}

	/**
		The default font family.
	**/
	public var fontFamily:String;

	/**
		The default font size.
	**/
	public var fontSize:Int;

	/**
		The default tab stops.
	**/
	public var tabStops:Array<Int> = {
		var stops:Array<Int> = [];
		var value = 0;
		for (i in 0...100) {
			value += Math.ceil(7.82666015625 * 4);
			stops.push(value);
		}
		stops;
	}
}
