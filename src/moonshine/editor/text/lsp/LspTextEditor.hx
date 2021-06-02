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

package moonshine.editor.text.lsp;

import moonshine.lsp.Range;
import moonshine.lsp.TextDocumentIdentifier;
import moonshine.editor.text.lsp.managers.DefinitionManager;
import moonshine.lsp.DefinitionParams;
import moonshine.lsp.CodeActionParams;
import moonshine.lsp.HoverParams;
import moonshine.lsp.Position;
import moonshine.lsp.CompletionParams;
import moonshine.lsp.SignatureHelpParams;
import openfl.errors.IllegalOperationError;
import feathers.data.ListViewItemState;
import moonshine.editor.text.lines.TextLineModel;
import moonshine.editor.text.lines.TextLineRenderer;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageActionEvent;
import moonshine.editor.text.lsp.lines.LspTextLineRenderer;
import moonshine.editor.text.lsp.managers.CodeActionsManager;
import moonshine.editor.text.lsp.managers.CompletionManager;
import moonshine.editor.text.lsp.managers.HoverManager;
import moonshine.editor.text.lsp.managers.SignatureHelpManager;
import moonshine.editor.text.utils.TextUtil;
import moonshine.lsp.CodeAction;
import moonshine.lsp.Diagnostic;
import moonshine.lsp.LocationLink;
import openfl.events.MouseEvent;
import openfl.geom.Point;

class LspTextEditor extends TextEditor {
	public function new(?textDocument:TextDocumentIdentifier, ?text:String, readOnly:Bool = false) {
		super(text, readOnly);
		this._textDocument = textDocument;
		if (!_readOnly) {
			_completionManager = new CompletionManager(this);
			_signatureHelpManager = new SignatureHelpManager(this);
			_codeActionsManager = new CodeActionsManager(this, activateCodeAction);
		}
		_hoverManager = new HoverManager(this);
		_definitionManager = new DefinitionManager(this, handleDefinition, handleDefinitionLink);
	}

	private var _completionManager:CompletionManager;
	private var _signatureHelpManager:SignatureHelpManager;
	private var _hoverManager:HoverManager;
	private var _definitionManager:DefinitionManager;
	private var _codeActionsManager:CodeActionsManager;

	private var _linksPosition:Position;
	private var _linkStartChar:Int = -1;
	private var _linkEndChar:Int = -1;
	private var _links:Array<LocationLink> = null;

	public var completionTriggerCharacters:Array<String> = ["."];
	public var signatureHelpTriggerCharacters:Array<String> = ["(", ","];

	public var diagnostics:Array<Diagnostic> = [];

	private var _textDocument:TextDocumentIdentifier;

	public var textDocument(get, set):TextDocumentIdentifier;

	private function get_textDocument():TextDocumentIdentifier {
		return _textDocument;
	}

	private function set_textDocument(value:TextDocumentIdentifier):TextDocumentIdentifier {
		_textDocument = value;
		return _textDocument;
	}

	public function completion():Void {
		if (_readOnly) {
			throw new IllegalOperationError("Completion is not allowed in a read-only text editor editor");
		}
		_completionManager.dispatchCompletionEvent({
			textDocument: _textDocument,
			position: new Position(caretLineIndex, caretCharIndex),
		});
	}

	public function signatureHelp():Void {
		_signatureHelpManager.dispatchSignatureHelpEvent({
			textDocument: _textDocument,
			position: new Position(caretLineIndex, caretCharIndex),
		});
	}

	public function hover():Void {
		_hoverManager.dispatchHoverEvent({
			textDocument: _textDocument,
			position: new Position(caretLineIndex, caretCharIndex),
		});
	}

	public function definition():Void {
		_definitionManager.dispatchDefinitionEvent({
			textDocument: _textDocument,
			position: new Position(caretLineIndex, caretCharIndex),
		});
	}

