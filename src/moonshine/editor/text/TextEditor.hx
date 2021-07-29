/*
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License

	No warranty of merchantability or fitness of any kind.
	Use this software at your own risk.
 */

package moonshine.editor.text;

import feathers.controls.ListView;
import feathers.core.FeathersControl;
import feathers.core.IFocusObject;
import feathers.core.IStageFocusDelegate;
import feathers.data.ArrayCollection;
import feathers.data.ListViewItemState;
import feathers.events.ScrollEvent;
import feathers.layout.VerticalListFixedRowLayout;
import feathers.utils.DisplayObjectRecycler;
import moonshine.editor.text.events.TextEditorChangeEvent;
import moonshine.editor.text.events.TextEditorEvent;
import moonshine.editor.text.events.TextEditorLineEvent;
import moonshine.editor.text.lines.TextLineModel;
import moonshine.editor.text.lines.TextLineRenderer;
import moonshine.editor.text.managers.ColorManager;
import moonshine.editor.text.managers.EditManager;
import moonshine.editor.text.managers.FindReplaceManager;
import moonshine.editor.text.managers.SelectionManager;
import moonshine.editor.text.managers.UndoManager;
import moonshine.editor.text.syntax.format.PlainTextFormatBuilder;
import moonshine.editor.text.syntax.parser.ILineParser;
import moonshine.editor.text.syntax.parser.PlainTextLineParser;
import moonshine.editor.text.theme.TextEditorStyles;
import moonshine.editor.text.utils.TextEditorUtil;
import moonshine.editor.text.utils.TextUtil;
import openfl.Lib;
import openfl.display.InteractiveObject;
import openfl.errors.IllegalOperationError;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextFormat;

/**
	A multiline text editor for code.
**/
@:event(feathers.events.ScrollEvent.SCROLL)
class TextEditor extends FeathersControl implements IFocusObject implements IStageFocusDelegate {
	public static final CHILD_VARIANT_LIST_VIEW = "textEditor_listView";

	public function new(?text:String, readOnly:Bool = false) {
		TextEditorStyles.initialize();
		super();
		_readOnly = readOnly;
		if (!_readOnly) {
			_editMananger = new EditManager(this);
			_undoManager = new UndoManager(this);
		}
		_selectionMananger = new SelectionManager(this);
		_colorManager = new ColorManager(this);
		_findReplaceManager = new FindReplaceManager(this);
		this.text = text;
		addEventListener(TextEditorChangeEvent.TEXT_CHANGE, textEditor_textChangeHandler, false, 1);
		addEventListener(TextEditorLineEvent.COLOR_CHANGE, textEditor_colorChangeHandler);
		addEventListener(FocusEvent.FOCUS_IN, textEditor_focusInHandler);
	}

	private var _readOnly:Bool;

	/**
		Indicates if the editor allows editing or not.
	**/
	@:flash.property
	public var readOnly(get, never):Bool;

	private function get_readOnly():Bool {
		return _readOnly;
	}

	private var _editMananger:EditManager;
	private var _undoManager:UndoManager;
	private var _selectionMananger:SelectionManager;
	private var _colorManager:ColorManager;
	private var _findReplaceManager:FindReplaceManager;

	private var _listView:ListView;

	@:flash.property
	public var stageFocusTarget(get, never):InteractiveObject;

	private function get_stageFocusTarget():InteractiveObject {
		return _listView;
	}

	/**
		The default `lineDelimeter` to use when none can be detected.
	**/
	public var defaultLineDelimiter:String = "\n";

	public var _lineDelimiter:String = null;

	/**
		The string used to indicate line breaks. May be `\n`, `\r`, or `\r\n`.
	**/
	@:flash.property
	public var lineDelimiter(get, set):String;

	private function get_lineDelimiter():String {
		if (_lineDelimiter == null) {
			return defaultLineDelimiter;
		}
		return _lineDelimiter;
	}

	private function set_lineDelimiter(value:String):String {
		if (_lineDelimiter == value) {
			return _lineDelimiter;
		}
		_lineDelimiter = value;
		return _lineDelimiter;
	}

	private var _lines:ArrayCollection<TextLineModel>;

	/**
		The `text` divided into lines, with extra metadata.
	**/
	@:flash.property
	public var lines(get, never):ArrayCollection<TextLineModel>;

	private function get_lines():ArrayCollection<TextLineModel> {
		return _lines;
	}

	/**
		The text to be displayed by the editor.
	**/
	@:flash.property
	public var text(get, set):String;

	private function get_text():String {
		return _lines.array.map(line -> line.text).join(lineDelimiter);
	}

