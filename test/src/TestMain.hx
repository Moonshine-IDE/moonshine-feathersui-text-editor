import openfl.display.Sprite;
import utest.Runner;
import utest.ui.Report;

class TestMain extends Sprite {
	public static var test_root:Sprite;

	public function new() {
		super();

		test_root = this;

		// create a `Runner` to run your tests
		var runner = new Runner();

		// add as many test cases as you need
		runner.addCase(new tests.TextEditorSelectionTestCase());
		runner.addCase(new tests.TextEditorTextInputTestCase());
		runner.addCase(new tests.TextEditorUndoRedoTestCase());
		runner.addCase(new tests.LspTextEditorCompletionTestCase());
		runner.addCase(new tests.LspTextEditorSignatureHelpTestCase());
		runner.addCase(new tests.LspTextEditorHoverTestCase());
		runner.addCase(new tests.LspTextEditorCodeActionTestCase());

		// a report prints the final results after all tests have run
		Report.create(runner);

		// don't forget to start the runner
		runner.run();
	}
}
