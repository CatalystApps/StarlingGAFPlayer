package com.catalystapps.gaf.core
{
	import com.catalystapps.gaf.data.GAFAsset;
	import com.catalystapps.gaf.display.GAFMovieClip;
	/**
	 * @author mitvad
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
		
		public static function addGAFAsset(asset: GAFAsset): void
		{
			if(!_assetsCollection[asset.id])
			{
				_assetsCollection[asset.id] = asset;
				
				_assetsTotal++;
			}
		}
		
		public static function getGAFMovieClip(id: String, mappedAssetID: String = ""): GAFMovieClip
		{
			if(_assetsCollection[id])
			{
				return new GAFMovieClip(_assetsCollection[id], mappedAssetID);
			}
			else
			{
				return null;
			}
		}
		
		public static function hasGAFMovieClip(id: String): Boolean
		{
			if(_assetsCollection[id])
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		
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