	private function set_text(value:String):String {
		if (value == null) {
			value = "";
		}

		// Detect line ending (for saves)
		// TODO: take first found line encoding
		if (value.indexOf("\r\n") != -1) {
			_lineDelimiter = "\r\n";
		} else if (value.indexOf("\r") != -1) {
			_lineDelimiter = "\r";
		} else if (value.indexOf("\n") != -1) {
			_lineDelimiter = "\n";
		} else {
			_lineDelimiter = defaultLineDelimiter;
		}

		// Split lines regardless of line encoding
		var lines = ~/\r?\n|\r/g.split(value);

		// Populate lines into model
		var lineModels:Array<TextLineModel> = [];
		lineModels.resize(lines.length);

		for (i in 0...lines.length) {
			lineModels[i] = new TextLineModel(lines[i], i);
		}
		if (_lines != null) {
			_lines.removeEventListener(Event.CHANGE, textEditor_lines_changeHandler);
		}
		_lines = new ArrayCollection(lineModels);
		_lines.addEventListener(Event.CHANGE, textEditor_lines_changeHandler);

		_colorManager.reset();

		// Clear undo history (readOnly doesn't have it)
		if (_undoManager != null) {
			_undoManager.clear();
		}

		// Reset selection state
		setSelection(0, 0, 0, 0);
		// Reset scroll
		_lineScrollY = 0;
		if (_listView != null) {
			_listView.scrollX = 0.0;
			_listView.scrollY = 0.0;
		}
		/*
			model.horizontalScrollPosition = 0; */

		setInvalid(DATA);

		return value;
	}

	private var _viewPortVisibleBounds = new Rectangle();

	private var _ignoreScrollChanges = false;

	private var _lineScrollY:Int = 0;

	/**
		The current scroll position, as measured in lines.
	**/
	@:flash.property
	public var lineScrollY(get, set):Int;

	private function get_lineScrollY():Int {
		return _lineScrollY;
	}

	private function set_lineScrollY(value:Int):Int {
		if (lineScrollY == value) {
			return lineScrollY;
		}
		_lineScrollY = value;
		if (_listView != null) {
			_listView.scrollY = _lineScrollY * _lineHeight;
		}
		return _lineScrollY;
	}

	private var _maxLineScrollY:Int = 0;

	/**
		The maximum value currently allowed for `lineScrollY`.
	**/
	@:flash.property
	public var maxLineScrollY(get, never):Int;

	private function get_maxLineScrollY():Int {
		return _maxLineScrollY;
	}

	private var _visibleLines:Int = 0;

	/**
		The number of lines that are currently visible.
	**/
	@:flash.property
	public var visibleLines(get, never):Int;

	private function get_visibleLines():Int {
		return _visibleLines;
	}

	private var _gutterWidth:Float = 0.0;

	/**
		The width of the gutter to the left of the lines.
	**/
	@:flash.property
	public var gutterWidth(get, never):Float;

	private function get_gutterWidth():Float {
		return _gutterWidth;
	}

	@:style
	public var lineNumberWidth:Null<Float> = null;

	@:style
	public var minLineNumberCharacters:Int = 3;

	private var _showLineNumbers:Bool = true;

	@:flash.property
	public var showLineNumbers(get, set):Bool;

	private function get_showLineNumbers():Bool {
		return _showLineNumbers;
	}

	private function set_showLineNumbers(value:Bool):Bool {
		if (_showLineNumbers == value) {
			return _showLineNumbers;
		}
		_showLineNumbers = value;
		setInvalid(DATA);
		return _showLineNumbers;
	}

	private var _hasFocus:Bool = false;

	private var _parser:ILineParser;

	private var _textStyles:Map<Int, TextFormat>;

	/**
		Gets the `TextFormat` for the specified text style id.
	**/
	public function getTextStyle(id:Int):TextFormat {
		return _textStyles.get(id);
	}

	public function getDefaultTextStyle():TextFormat {
		if (_parser == null) {
			return _textStyles.get(0x0);
		}
		return _textStyles.get(_parser.defaultContext);
	}

	@:style
	public var embedFonts:Bool = false;

	private var _lineHeight:Float = 0.0;

	/**
		The height of each line, measured in pixels.
	**/
	@:flash.property
	public var lineHeight(get, never):Float;

	private function get_lineHeight():Float {
		return _lineHeight;
	}

	/**
		Indicates if the file has been edited.
	**/
	@:flash.property
	public var edited(get, never):Bool;

	private function get_edited():Bool {
		if (_undoManager == null) {
			return false;
		}
		return _undoManager.edited;
	}

	/**
		Indicates if there is currently a selected range.
	**/
	@:flash.property
	public var hasSelection(get, never):Bool;

	private function get_hasSelection():Bool {
		return _selectionStartLineIndex != -1;
	}

	@:flash.property
	public var selectedText(get, never):String;

