package com.catalystapps.gaf.data.config
{
	import com.catalystapps.gaf.core.GAFTextureMappingManager;
	import com.catalystapps.gaf.display.GAFScale9Texture;
	import com.catalystapps.gaf.display.GAFTexture;
	import com.catalystapps.gaf.display.IGAFTexture;

	import flash.display.BitmapData;
	import flash.geom.Matrix;

	import starling.textures.Texture;
	import starling.textures.TextureAtlas;

	/**
	 * @private
	 */
	public class CTextureAtlas
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

		private var _textureAtlasesDictionary: Object;
		private var _textureAtlasConfig: CTextureAtlasCSF;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function CTextureAtlas(textureAtlasesDictionary: Object, textureAtlasConfig: CTextureAtlasCSF)
		{
			this._textureAtlasesDictionary = textureAtlasesDictionary;
			this._textureAtlasConfig = textureAtlasConfig;
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		public static function textureFromImg(img: BitmapData, csf: Number): Texture
		{
			return Texture.fromBitmapData(img, false, false, csf);
		}

		public static function createFromTextures(texturesDictionary: Object,
		                                          textureAtlasConfig: CTextureAtlasCSF): CTextureAtlas
		{
			var atlasesDictionary: Object = {};

			var atlas: TextureAtlas;

			for each(var element: CTextureAtlasElement in textureAtlasConfig.elements.elementsVector)
			{
				if (!atlasesDictionary[element.atlasID])
				{
					atlasesDictionary[element.atlasID] = new TextureAtlas(texturesDictionary[element.atlasID]);
				}

				atlas = atlasesDictionary[element.atlasID];

				atlas.addRegion(element.id, element.region);
			}

			var result: CTextureAtlas = new CTextureAtlas(atlasesDictionary, textureAtlasConfig);

			return result;
		}

		public function dispose(): void
		{
			for each(var textureAtlas: TextureAtlas in this._textureAtlasesDictionary)
			{
				textureAtlas.dispose();
			}
		}

		public function getTexture(id: String, mappedAssetID: String = "", ignoreMapping: Boolean = false): IGAFTexture
		{
			var textureAtlasElement: CTextureAtlasElement = this._textureAtlasConfig.elements.getElement(id);

			if (textureAtlasElement)
			{
				var texture: Texture = this.getTextureByIDAndAtlasID(id, textureAtlasElement.atlasID);

				var pivotMatrix: Matrix;

				if (this._textureAtlasConfig.elements.getElement(id))
				{
					pivotMatrix = this._textureAtlasConfig.elements.getElement(id).pivotMatrix;
				}
				else
				{
					pivotMatrix = new Matrix();
				}

				if (textureAtlasElement.scale9Grid != null)
				{
					return new GAFScale9Texture(id, texture, pivotMatrix, textureAtlasElement.scale9Grid);
				}
				else
				{
					return new GAFTexture(id, texture, pivotMatrix);
				}
			}
			else
			{
				if (ignoreMapping)
				{
					return null;
				}
				else
				{
					return GAFTextureMappingManager.getMappedTexture(id, mappedAssetID);
				}
			}
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		private function getTextureByIDAndAtlasID(id: String, atlasID: String): Texture
		{
			var textureAtlas: TextureAtlas = this._textureAtlasesDictionary[atlasID];

			return textureAtlas.getTexture(id);
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
	}
}
