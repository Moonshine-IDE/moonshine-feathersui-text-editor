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

package moonshine.editor.text.lines;

import feathers.core.FeathersControl;
import feathers.core.IValidating;
import feathers.skins.IProgrammaticSkin;
import feathers.skins.RectangleSkin;
import feathers.utils.TextFormatUtil;
import moonshine.editor.text.TextEditorSearchResult.SearchResultItem;
import moonshine.editor.text.events.TextEditorLineEvent;
import moonshine.editor.text.theme.TextLineRendererStyles;
import openfl.display.DisplayObject;
import openfl.events.MouseEvent;
import openfl.events.TimerEvent;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import openfl.utils.Timer;

/**
	Displays the text for a specific line within a `TextEditor`.
**/
@:styleContext
class TextLineRenderer extends FeathersControl {
	/**
		Creates a new `TextLineRenderer` object.
	**/
	public function new() {
		TextLineRendererStyles.initialize();

		super();

		_caretTimer = new Timer(600.0);
		_caretTimer.addEventListener(TimerEvent.TIMER, textLineRenderer_caretTimer_timerHandler);

		addEventListener(MouseEvent.MOUSE_DOWN, textLineRenderer_mouseDownHandler);
	}

	private var _oldMouseCursor:String;

	private var _mainTextField:TextField;
	private var _lineNumberTextField:TextField;

	private var _tabToSpaceOffsets:Array<Int> = [];
	private var _spaceToTabOffsets:Array<Int> = [];
	private var _renderedText:String;

	private var _text:String;

	/**
		The line's text.
	**/
	@:flash.property
	public var text(get, set):String;

	private function get_text():String {
		return _text;
	}

	private function set_text(value:String):String {
		if (_text == value) {
			return _text;
		}
		_text = value;
		refreshTabOffsets();
		refreshRenderedText();
		setInvalid(DATA);
		return _text;
	}

	private var _lineIndex:Int = -1;

	/**
		The index of the line within the `TextEditor`.
	**/
	@:flash.property
	public var lineIndex(get, set):Int;

	private function get_lineIndex():Int {
		return _lineIndex;
	}

	private function set_lineIndex(value:Int):Int {
		if (_lineIndex == value) {
			return _lineIndex;
		}
		_lineIndex = value;
		setInvalid(DATA);
		return _lineIndex;
	}

	private var _minLineNumberCharacters:Int = 1;

	/**
		@see `TextEditor.minLineNumberCharacters`
	**/
	@:flash.property
	public var minLineNumberCharacters(get, set):Int;

	private function get_minLineNumberCharacters():Int {
		return _minLineNumberCharacters;
	}

	private function set_minLineNumberCharacters(value:Int):Int {
		if (_minLineNumberCharacters == value) {
			return _minLineNumberCharacters;
		}
		_minLineNumberCharacters = value;
		setInvalid(DATA);
		return _minLineNumberCharacters;
	}

	private var _numLines:Int = -1;

	/**
		The total number of lines in the `TextEditor`.
	**/
	@:flash.property
	public var numLines(get, set):Int;

	private function get_numLines():Int {
		return _numLines;
	}

	private function set_numLines(value:Int):Int {
		if (_numLines == value) {
			return _numLines;
		}
		_numLines = value;
		setInvalid(DATA);
		return _numLines;
	}

	private var _tabWidth:Int = 4;

	/**
		@see `TextEditor.tabWidth`
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

	private var _styleRanges:Array<Int>;

	/**
		Alternating text index values and identifiers from the `textStyles` that
		indicate ranges for syntax highlighting.

		@see `TextLineRenderer.textStyles`
	**/
	@:flash.property
	public var styleRanges(get, set):Array<Int>;

	private function get_styleRanges():Array<Int> {
		return _styleRanges;
	}

	private function set_styleRanges(value:Array<Int>):Array<Int> {
		if (_styleRanges == value) {
			return _styleRanges;
		}
		_styleRanges = value;
		setInvalid(DATA);
		return _styleRanges;
	}

	private var _breakpoint:Bool;

	/**
		Determines if the current line has a breakpoint.

		@see `TextLineRenderer.breakpointVerified`
		@see `TextLineRenderer.breakpointSkin`
	**/
	@:flash.property
	public var breakpoint(get, set):Bool;

	private function get_breakpoint():Bool {
		return _breakpoint;
	}

	private function set_breakpoint(value:Bool):Bool {
		if (_breakpoint == value) {
			return _breakpoint;
		}
		_breakpoint = value;
		setInvalid(DATA);
		return _breakpoint;
	}

	private var _breakpointVerified:Bool = true;

	/**
		Determines if the current line's breakpoint is considered to be
		_verified_. If unverified, it may be displayed in a less prominent
		visual style.

		@see `TextLineRenderer.breakpoint`
		@see `TextLineRenderer.unverifiedBreakpointSkin`
	**/
	@:flash.property
	public var breakpointVerified(get, set):Bool;

	private function get_breakpointVerified():Bool {
		return _breakpointVerified;
	}

	private function set_breakpointVerified(value:Bool):Bool {
		if (_breakpointVerified == value) {
			return _breakpointVerified;
		}
		_breakpointVerified = value;
		setInvalid(DATA);
		return _breakpointVerified;
	}

	private var _renderTabsWithSpaces = #if flash false #else true #end;

	private var _debuggerStopped:Bool = false;

	/**
		Indicates if the debugger is currently stopped on this line.
	**/
	@:flash.property
	public var debuggerStopped(get, set):Bool;

