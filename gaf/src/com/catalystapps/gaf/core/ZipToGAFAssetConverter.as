package com.catalystapps.gaf.core
{
	import flash.events.ErrorEvent;
	import flash.utils.setTimeout;
	import com.catalystapps.gaf.data.config.CTextureAtlasSource;
	import com.catalystapps.gaf.data.config.CTextureAtlasCSF;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;
	import com.catalystapps.gaf.data.converters.JsonGAFAssetConfigConverter;
	import com.catalystapps.gaf.data.converters.BinGAFAssetConfigConverter;
	import com.catalystapps.gaf.data.GAFAssetConfig;
	import flash.utils.clearTimeout;
	import flash.display.BitmapData;
	import deng.fzip.FZipFile;
	import flash.events.Event;
	import deng.fzip.FZipErrorEvent;
	import flash.utils.ByteArray;
	import com.catalystapps.gaf.data.GAFAsset;
	import com.catalystapps.gaf.data.GAFBundle;
	import com.catalystapps.gaf.data.GAFGFXData;
	import deng.fzip.FZip;
	import deng.fzip.FZipLibrary;
	import flash.events.EventDispatcher;

	/** Dispatched when convertation completed */
    [Event(name="complete", type="flash.events.Event")]

	/** Dispatched when conversion failed for some reason */
    [Event(name="error", type="flash.events.ErrorEvent")]

	/**
	 * The ZipToGAFAssetConverter simply converts loaded GAF file into <code>GAFAsset</code> object that
	 * is used to create <code>GAFMovieClip</code> - animation display object ready to be used in starling display list.
	 * If GAF file is created as Bundle it converts as <code>GAFBundle</code>
	 *
	 * <p>Here is the simple rules to understand what is <code>GAFAsset</code>, <code>GAFBundle</code> and <code>GAFMovieClip</code>:</p>
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

		/**
		 * In process of conversion doesn't create textures (doesn't load in GPU memory).
		 * Be sure to set up <code>ZipToGAFAssetConverter.keepImagesInRAM = true</code> when using this action, otherwise Error will occur
		 */
		public static const ACTION_DONT_LOAD_IN_GPU_MEMORY: String = "actionDontLoadInGPUMemory";

		/**
		 * In process of conversion create textures (load in GPU memory).
		 */
		public static const ACTION_LOAD_ALL_IN_GPU_MEMORY: String = "actionLoadAllInGPUMemory";

		/**
		 * In process of conversion create textures (load in GPU memory) only atlases for default scale and csf
		 */
		public static const ACTION_LOAD_IN_GPU_MEMORY_ONLY_DEFAULT: String = "actionLoadInGPUMemoryOnlyDefault";

		/**
		 * Action that should be applied to atlases in process of conversion. Possible values are action constants.
		 * By default loads in GPU memory only atlases for default scale and csf
		 */
		public static var actionWithAtlases: String = ACTION_LOAD_IN_GPU_MEMORY_ONLY_DEFAULT;

		/**
		 * Indicates keep or not to keep all atlases as BitmapData for further usage.
		 * All saved atlases available through <code>gafgfxData</code> property in <code>GAFAsset</code>
		 * By default converter won't keep images for further usage
		 */
		public static var keepImagesInRAM: Boolean = false;

		//--------------------------------------------------------------------------
		//
		//  PRIVATE VARIABLES
		//
		//--------------------------------------------------------------------------

		private var _zip: FZip;
		private var _zipLoader: FZipLibrary;

		private var currentConfigIndex: uint = 0;
		private var configConvertTimeout: Number;

		private var gafAssetConfigSources: Object;
		private var gafAssetsIDs: Array;

		private var pngImgs: Object;

		private var gfxData: GAFGFXData;

		//private var _gafAsset: GAFAsset;
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
			this.gfxData = new GAFGFXData();
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * Converts GAF file (*.zip) into <code>GAFAsset</code> or <code>GAFBundle</code> depending on file content.
		 * Because conversion process is asynchronous use <code>Event.COMPLETE</code> listener to trigger successful conversion.
		 * Use <code>ErrorEvent.ERROR</code> listener to trigger any conversion fail.
		 *
		 * @param zipByteArray *.zip file binary
		 * @param defaultScale Scale value for <code>GAFAsset</code> that will be set by default
		 * @param defaultContentScaleFactor Content scale factor (csf) value for <code>GAFAsset</code> that will be set by default
		 */
		public function convert(zipByteArray: ByteArray, defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN): void
		{
			this._defaultScale = defaultScale;
			this._defaultContentScaleFactor = defaultContentScaleFactor;

			this._zip = new FZip();
			this._zip.addEventListener(FZipErrorEvent.PARSE_ERROR, this.onParseError);
			this._zip.loadBytes(zipByteArray);

			this._zipLoader = new FZipLibrary();
			this._zipLoader.formatAsBitmapData(".png");
			this._zipLoader.addEventListener(Event.COMPLETE, this.onZipLoadedComplete);
			this._zipLoader.addEventListener(FZipErrorEvent.PARSE_ERROR, this.onParseError);
			this._zipLoader.addZip(this._zip);
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		private function parseZip(): void
		{
			var length: uint = this._zip.getFileCount();

			var zipFile: FZipFile;

			var fileName: String;
			var bmp: BitmapData;

			this.pngImgs = new Object();

			this.gafAssetConfigSources = new Object();
			this.gafAssetsIDs = new Array();

			for (var i: uint = 0; i < length; i++)
			{
				zipFile = this._zip.getFileAt(i);

				if (zipFile.filename.indexOf(".png") != -1)
				{
					fileName = zipFile.filename.substring(zipFile.filename.lastIndexOf("/") + 1);
					bmp = this._zipLoader.getBitmapData(zipFile.filename);

					this.pngImgs[fileName] = bmp;
				}
				else if (zipFile.filename.indexOf(".json") != -1)
				{
					this.gafAssetsIDs.push(zipFile.filename);

					this.gafAssetConfigSources[zipFile.filename] = zipFile.getContentAsString();
				}
				else if (zipFile.filename.indexOf(".gaf") != -1)
				{
					this.gafAssetsIDs.push(zipFile.filename);

					this.gafAssetConfigSources[zipFile.filename] = zipFile.content;
				}
			}

			this.createGAFAsset();
		}

		private function createGAFAsset(): void
		{
			clearTimeout(this.configConvertTimeout);

			var configs: Vector.<GAFAssetConfig>;
			var configSource: Object = this.gafAssetConfigSources[this.gafAssetsIDs[this.currentConfigIndex]];
			var gafAssetID: String = this.getAssetId(this.gafAssetsIDs[this.currentConfigIndex]);

//			try
//			{
				if (configSource is ByteArray)
				{
					configs = BinGAFAssetConfigConverter.convert(gafAssetID, configSource as ByteArray, this._defaultScale, this._defaultContentScaleFactor);
				}
				else
				{
					configs = JsonGAFAssetConfigConverter.convert(gafAssetID, configSource as String, this._defaultScale, this._defaultContentScaleFactor);
				}
//			}
//			catch(error: Error)
//			{
//				this.zipProcessError(error.message, 4);
//				
//				return;
//			}

			///////////////////////////////////

			var assets: Vector.<GAFAsset> = new <GAFAsset>[];

			for each (var config: GAFAssetConfig in configs)
			{
				assets.push(this.createAsset(config));
			}

			/*if (this.gafAssetsIDs.length > 1 || assets.length > 1)
			{*/
				if (!this._gafBundle)
				{
					this._gafBundle = new GAFBundle();
				}

				for each (var asset: GAFAsset in assets)
				{
					this._gafBundle.addGAFAsset(asset);
					asset.gafBundle = this._gafBundle;
				}
			/*}
			else
			{
				this._gafAsset = assets[0];
			}*/

			this.currentConfigIndex++;

			if (this.currentConfigIndex >= this.gafAssetsIDs.length)
			{
				if (!ZipToGAFAssetConverter.keepImagesInRAM)
				{
					this.gfxData.removeImages();

					if (ZipToGAFAssetConverter.actionWithAtlases == ZipToGAFAssetConverter.ACTION_DONT_LOAD_IN_GPU_MEMORY)
					{
						throw new Error("Impossible parameters combination! keepImagesInRAM = false and actionWithAtlases = ACTION_DONT_LOAD_ALL_IN_VIDEO_MEMORY One of the parameters must be changed!");
					}
				}

				this.dispatchEvent(new Event(Event.COMPLETE));
			}
			else
			{
				this.configConvertTimeout = setTimeout(this.createGAFAsset, 40);
			}
		}

		private function createAsset(config: GAFAssetConfig): GAFAsset
		{
			///////////////////////////////////

			for each (var cScale: CTextureAtlasScale in config.allTextureAtlases)
			{
				for each (var cCSF: CTextureAtlasCSF in cScale.allContentScaleFactors)
				{
					for each (var taSource: CTextureAtlasSource in cCSF.sources)
					{
						if (this.pngImgs[taSource.source])
						{
							this.gfxData.addImage(cScale.scale, cCSF.csf, taSource.id, this.pngImgs[taSource.source]);
						}
						else
						{
							this.zipProcessError("There is no PNG file '" + taSource.source + "' in zip", 3);
						}
					}
				}
			}

			///////////////////////////////////

			var asset: GAFAsset = new GAFAsset(config);
			asset.id = config.id;

			asset.gafgfxData = this.gfxData;

			///////////////////////////////////

			switch (ZipToGAFAssetConverter.actionWithAtlases)
			{
				case ZipToGAFAssetConverter.ACTION_LOAD_ALL_IN_GPU_MEMORY:
					asset.loadInVideoMemory(GAFAsset.CONTENT_ALL);
					break;

				case ZipToGAFAssetConverter.ACTION_LOAD_IN_GPU_MEMORY_ONLY_DEFAULT:
					asset.loadInVideoMemory(GAFAsset.CONTENT_DEFAULT);
					break;
			}

			///////////////////////////////////

			return asset;
		}

		private function getAssetId(configName: String): String
		{
			var startIndex: int = configName.lastIndexOf("/");

			if (startIndex < 0)
			{
				startIndex = 0;
			}
			else
			{
				startIndex++;
			}

			var endIndex: int = configName.lastIndexOf(".");

			if (endIndex < 0)
			{
				endIndex = 0x7fffffff;
			}

			return configName.substring(startIndex, endIndex);
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
			if (this._zip.getFileCount())
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
		/*public function get gafAsset(): GAFAsset
		{
			return _gafAsset;
		}*/

		/**
		 * Return converted <code>GAFBundle</code>. If GAF asset file created as single animation - returns null.
		 */
		public function get gafBundle(): GAFBundle
		{
			return _gafBundle;
		}

		/**
		 * Return loaded zip file as <code>FZip</code> object
		 */
		public function get zip(): FZip
		{
			return _zip;
		}

		/**
		 * Return zipLoader object
		 */
		public function get zipLoader(): FZipLibrary
		{
			return _zipLoader;
		}

	}
}
