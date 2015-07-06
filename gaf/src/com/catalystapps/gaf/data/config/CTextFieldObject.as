/**
 * Created by Nazar on 03.03.14.
 */
package com.catalystapps.gaf.data.config
{
	import flash.geom.Point;
	import flash.text.TextFormat;

	/**
	 * @private
	 */
	public class CTextFieldObject
	{
		//--------------------------------------------------------------------------
		//
		//  PUBLIC VARIABLES
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  PRIVATE VARIABLES
		//
		//--------------------------------------------------------------------------

		private var _id: String;
		private var _width: Number;
		private var _height: Number;
		private var _text: String;
		private var _embedFonts: Boolean;
		private var _multiline: Boolean;
		private var _wordWrap: Boolean;
		private var _restrict: String;
		private var _editable: Boolean;
		private var _selectable: Boolean;
		private var _displayAsPassword: Boolean;
		private var _maxChars: int;
		private var _textFormat: TextFormat;
		private var _pivotPoint: Point;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function CTextFieldObject(id: String, text: String, textFormat: TextFormat, width: Number,
		                                 height: Number)
		{
			_id = id;
			_text = text;
			_textFormat = textFormat;

			_width = width;
			_height = height;

			_pivotPoint = new Point();
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  EVENT HANDLERS
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------

		public function get id(): String
		{
			return this._id;
		}

		public function set id(value: String): void
		{
			this._id = value;
		}

		public function get text(): String
		{
			return this._text;
		}

		public function set text(value: String): void
		{
			this._text = value;
		}

		public function get textFormat(): TextFormat
		{
			return this._textFormat;
		}

		public function set textFormat(value: TextFormat): void
		{
			this._textFormat = value;
		}

		public function get width(): Number
		{
			return this._width;
		}

		public function set width(value: Number): void
		{
			this._width = value;
		}

		public function get height(): Number
		{
			return this._height;
		}

		public function set height(value: Number): void
		{
			this._height = value;
		}

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------

		public function get embedFonts(): Boolean
		{
			return this._embedFonts;
		}

		public function set embedFonts(value: Boolean): void
		{
			this._embedFonts = value;
		}

		public function get multiline(): Boolean
		{
			return this._multiline;
		}

		public function set multiline(value: Boolean): void
		{
			this._multiline = value;
		}

		public function get wordWrap(): Boolean
		{
			return this._wordWrap;
		}

		public function set wordWrap(value: Boolean): void
		{
			this._wordWrap = value;
		}

		public function get restrict(): String
		{
			return this._restrict;
		}

		public function set restrict(value: String): void
		{
			this._restrict = value;
		}

		public function get editable(): Boolean
		{
			return this._editable;
		}

		public function set editable(value: Boolean): void
		{
			this._editable = value;
		}

		public function get selectable(): Boolean
		{
			return this._selectable;
		}

		public function set selectable(value: Boolean): void
		{
			this._selectable = value;
		}

		public function get displayAsPassword(): Boolean
		{
			return this._displayAsPassword;
		}

		public function set displayAsPassword(value: Boolean): void
		{
			this._displayAsPassword = value;
		}

		public function get maxChars(): int
		{
			return this._maxChars;
		}

		public function set maxChars(value: int): void
		{
			this._maxChars = value;
		}

		public function get pivotPoint(): Point
		{
			return this._pivotPoint;
		}

		public function set pivotPoint(value: Point): void
		{
			this._pivotPoint = value;
		}
	}
}
