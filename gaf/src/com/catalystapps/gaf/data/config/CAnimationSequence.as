package com.catalystapps.gaf.data.config
{
	/**
	 * @author mitvad
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
		
		public function CAnimationSequence(id: String , startFrameNo: uint, endFrameNo: uint)
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
		
		public function isSequenceFrame(frameNo: uint): Boolean
		{
			// first frame is "1" !!!
			
			if(frameNo >= this._startFrameNo && frameNo <= this._endFrameNo)
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
		
		public function get id(): String
		{
			return _id;
		}

		public function get startFrameNo(): uint
		{
			return _startFrameNo;
		}

		public function get endFrameNo(): uint
		{
			return _endFrameNo;
		}
		
	}
}
