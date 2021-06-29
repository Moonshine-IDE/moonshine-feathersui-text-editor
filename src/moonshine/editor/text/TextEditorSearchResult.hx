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

package moonshine.editor.text;

class TextEditorSearchResult {
	// Which occurance is selected now?
	public var selectedIndex:Int = -1;

	public var startLineIndex:Int = -1;
	public var startCharIndex:Int = -1;

	public var endLineIndex:Int = -1;
	public var endCharIndex:Int = -1;

	public var didWrap:Bool = false;

	public var results:Array<{pos:Int, len:Int}>;
	public var replaced:Array<{pos:Int, len:Int}>;

	public var search:EReg;
	public var backwards:Bool;
	public var allowWrap:Bool;

	public function new(search:EReg, backwards:Bool, allowWrap:Bool, ?results:Array<{pos:Int, len:Int}>, ?replaced:Array<{pos:Int, len:Int}>) {
		this.search = search;
		this.backwards = backwards;
		this.allowWrap = allowWrap;
		if (results == null) {
			results = [];
		}
		this.results = results;
		if (replaced == null) {
			replaced = [];
		}
		this.replaced = replaced;
	}
}
