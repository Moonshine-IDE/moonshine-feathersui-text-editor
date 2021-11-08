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

package moonshine.editor.text.utils;

import moonshine.editor.text.changes.TextEditorChange;

/**
	Utility functions for the `TextEditor` component.
**/
class TextEditorUtil {
	/**
		Applies a `TextEditorChange` to an array of strings representing a file
		displayed by a `TextEditor`.
	**/
	public static function applyTextChangeToLines(lines:Array<String>, change:TextEditorChange):Array<String> {
		var result = lines.copy();

		var startLine = change.startLine;
		var startChar = change.startChar;
		var endLine = change.endLine;
		var endChar = change.endChar;

		var newText = change.newText;
		var insertedLines:Array<String> = null;
		if (newText != null && newText.length > 0) {
			insertedLines = ~/\r?\n|\r/g.split(newText);
		}

		var startTextToKeep = result[startLine].substring(0, startChar);
		var endTextToKeep = result[endLine].substring(endChar);

		// Remove all lines after the first
		if (startLine != endLine) {
			result.splice(startLine + 1, endLine - startLine);
		}

		if (insertedLines == null) {
			// remove only
			result[startLine] = startTextToKeep + endTextToKeep;
		} else {
			for (i in 0...insertedLines.length) {
				var updatedText = "";
				if (i == 0) {
					updatedText = startTextToKeep;
				}
				updatedText += insertedLines[i];
				if (i == (insertedLines.length - 1)) {
					updatedText += endTextToKeep;
				}
				result[startLine + i] = updatedText;
			}
		}
		return result;
	}
}