	private function get_debuggerStopped():Bool {
		return _debuggerStopped;
	}

	private function set_debuggerStopped(value:Bool):Bool {
		if (_debuggerStopped == value) {
			return _debuggerStopped;
		}
		_debuggerStopped = value;
		setInvalid(DATA);
		return _debuggerStopped;
	}

	private var _caretX:Float = 0.0;

	/**
		Returns the current `x` position of the caret, if it appears on this
		line.
	**/
	@:flash.property
	public var caretX(get, never):Float;

	private function get_caretX():Float {
		return _caretX;
	}

	private var _gutterWidth:Float = 0.0;

	/**
		Returns the width of the gutter.
	**/
	@:flash.property
	public var gutterWidth(get, never):Float;

	private function get_gutterWidth():Float {
		return _gutterWidth;
	}

	private var _lineNumberWidth:Null<Float> = null;

	/**
		@see `TextEditor.lineNumberWidth`
	**/
	@:flash.property
	public var lineNumberWidth(get, set):Null<Float>;

	private function get_lineNumberWidth():Null<Float> {
		return _lineNumberWidth;
	}

	private function set_lineNumberWidth(value:Null<Float>):Null<Float> {
		if (_lineNumberWidth == value) {
			return _lineNumberWidth;
		}
		_lineNumberWidth = value;
		setInvalid(DATA);
		return _lineNumberWidth;
	}

	private var _showLineNumbers:Bool = true;

	/**
		@see `TextEditor.showLineNumbers`
	**/
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

	private var _allowToggleBreakpoints:Bool = false;

	/**
		@see `TextEditor.allowToggleBreakpoints`
	**/
	@:flash.property
	public var allowToggleBreakpoints(get, set):Bool;

	private function get_allowToggleBreakpoints():Bool {
		return _allowToggleBreakpoints;
	}

	private function set_allowToggleBreakpoints(value:Bool):Bool {
		if (_allowToggleBreakpoints == value) {
			return _allowToggleBreakpoints;
		}
		_allowToggleBreakpoints = value;
		setInvalid(DATA);
		return _allowToggleBreakpoints;
	}

	private var _caretTimer:Timer;

	private var _caretSkin:RectangleSkin;

	/**
		Determines if an embedded font is used for the text displayed by the
		text line renderer.
	**/
	@:style
	public var embedFonts:Bool = false;

	/**
		The text format used for line numbers.
	**/
	@:style
	public var lineNumberTextFormat:TextFormat = null;

	private var _currentGutterBackgroundSkin:DisplayObject;

	/**
		The optional background skin to display behind the gutter.
	**/
	@:style
	public var gutterBackgroundSkin:DisplayObject = null;

	/**
		The optional background skin to display behind the gutter when a
		breakpoint has been added to this line.
	**/
	@:style
	public var breakpointGutterBackgroundSkin:DisplayObject = null;

	private var _currentBackgroundSkin:DisplayObject;

	/**
		The default background skin to display behind the text line renderer's
		content.
	**/
	@:style
	public var backgroundSkin:DisplayObject = null;

	/**
		The background skin to display behind the text line renderer's content
		when the line has focus.
	**/
	@:style
	public var focusedBackgroundSkin:DisplayObject = null;

	/**
		The background skin to display behind the text line renderer's content
		when the debugger is stopped at this line.
	**/
	@:style
	public var debuggerStoppedBackgroundSkin:DisplayObject = null;

	private var _currentSelectedTextBackgroundSkin:DisplayObject;

	/**
		The background skin to display behind selected text.
	**/
	@:style
	public var selectedTextBackgroundSkin:DisplayObject = null;

	/**
		The background skin to display behind selected text when the text line
		renderer is not focused.
	**/
	@:style
	public var selectedTextUnfocusedBackgroundSkin:DisplayObject = null;

	/**
		Creates background skins for search results.
	**/
	@:style
	public var searchResultBackgroundSkinFactory:() -> DisplayObject = null;

	/**
		Maps identifiers for syntax highlighting styles to `TextFormat` values.

		@see `TextLineRenderer.styleRanges`
	**/
	@:style
	public var textStyles:Map<Int, TextFormat> = null;

	private var _defaultTextStyleContext:Int = 0x0;

	/**
		The default text style context for the current language.
	**/
	@:flash.property
	public var defaultTextStyleContext(get, set):Int;

	private function get_defaultTextStyleContext():Int {
		return _defaultTextStyleContext;
	}

	private function set_defaultTextStyleContext(value:Int):Int {
		if (_defaultTextStyleContext == value) {
			return _defaultTextStyleContext;
		}
		_defaultTextStyleContext = value;
		setInvalid(STYLES);
		return _defaultTextStyleContext;
	}

	private var _currentBreakpointSkin:DisplayObject;

	/**
		The skin to display a breakpoint in the renderer's gutter.

		@see `TextLineRenderer.breakpoint`
	**/
	@:style
	public var breakpointSkin:DisplayObject = null;

	/**
		The skin to display an unverified breakpoint in the renderer's gutter.

		@see `TextLineRenderer.breakpoint`
		@see `TextLineRenderer.unverifiedBreakpoint`
	**/
	@:style
	public var unverifiedBreakpointSkin:DisplayObject = null;

	/**
		The space, measured in pixels, between items added to the renderer's
		gutter.

		@see `TextLineRenderer.gutterPaddingLeft`
		@see `TextLineRenderer.gutterPaddingRight`
	**/
	@:style
	public var gutterGap:Float = 0.0;

