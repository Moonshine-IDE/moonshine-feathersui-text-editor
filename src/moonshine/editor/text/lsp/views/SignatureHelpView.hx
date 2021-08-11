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

import feathers.controls.Button;
import feathers.controls.Label;
import feathers.controls.LayoutGroup;
import feathers.controls.ScrollContainer;
import feathers.core.IFocusExtras;
import feathers.events.TriggerEvent;
import feathers.layout.HorizontalLayout;
import feathers.layout.VerticalLayout;
import feathers.text.TextFormat;
import moonshine.editor.text.lsp.views.theme.SignatureHelpViewStyles;
import moonshine.lsp.MarkupContent;
import moonshine.lsp.SignatureHelp;
import openfl.display.DisplayObject;

@:styleContext
class SignatureHelpView extends ScrollContainer implements IFocusExtras {
	public static final CHILD_VARIANT_PREVIOUS_SIGNATURE_BUTTON = "signatureHelpView_previousSignatureButton";
	public static final CHILD_VARIANT_NEXT_SIGNATURE_BUTTON = "signatureHelpView_nextSignatureButton";

	public function new() {
		SignatureHelpViewStyles.initialize();
		super();

		tabEnabled = false;
	}

	private var label:Label;
	private var buttonGroup:LayoutGroup;
	private var prevButton:Button;
	private var nextButton:Button;

