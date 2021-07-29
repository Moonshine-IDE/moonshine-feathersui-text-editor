import feathers.controls.Application;
import feathers.controls.Label;
import feathers.layout.VerticalLayout;
import feathers.layout.VerticalLayoutData;
import moonshine.editor.text.lsp.LspTextEditor;
import moonshine.editor.text.lsp.events.LspTextEditorLanguageRequestEvent;
import moonshine.lsp.ParameterInformation;
import moonshine.lsp.SignatureHelp;
import moonshine.lsp.SignatureInformation;
import openfl.system.Capabilities;

class Main extends Application {
	public function new() {
		super();

		var appLayout = new VerticalLayout();
		appLayout.horizontalAlign = JUSTIFY;
		layout = appLayout;

		var instructions = new Label();
		instructions.text = 'Use the ${StringTools.startsWith(Capabilities.version, "MAC ") ? "Command" : "Ctrl"}+Shift+Space keyboard shortcut to show signature help, or type the "(" character.';
		instructions.wordWrap = true;
		instructions.setPadding(10.0);
		addChild(instructions);

		var textEditor = new LspTextEditor();
		textEditor.layoutData = VerticalLayoutData.fill();
		addChild(textEditor);

		textEditor.addEventListener(LspTextEditorLanguageRequestEvent.REQUEST_SIGNATURE_HELP, event -> {
			var signatureHelp = new SignatureHelp();
			signatureHelp.activeSignature = 0;
			signatureHelp.activeParameter = 0;
			signatureHelp.signatures = [
				{
					var info = new SignatureInformation();
					info.label = "addChild(child:DisplayObject):DisplayObject";
					info.parameters = [new ParameterInformation("child", "The child to add.")];
					info.documentation = "Adds a DisplayObject instance to a DisplayObjectContainer instance";
					info;
				},
			];
			event.callback(signatureHelp);
		});
	}
}
