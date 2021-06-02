package tests;

import moonshine.editor.text.TextEditor;
import openfl.Lib;
import openfl.events.KeyboardEvent;
import openfl.events.TextEvent;
import openfl.ui.Keyboard;
import utest.Assert;
import utest.Test;

class TextEditorUndoRedoTestCase extends Test {
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

	public function testUndoTextInput():Void {
		_textEditor.stage.focus = _textEditor;
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, "hello"));
		Assert.equals("hello", _textEditor.text);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, "z".charCodeAt(0), Keyboard.Z, null, true));
		Assert.equals("", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testRedoTextInput():Void {
		_textEditor.stage.focus = _textEditor;
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, "hello"));
		Assert.equals("hello", _textEditor.text);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, "z".charCodeAt(0), Keyboard.Z, null, true));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, "z".charCodeAt(0), Keyboard.Z, null, true, false, true));
		Assert.equals("hello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testUndoMultipleTextInput():Void {
		_textEditor.stage.focus = _textEditor;
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, "hello"));
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, " world"));
		Assert.equals("hello world", _textEditor.text);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, "z".charCodeAt(0), Keyboard.Z, null, true));
		Assert.equals("", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testRedoMultipleTextInput():Void {
		_textEditor.stage.focus = _textEditor;
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, "hello"));
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, " world"));
		Assert.equals("hello world", _textEditor.text);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, "z".charCodeAt(0), Keyboard.Z, null, true));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, "z".charCodeAt(0), Keyboard.Z, null, true, false, true));
		Assert.equals("hello world", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(11, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testUndoTextInputBackspaceTextInput():Void {
		_textEditor.stage.focus = _textEditor;
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, "hi"));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.BACKSPACE));
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, "ello"));
		Assert.equals("hello", _textEditor.text);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, "z".charCodeAt(0), Keyboard.Z, null, true));
		Assert.equals("h", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(1, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testUndoBackspace():Void {
		_textEditor.stage.focus = _textEditor;
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, "hi"));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.BACKSPACE));
		Assert.equals("h", _textEditor.text);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, "z".charCodeAt(0), Keyboard.Z, null, true));
		Assert.equals("hi", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testRedoBackspace():Void {
		_textEditor.stage.focus = _textEditor;
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, "hi"));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.BACKSPACE));
		Assert.equals("h", _textEditor.text);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, "z".charCodeAt(0), Keyboard.Z, null, true));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, "z".charCodeAt(0), Keyboard.Z, null, true, false, true));
		Assert.equals("h", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(1, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testUndoBackspaceMultiline():Void {
		_textEditor.stage.focus = _textEditor;
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, "hello\nworld"));
		_textEditor.setSelection(0, 2, 1, 3);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.BACKSPACE));
		Assert.equals("held", _textEditor.text);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, "z".charCodeAt(0), Keyboard.Z, null, true));
		Assert.equals("hello\nworld", _textEditor.text);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
	}

	public function testRedoBackspaceMultiline():Void {
		_textEditor.stage.focus = _textEditor;
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, "hello\nworld"));
		_textEditor.setSelection(0, 2, 1, 3);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.BACKSPACE));
		Assert.equals("held", _textEditor.text);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, "z".charCodeAt(0), Keyboard.Z, null, true));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, "z".charCodeAt(0), Keyboard.Z, null, true, false, true));
		Assert.equals("held", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
	}
}
