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
import openfl.Lib;
import openfl.text.TextField;
import openfl.text.TextFormat;

class TextEditorUtil {
	private static var _previousTabWidth:Float = 0.0;
	private static var _previousTextFormat:TextFormat;
	private static var _charWidthCache:Map<String, Float> = [];
	private static var _charHeightCache:Map<String, Float> = [];

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

	private static function updateCache(textEditor:TextEditor, text:String):Void {
		var textFormat = textEditor.getDefaultTextStyle();
		if (_previousTextFormat != textFormat) {
			_charWidthCache.clear();
			_charHeightCache.clear();
			_previousTextFormat = textFormat;
		} else if (_previousTabWidth != textEditor.tabWidth) {
			_charWidthCache.remove("\t");
		}

		var uncachedChars = "";

		// Collect uncached characters
		for (i in 0...text.length) {
			var calculatedChar = text.charAt(i);
			if (!_charWidthCache.exists(calculatedChar)) {
				if (calculatedChar == "\t" && !_charWidthCache.exists(" ")) {
					// make sure that space exists too, since tab is based on it
					uncachedChars += " ";
					_charWidthCache.set(" ", 0.0);
					_charHeightCache.set(" ", 0.0);
				}
				uncachedChars += calculatedChar;
				_charWidthCache.set(calculatedChar, 0.0);
				_charHeightCache.set(calculatedChar, 0.0);
			}
		}
		// Measure uncached characters
		if (uncachedChars.length > 0) {
			var tf = new TextField();
			tf.defaultTextFormat = textFormat;
			tf.text = uncachedChars;
			// for some reason, getCharBoundaries() is broken unless added to stage
			Lib.current.stage.addChild(tf);
			for (i in 0...uncachedChars.length) {
				var calculatedChar = uncachedChars.charAt(i);
				if (calculatedChar == "\t") {
					_previousTabWidth = textEditor.tabWidth;
					_charWidthCache.set(calculatedChar, _charWidthCache.get(" ") * textEditor.tabWidth);
					_charHeightCache.set(calculatedChar, _charHeightCache.get(" "));
				} else {
					var bounds = tf.getCharBoundaries(i);
					_charWidthCache.set(calculatedChar, bounds.width);
					_charHeightCache.set(calculatedChar, bounds.height);
				}
			}
			Lib.current.stage.removeChild(tf);
		}
	}

	public static function estimateTextWidth(textEditor:TextEditor, text:String):Float {
		updateCache(textEditor, text);

		var calculatedWidth = 0.0;
		for (i in 0...text.length) {
			var currentChar = text.charAt(i);
			calculatedWidth += _charWidthCache.get(currentChar);
		}

		return calculatedWidth;
	}

	public static function estimateTextHeight(textEditor:TextEditor, text:String):Float {
		updateCache(textEditor, text);

		var calculatedHeight = 0.0;
		for (i in 0...text.length) {
			var currentChar = text.charAt(i);
			calculatedHeight = Math.max(calculatedHeight, _charHeightCache.get(currentChar));
		}

		return calculatedHeight;
	}
}
