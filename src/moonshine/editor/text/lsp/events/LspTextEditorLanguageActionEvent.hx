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

import moonshine.lsp.WorkspaceEdit;
import moonshine.lsp.CodeAction;
import moonshine.lsp.Command;
import moonshine.lsp.LocationLink;
import openfl.events.Event;
import openfl.events.EventType;

class LspTextEditorLanguageActionEvent<T> extends Event {
	public static final APPLY_WORKSPACE_EDIT:EventType<LspTextEditorLanguageActionEvent<WorkspaceEdit>> = "applyWorkspaceEdit";
	public static final RUN_COMMAND:EventType<LspTextEditorLanguageActionEvent<Command>> = "runCommand";
	public static final OPEN_LINK:EventType<LspTextEditorLanguageActionEvent<Array<LocationLink>>> = "openLink";

	public function new(type:String, data:T) {
		super(type);
		this.data = data;
	}

	public var data:T;

	override public function clone():Event {
		return new LspTextEditorLanguageActionEvent(type, data);
	}
}
