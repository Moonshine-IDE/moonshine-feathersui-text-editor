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

package moonshine.editor.text;

/**
	A set of line and character indices that represents a position within a
	`TextEditor`.
**/
class TextEditorPosition {
	/**
		Creates a new `TextEditorPosition` object.
	**/
	public function new(line:Int = 0, character:Int = 0) {
		this.line = line;
		this.character = character;
	}

	/**
		A line index within the text editor's content.
	**/
	public var line:Int;

	/**
		A character index within a line.
	**/
	public var character:Int;
}
