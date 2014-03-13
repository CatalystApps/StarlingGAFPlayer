/**
 * Created by Nazar on 03.03.14.
 */
package com.catalystapps.gaf.data.config
{
	import flash.text.TextFormat;

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

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function CTextFieldObject(id: String, text: String, textFormat: TextFormat, width: Number, height: Number)
		{
			_id = id;
			_text = text;
			_textFormat = textFormat;

			_width = width;
			_height = height;
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
			return _id;
		}

		public function set id(value: String): void
		{
			_id = value;
		}

		public function get text(): String
		{
			return _text;
		}

		public function set text(value: String): void
		{
			_text = value;
		}

		public function get textFormat(): TextFormat
		{
			return _textFormat;
		}

		public function set textFormat(value: TextFormat): void
		{
			_textFormat = value;
		}

		public function get width(): Number
		{
			return _width;
		}

		public function set width(value: Number): void
		{
			_width = value;
		}

		public function get height(): Number
		{
			return _height;
		}

		public function set height(value: Number): void
		{
			_height = value;
		}

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------

		public function get embedFonts(): Boolean
		{
			return _embedFonts;
		}

		public function set embedFonts(value: Boolean): void
		{
			_embedFonts = value;
		}

		public function get multiline(): Boolean
		{
			return _multiline;
		}

		public function set multiline(value: Boolean): void
		{
			_multiline = value;
		}

		public function get wordWrap(): Boolean
		{
			return _wordWrap;
		}

		public function set wordWrap(value: Boolean): void
		{
			_wordWrap = value;
		}

		public function get restrict(): String
		{
			return _restrict;
		}

		public function set restrict(value: String): void
		{
			_restrict = value;
		}

		public function get editable(): Boolean
		{
			return _editable;
		}

		public function set editable(value: Boolean): void
		{
			_editable = value;
		}

		public function get selectable(): Boolean
		{
			return _selectable;
		}

		public function set selectable(value: Boolean): void
		{
			_selectable = value;
		}

		public function get displayAsPassword(): Boolean
		{
			return _displayAsPassword;
		}

		public function set displayAsPassword(value: Boolean): void
		{
			_displayAsPassword = value;
		}

		public function get maxChars(): int
		{
			return _maxChars;
		}

		public function set maxChars(value: int): void
		{
			_maxChars = value;
		}
	}
}
