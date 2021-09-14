import feathers.controls.Alert;
import feathers.controls.Application;
import feathers.controls.Button;
import feathers.controls.Form;
import feathers.controls.FormItem;
import feathers.controls.Header;
import feathers.controls.Label;
import feathers.controls.LayoutGroup;
import feathers.controls.TextInput;
import feathers.events.TriggerEvent;
import feathers.layout.HorizontalLayout;
import feathers.layout.HorizontalLayoutData;
import feathers.layout.VerticalLayout;
import feathers.layout.VerticalLayoutData;
import moonshine.editor.text.TextEditor;
import moonshine.editor.text.TextEditorSearchResult;
import moonshine.editor.text.events.TextEditorChangeEvent;
import moonshine.editor.text.events.TextEditorEvent;
import moonshine.editor.text.syntax.format.AS3SyntaxFormatBuilder;
import moonshine.editor.text.syntax.format.CSSSyntaxFormatBuilder;
import moonshine.editor.text.syntax.format.GroovySyntaxFormatBuilder;
import moonshine.editor.text.syntax.format.HTMLSyntaxFormatBuilder;
import moonshine.editor.text.syntax.format.HaxeSyntaxFormatBuilder;
import moonshine.editor.text.syntax.format.JSSyntaxFormatBuilder;
import moonshine.editor.text.syntax.format.JavaSyntaxFormatBuilder;
import moonshine.editor.text.syntax.format.MXMLSyntaxFormatBuilder;
import moonshine.editor.text.syntax.format.PlainTextFormatBuilder;
import moonshine.editor.text.syntax.format.PythonSyntaxFormatBuilder;
import moonshine.editor.text.syntax.format.SyntaxColorSettings;
import moonshine.editor.text.syntax.format.SyntaxFontSettings;
import moonshine.editor.text.syntax.format.XMLSyntaxFormatBuilder;
import moonshine.editor.text.syntax.parser.AS3LineParser;
import moonshine.editor.text.syntax.parser.CSSLineParser;
import moonshine.editor.text.syntax.parser.GroovyLineParser;
import moonshine.editor.text.syntax.parser.HTMLLineParser;
import moonshine.editor.text.syntax.parser.HaxeLineParser;
import moonshine.editor.text.syntax.parser.ILineParser;
import moonshine.editor.text.syntax.parser.JSLineParser;
import moonshine.editor.text.syntax.parser.JavaLineParser;
import moonshine.editor.text.syntax.parser.MXMLLineParser;
import moonshine.editor.text.syntax.parser.PlainTextLineParser;
import moonshine.editor.text.syntax.parser.PythonLineParser;
import moonshine.editor.text.syntax.parser.XMLLineParser;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
#if (openfl > "9.1.0" && (air || sys))
import openfl.filesystem.File;
import openfl.filesystem.FileMode;
import openfl.filesystem.FileStream;
#elseif (air)
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
#end