	/**
		The space, measured in pixels, that appears on the left side of the
		gutter.

		@see `TextLineRenderer.gutterPaddingRight`
		@see `TextLineRenderer.gutterGap`
	**/
	@:style
	public var gutterPaddingLeft:Float = 0.0;

	/**
		The space, measured in pixels, that appears on the right side of the
		gutter.

		@see `TextLineRenderer.gutterPaddingLeft`
		@see `TextLineRenderer.gutterGap`
	**/
	@:style
	public var gutterPaddingRight:Float = 0.0;

	private var _scrollX:Float = 0.0;

	/**
		The current horizontal scroll position of the `TextEditor`.
	**/
	@:flash.property
	public var scrollX(get, set):Float;

	private function get_scrollX():Float {
		return _scrollX;
	}

	private function set_scrollX(value:Float):Float {
		if (_scrollX == value) {
			return _scrollX;
		}
		_scrollX = value;
		setInvalid(SCROLL);
		return _scrollX;
	}

	private var _caretIndex:Int = -1;

	/**
		The character index of the caret on this line, or `-1`, if the caret is 
		currently on a different line.
	**/
	@:flash.property
	public var caretIndex(get, set):Int;

	private function get_caretIndex():Int {
		return _caretIndex;
	}

	private function set_caretIndex(value:Int):Int {
		if (_caretIndex == value) {
			return _caretIndex;
		}
		_caretIndex = value;
		refreshCaretTimer();
		setInvalid(STATE);
		return _caretIndex;
	}

	private var _textEditorHasFocus:Bool = false;

	/**
		Indicates if the `TextEditor` currently has focus.
	**/
	@:flash.property
	public var textEditorHasFocus(get, set):Bool;

	private function get_textEditorHasFocus():Bool {
		return _textEditorHasFocus;
	}

	private function set_textEditorHasFocus(value:Bool):Bool {
		if (_textEditorHasFocus == value) {
			return _textEditorHasFocus;
		}
		_textEditorHasFocus = value;
		refreshCaretTimer();
		setInvalid(STATE);
		return _textEditorHasFocus;
	}

	private var _selectionStartIndex:Int = -1;

	/**
		The start character index of this line's current selection, or `-1` if
		there is no selection on this line.

		@see `TextLineRenderer.selectionEndIndex`
	**/
	@:flash.property
	public var selectionStartIndex(get, set):Int;

	private function get_selectionStartIndex():Int {
		return _selectionStartIndex;
	}

	private function set_selectionStartIndex(value:Int):Int {
		if (_selectionStartIndex == value) {
			return _selectionStartIndex;
		}
		_selectionStartIndex = value;
		setInvalid(STATE);
		return _selectionStartIndex;
	}

	private var _selectionEndIndex:Int = -1;

	/**
		The end character index of this line's current selection, or `-1` if
		there is no selection on this line.

		@see `TextLineRenderer.selectionStartIndex`
	**/
	@:flash.property
	public var selectionEndIndex(get, set):Int;

	private function get_selectionEndIndex():Int {
		return _selectionEndIndex;
	}

	private function set_selectionEndIndex(value:Int):Int {
		if (_selectionEndIndex == value) {
			return _selectionEndIndex;
		}
		_selectionEndIndex = value;
		setInvalid(STATE);
		return _selectionEndIndex;
	}

	private var _linkStartChar:Int = -1;

	/**
		The start character index of a link on this line, or `-1` if
		there is no link on this line.

		@see `TextLineRenderer.linkEndChar`
	**/
	@:flash.property
	public var linkStartChar(get, set):Int;

	private function get_linkStartChar():Int {
		return _linkStartChar;
	}

	private function set_linkStartChar(value:Int):Int {
		if (_linkStartChar == value) {
			return _linkStartChar;
		}
		_linkStartChar = value;
		setInvalid(DATA);
		return _linkStartChar;
	}

	private var _linkEndChar:Int = -1;

	/**
		The end character index of a link on this line, or `-1` if
		there is no link on this line.

		@see `TextLineRenderer.linkStartChar`
	**/
	@:flash.property
	public var linkEndChar(get, set):Int;

	private function get_linkEndChar():Int {
		return _linkEndChar;
	}

	private function set_linkEndChar(value:Int):Int {
		if (_linkEndChar == value) {
			return _linkEndChar;
		}
		_linkEndChar = value;
		setInvalid(DATA);
		return _linkEndChar;
	}

	@:style
	public var highlightAllFindResults:Bool = false;

	private var _searchResultBackgroundSkins:Array<DisplayObject> = [];

	private var _currentSearchResults:Array<SearchResultItem> = [];

	private var _searchResult:TextEditorSearchResult = null;

	/**
		The current search result displayed by the text editor.
	**/
	@:flash.property
	public var searchResult(get, set):TextEditorSearchResult;

	private function get_searchResult():TextEditorSearchResult {
		return _searchResult;
	}

	private function set_searchResult(value:TextEditorSearchResult):TextEditorSearchResult {
		if (_searchResult == value) {
			return _searchResult;
		}
		_searchResult = value;
		setInvalid(STATE);
		return _searchResult;
	}

