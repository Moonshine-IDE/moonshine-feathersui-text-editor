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

@:styleContext
class TextLineRenderer extends FeathersControl {
	public function new() {
		TextLineRendererStyles.initialize();

		super();

		_caretTimer = new Timer(600.0);
		_caretTimer.addEventListener(TimerEvent.TIMER, textLineRenderer_caretTimer_timerHandler);

		addEventListener(MouseEvent.ROLL_OVER, textLineRenderer_rollOverHandler);
		addEventListener(MouseEvent.ROLL_OUT, textLineRenderer_rollOutHandler);
		addEventListener(MouseEvent.MOUSE_DOWN, textLineRenderer_mouseDownHandler);
	}

	private var _oldMouseCursor:String;

	private var _mainTextField:TextField;
	private var _lineNumberTextField:TextField;

	private var _tabToSpaceOffsets:Array<Int> = [];
	private var _spaceToTabOffsets:Array<Int> = [];
	private var _renderedText:String;

	private var _text:String;

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

	private var _numLines:Int = -1;

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

	@:flash.property
	public var caretX(get, never):Float;

	private function get_caretX():Float {
		return _caretX;
	}

	private var _gutterWidth:Float = 0.0;

	public var gutterWidth(get, never):Float;

	private function get_gutterWidth():Float {
		return _gutterWidth;
	}

	private var _lineNumberWidth:Null<Float> = null;

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

	@:style
	public var embedFonts:Bool = false;

	@:style
	public var lineNumberTextFormat:TextFormat = null;

	private var _currentGutterBackgroundSkin:DisplayObject;

	@:style
	public var gutterBackgroundSkin:DisplayObject = null;

	@:style
	public var breakpointGutterBackgroundSkin:DisplayObject = null;

	private var _currentBackgroundSkin:DisplayObject;

	@:style
	public var backgroundSkin:DisplayObject = null;

	@:style
	public var focusedBackgroundSkin:DisplayObject = null;

	@:style
	public var debuggerStoppedBackgroundSkin:DisplayObject = null;

	private var _currentSelectedTextBackgroundSkin:DisplayObject;

	@:style
	public var selectedTextBackgroundSkin:DisplayObject = null;

	@:style
	public var selectedTextUnfocusedBackgroundSkin:DisplayObject = null;

	@:style
	public var searchResultBackgroundSkinFactory:() -> DisplayObject = null;

	@:style
	public var textStyles:Map<Int, TextFormat> = null;

	private var _defaultTextStyleContext:Int = 0x0;

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

	@:style
	public var breakpointSkin:DisplayObject = null;

	@:style
	public var unverifiedBreakpointSkin:DisplayObject = null;

	@:style
	public var gutterGap:Float = 0.0;

	@:style
	public var gutterPaddingLeft:Float = 0.0;

	@:style
	public var gutterPaddingRight:Float = 0.0;

	private var _scrollX:Float = 0.0;

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

	private var _searchResultsBackgroundSkins:Array<DisplayObject> = [];

	private var _searchResults:Array<TextEditorSearchResult> = null;

	@:flash.property
	public var searchResults(get, set):Array<TextEditorSearchResult>;

	private function get_searchResults():Array<TextEditorSearchResult> {
		return _searchResults;
	}

