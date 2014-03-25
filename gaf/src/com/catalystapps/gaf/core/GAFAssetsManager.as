package com.catalystapps.gaf.core
{
	import com.catalystapps.gaf.data.GAFAsset;
	import com.catalystapps.gaf.display.GAFMovieClip;

	/**
	 * Utility class that allows easily manage all <code>GAFAsset's</code>
	 */
	public class GAFAssetsManager
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

		private static var _assetsCollection: Object = {};
		private static var _assetsTotal: uint = 0;

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
		 * Add <code>GAFAsset</code> into assets collection
		 */
		public static function addGAFAsset(asset: GAFAsset): void
		{
			if (!_assetsCollection[asset.id])
			{
				_assetsCollection[asset.id] = asset;

				_assetsTotal++;
			}
			else
			{
				throw new Error("Trying to add asset that already exist in collection. Asset ID: " + asset.id);
			}
		}

		/**
		 * Returns instance of <code>GAFMovieClip</code>. In case when <code>GAFAsset</code> with specified ID is absent - returns <code>null</code>
		 *
		 * @param id Asset ID
		 * @param mappedAssetID To be defined
		 */
		public static function getGAFMovieClip(id: String, mappedAssetID: String = ""): GAFMovieClip
		{
			if (_assetsCollection[id])
			{
				return new GAFMovieClip(_assetsCollection[id], mappedAssetID);
			}
			else
			{
				return null;
			}
		}

		/**
		 * Check is there asset in collection
		 *
		 * @param id Asset ID
		 */
		public static function hasGAFAsset(id: String): Boolean
		{
			if (_assetsCollection[id])
			{
				return true;
			}
			else
			{
				return false;
			}
		}

		/**
		 * Total number of assets in collection
		 */
		public static function get assetsTotal(): uint
		{
			return _assetsTotal;
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
