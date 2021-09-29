package tests;

import moonshine.editor.text.lsp.LspTextEditor;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageRequestEvent;
import openfl.Lib;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import utest.Assert;
import utest.Test;

class LspTextEditorSignatureHelpTestCase extends Test {
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
		var dispatchedSignatureHelp = false;
		_textEditor.addEventListener(LspTextEditorLanguageRequestEvent.REQUEST_SIGNATURE_HELP, event -> {
			dispatchedSignatureHelp = true;
		});
		_textEditor.stage.focus = _textEditor;
		Assert.isFalse(dispatchedSignatureHelp);
		_textEditor.signatureHelp();
		Assert.isTrue(dispatchedSignatureHelp);
	}

	public function testKeyboardShortcutDispatchesEvent():Void {
		var dispatchedRequestSignatureHelp = false;
		_textEditor.addEventListener(LspTextEditorLanguageRequestEvent.REQUEST_SIGNATURE_HELP, event -> {
			dispatchedRequestSignatureHelp = true;
		});
		_textEditor.stage.focus = _textEditor;
		Assert.isFalse(dispatchedRequestSignatureHelp);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, " ".charCodeAt(0), Keyboard.SPACE, null, true, false,
			true));
		Assert.isTrue(dispatchedRequestSignatureHelp);
	}

	public function testClearSignatureHelpWhenReadOnly():Void {
		var textEditor = new LspTextEditor(null, "", true);
		// make sure that there are no exceptions
		textEditor.clearSignatureHelp();
		Assert.pass();
	}
}
