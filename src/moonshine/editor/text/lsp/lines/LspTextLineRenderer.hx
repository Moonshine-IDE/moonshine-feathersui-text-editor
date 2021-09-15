/*
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License

	No warranty of merchantability or fitness of any kind.
	Use this software at your own risk.
 */

package moonshine.editor.text.lsp.lines;

import moonshine.editor.text.lines.TextLineRenderer;
import moonshine.lsp.Diagnostic;
import openfl.display.Shape;

class LspTextLineRenderer extends TextLineRenderer {
	public function new() {
		super();
	}

	private var _diagnosticsShape:Shape;

	private var _diagnostics:Array<Diagnostic>;

	@:flash.property
	public var diagnostics(get, set):Array<Diagnostic>;

	private function get_diagnostics():Array<Diagnostic> {
		return _diagnostics;
	}

	private function set_diagnostics(value:Array<Diagnostic>):Array<Diagnostic> {
		if (_diagnostics == value) {
			return _diagnostics;
		}
		_diagnostics = value;
		setInvalid(DATA);
		return _diagnostics;
	}

	override private function initialize():Void {
		super.initialize();

		if (_diagnosticsShape == null) {
			_diagnosticsShape = new Shape();
			addChild(_diagnosticsShape);
		}
	}

	override private function update():Void {
		super.update();

		drawDiagnostics();
	}

	private function drawDiagnostics():Void {
		_diagnosticsShape.graphics.clear();
		if (diagnostics == null || diagnostics.length == 0) {
			_diagnosticsShape.visible = false;
			return;
		}
		var hasDiagnosticsOnLine = false;
		for (diagnostic in diagnostics) {
			if (diagnostic.severity == Hint) {
				// skip hints because they are not meant to be displayed
				// to the user like regular problems. they're used
				// internally by the language server or the editor for
				// other types of things, such as code actions.
				continue;
			}
			var range = diagnostic.range;
			var start = range.start;
			var end = range.end;
			if (lineIndex < start.line || lineIndex > end.line) {
				continue;
			}
			hasDiagnosticsOnLine = true;
			var maxChar = _mainTextField.length - 1;
			var startChar = (lineIndex == start.line) ? start.character : 0;
			var endChar = (lineIndex == end.line) ? end.character : maxChar;
			if (startChar > maxChar) {
				startChar = maxChar;
			}
			if (endChar > maxChar) {
				endChar = maxChar;
			}
			var lineColor = switch (diagnostic.severity) {
				case Error: 0xfa0707;
				case Warning: 0x078a07;
				case Hint: 0x0707fa;
				case Information: 0x0707fa;
				default: 0xfa0707;
			};
			_diagnosticsShape.graphics.lineStyle(1, lineColor);
			var stepLength = 3.0;
			var startX = 0.0;
			var lineLength = 0.0;
			if (_text.length == 0) {
				var lineMetrics = _mainTextField.getLineMetrics(0);
				startX = lineMetrics.x;
				lineLength = Math.max(2.0 * stepLength, lineMetrics.width);
			} else {
				var startBounds = _mainTextField.getCharBoundaries(startChar);
				var endBounds = _mainTextField.getCharBoundaries(endChar);
				startX = startBounds.x;
				// does not include the full end char
				lineLength = endBounds.x - startBounds.x;
			}
			_diagnosticsShape.graphics.moveTo(startX, 0.0);
			var upDirection = false;
			var offset = 0.0;
			var startBoundsOffset = 0.0;
			while (offset <= lineLength) {
				offset = offset + stepLength;
				startBoundsOffset = startX + offset;

				if (upDirection) {
					_diagnosticsShape.graphics.lineTo(startBoundsOffset, 0);
				} else {
					_diagnosticsShape.graphics.lineTo(startBoundsOffset, stepLength);
				}
				upDirection = !upDirection;
			}
		}
		_diagnosticsShape.visible = hasDiagnosticsOnLine;
		if (hasDiagnosticsOnLine) {
			var lineMetrics = _mainTextField.getLineMetrics(0);
			_diagnosticsShape.x = _mainTextField.x;
			_diagnosticsShape.y = _mainTextField.y + lineMetrics.height;
		}
	}
}
