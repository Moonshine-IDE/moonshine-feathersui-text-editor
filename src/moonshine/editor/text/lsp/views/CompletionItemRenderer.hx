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

package moonshine.editor.text.lsp.views;

import feathers.controls.Label;
import feathers.controls.dataRenderers.ItemRenderer;
import moonshine.editor.text.lsp.views.theme.CompletionItemRendererStyles;
import moonshine.lsp.CompletionItem;

@:styleContext
class CompletionItemRenderer extends ItemRenderer {
	public static final CHILD_VARIANT_DETAIL_TEXT = "completionItemRenderer_detailText";

	public function new() {
		CompletionItemRendererStyles.initialize();
		super();
	}

	private var _completionIcon:CompletionItemIcon;
	private var _detailText:Label;

	override private function initialize():Void {
		super.initialize();

		_completionIcon = new CompletionItemIcon();
		icon = _completionIcon;

		_detailText = new Label();
		_detailText.variant = CHILD_VARIANT_DETAIL_TEXT;
		accessoryView = _detailText;
	}

	override private function update():Void {
		var dataInvalid = isInvalid(DATA);

		if (dataInvalid) {
			var item = cast(this.data, CompletionItem);
			if (item != null) {
				text = item.label;
				_detailText.text = item.detail;
			} else {
				text = null;
				_detailText.text = null;
			}
			_completionIcon.data = item;
		}

		super.update();
	}
}