	/**
		Returns the boundaries of the specified character index. If the index
		is out of the text length, returns null.
	**/
	public function getCharBoundaries(charIndex:Int):Rectangle {
		validateNow();
		var end = charIndex == _text.length;
		if (end) {
			if (charIndex == 0) {
				return new Rectangle(_mainTextField.x, _mainTextField.y, 0.0, _mainTextField.textHeight);
			}
			charIndex--;
		}
		var renderedCharIndex = textIndexToRenderedIndex(charIndex);
		var bounds = _mainTextField.getCharBoundaries(renderedCharIndex);
		if (bounds == null) {
			return null;
		}
		bounds.x += _mainTextField.x;
		bounds.y += _mainTextField.y;
		if (end) {
			bounds.x += bounds.width;
			bounds.width = 0.0;
		}
		return bounds;
	}

	/**
		Returns the character index of the specified local x/y point. If the
		local point is out of bounds, returns `-1`.

		Similar to `TextField.getCharIndexAtPoint()`
	**/
	public function getCharIndexAtPoint(localX:Float, localY:Float):Int {
		validateNow();
		if (_mainTextField == null) {
			return -1;
		}
		var renderedIndex = _mainTextField.getCharIndexAtPoint(localX - _mainTextField.x, localY - _mainTextField.y);
		if (renderedIndex == -1) {
			return renderedIndex;
		}
		return renderedIndexToTextIndex(renderedIndex);
	}

	/**
		Similar to `getCharIndexAtPoint()`, but avoids returning `-1`. When
		out of bounds, returns either the first or last index.
	**/
	public function getSelectionCharIndexAtPoint(localX:Float, localY:Float, returnNextAfterCenter:Bool = true):Int {
		validateNow();
		if (_mainTextField == null) {
			return 0;
		}

		if (localX < _gutterWidth) {
			// before text
			return 0;
		} else if (localX >= (_mainTextField.x + _mainTextField.width)) {
			// after text
			return _text.length;
		}
		// Get a line through the middle of the text field for y
		var renderedCharIndexAtPoint = _mainTextField.getCharIndexAtPoint(localX - _mainTextField.x, actualHeight / 2.0);
		if (renderedCharIndexAtPoint != -1 && returnNextAfterCenter) {
			var bounds = _mainTextField.getCharBoundaries(renderedCharIndexAtPoint);
			var center = _gutterWidth + bounds.x + (bounds.width / 2.0);
			// If point falls after the center of the character, move to next one
			if (localX >= center) {
				renderedCharIndexAtPoint++;
			}
		}

		return renderedIndexToTextIndex(renderedCharIndexAtPoint);
	}

	override private function initialize():Void {
		if (_mainTextField == null) {
			_mainTextField = new TextField();
			_mainTextField.autoSize = LEFT;
			_mainTextField.selectable = false;
			_mainTextField.mouseWheelEnabled = false;
			_mainTextField.addEventListener(MouseEvent.ROLL_OVER, textLineRenderer_mainTextField_rollOverHandler);
			_mainTextField.addEventListener(MouseEvent.ROLL_OUT, textLineRenderer_mainTextField_rollOutHandler);
			addChild(_mainTextField);
		}
		if (_lineNumberTextField == null) {
			_lineNumberTextField = new TextField();
			_lineNumberTextField.autoSize = LEFT;
			_lineNumberTextField.selectable = false;
			_lineNumberTextField.mouseWheelEnabled = false;
			_lineNumberTextField.addEventListener(MouseEvent.MOUSE_DOWN, textLineRenderer_lineNumberTextField_mouseDownHandler);
			addChild(_lineNumberTextField);
		}
	}

	override private function update():Void {
		var dataInvalid = isInvalid(DATA);
		var scrollInvalid = isInvalid(SCROLL);
		var stateInvalid = isInvalid(STATE);
		var stylesInvalid = isInvalid(STYLES);

		if (stateInvalid || stylesInvalid || dataInvalid) {
			refreshCurrentSearchResults();
		}

		if (stateInvalid || stylesInvalid) {
			refreshBackgroundSkin();
		}

		if (dataInvalid || stylesInvalid) {
			refreshGutterBackgroundSkin();
			refreshBreakpointSkin();
		}

		if (stylesInvalid || stateInvalid) {
			refreshSelectedTextBackgroundSkin();
		}

		if (stylesInvalid) {
			refreshCaretSkin();
		}

		if (dataInvalid || stylesInvalid) {
			refreshLineNumber();
			refreshText();
		}

		if (dataInvalid || stylesInvalid) {
			refreshLineNumberTextStyles();
		}

		if (dataInvalid || stylesInvalid) {
			refreshGutterWidth();
		}

		if (dataInvalid || stateInvalid || stylesInvalid) {
			refreshCaretPosition();
		}

		if (stateInvalid || stylesInvalid) {
			refreshSelectionPosition();
		}

		measure();

		layoutContent();

		if (dataInvalid || stateInvalid || stylesInvalid) {
			refreshSearchResultBackgroundSkins();
		}
	}

	private function measure():Bool {
		var needsWidth = explicitWidth == null;
		var needsHeight = explicitHeight == null;
		var needsMinWidth = explicitMinWidth == null;
		var needsMinHeight = explicitMinHeight == null;
		var needsMaxWidth = explicitMaxWidth == null;
		var needsMaxHeight = explicitMaxHeight == null;
		if (!needsWidth && !needsHeight && !needsMinWidth && !needsMinHeight && !needsMaxWidth && !needsMaxHeight) {
			return false;
		}

		var newWidth = explicitWidth;
		if (needsWidth) {
			newWidth = _gutterWidth + _mainTextField.width;
		}

		var newHeight = explicitHeight;
		if (needsHeight) {
			newHeight = Math.max(_lineNumberTextField.height, _mainTextField.height);
		}

		return saveMeasurements(newWidth, newHeight);
	}

