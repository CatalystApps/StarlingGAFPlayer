package com.catalystapps.gaf.core
{
	import deng.fzip.FZip;
	import deng.fzip.FZipErrorEvent;
	import deng.fzip.FZipFile;
	import deng.fzip.FZipLibrary;

	import starling.textures.Texture;
	
	import com.catalystapps.gaf.data.GAFAsset;
	import com.catalystapps.gaf.data.GAFAssetConfig;
	import com.catalystapps.gaf.data.GAFBundle;
	import com.catalystapps.gaf.data.config.CTextureAtlas;
	import com.catalystapps.gaf.data.config.CTextureAtlasCSF;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;
	import com.catalystapps.gaf.data.config.CTextureAtlasSource;

	import flash.display.BitmapData;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	/** Dispatched when convertation completed */
    [Event(name="complete", type="flash.events.Event")]
	
	/** Dispatched when convertation failed for some reason */
    [Event(name="error", type="flash.events.ErrorEvent")]

	/**
	 * The ZipToGAFAssetConverter simply converts loaded GAF file into <code>GAFAsset</code> object that
	 * is used to create <code>GAFMovieClip</code> - animation display object ready to be used in starling display list. 
	 * If GAF file is created as Bundle it converts as <code>GAFBundle</code>
	 * 
	 * <p>Here is the simple rules to understend what is <code>GAFAsset</code>, <code>GAFBundle</code> and <code>GAFMovieClip</code>:</p>
	 * 
	 * <ul>
	 * 	<li><code>GAFAsset</code> - is like a library symbol in Flash IDE. When you load GAF asset file you can not use it directly. 
	 * 		All you need to do is convert it into <code>GAFAsset</code> using ZipToGAFAssetConverter</li>
	 * 	<li><code>GAFBundle</code> - is a storage of all <code>GAFAsset's</code> from Bundle</li>
	 * 	<li><code>GAFMovieClip</code> - is like an instance of Flash <code>MovieClip</code>. 
	 * 		You can create it from <code>GAFAsset</code> and use in <code>Starling Display Object</code></li>
	 * </ul>
	 * 
	 * @see com.catalystapps.gaf.data.GAFAsset
	 * @see com.catalystapps.gaf.data.GAFBundle
	 * @see com.catalystapps.gaf.display.GAFMovieClip
	 * 
	 */
	public class ZipToGAFAssetConverter extends EventDispatcher
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
		
		private var zip: FZip;
		private var zipLoader: FZipLibrary;
		
		private var currentConfigIndex: uint = 0;
		private var configConvertTimeout: Number;
		
		private var texturesDictionary: Object;
		
		private var jsonConfigs: Object;
		private var gafAssetsIDs: Array;
		
		private var pngImgs: Object;
		
		private var _gafAsset: GAFAsset;
		private var _gafBundle: GAFBundle;
		
		private var _defaultScale: Number;
		private var _defaultContentScaleFactor: Number;
		
		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		/** @private */
		public function ZipToGAFAssetConverter()
		{
			this.texturesDictionary = new Object();
		}
		
		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Converts GAF file (*.zip) into <code>GAFAsset</code> or <code>GAFBundle</code> depending on file content.
		 * Because convertation process is asynchronous use <code>Event.COMPLETE</code> listener to trigger successful convertation.
		 * Use <code>ErrorEvent.ERROR</code> listener to trigger any convertation fail.
		 * 
		 * @param zipByteArray *.zip file binary
		 * @param defaultScale Scale value for <code>GAFAsset</code> that will be set by default
		 * @param defaultContentScaleFactor Content scale factor (csf) value for <code>GAFAsset</code> that will be set by default
		 */
		public function convert(zipByteArray: ByteArray, defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN): void
		{
			this._defaultScale = defaultScale;
			this._defaultContentScaleFactor = defaultContentScaleFactor;
			
			this.zip = new FZip();
			this.zip.addEventListener(FZipErrorEvent.PARSE_ERROR, this.onParseError);			
			this.zip.loadBytes(zipByteArray);
			
			this.zipLoader = new FZipLibrary();
			this.zipLoader.formatAsBitmapData(".png");
			this.zipLoader.addEventListener(Event.COMPLETE, this.onZipLoadedComplete);
			this.zipLoader.addEventListener(FZipErrorEvent.PARSE_ERROR, this.onParseError);
			this.zipLoader.addZip(this.zip);
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------
		
		private function parseZip() : void 
		{		
			var length: uint = this.zip.getFileCount();
			
			var zipFile: FZipFile;
			
			var fileName: String;
			var bmp: BitmapData;
			
			this.pngImgs = new Object();
			
			this.jsonConfigs = new Object();
			this.gafAssetsIDs = new Array();
			
			for(var i: uint = 0; i < length; i++)
			{
				zipFile = this.zip.getFileAt(i);
				
				if(zipFile.filename.indexOf(".png") != -1)
				{
					fileName = zipFile.filename.substring(zipFile.filename.lastIndexOf("/") + 1);
					bmp = this.zipLoader.getBitmapData(zipFile.filename);
					
					this.pngImgs[fileName] = bmp;
				}
				else if(zipFile.filename.indexOf(".json") != -1)
				{
					this.gafAssetsIDs.push(zipFile.filename);
					
					this.jsonConfigs[zipFile.filename] = zipFile.getContentAsString();
				}
			}
			
			this.createGAFAsset();
		}
		
		private function createGAFAsset(): void
		{
			clearTimeout(this.configConvertTimeout);
			
			var config: GAFAssetConfig;
			
			try
			{
				config = GAFAssetConfig.convert(this.jsonConfigs[this.gafAssetsIDs[this.currentConfigIndex]], this._defaultScale, this._defaultContentScaleFactor);
			}
			catch(error: Error)
			{
				this.zipProcessError(error.message, 4);
				
				return;
			}
			
			for each(var cScale: CTextureAtlasScale in config.allTextureAtlases)
			{
				for each(var cCSF: CTextureAtlasCSF in cScale.allContentScaleFactors)
				{
					var texturesDictionary: Object = new Object();
					var imagesDictionary: Object = new Object();
					
					for each(var taSource: CTextureAtlasSource in cCSF.sources)
					{
						texturesDictionary[taSource.id] = this.getTexture(cScale.scale, cCSF.csf, taSource);
						
						imagesDictionary[taSource.id] = this.pngImgs[taSource.source];
					}
					
					cCSF.atlas = CTextureAtlas.createFromTextures(texturesDictionary, cScale);
					
					if(GAFAsset.debug)
					{
						cCSF.atlas.imgs = imagesDictionary;
					}
				}
			}
			
			var asset: GAFAsset = new GAFAsset(config);
			asset.id = this.getAssetId(this.gafAssetsIDs[this.currentConfigIndex]);
			
			if(this.gafAssetsIDs.length > 1)
			{
				if(!this._gafBundle)
				{
					this._gafBundle = new GAFBundle();
				}
				
				this._gafBundle.addGAFAsset(asset);
			}
			else
			{
				this._gafAsset = asset;
			}
			
			this.currentConfigIndex++;
			
			if(this.currentConfigIndex >= this.gafAssetsIDs.length)
			{
				this.dispatchEvent(new Event(Event.COMPLETE));
			}
			else
			{
				this.configConvertTimeout = setTimeout(this.createGAFAsset, 40);
			}
		}
		
		private function getAssetId(configName: String): String
		{
			var startIndex: int = configName.lastIndexOf("/");
			
			if(startIndex < 0)
			{
				startIndex = 0;
			}
			else
			{
				startIndex++;
			}
			
			var endIndex: int = configName.lastIndexOf(".");
			
			if(endIndex < 0)
			{
				endIndex = 0x7fffffff;
			}
			
			return configName.substring(startIndex, endIndex);
		}
		
		private function getTexture(scale: Number, csf: Number, taSource: CTextureAtlasSource): Texture
		{
			if(!this.texturesDictionary[scale])
			{
				this.texturesDictionary[scale] = new Object();
			}
			
			if(!this.texturesDictionary[scale][csf])
			{
				this.texturesDictionary[scale][csf] = new Object();
			}
			
			if(!this.texturesDictionary[scale][csf][taSource.id])
			{
				var img: BitmapData = this.pngImgs[taSource.source];
						
				if(!img)
				{
					this.zipProcessError("There is no PNG file '" + taSource.source + "' in zip", 3);
		
					return null;
				}
						
				this.texturesDictionary[scale][csf][taSource.id] = CTextureAtlas.textureFromImg(img, csf);
			}
			
			return this.texturesDictionary[scale][csf][taSource.id];
		}
		
		private function zipProcessError(text: String, id: int = 0):void
		{
			this.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, text, id));
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
		
		private function onZipLoadedComplete(event: Event): void
		{
			if(this.zip.getFileCount())
			{				
				this.parseZip();
			}
			else
			{
				this.zipProcessError("zero file count in zip", 2);				
			}
		}
		
		private function onParseError(event: FZipErrorEvent): void
		{
			this.zipProcessError("onParseError", 1);
		}

		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Return converted <code>GAFAsset</code>. If GAF asset file created as Bundle - returns null.
		 */
		public function get gafAsset(): GAFAsset
		{
			return _gafAsset;
		}
		
		/**
		 * Return converted <code>GAFBundle</code>. If GAF asset file created as singl animation - returns null.
		 */
		public function get gafBundle(): GAFBundle
		{
			return _gafBundle;
		}
		
	}
}
