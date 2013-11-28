package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.data.config.CTextureAtlas;
	import com.catalystapps.gaf.data.config.CTextureAtlasCSF;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;
	/**
	 * @author mitvad
	 */
	public class GAFAsset
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
		
		private var _id: String;
		private var _config: GAFAssetConfig;
		
		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		public function GAFAsset(config: GAFAssetConfig)
		{
			this._id = id;
			this._config = config;
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		
		public function dispose(): void
		{
			this._config.dispose();
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
		
		public function get id(): String
		{
			return _id;
		}

		public function set id(id: String): void
		{
			_id = id;
		}
		
		public function get textureAtlas(): CTextureAtlas
		{
			return _config.textureAtlas.contantScaleFactor.atlas;
		}

		public function get config(): GAFAssetConfig
		{
			return _config;
		}
		
		////////////////////////////////////////////////////////////////////////////
		
		public function set scale(scale: Number): void
		{
			var csf: Number = this.contentScaleFactor;
			
			var taScale: CTextureAtlasScale = this._config.getTextureAtlasForScale(scale);
			
			if(taScale)
			{
				_config.textureAtlas = taScale;
				
				var taCSF: CTextureAtlasCSF = this._config.textureAtlas.getTextureAtlasForCSF(csf);
				
				if(taCSF)
				{
					_config.textureAtlas.contantScaleFactor = taCSF;
				}
				else
				{
					throw new Error("There is no csf " + csf + "in asset config for scalse " + scale);
				}
			}
			else
			{
				throw new Error("There is no scale " + scale + "in asset config");
			}
		}
		
		public function get scale(): Number
		{
			return _config.textureAtlas.scale;
		}
		
		public function set contentScaleFactor(csf: Number): void
		{
			var taCSF: CTextureAtlasCSF = this._config.textureAtlas.getTextureAtlasForCSF(csf);
			
			if(taCSF)
			{
				_config.textureAtlas.contantScaleFactor = taCSF;
			}
			else
			{
				throw new Error("There is no csf " + csf + "in asset config");
			}
		}
		
		public function get contentScaleFactor(): Number
		{
			return this._config.textureAtlas.contantScaleFactor.csf;
		}
		
		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------
		
		public static var debug: Boolean = false;
	}
}
