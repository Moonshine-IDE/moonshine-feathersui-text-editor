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

package moonshine.editor.text.syntax.parser;

import openfl.events.EventDispatcher;

/**
	Base class for line parsers.
**/
class LineParser extends EventDispatcher implements ILineParser {
	private var wordBoundaries:EReg;

	private var patterns:Array<LineParserPattern>;
	private var endPatterns:Array<LineParserPattern>;
	private var keywords:Map<Int, Array<String>>;
	private var caseSensitiveKeywords:Bool = true;

	// Generated based on keywords array
	private var keywordSet:Map<String, Int>;

	// Will start assuming this context
	private var context:Int = 0x1;

	// If nothing is found this context is set
	private var _defaultContext:Int = 0x1;

	/**
		@see `ILineParser.defaultContext`
	**/
	@:flash.property
	public var defaultContext(get, never):Int;

	private function get_defaultContext():Int {
		return _defaultContext;
	}

	private var result:Array<Int>;

	/**
		Creates a new `LineParser` object.
	**/
	public function new() {
		super();
	}

	/**
		@see `ILineParser.setContext()`
	**/
	public function setContext(newContext:Int):Void {
		context = newContext;
	}

	/**
		@see `ILineParser.parse()`
	**/
	public function parse(sourceCode:String, startLine:Int, startChar:Int, endLine:Int, endChar:Int):Array<Int> {
		initializeKeywordSet();
		result = [];

		for (endPattern in endPatterns) {
			if (endPattern.type == context) {
				result.push(0);
				result.push(context);
				findContextEnd(sourceCode, endPattern.expression);
				break;
			}
		}

		if (result.length == 0) {
			splitOnContext(sourceCode);
		}

		context = result[result.length - 1];

		return result;
	}

	private function findContextEnd(source:String, endPattern:EReg):Void {
		if (endPattern.match(source)) {
			var matchPos = endPattern.matchedPos();
			var matchLen = matchPos.len;
			var matchIndex = matchPos.pos;
			splitOnContext(source.substr(matchIndex + matchLen), matchIndex + matchLen);
		}
	}

	private function initializeKeywordSet():Void {
		keywordSet = [];
		for (keywordType in keywords.keys()) {
			var keywordsOfType = keywords.get(keywordType);
			for (keyword in keywordsOfType) {
				if (!caseSensitiveKeywords) {
					keyword = keyword.toLowerCase();
				}
				keywordSet.set(keyword, keywordType);
			}
		}
	}

	/*
		Takes string of source code, assigns styles to this.result.
		Dives instantly when pattern is found, unlike Prettify,
		which nests decoration/result array & then runs over it again.
	 */
	private function splitOnContext(tail:String, pos:Int = 0):Void {
		var style = 0;
		var lastStyle = 0;
		var head:String = "";

		// NOTE: for longer strings this could be a for loop & could break & be returned to,
		// as to make the parsing fully psuedo-threaded.
		while (tail.length > 0) {
			var token:Int = 0;

			for (pattern in patterns) {
				var expression = pattern.expression;
				if (expression.match(tail)) {
					token = expression.matched(0).length;
					lastStyle = style;
					style = pattern.type;
					break;
				}
			}
			if (token == 0) {
				token = 1;
				head += tail.charAt(0);
				lastStyle = style;
				style = _defaultContext;
			} else if (style != lastStyle && lastStyle == _defaultContext) {
				// Decorations are set to this.result instantly by this function
				splitOnKeywords(head, pos - head.length);
				head = "";
			}

			if (style != lastStyle && head.length == 0) {
				result.push(pos);
				result.push(style);
			}

			pos += token;
			tail = tail.substring(token);
		}

		// If head exists it means last matched token was unknown (defaultContext),
		// so we see if it contains keywords.
		if (head.length > 0) {
			splitOnKeywords(head, pos - head.length);
		}
	}

	private function splitOnKeywords(source:String, posOffset:Int):Void {
		var pos = 0;
		var style = 0;
		var lastStyle = 0;
		var sourceLen = source.length;
		while (true) {
			var startPos = pos;
			var endPos = sourceLen;
			var matched = wordBoundaries.matchSub(source, pos);
			if (matched) {
				var currentPos = wordBoundaries.matchedPos();
				endPos = currentPos.pos;
				pos = endPos + currentPos.len;
			} else {
				pos = sourceLen;
			}

			var currentKeyword = source.substring(startPos, endPos);
			if (!caseSensitiveKeywords) {
				currentKeyword = currentKeyword.toLowerCase();
			}
			if (keywordSet.exists(currentKeyword)) {
				style = keywordSet.get(currentKeyword);
			} else if (!~/^\s+$/m.match(currentKeyword)) { // Avoid switching styles for whitespace
				style = _defaultContext;
			}
			// the style before the word boundary (currentKeyword)
			if (style != lastStyle) {
				result.push(posOffset + startPos);
				result.push(style);
			}

			// the style of the word boundary
			style = _defaultContext;
			if (style != lastStyle) {
				result.push(posOffset + endPos);
				result.push(style);
			}

			if (!matched || pos >= sourceLen) {
				break;
			}
		}
	}
}