	public function codeActions():Void {
		if (_readOnly) {
			throw new IllegalOperationError("Code actions are not allowed in a read-only text editor editor");
		}
		var range:Range = if (hasSelection) {
			new Range(new Position(selectionStartLineIndex, selectionStartCharIndex), new Position(selectionEndLineIndex, selectionEndCharIndex));
		} else {
			new Range(new Position(caretLineIndex, caretCharIndex), new Position(caretLineIndex, caretCharIndex));
		};
		_codeActionsManager.dispatchCodeActionsEvent({
			textDocument: _textDocument,
			range: range,
			// TODO: get diagnostics for line
			context: {diagnostics: []},
		});
	}

	override private function createTextLineRenderer():TextLineRenderer {
		var renderer = new LspTextLineRenderer();
		renderer.addEventListener(MouseEvent.CLICK, lspTextEditor_textLineRenderer_clickHandler);
		return renderer;
	}

	override private function destroyTextLineRenderer(renderer:TextLineRenderer):Void {
		super.destroyTextLineRenderer(renderer);
		renderer.removeEventListener(MouseEvent.CLICK, lspTextEditor_textLineRenderer_clickHandler);
	}

	override private function updateTextLineRenderer(itemRenderer:TextLineRenderer, state:ListViewItemState):Void {
		super.updateTextLineRenderer(itemRenderer, state);

		var lspItemRenderer = cast(itemRenderer, LspTextLineRenderer);
		lspItemRenderer.diagnostics = diagnostics;

		var line = (state.data : TextLineModel);

		if (_linksPosition != null && _linksPosition.line == line.lineIndex) {
			itemRenderer.linkStartChar = _linkStartChar;
			itemRenderer.linkEndChar = _linkEndChar;
		} else {
			itemRenderer.linkStartChar = -1;
			itemRenderer.linkEndChar = -1;
		}
	}

	private function handleDefinition(position:Position, ?locations:Array<LocationLink>):Void {
		if (locations == null || locations.length == 0) {
			return;
		}
		dispatchEvent(new LspTextEditorLanguageActionEvent(LspTextEditorLanguageActionEvent.OPEN_LINK, locations));
	}

	private function handleDefinitionLink(position:Position, ?locations:Array<LocationLink>):Void {
		_linksPosition = position;
		_links = locations;

		_linkStartChar = -1;
		_linkEndChar = -1;
		if (_linksPosition != null && _links != null && _links.length > 0) {
			var line = _lines.get(_linksPosition.line);
			var locationLink = _links[0];
			var originSelectionRange = locationLink.originSelectionRange;
			if (originSelectionRange != null) {
				if (_linksPosition.line == originSelectionRange.start.line) {
					_linkStartChar = originSelectionRange.start.character;
				}
				if (_linksPosition.line == originSelectionRange.end.line) {
					_linkEndChar = originSelectionRange.end.character;
				}
			}
			if (_linkStartChar == -1) {
				_linkStartChar = TextUtil.startOfWord(line.text, _linksPosition.character);
			}
			if (_linkEndChar == -1) {
				_linkEndChar = TextUtil.endOfWord(line.text, _linksPosition.character);
			}
		}

		_lines.updateAll();
	}

	private function activateCodeAction(codeAction:CodeAction):Void {
		if (codeAction.edit != null) {
			dispatchEvent(new LspTextEditorLanguageActionEvent(LspTextEditorLanguageActionEvent.APPLY_WORKSPACE_EDIT, codeAction.edit));
		}
		if (codeAction.command != null) {
			dispatchEvent(new LspTextEditorLanguageActionEvent(LspTextEditorLanguageActionEvent.RUN_COMMAND, codeAction.command));
		}
	}

	private function lspTextEditor_textLineRenderer_clickHandler(event:MouseEvent):Void {
		var textLineRenderer = cast(event.currentTarget, LspTextLineRenderer);
		if (textLineRenderer.linkStartChar == -1 || textLineRenderer.linkEndChar == -1) {
			return;
		}
		var position = localToTextEditorPosition(new Point(mouseX, mouseY));
		if (position.line != _linksPosition.line) {
			return;
		}
		if (position.character < textLineRenderer.linkStartChar || position.character >= textLineRenderer.linkEndChar) {
			return;
		}
		dispatchEvent(new LspTextEditorLanguageActionEvent(LspTextEditorLanguageActionEvent.OPEN_LINK, _links));
	}
}
