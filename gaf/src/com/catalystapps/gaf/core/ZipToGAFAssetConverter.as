package com.catalystapps.gaf.core
{
	import com.catalystapps.gaf.data.GAFAsset;
	import com.catalystapps.gaf.data.GAFAssetConfig;
	import com.catalystapps.gaf.data.GAFBundle;
	import com.catalystapps.gaf.data.GAFGFXData;
	import com.catalystapps.gaf.data.GAFTimeline;
	import com.catalystapps.gaf.data.GAFTimelineConfig;
	import com.catalystapps.gaf.data.config.CSound;
	import com.catalystapps.gaf.data.config.CTextureAtlasCSF;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;
	import com.catalystapps.gaf.data.config.CTextureAtlasSource;
	import com.catalystapps.gaf.data.converters.BinGAFAssetConfigConverter;
	import com.catalystapps.gaf.data.converters.ErrorConstants;
	import com.catalystapps.gaf.data.tagfx.GAFATFData;
	import com.catalystapps.gaf.data.tagfx.TAGFXBase;
	import com.catalystapps.gaf.data.tagfx.TAGFXSourceATFBA;
	import com.catalystapps.gaf.data.tagfx.TAGFXSourceATFURL;
	import com.catalystapps.gaf.data.tagfx.TAGFXSourceBitmapData;
	import com.catalystapps.gaf.data.tagfx.TAGFXSourcePNGBA;
	import com.catalystapps.gaf.data.tagfx.TAGFXSourcePNGURL;
	import com.catalystapps.gaf.sound.GAFSoundData;
	import com.catalystapps.gaf.utils.FileUtils;
	import com.catalystapps.gaf.utils.MathUtility;

	import deng.fzip.FZip;
	import deng.fzip.FZipErrorEvent;
	import deng.fzip.FZipFile;
	import deng.fzip.FZipLibrary;

	import flash.display3D.Context3DTextureFormat;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	import flash.media.Sound;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.setTimeout;

	import starling.core.Starling;

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
		 * Be sure to set up <code>Starling.handleLostContext = true</code> when using this action, otherwise Error will occur
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
		 * <code>Context3DTextureFormat.BGR_PACKED</code> or <code>Context3DTextureFormat.BGRA_PACKED</code>.
		 * It will cut texture memory usage in half.
		 */
		public var textureFormat: String = Context3DTextureFormat.BGRA;

		/**
		 * Indicates keep or not to keep zip file content as ByteArray for further usage.
		 * It's available through get <code>zip</code> property.
		 * By default converter won't keep zip content for further usage.
		 */
		public static var keepZipInRAM: Boolean = false;

		//--------------------------------------------------------------------------
		//
		//  PRIVATE VARIABLES
		//
		//--------------------------------------------------------------------------
		private var _id: String;

		private var _zip: FZip;
		private var _zipLoader: FZipLibrary;

		private var _currentConfigIndex: uint;
		private var _configConvertTimeout: Number;

		private var _gafAssetsIDs: Array;
		private var _gafAssetConfigs: Object;
		private var _gafAssetConfigSources: Object;

		private var _sounds: Object;
		private var _taGFXs: Object;

		private var _gfxData: GAFGFXData;
		private var _soundData: GAFSoundData;

		private var _gafBundle: GAFBundle;

		private var _defaultScale: Number;
		private var _defaultContentScaleFactor: Number;

		private var _parseConfigAsync: Boolean;
		private var _ignoreSounds: Boolean;

		///////////////////////////////////

		private var _gafAssetsConfigURLs: Array;
		private var _gafAssetsConfigIndex: uint;

		private var _atlasSourceURLs: Array;
		private var _atlasSourceIndex: uint;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/** Creates a new <code>ZipToGAFAssetConverter</code> instance.
		 * @param id The id of the converter.
		 * If it is not empty <code>ZipToGAFAssetConverter</code> sets the <code>name</code> of produced bundle equal to this id.
		 */
		public function ZipToGAFAssetConverter(id: String = null)
		{
			this._id = id;
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
		 * @param data *.zip file binary or File object represents a path to a *.gaf file or directory with *.gaf config files
		 * @param defaultScale Scale value for <code>GAFTimeline</code> that will be set by default
		 * @param defaultContentScaleFactor Content scale factor (csf) value for <code>GAFTimeline</code> that will be set by default
		 */
		public function convert(data: *, defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN): void
		{
			if (ZipToGAFAssetConverter.actionWithAtlases == ZipToGAFAssetConverter.ACTION_DONT_LOAD_IN_GPU_MEMORY)
			{
				throw new Error("Impossible parameters combination! Starling.handleLostContext = false and actionWithAtlases = ACTION_DONT_LOAD_ALL_IN_VIDEO_MEMORY One of the parameters must be changed!");
			}

			this.reset();

			this._defaultScale = defaultScale;
			this._defaultContentScaleFactor = defaultContentScaleFactor;

			if (this._id && this._id.length > 0)
			{
				this._gafBundle.name = this._id;
			}

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

				if (!ZipToGAFAssetConverter.keepZipInRAM)
				{
					(data as ByteArray).clear();
				}
			}
			else if (data is Array || getQualifiedClassName(data) == "flash.filesystem::File")
			{
				this._gafAssetsConfigURLs = [];

				if (data is Array)
				{
					for each (var file: * in data)
					{
						this.processFile(file);
					}
				}
				else
				{
					this.processFile(data);
				}

				if (this._gafAssetsConfigURLs.length)
				{
					this.loadConfig();
				}
				else
				{
					this.zipProcessError(ErrorConstants.GAF_NOT_FOUND, 5);
				}
			}
			else if (data is Object && data.configs && data.atlases)
			{
				this.parseObject(data);
			}
			else
			{
				this.zipProcessError(ErrorConstants.UNKNOWN_FORMAT, 6);
			}
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		private function reset(): void
		{
			this._zip = null;
			this._zipLoader = null;
			this._currentConfigIndex = 0;
			this._configConvertTimeout = 0;

			this._sounds = {};
			this._taGFXs = {};

			this._gfxData = new GAFGFXData();
			this._soundData = new GAFSoundData();
			this._gafBundle = new GAFBundle();
			this._gafBundle.soundData = this._soundData;

			this._gafAssetsIDs = [];
			this._gafAssetConfigs = {};
			this._gafAssetConfigSources = {};

			this._gafAssetsConfigURLs = [];
			this._gafAssetsConfigIndex = 0;

			this._atlasSourceURLs = [];
			this._atlasSourceIndex = 0;
		}

		private function parseObject(data: Object): void
		{
			this._taGFXs = {};

			for each (var configObj: Object in data.configs)
			{
				this._gafAssetsIDs.push(configObj.name);

				var ba: ByteArray = configObj.config as ByteArray;
				ba.position = 0;

				if (configObj.type == "gaf")
				{
					this._gafAssetConfigSources[configObj.name] = ba;
				}
				else
				{
					this.zipProcessError(ErrorConstants.UNSUPPORTED_JSON);
				}
			}

			for each (var atlasObj: Object in data.atlases)
			{
				var taGFX: TAGFXBase = new TAGFXSourceBitmapData(atlasObj.bitmapData, this.textureFormat);
				this._taGFXs[atlasObj.name] = taGFX;
			}

			///////////////////////////////////

			this.convertConfig();
		}

		private function processFile(data: *): void
		{
			if (getQualifiedClassName(data) == "flash.filesystem::File")
			{
				if (!data["exists"] || data["isHidden"])
				{
					this.zipProcessError(ErrorConstants.FILE_NOT_FOUND + data["url"] + "'", 4);
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

								if (isGAFConfig(url))
								{
									this._gafAssetsConfigURLs.push(url);
								}
								else if (isJSONConfig(url))
								{
									this.zipProcessError(ErrorConstants.UNSUPPORTED_JSON);
									return;
								}
							}
						}
					}
					else
					{
						url = data["url"];

						if (isGAFConfig(url))
						{
							this._gafAssetsConfigURLs.push(url);
						}
						else if (isJSONConfig(url))
						{
							this.zipProcessError(ErrorConstants.UNSUPPORTED_JSON);
						}
					}
				}
			}
		}

		private function findAllAtlasURLs(): void
		{
			this._atlasSourceURLs = [];

			var url: String;
			var gafTimelineConfigs: Vector.<GAFTimelineConfig>;

			for (var id: String in this._gafAssetConfigs)
			{
				gafTimelineConfigs = this._gafAssetConfigs[id].timelines;

				for each (var config: GAFTimelineConfig in gafTimelineConfigs)
				{
					var folderURL: String = getFolderURL(id);

					for each (var scale: CTextureAtlasScale in config.allTextureAtlases)
					{
						if (isNaN(this._defaultScale) || MathUtility.equals(scale.scale, this._defaultScale))
						{
							for each (var csf: CTextureAtlasCSF in scale.allContentScaleFactors)
							{
								if (isNaN(this._defaultContentScaleFactor) || MathUtility.equals(csf.csf, this._defaultContentScaleFactor))
								{
									for each (var source: CTextureAtlasSource in csf.sources)
									{
										url = folderURL + source.source;

										if (source.source != "no_atlas"
												&& this._atlasSourceURLs.indexOf(url) == -1)
										{
											this._atlasSourceURLs.push(url);
										}
									}
								}
							}
						}
					}
				}
			}

			if (this._atlasSourceURLs.length)
			{
				this.loadNextAtlas();
			}
			else
			{
				this.createGAFTimelines();
			}
		}

		private function loadNextAtlas(): void
		{
			var url: String = this._atlasSourceURLs[this._atlasSourceIndex];
			var fileName: String = url.substring(url.lastIndexOf("/") + 1);

			var textureSize: Point;
			var taGFX: TAGFXBase;
			var FileClass: Class = getDefinitionByName("flash.filesystem::File") as Class;
			var file: * = new FileClass(url);
			if (file["exists"])
			{
				textureSize = FileUtils.getPNGSize(file);
				taGFX = new TAGFXSourcePNGURL(url, textureSize, this.textureFormat);

				this._taGFXs[fileName] = taGFX;
			}
			else
			{
				url = url.substring(0, url.lastIndexOf(".png")) + ".atf";
				file = new FileClass(url);
				if (file["exists"])
				{
					var atfData: GAFATFData = FileUtils.getATFData(file);
					taGFX = new TAGFXSourceATFURL(url, atfData);

					this._taGFXs[fileName] = taGFX;
				}
				else
				{
					this.zipProcessError(ErrorConstants.FILE_NOT_FOUND + url + "'", 4);
				}
			}

			this._atlasSourceIndex++;

			if (this._atlasSourceIndex >= this._atlasSourceURLs.length)
			{
				this.createGAFTimelines();
			}
			else
			{
				this.loadNextAtlas();
			}
		}

		private function loadConfig(): void
		{
			var url: String = this._gafAssetsConfigURLs[this._gafAssetsConfigIndex];
			var gafAssetsConfigURLLoader: URLLoader = new URLLoader();
			gafAssetsConfigURLLoader.dataFormat = URLLoaderDataFormat.BINARY;
			gafAssetsConfigURLLoader.addEventListener(IOErrorEvent.IO_ERROR, this.onConfigIOError);
			gafAssetsConfigURLLoader.addEventListener(Event.COMPLETE, this.onConfigLoadComplete);
			gafAssetsConfigURLLoader.load(new URLRequest(url));
		}

		private function finalizeParsing(): void
		{
			this._taGFXs = null;
			this._sounds = null;

			if (this._zip && !ZipToGAFAssetConverter.keepZipInRAM)
			{
				var file: FZipFile;
				var count: uint = this._zip.getFileCount();
				for (var i: uint = 0; i < count; i++)
				{
					file = this._zip.getFileAt(i);
					if (file.filename.toLowerCase().indexOf(".atf") == -1
							&& file.filename.toLowerCase().indexOf(".png") == -1)
					{
						file.content.clear();
					}
				}
				this._zip.close();
				this._zip = null;
			}

			if (this._gfxData.isTexturesReady)
			{
				this.dispatchEvent(new Event(Event.COMPLETE));
			}
			else
			{
				this._gfxData.addEventListener(GAFGFXData.EVENT_TYPE_TEXTURES_READY, this.onTexturesReady);
			}
		}

		private static function getFolderURL(url: String): String
		{
			var cutURL: String = url.split("?")[0];

			var lastIndex: int = cutURL.lastIndexOf("/");

			return cutURL.slice(0, lastIndex + 1);
		}

		private static function isJSONConfig(url: String): Boolean
		{
			return (url.split("?")[0].split(".").pop().toLowerCase() == "json");
		}

		private static function isGAFConfig(url: String): Boolean
		{
			return (url.split("?")[0].split(".").pop().toLowerCase() == "gaf");
		}

		private function parseZip(): void
		{
			var length: uint = this._zip.getFileCount();

			var zipFile: FZipFile;

			var fileName: String;
			var taGFX: TAGFXBase;

			this._taGFXs = {};

			this._gafAssetConfigSources = {};
			this._gafAssetsIDs = [];

			for (var i: uint = 0; i < length; i++)
			{
				zipFile = this._zip.getFileAt(i);
				fileName = zipFile.filename;

				switch (fileName.substr(fileName.toLowerCase().lastIndexOf(".")))
				{
					case ".png":
						fileName = fileName.substring(fileName.lastIndexOf("/") + 1);
						var pngBA: ByteArray = zipFile.content;
						var pngSize: Point = FileUtils.getPNGBASize(pngBA);
						taGFX = new TAGFXSourcePNGBA(pngBA, pngSize, this.textureFormat);
						this._taGFXs[fileName] = taGFX;
						break;
					case ".atf":
						fileName = fileName.substring(fileName.lastIndexOf("/") + 1, fileName.toLowerCase().lastIndexOf(".atf")) + ".png";
						taGFX = new TAGFXSourceATFBA(zipFile.content);
						this._taGFXs[fileName] = taGFX;
						break;
					case ".gaf":
						this._gafAssetsIDs.push(fileName);
						this._gafAssetConfigSources[fileName] = zipFile.content;
						break;
					case ".json":
						this.zipProcessError(ErrorConstants.UNSUPPORTED_JSON);
						break;
					case ".mp3":
					case ".wav":
						if (!this._ignoreSounds)
						{
							this._sounds[fileName] = zipFile.content;
						}
						break;
				}
			}

			this.convertConfig();
		}

		private function convertConfig(): void
		{
			clearTimeout(this._configConvertTimeout);
			this._configConvertTimeout = NaN;

			var configID: String = this._gafAssetsIDs[this._currentConfigIndex];
			var configSource: Object = this._gafAssetConfigSources[configID];
			var gafAssetID: String = this.getAssetId(this._gafAssetsIDs[this._currentConfigIndex]);

			if (configSource is ByteArray)
			{
				var converter: BinGAFAssetConfigConverter = new BinGAFAssetConfigConverter(gafAssetID, configSource as ByteArray);
				converter.defaultScale = this._defaultScale;
				converter.defaultCSF = this._defaultContentScaleFactor;
				converter.ignoreSounds = this._ignoreSounds;
				converter.addEventListener(Event.COMPLETE, onConverted);
				converter.addEventListener(ErrorEvent.ERROR, onConvertError);
				converter.convert(this._parseConfigAsync);
			}
			else
			{
				throw new Error();
			}
		}

		private function createGAFTimelines(event: Event = null): void
		{
			if (event)
			{
				Starling.current.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, createGAFTimelines);
			}
			if (!Starling.current.contextValid)
			{
				Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE, createGAFTimelines);
			}

			var gafTimelineConfigs: Vector.<GAFTimelineConfig>;
			var gafAssetConfigID: String;
			var gafAssetConfig: GAFAssetConfig;
			var gafAsset: GAFAsset;
			var i: uint;

			for each (var taGFX: TAGFXBase in this._taGFXs)
			{
				taGFX.clearSourceAfterTextureCreated = false;
			}

			for (i = 0; i < this._gafAssetsIDs.length; i++)
			{
				gafAssetConfigID = this._gafAssetsIDs[i];
				gafAssetConfig = this._gafAssetConfigs[gafAssetConfigID];
				gafTimelineConfigs = gafAssetConfig.timelines;

				gafAsset = new GAFAsset(gafAssetConfig);
				for each (var config: GAFTimelineConfig in gafTimelineConfigs)
				{
					gafAsset.addGAFTimeline(this.createTimeline(config, gafAsset));
				}

				this._gafBundle.gaf_internal::addGAFAsset(gafAsset);
			}

			if (!gafAsset || !gafAsset.timelines.length)
			{
				this.zipProcessError(ErrorConstants.TIMELINES_NOT_FOUND);
				return;
			}

			if (this._gafAssetsIDs.length == 1)
			{
				this._gafBundle.name ||= gafAssetConfig.id;
			}

			if (this._soundData.gaf_internal::hasSoundsToLoad && !this._ignoreSounds)
			{
				this._soundData.gaf_internal::loadSounds(this.finalizeParsing, this.onSoundLoadIOError);
			}
			else
			{
				this.finalizeParsing();
			}
		}

		private function createTimeline(config: GAFTimelineConfig, asset: GAFAsset): GAFTimeline
		{
			for each (var cScale: CTextureAtlasScale in config.allTextureAtlases)
			{
				if (isNaN(this._defaultScale) || MathUtility.equals(this._defaultScale, cScale.scale))
				{
					for each(var cCSF: CTextureAtlasCSF in cScale.allContentScaleFactors)
					{
						if (isNaN(this._defaultContentScaleFactor) || MathUtility.equals(this._defaultContentScaleFactor, cCSF.csf))
						{
							for each (var taSource: CTextureAtlasSource in cCSF.sources)
							{
								if (taSource.source == "no_atlas")
								{
									continue;
								}
								if (this._taGFXs[taSource.source])
								{
									var taGFX: TAGFXBase = this._taGFXs[taSource.source];
									taGFX.textureScale = cCSF.csf;
									this._gfxData.addTAGFX(cScale.scale, cCSF.csf, taSource.id, taGFX);
								}
								else
								{
									this.zipProcessError(ErrorConstants.ATLAS_NOT_FOUND + taSource.source + "' in zip", 3);
								}
							}
						}
					}
				}
			}

			var timeline: GAFTimeline = new GAFTimeline(config);
			timeline.gafgfxData = this._gfxData;
			timeline.gafSoundData = this._soundData;
			timeline.gafAsset = asset;

			switch (ZipToGAFAssetConverter.actionWithAtlases)
			{
				case ZipToGAFAssetConverter.ACTION_LOAD_ALL_IN_GPU_MEMORY:
					timeline.loadInVideoMemory(GAFTimeline.CONTENT_ALL);
					break;

				case ZipToGAFAssetConverter.ACTION_LOAD_IN_GPU_MEMORY_ONLY_DEFAULT:
					timeline.loadInVideoMemory(GAFTimeline.CONTENT_DEFAULT);
					break;
			}

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
			this.onConvertError(new ErrorEvent(ErrorEvent.ERROR, false, false, text, id));
		}

		private function removeLoaderListeners(target: EventDispatcher, onComplete: Function, onError: Function): void
		{
			target.removeEventListener(Event.COMPLETE, onComplete);
			target.removeEventListener(IOErrorEvent.IO_ERROR, onError);
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
				this.zipProcessError(ErrorConstants.EMPTY_ZIP, 2);
			}
		}

		private function onParseError(event: FZipErrorEvent): void
		{
			this.zipProcessError(ErrorConstants.ERROR_PARSING, 1);
		}

		private function onConvertError(event: ErrorEvent): void
		{
			if (this.hasEventListener(ErrorEvent.ERROR))
			{
				this.dispatchEvent(event);
			}
			else
			{
				throw new Error(event.text);
			}
		}

		private function onConverted(event: Event): void
		{
			use namespace gaf_internal;

			var configID: String = this._gafAssetsIDs[this._currentConfigIndex];
			var folderURL: String = getFolderURL(configID);
			var converter: BinGAFAssetConfigConverter = event.target as BinGAFAssetConfigConverter;
			converter.removeEventListener(Event.COMPLETE, onConverted);
			converter.removeEventListener(ErrorEvent.ERROR, onConvertError);

			this._gafAssetConfigs[configID] = converter.config;
			var sounds: Vector.<CSound> = converter.config.sounds;
			if (sounds && !this._ignoreSounds)
			{
				for (var i: int = 0; i < sounds.length; i++)
				{
					sounds[i].source = folderURL + sounds[i].source;
					this._soundData.addSound(sounds[i], converter.config.id, this._sounds[sounds[i].source]);
				}
			}

			this._currentConfigIndex++;

			if (this._currentConfigIndex >= this._gafAssetsIDs.length)
			{
				if (this._gafAssetsConfigURLs && _gafAssetsConfigURLs.length)
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
				this._configConvertTimeout = setTimeout(this.convertConfig, 40);
			}
		}

		private function onConfigLoadComplete(event: Event): void
		{
			var loader: URLLoader = event.target as URLLoader;
			var url: String = this._gafAssetsConfigURLs[this._gafAssetsConfigIndex];

			this.removeLoaderListeners(loader, onConfigLoadComplete, onConfigIOError);

			this._gafAssetsIDs.push(url);

			this._gafAssetConfigSources[url] = loader.data;

			this._gafAssetsConfigIndex++;

			if (this._gafAssetsConfigIndex >= this._gafAssetsConfigURLs.length)
			{
				this.convertConfig();
			}
			else
			{
				this.loadConfig();
			}
		}

		private function onConfigIOError(event: IOErrorEvent): void
		{
			var url: String = this._gafAssetsConfigURLs[this._gafAssetsConfigIndex];
			this.removeLoaderListeners(event.target as URLLoader, onConfigLoadComplete, onConfigIOError);
			this.zipProcessError(ErrorConstants.ERROR_LOADING + url, 5);
		}

		private function onSoundLoadIOError(event: IOErrorEvent): void
		{
			var sound: Sound = event.target as Sound;
			this.removeLoaderListeners(event.target as URLLoader, onSoundLoadIOError, onSoundLoadIOError);
			this.zipProcessError(ErrorConstants.ERROR_LOADING + sound.url, 6);
		}

		private function onTexturesReady(event: Event): void
		{
			this._gfxData.removeEventListener(GAFGFXData.EVENT_TYPE_TEXTURES_READY, this.onTexturesReady);

			this.dispatchEvent(new Event(Event.COMPLETE));
		}

		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------

		/**
		 * Return converted <code>GAFBundle</code>. If GAF asset file created as single animation - returns null.
		 */
		public function get gafBundle(): GAFBundle
		{
			return this._gafBundle;
		}

		/**
		 * Returns the first <code>GAFTimeline</code> in a <code>GAFBundle</code>.
		 */
		[Deprecated(replacement="com.catalystapps.gaf.data.GAFBundle.getGAFTimeline()", since="5.0")]
		public function get gafTimeline(): GAFTimeline
		{
			if (this._gafBundle && this._gafBundle.gafAssets.length > 0)
			{
				for each (var asset: GAFAsset in this._gafBundle.gafAssets)
				{
					if (asset.timelines.length > 0)
					{
						return asset.timelines[0];
					}
				}
			}
			return null;
		}

		/**
		 * Return loaded zip file as <code>FZip</code> object
		 */
		public function get zip(): FZip
		{
			return this._zip;
		}

		/**
		 * Return zipLoader object
		 */
		public function get zipLoader(): FZipLibrary
		{
			return this._zipLoader;
		}

		/**
		 * The id of the converter.
		 * If it is not empty <code>ZipToGAFAssetConverter</code> sets the <code>name</code> of produced bundle equal to this id.
		 */
		public function get id(): String
		{
			return this._id;
		}

		public function set id(value: String): void
		{
			this._id = value;
		}

		public function get parseConfigAsync(): Boolean
		{
			return this._parseConfigAsync;
		}

		/**
		 * Indicates whether to convert *.gaf config file asynchronously.
		 * If <code>true</code> - conversion is divided by chunk of 20 ms (may be up to
		 * 2 times slower than synchronous conversion, but conversion won't freeze the interface).
		 * If <code>false</code> - conversion goes within one stack (up to
		 * 2 times faster than async conversion, but conversion freezes the interface).
		 */
		public function set parseConfigAsync(parseConfigAsync: Boolean): void
		{
			this._parseConfigAsync = parseConfigAsync;
		}

		/**
		 * Prevents loading of sounds
		 */
		public function set ignoreSounds(ignoreSounds: Boolean): void
		{
			this._ignoreSounds = ignoreSounds;
		}
	}
}
