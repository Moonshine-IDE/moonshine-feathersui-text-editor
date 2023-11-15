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

import openfl.events.EventDispatcher;

/**
	A complex line parser with context switches.
**/
class ContextSwitchLineParser extends EventDispatcher implements ILineParser {
	public var switchManager:ContextSwitchManager;
	public var parserManager:InlineParserManager;

	private var context:Int = 0x0;

	// If nothing is found this context is set
	private var _defaultContext:Int = 0x0;

	/**
		@see `ILineParser.defaultContext`
	**/
	@:flash.property
	public var defaultContext(get, never):Int;

	private function get_defaultContext():Int {
		return _defaultContext;
	}

	/**
		Creates a new `ContextSwitchLineParser` object.
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
		var result:Array<Int> = [];
		var tail = sourceCode;
		var pos = 0;
		var curContext = 0;
		var curParser:InlineParser;

		if (switchManager != null) {
			while (tail.length > 0) {
				var firstMatch:{swtch:ContextSwitch, index:Int, length:Int} = null;

				// Skip whitespace, no point in coloring it
				var whiteSpacePattern = ~/^\s+/;
				if (whiteSpacePattern.match(tail)) {
					var whiteSpacePos = whiteSpacePattern.matchedPos();
					if (whiteSpacePos.len == tail.length) {
						break;
					}
					pos += whiteSpacePos.len;
					tail = sourceCode.substr(pos);
				}

				// Get current context, transposing to inline parser mask if available
				curContext = (context != 0) ? context : _defaultContext;
				if (parserManager != null) {
					curParser = parserManager.getParser(curContext);
					if (curParser != null) {
						curContext = curParser.contextMask;
					}
				}

				// Get switches for current context
				var curSwitches = switchManager.getSwitches(curContext);

				// Search for the first matching switch
				if (curSwitches != null) {
					for (swtch in curSwitches) {
						if (swtch.pattern != null) {
							if (swtch.pattern.match(tail)) {
								var matchPos = swtch.pattern.matchedPos();
								if (firstMatch == null || matchPos.pos < firstMatch.index) {
									firstMatch = {
										swtch: swtch,
										index: matchPos.pos,
										length: matchPos.len
									};
								}
							}
						} else {
							firstMatch = {
								swtch: swtch,
								index: 0,
								length: 0
							};
						}

						// Break early if matched at 0 (no point to keep processing, this is the earliest possible match)
						if (firstMatch != null && firstMatch.index == 0) {
							break;
						}
					}
				}

				// Apply the context switch, if one is found
				if (firstMatch != null) {
					var firstSwitch = firstMatch.swtch;
					var matchPos = firstMatch.index;
					var matchLen = firstMatch.length;
					var contextPos = pos + matchPos + (firstSwitch.post ? matchLen : 0);

					if (result.length == 0 && contextPos > 0) {
						result.push(0);
						result.push((context != 0) ? context : _defaultContext);
					}
					context = firstSwitch.to;
					// Avoid redundant context switches
					if (result.length > 0 && result[result.length - 1] != context) {
						if (result[result.length - 2] == contextPos) {
							result[result.length - 1] = context;
						} else {
							result.push(contextPos);
							result.push(context);
						}
					}

					pos += matchPos + matchLen;
					tail = sourceCode.substr(pos);
				} else {
					break;
				}
			}
		}

		if (result.length == 0) {
			result.push(0);
			result.push((context != 0) ? context : _defaultContext);
		}

		// Process inline contexts through inline parsers
		if (parserManager != null) {
			var i = result.length - 1;
			while (i > 0) {
				curContext = result[i];
				curParser = parserManager.getParser(curContext);

				if (curParser != null) {
					var inlinePos = result[i - 1];
					var inlineMask = curParser.contextMask;
					var inlineCutoff = (i < result.length - 1) ? result[i + 1] : sourceCode.length;

					tail = sourceCode.substring(inlinePos, inlineCutoff) + "\n";

					curParser.parser.setContext(curContext & ~inlineMask);
					var inlineResult = curParser.parser.parse(tail, startLine, startChar, endLine, endChar);

					// Remove old results
					result.splice(i - 1, 2);
					// Inject AS parser results, applying offsets and mask
					var n = 0;
					while (n < inlineResult.length) {
						pos = inlineResult[n] + inlinePos;

						if (inlineCutoff < 0 || pos < inlineCutoff) {
							var index = i - 1 + n;
							result.insert(index, pos);
							index++;
							result.insert(index, inlineResult[n + 1] | inlineMask);
						}
						n += 2;
					}

					context = result[result.length - 1];
				}
				i -= 2;
			}
		}

		return result;
	}
}
