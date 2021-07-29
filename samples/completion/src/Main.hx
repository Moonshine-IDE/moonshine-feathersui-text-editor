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
		instructions.text = 'Use the ${StringTools.startsWith(Capabilities.version, "MAC ") ? "Command" : "Ctrl"}+Space keyboard shortcut to show completion, or type the "." character.';
		instructions.wordWrap = true;
		instructions.setPadding(10.0);
		addChild(instructions);

		var textEditor = new LspTextEditor();
		textEditor.layoutData = VerticalLayoutData.fill();
		addChild(textEditor);
		textEditor.focusManager.focus = textEditor;

		textEditor.addEventListener(LspTextEditorLanguageRequestEvent.REQUEST_COMPLETION, event -> {
			var completion = new CompletionList([
				{
					var item = new CompletionItem();
					item.label = "parent";
					item.kind = Field;
					item.detail = "openfl.display.DisplayObjectContainer";
					item.documentation = "Indicates the DisplayObjectContainer object that contains this display object.";
					item;
				},
				{
					var item = new CompletionItem();
					item.label = "root";
					item.kind = Field;
					item.detail = "openfl.display.DisplayObject";
					item.documentation = "The top-most display object in the portion of the display list's tree structure.";
					item;
				},
				{
					var item = new CompletionItem();
					item.label = "stage";
					item.kind = Field;
					item.detail = "openfl.display.Stage";
					item.documentation = "The stage of the display object";
					item;
				},
			]);
			event.callback(completion);
		});
	}
}
