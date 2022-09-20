package tests;

import moonshine.editor.text.lines.TextLineRenderer;
import moonshine.editor.text.lsp.LspTextEditor;
import moonshine.editor.text.lsp.lines.LspTextLineRenderer;
import openfl.Lib;
import utest.Assert;
import utest.Test;

class LspTextEditorDiagnosticsTestCase extends Test {
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

	// catches a potential performance regression where changing diagnostics
	// causes renderers to get recreated instead of reused
	public function testItemRendererFactoryNotCalledOnSetDiagnostics():Void {
		var callCount = 0;
		_textEditor.textLineRendererFactory = function():TextLineRenderer {
			callCount++;
			return new LspTextLineRenderer();
		};
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 5, 0, 5);
		_textEditor.validateNow();
		callCount = 0;
		_textEditor.diagnostics = [];
		_textEditor.validateNow();
		Assert.equals(0, callCount);
	}
}
