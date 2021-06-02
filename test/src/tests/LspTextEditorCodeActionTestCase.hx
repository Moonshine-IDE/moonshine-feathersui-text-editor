package tests;

import moonshine.lsp.Range;
import moonshine.editor.text.lsp.LspTextEditor;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageRequestEvent;
import moonshine.lsp.Position;
import moonshine.lsp.TextDocumentIdentifier;
import openfl.Lib;
import utest.Assert;
import utest.Test;

class LspTextEditorCodeActionTestCase extends Test {
	private var _textEditor:LspTextEditor;

	public function setup():Void {
		_textEditor = new LspTextEditor();
		Lib.current.addChild(_textEditor);
		_textEditor.validateNow();
	}

	public function teardown():Void {
		Lib.current.removeChild(_textEditor);
		_textEditor = null;
	}

	public function testCallDispatchesEvent():Void {
		var dispatchedCodeAction = false;
		_textEditor.addEventListener(LspTextEditorLanguageRequestEvent.REQUEST_CODE_ACTIONS, event -> {
			dispatchedCodeAction = true;
		});
		_textEditor.stage.focus = _textEditor;
		Assert.isFalse(dispatchedCodeAction);
		_textEditor.codeActions();
		Assert.isTrue(dispatchedCodeAction);
	}
}