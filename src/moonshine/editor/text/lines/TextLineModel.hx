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

package moonshine.editor.text.lines;

import openfl.events.EventDispatcher;

class TextLineModel extends EventDispatcher {
	public function new(text:String, lineIndex:Int) {
		super();
		this.text = text;
		this.lineIndex = lineIndex;
	}

	public var lineIndex:Int;
	public var caretIndex:Int = -1;
	public var text:String;
	public var breakpoint:Bool;
	public var debuggerStoppedAtLine:Bool;

	public var styleRanges:Array<Int> = [0, 0];

	@:flash.property
	public var startContext(get, never):Int;

	public function get_startContext():Int {
		return (styleRanges != null) && styleRanges.length > 1 ? styleRanges[1] : 0;
	}

	@:flash.property
	public var endContext(get, never):Int;

	public function get_endContext():Int {
		return (styleRanges != null) && styleRanges.length > 1 ? styleRanges[styleRanges.length - 1] : 0;
	}

	// public var diagnostics:Array<Diagnostic>;
	// public var codeActions:Array<CodeAction>;
}
