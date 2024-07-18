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

package moonshine.editor.text.managers;

import moonshine.editor.text.events.TextEditorChangeEvent;
import moonshine.editor.text.utils.TextEditorUtil;
import openfl.desktop.Clipboard;
import openfl.desktop.ClipboardFormats;
import openfl.errors.IllegalOperationError;
import openfl.events.Event;

/**
	Used internally by `TextEditor` to manage clipboard interactions.
**/
class ClipboardManager {
	/**
		Creates a new `ClipboardManager` object.
	**/
	public function new(textEditor:TextEditor) {
		_textEditor = textEditor;
		_textEditor.addEventListener(Event.COPY, clipboardManager_textEditor_copyHandler, false, 0, true);
		_textEditor.addEventListener(Event.CUT, clipboardManager_textEditor_cutHandler, false, 0, true);
		#if !html5
		// the html5 target dispatches TextEvent.TEXT_INPUT on paste
		// when stage.window.textInputEnabled == true
		_textEditor.addEventListener(Event.PASTE, clipboardManager_textEditor_pasteHandler, false, 0, true);
		#end
	}

	private var _textEditor:TextEditor;

	/**
		Copies the current selection, if there is a selection.
	**/
	public function copy():Void {
		if (!_textEditor.hasSelection) {
			// don't update the clipboard if nothing is selected
			return;
		}
		Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, _textEditor.selectedText, false);
	}

	/**
		Cuts the current selection, if there is a selection.
	**/
	public function cut():Void {
		if (_textEditor.readOnly) {
			throw new IllegalOperationError("Cannot cut when editor is read-only");
		}
		copy();
		if (_textEditor.hasSelection) {
			// don't remove anything if nothing is selected
			var change = TextEditorUtil.deleteSelection(_textEditor);
			if (change != null) {
				_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, [change]));
			}
		}
	}

	/**
		Pastes text from the clipboard, if any is available.
	**/
	public function paste():Void {
		if (_textEditor.readOnly) {
			throw new IllegalOperationError("Cannot paste when editor is read-only");
		}
		if (!Clipboard.generalClipboard.hasFormat(ClipboardFormats.TEXT_FORMAT)) {
			return;
		}
		var newText = Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT);
		var change = TextEditorUtil.deleteSelection(_textEditor, newText);
		if (change != null) {
			_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, [change]));
		}
	}

	private function clipboardManager_textEditor_cutHandler(event:Event):Void {
		if (_textEditor.readOnly || event.isDefaultPrevented()) {
			return;
		}
		cut();
	}

	private function clipboardManager_textEditor_copyHandler(event:Event):Void {
		if (event.isDefaultPrevented()) {
			return;
		}
		copy();
	}

	private function clipboardManager_textEditor_pasteHandler(event:Event):Void {
		if (_textEditor.readOnly || event.isDefaultPrevented()) {
			return;
		}
		paste();
	}
}
