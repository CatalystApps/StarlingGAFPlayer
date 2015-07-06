/**
 * Created by Nazar on 03.03.14.
 */
package com.catalystapps.gaf.data.config
{
	/**
	 * @private
	 */
	public class CTextFieldObjects
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

		private var _textFieldObjectsDictionary: Object;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function CTextFieldObjects()
		{
			_textFieldObjectsDictionary = {};
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		public function addTextFieldObject(textFieldObject: CTextFieldObject): void
		{
			if (!this._textFieldObjectsDictionary[textFieldObject.id])
			{
				this._textFieldObjectsDictionary[textFieldObject.id] = textFieldObject;
			}
		}

		public function getAnimationObject(id: String): CAnimationObject
		{
			if (this._textFieldObjectsDictionary[id])
			{
				return this._textFieldObjectsDictionary[id];
			}
			else
			{
				return null;
			}
		}

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

		public function get textFieldObjectsDictionary(): Object
		{
			return this._textFieldObjectsDictionary;
		}

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------

	}
}
