import feathers.controls.Application;
import feathers.controls.Label;
import feathers.layout.VerticalLayout;
import feathers.layout.VerticalLayoutData;
import moonshine.editor.text.lsp.LspTextEditor;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageActionEvent;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageRequestEvent;
import moonshine.lsp.CodeAction;
import moonshine.lsp.CodeActionKind;
import moonshine.lsp.Command;
import openfl.system.Capabilities;

class Main extends Application {
	public function new() {
		super();
	}

	override private function initialize():Void {
		var appLayout = new VerticalLayout();
		appLayout.horizontalAlign = JUSTIFY;
		layout = appLayout;

		var instructions = new Label();
		instructions.text = 'Use the ${StringTools.startsWith(Capabilities.version, "MAC ") ? "Command" : "Ctrl"}+. keyboard shortcut to show code actions.';
		instructions.wordWrap = true;
		instructions.setPadding(10.0);
		addChild(instructions);

		var textEditor = new LspTextEditor();
		textEditor.text = "Check for code actions";
		textEditor.layoutData = VerticalLayoutData.fill();
		addChild(textEditor);

		textEditor.focusManager.focus = textEditor;

		textEditor.addEventListener(LspTextEditorLanguageRequestEvent.REQUEST_CODE_ACTIONS, event -> {
			var command = new Command();
			command.title = "My Custom Command";
			command.command = "myCustomCommand";
			command.arguments = ["string", 123.0];
			var codeAction = new CodeAction();
			codeAction.title = "Code Action with Command";
			codeAction.command = command;
			codeAction.kind = CodeActionKind.QuickFix;
			event.callback([codeAction]);
		});

		textEditor.addEventListener(LspTextEditorLanguageActionEvent.APPLY_WORKSPACE_EDIT, event -> {
			trace("workspace edit");
		});

		textEditor.addEventListener(LspTextEditorLanguageActionEvent.RUN_COMMAND, event -> {
			switch (event.data.command) {
				case "myCustomCommand":
					trace("myCustomCommand arguments: " + event.data.arguments);
				default:
					trace('Unknown command: ${event.data.command}');
			}
		});
	}
}
