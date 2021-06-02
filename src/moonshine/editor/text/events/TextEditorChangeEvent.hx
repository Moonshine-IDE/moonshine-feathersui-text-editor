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

class TextEditorChangeEvent extends Event {
	public static final TEXT_CHANGE:EventType<TextEditorChangeEvent> = "textChange";

	public static final ORIGIN_LOCAL:String = "local";
	public static final ORIGIN_UNDO:String = "undo";
	public static final ORIGIN_REMOTE:String = "remote";

	public function new(type:String, changes:Array<TextEditorChange>, ?origin:String) {
		super(type);
		this.changes = changes;
		this.origin = origin != null ? origin : ORIGIN_LOCAL;
	}

	public var changes:Array<TextEditorChange>;
	public var origin:String;

	override public function clone():Event {
		return new TextEditorChangeEvent(type, changes, origin);
	}
}