	private function refreshLineNumber():Void {
		var lineNumberText = Std.string(lineIndex + 1);
		var minNumChars = Std.int(Math.max(_minLineNumberCharacters, Std.string(numLines).length));
		lineNumberText = StringTools.lpad(lineNumberText, " ", minNumChars);
		_lineNumberTextField.text = lineNumberText;
	}

	private function refreshLineNumberTextStyles():Void {
		var tf = lineNumberTextFormat;
		if (tf == null) {
			if (textStyles == null) {
				return;
			}
			tf = textStyles.get(_defaultTextStyleContext);
		}
		if (tf == null) {
			return;
		}
		_lineNumberTextField.setTextFormat(tf);
		_lineNumberTextField.embedFonts = embedFonts;
	}

	private function refreshTabOffsets():Void {
		_tabToSpaceOffsets.resize(0);
		_spaceToTabOffsets.resize(0);
		if (_text == null || _text.length == 0 || !_renderTabsWithSpaces) {
			return;
		}
		var renderedCurrent = 0;
		var previous = 0;
		var current = 0;
		while ((current = _text.indexOf("\t", current)) != -1) {
			renderedCurrent += (current - previous);
			var spacesCount = renderedCurrent % _tabWidth;
			if (spacesCount == 0) {
				spacesCount = 4;
			}
			_tabToSpaceOffsets.push(current);
			_tabToSpaceOffsets.push(spacesCount);
			for (i in (renderedCurrent + 1)...(renderedCurrent + spacesCount)) {
				_spaceToTabOffsets.push(i);
				_spaceToTabOffsets.push((-1));
			}
			current++;
			renderedCurrent += spacesCount;
			previous = current;
		}
	}

	private function refreshRenderedText():Void {
		if (_text == null || _text.length == 0) {
			// some invisible whitespace for accurate height measurement
			_renderedText = " ";
			return;
		}
		if (!_renderTabsWithSpaces) {
			_renderedText = _text;
			return;
		}
		_renderedText = "";
		var i = 0;
		var previous = 0;
		while (i < _tabToSpaceOffsets.length) {
			var current = _tabToSpaceOffsets[i];
			i++;
			var spacesCount = _tabToSpaceOffsets[i];
			i++;
			var startSubstr = _text.substring(previous, current);
			var spaces = StringTools.rpad("", " ", spacesCount);
			_renderedText += startSubstr + spaces;
			previous = current + 1;
		}
		_renderedText += _text.substring(previous);
	}

	private function textIndexToRenderedIndex(textIndex:Int):Int {
		if (!_renderTabsWithSpaces) {
			return textIndex;
		}
		var renderedIndex = textIndex;
		var i = 0;
		while (i < _tabToSpaceOffsets.length) {
			var current = _tabToSpaceOffsets[i];
			i++;
			if (current >= textIndex) {
				break;
			}
			var spacesCount = _tabToSpaceOffsets[i];
			i++;
			renderedIndex += (spacesCount - 1);
		}
		return renderedIndex;
	}

	private function renderedIndexToTextIndex(renderedIndex:Int):Int {
		if (!_renderTabsWithSpaces) {
			return renderedIndex;
		}
		var textIndex = renderedIndex;
		var i = 0;
		while (i < _spaceToTabOffsets.length) {
			var current = _spaceToTabOffsets[i];
			i++;
			if (current > renderedIndex) {
				break;
			}
			var spacesCount = _spaceToTabOffsets[i];
			i++;
			textIndex += spacesCount;
		}
		return textIndex;
	}

	private function refreshText():Void {
		_mainTextField.text = _renderedText;
		if (textStyles == null) {
			return;
		}
		var lineTextLength = _text.length;
		var linkStartChar = _linkStartChar;
		if (linkStartChar > lineTextLength) {
			linkStartChar = lineTextLength;
		}
		var linkEndChar = _linkEndChar;
		if (linkEndChar > lineTextLength) {
			linkEndChar = lineTextLength;
		}
		var i = 0;
		do {
			var current = 0;
			var next = lineTextLength;
			var style = _defaultTextStyleContext;
			if (_styleRanges != null && i < _styleRanges.length) {
				current = _styleRanges[i];
				i++;
				if (i < _styleRanges.length) {
					style = _styleRanges[i];
				}
				i++;
				next = lineTextLength;
				if (i < _styleRanges.length) {
					next = _styleRanges[i];
				}
			}
			if (current >= lineTextLength) {
				break;
			}
			if (next > lineTextLength) {
				// this isn't ideal, but the ColorManager may take longer to
				// completely update all syntax, so the colors may be wrong
				// for a couple of frames
				next = lineTextLength;
			}
			if (current == next) {
				continue;
			}
			var format = textStyles.get(style);
			if (format == null) {
				// TextField won't accept a null TextFormat, so use the default
				format = textStyles.get(_defaultTextStyleContext);
			}
			if (linkStartChar != -1 && linkStartChar >= current && linkStartChar < next) {
				var linkStartRendered = textIndexToRenderedIndex(linkStartChar);
				var linkEndRendered = textIndexToRenderedIndex(linkEndChar);
				var currentRendered = textIndexToRenderedIndex(current);
				var nextRendered = textIndexToRenderedIndex(next);
				var linkFormat = TextFormatUtil.clone(format);
				linkFormat.underline = true;
				if (linkStartRendered > currentRendered) {
					_mainTextField.setTextFormat(format, currentRendered, linkStartRendered);
				}
				_mainTextField.setTextFormat(linkFormat, linkStartRendered, linkEndRendered);
				if (linkEndRendered < nextRendered) {
					_mainTextField.setTextFormat(format, linkEndRendered, nextRendered);
				}
			} else {
				if (format.underline == null) {
					// null is not treated like false, so if we want to clear an
					// old link, we need false instead of null
					format.underline = false;
				}
				current = textIndexToRenderedIndex(current);
				next = textIndexToRenderedIndex(next);
				_mainTextField.setTextFormat(format, current, next);
			}
		} while (_styleRanges != null && i < _styleRanges.length);
		if (_text == null || _text.length == 0) {
			// make sure that the fallback space character used for measurement
			// has the proper formatting
			var format = textStyles.get(_defaultTextStyleContext);
			_mainTextField.setTextFormat(format);
		}
		_mainTextField.embedFonts = embedFonts;
	}

