package com.catalystapps.gaf.data.config
{
	import flash.geom.Point;

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

		public static const TYPE_TEXTURE: String = "texture";
		public static const TYPE_TEXTFIELD: String = "textField";
		public static const TYPE_TIMELINE: String = "timeline";

		//--------------------------------------------------------------------------
		//
		//  PRIVATE VARIABLES
		//
		//--------------------------------------------------------------------------

		private var _instanceID: String;
		private var _regionID: String;
		private var _type: String;
		private var _mask: Boolean;
		private var _maxSize: Point;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function CAnimationObject(instanceID: String, regionID: String, type: String, mask: Boolean)
		{
			this._instanceID = instanceID;
			this._regionID = regionID;
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
			return this._instanceID;
		}

		public function get regionID(): String
		{
			return this._regionID;
		}

		public function get mask(): Boolean
		{
			return this._mask;
		}

		public function get type(): String
		{
			return this._type;
		}

		public function get maxSize(): Point
		{
			return this._maxSize;
		}

		public function set maxSize(value: Point): void
		{
			this._maxSize = value;
		}
	}
}