	private function get_selectedText():String {
		if (!hasSelection) {
			return "";
		}

		if (_selectionStartLineIndex != _selectionEndLineIndex) {
			var startLine = _selectionStartLineIndex;
			var endLine = _selectionEndLineIndex;

			var startChar = _selectionStartCharIndex;
			var endChar = _selectionEndCharIndex;

			if (startLine > endLine) {
				startLine = endLine;
				endLine = _selectionStartLineIndex;

				startChar = endChar;
				endChar = _selectionStartCharIndex;
			}

			var selText = _lines.get(startLine).text.substr(startChar);
			for (i in (startLine + 1)...endLine) {
				selText += _lineDelimiter + _lines.get(i).text;
			}
			selText += _lineDelimiter + _lines.get(endLine).text.substr(0, endChar);

			return selText;
		}
		var startChar = _selectionStartCharIndex;
		var endChar = _selectionEndCharIndex;
		if (startChar > endChar) {
			startChar = endChar;
			endChar = _selectionStartCharIndex;
		}
		return _lines.get(_selectionStartLineIndex).text.substring(startChar, endChar);
	}

	private var _selectionStartLineIndex:Int = -1;

	/**
		The line index of the start of the selection.

		To set `selectionStartLineIndex`, call `setSelection()`.
	**/
	@:flash.property
	public var selectionStartLineIndex(get, never):Int;

	private function get_selectionStartLineIndex():Int {
		return _selectionStartLineIndex;
	}

	private var _selectionStartCharIndex:Int = -1;

	/**
		The character index of the start of the selection.

		To set `selectionStartCharIndex`, call `setSelection()`.
	**/
	@:flash.property
	public var selectionStartCharIndex(get, never):Int;

	private function get_selectionStartCharIndex():Int {
		return _selectionStartCharIndex;
	}

	private var _selectionEndLineIndex:Int = -1;

	/**
		The line index of the end of the selection.

		To set `selectionEndLineIndex`, call `setSelection()`.
	**/
	@:flash.property
	public var selectionEndLineIndex(get, never):Int;

	private function get_selectionEndLineIndex():Int {
		return _selectionEndLineIndex;
	}

	private var _selectionEndCharIndex:Int = -1;

	/**
		The character index of the end of the selection.

		To set `selectionEndCharIndex`, call `setSelection()`.
	**/
	@:flash.property
	public var selectionEndCharIndex(get, never):Int;

	private function get_selectionEndCharIndex():Int {
		return _selectionEndCharIndex;
	}

	@:flash.property
	public var caretLine(get, never):TextLineModel;

	private function get_caretLine():TextLineModel {
		if (_caretLineIndex == -1) {
			return null;
		}
		return _lines.get(_caretLineIndex);
	}

	private var _caretLineIndex:Int = 0;

	/**
		The line index of the caret.

		To set `caretLineIndex`, use `setSelection()` with both char values equal
	**/
	@:flash.property
	public var caretLineIndex(get, never):Int;

	private function get_caretLineIndex():Int {
		return _caretLineIndex;
	}

	private var _expandedCaretCharIndex:Int = 0;

	/**
		The character index of the caret.

		To set `caretCharIndex`, use `setSelection()` with both char values equal
	**/
	@:flash.property
	public var caretCharIndex(get, never):Int;

	private function get_caretCharIndex():Int {
		var caretLine = _lines.get(_caretLineIndex);
		if (caretLine == null) {
			return 0;
		}
		// we allow a larger caretIndex to remain here after moving to a shorter
		// line because it will be restored after moving back to a longer line

		// Get current line indentation
		var indent = TextUtil.indentAmount(caretLine.text);
		// Get the index with tabs contracted
		var index = _expandedCaretCharIndex - indent * (_tabWidth - 1);
		// If the index falls within the indentation, approximate
		if (index <= indent) {
			index = Math.round(_expandedCaretCharIndex / _tabWidth);
		}

		// Limit the index by the line length
		return Std.int(Math.min(index, caretLine.text.length));
	}

	/**
		Used by the `SelectionManager` for smarter caret placement when moving
		the caret between multiple lines.
	**/
	@:flash.property
	public var expandedCaretCharIndex(get, never):Int;

	private function get_expandedCaretCharIndex():Int {
		return _expandedCaretCharIndex;
	}

	private var _tabWidth:Int = 4;

	/**
		The number of spaces that make up a tab character.
	**/
	@:flash.property
	public var tabWidth(get, set):Int;

	private function get_tabWidth():Int {
		return _tabWidth;
	}

	private function set_tabWidth(value:Int):Int {
		if (_tabWidth == value) {
			return _tabWidth;
		}
		_tabWidth = value;
		setInvalid(DATA);
		return _tabWidth;
	}

	/**
		Determines if the tab key should insert spaces instead of the tab `\t`
		character.

		@see `TextEditor.tabWidth`
	**/
	public var insertSpacesForTabs:Bool = false;