	private function refreshBackgroundSkin():Void {
		var oldSkin = _currentBackgroundSkin;
		_currentBackgroundSkin = getCurrentBackgroundSkin();
		if (oldSkin == _currentBackgroundSkin) {
			return;
		}
		if (oldSkin != null) {
			if ((oldSkin is IProgrammaticSkin)) {
				cast(oldSkin, IProgrammaticSkin).uiContext = null;
			}
			removeChild(oldSkin);
		}
		if (_currentBackgroundSkin == null) {
			return;
		}
		addChildAt(_currentBackgroundSkin, 0);
		if ((_currentBackgroundSkin is IProgrammaticSkin)) {
			cast(_currentBackgroundSkin, IProgrammaticSkin).uiContext = this;
		}
	}

	private function getCurrentBackgroundSkin():DisplayObject {
		if (_debuggerStopped && debuggerStoppedBackgroundSkin != null) {
			return debuggerStoppedBackgroundSkin;
		}
		if (_textEditorHasFocus && _caretIndex != -1 && _selectionStartIndex == -1 && _selectionEndIndex == -1 && focusedBackgroundSkin != null) {
			return focusedBackgroundSkin;
		}
		return backgroundSkin;
	}

	private function refreshGutterWidth():Void {
		_gutterWidth = 0.0;
		if (_allowToggleBreakpoints && _currentBreakpointSkin != null) {
			if ((_currentBreakpointSkin is IValidating)) {
				cast(_currentBreakpointSkin, IValidating).validateNow();
			}
			_gutterWidth += _currentBreakpointSkin.width;
		}
		if (_showLineNumbers) {
			if (_gutterWidth > 0.0) {
				_gutterWidth += gutterGap;
			}
			if (lineNumberWidth != null) {
				_gutterWidth += lineNumberWidth;
			} else {
				_gutterWidth += _lineNumberTextField.width;
			}
		}
		_gutterWidth += gutterPaddingLeft + gutterPaddingRight;
	}

	private function refreshGutterBackgroundSkin():Void {
		var oldSkin = _currentGutterBackgroundSkin;
		_currentGutterBackgroundSkin = getCurrentGutterBackgroundSkin();
		if (oldSkin == _currentGutterBackgroundSkin) {
			return;
		}
		if (oldSkin != null) {
			if ((oldSkin is IProgrammaticSkin)) {
				cast(oldSkin, IProgrammaticSkin).uiContext = null;
			}
			removeChild(oldSkin);
		}
		if (_currentGutterBackgroundSkin == null) {
			return;
		}
		addChildAt(_currentGutterBackgroundSkin, getChildIndex(_lineNumberTextField));
		if ((_currentGutterBackgroundSkin is IProgrammaticSkin)) {
			cast(_currentGutterBackgroundSkin, IProgrammaticSkin).uiContext = this;
		}
	}

	private function getCurrentGutterBackgroundSkin():DisplayObject {
		if (_breakpoint && breakpointGutterBackgroundSkin != null) {
			return breakpointGutterBackgroundSkin;
		}
		return gutterBackgroundSkin;
	}

	private function refreshCaretSkin():Void {
		var caretColor = 0x000000;
		if (textStyles != null) {
			caretColor = textStyles.get(_defaultTextStyleContext).color;
		}
		if (_caretSkin == null) {
			_caretSkin = new RectangleSkin(SolidColor(caretColor));
			_caretSkin.width = 2.0;
			_caretSkin.height = 2.0;
			addChildAt(_caretSkin, getChildIndex(_mainTextField) + 1);
		}
		_caretSkin.mouseChildren = false;
		_caretSkin.mouseEnabled = false;
		_caretSkin.fill = SolidColor(caretColor);
	}

	private function refreshBreakpointSkin():Void {
		var oldSkin = _currentBreakpointSkin;
		_currentBreakpointSkin = getCurrentBreakpointSkin();
		if (oldSkin == _currentBreakpointSkin) {
			return;
		}
		if (oldSkin != null) {
			if ((oldSkin is IProgrammaticSkin)) {
				cast(oldSkin, IProgrammaticSkin).uiContext = null;
			}
			removeChild(oldSkin);
		}
		if (_currentBreakpointSkin == null) {
			return;
		}
		addChild(_currentBreakpointSkin);
		if ((_currentBreakpointSkin is IProgrammaticSkin)) {
			cast(_currentBreakpointSkin, IProgrammaticSkin).uiContext = this;
		}
	}

