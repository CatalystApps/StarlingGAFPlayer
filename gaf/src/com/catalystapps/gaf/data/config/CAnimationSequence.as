package com.catalystapps.gaf.data.config
{
	/**
	 * Data object that describe sequence
	 */
	public class CAnimationSequence
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
		private var _startFrameNo: uint;
		private var _endFrameNo: uint;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/**
		 * @private
		 */
		public function CAnimationSequence(id: String, startFrameNo: uint, endFrameNo: uint)
		{
			this._id = id;
			this._startFrameNo = startFrameNo;
			this._endFrameNo = endFrameNo;
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * @private
		 */
		public function isSequenceFrame(frameNo: uint): Boolean
		{
			// first frame is "1" !!!

			if (frameNo >= this._startFrameNo && frameNo <= this._endFrameNo)
			{
				return true;
			}
			else
			{
				return false;
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

		/**
		 * Sequence ID
		 */
		public function get id(): String
		{
			return _id;
		}

		/**
		 * Sequence start frame number
		 */
		public function get startFrameNo(): uint
		{
			return _startFrameNo;
		}

		/**
		 * Sequence start end number
		 */
		public function get endFrameNo(): uint
		{
			return _endFrameNo;
		}

	}
}
