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

package moonshine.editor.text.changes;

/**
	Specifies a range of text to remove, along with an optional string to
	replace it. If the start position and the end position are equal, no text
	is removed, and the new text is simply inserted at the new position.
**/
class TextEditorChange {
	private var _startLine:Int;

	/**
		The start line index of the text to remove.
	**/
	@:flash.property
	public var startLine(get, never):Int;

	private function get_startLine():Int {
		return _startLine;
	}

	private var _startChar:Int;

	/**
		The start character index of the text to remove.
	**/
	@:flash.property
	public var startChar(get, never):Int;

	private function get_startChar():Int {
		return _startChar;
	}

	private var _endLine:Int;

	/**
		The line character index of the text to remove.
	**/
	@:flash.property
	public var endLine(get, never):Int;

	private function get_endLine():Int {
		return _endLine;
	}

	private var _endChar:Int;

	/**
		The end character index of the text to remove.
	**/
	@:flash.property
	public var endChar(get, never):Int;

	private function get_endChar():Int {
		return _endChar;
	}

	private var _newText:String;

	/**
		The new text to insert at the position represented by `startLine` and
		`startChar`.
	**/
	@:flash.property
	public var newText(get, never):String;

	private function get_newText():String {
		return _newText;
	}

	/**
		Creates a new `TextEditorChange` object.
	**/
	public function new(startLine:Int, startChar:Int, endLine:Int, endChar:Int, ?newText:String) {
		_startLine = startLine;
		_startChar = startChar;
		_endLine = endLine;
		_endChar = endChar;
		_newText = newText;
	}
}
