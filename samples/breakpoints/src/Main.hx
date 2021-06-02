import feathers.controls.Application;
import feathers.controls.Label;
import feathers.layout.VerticalLayout;
import feathers.layout.VerticalLayoutData;
import moonshine.editor.text.TextEditor;
import moonshine.editor.text.events.TextEditorLineEvent;

class Main extends Application {
	public function new() {
		super();

		var appLayout = new VerticalLayout();
		appLayout.horizontalAlign = JUSTIFY;
		layout = appLayout;

		var instructions = new Label();
		instructions.text = 'Click the gutter area by the line number to toggle breakpoints.';
		instructions.wordWrap = true;
		instructions.setPadding(10.0);
		addChild(instructions);

		var textEditor = new TextEditor();
		textEditor.text = "class MyClass extends AnotherClass {\n" + "\tpublic function new() {\n" + "\t\tsuper();\n" + "\t}\n" + "}\n";
		textEditor.allowToggleBreakpoints = true;
		textEditor.layoutData = VerticalLayoutData.fill();
		textEditor.addEventListener(TextEditorLineEvent.TOGGLE_BREAKPOINT, event -> {
			var hasBreakpoint = textEditor.breakpoints.contains(event.lineIndex);
			trace('breakpoint ${hasBreakpoint ? "added" : "removed"} at line: ${event.lineIndex}');
		});
		addChild(textEditor);
	}
}
