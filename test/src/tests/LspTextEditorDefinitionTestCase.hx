package tests;

import moonshine.editor.text.lsp.LspTextEditor;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageRequestEvent;
import openfl.Lib;
import utest.Assert;
import utest.Test;

class LspTextEditorDefinitionTestCase extends Test {
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
		var dispatchedDefinition = false;
		_textEditor.addEventListener(LspTextEditorLanguageRequestEvent.REQUEST_DEFINITION, event -> {
			dispatchedDefinition = true;
		});
		_textEditor.stage.focus = _textEditor;
		Assert.isFalse(dispatchedDefinition);
		_textEditor.definition();
		Assert.isTrue(dispatchedDefinition);
	}
}
