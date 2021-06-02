import feathers.controls.Application;
import feathers.controls.Label;
import feathers.layout.VerticalLayout;
import feathers.layout.VerticalLayoutData;
import moonshine.editor.text.lsp.LspTextEditor;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageRequestEvent;
import moonshine.lsp.CompletionItem;
import moonshine.lsp.CompletionList;
import openfl.system.Capabilities;

class Main extends Application {
	public function new() {
		super();
	}

	override private function initialize():Void {
		super.initialize();

		var appLayout = new VerticalLayout();
		appLayout.horizontalAlign = JUSTIFY;
		layout = appLayout;

		var instructions = new Label();
		instructions.text = 'Use the ${StringTools.startsWith(Capabilities.version, "MAC ") ? "Command" : "Ctrl"}+Space keyboard shortcut to show completion, or type the "." character. Use the Up and Down arrow keys to navigate the list and resolve the incomplete items.';
		instructions.wordWrap = true;
		instructions.setPadding(10.0);
		addChild(instructions);

		var textEditor = new LspTextEditor();
		textEditor.layoutData = VerticalLayoutData.fill();
		addChild(textEditor);
		textEditor.focusManager.focus = textEditor;

		textEditor.addEventListener(LspTextEditorLanguageRequestEvent.REQUEST_COMPLETION, event -> {
			var items = [
				{
					var item = new CompletionItem();
					item.label = "Item1";
					item.kind = Field;
					item;
				},
				{
					var item = new CompletionItem();
					item.label = "Item2";
					item.kind = Field;
					item;
				},
			];
			var isIncomplete = true;
			var completion = new CompletionList(items, isIncomplete);
			event.callback(completion);
		});
		textEditor.addEventListener(LspTextEditorLanguageRequestEvent.REQUEST_RESOLVE_COMPLETION, event -> {
			var item = event.params;
			item.detail = "Resolved";
			event.callback(item);
		});
	}
}
