package com.catalystapps.gaf.data.config
{
	/**
	 * @private
	 */
	public class CAnimationObject
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

		private var _instanceID: String;
		private var _staticObjectID: String;
		private var _type: String;
		private var _mask: Boolean;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function CAnimationObject(instanceID: String, staticObjectID: String, type: String, mask: Boolean)
		{
			this._instanceID = instanceID;
			this._staticObjectID = staticObjectID;
			this._type = type;
			this._mask = mask;
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

		public function get instanceID(): String
		{
			return _instanceID;
		}

		public function get staticObjectID(): String
		{
			return _staticObjectID;
		}

		public function get mask(): Boolean
		{
			return _mask;
		}

		public function get type(): String
		{
			return _type;
		}
	}
}
