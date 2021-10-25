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

package moonshine.editor.text.lsp.managers;

import openfl.errors.ArgumentError;
import moonshine.lsp.Command;
import openfl.utils.Promise;
import haxe.Constraints.Function;

class CommandManager {
	public function new(textEditor:LspTextEditor) {
		_textEditor = textEditor;

		registerCommand("editor.action.revealDefinition", () -> {
			_textEditor.definition();
		});
		registerCommand("editor.action.selectAll", () -> {
			_textEditor.selectAll();
		});
		registerCommand("editor.action.showHover", () -> {
			_textEditor.hover();
		});
		registerCommand("editor.action.triggerParameterHints", () -> {
			_textEditor.signatureHelp();
		});
		registerCommand("editor.action.triggerSuggest", () -> {
			_textEditor.completion();
		});
		registerCommand("editor.action.commentLine", () -> {
			_textEditor.toggleLineComment();
		});
		registerCommand("editor.action.blockComment", () -> {
			_textEditor.toggleBlockComment();
		});
		registerCommand("editor.debug.action.toggleBreakpoint", () -> {
			_textEditor.toggleBreakpoint();
		});
	}

	private var _textEditor:LspTextEditor;

	private var _commands:Map<String, Function> = [];

	public function hasCommand(id:String):Bool {
		return _commands.exists(id);
	}

	public function runCommand(command:Command, ?callback:Function):Void {
		var commandFunc = _commands.get(command.command);
		if (commandFunc == null) {
			throw new ArgumentError('Command not registered: ${command.command}');
		}
		var result = Reflect.callMethod(null, commandFunc, command.arguments);
		if (callback == null) {
			return;
		}
		if ((result is Promise)) {
			(result : Promise<Dynamic>).future.onComplete(cast callback);
			return;
		}
		callback(result);
	}

	public function registerCommand(id:String, command:Function):Void {
		_commands.set(id, command);
	}
}
