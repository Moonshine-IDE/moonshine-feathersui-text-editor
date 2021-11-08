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

/**
	The result returned by find and replace actions on a `TextEditor` component.

	@see `TextEditor.find()`
	@see `TextEditor.findNext()`
	@see `TextEditor.replace()`
	@see `TextEditor.replaceAll()`
**/
class TextEditorSearchResult {
	/**
		The result that is currently selected.
	**/
	public var selectedIndex:Int = -1;

	/**
		The start line index of the result that is currently selected.

		@see `TextEditorSearchResult.selectedIndex`
	**/
	public var startLineIndex:Int = -1;

	/**
		The start character index of the result that is currently selected.

		@see `TextEditorSearchResult.selectedIndex`
	**/
	public var startCharIndex:Int = -1;

	/**
		The end line index of the result that is currently selected.

		@see `TextEditorSearchResult.selectedIndex`
	**/
	public var endLineIndex:Int = -1;

	/**
		The end character index of the result that is currently selected.

		@see `TextEditorSearchResult.selectedIndex`
	**/
	public var endCharIndex:Int = -1;

	/**
		Indicates if the search wrapped around to restart at the beginning.
	**/
	public var didWrap:Bool = false;

	/**
		All results of the search.
	**/
	public var results:Array<{pos:Int, len:Int}>;

	/**
		The replaced ranges of the search.
	**/
	public var replaced:Array<{pos:Int, len:Int}>;

	/**
		The search performed.
	**/
	public var search:EReg;

	/**
		Indicates if the search was backwards or forwards.
	**/
	public var backwards:Bool;

	/**
		Indicates if wrapping was allowed.
	**/
	public var allowWrap:Bool;

	/**
		Creates a new `TextEditorSearchResult` object.
	**/
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
