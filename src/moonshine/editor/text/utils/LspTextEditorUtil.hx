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
import moonshine.lsp.Position;
import moonshine.lsp.TextEdit;

/**
	Utility functions for the `LspTextEditor` component.
**/
class LspTextEditorUtil {
	/**
		Converts a `TextEdit` value object from the language server protocol
		to a `TextEditorChange` object used by the `TextEditor` component.
	**/
	public static function lspTextEditToTextEditorChange(textEdit:TextEdit):TextEditorChange {
		return new TextEditorChange(textEdit.range.start.line, textEdit.range.start.character, textEdit.range.end.line, textEdit.range.end.character,
			textEdit.newText);
	}

	/**
		Converts a `TextEditorPosition` value object from the language server
		protocol to a `Position` object used by the `TextEditor`
		component.
	**/
	public static function textEditorPositionToLspPosition(pos:TextEditorPosition):Position {
		return new Position(pos.line, pos.character);
	}

	/**
		Converts a `Position` used by the `TextEditor` component to a
		`TextEditorPosition` value object from the language server protocol.
	**/
	public static function lspPositionToTextEditorPosition(pos:Position):TextEditorPosition {
		return new TextEditorPosition(pos.line, pos.character);
	}
}