	private function getCurrentBreakpointSkin():DisplayObject {
		if (!breakpointVerified && unverifiedBreakpointSkin != null) {
			return unverifiedBreakpointSkin;
		}
		return breakpointSkin;
	}

	private function refreshSearchResultBackgroundSkins():Void {
		var skinsCount = _currentSearchResults.length;
		var difference = skinsCount - _searchResultBackgroundSkins.length;
		if (difference < 0) {
			for (i in 0... - difference) {
				var skin = _searchResultBackgroundSkins.pop();
				removeChild(skin);
			}
		}
		if (skinsCount == 0 || searchResultBackgroundSkinFactory == null) {
			return;
		}
		// display below the selected text, but if that doesn't exist, below the
		// text field instead
		var index = (_currentSelectedTextBackgroundSkin != null) ? getChildIndex(_currentSelectedTextBackgroundSkin) : getChildIndex(_mainTextField);
		for (i in 0...skinsCount) {
			var result = _currentSearchResults[i];

			var startBounds = _mainTextField.getCharBoundaries(result.startChar);
			var endBounds = _mainTextField.getCharBoundaries(result.endChar - 1);
			if (startBounds == null || endBounds == null) {
				continue;
			}
			var skin:DisplayObject = null;
			if (i < _searchResultBackgroundSkins.length) {
				skin = _searchResultBackgroundSkins[i];
			} else {
				skin = searchResultBackgroundSkinFactory();
				_searchResultBackgroundSkins[i] = skin;
				addChildAt(skin, index);
			}
			skin.x = _mainTextField.x + startBounds.x;
			skin.y = _mainTextField.y + startBounds.y;
			skin.width = endBounds.x + endBounds.width - startBounds.x;
			skin.height = endBounds.y + endBounds.height - startBounds.y;
		}
	}

	private function refreshSelectedTextBackgroundSkin():Void {
		var oldSkin = _currentSelectedTextBackgroundSkin;
		_currentSelectedTextBackgroundSkin = getCurrentSelectedTextBackgroundSkin();
		if (oldSkin == _currentSelectedTextBackgroundSkin) {
			return;
		}
		if (oldSkin != null) {
			if ((oldSkin is IProgrammaticSkin)) {
				cast(oldSkin, IProgrammaticSkin).uiContext = null;
			}
			removeChild(oldSkin);
		}
		if (_currentSelectedTextBackgroundSkin == null) {
			return;
		}
		// display directly below the text field
		var index = getChildIndex(_mainTextField);
		addChildAt(_currentSelectedTextBackgroundSkin, index);
		if ((_currentSelectedTextBackgroundSkin is IProgrammaticSkin)) {
			cast(_currentSelectedTextBackgroundSkin, IProgrammaticSkin).uiContext = this;
		}
	}

	private function getCurrentSelectedTextBackgroundSkin():DisplayObject {
		if (!_textEditorHasFocus && selectedTextUnfocusedBackgroundSkin != null) {
			return selectedTextUnfocusedBackgroundSkin;
		}
		return selectedTextBackgroundSkin;
	}

	private function refreshCaretPosition():Void {
		if (_caretSkin == null) {
			_caretX = 0.0;
			return;
		}
		if (!_textEditorHasFocus || _caretIndex == -1) {
			_caretSkin.visible = false;
			_caretX = 0.0;
			return;
		}
		var textLength = _text.length;
		var adjustedCaretIndex = _caretIndex;
		if (_caretIndex >= textLength) {
			if (textLength > 0) {
				adjustedCaretIndex = textLength - 1;
			} else {
				adjustedCaretIndex = 0;
			}
		}
		var renderedCaretIndex = textIndexToRenderedIndex(adjustedCaretIndex);
		var bounds = _mainTextField.getCharBoundaries(renderedCaretIndex);
		var caretX = _gutterWidth;
		var caretY = _mainTextField.y;
		var caretHeight = _mainTextField.height;
		if (bounds != null) {
			caretX += bounds.x;
			caretY += bounds.y;
			caretHeight = bounds.height;
			if (textLength > 0 && _caretIndex > adjustedCaretIndex) {
				if (_renderTabsWithSpaces && _text.charAt(adjustedCaretIndex) == "\t") {
					caretX += bounds.width * _tabWidth;
				} else {
					caretX += bounds.width;
				}
			}
		}
		_caretSkin.x = caretX;
		_caretSkin.y = caretY;
		_caretSkin.height = caretHeight;
		_caretSkin.visible = true;
		_caretX = _caretSkin.x;
	}

