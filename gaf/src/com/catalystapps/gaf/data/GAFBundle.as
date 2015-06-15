package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.core.gaf_internal;
	import com.catalystapps.gaf.display.IGAFTexture;

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

		private var _gafAssets: Vector.<GAFAsset>;
		private var _gafAssetsDictionary: Object; // GAFAssetConfig by SWF name

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/** @private */
		public function GAFBundle()
		{
			this._gafAssets = new Vector.<GAFAsset>();
			this._gafAssetsDictionary = {};
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
			if (this._gafAssets.length > 0)
			{
				GAF.soundManager.stopAll();

				this._gafAssets[0].timelines[0].gafSoundData.gaf_internal::dispose();

				for each (var gafAsset: GAFAsset in this._gafAssets)
				{
					gafAsset.dispose();
				}
			}
		}

		/**
		 * Returns <code>GAFTimeline</code> from bundle by timelineID
		 * @param swfName is the name of swf file, used to create gaf file
		 * @return GAFTimeline timeline on the stage of swf file
		 */
		[Deprecated(replacement="com.catalystapps.gaf.data.GAFBundle.getGAFTimeline()", since="5.0")]
		public function getGAFTimelineByID(swfName: String): GAFTimeline
		{
			var gafTimeline: GAFTimeline;
			var gafAsset: GAFAsset = this._gafAssetsDictionary[swfName] as GAFAsset;
			if (gafAsset && gafAsset.timelines.length)
			{
				gafTimeline = gafAsset.timelines[0];
			}

			return gafTimeline;
		}

		/**
		 * Returns <code>GAFTimeline</code> from bundle by linkage
		 * @param linkage linkage in a *.fla file library
		 */
		[Deprecated(replacement="com.catalystapps.gaf.data.GAFBundle.getGAFTimeline()", since="5.0")]
		public function getGAFTimelineByLinkage(linkage: String): GAFTimeline
		{
			var i: uint;
			var gafAsset: GAFAsset;
			var gafTimeline: GAFTimeline;
			while (!gafAsset && i < this._gafAssets.length)
			{
				gafAsset = this._gafAssets[i++];
				gafTimeline = gafAsset.getGAFTimelineByLinkage(linkage);
			}

			return gafTimeline;
		}

		/**
		 * Returns <code>GAFTimeline</code> from bundle by <code>swfName</code> and <code>linkage<code/>.
		 * @param swfName is the name of SWF file where original timeline was located (or the name of the *.gaf config file where it is located)
		 * @param linkage is the linkage name of the timeline
		 */
		public function getGAFTimeline(swfName: String, linkage: String): GAFTimeline
		{
			var i: uint;
			var gafTimeline: GAFTimeline;
			var gafAsset: GAFAsset = this._gafAssetsDictionary[swfName];
			if (gafAsset)
			{
				gafTimeline = gafAsset.getGAFTimelineByLinkage(linkage);
			}

			return gafTimeline;
		}

		public function getCustomRegion(swfName: String, linkage: String, scale: Number = NaN, csf: Number = NaN): IGAFTexture
		{
			var gafTexture: IGAFTexture;
			var gafAsset: GAFAsset = this._gafAssetsDictionary[swfName];
			if (gafAsset)
			{
				gafTexture = gafAsset.gaf_internal::getCustomRegion(linkage, scale, csf);
			}

			return gafTexture;
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * Returns <code>GAFTimeline</code> from bundle by linkage
		 * @param linkage linkage in a *.fla file library
		 */
		gaf_internal function getGAFTimelineBySWFNameAndID(swfName: String, id: String): GAFTimeline
		{
			var i: uint;
			var gafTimeline: GAFTimeline;
			var gafAsset: GAFAsset = this._gafAssetsDictionary[swfName];
			if (gafAsset)
			{
				gafTimeline = gafAsset.gaf_internal::getGAFTimelineByID(id);
			}

			return gafTimeline;
		}

		gaf_internal function addGAFAsset(gafAsset: GAFAsset): void
		{
			use namespace gaf_internal;
			if (!this._gafAssetsDictionary[gafAsset.id])
			{
				this._gafAssetsDictionary[gafAsset.id] = gafAsset;
				this._gafAssets.push(gafAsset);
			}
			else
			{
				throw new Error("Bundle error. More then one gaf asset use id: '" + gafAsset.id + "'");
			}
		}

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
			var gafAsset: GAFAsset;
			var timelines: Vector.<GAFTimeline> = new Vector.<GAFTimeline>();

			for (var i: uint = 0, al: uint = this._gafAssets.length; i < al; i++)
			{
				gafAsset = this._gafAssets[i];
				for (var j: uint = 0, tl: uint = gafAsset.timelines.length; j < tl; j++)
				{
					timelines.push(gafAsset.timelines[j]);
				}
			}

			return timelines;
		}
	}
}
