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

import moonshine.editor.text.events.TextEditorChangeEvent;
import moonshine.editor.text.lines.TextLineModel;
import moonshine.editor.text.lines.TextLineRenderer;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageActionEvent;
import moonshine.editor.text.lsp.lines.LspTextLineRenderer;
import moonshine.editor.text.lsp.managers.CodeActionsManager;
import moonshine.editor.text.lsp.managers.CommandManager;
import moonshine.editor.text.lsp.managers.CompletionManager;
import moonshine.editor.text.lsp.managers.DefinitionManager;
import moonshine.editor.text.lsp.managers.HoverManager;
import moonshine.editor.text.lsp.managers.SignatureHelpManager;
import moonshine.editor.text.utils.LspTextEditorUtil;
import moonshine.editor.text.utils.TextUtil;
import moonshine.lsp.CodeAction;
import moonshine.lsp.Command;
import moonshine.lsp.Diagnostic;
import moonshine.lsp.LocationLink;
import moonshine.lsp.Position;
import moonshine.lsp.Range;
import moonshine.lsp.TextDocumentIdentifier;
import moonshine.lsp.TextEdit;
import openfl.errors.IllegalOperationError;
import openfl.events.MouseEvent;
import openfl.geom.Point;

/**
	Adds language code intelligence features to the `TextEditor` component, such
	as completion, signature help, hover tool tips, ctrl+click jump to
	definition, etc.

	This component uses value objects (VOs) that are based on the
	_Language Server Protocol_ (which is where the name `LspTextEditor` comes
	from). However, using this protocol is not mandatory. As long as objects are
	translated into LSP VOs, any other provider of code intelligence data may be
	used instead.
**/
class LspTextEditor extends TextEditor {
	/**
		Creates a new `LspTextEditor` object.
	**/
	public function new(?textDocument:TextDocumentIdentifier, ?text:String, readOnly:Bool = false) {
		super(text, readOnly);
		_textDocument = textDocument;
		if (!_readOnly) {
			_completionManager = new CompletionManager(this);
			_signatureHelpManager = new SignatureHelpManager(this);
			_codeActionsManager = new CodeActionsManager(this, activateCodeAction);
			_commandManager = new CommandManager(this);
		}
		_hoverManager = new HoverManager(this);
		_definitionManager = new DefinitionManager(this, handleDefinition, handleDefinitionLink);
	}

	private var _completionManager:CompletionManager;
	private var _signatureHelpManager:SignatureHelpManager;
	private var _hoverManager:HoverManager;
	private var _definitionManager:DefinitionManager;
	private var _codeActionsManager:CodeActionsManager;
	private var _commandManager:CommandManager;

	private var _linksPosition:Position;
	private var _linkStartChar:Int = -1;
	private var _linkEndChar:Int = -1;
	private var _links:Array<LocationLink> = null;

	/**
		A set of characters that, when typed by the user, will trigger a request
		for completion.
	**/
	public var completionTriggerCharacters:Array<String> = ["."];

	/**
		A set of characters that, when typed by the user, will trigger a request
		for signature help.
	**/
	public var signatureHelpTriggerCharacters:Array<String> = ["(", ","];

	private var _diagnostics:Array<Diagnostic>;

	/**
		The diagnostics (compiler errors, warnings, and informational messages)
		that are associated with the currently displayed file.
	**/
	@:flash.property
	public var diagnostics(get, set):Array<Diagnostic>;

	private function get_diagnostics():Array<Diagnostic> {
		return _diagnostics;
	}

	private function set_diagnostics(value:Array<Diagnostic>):Array<Diagnostic> {
		if (_diagnostics == value) {
			return _diagnostics;
		}
		if (_diagnostics != null) {
			for (diagnostic in _diagnostics) {
				var start = diagnostic.range.start.line;
				var end = diagnostic.range.end.line + 1;
				if (end > _lines.length) {
					end = _lines.length;
				}
				for (i in start...end) {
					_lines.updateAt(i);
				}
			}
		}
		_diagnostics = value;
		if (_diagnostics != null) {
			for (diagnostic in _diagnostics) {
				var start = diagnostic.range.start.line;
				var end = diagnostic.range.end.line + 1;
				if (end > _lines.length) {
					end = _lines.length;
				}
				for (i in start...end) {
					_lines.updateAt(i);
				}
			}
		}
		setInvalid(DATA);
		return _diagnostics;
	}

	private var _textDocument:TextDocumentIdentifier;

	/**
		The URI identifier associated with the currently displayed file.
	**/
	@:flash.property
	public var textDocument(get, set):TextDocumentIdentifier;

	private function get_textDocument():TextDocumentIdentifier {
		return _textDocument;
	}

	private function set_textDocument(value:TextDocumentIdentifier):TextDocumentIdentifier {
		_textDocument = value;
		return _textDocument;
	}

	/**
		Cancels active requests and clears any pop-up views.
	**/
	public function clearAll():Void {
		clearCompletion();
		clearSignatureHelp();
		clearHover();
		clearCodeActions();
	}

	/**
		Cancels active completion requests and clears the pop-up completion
		list view.
	**/
	public function clearCompletion():Void {
		if (_completionManager == null) {
			// will be null when read-only
			return;
		}
		_completionManager.clear();
	}

