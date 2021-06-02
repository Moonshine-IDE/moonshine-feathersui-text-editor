package tests;

import moonshine.editor.text.lsp.LspTextEditor;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageRequestEvent;
import moonshine.lsp.Position;
import moonshine.lsp.TextDocumentIdentifier;
import openfl.Lib;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import utest.Assert;
import utest.Test;

class LspTextEditorCompletionTestCase extends Test {
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
		var dispatchedCompletion = false;
		_textEditor.addEventListener(LspTextEditorLanguageRequestEvent.REQUEST_COMPLETION, event -> {
			dispatchedCompletion = true;
		});
		_textEditor.stage.focus = _textEditor;
		Assert.isFalse(dispatchedCompletion);
		_textEditor.completion();
		Assert.isTrue(dispatchedCompletion);
	}

	public function testKeyboardShortcutDispatchesEvent():Void {
		var dispatchedCompletion = false;
		_textEditor.addEventListener(LspTextEditorLanguageRequestEvent.REQUEST_COMPLETION, event -> {
			dispatchedCompletion = true;
		});
		_textEditor.stage.focus = _textEditor;
		Assert.isFalse(dispatchedCompletion);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, " ".charCodeAt(0), Keyboard.SPACE, null, true));
		Assert.isTrue(dispatchedCompletion);
	}
}