class Main extends Application {
	public function new() {
		super();

		var appLayout = new VerticalLayout();
		layout = appLayout;

		_header = new Header();
		_header.layoutData = new VerticalLayoutData(100.0);
		addChild(_header);

		var headerToolBar = new LayoutGroup();
		var toolBarLayout = new HorizontalLayout();
		toolBarLayout.gap = 4.0;
		headerToolBar.layout = toolBarLayout;
		_header.leftView = headerToolBar;

		var newFileButton = new Button();
		newFileButton.text = "New";
		newFileButton.addEventListener(TriggerEvent.TRIGGER, newFileButton_triggerHandler);
		headerToolBar.addChild(newFileButton);
		var openFileButton = new Button();
		openFileButton.text = "Open";
		openFileButton.addEventListener(TriggerEvent.TRIGGER, openFileButton_triggerHandler);
		headerToolBar.addChild(openFileButton);
		var saveFileButton = new Button();
		saveFileButton.text = "Save";
		saveFileButton.addEventListener(TriggerEvent.TRIGGER, saveFileButton_triggerHandler);
		headerToolBar.addChild(saveFileButton);

		_textEditor = new TextEditor();
		_textEditor.layoutData = new VerticalLayoutData(100.0, 100.0);
		_textEditor.addEventListener(TextEditorChangeEvent.TEXT_CHANGE, event -> {
			_findResult = null;
			refreshFileNameOrEdited();
			refreshStatus();
		});
		_textEditor.addEventListener(TextEditorEvent.SELECTION_CHANGE, event -> {
			_findResult = null;
			refreshStatus();
		});
		addChild(_textEditor);

		_findReplaceToolBar = new LayoutGroup();
		_findReplaceToolBar.variant = LayoutGroup.VARIANT_TOOL_BAR;
		_findReplaceToolBar.layoutData = new VerticalLayoutData(100.0);
		var findReplaceToolBarLayout = new VerticalLayout();
		findReplaceToolBarLayout.paddingTop = 4.0;
		findReplaceToolBarLayout.paddingRight = 10.0;
		findReplaceToolBarLayout.paddingBottom = 4.0;
		findReplaceToolBarLayout.paddingLeft = 10.0;
		findReplaceToolBarLayout.gap = 4.0;
		findReplaceToolBarLayout.horizontalAlign = JUSTIFY;
		_findReplaceToolBar.layout = findReplaceToolBarLayout;
		_findReplaceToolBar.visible = false;
		_findReplaceToolBar.includeInLayout = false;
		addChild(_findReplaceToolBar);

		_findReplaceForm = new Form();
		_findReplaceToolBar.addChild(_findReplaceForm);
		_findItem = new FormItem();
		_findItem.text = "Find:";
		_findItem.textPosition = LEFT;
		_findItem.horizontalAlign = JUSTIFY;
		_findReplaceForm.addChild(_findItem);
		var findContainer = new LayoutGroup();
		var findContainerLayout = new HorizontalLayout();
		findContainerLayout.gap = 4.0;
		findContainerLayout.verticalAlign = MIDDLE;
		findContainer.layout = findContainerLayout;
		_findItem.content = findContainer;
		_findInput = new TextInput();
		_findInput.layoutData = new HorizontalLayoutData(100.0);
		_findInput.addEventListener(KeyboardEvent.KEY_DOWN, findInput_keyDownHandler);
		_findInput.addEventListener(Event.CHANGE, findInput_changeHandler);
		findContainer.addChild(_findInput);
		var findNextButton = new Button();
		findNextButton.text = "Find";
		findNextButton.addEventListener(TriggerEvent.TRIGGER, findNextButton_triggerHandler);
		findContainer.addChild(findNextButton);
		var findPrevButton = new Button();
		findPrevButton.text = "Find Previous";
		findPrevButton.addEventListener(TriggerEvent.TRIGGER, findPrevButton_triggerHandler);
		findContainer.addChild(findPrevButton);

		_replaceItem = new FormItem();
		_replaceItem.text = "Replace:";
		_replaceItem.textPosition = LEFT;
		_replaceItem.horizontalAlign = JUSTIFY;
		_findReplaceForm.addChild(_replaceItem);
		var replaceContainer = new LayoutGroup();
		var replaceContainerLayout = new HorizontalLayout();
		replaceContainerLayout.gap = 4.0;
		replaceContainerLayout.verticalAlign = MIDDLE;
		replaceContainer.layout = replaceContainerLayout;
		_replaceItem.content = replaceContainer;
		_replaceInput = new TextInput();
		_replaceInput.layoutData = new HorizontalLayoutData(100.0);
		_replaceInput.addEventListener(KeyboardEvent.KEY_DOWN, replaceInput_keyDownHandler);
		replaceContainer.addChild(_replaceInput);
		var replaceOneButton = new Button();
		replaceOneButton.text = "Replace";
		replaceOneButton.addEventListener(TriggerEvent.TRIGGER, replaceOneButton_triggerHandler);
		replaceContainer.addChild(replaceOneButton);
		var replaceAllButton = new Button();
		replaceAllButton.text = "Replace All";
		replaceAllButton.addEventListener(TriggerEvent.TRIGGER, replaceAllButton_triggerHandler);
		replaceContainer.addChild(replaceAllButton);

		var footerToolBar = new LayoutGroup();
		footerToolBar.variant = LayoutGroup.VARIANT_TOOL_BAR;
		footerToolBar.layoutData = new VerticalLayoutData(100.0);
		var footerLayout = new HorizontalLayout();
		footerLayout.horizontalAlign = LEFT;
		footerLayout.verticalAlign = MIDDLE;
		footerLayout.paddingTop = 4.0;
		footerLayout.paddingRight = 10.0;
		footerLayout.paddingBottom = 4.0;
		footerLayout.paddingLeft = 10.0;
		footerLayout.gap = 12.0;
		footerToolBar.layout = footerLayout;
		addChild(footerToolBar);

		_statusLabel = new Label();
		footerToolBar.addChild(_statusLabel);

		_lineEndingLabel = new Label();
		footerToolBar.addChild(_lineEndingLabel);

		_syntaxNameLabel = new Label();
		footerToolBar.addChild(_syntaxNameLabel);

		var spacer = new LayoutGroup();
		spacer.layoutData = new HorizontalLayoutData(100.0);
		footerToolBar.addChild(spacer);

		stage.addEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);