	/**
		Cancels active signature help requests and clears the pop-up signature
		help view.
	**/
	public function clearSignatureHelp():Void {
		if (_signatureHelpManager == null) {
			// will be null when read-only
			return;
		}
		_signatureHelpManager.clear();
	}

	/**
		Cancels active hover requests and clears the pop-up hover view.
	**/
	public function clearHover():Void {
		_hoverManager.clear();
	}

	/**
		Cancels active code actions requests and clears the pop-up code actions
		view.
	**/
	public function clearCodeActions():Void {
		if (_codeActionsManager == null) {
			// will be null when read-only
			return;
		}
		_codeActionsManager.clear();
	}

	/**
		Requests completion for the current caret position.
	**/
	public function completion():Void {
		if (_readOnly) {
			throw new IllegalOperationError("Completion is not allowed in a read-only text editor");
		}
		_completionManager.dispatchCompletionEvent({
			textDocument: _textDocument,
			position: new Position(caretLineIndex, caretCharIndex),
		});
	}

	/**
		Requests signature help for the current caret position.
	**/
	public function signatureHelp():Void {
		_signatureHelpManager.dispatchSignatureHelpEvent({
			textDocument: _textDocument,
			position: new Position(caretLineIndex, caretCharIndex),
		});
	}

	/**
		Requests hover details for the current caret position.
	**/
	public function hover():Void {
		_hoverManager.dispatchHoverEvent({
			textDocument: _textDocument,
			position: new Position(caretLineIndex, caretCharIndex),
		});
	}

	/**
		Requests the definition for the current caret position.
	**/
	public function definition():Void {
		_definitionManager.dispatchDefinitionEvent({
			textDocument: _textDocument,
			position: new Position(caretLineIndex, caretCharIndex),
		});
	}

	/**
		Requests the running of a registered command.
	**/
	public function runCommand(command:Command):Void {
		if (_readOnly) {
			throw new IllegalOperationError("Commands are not allowed in a read-only text editor");
		}
		if (_commandManager.hasCommand(command.command)) {
			_commandManager.runCommand(command);
			return;
		}
		dispatchEvent(new LspTextEditorLanguageActionEvent(LspTextEditorLanguageActionEvent.RUN_COMMAND, command));
	}

	/**
		Requests code actions (such as quick fixes) for the current caret
		position.
	**/
	public function codeActions():Void {
		if (_readOnly) {
			throw new IllegalOperationError("Code actions are not allowed in a read-only text editor");
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

	/**
		Applies a set of text edits to the currently displayed text.
	**/
	public function applyTextEdits(textEdits:Array<TextEdit>):Void {
		var changes = textEdits.map(textEdit -> LspTextEditorUtil.lspTextEditToTextEditorChange(textEdit));
		dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, changes, TextEditorChangeEvent.ORIGIN_LOCAL));
	}

	override private function createTextLineRenderer():TextLineRenderer {
		var renderer:LspTextLineRenderer = null;
		if (_textLineRendererFactory != null) {
			renderer = cast(_textLineRendererFactory.create(), LspTextLineRenderer);
		} else {
			renderer = new LspTextLineRenderer();
		}
		renderer.addEventListener(MouseEvent.CLICK, lspTextEditor_textLineRenderer_clickHandler);
		return renderer;
	}

	override private function destroyTextLineRenderer(renderer:TextLineRenderer):Void {
		super.destroyTextLineRenderer(renderer);
		renderer.removeEventListener(MouseEvent.CLICK, lspTextEditor_textLineRenderer_clickHandler);
	}

	override private function updateTextLineRendererFromModel(itemRenderer:TextLineRenderer, lineModel:TextLineModel):Void {
		super.updateTextLineRendererFromModel(itemRenderer, lineModel);

		var lspItemRenderer = cast(itemRenderer, LspTextLineRenderer);
		lspItemRenderer.diagnostics = _diagnostics;

		if (_linksPosition != null && _linksPosition.line == lineModel.lineIndex) {
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
		if (position == null && _linksPosition == null) {
			// nothing has changed
			return;
		}

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

		invalidateVisibleLines();
	}

	private function activateCodeAction(codeAction:CodeAction):Void {
		if (codeAction.edit != null) {
			dispatchEvent(new LspTextEditorLanguageActionEvent(LspTextEditorLanguageActionEvent.APPLY_WORKSPACE_EDIT, codeAction.edit));
		}
		if (codeAction.command != null) {
			runCommand(codeAction.command);
		}
	}

	private function lspTextEditor_textLineRenderer_clickHandler(event:MouseEvent):Void {
		var textLineRenderer = cast(event.currentTarget, LspTextLineRenderer);
		if (textLineRenderer.linkStartChar == -1 || textLineRenderer.linkEndChar == -1) {
			return;
		}
		var position = localToTextEditorPosition(new Point(mouseX, mouseY));
		if (position == null) {
			return;
		}
		if (position.line != _linksPosition.line) {
			return;
		}
		if (position.character < textLineRenderer.linkStartChar || position.character >= textLineRenderer.linkEndChar) {
			return;
		}
		dispatchEvent(new LspTextEditorLanguageActionEvent(LspTextEditorLanguageActionEvent.OPEN_LINK, _links));
	}
}
