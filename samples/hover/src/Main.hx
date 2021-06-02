import feathers.controls.Application;
import feathers.controls.Label;
import feathers.layout.VerticalLayout;
import feathers.layout.VerticalLayoutData;
import moonshine.editor.text.lsp.LspTextEditor;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageRequestEvent;
import moonshine.lsp.Hover;

class Main extends Application {
	public function new() {
		super();

		var appLayout = new VerticalLayout();
		appLayout.horizontalAlign = JUSTIFY;
		layout = appLayout;

		var instructions = new Label();
		instructions.text = 'Hover your mouse over the text in the editor.';
		instructions.wordWrap = true;
		instructions.setPadding(10.0);
		addChild(instructions);

		var textEditor = new LspTextEditor();
		textEditor.text = "class MyClass extends AnotherClass {\n" + "\tpublic function new() {\n" + "\t\tsuper();\n" + "\t}\n" + "}\n";
		textEditor.layoutData = VerticalLayoutData.fill();
		addChild(textEditor);

		textEditor.addEventListener(LspTextEditorLanguageRequestEvent.REQUEST_HOVER, event -> {
			var position = event.params.position;
			var line = textEditor.lines.get(position.line);
			var char = line.text.charAt(position.character);
			if (~/[\W]/.match(char)) {
				// not inside a word
				event.callback(null);
				return;
			}

			var findPrevNonWord = ~/[\W]/;
			var startChar = 0;
			while (findPrevNonWord.matchSub(line.text, startChar, position.character - startChar)) {
				startChar = findPrevNonWord.matchedPos().pos + 1;
			}
			var endChar = line.text.length;
			var findNextNonWord = ~/[\W]/;
			if (findNextNonWord.matchSub(line.text, position.character)) {
				endChar = findNextNonWord.matchedPos().pos;
			}
			var hover = new Hover();
			hover.contents = "Current word: " + line.text.substring(startChar, endChar);
			event.callback(hover);
		});
	}
}
