package tests;

import openfl.errors.ArgumentError;
import utest.Assert;
import moonshine.editor.text.changes.TextEditorChange;
import moonshine.editor.text.events.TextEditorChangeEvent;
import moonshine.editor.text.TextEditor;
import openfl.Lib;
import utest.Test;

class TextEditorChangeEventTestCase extends Test {
	private var _textEditor:TextEditor;

	public function setup():Void {
		_textEditor = new TextEditor();
		Lib.current.addChild(_textEditor);
		_textEditor.validateNow();
	}

	public function teardown():Void {
		Lib.current.removeChild(_textEditor);
		_textEditor = null;
	}

	public function testSingleInsertEdit():Void {
		_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, [new TextEditorChange(0, 0, 0, 0, "hello")]));
		Assert.equals("hello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testMultipleInsertEditsAtSamePosition():Void {
		_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, [
			new TextEditorChange(0, 0, 0, 0, "hello"),
			new TextEditorChange(0, 0, 0, 0, " world")
		]));
		Assert.equals("hello world", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(11, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testMultipleInsertEditsFollowedByRemoveEditAtSamePosition():Void {
		_textEditor.text = "hi";
		_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, [
			new TextEditorChange(0, 0, 0, 0, "hello"),
			new TextEditorChange(0, 0, 0, 0, " world"),
			new TextEditorChange(0, 0, 0, 2)
		]));
		Assert.equals("hello world", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(11, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testMultipleInsertEditsFollowedByReplaceEditAtSamePosition():Void {
		_textEditor.text = "hi";
		_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, [
			new TextEditorChange(0, 0, 0, 0, "hello"),
			new TextEditorChange(0, 0, 0, 0, " world"),
			new TextEditorChange(0, 0, 0, 2, ", I said")
		]));
		Assert.equals("hello world, I said", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(19, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	#if !flash
	// for some reason, the Assert.raise() try/catch doesn't work on the
	// flash/air targets, even though the error is thrown
	public function testThrowsWithMultipleInsertEditsFollowedByMultipleRemoveEditsAtSamePosition():Void {
		_textEditor.text = "hi";
		Assert.raises(() -> {
			_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, [
				new TextEditorChange(0, 0, 0, 0, "hello"),
				new TextEditorChange(0, 0, 0, 0, " world"),
				new TextEditorChange(0, 0, 0, 1),
				new TextEditorChange(0, 0, 0, 1)
			]));
		}, ArgumentError);
	}
	#end

	public function testWithAdjacentReplaceEdits():Void {
		_textEditor.text = "hi";
		_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, [
			new TextEditorChange(0, 0, 0, 1, "hello"),
			new TextEditorChange(0, 1, 0, 2, " world")
		]));
		Assert.equals("hello world", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		// skip for now
		// Assert.equals(11, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testImportStyleEdits():Void {
		_textEditor.text = "import openfl.display.Sprite;\n\nvar event:";
		_textEditor.setSelection(2, 10, 2, 10);
		_textEditor.dispatchEvent(new TextEditorChangeEvent(TextEditorChangeEvent.TEXT_CHANGE, [
			new TextEditorChange(2, 10, 2, 10, "Event"),
			new TextEditorChange(1, 0, 1, 0, "import openfl.events.Event;\n")
		]));
		Assert.equals("import openfl.display.Sprite;\nimport openfl.events.Event;\n\nvar event:Event", _textEditor.text);
		Assert.equals(3, _textEditor.caretLineIndex);
		Assert.equals(15, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}
}
