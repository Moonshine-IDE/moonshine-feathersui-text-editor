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

import feathers.layout.VerticalLayoutData;
import moonshine.editor.text.lsp.views.theme.SignatureHelpViewStyles;
import feathers.events.TriggerEvent;
import moonshine.lsp.SignatureHelp;
import feathers.layout.HorizontalLayout;
import feathers.layout.VerticalLayout;
import feathers.controls.Button;
import feathers.controls.Label;
import feathers.controls.LayoutGroup;

@:styleContext
class SignatureHelpView extends LayoutGroup {
	public static final CHILD_VARIANT_SIGNATURE_CHANGE_BUTTON = "signatureHelpView_signatureChangeButton";

	public function new() {
		SignatureHelpViewStyles.initialize();
		super();
	}

	private var label:Label;
	private var buttonGroup:LayoutGroup;
	private var prevButton:Button;
	private var nextButton:Button;

	private var _activeSignature:Int = 0;
	private var _activeParameter:Int = 0;

	private var _signatureHelp:SignatureHelp;

	@:flash.property
	public var signatureHelp(get, set):SignatureHelp;

	private function get_signatureHelp():SignatureHelp {
		return _signatureHelp;
	}

	private function set_signatureHelp(value:SignatureHelp):SignatureHelp {
		if (_signatureHelp == value) {
			return _signatureHelp;
		}
		_signatureHelp = value;
		if (_signatureHelp != null) {
			_activeSignature = _signatureHelp.activeSignature;
			_activeParameter = _signatureHelp.activeParameter;
		}
		setInvalid(DATA);
		return _signatureHelp;
	}

	override private function initialize():Void {
		super.initialize();

		var viewLayout = new VerticalLayout();
		viewLayout.gap = 10.0;
		viewLayout.setPadding(10.0);
		layout = viewLayout;

		label = new Label();
		label.wordWrap = true;
		// label.layoutData = new VerticalLayoutData(100.0);
		addChild(label);

		var buttonLayout = new HorizontalLayout();
		buttonLayout.gap = 10.0;
		buttonGroup = new LayoutGroup();
		buttonGroup.layout = buttonLayout;
		addChild(buttonGroup);

		prevButton = new Button();
		prevButton.variant = CHILD_VARIANT_SIGNATURE_CHANGE_BUTTON;
		prevButton.text = "◀";
		prevButton.addEventListener(TriggerEvent.TRIGGER, signatureHelpView_prevButton_triggerHandler);
		buttonGroup.addChild(prevButton);

		nextButton = new Button();
		nextButton.variant = CHILD_VARIANT_SIGNATURE_CHANGE_BUTTON;
		nextButton.text = "▶";
		nextButton.addEventListener(TriggerEvent.TRIGGER, signatureHelpView_nextButton_triggerHandler);
		buttonGroup.addChild(nextButton);
	}

	override private function update():Void {
		var dataInvalid = isInvalid(DATA);

		if (dataInvalid) {
			if (_signatureHelp != null) {
				label.htmlText = getSignatureText();
				label.resetMinWidth();
				label.resetWidth();

				buttonGroup.visible = buttonGroup.includeInLayout = _signatureHelp.signatures.length > 1;
				prevButton.enabled = _activeSignature > 0;
				nextButton.enabled = _activeSignature < (_signatureHelp.signatures.length - 1);
			} else {
				label.htmlText = null;
				prevButton.enabled = false;
				nextButton.enabled = false;
			}
		}

		super.update();
	}

	private function getSignatureText():String {
		if (_signatureHelp == null
			|| _signatureHelp.signatures == null
			|| _signatureHelp.signatures.length == 0
			|| _activeSignature == -1
			|| _activeParameter == -1) {
			return null;
		}
		var signature = _signatureHelp.signatures[_activeSignature];
		var parameters = signature.parameters;
		var signatureParts = ~/[\(\)]/g.split(signature.label);
		var signatureHelpText = StringTools.htmlEscape(signatureParts[0]);
		signatureHelpText += "(";
		var parametersText = signatureParts[1];
		var parameterParts = parametersText.split(",");
		for (i in 0...parameters.length) {
			if (i > 0) {
				signatureHelpText += ",";
			}
			var partText = parameterParts[i];
			if (i == _activeParameter) {
				signatureHelpText += "<b>";
			}
			signatureHelpText += StringTools.htmlEscape(partText);
			if (i == _activeParameter) {
				signatureHelpText += "</b>";
			}
		}
		signatureHelpText += ")";
		if (signatureParts.length > 2) {
			signatureHelpText += StringTools.htmlEscape(signatureParts[2]);
		}
		return signatureHelpText;
	}

	private function signatureHelpView_prevButton_triggerHandler(event:TriggerEvent):Void {
		_activeSignature--;
		if (_activeSignature < 0) {
			_activeSignature = 0;
		}
		setInvalid(DATA);
	}

	private function signatureHelpView_nextButton_triggerHandler(event:TriggerEvent):Void {
		_activeSignature++;
		if (_activeSignature >= _signatureHelp.signatures.length) {
			_activeSignature = _signatureHelp.signatures.length - 1;
		}
		setInvalid(DATA);
	}
}
