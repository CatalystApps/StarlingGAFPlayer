package com.catalystapps.gaf.core
{
	import deng.fzip.FZip;
	import deng.fzip.FZipErrorEvent;
	import deng.fzip.FZipFile;
	import deng.fzip.FZipLibrary;

	import com.catalystapps.gaf.data.GAFBundle;
	import com.catalystapps.gaf.data.GAFGFXData;
	import com.catalystapps.gaf.data.GAFTimeline;
	import com.catalystapps.gaf.data.GAFTimelineConfig;
	import com.catalystapps.gaf.data.config.CTextureAtlasCSF;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;
	import com.catalystapps.gaf.data.config.CTextureAtlasSource;
	import com.catalystapps.gaf.data.converters.BinGAFAssetConfigConverter;
	import com.catalystapps.gaf.data.converters.IGAFAssetConfigConverter;
	import com.catalystapps.gaf.data.converters.JsonGAFAssetConfigConverter;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.getQualifiedClassName;
	import flash.utils.setTimeout;

	/** Dispatched when convertation completed */
	[Event(name="complete", type="flash.events.Event")]

	/** Dispatched when conversion failed for some reason */
	[Event(name="error", type="flash.events.ErrorEvent")]

	/**
	 * The ZipToGAFAssetConverter simply converts loaded GAF file into <code>GAFTimeline</code> object that
	 * is used to create <code>GAFMovieClip</code> - animation display object ready to be used in starling display list.
	 * If GAF file is created as Bundle it converts as <code>GAFBundle</code>
	 *
	 * <p>Here is the simple rules to understand what is <code>GAFTimeline</code>, <code>GAFBundle</code> and <code>GAFMovieClip</code>:</p>
	 *
	 * <ul>
	 *    <li><code>GAFTimeline</code> - is like a library symbol in Flash IDE. When you load GAF asset file you can not use it directly.
	 *        All you need to do is convert it into <code>GAFTimeline</code> using ZipToGAFAssetConverter</li>
	 *    <li><code>GAFBundle</code> - is a storage of all <code>GAFTimeline's</code> from Bundle</li>
	 *    <li><code>GAFMovieClip</code> - is like an instance of Flash <code>MovieClip</code>.
	 *        You can create it from <code>GAFTimeline</code> and use in <code>Starling Display Object</code></li>
	 * </ul>
	 *
	 * @see com.catalystapps.gaf.data.GAFTimeline
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
		 * Defines the values to use for specifying a texture format.
		 * If you prefer to use 16 bit-per-pixel textures just set
		 * <code>GAFGFXData.BGR_PACKED</code> or <code>GAFGFXData.BGRA_PACKED</code>.
		 * It will cut texture memory usage in half.
		 */
		public var textureFormat: String = GAFGFXData.BGRA;

		/**
		 * Indicates keep or not to keep all atlases as BitmapData for further usage.
		 * All saved atlases available through <code>gafgfxData</code> property in <code>GAFTimeline</code>
		 * By default converter won't keep images for further usage
		 */
		public static var keepImagesInRAM: Boolean = false;

		//--------------------------------------------------------------------------
		//
		//  PRIVATE VARIABLES
		//
		//--------------------------------------------------------------------------
		private var _id: String;

		private var _zip: FZip;
		private var _zipLoader: FZipLibrary;

		private var currentConfigIndex: uint = 0;
		private var configConvertTimeout: Number;

		private var gafAssetConfigSources: Object;
		private var gafAssetConfigs: Object;
		private var gafAssetsIDs: Array;

		private var pngImgs: Object;
		private var atfData: Object;

		private var gfxData: GAFGFXData;

		//private var _gafAsset: GAFAsset;
		private var _gafBundle: GAFBundle;

		private var _defaultScale: Number;
		private var _defaultContentScaleFactor: Number;

		///////////////////////////////////

		private var gafAssetsConfigURLs: Array;
		private var gafAssetsConfigIndex: uint = 0;
		private var gafAssetsConfigURLLoader: URLLoader;

		private var atlasSourceURLs: Array;
		private var atlasSourceIndex: uint = 0;
		private var atlasSourceLoader: Loader;
		private var atfSourceLoader: URLLoader;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/** @private */
		public function ZipToGAFAssetConverter(id: String = null)
		{
			this.id = id;
			this.gfxData = new GAFGFXData();

			this.gafAssetConfigs = {};

			this.gafAssetConfigSources = {};
			this.gafAssetsIDs = [];

			this.pngImgs = {};
			this.atfData = {};
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * Converts GAF file (*.zip) into <code>GAFTimeline</code> or <code>GAFBundle</code> depending on file content.
		 * Because conversion process is asynchronous use <code>Event.COMPLETE</code> listener to trigger successful conversion.
		 * Use <code>ErrorEvent.ERROR</code> listener to trigger any conversion fail.
		 *
		 * @param data *.zip file binary or File object represents a path to a *.gaf/*.json file or directory with *.gaf/*.json config files
		 * @param defaultScale Scale value for <code>GAFTimeline</code> that will be set by default
		 * @param defaultContentScaleFactor Content scale factor (csf) value for <code>GAFTimeline</code> that will be set by default
		 */
		public function convert(data: *, defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN): void
		{
			if (ZipToGAFAssetConverter.actionWithAtlases == ZipToGAFAssetConverter.ACTION_DONT_LOAD_IN_GPU_MEMORY)
			{
				throw new Error("Impossible parameters combination! keepImagesInRAM = false and actionWithAtlases = ACTION_DONT_LOAD_ALL_IN_VIDEO_MEMORY One of the parameters must be changed!");
			}

			this._defaultScale = defaultScale;
			this._defaultContentScaleFactor = defaultContentScaleFactor;

			if (data is ByteArray)
			{
				this._zip = new FZip();
				this._zip.addEventListener(FZipErrorEvent.PARSE_ERROR, this.onParseError);
				this._zip.loadBytes(data);

				this._zipLoader = new FZipLibrary();
				this._zipLoader.formatAsBitmapData(".png");
				this._zipLoader.addEventListener(Event.COMPLETE, this.onZipLoadedComplete);
				this._zipLoader.addEventListener(FZipErrorEvent.PARSE_ERROR, this.onParseError);
				this._zipLoader.addZip(this._zip);
			}
			else if (data is Array || getQualifiedClassName(data) == "flash.filesystem::File")
			{
				this.gafAssetsConfigURLs = [];

				if (data is Array)
				{
					for each(var file: * in data)
					{
						this.processFile(file);
					}
				}
				else
				{
					this.processFile(data);
				}

				if (this.gafAssetsConfigURLs.length)
				{
					this.loadConfig();
				}
				else
				{
					this.zipProcessError("No GAF animation files found", 5);
				}
			}
			else if (data is Object && data.configs && data.atlases)
			{
				this.parseObject(data);
			}
			else
			{
				this.zipProcessError("Unknown data format.", 6);
			}
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		private function parseObject(data: Object): void
		{
			this.pngImgs = {};

			for each (var configObj: Object in data.configs)
			{
				this.gafAssetsIDs.push(configObj.name);

				var ba: ByteArray = configObj.config as ByteArray;
				ba.position = 0;

				if (configObj.type == "json")
				{
					this.gafAssetConfigSources[configObj.name] = ba.readUTFBytes(ba.length);
				}
				else if (configObj.type == "gaf")
				{
					this.gafAssetConfigSources[configObj.name] = ba;
				}
			}

			for each(var atlasObj: Object in data.atlases)
			{
				this.pngImgs[atlasObj.name] = atlasObj.bitmapData;
			}

			///////////////////////////////////

			this.convertConfig();
		}

		//--------------------------------------------------------------------------
		//
		//
		//
		//--------------------------------------------------------------------------

		private function processFile(data: *): void
		{
			if (getQualifiedClassName(data) == "flash.filesystem::File")
			{
				if (!data["exists"] || data["isHidden"])
				{
					this.zipProcessError("File or directory not found: '" + data["url"] + "'", 4);
				}
				else
				{
					var url: String;

					if (data["isDirectory"])
					{
						var files: Array = data["getDirectoryListing"]();

						for each (var file: * in files)
						{
							if (file["exists"] && !file["isHidden"] && !file["isDirectory"])
							{
								url = file["url"];

								if (this.isConfigURL(url))
								{
									this.gafAssetsConfigURLs.push(url);
								}
							}
						}
					}
					else
					{
						url = data["url"];

						if (this.isConfigURL(url))
						{
							this.gafAssetsConfigURLs.push(url);
						}
					}
				}
			}
		}

		private function loadConfig(): void
		{
			var url: String = this.gafAssetsConfigURLs[this.gafAssetsConfigIndex];

			this.gafAssetsConfigURLLoader = new URLLoader();

			if (this.isJSONConfig(url))
			{
				this.gafAssetsConfigURLLoader.dataFormat = URLLoaderDataFormat.TEXT;
			}
			else
			{
				this.gafAssetsConfigURLLoader.dataFormat = URLLoaderDataFormat.BINARY;
			}

			this.gafAssetsConfigURLLoader.addEventListener(IOErrorEvent.IO_ERROR, this.onConfigIoError);
			this.gafAssetsConfigURLLoader.addEventListener(Event.COMPLETE, this.onConfigUrlLoaderComplete);
			this.gafAssetsConfigURLLoader.load(new URLRequest(url));

		}

		private function onConfigUrlLoaderComplete(event: Event): void
		{
			var url: String = this.gafAssetsConfigURLs[this.gafAssetsConfigIndex];

			this.gafAssetsIDs.push(url);

			this.gafAssetConfigSources[url] = this.gafAssetsConfigURLLoader.data;

			this.gafAssetsConfigIndex++;

			if (this.gafAssetsConfigIndex >= this.gafAssetsConfigURLs.length)
			{
				this.convertConfig();
			}
			else
			{
				this.loadConfig();
			}
		}

		private function findAllAtlasURLs(): void
		{
			this.atlasSourceURLs = [];

			var configs: Vector.<GAFTimelineConfig>;

			for (var id: String in this.gafAssetConfigs)
			{
				configs = this.gafAssetConfigs[id];

				for each (var config: GAFTimelineConfig in configs)
				{
					var folderURL: String = this.getFolderURL(id);

					for each(var scale: CTextureAtlasScale in config.allTextureAtlases)
					{
						if (isNaN(this._defaultScale) || scale.scale == this._defaultScale)
						{
							for each (var csf: CTextureAtlasCSF in scale.allContentScaleFactors)
							{
								if (isNaN(this._defaultContentScaleFactor) || csf.csf == this._defaultContentScaleFactor)
								{
									for each (var source: CTextureAtlasSource in csf.sources)
									{
										var url: String = folderURL + source.source;

										if (source.source != "no_atlas"
										&&  this.atlasSourceURLs.indexOf(url) == -1)
										{
											this.atlasSourceURLs.push(url);
										}
									}
								}
							}
						}
					}
				}
			}

			if (this.atlasSourceURLs.length)
			{
				if (textureFormat == GAFGFXData.ATF)
				{
					this.loadATF();
				}
				else
				{
					this.loadPNG();
				}
			}
			else
			{
				this.createGAFTimelines();
			}
		}

		private function loadPNG(): void
		{
			var request: URLRequest = new URLRequest(this.atlasSourceURLs[this.atlasSourceIndex]);
			
			this.atlasSourceLoader = new Loader();
			this.atlasSourceLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.onPNGLoadComplete);
			this.atlasSourceLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, this.onAtlasLoadIOError);
			this.atlasSourceLoader.load(request, new LoaderContext());
		}
		
		private function loadATF(): void
		{
			var url: String = this.atlasSourceURLs[this.atlasSourceIndex];
			var atfURL: String = url.substring(0, url.lastIndexOf(".png")) + ".atf";
			var request: URLRequest = new URLRequest(atfURL);

			this.atfSourceLoader = new URLLoader();
			this.atfSourceLoader.dataFormat = URLLoaderDataFormat.BINARY;
			this.atfSourceLoader.addEventListener(Event.COMPLETE, this.onATFLoadComplete);
			this.atfSourceLoader.addEventListener(IOErrorEvent.IO_ERROR, this.onAtlasLoadIOError);
			this.atfSourceLoader.load(request);
		}

		private function onAtlasLoadIOError(event: IOErrorEvent): void
		{
			this.zipProcessError("Error occured while loading " + this.atlasSourceURLs[this.atlasSourceIndex], 6);
		}

		private function onPNGLoadComplete(event: Event): void
		{
			var url: String = this.atlasSourceURLs[this.atlasSourceIndex];
			var fileName: String = url.substring(url.lastIndexOf("/") + 1);

			this.pngImgs[fileName] = (this.atlasSourceLoader.content as Bitmap).bitmapData;

			this.atlasSourceIndex++;

			if (this.atlasSourceIndex >= this.atlasSourceURLs.length)
			{
				this.createGAFTimelines();
			}
			else
			{
				this.loadPNG();
			}
		}
		
		private function onATFLoadComplete(event: Event): void
		{
			var url: String = this.atlasSourceURLs[this.atlasSourceIndex];
			var fileName: String = url.substring(url.lastIndexOf("/") + 1);

			this.atfData[fileName] = this.atfSourceLoader.data;

			this.atlasSourceIndex++;

			if (this.atlasSourceIndex >= this.atlasSourceURLs.length)
			{
				this.createGAFTimelines();
			}
			else
			{
				this.loadATF();
			}
		}

		private function getFolderURL(url: String): String
		{
			var cutURL: String = url.split("?")[0];

			var lastIndex: int = cutURL.lastIndexOf("/");

			return cutURL.slice(0, lastIndex + 1);
		}

		private function onConfigIoError(event: IOErrorEvent): void
		{
			this.zipProcessError("Error occurred while loading " + this.gafAssetsConfigURLs[this.gafAssetsConfigIndex],
			                     5);
		}

		private function isConfigURL(url: String): Boolean
		{
			return (this.isJSONConfig(url) || this.isGAFConfig(url));
		}

		private function isJSONConfig(url: String): Boolean
		{
			return (url.split("?")[0].split(".").pop().toLowerCase() == "json");
		}

		private function isGAFConfig(url: String): Boolean
		{
			return (url.split("?")[0].split(".").pop().toLowerCase() == "gaf");
		}

		private function parseZip(): void
		{
			var length: uint = this._zip.getFileCount();

			var zipFile: FZipFile;

			var fileName: String;
			var bmp: BitmapData;

			this.pngImgs = {};
			this.atfData = {};

			this.gafAssetConfigSources = {};
			this.gafAssetsIDs = [];

			for (var i: uint = 0; i < length; i++)
			{
				zipFile = this._zip.getFileAt(i);
				fileName = zipFile.filename;

				if (fileName.indexOf(".png") != -1)
				{
					fileName = fileName.substring(fileName.lastIndexOf("/") + 1);
					bmp = this._zipLoader.getBitmapData(zipFile.filename);

					this.pngImgs[fileName] = bmp;
				}
				else if (fileName.toLowerCase().indexOf(".atf") != -1)
				{
					fileName = fileName.substring(fileName.lastIndexOf("/") + 1, fileName.toLowerCase().lastIndexOf(".atf")) + ".png";
					
					this.atfData[fileName] = zipFile.content;
				}
				else if (fileName.indexOf(".json") != -1)
				{
					this.gafAssetsIDs.push(fileName);

					this.gafAssetConfigSources[fileName] = zipFile.getContentAsString();
				}
				else if (fileName.indexOf(".gaf") != -1)
				{
					this.gafAssetsIDs.push(fileName);

					this.gafAssetConfigSources[fileName] = zipFile.content;
				}
			}
			///////////////////////////////////

			this.convertConfig();
		}

		private function convertConfig(): void
		{
			clearTimeout(this.configConvertTimeout);

			var configID: String = this.gafAssetsIDs[this.currentConfigIndex];
			var configSource: Object = this.gafAssetConfigSources[configID];
			var gafAssetID: String = this.getAssetId(this.gafAssetsIDs[this.currentConfigIndex]);

			var converter: IGAFAssetConfigConverter;
			if (configSource is ByteArray)
			{
				converter = new BinGAFAssetConfigConverter(gafAssetID, configSource as ByteArray, this._defaultScale, this._defaultContentScaleFactor);
			}
			else
			{
				converter = new JsonGAFAssetConfigConverter(gafAssetID, configSource as String, this._defaultScale, this._defaultContentScaleFactor);
			}
			
			converter.addEventListener(Event.COMPLETE, onConverted);
			converter.convert();
		}

		private function onConverted(event: Event): void
		{
			var configID: String = this.gafAssetsIDs[this.currentConfigIndex];
			var converter: IGAFAssetConfigConverter = event.target as IGAFAssetConfigConverter;
			converter.removeEventListener(Event.COMPLETE, onConverted);
			
			this.gafAssetConfigs[configID] = converter.config.timelines;

			this.currentConfigIndex++;

			if (this.currentConfigIndex >= this.gafAssetsIDs.length)
			{
				if (this.gafAssetsConfigURLs && gafAssetsConfigURLs.length)
				{
					this.findAllAtlasURLs();
				}
				else
				{
					this.createGAFTimelines();
				}
			}
			else
			{
				this.configConvertTimeout = setTimeout(this.convertConfig, 40);
			}
		}

		private function createGAFTimelines(): void
		{
			var gafTimelineConfigs: Vector.<GAFTimelineConfig>;
			var gafAssetConfigID: String;

			for (var i: uint = 0; i < this.gafAssetsIDs.length; i++)
			{
				gafAssetConfigID = this.gafAssetsIDs[i];
				gafTimelineConfigs = this.gafAssetConfigs[gafAssetConfigID];

				var timelines: Vector.<GAFTimeline> = new Vector.<GAFTimeline>();

				for each (var config: GAFTimelineConfig in gafTimelineConfigs)
				{
					timelines.push(this.createTimeline(config));
				}

				///////////////////////////////////

				if (!this._gafBundle)
				{
					this._gafBundle = new GAFBundle();
				}

				for each (var timeline: GAFTimeline in timelines)
				{
					this._gafBundle.addGAFTimeline(timeline);

					timeline.gafBundle = this._gafBundle;
				}
			}

			if (!ZipToGAFAssetConverter.keepImagesInRAM)
			{
				if (textureFormat == GAFGFXData.ATF)
				{
					this.gfxData.removeATFs();
				}
				else
				{
					this.gfxData.removeImages();
				}
			}

			if (!this._gafBundle.timelines.length)
			{
				throw new Error("No animations found.");
			}

			this.dispatchEvent(new Event(Event.COMPLETE));
		}

		private function createTimeline(config: GAFTimelineConfig): GAFTimeline
		{
			///////////////////////////////////

			for each (var cScale: CTextureAtlasScale in config.allTextureAtlases)
			{
				if (isNaN(this._defaultScale) || this._defaultScale == cScale.scale)
				{
					for each(var cCSF: CTextureAtlasCSF in cScale.allContentScaleFactors)
					{
						if (isNaN(this._defaultContentScaleFactor) || this._defaultContentScaleFactor == cCSF.csf)
						{
							for each (var taSource: CTextureAtlasSource in cCSF.sources)
							{
								if (taSource.source == "no_atlas")
								{
									continue;
								}
								if (this.pngImgs[taSource.source])
								{
									this.gfxData.addImage(cScale.scale, cCSF.csf, taSource.id,
									                      this.pngImgs[taSource.source]);
								}
								else if (this.atfData[taSource.source])
								{
									this.gfxData.addATFData(cScale.scale, cCSF.csf, taSource.id,
									                      this.atfData[taSource.source]);
								}
								else
								{
									this.zipProcessError("There is no texture atlas file '" + taSource.source + "' in zip", 3);
								}
							}
						}
					}
				}
			}

			///////////////////////////////////

			var timeline: GAFTimeline = new GAFTimeline(config);
			timeline.gafgfxData = this.gfxData;

			///////////////////////////////////

			switch (ZipToGAFAssetConverter.actionWithAtlases)
			{
				case ZipToGAFAssetConverter.ACTION_LOAD_ALL_IN_GPU_MEMORY:
					timeline.loadInVideoMemory(GAFTimeline.CONTENT_ALL, NaN, NaN, textureFormat);
					break;

				case ZipToGAFAssetConverter.ACTION_LOAD_IN_GPU_MEMORY_ONLY_DEFAULT:
					timeline.loadInVideoMemory(GAFTimeline.CONTENT_DEFAULT, NaN, NaN, textureFormat);
					break;
			}

			///////////////////////////////////

			return timeline;
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

		private function zipProcessError(text: String, id: int = 0): void
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
		 * Return converted <code>GAFTimeline</code>. If GAF asset file created as Bundle - returns null.
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
		 * Returns the first <code>GAFTimeline</code> in a <code>GAFBundle</code>.
		 */
		public function get gafTimeline(): GAFTimeline
		{
			if (_gafBundle && _gafBundle.timelines.length > 0)
			{
				return _gafBundle.timelines[0];
			}
			
			return null;
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

		/**
		 * Return the id of the converter
		 */
		public function get id(): String
		{
			return _id;
		}

		public function set id(value: String): void
		{
			_id = value;
		}
	}
}