	public var allowToggleBreakpoints:Bool = false;

	@:flash.property
	public var breakpoints(get, set):Array<Int>;

	private function get_breakpoints():Array<Int> {
		var result:Array<Int> = [];
		for (i in 0..._lines.length) {
			var line = _lines.get(i);
			if (line.breakpoint) {
				result.push(i);
			}
		}
		return result;
	}

	private function set_breakpoints(value:Array<Int>):Array<Int> {
		for (i in 0..._lines.length) {
			var line = _lines.get(i);
			line.breakpoint = value.contains(i);
		}
		return value;
	}

	private var _debuggerLineIndex:Int = -1;

	/**
		The line index where the debugger is currently stopped. If the debugger
		is not currently stopped on a line, the value is `-1`.
	**/
	@:flash.property
	public var debuggerLineIndex(get, set):Int;

	private function get_debuggerLineIndex():Int {
		return _caretLineIndex;
	}

	private function set_debuggerLineIndex(value:Int):Int {
		if (_debuggerLineIndex == value) {
			return _debuggerLineIndex;
		}
		_debuggerLineIndex = value;
		setInvalid(DATA);
		return _debuggerLineIndex;
	}

	private var _textLineModelFactory:(String, Int) -> TextLineModel = (text, lineIndex) -> new TextLineModel(text, lineIndex);

	/**
		Used to customize how new `TextLineModel` objects are created.
	**/
	@:flash.property
	public var textLineModelFactory(get, set):(String, Int) -> TextLineModel;

	private function get_textLineModelFactory():(String, Int) -> TextLineModel {
		return _textLineModelFactory;
	}

	private function set_textLineModelFactory(value:(String, Int) -> TextLineModel):(String, Int) -> TextLineModel {
		if (value == _textLineModelFactory) {
			return _textLineModelFactory;
		}
		_textLineModelFactory = value;
		for (i in 0..._lines.length) {
			var oldLine = _lines.get(i);
			_lines.set(i, _textLineModelFactory(oldLine.text, oldLine.lineIndex));
		}
		return _textLineModelFactory;
	}

	/**
		Updates the code parser used for syntax highlighting.
	**/
	public function setParserAndTextStyles(parser:ILineParser, textStyles:Map<Int, TextFormat>):Void {
		_parser = parser;
		_textStyles = textStyles;
		_colorManager.parser = parser;
		setInvalid(DATA);
	}

	/**
		Returns the visible bounds of the view port.
	**/
	public function getViewPortVisibleBounds(result:Rectangle = null):Rectangle {
		return _viewPortVisibleBounds;
	}

	/**
		To be called when the file is saved. Updates the undo/redo manager
		appropriately.
	**/
	public function save():Void {
		if (_undoManager != null) {
			_undoManager.save();
		}
	}

	/**
		Used by `SelectionManager` to preserve the expanded caret char index.
	**/
	public function setSelectionAdvanced(startLine:Int, startChar:Int, endLine:Int, endChar:Int, expandCaret:Bool):Void {
		var selectionChanged = false;
		var maxLine = _lines.length - 1;
		if (startLine > maxLine) {
			startLine = maxLine;
		}
		if (startLine < 0) {
			startLine = 0;
		}
		if (startChar < 0) {
			startChar = 0;
		}
		if (endLine > maxLine) {
			endLine = maxLine;
		}
		if (endLine < 0) {
			endLine = 0;
		}
		if (endChar < 0) {
			endChar = 0;
		}
		if (startLine == endLine && startChar == endChar) {
			if (_selectionStartCharIndex != -1) {
				_selectionStartLineIndex = -1;
				_selectionStartCharIndex = -1;
				_selectionEndLineIndex = -1;
				_selectionEndCharIndex = -1;
				selectionChanged = true;
			}
		} else {
			if (_selectionStartLineIndex != startLine) {
				_selectionStartLineIndex = startLine;
				selectionChanged = true;
			}
			if (_selectionStartCharIndex != startChar) {
				_selectionStartCharIndex = startChar;
				selectionChanged = true;
			}
			if (_selectionEndLineIndex != endLine) {
				_selectionEndLineIndex = endLine;
				selectionChanged = true;
			}
			if (_selectionEndCharIndex != endChar) {
				_selectionEndCharIndex = endChar;
				selectionChanged = true;
			}
		}
		if (_caretLineIndex != endLine) {
			_caretLineIndex = endLine;
			selectionChanged = true;
		}
		var newCaretCharIndex = expandCaret ? expandCaretCharIndex(endChar) : endChar;
		if (_expandedCaretCharIndex != newCaretCharIndex) {
			_expandedCaretCharIndex = newCaretCharIndex;
			selectionChanged = true;
		}
		if (!selectionChanged) {
			return;
		}
		_lines.updateAll();
		dispatchEvent(new TextEditorEvent(TextEditorEvent.SELECTION_CHANGE));
	}

