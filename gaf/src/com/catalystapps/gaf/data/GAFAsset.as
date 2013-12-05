package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.data.config.CTextureAtlas;
	import com.catalystapps.gaf.data.config.CTextureAtlasCSF;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;
	
	/**
	 * <p>GAFAsset represents converted GAF file. It is like a library symbol in Flash IDE that contains all information about GAF animation. 
	 * It is used to create <code>GAFMovieClip</code> that is ready animation object to be used in starling display list</p>
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
		
		/**
		 * Creates an GAFAsset object
		 * 
		 * @param config GAF asset config
		 */
		public function GAFAsset(config: GAFAssetConfig)
		{
			this._config = config;
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Disposes the underlying GAF asset config
		 */
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
		
		/**
		 * Asset idintifier (name given at animation's upload or assigned by developer)
		 */
		public function get id(): String
		{
			return _id;
		}

		public function set id(id: String): void
		{
			_id = id;
		}
		
		/** @private */
		public function get textureAtlas(): CTextureAtlas
		{
			return _config.textureAtlas.contantScaleFactor.atlas;
		}
		
		/** @private */
		public function get config(): GAFAssetConfig
		{
			return _config;
		}
		
		////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Texture atlas scale that will be used for <code>GAFMovieClip</code> creation. To create <code>GAFMovieClip's</code>
		 * with different scale assign apropriate scale to <code>GAFAsset</code> and only after that instantiate <code>GAFMovieClip</code>.
		 * Possible values are values from converted animation config. They are depends from project settings on site converter
		 */
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
		
		/**
		 * Texture atlas content scale factor (csf) that will be used for <code>GAFMovieClip</code> creation. To create <code>GAFMovieClip's</code>
		 * with different csf assign apropriate csf to <code>GAFAsset</code> and only after that instantiate <code>GAFMovieClip</code>.
		 * Possible values are values from converted animation config. They are depends from project settings on site converter
		 */
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
		
		/** @private */
		public static var debug: Boolean = false;
	}
}
