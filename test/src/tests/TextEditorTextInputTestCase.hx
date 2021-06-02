package tests;

import moonshine.editor.text.TextEditor;
import openfl.Lib;
import openfl.desktop.Clipboard;
import openfl.desktop.ClipboardFormats;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.TextEvent;
import openfl.ui.Keyboard;
import utest.Assert;
import utest.Test;

class TextEditorTextInputTestCase extends Test {
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

	public function testEmpty():Void {
		Assert.equals("", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testTextInputEvent():Void {
		_textEditor.stage.focus = _textEditor;
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, "hello"));
		Assert.equals("hello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testMultipleTextInputEvents():Void {
		_textEditor.stage.focus = _textEditor;
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, "hello"));
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, " world"));
		Assert.equals("hello world", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(11, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testTextInputEventWithSelectedRange():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 1, 1, 4);
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, "ear"));
		Assert.equals("heard", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(4, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	#if !html5
	public function testPasteEvent():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 5, 1, 5);
		Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, " world");
		_textEditor.dispatchEvent(new Event(Event.PASTE));
		Assert.equals("hello world", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(11, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testPasteEventWithSelectedRange():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 3, 0, 5);
		Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, "ping");
		_textEditor.dispatchEvent(new Event(Event.PASTE));
		Assert.equals("helping", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(7, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testPasteEventWithMultipleInsertedLines():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 1, 1, 4);
		Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, "elp\nte");
		_textEditor.dispatchEvent(new Event(Event.PASTE));
		Assert.equals("help\nted", _textEditor.text);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}
	#end

	public function testBackspaceWithCaret():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 1, 0, 1);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.BACKSPACE));
		Assert.equals("ello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testBackspaceWithSelectedRange():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 2, 1, 3);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.BACKSPACE));
		Assert.equals("held", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testDeleteWithCaret():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.DELETE));
		Assert.equals("ello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testDeleteWithSelectedRange():Void {
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 2, 1, 3);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.DELETE));
		Assert.equals("held", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testTextInputThenBackspace():Void {
		_textEditor.stage.focus = _textEditor;
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, "greetings"));
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.BACKSPACE));
		Assert.equals("greeting", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(8, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testTabWithCaretSelection():Void {
		_textEditor.text = "\thello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 3, 0, 3);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.TAB));
		Assert.equals("\the\tllo", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(4, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testTabWithRangeSelection():Void {
		_textEditor.text = "\thello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 2, 0, 3);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.TAB));
		Assert.equals("\th\tllo", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}
	/*public function testShiftTabWithCaretSelection():Void {
		_textEditor.text = "\thello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 3, 0, 3);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.TAB, null, false, false, true));
		Assert.equals("hello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}*/
}