	private var _activeSignatureIndex:Int = 0;

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
			_activeSignatureIndex = _signatureHelp.activeSignature;
		} else {
			_activeSignatureIndex = -1;
		}
		setInvalid(DATA);
		return _signatureHelp;
	}

	@:style
	public var textFormat:TextFormat = null;

	private var _focusExtrasBefore:Array<DisplayObject> = [];

	@:dox(hide)
	@:flash.property
	public var focusExtrasBefore(get, never):Array<DisplayObject>;

	private function get_focusExtrasBefore():Array<DisplayObject> {
		return this._focusExtrasBefore;
	}

	private var _focusExtrasAfter:Array<DisplayObject> = [];

	@:dox(hide)
	@:flash.property
	public var focusExtrasAfter(get, never):Array<DisplayObject>;

	private function get_focusExtrasAfter():Array<DisplayObject> {
		return this._focusExtrasAfter;
	}

	override private function initialize():Void {
		super.initialize();

		var viewLayout = new VerticalLayout();
		viewLayout.horizontalAlign = JUSTIFY;
		viewLayout.justifyResetEnabled = true;
		viewLayout.setPadding(10.0);
		layout = viewLayout;

		label = new Label();
		label.selectable = true;
		label.wordWrap = true;
		addChild(label);

		var buttonLayout = new HorizontalLayout();
		buttonLayout.gap = 4.0;
		buttonLayout.setPadding(10.0);
		buttonLayout.verticalAlign = BOTTOM;
		buttonGroup = new LayoutGroup();
		buttonGroup.layout = buttonLayout;
		_focusExtrasBefore.push(buttonGroup);
		addRawChild(buttonGroup);

		prevButton = new Button();
		prevButton.variant = CHILD_VARIANT_PREVIOUS_SIGNATURE_BUTTON;
		prevButton.text = "◀";
		prevButton.addEventListener(TriggerEvent.TRIGGER, signatureHelpView_prevButton_triggerHandler);
		buttonGroup.addChild(prevButton);

		nextButton = new Button();
		nextButton.variant = CHILD_VARIANT_NEXT_SIGNATURE_BUTTON;
		nextButton.text = "▶";
		nextButton.addEventListener(TriggerEvent.TRIGGER, signatureHelpView_nextButton_triggerHandler);
		buttonGroup.addChild(nextButton);
	}

	override private function update():Void {
		var dataInvalid = isInvalid(DATA);
		var stylesInvalid = isInvalid(STYLES);

		if (dataInvalid) {
			label.htmlText = getHtmlText();
		}

		if (stylesInvalid) {
			label.textFormat = textFormat;
		}

		super.update();

		this.layoutButtonGroup();
	}

	override private function calculateViewPortOffsets(forceScrollBars:Bool, useActualBounds:Bool):Void {
		if (_signatureHelp != null && _signatureHelp.signatures.length > 1) {
			this.buttonGroup.validateNow();
			this.leftViewPortOffset += this.buttonGroup.width;
			this.chromeMeasuredHeight = Math.max(this.chromeMeasuredHeight, this.buttonGroup.height);
			this.chromeMeasuredMinHeight = Math.max(this.chromeMeasuredMinHeight, this.buttonGroup.minHeight);
		}
		super.calculateViewPortOffsets(forceScrollBars, useActualBounds);
	}

	private function layoutButtonGroup():Void {
		this.buttonGroup.visible = _signatureHelp != null && _signatureHelp.signatures.length > 1;
		this.buttonGroup.x = this.paddingLeft;
		this.buttonGroup.y = this.paddingTop;
		this.buttonGroup.height = this.actualHeight - this.paddingTop - this.paddingBottom;
		this.buttonGroup.validateNow();
	}

	private function getHtmlText():String {
		var signatureText = getSignatureHtmlText();
		if (signatureText == null) {
			return null;
		}
		var markdown = "";

		var activeParameterIndex = _signatureHelp.activeParameter;
		var signatureDocumentation:String = null;
		var parameterDocumentation:String = null;
		if (_activeSignatureIndex != -1 && _activeSignatureIndex < _signatureHelp.signatures.length) {
			var activeSignature = _signatureHelp.signatures[_activeSignatureIndex];
			signatureDocumentation = getDocumentation(activeSignature.documentation);
			if (activeSignature.activeParameter != -1) {
				activeParameterIndex = activeSignature.activeParameter;
			}
			if (activeParameterIndex != -1 && activeParameterIndex < activeSignature.parameters.length) {
				var activeParameter = activeSignature.parameters[activeParameterIndex];
				parameterDocumentation = getDocumentation(activeParameter.documentation);
			}
		}

		var hasParameterDocumentation = parameterDocumentation != null && parameterDocumentation.length > 0;
		var hasSignatureDocumentation = signatureDocumentation != null && signatureDocumentation.length > 0;
		if (hasParameterDocumentation || hasSignatureDocumentation) {
			markdown += "-----\n\n";
		}

		if (hasParameterDocumentation) {
			markdown += StringTools.trim(parameterDocumentation);
		}
		if (hasSignatureDocumentation) {
			if (hasParameterDocumentation) {
				markdown += "\n\n";
			}
			markdown += StringTools.trim(signatureDocumentation);
		}
		var result = signatureText;
		if (markdown.length > 0) {
			result += "\n" + TextFieldMarkdown.markdownToHtml(markdown);
		}
		return result;
	}

	private function getSignatureHtmlText():String {
		if (_signatureHelp == null
			|| _signatureHelp.signatures == null
			|| _signatureHelp.signatures.length == 0
			|| _activeSignatureIndex == -1) {
			return null;
		}
		var activeParameter = _signatureHelp.activeParameter;
		var signature = _signatureHelp.signatures[_activeSignatureIndex];
		if (signature.activeParameter != -1) {
			activeParameter = signature.activeParameter;
		}

		var parameters = signature.parameters;
		var signatureParts = ~/[\(\)]/g.split(signature.label);
		var signatureHelpText = '<p class="pre"><font face="_typewriter">';
		signatureHelpText += StringTools.htmlEscape(signatureParts[0]);
		signatureHelpText += "(";
		var parametersText = signatureParts[1];
		var parameterParts = parametersText.split(",");
		for (i in 0...parameters.length) {
			if (i > 0) {
				signatureHelpText += ",";
			}
			var partText = parameterParts[i];
			if (i == activeParameter) {
				signatureHelpText += "<b>";
			}
			signatureHelpText += StringTools.htmlEscape(partText);
			if (i == activeParameter) {
				signatureHelpText += "</b>";
			}
		}
		signatureHelpText += ")";
		if (signatureParts.length > 2) {
			signatureHelpText += StringTools.htmlEscape(signatureParts[2]);
		}
		signatureHelpText += "</font></p>";
		return signatureHelpText;
	}

	private function getDocumentation(original:Any):String {
		if (original == null) {
			return null;
		}
		if ((original is String)) {
			return (original : String);
		}
		if ((original is MarkupContent)) {
			var markupContent = (original : MarkupContent);
			return markupContent.value;
		}
		// some kind of content that we don't understand
		// to be safe, show nothing
		return null;
	}

	private function signatureHelpView_prevButton_triggerHandler(event:TriggerEvent):Void {
		_activeSignatureIndex--;
		if (_activeSignatureIndex < 0) {
			_activeSignatureIndex = 0;
		}
		setInvalid(DATA);
	}

	private function signatureHelpView_nextButton_triggerHandler(event:TriggerEvent):Void {
		_activeSignatureIndex++;
		if (_activeSignatureIndex >= _signatureHelp.signatures.length) {
			_activeSignatureIndex = _signatureHelp.signatures.length - 1;
		}
		setInvalid(DATA);
	}
}
