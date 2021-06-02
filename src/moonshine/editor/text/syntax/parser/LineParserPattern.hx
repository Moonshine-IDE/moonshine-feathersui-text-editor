/*
	See COPYRIGHT.txt in this directory for full copyright text.

	Pretty resumable parser
	Inspired by Google Code Prettify
	Which was ported by Anirudh Sasikumar to AS3

	Modified and simplified to be able to handle on-the-fly changes,
	by parsing one line at a time, which can be spread out over multiple frames
	as to emulate threading in a Flash runtime.

	You need to populate wordBoundaries, patterns, endPatterns & keywords.
	See AS3LineParser for an example	
 */

package moonshine.editor.text.syntax.parser;

class LineParserPattern {
	public function new(type:Int, expression:EReg) {
		this.type = type;
		this.expression = expression;
	}

	public var type:Int;
	public var expression:EReg;
}
