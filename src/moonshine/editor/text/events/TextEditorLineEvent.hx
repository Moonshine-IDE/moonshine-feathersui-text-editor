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

import openfl.events.Event;
import openfl.events.EventType;

class TextEditorLineEvent extends Event {
	public static final TOGGLE_BREAKPOINT:EventType<TextEditorLineEvent> = "toggleBreakpoint";

	public function new(type:String, lineIndex:Int) {
		super(type);
		this.lineIndex = lineIndex;
	}

	public var lineIndex:Int;

	override public function clone():Event {
		return new TextEditorLineEvent(type, lineIndex);
	}
}
