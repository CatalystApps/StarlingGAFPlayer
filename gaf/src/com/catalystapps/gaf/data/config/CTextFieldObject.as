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
	}
}
