import moonshine.editor.text.lines.TextLineRenderer;
import feathers.skins.RectangleSkin;
import feathers.controls.Application;
import feathers.controls.Header;
import feathers.controls.LayoutGroup;
import feathers.controls.PopUpListView;
import feathers.data.ArrayCollection;
import feathers.layout.HorizontalLayout;
import feathers.layout.VerticalLayout;
import feathers.layout.VerticalLayoutData;
import moonshine.editor.text.TextEditor;
import moonshine.editor.text.syntax.format.HaxeSyntaxFormatBuilder;
import moonshine.editor.text.syntax.format.SyntaxColorSettings;
import moonshine.editor.text.syntax.format.SyntaxFontSettings;
import moonshine.editor.text.syntax.parser.HaxeLineParser;
import moonshine.editor.text.utils.AutoClosingPair;
import openfl.events.Event;

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

		_colorSchemePicker = new PopUpListView();
		_colorSchemePicker.itemToText = item -> item.name;
		_colorSchemePicker.dataProvider = new ArrayCollection([
			{name: "Light", colors: SyntaxColorSettings.defaultLight()},
			{name: "Dark", colors: SyntaxColorSettings.defaultDark()},
			{name: "Monokai", colors: SyntaxColorSettings.monokai()},
		]);
		_colorSchemePicker.addEventListener(Event.CHANGE, colorSchemePicker_changeHandler);
		headerToolBar.addChild(_colorSchemePicker);

		_textEditor = new TextEditor();
		_textEditor.layoutData = new VerticalLayoutData(100.0, 100.0);
		_textEditor.text = "package com.example;\n\nimport openfl.display.Sprite;\n\n/**\n\tHello world!\n**/\nclass HelloWorld extends Sprite {\n\tpublic function new() {\n\t\tsuper();\n\t}\n}\n";
		_textEditor.brackets = [["{", "}"], ["[", "]"], ["(", ")"]];
		_textEditor.autoClosingPairs = [
			new AutoClosingPair("{", "}"),
			new AutoClosingPair("[", "]"),
			new AutoClosingPair("(", ")"),
			new AutoClosingPair("'", "'"),
			new AutoClosingPair("\"", "\"")
		];
		_textEditor.lineComment = "//";
		_textEditor.blockComment = ["/*", "*/"];
		refreshSyntaxColorSettings();
		addChild(_textEditor);
	}

	private var _header:Header;
	private var _textEditor:TextEditor;
	private var _colorSchemePicker:PopUpListView;

	private var _colorSettings:SyntaxColorSettings = SyntaxColorSettings.defaultLight();
	private var _fontSettings:SyntaxFontSettings = new SyntaxFontSettings();

	private function refreshSyntaxColorSettings():Void {
		var colorSettings = cast(_colorSchemePicker.selectedItem.colors, SyntaxColorSettings);
		var formatBuilder = new HaxeSyntaxFormatBuilder();
		formatBuilder.setFontSettings(new SyntaxFontSettings());
		formatBuilder.setColorSettings(colorSettings);
		var formats = formatBuilder.build();
		_textEditor.setParserAndTextStyles(new HaxeLineParser(), formats);

		_textEditor.backgroundSkin = new RectangleSkin(SolidColor(colorSettings.backgroundColor));
		_textEditor.textLineRendererFactory = () -> {
			var textLineRenderer = new TextLineRenderer();
			textLineRenderer.backgroundSkin = new RectangleSkin(SolidColor(colorSettings.backgroundColor));
			textLineRenderer.gutterBackgroundSkin = new RectangleSkin(SolidColor(colorSettings.backgroundColor));
			textLineRenderer.selectedTextBackgroundSkin = new RectangleSkin(SolidColor(colorSettings.selectionBackgroundColor,
				colorSettings.selectionBackgroundAlpha));
			textLineRenderer.selectedTextBackgroundSkin = new RectangleSkin(SolidColor(colorSettings.selectionUnfocusedBackgroundColor,
				colorSettings.selectionUnfocusedBackgroundAlpha));
			textLineRenderer.focusedBackgroundSkin = new RectangleSkin(SolidColor(colorSettings.focusedLineBackgroundColor));
			textLineRenderer.debuggerStoppedBackgroundSkin = new RectangleSkin(SolidColor(colorSettings.backgroundColor));
			textLineRenderer.searchResultBackgroundSkinFactory = () -> {
				return new RectangleSkin(SolidColor(colorSettings.searchResultBackgroundColor));
			}
			return textLineRenderer;
		}
	}

	private function colorSchemePicker_changeHandler(event:Event):Void {
		refreshSyntaxColorSettings();
	}
}
