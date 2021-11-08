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

package moonshine.editor.text.events;

import moonshine.editor.text.changes.TextEditorChange;
import openfl.events.Event;
import openfl.events.EventType;

/**
	Dispatched by a `TextEditor` when its text changes.
**/
class TextEditorChangeEvent extends Event {
	/**
		Dispatched when the text changes.
	**/
	public static final TEXT_CHANGE:EventType<TextEditorChangeEvent> = "textChange";

	/**
		The text change was initiated locally.
	**/
	public static final ORIGIN_LOCAL:String = "local";

	/**
		The text change was initiated by an undo action.
	**/
	public static final ORIGIN_UNDO:String = "undo";

	/**
		The text change was initiated remotely.
	**/
	public static final ORIGIN_REMOTE:String = "remote";

	/**
		Creates a new `TextEditorChangeEvent` object.
	**/
	public function new(type:String, changes:Array<TextEditorChange>, ?origin:String) {
		super(type);
		this.changes = changes;
		this.origin = origin != null ? origin : ORIGIN_LOCAL;
	}

	/**
		The set of changes to apply.
	**/
	public var changes:Array<TextEditorChange>;

	/**
		The origin of the changes.
	**/
	public var origin:String;

	override public function clone():Event {
		return new TextEditorChangeEvent(type, changes, origin);
	}
}