		newFile();
	}

	private var _parser:ILineParser;
	private var _header:Header;
	private var _textEditor:TextEditor;
	private var _statusLabel:Label;
	private var _lineEndingLabel:Label;
	private var _syntaxNameLabel:Label;
	private var _findReplaceToolBar:LayoutGroup;
	private var _findReplaceForm:Form;
	private var _findItem:FormItem;
	private var _replaceItem:FormItem;
	private var _findInput:TextInput;
	private var _replaceInput:TextInput;

	private var _syntaxName:String;

	private var _openedFile:File;

	private var _findResult:TextEditorSearchResult;

	private var _colorSettings:SyntaxColorSettings = new SyntaxColorSettings();
	private var _fontSettings:SyntaxFontSettings = new SyntaxFontSettings();

	private function refreshSyntaxName():Void {
		_syntaxNameLabel.text = (_syntaxName != null) ? _syntaxName : "Plain Text";
	}

	private function refreshStatus():Void {
		if (_findResult != null) {
			if (_findResult.results.length == 0) {
				_statusLabel.text = "No Matches";
			} else {
				_statusLabel.text = '${_findResult.selectedIndex + 1} of ${_findResult.results.length} matches';
			}
		} else {
			_statusLabel.text = 'Line ${_textEditor.caretLineIndex + 1}, Column ${_textEditor.caretCharIndex + 1}';
		}
	}

	private function refreshFileNameOrEdited():Void {
		var headerText = (_openedFile != null) ? _openedFile.name : "Untitled";
		if (_textEditor.edited) {
			headerText = "• " + headerText;
		}
		_header.text = headerText;
	}

	private function refreshLineEnding():Void {
		_lineEndingLabel.text = switch (_textEditor.lineDelimiter) {
			case "\r\n": "Windows";
			case "\r": "MacOS";
			case "\n": "Unix";
			default: "Unknown";
		}
	}

	private function newFileButton_triggerHandler(event:TriggerEvent):Void {
		newFile();
	}

	private function openFileButton_triggerHandler(event:TriggerEvent):Void {
		#if (air || (openfl > "9.1.0" && sys))
		var file = new File();
		file.addEventListener(Event.SELECT, event -> {
			openFile(file);
		});
		file.browseForOpen("Open File");
		#else
		feathers.controls.Alert.show("Open is not supported on this platform", "Error", ["OK"]);
		#end
	}

	#if (air || (openfl > "9.1.0" && sys))
	private function saveFile(file:File):Void {
		_openedFile = file;
		var stream = new FileStream();
		try {
			stream.open(_openedFile, FileMode.WRITE);
			stream.writeUTFBytes(_textEditor.text);
			stream.close();
		} catch (e:Any) {
			Alert.show("File could not be saved: " + _openedFile.name, "Error", ["OK"]);
			stream.close();
			return;
		}
		stream.close();

		_textEditor.save();
		refreshFileNameOrEdited();
	}
	#end

	private function newFile(?extension:String):Void {
		_openedFile = null;
		_textEditor.text = "";
		_findReplaceToolBar.visible = false;
		_findReplaceToolBar.includeInLayout = false;
		_findResult = null;
		var brackets:Array<Array<String>> = null;
		var formats:Map<Int, TextFormat> = [];
		var lineComment:String = null;
		switch (extension) {
			case "hx":
				_syntaxName = "Haxe";
				_parser = new HaxeLineParser();
				var formatBuilder = new HaxeSyntaxFormatBuilder();
				formatBuilder.setFontSettings(_fontSettings);
				formatBuilder.setColorSettings(_colorSettings);
				formats = formatBuilder.build();
				brackets = [["{", "}"], ["[", "]"], ["(", ")"]];
				lineComment = "//";
			case "as":
				_syntaxName = "ActionScript";
				_parser = new AS3LineParser();
				var formatBuilder = new AS3SyntaxFormatBuilder();
				formatBuilder.setFontSettings(_fontSettings);
				formatBuilder.setColorSettings(_colorSettings);
				formats = formatBuilder.build();
				brackets = [["{", "}"], ["[", "]"], ["(", ")"]];
				lineComment = "//";
			case "js" | "json":
				_syntaxName = (extension == "json") ? "JSON" : "JavaScript";
				_parser = new JSLineParser();
				var formatBuilder = new JSSyntaxFormatBuilder();
				formatBuilder.setFontSettings(_fontSettings);
				formatBuilder.setColorSettings(_colorSettings);
				formats = formatBuilder.build();
				brackets = [["{", "}"], ["[", "]"], ["(", ")"]];
				if (extension != "json") {
					lineComment = "//";
				}
			case "py":
				_syntaxName = "Python";
				_parser = new PythonLineParser();
				var formatBuilder = new PythonSyntaxFormatBuilder();
				formatBuilder.setFontSettings(_fontSettings);
				formatBuilder.setColorSettings(_colorSettings);
				formats = formatBuilder.build();
				brackets = [["{", "}"], ["[", "]"], ["(", ")"]];
				lineComment = "#";
			case "java":
				_syntaxName = "Java";
				_parser = new JavaLineParser();
				var formatBuilder = new JavaSyntaxFormatBuilder();
				formatBuilder.setFontSettings(_fontSettings);
				formatBuilder.setColorSettings(_colorSettings);
				formats = formatBuilder.build();
				brackets = [["{", "}"], ["[", "]"], ["(", ")"]];
				lineComment = "//";
			case "groovy" | "gradle":
				_syntaxName = "Groovy";
				_parser = new GroovyLineParser();
				var formatBuilder = new GroovySyntaxFormatBuilder();
				formatBuilder.setFontSettings(_fontSettings);
				formatBuilder.setColorSettings(_colorSettings);
				formats = formatBuilder.build();
				brackets = [["{", "}"], ["[", "]"], ["(", ")"]];
				lineComment = "//";
			case "css":
				_syntaxName = "CSS";
				_parser = new CSSLineParser();
				var formatBuilder = new CSSSyntaxFormatBuilder();
				formatBuilder.setFontSettings(_fontSettings);
				formatBuilder.setColorSettings(_colorSettings);
				formats = formatBuilder.build();
				brackets = [["{", "}"], ["[", "]"], ["(", ")"]];
			case "xml":
				_syntaxName = "XML";
				_parser = new XMLLineParser();
				var formatBuilder = new XMLSyntaxFormatBuilder();
				formatBuilder.setFontSettings(_fontSettings);
				formatBuilder.setColorSettings(_colorSettings);
				formats = formatBuilder.build();
				brackets = [["<!--", "-->"], ["<", ">"], ["{", "}"], ["(", ")"]];
			case "mxml":
				_syntaxName = "MXML";
				_parser = new MXMLLineParser();
				var formatBuilder = new MXMLSyntaxFormatBuilder();
				formatBuilder.setFontSettings(_fontSettings);
				formatBuilder.setColorSettings(_colorSettings);
				formats = formatBuilder.build();
				brackets = [["<!--", "-->"], ["<", ">"], ["{", "}"], ["(", ")"]];
			case "html" | "htm":
				_syntaxName = "HTML";
				_parser = new HTMLLineParser();
				var formatBuilder = new HTMLSyntaxFormatBuilder();
				formatBuilder.setFontSettings(_fontSettings);
				formatBuilder.setColorSettings(_colorSettings);
				formats = formatBuilder.build();
				brackets = [["<!--", "-->"], ["<", ">"], ["{", "}"], ["(", ")"]];
			default:
				_syntaxName = null;
				_parser = new PlainTextLineParser();
				var formatBuilder = new PlainTextFormatBuilder();
				formatBuilder.setFontSettings(_fontSettings);
				formatBuilder.setColorSettings(_colorSettings);
				formats = formatBuilder.build();
		}
		_textEditor.brackets = brackets;
		_textEditor.lineComment = lineComment;
		_textEditor.setParserAndTextStyles(_parser, formats);

		refreshFileNameOrEdited();
		refreshStatus();
		refreshLineEnding();
		refreshSyntaxName();
	}

	#if (air || (openfl > "9.1.0" && sys))
	private function openFile(file:File):Void {
		newFile(file.extension);

		_openedFile = file;
		var stream = new FileStream();
		stream.open(file, FileMode.READ);
		var text = stream.readUTFBytes(stream.bytesAvailable);
		stream.close();

		_textEditor.text = text;

		refreshFileNameOrEdited();
		refreshStatus();
		refreshLineEnding();
		refreshSyntaxName();
	}
	#end

	private function saveFileButton_triggerHandler(event:TriggerEvent):Void {
		#if (air || (openfl > "9.1.0" && sys))
		if (_openedFile == null) {
			var file = new File();
			file.addEventListener(Event.SELECT, event -> {
				saveFile(file);
			});
			file.browseForSave("Save File As");
			return;
		}
		saveFile(_openedFile);
		#else
		feathers.controls.Alert.show("Save is not supported on this platform", "Error", ["OK"]);
		#end
	}

	private function refreshFind():Void {
		_findResult = _textEditor.find(_findInput.text, false);
		refreshStatus();
	}

	private function findInput_changeHandler(event:Event):Void {
		refreshFind();
	}

	private function findInput_keyDownHandler(event:KeyboardEvent):Void {
		if (event.keyCode != Keyboard.ENTER) {
			return;
		}
		_findResult = _textEditor.findNext(event.shiftKey);
		refreshStatus();
	}

	private function findNextButton_triggerHandler(event:TriggerEvent):Void {
		_findResult = _textEditor.findNext(false);
		refreshStatus();
	}

	private function findPrevButton_triggerHandler(event:TriggerEvent):Void {
		_findResult = _textEditor.findNext(true);
		refreshStatus();
	}

	private function replaceInput_keyDownHandler(event:KeyboardEvent):Void {
		if (event.keyCode != Keyboard.ENTER) {
			return;
		}
		_findResult = _textEditor.replaceOne(_replaceInput.text);
		refreshStatus();
	}

	private function replaceOneButton_triggerHandler(event:TriggerEvent):Void {
		_findResult = _textEditor.replaceOne(_replaceInput.text);
		refreshStatus();
	}

	private function replaceAllButton_triggerHandler(event:TriggerEvent):Void {
		_findResult = _textEditor.replaceAll(_replaceInput.text);
		refreshStatus();
	}

	private function stage_keyDownHandler(event:KeyboardEvent):Void {
		if (event.isDefaultPrevented()) {
			return;
		}
		if (event.keyCode == Keyboard.ESCAPE && !event.ctrlKey && !event.shiftKey && !event.altKey && _findReplaceToolBar.visible) {
			event.preventDefault();
			_findReplaceToolBar.visible = false;
			_findReplaceToolBar.includeInLayout = false;
			_findResult = null;
			refreshStatus();
			focusManager.focus = _textEditor;
		} else if (event.keyCode == Keyboard.F && event.ctrlKey && !event.shiftKey) {
			event.preventDefault();
			_findReplaceToolBar.visible = true;
			_findReplaceToolBar.includeInLayout = true;
			if (event.altKey) {
				_replaceItem.visible = true;
				_replaceItem.includeInLayout = true;
			} else {
				_replaceItem.visible = false;
				_replaceItem.includeInLayout = false;
			}
			if (_findReplaceToolBar.visible) {
				focusManager.focus = _findInput;
				if (_findInput.text.length > 0) {
					_findResult = _textEditor.find(_findInput.text, false);
				}
			}
			refreshStatus();
		}
	}
}