	/**
		Selects the specified range. If the start and end positions are the
		same, nothing will be selected, but the caret will move.
	**/
	public function setSelection(startLine:Int, startChar:Int, endLine:Int, endChar:Int):Void {
		setSelectionAdvanced(startLine, startChar, endLine, endChar, true);
	}

	/**
		Removes the current selection.
	**/
	public function removeSelection():Void {
		if (_selectionStartLineIndex == -1) {
			return;
		}
		setSelectionAdvanced(_caretLineIndex, _expandedCaretCharIndex, _caretLineIndex, _expandedCaretCharIndex, false);
	}

	/**
		Searches for the specified `String` or `EReg` in the editor's text.
	**/
	public function find(search:Any /* EReg | String */, backwards:Bool = false, allowWrap:Bool = true):TextEditorSearchResult {
		return _findReplaceManager.find(search, backwards, allowWrap);
	}

	/**
		Makes the next `find()` result into the current result.

		Must be called after `find()`
	**/
	public function findNext(backwards:Bool = false, allowWrap:Bool = true):TextEditorSearchResult {
		return _findReplaceManager.findNext(backwards, allowWrap);
	}

	/**
		Replaces the current `find()` result with the specified text.

		Must be called after `find()`
	**/
	public function replaceOne(newText:String, allowWrap:Bool = true):TextEditorSearchResult {
		if (readOnly) {
			throw new IllegalOperationError("Replace not allowed on read-only text editor");
		}
		return _findReplaceManager.replace(newText, false, allowWrap);
	}

	/**
		Replaces all `find()` results with the specified text.

		Must be called after `find()`
	**/
	public function replaceAll(newText:String):TextEditorSearchResult {
		if (readOnly) {
			throw new IllegalOperationError("Replace all not allowed on read-only text editor");
		}
		return _findReplaceManager.replace(newText, true);
	}

	/**
		Returns the boundaries of the specified character index.

		Similar to `TextField.getCharBoundaries()`
	**/
	public function getTextEditorPositionBoundaries(pos:TextEditorPosition):Rectangle {
		var lineIndex = pos.line;
		var line = _lines.get(lineIndex);
		var charX = 0.0;
		var charWidth = 0.0;
		// prefer the existing text line renderer
		var textLineRenderer = cast(_listView.itemToItemRenderer(line), TextLineRenderer);
		if (textLineRenderer != null) {
			var bounds = textLineRenderer.getCharBoundaries(pos.character);
			charX = bounds.x;
			charWidth = bounds.width;
		} else {
			var state = new ListViewItemState(line, lineIndex, false, line.text);
			textLineRenderer = createTextLineRenderer();
			updateTextLineRenderer(textLineRenderer, state);
			// getCharBoundaries() doesn't return an accurate result unless the
			// TextField is added to the stage
			Lib.current.stage.addChild(textLineRenderer);
			textLineRenderer.validateNow();
			var bounds = textLineRenderer.getCharBoundaries(pos.character);
			charX = bounds.x;
			charWidth = bounds.width;
			resetTextLineRenderer(textLineRenderer, state);
			Lib.current.stage.removeChild(textLineRenderer);
			destroyTextLineRenderer(textLineRenderer);
		}
		var localX = _viewPortVisibleBounds.x + charX - _listView.scrollX;
		var localY = _viewPortVisibleBounds.y + (lineHeight * lineIndex) - _listView.scrollY;
		return new Rectangle(localX, localY, charWidth, lineHeight);
	}

	/**
		Converts a `TextEditorPosition` object to a `Point` in the local
		coordinate sytem.
	**/
	public function textEditorPositionToLocal(pos:TextEditorPosition):Point {
		var lineIndex = pos.line;
		if (lineIndex < 0 || lineIndex >= _lines.length) {
			return null;
		}
		var charX = 0.0;
		var line = _lines.get(lineIndex);
		var textLineRenderer = cast(_listView.itemToItemRenderer(line), TextLineRenderer);
		if (textLineRenderer != null) {
			var bounds = textLineRenderer.getCharBoundaries(pos.character);
			charX = bounds.x;
		} else {
			var state = new ListViewItemState(line, lineIndex, false, line.text);
			textLineRenderer = createTextLineRenderer();
			updateTextLineRenderer(textLineRenderer, state);
			// getCharBoundaries() doesn't return an accurate result unless the
			// TextField is added to the stage
			Lib.current.stage.addChild(textLineRenderer);
			textLineRenderer.validateNow();
			var bounds = textLineRenderer.getCharBoundaries(pos.character);
			charX = bounds.x;
			resetTextLineRenderer(textLineRenderer, state);
			Lib.current.stage.removeChild(textLineRenderer);
			destroyTextLineRenderer(textLineRenderer);
		}
		var localX = _viewPortVisibleBounds.x + charX - _listView.scrollX;
		var localY = _viewPortVisibleBounds.y + lineHeight * pos.line - _listView.scrollY;
		return new Point(localX, localY);
	}

