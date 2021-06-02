import feathers.controls.Application;
import feathers.controls.Label;
import feathers.layout.VerticalLayout;
import feathers.layout.VerticalLayoutData;
import moonshine.editor.text.lsp.LspTextEditor;
import moonshine.lsp.Diagnostic;
import moonshine.lsp.Position;
import moonshine.lsp.Range;

class Main extends Application {
	public function new() {
		super();

		var appLayout = new VerticalLayout();
		appLayout.horizontalAlign = JUSTIFY;
		layout = appLayout;

		var instructions = new Label();
		instructions.text = 'Hover your mouse over the diagnostics to see more details.';
		instructions.wordWrap = true;
		instructions.setPadding(10.0);
		addChild(instructions);

		var textEditor = new LspTextEditor();
		textEditor.text = "diagnostics may be warnings,\n" + "they may be errors,\n" + "or they may be informational messages.\n"
			+ "hover over them to see more details!";
		textEditor.layoutData = VerticalLayoutData.fill();
		addChild(textEditor);

		textEditor.diagnostics = [
			{
				var diagnostic = new Diagnostic();
				diagnostic.severity = Warning;
				diagnostic.message = "Warnings might be a problem, or maybe not!";
				diagnostic.range = new Range(new Position(0, 19), new Position(0, 27));
				diagnostic;
			},
			{
				var diagnostic = new Diagnostic();
				diagnostic.severity = Error;
				diagnostic.message = "Errors are always bad!";
				diagnostic.range = new Range(new Position(1, 12), new Position(1, 18));
				diagnostic;
			},
			{
				var diagnostic = new Diagnostic();
				diagnostic.severity = Information;
				diagnostic.message = "Informational messages may be used for everything else!";
				diagnostic.range = new Range(new Position(2, 15), new Position(2, 28));
				diagnostic;
			}
		];
	}
}
