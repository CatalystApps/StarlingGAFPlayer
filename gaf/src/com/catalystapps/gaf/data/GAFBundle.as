package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.sound.SoundManager;
	import com.catalystapps.gaf.core.gaf_internal;
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

		private var _soundManager: SoundManager;
		private var _timelines: Vector.<GAFTimeline>;
		private var _timelinesDictionary: Object = {};
		private var _timelinesByLinkage: Object = {};

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/** @private */
		public function GAFBundle(soundManager: SoundManager)
		{
			this._timelines = new Vector.<GAFTimeline>();
			this._soundManager = soundManager;
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
			use namespace gaf_internal;
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
		 * Returns <code>GAFTimeline</code> from bundle by timelineID
		 * @param timelineID is the name of swf file, used to create gaf file
		 * @return GAFTimeline timeline on the stage of swf file
		 */
		public function getGAFTimelineByID(timelineID: String): GAFTimeline
		{
			return this._timelinesDictionary[timelineID + "::" + 0];
		}

		/** @private
		 * Returns <code>GAFTimeline</code> from bundle by ID
		 */
		gaf_internal function getGAFTimelineByID(assetID: String, id: String): GAFTimeline
		{
			return this._timelinesDictionary[assetID + "::" + id];
		}

		/** @private
		 * Returns <code>GAFTimeline</code> from bundle by ID
		 */
		gaf_internal function getGAFTimelineByLinkage(assetID: String, linkage: String): GAFTimeline
		{
			return this._timelinesByLinkage[assetID + "::" + linkage];
		}

		/**
		 * Returns <code>GAFTimeline</code> from bundle by linkage
		 * @param linkage linkage in a *.fla file library
		 */
		public function getGAFTimelineByLinkage(linkage: String): GAFTimeline
		{
			var i: uint;
			var gafTimeline: GAFTimeline;
			while (!gafTimeline && i < this._timelines.length)
			{
				gafTimeline = this._timelinesByLinkage[this._timelines[i++].assetID + "::" + linkage];
			}
			return gafTimeline;
		}

		/** @private
		 * Returns <code>GAFTimeline</code> from bundle by ID
		 */
		gaf_internal function getGAFTimelineByUniqueID(uniqueID: String): GAFTimeline
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
		 * Returns all <code>GAFTimeline's</code> from bundle as <code>Vector</code>
		 */
		public function get timelines(): Vector.<GAFTimeline>
		{
			return this._timelines;
		}

		public function get soundManager(): SoundManager
		{
			return _soundManager;
		}
	}
}
