package tests;

import moonshine.editor.text.TextEditor;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import utest.Assert;
import utest.Test;

class TextEditorSelectionTestCase extends Test {
	private var _textEditor:TextEditor;

	public function setup():Void {
		_textEditor = new TextEditor();
		TestMain.test_root.addChild(_textEditor);
		_textEditor.validateNow();
	}

	public function teardown():Void {
		TestMain.test_root.removeChild(_textEditor);
		_textEditor = null;
	}

	public function testEmpty():Void {
		Assert.equals("", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelection():Void {
		_textEditor.text = "hello";
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		_textEditor.setSelection(0, 2, 0, 2);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionForwardOnOneLine():Void {
		_textEditor.text = "hello";
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		_textEditor.setSelection(0, 1, 0, 4);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(4, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(1, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(4, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionBackwardOnOneLine():Void {
		_textEditor.text = "hello";
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		_textEditor.setSelection(0, 4, 0, 1);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(1, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(4, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(1, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionForwardOnMultipleLines():Void {
		_textEditor.text = "hello\nworld";
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		_textEditor.setSelection(0, 1, 1, 4);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(4, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(1, _textEditor.selectionStartCharIndex);
		Assert.equals(1, _textEditor.selectionEndLineIndex);
		Assert.equals(4, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionBackwardOnMultipleLines():Void {
		_textEditor.text = "hello\nworld";
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		_textEditor.setSelection(1, 4, 0, 1);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(1, _textEditor.caretCharIndex);
		Assert.equals(1, _textEditor.selectionStartLineIndex);
		Assert.equals(4, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(1, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionOutOfRangeClamps():Void {
		_textEditor.text = "hello";
		_textEditor.setSelection(0, 6, 0, 6);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testClearTextSelectionResetToBeginningOfDocument():Void {
		_textEditor.text = "hello";
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.setSelection(0, 2, 0, 2);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.text = "";
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardRight():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.RIGHT));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(1, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardRightAtEndOfLine():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 5, 0, 5);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.RIGHT));
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardRightAtEndOfFile():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(1, 5, 1, 5);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.RIGHT));
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionWithKeyboardRight():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.RIGHT, null, false, false, true));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(1, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(0, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(1, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionWithMultipleKeyboardRight():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.RIGHT, null, false, false, true));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.RIGHT, null, false, false, true));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(0, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(2, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionWithMultipleKeyboardRightThenKeyboardLeft():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.RIGHT, null, false, false, true));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.RIGHT, null, false, false, true));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.LEFT, null, false, false, true));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(1, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(0, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(1, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionWithKeyboardRightAtEndOfLine():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 5, 0, 5);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.RIGHT, null, false, false, true));
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(5, _textEditor.selectionStartCharIndex);
		Assert.equals(1, _textEditor.selectionEndLineIndex);
		Assert.equals(0, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardLeft():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 5, 0, 5);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.LEFT));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(4, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardLeftAtStartOfLine():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(1, 0, 1, 0);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.LEFT));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardLeftAtStartOfFile():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 0, 0, 0);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.LEFT));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionWithKeyboardLeft():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 5, 0, 5);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.LEFT, null, false, false, true));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(4, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(5, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(4, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionWithMultipleKeyboardLeft():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 5, 0, 5);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.LEFT, null, false, false, true));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.LEFT, null, false, false, true));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(5, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(3, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionWithMultipleKeyboardLeftThenKeyboardRight():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 5, 0, 5);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.LEFT, null, false, false, true));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.LEFT, null, false, false, true));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.RIGHT, null, false, false, true));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(4, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(5, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(4, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionWithKeyboardLeftAtStartOfLine():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(1, 0, 1, 0);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.LEFT, null, false, false, true));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(1, _textEditor.selectionStartLineIndex);
		Assert.equals(0, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(5, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionLeftFromRangeSelection():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 1, 0, 4);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(4, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(1, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(4, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.LEFT));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(1, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionRightFromRangeSelection():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 1, 0, 4);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(4, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(1, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(4, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.RIGHT));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(4, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardHomeNoTabs():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 5, 0, 5);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.HOME));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionWithKeyboardHomeNoTabs():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 3, 0, 3);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.HOME, null, false, false, true));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(3, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(0, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardEnd():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.END));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionWithKeyboardEnd():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 2, 0, 2);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.END, null, false, false, true));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(2, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(5, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardUpAtFirstLine():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 2, 0, 2);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.UP));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionWithKeyboardUpAtFirstLine():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 2, 0, 2);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.UP, null, false, false, true));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(2, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(0, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardDownAtLastLine():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(1, 2, 1, 2);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.DOWN));
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionWithKeyboardDownAtLastLine():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(1, 2, 1, 2);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.DOWN, null, false, false, true));
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(1, _textEditor.selectionStartLineIndex);
		Assert.equals(2, _textEditor.selectionStartCharIndex);
		Assert.equals(1, _textEditor.selectionEndLineIndex);
		Assert.equals(5, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardLeftAtBeginningOfDocument():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.LEFT));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardRightAtEndOfDocument():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 5, 0, 5);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.RIGHT));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardUp():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(1, 3, 1, 3);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.UP));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionWithKeyboardUp():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(1, 3, 1, 3);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.UP, null, false, false, true));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(1, _textEditor.selectionStartLineIndex);
		Assert.equals(3, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(3, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardUpToShorterLine():Void {
		_textEditor.text = "hi\nhello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(1, 3, 1, 3);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.UP));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardUpToShorterLineAndThenAgainToLongerLine():Void {
		_textEditor.text = "hello\nhi\nhowdy";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(2, 3, 2, 3);
		Assert.equals(2, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.UP));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.UP));
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardDown():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 3, 0, 3);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.DOWN));
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetRangeSelectionWithKeyboardDown():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 3, 0, 3);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.DOWN, null, false, false, true));
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(3, _textEditor.selectionStartCharIndex);
		Assert.equals(1, _textEditor.selectionEndLineIndex);
		Assert.equals(3, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardDownToShorterLine():Void {
		_textEditor.text = "hello\nhi";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 3, 0, 3);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.DOWN));
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSetCaretSelectionWithKeyboardDownToShorterLineThenAgainToLongerLine():Void {
		_textEditor.text = "hello\nhi\nhowdy";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 3, 0, 3);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.DOWN));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.DOWN));
		Assert.equals(2, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testSelectAll():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 3, 0, 3);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.dispatchEvent(new Event(Event.SELECT_ALL, false, false));
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(0, _textEditor.selectionStartCharIndex);
		Assert.equals(1, _textEditor.selectionEndLineIndex);
		Assert.equals(5, _textEditor.selectionEndCharIndex);
	}

	public function testSelectAllKeyboard():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 3, 0, 3);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, "a".charCodeAt(0), Keyboard.A, null, true));
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(0, _textEditor.selectionStartCharIndex);
		Assert.equals(1, _textEditor.selectionEndLineIndex);
		Assert.equals(5, _textEditor.selectionEndCharIndex);
	}
}
