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
		The result that is currently selected.

		@see `TextEditorSearchResult.selectedIndex`
	**/
	public var current:SearchResultItem = null;

	/**
		All results of the search.
	**/
	public var results:Array<SearchResultItem>;

	/**
		The replaced ranges of the search.
	**/
	public var replaced:Array<SearchResultItem>;

	/**
		Indicates if the search wrapped around to restart at the beginning.
	**/
	public var didWrap:Bool = false;

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
	public function new(search:EReg, backwards:Bool, allowWrap:Bool, ?results:Array<SearchResultItem>, ?replaced:Array<SearchResultItem>) {
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

@:structInit
class SearchResultItem {
	public var index:Int;
	public var length:Int;
	public var startLine:Int;
	public var startChar:Int;
	public var endLine:Int;
	public var endChar:Int;
}