	/**
		Converts a `Point` in the local coordinate system to a
		`TextEditorPosition` object.
	**/
	public function localToTextEditorPosition(localXY:Point, forSelection:Bool = false):TextEditorPosition {
		var lineIndex = Std.int((localXY.y + _listView.scrollY) / lineHeight);
		if (forSelection) {
			lineIndex = Std.int(Math.max(0, Math.min(_lines.length - 1, lineIndex)));
		} else if (lineIndex < 0 || lineIndex >= _lines.length) {
			return null;
		}
		var charIndex = -1;
		var line = _lines.get(lineIndex);
		// prefer the existing text line renderer
		var textLineRenderer = cast(_listView.itemToItemRenderer(line), TextLineRenderer);
		if (textLineRenderer != null) {
			var rendererXY = textLineRenderer.globalToLocal(localToGlobal(localXY));
			if (forSelection) {
				charIndex = textLineRenderer.getSelectionCharIndexAtPoint(rendererXY.x, rendererXY.y);
			} else {
				charIndex = textLineRenderer.getCharIndexAtPoint(rendererXY.x, rendererXY.y);
			}
		} else {
			var state = new ListViewItemState(line, lineIndex, false, line.text);
			textLineRenderer = createTextLineRenderer();
			updateTextLineRenderer(textLineRenderer, state);
			textLineRenderer.validateNow();
			var rendererX = localXY.x - _viewPortVisibleBounds.x;
			var rendererY = localXY.y - _viewPortVisibleBounds.y - (lineIndex * _lineHeight);
			if (forSelection) {
				charIndex = textLineRenderer.getSelectionCharIndexAtPoint(rendererX, rendererY);
			} else {
				charIndex = textLineRenderer.getCharIndexAtPoint(rendererX, rendererY);
			}
			resetTextLineRenderer(textLineRenderer, state);
			destroyTextLineRenderer(textLineRenderer);
		}
		if (charIndex == -1) {
			return null;
		}
		return new TextEditorPosition(lineIndex, charIndex);
	}

	/**
		Scrolls the view to display the caret, if it is not currently visible.
	**/
	public function scrollViewIfNeeded():Void {
		if (_lines.length == 0 || _caretLineIndex == -1 || _expandedCaretCharIndex == -1) {
			return;
		}
		_ignoreScrollChanges = true;
		var caretLine = _lines.get(_caretLineIndex);
		var caretLineText = caretLine.text.substring(0, caretCharIndex);
		var caretPos = TextEditorUtil.estimateTextWidth(this, caretLineText) + _gutterWidth + _viewPortVisibleBounds.x;

		if (_caretLineIndex < lineScrollY || visibleLines <= 2 && _caretLineIndex > lineScrollY) {
			lineScrollY = Std.int(Math.min(_caretLineIndex, _maxLineScrollY));
		} else if (visibleLines > 2 && _caretLineIndex + 2 > lineScrollY + visibleLines) {
			var newLineScrollY = _caretLineIndex - visibleLines + 2;
			if (newLineScrollY < 0) {
				newLineScrollY = 0;
			}
			lineScrollY = Std.int(Math.min(newLineScrollY, _maxLineScrollY));
		}
		var horizontalLookahead = TextEditorUtil.estimateTextWidth(this, "M") * 8.0;
		if (caretPos < (_listView.scrollX + _gutterWidth + _viewPortVisibleBounds.x)) {
			var scrollPos = caretPos - horizontalLookahead - _gutterWidth - _viewPortVisibleBounds.x;
			if (scrollPos < 0.0) {
				scrollPos = 0.0;
			}

			_listView.scrollX = scrollPos;
		} else if (caretPos > (_listView.scrollX + _viewPortVisibleBounds.width)) {
			_listView.scrollX = caretPos - _viewPortVisibleBounds.width + horizontalLookahead;
		}
		_ignoreScrollChanges = false;
	}

	override private function initialize():Void {
		if (_listView == null) {
			_listView = new TextEditorListView();
			var layout = new VerticalListFixedRowLayout();
			layout.contentJustify = true;
			_listView.layout = layout;
			_listView.scrollY = _lineScrollY * _lineHeight;
			_listView.itemRendererRecycler = DisplayObjectRecycler.withFunction(createTextLineRenderer, updateTextLineRenderer, resetTextLineRenderer,
				destroyTextLineRenderer);
			_listView.addEventListener(ScrollEvent.SCROLL, textEditor_listView_scrollHandler);
			_listView.addEventListener(FocusEvent.FOCUS_IN, textEditor_listView_focusInHandler);
			_listView.addEventListener(FocusEvent.FOCUS_OUT, textEditor_listView_focusOutHandler);
			addChild(_listView);
		}
	}

