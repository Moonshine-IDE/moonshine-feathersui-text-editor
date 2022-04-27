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

/**
	A value object for the data associated with a line of text.
**/
class TextLineModel extends EventDispatcher {
	/**
		Creates a new `TextLineModel` object.
	**/
	public function new(text:String, lineIndex:Int) {
		super();
		this.text = text;
		this.lineIndex = lineIndex;
	}

	/**
		The index of the line.
	**/
	public var lineIndex:Int;

	/**
		The character index of the caret within the line, or `-1` if the caret
		is within a different line.
	**/
	public var caretIndex:Int = -1;

	/**
		The line's text.
	**/
	public var text:String;

	/**
		Indicates if the debugger is stopped at this line.
	**/
	public var debuggerStoppedAtLine:Bool;

	/**
		The style ranges for syntax highlighting.
	**/
	public var styleRanges:Array<Int> = null;
}
