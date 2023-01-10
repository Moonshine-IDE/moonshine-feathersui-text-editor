package tests;

import moonshine.editor.text.utils.TextUtil;
import utest.Assert;
import utest.Test;

class TextUtilTestCase extends Test {
	public function testGetFirstIndentAtStartOfLine():Void {
		Assert.equals("\t", TextUtil.getFirstIndentAtStartOfLine("\tabc", 4));
		Assert.equals("    ", TextUtil.getFirstIndentAtStartOfLine("    abc", 4));
		Assert.equals("\t", TextUtil.getFirstIndentAtStartOfLine("\t\tabc", 4));
		Assert.equals("    ", TextUtil.getFirstIndentAtStartOfLine("        abc", 4));
		Assert.equals("\t", TextUtil.getFirstIndentAtStartOfLine("\t    abc", 4));
		Assert.equals("    ", TextUtil.getFirstIndentAtStartOfLine("    \tabc", 4));
		Assert.equals("", TextUtil.getFirstIndentAtStartOfLine("  abc", 4));
		Assert.equals("  ", TextUtil.getFirstIndentAtStartOfLine("  abc", 4, true));
		Assert.equals("    ", TextUtil.getFirstIndentAtStartOfLine("      abc", 4));
		Assert.equals("    ", TextUtil.getFirstIndentAtStartOfLine("      \tabc", 4));
	}

	public function testGetIndentAtStartOfLine():Void {
		Assert.equals("\t", TextUtil.getIndentAtStartOfLine("\tabc", 4));
		Assert.equals("    ", TextUtil.getIndentAtStartOfLine("    abc", 4));
		Assert.equals("\t\t", TextUtil.getIndentAtStartOfLine("\t\tabc", 4));
		Assert.equals("        ", TextUtil.getIndentAtStartOfLine("        abc", 4));
		Assert.equals("\t    ", TextUtil.getIndentAtStartOfLine("\t    abc", 4));
		Assert.equals("    \t", TextUtil.getIndentAtStartOfLine("    \tabc", 4));
		Assert.equals("", TextUtil.getIndentAtStartOfLine("  abc", 4));
		Assert.equals("  ", TextUtil.getIndentAtStartOfLine("  abc", 4, true));
		Assert.equals("    ", TextUtil.getIndentAtStartOfLine("      abc", 4));
		Assert.equals("      ", TextUtil.getIndentAtStartOfLine("      abc", 4, true));
		Assert.equals("      \t", TextUtil.getIndentAtStartOfLine("      \tabc", 4));
	}

	public function testGetIndentCountAtStartOfLine():Void {
		Assert.equals(1, TextUtil.getIndentCountAtStartOfLine("\tabc", 4));
		Assert.equals(1, TextUtil.getIndentCountAtStartOfLine("    abc", 4));
		Assert.equals(2, TextUtil.getIndentCountAtStartOfLine("\t\tabc", 4));
		Assert.equals(2, TextUtil.getIndentCountAtStartOfLine("        abc", 4));
		Assert.equals(2, TextUtil.getIndentCountAtStartOfLine("\t    abc", 4));
		Assert.equals(2, TextUtil.getIndentCountAtStartOfLine("    \tabc", 4));
		Assert.equals(0, TextUtil.getIndentCountAtStartOfLine("  abc", 4));
		Assert.equals(1, TextUtil.getIndentCountAtStartOfLine("  abc", 4, true));
		Assert.equals(1, TextUtil.getIndentCountAtStartOfLine("      abc", 4));
		Assert.equals(2, TextUtil.getIndentCountAtStartOfLine("      abc", 4, true));
		Assert.equals(2, TextUtil.getIndentCountAtStartOfLine("      \tabc", 4));
	}
}