	private function expandCaretCharIndex(value:Int):Int {
		var caretLine = _lines.get(_caretLineIndex);
		// Get current line indentation
		var indent = caretLine != null ? TextUtil.indentAmount(caretLine.text) : 0;

		// Store the index with tabs expanded
		return Std.int(value + Math.min(indent, value) * (_tabWidth - 1));
	}

	private function textEditorPositionToTextLineRenderer(pos:TextEditorPosition):TextLineRenderer {
		if (pos.line < 0 || pos.line >= _lines.length) {
			return null;
		}
		return getTextLineRendererAtIndex(pos.line);
	}

	private function localToTextLineRenderer(localXY:Point):TextLineRenderer {
		var lineIndex = Std.int((localXY.y + _listView.scrollY) / lineHeight);
		return getTextLineRendererAtIndex(lineIndex);
	}

	private function getTextLineRendererAtIndex(lineIndex:Int):TextLineRenderer {
		if (isInvalid()) {
			validateNow();
		}
		return cast(_listView.indexToItemRenderer(lineIndex), TextLineRenderer);
	}

	private function createTextLineRenderer():TextLineRenderer {
		return new TextLineRenderer();
	}

	private function updateTextLineRenderer(itemRenderer:TextLineRenderer, state:ListViewItemState):Void {
		var lineModel = cast(state.data, TextLineModel);
		itemRenderer.lineIndex = lineModel.lineIndex;
		if (lineModel.lineIndex == _caretLineIndex) {
			itemRenderer.caretIndex = Std.int(Math.min(caretCharIndex, lineModel.text.length));
		} else {
			itemRenderer.caretIndex = -1;
		}
		itemRenderer.numLines = _lines.length;
		itemRenderer.tabWidth = _tabWidth;
		itemRenderer.text = lineModel.text;
		itemRenderer.scrollX = _listView.scrollX;
		itemRenderer.breakpoint = lineModel.breakpoint;
		itemRenderer.textEditorHasFocus = _hasFocus;
		itemRenderer.allowToggleBreakpoints = allowToggleBreakpoints;
		itemRenderer.debuggerStopped = _debuggerLineIndex == lineModel.lineIndex;
		itemRenderer.styleRanges = lineModel.styleRanges;
		itemRenderer.textStyles = _textStyles;
		itemRenderer.defaultTextStyleContext = (_parser != null) ? _parser.defaultContext : 0x0;
		itemRenderer.showLineNumbers = _showLineNumbers;
		itemRenderer.lineNumberWidth = lineNumberWidth;
		itemRenderer.embedFonts = embedFonts;

		if (_selectionStartLineIndex != _selectionEndLineIndex) {
			if (lineModel.lineIndex == _selectionStartLineIndex) { // Beginning of selection (may be below or above current point)
				if (_selectionStartLineIndex > _caretLineIndex) {
					itemRenderer.selectionStartIndex = 0;
					itemRenderer.selectionEndIndex = _selectionStartCharIndex;
				} else {
					itemRenderer.selectionStartIndex = _selectionStartCharIndex;
					itemRenderer.selectionEndIndex = lineModel.text.length;
				}
			} else if (lineModel.lineIndex == _caretLineIndex) { // Selected line
				if (_caretLineIndex > _selectionStartLineIndex) {
					itemRenderer.selectionStartIndex = 0;
					itemRenderer.selectionEndIndex = caretCharIndex;
				} else {
					itemRenderer.selectionStartIndex = caretCharIndex;
					itemRenderer.selectionEndIndex = lineModel.text.length;
				}
			} else if (_selectionStartLineIndex < lineModel.lineIndex
				&& _caretLineIndex > lineModel.lineIndex) { // Start of selection is above current line
				itemRenderer.selectionStartIndex = 0;
				itemRenderer.selectionEndIndex = lineModel.text.length;
			} else if (_selectionStartLineIndex > lineModel.lineIndex
				&& _caretLineIndex < lineModel.lineIndex) { // Start of selection is below current line
				itemRenderer.selectionStartIndex = 0;
				itemRenderer.selectionEndIndex = lineModel.text.length;
			} else { // No selection
				itemRenderer.selectionStartIndex = -1;
				itemRenderer.selectionEndIndex = -1;
			}
		} else {
			if (lineModel.lineIndex == _caretLineIndex) {
				itemRenderer.selectionStartIndex = _selectionStartCharIndex;
				itemRenderer.selectionEndIndex = _selectionEndCharIndex;
			} else { // No selection
				itemRenderer.selectionStartIndex = -1;
				itemRenderer.selectionEndIndex = -1;
			}
		}
		itemRenderer.addEventListener(TextEditorLineEvent.TOGGLE_BREAKPOINT, textEditor_textLineRenderer_toggleBreakpointHandler);
	}

