package com.catalystapps.gaf.data
{
	/**
	 * @author mitvad
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
		
		public function dispose(): void
		{
			for each(var asset: GAFAsset in this._assets)
			{
				asset.dispose();
			}
		}
		
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
		
		public function get assets(): Vector.<GAFAsset>
		{
			return _assets;
		}
		
	}
}
