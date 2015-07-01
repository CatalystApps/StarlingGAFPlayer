package com.catalystapps.gaf.core
{
	import com.catalystapps.gaf.data.GAFAsset;
	import com.catalystapps.gaf.data.GAFBundle;
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

		private static var _bundlesBySwfName: Object = {};

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
		 * Add all <code>GAFTimeline's</code> from bundle into timelines collection
		 * @param bundle
		 */
		public static function addGAFBundle(bundle: GAFBundle): void
		{
			if (bundle)
			{
				for each (var asset: GAFAsset in bundle.gafAssets)
				{
					if (!_bundlesBySwfName[asset.id])
					{
						_bundlesBySwfName[asset.id] = bundle;
					}
					else
					{
						throw new Error("Trying to add GAF asset that already exist in collection. \"swfName\": " + asset.id);
					}
				}
			}
			else
			{
				throw new ArgumentError("Invalid argument value. Value must be not null.");
			}
		}

		/**
		 * Returns <code>GAFTimeline</code> from timelines collection by <code>swfName</code> and <code>linkage</code>.
		 * @param swfName is the name of SWF file where original timeline was located (or the name of the *.gaf config file where it is located).
		 * @param linkage is the linkage name of the timeline. If you need to get the Main Timeline from SWF use the "rootTimeline" linkage name.
		 * @return <code>GAFTimeline</code> from timelines collection
		 */
		public static function getGAFTimeline(swfName: String, linkage: String): GAFTimeline
		{
			var gafTimeline: GAFTimeline;
			var bundle: GAFBundle = _bundlesBySwfName[swfName];
			if (bundle)
			{
				gafTimeline = bundle.getGAFTimeline(swfName, linkage);
			}

			return gafTimeline;
		}

		/**
		 * Returns instance of <code>GAFMovieClip</code>. In case when <code>GAFTimeline</code> with specified swfName and linkage is absent - returns <code>null</code>
		 *
		 * @param swfName is the name of SWF file where original timeline was located (or the name of the *.gaf config file where it is located).
		 * @param linkage is the linkage name of the timeline. If you need to get the Main Timeline from SWF use the "rootTimeline" linkage name.
		 * @return new instance of <code>GAFMovieClip</code>
		 */
		public static function getGAFMovieClip(swfName: String, linkage: String): GAFMovieClip
		{
			var gafMovieClip: GAFMovieClip;
			var gafTimeline: GAFTimeline = getGAFTimeline(swfName, linkage);
			if (gafTimeline)
			{
				gafMovieClip = new GAFMovieClip(gafTimeline);
			}

			return gafMovieClip;
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
