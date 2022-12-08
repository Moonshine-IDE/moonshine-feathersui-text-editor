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
import feathers.layout.Measurements;
import feathers.layout.VerticalLayout;
import feathers.text.TextFormat;
import moonshine.editor.text.lsp.views.theme.SignatureHelpViewStyles;
import moonshine.lsp.MarkupContent;
import moonshine.lsp.SignatureHelp;
import openfl.display.DisplayObject;
import openfl.events.Event;

/**
	A view to display signature help data.

	@see `moonshine.lsp.SignatureHelp`
**/
@:styleContext
class SignatureHelpView extends ScrollContainer implements IFocusExtras {
	/**
		The variant used to style the "previous" button child component in a
		theme. The component is a `Button`.
	**/
	public static final CHILD_VARIANT_PREVIOUS_SIGNATURE_BUTTON = "signatureHelpView_previousSignatureButton";

	/**
		The variant used to style the "next" button child component in a
		theme. The component is a `Button`.
	**/
	public static final CHILD_VARIANT_NEXT_SIGNATURE_BUTTON = "signatureHelpView_nextSignatureButton";

	/**
		Creates a new `SignatureHelpView` object.
	**/
	public function new() {
		SignatureHelpViewStyles.initialize();
		super();

		tabEnabled = false;

		addEventListener(Event.REMOVED_FROM_STAGE, signatureHelpView_removedFromStageHandler);
	}

	private var label:Label;
	private var _buttonGroupMeasurements:Measurements;
	private var buttonGroup:LayoutGroup;
	private var prevButton:Button;
	private var nextButton:Button;

	private var _activeSignatureIndex:Int = 0;

	private var _signatureHelp:SignatureHelp;

	/**
		The signature help data to display.
	**/
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

	/**
		The font styles used to display the text.
	**/
	@:style
	public var textFormat:TextFormat = null;

	private var _focusExtrasBefore:Array<DisplayObject> = [];

	@:dox(hide)
	@:flash.property
	public var focusExtrasBefore(get, never):Array<DisplayObject>;

	private function get_focusExtrasBefore():Array<DisplayObject> {
		return _focusExtrasBefore;
	}

	private var _focusExtrasAfter:Array<DisplayObject> = [];

	@:dox(hide)
	@:flash.property
	public var focusExtrasAfter(get, never):Array<DisplayObject>;

	private function get_focusExtrasAfter():Array<DisplayObject> {
		return _focusExtrasAfter;
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
		buttonGroup.initializeNow();
		_buttonGroupMeasurements = new Measurements(buttonGroup);

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

		layoutButtonGroup();
	}

	override private function calculateViewPortOffsets(forceScrollBars:Bool, useActualBounds:Bool):Void {
		if (_signatureHelp != null && _signatureHelp.signatures.length > 1) {
			if (_buttonGroupMeasurements != null) {
				_buttonGroupMeasurements.restore(buttonGroup);
			}
			buttonGroup.validateNow();
			leftViewPortOffset += buttonGroup.width;
			chromeMeasuredHeight = Math.max(chromeMeasuredHeight, buttonGroup.height);
			chromeMeasuredMinHeight = Math.max(chromeMeasuredMinHeight, buttonGroup.minHeight);
		}
		super.calculateViewPortOffsets(forceScrollBars, useActualBounds);
	}

	private function layoutButtonGroup():Void {
		buttonGroup.visible = _signatureHelp != null && _signatureHelp.signatures.length > 1;
		buttonGroup.x = paddingLeft;
		buttonGroup.y = paddingTop;
		buttonGroup.height = actualHeight - paddingTop - paddingBottom;
		buttonGroup.validateNow();
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

		var parameterStartIndex = -1;
		var parameterLength = -1;
		var parameters = signature.parameters;
		if (activeParameter != -1 && activeParameter < parameters.length) {
			var activeParameterText = parameters[activeParameter].label;
			var paramPattern = new EReg('(\\W|^)${EReg.escape(activeParameterText)}(?=\\W|$)', '');
			var matched = paramPattern.match(signature.label);
			if (matched) {
				var matchedPos = paramPattern.matchedPos();
				var group1Length = paramPattern.matched(1).length;
				parameterStartIndex = matchedPos.pos + group1Length;
				parameterLength = matchedPos.len - group1Length;
			}
		}
		var signatureHelpText = '<p class="pre"><font face="_typewriter">';
		if (parameterStartIndex == -1) {
			signatureHelpText += signature.label;
		} else {
			signatureHelpText += signature.label.substr(0, parameterStartIndex);
			signatureHelpText += "<b>";
			signatureHelpText += signature.label.substr(parameterStartIndex, parameterLength);
			signatureHelpText += "</b>";
			signatureHelpText += signature.label.substr(parameterStartIndex + parameterLength);
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

	private function signatureHelpView_removedFromStageHandler(event:Event):Void {
		// reset the scroll position so that the next signature help is shown
		// from the beginning
		scrollX = minScrollX;
		scrollY = minScrollY;
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
