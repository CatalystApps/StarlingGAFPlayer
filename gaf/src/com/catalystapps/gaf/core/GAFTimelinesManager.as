package com.catalystapps.gaf.core
{
	import com.catalystapps.gaf.data.GAFTimeline;
	import com.catalystapps.gaf.display.GAFMovieClip;

	/**
	 * Utility class that allows easily manage all <code>GAFTimeline's</code>
	 */
	public class GAFTimelinesManager
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

		private static var _timelinesCollection: Object = {};
		private static var _timelinesTotal: uint = 0;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * Add <code>GAFTimeline</code> into timelines collection
		 */
		public static function addGAFTimeline(timeline: GAFTimeline): void
		{
			if (!_timelinesCollection[timeline.id])
			{
				_timelinesCollection[timeline.id] = timeline;

				_timelinesTotal++;
			}
			else
			{
				throw new Error("Trying to add timeline that already exist in collection. Timeline ID: " + timeline.id);
			}
		}

		/**
		 * Returns instance of <code>GAFMovieClip</code>. In case when <code>GAFTimeline</code> with specified ID is absent - returns <code>null</code>
		 *
		 * @param id Timeline ID
		 * @return GAFMovieClip
		 */
		public static function getGAFMovieClip(id: String): GAFMovieClip
		{
			if (_timelinesCollection[id])
			{
				return new GAFMovieClip(_timelinesCollection[id]);
			}
			else
			{
				return null;
			}
		}

		/**
		 * Check is there timeline in collection
		 *
		 * @param id Asset ID
		 * @return A Boolean value of true if there is timeline in collection; otherwise, false.
		 */
		public static function hasGAFAsset(id: String): Boolean
		{
			if (_timelinesCollection[id])
			{
				return true;
			}
			else
			{
				return false;
			}
		}

		/**
		 * Total number of timelines in collection
		 * @return number of timelines
		 */
		public static function get timelinesTotal(): uint
		{
			return _timelinesTotal;
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
	}
}