	private function set_searchResults(value:Array<TextEditorSearchResult>):Array<TextEditorSearchResult> {
		if (_searchResults == value) {
			return _searchResults;
		}
		_searchResults = value;
		setInvalid(STATE);
		return _searchResults;
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
			_mainTextField.mouseEnabled = false;
			_mainTextField.mouseWheelEnabled = false;
			addChild(_mainTextField);
		}
		if (_lineNumberTextField == null) {
			_lineNumberTextField = new TextField();
			_lineNumberTextField.autoSize = LEFT;
			_lineNumberTextField.selectable = false;
			_lineNumberTextField.mouseEnabled = false;
			_lineNumberTextField.mouseWheelEnabled = false;
			addChild(_lineNumberTextField);
		}
	}

	override private function update():Void {
		var dataInvalid = isInvalid(DATA);
		var scrollInvalid = isInvalid(SCROLL);
		var stateInvalid = isInvalid(STATE);
		var stylesInvalid = isInvalid(STYLES);

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

		if (dataInvalid) {
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

		if (stateInvalid || stylesInvalid) {
			refreshSearchResultsBackgroundSkins();
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
		var minNumChars = Std.int(Math.max(3, Std.string(numLines).length));
		lineNumberText = StringTools.lpad(lineNumberText, "\u00A0", minNumChars);
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
		var i = 0;
		do {
			var current = 0;
			var next = lineTextLength;
			var style = _defaultTextStyleContext;
			if (i < _styleRanges.length) {
				current = _styleRanges[i];
				i++;
				style = _styleRanges[i];
				i++;
				next = lineTextLength;
				if (i < styleRanges.length) {
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
			if (_linkStartChar != -1 && _linkStartChar >= current && _linkStartChar < next) {
				var linkStart = textIndexToRenderedIndex(_linkStartChar);
				var linkEnd = textIndexToRenderedIndex(_linkEndChar);
				current = textIndexToRenderedIndex(current);
				next = textIndexToRenderedIndex(next);
				var linkFormat = TextFormatUtil.clone(format);
				linkFormat.underline = true;
				if (linkStart > current) {
					_mainTextField.setTextFormat(format, current, linkStart);
				}
				_mainTextField.setTextFormat(linkFormat, linkStart, linkEnd);
				if (linkEnd < next) {
					_mainTextField.setTextFormat(format, linkEnd, next);
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
		} while (i < _styleRanges.length);
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
		if (_textEditorHasFocus && _caretIndex != -1 && focusedBackgroundSkin != null) {
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
			textStyles.get(_defaultTextStyleContext).color;
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

	private function refreshSearchResultsBackgroundSkins():Void {
		for (skin in _searchResultsBackgroundSkins) {
			removeChild(skin);
		}
		_searchResultsBackgroundSkins.resize(0);
		if (_searchResults == null || _searchResults.length == 0 || searchResultBackgroundSkinFactory == null) {
			return;
		}
		// display below the selected text, but if that doesn't exist, below the
		// text field instead
		var index = (_currentSelectedTextBackgroundSkin != null) ? getChildIndex(_currentSelectedTextBackgroundSkin) : getChildIndex(_mainTextField);
		for (result in _searchResults) {
			var skin = searchResultBackgroundSkinFactory();
			var startBounds = _mainTextField.getCharBoundaries(result.startCharIndex);
			var endBounds = _mainTextField.getCharBoundaries(result.endCharIndex - 1);
			skin.x = _mainTextField.x + startBounds.x;
			skin.y = _mainTextField.y + startBounds.y;
			skin.width = endBounds.x + endBounds.width - startBounds.x;
			skin.height = endBounds.y + endBounds.height - startBounds.y;
			addChildAt(skin, index);
			_searchResultsBackgroundSkins.push(skin);
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
		var offsetX = 0.0;
		if (textLength > 0 && _caretIndex > adjustedCaretIndex) {
			if (_renderTabsWithSpaces && _text.charAt(adjustedCaretIndex) == "\t") {
				offsetX = bounds.width * _tabWidth;
			} else {
				offsetX = bounds.width;
			}
		}
		_caretSkin.x = _gutterWidth + bounds.x + offsetX;
		_caretSkin.y = _mainTextField.y + bounds.y;
		_caretSkin.height = bounds.height;
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
		var startOffsetX = (textLength > 0 && startIndex > adjustedStartIndex) ? startBounds.width : 0.0;
		var endBounds = _mainTextField.getCharBoundaries(renderedEndIndex);
		var endOffsetX = (textLength > 0 && endIndex > adjustedEndIndex) ? endBounds.width : 0.0;
		_currentSelectedTextBackgroundSkin.x = _gutterWidth + startBounds.x + startOffsetX;
		_currentSelectedTextBackgroundSkin.y = _mainTextField.y + startBounds.y;
		_currentSelectedTextBackgroundSkin.width = (endBounds.x + endOffsetX) - (startBounds.x + startOffsetX);
		_currentSelectedTextBackgroundSkin.height = startBounds.height;
		_currentSelectedTextBackgroundSkin.visible = true;
	}

	private function layoutContent():Void {
		if (_currentGutterBackgroundSkin != null) {
			_currentGutterBackgroundSkin.width = _gutterWidth;
			_currentGutterBackgroundSkin.height = actualHeight;
			_currentGutterBackgroundSkin.x = Math.round(_scrollX);
			_currentGutterBackgroundSkin.y = 0.0;
		}

		if (_currentBackgroundSkin != null) {
			_currentBackgroundSkin.width = actualWidth - _gutterWidth;
			_currentBackgroundSkin.height = actualHeight;
			_currentBackgroundSkin.x = _gutterWidth;
			_currentBackgroundSkin.y = 0.0;
		}

		_lineNumberTextField.visible = _showLineNumbers;
		_lineNumberTextField.x = _currentGutterBackgroundSkin.x + _gutterWidth - _lineNumberTextField.width - gutterPaddingRight;
		_lineNumberTextField.y = (actualHeight - _lineNumberTextField.height) / 2.0;

		if (_currentBreakpointSkin != null) {
			_currentBreakpointSkin.visible = _allowToggleBreakpoints && _breakpoint;
			if ((_currentBreakpointSkin is IValidating)) {
				cast(_currentBreakpointSkin, IValidating).validateNow();
			}
			_currentBreakpointSkin.x = _currentGutterBackgroundSkin.x + gutterPaddingLeft;
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

	private function textLineRenderer_rollOverHandler(event:MouseEvent):Void {
		_oldMouseCursor = Mouse.cursor;
		Mouse.cursor = MouseCursor.IBEAM;
	}

	private function textLineRenderer_rollOutHandler(event:MouseEvent):Void {
		Mouse.cursor = _oldMouseCursor;
		_oldMouseCursor = null;
	}

	private function textLineRenderer_mouseDownHandler(event:MouseEvent):Void {
		if (!_allowToggleBreakpoints) {
			return;
		}
		if (mouseX > _gutterWidth) {
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
}
