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

import moonshine.lsp.CodeAction;
import moonshine.lsp.CodeActionParams;
import moonshine.lsp.CompletionItem;
import moonshine.lsp.CompletionList;
import moonshine.lsp.CompletionParams;
import moonshine.lsp.DefinitionParams;
import moonshine.lsp.Hover;
import moonshine.lsp.HoverParams;
import moonshine.lsp.SignatureHelp;
import moonshine.lsp.SignatureHelpParams;
import openfl.events.Event;
import openfl.events.EventType;

/**
	Events dispatched by a `LspTextEditor` when performing a language-related
	request.
**/
class LspTextEditorLanguageRequestEvent<ParamsType, ResultType> extends Event {
	/**
		Dispatched when the text editor requests hover details.
	**/
	public static final REQUEST_HOVER:EventType<LspTextEditorLanguageRequestEvent<HoverParams, Hover>> = "requestHover";

	/**
		Dispatched when the text editor requests a definition.
	**/
	public static final REQUEST_DEFINITION:EventType<LspTextEditorLanguageRequestEvent<DefinitionParams,
		Array<Any /* Location | LocationLink */>>> = "requestDefinition";

	/**
		Dispatched when the text editor requests a completion list.
	**/
	public static final REQUEST_COMPLETION:EventType<LspTextEditorLanguageRequestEvent<CompletionParams, CompletionList>> = "requestCompletion";

	/**
		Dispatched when the text editor requests resolution of a completion
		item.
	**/
	public static final REQUEST_RESOLVE_COMPLETION:EventType<LspTextEditorLanguageRequestEvent<CompletionItem, CompletionItem>> = "requestResolveCompletion";

	/**
		Dispatched when the text editor requests signature help.
	**/
	public static final REQUEST_SIGNATURE_HELP:EventType<LspTextEditorLanguageRequestEvent<SignatureHelpParams, SignatureHelp>> = "requestSignatureHelp";

	/**
		Dispatched when the text editor requests code actions.
	**/
	public static final REQUEST_CODE_ACTIONS:EventType<LspTextEditorLanguageRequestEvent<CodeActionParams, Array<CodeAction>>> = "requestCodeActions";

	/**
		Creates a new `LspTextEditorLanguageRequestEvent` object.
	**/
	public function new(type:EventType<LspTextEditorLanguageRequestEvent<ParamsType, ResultType>>, params:ParamsType, callback:(ResultType) -> Void) {
		super(type);
		this.params = params;
		this.callback = callback;
	}

	/**
		The parameters for the request.
	**/
	public var params:ParamsType;

	/**
		A function to call when the result of the request is returned.
	**/
	public var callback:(ResultType) -> Void;

	override public function clone():Event {
		return new LspTextEditorLanguageRequestEvent(type, params, callback);
	}
}
