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

import haxe.Constraints.Function;
import moonshine.lsp.Command;
import openfl.errors.ArgumentError;
import openfl.utils.Future;

/**
	Used internally by `LspTextEditor` to manage command requests.
**/
class CommandManager {
	/**
		Creates a new `CommandManager` object.
	**/
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

	/**
		Registers a command with the specified identifier.
	**/
	public function registerCommand(id:String, command:Function):Void {
		_commands.set(id, command);
	}

	/**
		Returns `true` if a command has been registered.
	**/
	public function hasCommand(id:String):Bool {
		return _commands.exists(id);
	}

	/**
		Runs a command, and passes the result to the callback. If the command
		has not been registered, throws an `ArgumentError`.
	**/
	public function runCommand(command:Command, ?callback:Function):Void {
		var commandFunc = _commands.get(command.command);
		if (commandFunc == null) {
			throw new ArgumentError('Command not registered: ${command.command}');
		}
		var result = Reflect.callMethod(null, commandFunc, command.arguments);
		if (callback == null) {
			return;
		}
		#if (openfl >= "9.0.0")
		if ((result is openfl.utils.Promise)) {
			var promise = cast(result, openfl.utils.Promise<Dynamic>);
			promise.future.onComplete(cast callback);
			return;
		} else
		#end
		if ((result is Future)) {
			var future = cast(result, Future<Dynamic>);
			future.onComplete(cast callback);
			return;
		}
		callback(result);
	}
}