	private function refreshSelectionPosition():Void {
		if (_currentSelectedTextBackgroundSkin == null) {
			return;
		}
		if (_selectionStartIndex == -1 || _selectionEndIndex == -1) {
			_currentSelectedTextBackgroundSkin.visible = false;
			return;
		}
		var textLength = _text.length;

		var startIndex = (_selectionStartIndex < _selectionEndIndex) ? _selectionStartIndex : _selectionEndIndex;
		var adjustedStartIndex = startIndex;
		if (startIndex >= textLength) {
			if (textLength > 0) {
				adjustedStartIndex = textLength - 1;
			} else {
				adjustedStartIndex = 0;
			}
		}
		var endIndex = (_selectionStartIndex < _selectionEndIndex) ? _selectionEndIndex : _selectionStartIndex;
		var adjustedEndIndex = endIndex;
		if (endIndex >= textLength) {
			if (textLength > 0) {
				adjustedEndIndex = textLength - 1;
			} else {
				adjustedEndIndex = 0;
			}
		}

		var renderedStartIndex = textIndexToRenderedIndex(adjustedStartIndex);
		var renderedEndIndex = textIndexToRenderedIndex(adjustedEndIndex);
		var startBounds = _mainTextField.getCharBoundaries(renderedStartIndex);
		var endBounds = _mainTextField.getCharBoundaries(renderedEndIndex);
		if (startBounds == null || endBounds == null) {
			_currentSelectedTextBackgroundSkin.visible = false;
			return;
		}
		var startOffsetX = (textLength > 0 && startIndex > adjustedStartIndex) ? startBounds.width : 0.0;
		var endOffsetX = (textLength > 0 && endIndex > adjustedEndIndex) ? endBounds.width : 0.0;
		_currentSelectedTextBackgroundSkin.x = _gutterWidth + startBounds.x + startOffsetX;
		_currentSelectedTextBackgroundSkin.y = _mainTextField.y + startBounds.y;
		var selectionWidth = (endBounds.x + endOffsetX) - (startBounds.x + startOffsetX);
		if (textLength == 0 && renderedStartIndex == renderedEndIndex) {
			// ensure that the width isn't 0 so that something is visible
			selectionWidth = _mainTextField.width;
		}
		_currentSelectedTextBackgroundSkin.width = selectionWidth;
		_currentSelectedTextBackgroundSkin.height = startBounds.height;
		_currentSelectedTextBackgroundSkin.visible = true;
	}

	private function layoutContent():Void {
		#if flash
		// the flash target internally rounds to the nearest pixel when using
		// scrollRect, while other targets do not
		var gutterStartX = (parent == null || parent.scrollRect == null) ? _scrollX : Math.fround(_scrollX);
		#else
		var gutterStartX = _scrollX;
		#end
		if (_currentGutterBackgroundSkin != null) {
			_currentGutterBackgroundSkin.width = _gutterWidth;
			_currentGutterBackgroundSkin.height = actualHeight;
			_currentGutterBackgroundSkin.x = gutterStartX;
			_currentGutterBackgroundSkin.y = 0.0;
		}

		if (_currentBackgroundSkin != null) {
			_currentBackgroundSkin.height = actualHeight;
			if (_currentGutterBackgroundSkin != null) {
				_currentBackgroundSkin.width = actualWidth - _gutterWidth;
				_currentBackgroundSkin.x = _gutterWidth;
			} else {
				_currentBackgroundSkin.width = actualWidth;
				_currentBackgroundSkin.x = 0.0;
			}
			_currentBackgroundSkin.y = 0.0;
		}

		_lineNumberTextField.visible = _showLineNumbers;
		_lineNumberTextField.x = gutterStartX + _gutterWidth - _lineNumberTextField.width - gutterPaddingRight;
		_lineNumberTextField.y = (actualHeight - _lineNumberTextField.height) / 2.0;

		if (_currentBreakpointSkin != null) {
			_currentBreakpointSkin.visible = _allowToggleBreakpoints && _breakpoint;
			if ((_currentBreakpointSkin is IValidating)) {
				cast(_currentBreakpointSkin, IValidating).validateNow();
			}
			_currentBreakpointSkin.x = gutterStartX + gutterPaddingLeft;
			_currentBreakpointSkin.y = (actualHeight - _currentBreakpointSkin.height) / 2.0;
		}

		_mainTextField.x = _gutterWidth;
		_mainTextField.y = (actualHeight - _mainTextField.height) / 2.0;
		_mainTextField.width = actualWidth - _gutterWidth;
	}

	private function refreshCaretTimer():Void {
		_caretTimer.reset();
		if (_textEditorHasFocus && _caretIndex != -1) {
			_caretTimer.start();
		}
	}

	private function refreshCurrentSearchResults():Void {
		_currentSearchResults.resize(0);
		if (highlightAllFindResults && _searchResult != null) {
			for (result in _searchResult.results) {
				if (lineIndex < result.startLine || lineIndex > result.endLine) {
					continue;
				}
				_currentSearchResults.push(result);
			}
		}
	}

	private function textLineRenderer_mainTextField_rollOverHandler(event:MouseEvent):Void {
		_oldMouseCursor = Mouse.cursor;
		Mouse.cursor = MouseCursor.IBEAM;
	}

	private function textLineRenderer_mainTextField_rollOutHandler(event:MouseEvent):Void {
		Mouse.cursor = _oldMouseCursor;
		_oldMouseCursor = null;
	}

	private function textLineRenderer_mouseDownHandler(event:MouseEvent):Void {
		if (!_allowToggleBreakpoints) {
			return;
		}
		if (mouseX > _lineNumberTextField.x) {
			return;
		}
		dispatchEvent(new TextEditorLineEvent(TextEditorLineEvent.TOGGLE_BREAKPOINT, lineIndex));
	}

	private function textLineRenderer_caretTimer_timerHandler(event:TimerEvent):Void {
		if (_caretSkin == null) {
			return;
		}
		_caretSkin.visible = !_caretSkin.visible;
	}

	private function textLineRenderer_lineNumberTextField_mouseDownHandler(event:MouseEvent):Void {
		dispatchEvent(new TextEditorLineEvent(TextEditorLineEvent.SELECT_LINE, lineIndex));
	}
}
