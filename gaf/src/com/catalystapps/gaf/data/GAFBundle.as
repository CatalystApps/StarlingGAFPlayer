package com.catalystapps.gaf.data
{
	/**
	 * GAFBundle is utility class that used to save all converted GAFAssets from bundle in one place with easy access after convertation complete
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
		
		private var _assets: Vector.<GAFAsset>;
		private var _assetsDictionary: Object;
		
		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		/** @private */
		public function GAFBundle()
		{
			this._assets = new Vector.<GAFAsset>();
			this._assetsDictionary = new Object();
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
			for each(var asset: GAFAsset in this._assets)
			{
				asset.dispose();
			}
		}
		
		/** @private */
		public function addGAFAsset(gafAsset: GAFAsset): void
		{
			if(!this._assetsDictionary[gafAsset.id])
			{
				this._assetsDictionary[gafAsset.id] = gafAsset;
				this._assets.push(gafAsset);
			}
			else
			{
				throw new Error("Bundle error. More then one asset use id: '" + gafAsset.id + "'");
			}
		}
		
		/**
		 * Returns <code>GAFAsset</code> from bundle by ID
		 */
		public function getGAFassetByID(id: String): GAFAsset
		{
			return this._assetsDictionary[id];
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
		public function get assets(): Vector.<GAFAsset>
		{
			return _assets;
		}
		
	}
}
