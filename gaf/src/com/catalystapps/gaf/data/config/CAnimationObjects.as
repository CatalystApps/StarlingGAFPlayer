package com.catalystapps.gaf.data.config
{
	/**
	 * @private
	 */
	public class CAnimationObjects
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

		private var _animationObjectsDictionary: Object;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function CAnimationObjects()
		{
			this._animationObjectsDictionary = {};
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		public function addAnimationObject(animationObject: CAnimationObject): void
		{
			if (!this._animationObjectsDictionary[animationObject.instanceID])
			{
				this._animationObjectsDictionary[animationObject.instanceID] = animationObject;
			}
		}

		public function getAnimationObject(instanceID: String): CAnimationObject
		{
			if (this._animationObjectsDictionary[instanceID])
			{
				return this._animationObjectsDictionary[instanceID];
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

		public function get animationObjectsDictionary(): Object
		{
			return this._animationObjectsDictionary;
		}

	}
}
