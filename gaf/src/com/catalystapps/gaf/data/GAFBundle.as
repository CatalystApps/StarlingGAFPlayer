package com.catalystapps.gaf.data
{
	/**
	 * GAFBundle is utility class that used to save all converted GAFTimelines from bundle in one place with easy access after conversion complete
	 */
	public class GAFBundle
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

		private var _timelines: Vector.<GAFTimeline>;
		private var _timelinesDictionary: Object;

		private var _timelinesByLinkage: Object;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/** @private */
		public function GAFBundle()
		{
			this._timelines = new Vector.<GAFTimeline>();
			this._timelinesDictionary = {};
			this._timelinesByLinkage = {};
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * Disposes all assets in bundle
		 */
		public function dispose(): void
		{
			for each (var timeline: GAFTimeline in this._timelines)
			{
				timeline.dispose();
			}
		}

		/** @private */
		public function addGAFTimeline(timeline: GAFTimeline): void
		{
			if (!this._timelinesDictionary[timeline.uniqueID])
			{
				this._timelinesDictionary[timeline.uniqueID] = timeline;
				this._timelines.push(timeline);

				if (timeline.config.linkage)
				{
					this._timelinesByLinkage[timeline.uniqueLinkage] = timeline;
				}
			}
			else
			{
				throw new Error("Bundle error. More then one timeline use id: '" + timeline.uniqueID + "'");
			}
		}

		/**
		 * Returns <code>GAFTimeline</code> from bundle by ID
		 */
		public function getGAFTimelineByID(timelineID: String, id: String): GAFTimeline
		{
			return this._timelinesDictionary[timelineID + "::" + id];
		}

		/**
		 * Returns <code>GAFTimeline</code> from bundle by ID
		 */
		public function getGAFTimelineByLinkage(timelineID: String, linkage: String): GAFTimeline
		{
			return this._timelinesByLinkage[timelineID + "::" + linkage];
		}

		/**
		 * Returns <code>GAFTimeline</code> from bundle by ID
		 */
		public function getGAFTimelineByUniqueID(uniqueID: String): GAFTimeline
		{
			return this._timelinesDictionary[uniqueID];
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
		 * Returns all <code>GAFAsset's</code> from bundle as <code>Vector</code>
		 */
		public function get timelines(): Vector.<GAFTimeline>
		{
			return _timelines;
		}

	}
}
