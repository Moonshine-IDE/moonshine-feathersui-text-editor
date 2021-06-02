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

package moonshine.editor.text.syntax.parser.context;

class ContextSwitchManager {
	private var switches:Map<Int, Array<ContextSwitch>> = [];

	public function new(switches:Array<ContextSwitch>) {
		for (swtch in switches) {
			addSwitch(swtch);
		}
	}

	public function addSwitch(swtch:ContextSwitch, highPriority:Bool = false):Void {
		for (from in swtch.from) {
			if (!switches.exists(from)) {
				switches.set(from, []);
			}

			if (highPriority) {
				switches.get(from).unshift(swtch);
			} else {
				switches.get(from).push(swtch);
			}
		}
	}

	public function getSwitches(from:Int):Array<ContextSwitch> {
		return switches.get(from);
	}
}
