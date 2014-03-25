package com.catalystapps.gaf.core
{
	import com.catalystapps.gaf.data.GAFAsset;
	import com.catalystapps.gaf.display.GAFTexture;
	import com.catalystapps.gaf.display.IGAFTexture;

	import flash.geom.Matrix;

	import starling.textures.Texture;

	/**
	 * @private
	 */
	public class GAFTextureMapingManager
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

		private static var _tmpTexture: Texture;

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
			if (!_assetsCollection[asset.id])
			{
				_assetsCollection[asset.id] = asset;
			}
		}

		public static function getMappedTexture(id: String, mappedAssetID: String): IGAFTexture
		{
			var result: IGAFTexture;

			var asset: GAFAsset;

			if (mappedAssetID)
			{
				asset = _assetsCollection[mappedAssetID];

				if (asset)
				{
					result = asset.textureAtlas.getTexture(id, "", true);

					if (result)
					{
						return result;
					}
				}
			}
			else
			{
				for each(asset in _assetsCollection)
				{
					result = asset.textureAtlas.getTexture(id, "", true);

					if (result)
					{
						return result;
					}

				}
			}

			// when there is no mapped texture

			if (!_tmpTexture)
			{
				_tmpTexture = Texture.fromColor(10, 50, 0xFF0000);
			}

			result = new GAFTexture("tmpTexture", _tmpTexture, new Matrix());

			return result;
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
