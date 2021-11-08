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

package moonshine.editor.text.lsp.events;

import moonshine.lsp.Command;
import moonshine.lsp.LocationLink;
import moonshine.lsp.WorkspaceEdit;
import openfl.events.Event;
import openfl.events.EventType;

/**
	Events dispatched by a `LspTextEditor` when it needs to perform a
	language-related action.
**/
class LspTextEditorLanguageActionEvent<T> extends Event {
	/**
		Dispatched when the text editor needs to apply a workspace edit, which
		may affect other files.
	**/
	public static final APPLY_WORKSPACE_EDIT:EventType<LspTextEditorLanguageActionEvent<WorkspaceEdit>> = "applyWorkspaceEdit";

	/**
		Dispatched when the text editor needs to run a command.
	**/
	public static final RUN_COMMAND:EventType<LspTextEditorLanguageActionEvent<Command>> = "runCommand";

	/**
		Dispatched when the text editor needs to open a link, either to another
		file or to an external URL.
	**/
	public static final OPEN_LINK:EventType<LspTextEditorLanguageActionEvent<Array<LocationLink>>> = "openLink";

	/**
		Creates a new `LspTextEditorLanguageActionEvent` object.
	**/
	public function new(type:String, data:T) {
		super(type);
		this.data = data;
	}

	/**
		The data associated with the event type.
	**/
	public var data:T;

	override public function clone():Event {
		return new LspTextEditorLanguageActionEvent(type, data);
	}
}
