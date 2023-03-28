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

// NOTE: As the name suggests, this class is designed to provide a simple
// weighting algorithm for completion. Don't modify how this class behaves,
// except to fix critical bugs (infinite loop, exception, crash, etc.). If yo
// want to improve the weight calculation algorithm, you should almost certainly
// create a new implementation of `ICompletionManager` instead.

/**
	Calculates a weight value for each `CompletionItem`, and sorts by weight.

	Filtering:

	- Case-insensitive. Calls `toLowerCase() on all text.
	- The first character of the filter text must match the first character of
	the `CompletionItem` text.
	- The `CompletionItem` text must contain every character from the filter
	text, in order, but the characters don't need to be consecutive.

	Sorting:

	- Sorts by weight, ascending.
	- A weight value of 0 is a perfect match.
	- For every character in the `CompletionItem` text that is skipped, and for
	every remaining character after the filter text is exhausted, the weight
	increases by one.
	- If two weight values match, falls back case-insensitive string comparison.
**/
class SimpleWeightedCompletionMatcher implements ICompletionMatcher {
	public function new() {}

	private var _filterText:String;
	private var _weightMap:Map<CompletionItem, Int> = [];

	public function updateFilter(filterText:String):Void {
		_filterText = filterText.toLowerCase();
		_weightMap.clear();
	}

	public function filter(item:CompletionItem):Bool {
		var itemText = item.label;
		if (item.filterText != null) {
			itemText = item.filterText;
		}
		var score = 0;
		itemText = itemText.toLowerCase();
		var itemIndex = 0;
		var filterIndex = 0;
		var itemLength = itemText.length;
		var filterLength = _filterText.length;
		while (itemIndex < itemLength && filterIndex < filterLength) {
			var itemChar = itemText.charAt(itemIndex);
			var filterChar = _filterText.charAt(filterIndex);
			if (itemChar == filterChar) {
				filterIndex++;
			} else {
				if (itemIndex == 0) {
					// the first character must match
					return false;
				}
				score++;
			}
			itemIndex++;
		}
		_weightMap.set(item, score);
		return filterIndex == filterLength;
	}

	public function sort(item1:CompletionItem, item2:CompletionItem):Int {
		var score1 = _weightMap.get(item1);
		var score2 = _weightMap.get(item2);
		if (score1 < score2) {
			return -1;
		} else if (score1 > score2) {
			return 1;
		}
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