	private function resetTextLineRenderer(itemRenderer:TextLineRenderer, state:ListViewItemState):Void {
		itemRenderer.caretIndex = -1;
		itemRenderer.lineIndex = -1;
		itemRenderer.styleRanges = null;
		itemRenderer.textStyles = null;
		itemRenderer.text = null;
		itemRenderer.selectionStartIndex = -1;
		itemRenderer.selectionEndIndex = -1;
		itemRenderer.removeEventListener(TextEditorLineEvent.TOGGLE_BREAKPOINT, textEditor_textLineRenderer_toggleBreakpointHandler);
	}

	private function destroyTextLineRenderer(itemRenderer:TextLineRenderer):Void {}

	override private function update():Void {
		var dataInvalid = isInvalid(DATA);
		var scrollInvalid = isInvalid(SCROLL);

		if (_parser == null) {
			_parser = new PlainTextLineParser();
			_textStyles = new PlainTextFormatBuilder().build();
		}

		if (dataInvalid) {
			_listView.dataProvider = _lines;
		}

		layoutContent();
	}

	private function layoutContent():Void {
		_listView.x = 0.0;
		_listView.y = 0.0;
		_listView.width = actualWidth;
		_listView.height = actualHeight;
		_listView.validateNow();

		_listView.getViewPortVisibleBounds(_viewPortVisibleBounds);
		_viewPortVisibleBounds.x += _listView.x;
		_viewPortVisibleBounds.y += _listView.y;

		var firstLine = cast(_listView.itemToItemRenderer(_lines.get(_lineScrollY)), TextLineRenderer);
		_gutterWidth = firstLine.gutterWidth;

		if (_lines.length == 0) {
			// don't want to divide by zero
			_lineHeight = 0.0;
			_visibleLines = 1;
			_maxLineScrollY = 0;
		} else {
			_lineHeight = firstLine.height;
			_visibleLines = Std.int(_viewPortVisibleBounds.height / _lineHeight);
			_maxLineScrollY = Std.int(Math.max(_visibleLines, _lines.length)) - _visibleLines;
		}
	}

	private function textEditor_focusInHandler(event:FocusEvent):Void {
		if (this.stage != null && this.stage.focus != _listView) {
			event.stopImmediatePropagation();
			this.stage.focus = _listView;
		}
	}

	private function textEditor_textChangeHandler(event:TextEditorChangeEvent):Void {
		if (_readOnly) {
			throw new IllegalOperationError("Read-only text editor must not dispatch text change event");
		}
		_lines.updateAll();
	}

	private function textEditor_colorChangeHandler(event:TextEditorLineEvent):Void {
		if (_listView == null || _listView.dataProvider == null) {
			return;
		}
		// Line invalidation is required if the changed line is on-screen
		if ((event.lineIndex >= _lineScrollY) && event.lineIndex <= (_lineScrollY + visibleLines + 1)) {
			_lines.updateAll();
		}
	}

	private function textEditor_listView_scrollHandler(event:ScrollEvent):Void {
		if (_ignoreScrollChanges) {
			return;
		}
		var newLineScrollY = 0;
		if (_lineHeight != 0.0) {
			// don't want to divide by zero
			newLineScrollY = Std.int(_listView.scrollY / _lineHeight);
		}
		_lineScrollY = newLineScrollY;
		ScrollEvent.dispatch(this, ScrollEvent.SCROLL);
	}

	private function textEditor_listView_focusInHandler(event:FocusEvent):Void {
		_hasFocus = true;
		_lines.updateAll();
	}

	private function textEditor_listView_focusOutHandler(event:FocusEvent):Void {
		_hasFocus = false;
		_lines.updateAll();
	}

	private function textEditor_textLineRenderer_toggleBreakpointHandler(event:TextEditorLineEvent):Void {
		if (!allowToggleBreakpoints) {
			return;
		}
		var lineIndex = event.lineIndex;
		var line = _lines.get(lineIndex);
		line.breakpoint = !line.breakpoint;
		lines.updateAt(lineIndex);
		dispatchEvent(new TextEditorLineEvent(TextEditorLineEvent.TOGGLE_BREAKPOINT, lineIndex));
	}

	private function textEditor_lines_changeHandler(event:Event):Void {
		setInvalid(DATA);
	}
}

private class TextEditorListView extends ListView {
	public function new() {
		super();
		selectable = false;
		// scrollPixelSnapping = true;
	}

	@:getter(tabEnabled)
	override private function get_tabEnabled() {
		return _enabled && rawTabEnabled;
	}
}
