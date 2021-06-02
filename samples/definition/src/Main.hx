import feathers.controls.Alert;
import feathers.controls.Application;
import feathers.controls.Label;
import feathers.layout.VerticalLayout;
import feathers.layout.VerticalLayoutData;
import moonshine.editor.text.lsp.LspTextEditor;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageActionEvent;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageRequestEvent;
import moonshine.editor.text.utils.TextUtil;
import moonshine.lsp.LocationLink;
import moonshine.lsp.Position;
import moonshine.lsp.Range;
import openfl.system.Capabilities;

class Main extends Application {
	public function new() {
		super();

		var appLayout = new VerticalLayout();
		appLayout.horizontalAlign = JUSTIFY;
		layout = appLayout;

		var instructions = new Label();
		instructions.text = 'Hold the ${StringTools.startsWith(Capabilities.version, "MAC ") ? "Command" : "Ctrl"} key and hover your mouse over either "MyClass" or "AnotherClass".';
		instructions.wordWrap = true;
		instructions.setPadding(10.0);
		addChild(instructions);

		var textEditor = new LspTextEditor();
		textEditor.text = "class MyClass extends AnotherClass {\n" + "\tpublic function new() {\n" + "\t\tsuper();\n" + "\t}\n" + "}\n";
		textEditor.layoutData = VerticalLayoutData.fill();
		addChild(textEditor);

		textEditor.addEventListener(LspTextEditorLanguageRequestEvent.REQUEST_DEFINITION, event -> {
			var line = textEditor.lines.get(event.params.position.line);
			var startIndex = TextUtil.startOfWord(line.text, event.params.position.character);
			var endIndex = TextUtil.endOfWord(line.text, event.params.position.character);
			var word = line.text.substring(startIndex, endIndex);
			if (word != "MyClass" && word != "AnotherClass") {
				event.callback(null);
				return;
			}
			var definitions:Array<LocationLink> = [
				new LocationLink('file:///path/to/${word}.hx', new Range(new Position(0, 0), new Position(0, 5)),
					new Range(new Position(0, 0), new Position(0, 5)))
			];
			event.callback(cast definitions);
		});
		textEditor.addEventListener(LspTextEditorLanguageActionEvent.OPEN_LINK, event -> {
			Alert.show(event.data[0].targetUri, "Link Clicked", ["OK"]);
		});
	}
}
