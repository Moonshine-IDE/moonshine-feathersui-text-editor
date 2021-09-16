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

	#if (!html5 && (!flash || air))
	public function testCopyEvent():Void {
		final INVALID = "INVALID CLIPBOARD DATA";
		final VALID = "ell";
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 1, 0, 4);
		Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, INVALID);
		Assert.equals(INVALID, Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT));
		_textEditor.dispatchEvent(new Event(Event.COPY));
		Assert.equals(VALID, Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT));
		Assert.equals("hello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(4, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(1, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(4, _textEditor.selectionEndCharIndex);
	}

	public function testCopyEventMultiline():Void {
		final INVALID = "INVALID CLIPBOARD DATA";
		final VALID = "llo\nwor";
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 2, 1, 3);
		Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, INVALID);
		Assert.equals(INVALID, Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT));
		_textEditor.dispatchEvent(new Event(Event.COPY));
		Assert.equals(VALID, Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT));
		Assert.equals("hello\nworld", _textEditor.text);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(2, _textEditor.selectionStartCharIndex);
		Assert.equals(1, _textEditor.selectionEndLineIndex);
		Assert.equals(3, _textEditor.selectionEndCharIndex);
	}

	public function testCopyEventNoSelection():Void {
		final INVALID = "INVALID CLIPBOARD DATA";
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 1, 0, 1);
		Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, INVALID);
		Assert.equals(INVALID, Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT));
		_textEditor.dispatchEvent(new Event(Event.COPY));
		Assert.equals(INVALID, Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT));
		Assert.equals("hello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(1, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testCutEvent():Void {
		final INVALID = "INVALID CLIPBOARD DATA";
		final VALID = "ell";
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 1, 0, 4);
		Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, INVALID);
		Assert.equals(INVALID, Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT));
		_textEditor.dispatchEvent(new Event(Event.CUT));
		Assert.equals(VALID, Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT));
		Assert.equals("ho", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(1, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testCutEventMultiline():Void {
		final INVALID = "INVALID CLIPBOARD DATA";
		final VALID = "llo\nwor";
		_textEditor.text = "hello\nworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 2, 1, 3);
		Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, INVALID);
		Assert.equals(INVALID, Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT));
		_textEditor.dispatchEvent(new Event(Event.CUT));
		Assert.equals(VALID, Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT));
		Assert.equals("held", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testCutEventNoSelection():Void {
		final INVALID = "INVALID CLIPBOARD DATA";
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 1, 0, 1);
		Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, INVALID);
		Assert.equals(INVALID, Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT));
		_textEditor.dispatchEvent(new Event(Event.CUT));
		Assert.equals(INVALID, Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT));
		Assert.equals("hello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(1, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

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

	public function testEnter():Void {
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 5, 0, 5);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.ENTER));
		Assert.equals("hello\n", _textEditor.text);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(0, _textEditor.caretCharIndex);
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

	public function testTabWithRangeSelectionOneLine():Void {
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

	public function testTabWithRangeSelectionMultipleLines():Void {
		_textEditor.text = "\thello\n\tworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 2, 1, 2);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.TAB));
		Assert.equals("\t\thello\n\t\tworld", _textEditor.text);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(3, _textEditor.selectionStartCharIndex);
		Assert.equals(1, _textEditor.selectionEndLineIndex);
		Assert.equals(3, _textEditor.selectionEndCharIndex);
	}

	public function testShiftTabWithCaretSelection():Void {
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
	}

	public function testShiftTabWithRangeSelectionOneLine():Void {
		_textEditor.text = "\thello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 2, 0, 4);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.TAB, null, false, false, true));
		Assert.equals("hello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(3, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(1, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(3, _textEditor.selectionEndCharIndex);
	}

	public function testShiftTabWithRangeSelectionMultipleLines():Void {
		_textEditor.text = "\t\thello\n\t\tworld";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 3, 1, 3);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.TAB, null, false, false, true));
		Assert.equals("\thello\n\tworld", _textEditor.text);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(2, _textEditor.selectionStartCharIndex);
		Assert.equals(1, _textEditor.selectionEndLineIndex);
		Assert.equals(2, _textEditor.selectionEndCharIndex);
	}

	public function testNewLineAfterBracketOpenIncreasesIndent():Void {
		_textEditor.brackets = [["{", "}"]];
		_textEditor.text = "hello {";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 7, 0, 7);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.ENTER));
		Assert.equals("hello {\n\t", _textEditor.text);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(1, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testBracketCloseAfterNewLineDecreasesIndent():Void {
		_textEditor.brackets = [["{", "}"]];
		_textEditor.text = "hello {\n\t";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(1, 1, 1, 1);
		_textEditor.dispatchEvent(new TextEvent(TextEvent.TEXT_INPUT, false, false, "}"));
		Assert.equals("hello {\n}", _textEditor.text);
		Assert.equals(1, _textEditor.caretLineIndex);
		Assert.equals(1, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testToggleLineCommentOn():Void {
		_textEditor.lineComment = "//";
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 2, 0, 2);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.SLASH, "/".charCodeAt(0), true));
		Assert.equals("// hello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(5, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testToggleLineCommentOff():Void {
		_textEditor.lineComment = "//";
		_textEditor.text = "// hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 5, 0, 5);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.SLASH, "/".charCodeAt(0), true));
		Assert.equals("hello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testToggleLineCommentOffWithoutSpace():Void {
		_textEditor.lineComment = "//";
		_textEditor.text = "//hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 4, 0, 4);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.SLASH, "/".charCodeAt(0), true));
		Assert.equals("hello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}

	public function testToggleBlockCommentOn():Void {
		_textEditor.blockComment = ["/*", "*/"];
		_textEditor.text = "hello";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 1, 0, 4);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.SLASH, "/".charCodeAt(0), true, true));
		Assert.equals("h/* ell */o", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(7, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(4, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(7, _textEditor.selectionEndCharIndex);
	}

	public function testToggleBlockCommentOff():Void {
		_textEditor.blockComment = ["/*", "*/"];
		_textEditor.text = "h/* ell */o";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 4, 0, 7);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.SLASH, "/".charCodeAt(0), true, true));
		Assert.equals("hello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(4, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(1, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(4, _textEditor.selectionEndCharIndex);
	}

	public function testToggleBlockCommentOffWithoutSpaces():Void {
		_textEditor.blockComment = ["/*", "*/"];
		_textEditor.text = "h/*ell*/o";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 3, 0, 6);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.SLASH, "/".charCodeAt(0), true, true));
		Assert.equals("hello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(4, _textEditor.caretCharIndex);
		Assert.equals(0, _textEditor.selectionStartLineIndex);
		Assert.equals(1, _textEditor.selectionStartCharIndex);
		Assert.equals(0, _textEditor.selectionEndLineIndex);
		Assert.equals(4, _textEditor.selectionEndCharIndex);
	}

	public function testToggleBlockCommentOffWithCaretOnly():Void {
		_textEditor.blockComment = ["/*", "*/"];
		_textEditor.text = "h/* ell */o";
		_textEditor.stage.focus = _textEditor;
		_textEditor.setSelection(0, 5, 0, 5);
		_textEditor.stage.focus.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, 0, Keyboard.SLASH, "/".charCodeAt(0), true, true));
		Assert.equals("hello", _textEditor.text);
		Assert.equals(0, _textEditor.caretLineIndex);
		Assert.equals(2, _textEditor.caretCharIndex);
		Assert.equals(-1, _textEditor.selectionStartLineIndex);
		Assert.equals(-1, _textEditor.selectionStartCharIndex);
		Assert.equals(-1, _textEditor.selectionEndLineIndex);
		Assert.equals(-1, _textEditor.selectionEndCharIndex);
	}
}
