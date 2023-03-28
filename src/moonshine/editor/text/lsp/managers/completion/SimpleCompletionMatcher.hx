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

package moonshine.editor.text.lsp.managers.completion;

import moonshine.lsp.CompletionItem;

// NOTE: As the name suggests, this is basically meant to be one of the simplest
// possible implementations of the `ICompletionManager` interface. Don't modify
// how this class works, except to fix a critical bug (infinite loop, runtime
// exception, crash, etc.). If you want to improve the behavior, in any way, you
// should almost certainly create a new implementation of `ICompletionManager`
// instead.

/**
	Checks if the `CompletionItem` text starts with the filter text.

	Filtering:

	- Case-insensitive. Calls `toLowerCase()` on all text.
	- The `CompletionItem` text must start with the filter text.

	Sorting:

	- A case-insensitive string comparison.
**/
class SimpleCompletionMatcher implements ICompletionMatcher {
	public function new() {}

	private var _filterText:String;

	public function updateFilter(filterText:String):Void {
		_filterText = filterText.toLowerCase();
	}

	public function filter(item:CompletionItem):Bool {
		var itemText = item.label;
		if (item.filterText != null) {
			itemText = item.filterText;
		}
		var lowerItemText = itemText.toLowerCase();
		return StringTools.startsWith(lowerItemText, _filterText);
	}

	public function sort(item1:CompletionItem, item2:CompletionItem):Int {
		var text1 = (item1.sortText != null) ? item1.sortText : item1.label;
		text1 = text1.toLowerCase();
		var text2 = (item2.sortText != null) ? item2.sortText : item2.label;
		text2 = text2.toLowerCase();
		if (text1 < text2) {
			return -1;
		}
		if (text1 > text2) {
			return 1;
		}
		// if sortText is equal, fall back to comparing label instead
		if (item1.sortText != null || item2.sortText != null) {
			text1 = item1.label.toLowerCase();
			text2 = item2.label.toLowerCase();
			if (text1 < text2) {
				return -1;
			}
			if (text1 > text2) {
				return 1;
			}
		}
		return 0;
	}
}
