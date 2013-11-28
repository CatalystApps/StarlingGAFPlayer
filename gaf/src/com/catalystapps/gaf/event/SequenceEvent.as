package com.catalystapps.gaf.event
{
	import starling.events.Event;

	import com.catalystapps.gaf.data.config.CAnimationSequence;

	/**
	 * @author mitvad
	 */
	public class SequenceEvent extends Event
	{
		//--------------------------------------------------------------------------
		//
		//  PUBLIC VARIABLES
		//
		//--------------------------------------------------------------------------
		
		public static const TYPE_SEQUENCE_START: String = "typeSequenceStart";
		public static const TYPE_SEQUENCE_END: String = "typeSequenceEnd";
		
		//--------------------------------------------------------------------------
		//
		//  PRIVATE VARIABLES
		//
		//--------------------------------------------------------------------------
		
		private var _sequence: CAnimationSequence;
		
		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		public function SequenceEvent(type: String, sequence: CAnimationSequence)
		{
			super(type, false, null);
			
			this._sequence = sequence;
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
		
		public function get sequence(): CAnimationSequence
		{
			return _sequence;
		}
		
	}
}
