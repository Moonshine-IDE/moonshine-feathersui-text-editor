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

class SyntaxFontSettings {
	public function new() {}

	public var fontFamily:String = "_typewriter";
	public var fontSize:Int = 13;

	// Width of a tab-stop, in characters
	public var tabWidth:Int = 4;

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
