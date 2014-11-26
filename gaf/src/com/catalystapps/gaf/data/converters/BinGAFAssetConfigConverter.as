package com.catalystapps.gaf.data.converters
{
	import com.catalystapps.gaf.utils.MathUtility;
	import com.catalystapps.gaf.data.config.CBlurFilterData;
	import flash.events.ErrorEvent;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import com.catalystapps.gaf.data.config.CFrameAction;
	import com.catalystapps.gaf.data.GAFAssetConfig;
	import com.catalystapps.gaf.data.GAFTimelineConfig;
	import com.catalystapps.gaf.data.config.CAnimationFrame;
	import com.catalystapps.gaf.data.config.CAnimationFrameInstance;
	import com.catalystapps.gaf.data.config.CAnimationFrames;
	import com.catalystapps.gaf.data.config.CAnimationObject;
	import com.catalystapps.gaf.data.config.CAnimationSequence;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.data.config.CStage;
	import com.catalystapps.gaf.data.config.CTextFieldObject;
	import com.catalystapps.gaf.data.config.CTextureAtlasCSF;
	import com.catalystapps.gaf.data.config.CTextureAtlasElement;
	import com.catalystapps.gaf.data.config.CTextureAtlasElements;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;
	import com.catalystapps.gaf.data.config.CTextureAtlasSource;

	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	import flash.utils.Endian;

	/**
	 * @private
	 */
	public class BinGAFAssetConfigConverter extends EventDispatcher implements IGAFAssetConfigConverter
	{
		private static const SIGNATURE_GAF: uint = 0x00474146;
		private static const SIGNATURE_GAC: uint = 0x00474143;
		private static const HEADER_LENGTH: uint = 36;

		private static const FIXED8_DIVISION: uint = 256;

		//tags
		private static const TAG_END: uint = 0;
		private static const TAG_DEFINE_ATLAS: uint = 1;
		private static const TAG_DEFINE_ATLAS2: uint = 8; // v4.0
		private static const TAG_DEFINE_ANIMATION_MASKS: uint = 2;
		private static const TAG_DEFINE_ANIMATION_MASKS2: uint = 11; // v4.0
		private static const TAG_DEFINE_ANIMATION_OBJECTS: uint = 3;
		private static const TAG_DEFINE_ANIMATION_OBJECTS2: uint = 10; // v4.0
		private static const TAG_DEFINE_ANIMATION_FRAMES: uint = 4;
		private static const TAG_DEFINE_ANIMATION_FRAMES2: uint = 12; // v4.0
		private static const TAG_DEFINE_NAMED_PARTS: uint = 5;
		private static const TAG_DEFINE_SEQUENCES: uint = 6;
		private static const TAG_DEFINE_TEXT_FIELDS: uint = 7; // v4.0
		private static const TAG_DEFINE_STAGE: uint = 9;
		private static const TAG_DEFINE_TIMELINE: uint = 13; // v4.0

		//filters
		private static const FILTER_DROP_SHADOW: uint = 0;
		private static const FILTER_BLUR: uint = 1;
		private static const FILTER_GLOW: uint = 2;
		private static const FILTER_COLOR_MATRIX: uint = 6;

		private var _assetID: String;
		private var _bytes: ByteArray;
		private var _defaultScale: Number;
		private var _defaultContentScaleFactor: Number;
		private var _config: GAFAssetConfig;

		private var time: uint;


		// --------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		public function BinGAFAssetConfigConverter(assetID: String, bytes: ByteArray, defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN)
		{
			_defaultContentScaleFactor = defaultContentScaleFactor;
			_defaultScale = defaultScale;
			_bytes = bytes;
			_assetID = assetID;
		}

		public function convert(): void
		{
			time = uint.MAX_VALUE;
			checkTimeout(parseStart);
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		private function parseStart(): void
		{
			_bytes.endian = Endian.LITTLE_ENDIAN;

			_config = new GAFAssetConfig(_assetID);
			_config.compression = _bytes.readInt();
			_config.versionMajor = _bytes.readByte();
			_config.versionMinor = _bytes.readByte();
			_config.fileLength = _bytes.readUnsignedInt();

			if (_config.versionMajor > GAFAssetConfig.MAX_VERSION)
			{
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, WarningConstants.UNSUPPORTED_FILE +
							"Library version: " + GAFAssetConfig.MAX_VERSION + ", file version: " + _config.versionMajor));
				return;
			}

			switch (_config.compression)
			{
				case SIGNATURE_GAC:
					decompressConfig();
					break;
			}

			checkTimeout(parseContinue);
		}

		private function decompressConfig(): void
		{
			var uncompressedBA: ByteArray = new ByteArray();
			uncompressedBA.endian = Endian.LITTLE_ENDIAN;

			_bytes.readBytes(uncompressedBA);

			uncompressedBA.uncompress(CompressionAlgorithm.ZLIB);

			_bytes = uncompressedBA;
		}

		/**
		 * runs <b>nextFunction</b> with <b>args</b> after a small delay (in the next stack)
		 */
		private function checkTimeout(nextFunction: Function, ...args): void
		{
			if (time - getTimer() >= 20)
			{
				time = getTimer() + 1;
				args.unshift(nextFunction, 1);
				setTimeout.apply(null, args);
			}
			else
			{
				nextFunction.apply(null, args);
			}
		}

		private function parseContinue(): void
		{
			var timelineConfig: GAFTimelineConfig;
			if (_config.versionMajor < 4)
			{
				timelineConfig = new GAFTimelineConfig(_config.versionMajor + "." + _config.versionMinor);
				timelineConfig.id = "0";
				timelineConfig.assetID = _assetID;
				timelineConfig.framesCount = _bytes.readShort();
				timelineConfig.bounds = new Rectangle(_bytes.readFloat(), _bytes.readFloat(), _bytes.readFloat(), _bytes.readFloat());
				timelineConfig.pivot = new Point(_bytes.readFloat(), _bytes.readFloat());
				_config.timelines.push(timelineConfig);
			}
			else
			{
				var i: int;
				var l: uint = _bytes.readUnsignedInt();
				for (i = 0; i < l; i++)
				{
					_config.scaleValues.push(_bytes.readFloat());
				}

				l = _bytes.readUnsignedInt();
				for (i = 0; i < l; i++)
				{
					_config.csfValues.push(_bytes.readFloat());
				}
			}

			parseTags(_bytes, onParseComplete, timelineConfig);
		}

		private function onParseComplete(timelineConfig: GAFTimelineConfig): void
		{
			if (_config.versionMajor < 4)
			{
				if (!timelineConfig.textureAtlas && timelineConfig.allTextureAtlases.length)
				{
					timelineConfig.textureAtlas = timelineConfig.allTextureAtlases[0];
				}

				_config.timelines[0].stageConfig = _config.stageConfig;

				checkForMissedRegions(timelineConfig);
			}
			else
			{
				for each (timelineConfig in _config.timelines)
				{
					timelineConfig.stageConfig = _config.stageConfig;

					checkForMissedRegions(timelineConfig);
				}
			}

			dispatchEvent(new Event(Event.COMPLETE));
		}

		private function checkForMissedRegions(timelineConfig: GAFTimelineConfig): void
		{
			if (timelineConfig.textureAtlas && timelineConfig.textureAtlas.contentScaleFactor.elements)
			{
				for each (var ao: CAnimationObject in timelineConfig.animationObjects.animationObjectsDictionary)
				{
					if (ao.type == CAnimationObject.TYPE_TEXTURE
					&& !timelineConfig.textureAtlas.contentScaleFactor.elements.getElement(ao.regionID))
					{
						timelineConfig.addWarning(WarningConstants.REGION_NOT_FOUND);
						break;
					}
				}
			}
		}

		private function parseTags(tagsBytes: ByteArray, onComplete: Function, ...args): void
		{
			if (tagsBytes.bytesAvailable > 0)
			{
				readNextTag(tagsBytes);
				args.unshift(parseTags, tagsBytes, onComplete);
				checkTimeout.apply(null, args);
			}
			else
			{
				onComplete.apply(null, args);
			}
		}

		private function readNextTag(bytes: ByteArray): void
		{
			var tagID: int = bytes.readShort();
			var tagLength: uint = bytes.readUnsignedInt();
			var tagContent: ByteArray = new ByteArray();
			tagContent.endian = Endian.LITTLE_ENDIAN;
			bytes.readBytes(tagContent, 0, tagLength);
			tagContent.position = 0;

			var timelineConfig: GAFTimelineConfig;
			if (_config.timelines.length > 0)
			{
				timelineConfig = _config.timelines[_config.timelines.length - 1];
			}

			switch (tagID)
			{
				case BinGAFAssetConfigConverter.TAG_DEFINE_STAGE:
					readStageConfig(tagContent, _config);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_ATLAS:
				case BinGAFAssetConfigConverter.TAG_DEFINE_ATLAS2:
					readTextureAtlasConfig(tagID, tagContent, timelineConfig, _defaultScale, _defaultContentScaleFactor);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_MASKS:
				case BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_MASKS2:
					readAnimationMasks(tagID, tagContent, timelineConfig);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_OBJECTS:
				case BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_OBJECTS2:
					readAnimationObjects(tagID, tagContent, timelineConfig);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_FRAMES:
				case BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_FRAMES2:
					readAnimationFrames(tagID, tagContent, timelineConfig);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_NAMED_PARTS:
					readNamedParts(tagID, tagContent, timelineConfig);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_SEQUENCES:
					readAnimationSequences(tagID, tagContent, timelineConfig);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_TEXT_FIELDS:
					readTextFields(tagID, tagContent, timelineConfig);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_TIMELINE:
					readTimeline(tagContent);
					break;
				case BinGAFAssetConfigConverter.TAG_END:
					break;
				default:
					trace(WarningConstants.UNSUPPORTED_TAG);
					break;
			}
		}

		private function readTimeline(tagContent: ByteArray): void
		{
			var timelineConfig: GAFTimelineConfig = new GAFTimelineConfig(_config.versionMajor + "." + _config.versionMinor);
			timelineConfig.id = tagContent.readUnsignedInt().toString();
			timelineConfig.assetID = _config.id;
			timelineConfig.framesCount = tagContent.readUnsignedInt();
			timelineConfig.bounds = new Rectangle(tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat());
			timelineConfig.pivot = new Point(tagContent.readFloat(), tagContent.readFloat());

			var hasLinkage: Boolean = tagContent.readBoolean();
			if (hasLinkage)
			{
				timelineConfig.linkage = tagContent.readUTF();
			}

			_config.timelines.push(timelineConfig);

			var nestedTags: ByteArray = new ByteArray();
			nestedTags.endian = Endian.LITTLE_ENDIAN;
			nestedTags.writeBytes(tagContent, tagContent.position, tagContent.bytesAvailable);
			nestedTags.position = 0;

			parseTags(nestedTags, onParseTimelineComplete, timelineConfig);
		}

		private function onParseTimelineComplete(timelineConfig: GAFTimelineConfig): void
		{
			if (!timelineConfig.allTextureAtlases.length && _config.scaleValues != null && _config.csfValues != null) // timeline hasn't atlas, create empty
			{
				var textureAtlas: CTextureAtlasScale;
				for each (var scale: Number in _config.scaleValues)
				{
					textureAtlas = new CTextureAtlasScale();
					textureAtlas.scale = scale;

					textureAtlas.allContentScaleFactors = new Vector.<CTextureAtlasCSF>();
					for each (var csf: Number in _config.csfValues)
					{
						var item: CTextureAtlasCSF;
						item = new CTextureAtlasCSF(csf, scale);

						if ((!isNaN(_defaultContentScaleFactor)
						&& MathUtility.equals(_defaultContentScaleFactor, csf))
						|| !textureAtlas.contentScaleFactor)
						{
							textureAtlas.contentScaleFactor = item;
						}

						textureAtlas.allContentScaleFactors.push(item);
					}
					timelineConfig.allTextureAtlases.push(textureAtlas);
					if (!isNaN(_defaultScale) && MathUtility.equals(_defaultScale, scale))
					{
						timelineConfig.textureAtlas = textureAtlas;
					}
				}
				if (!timelineConfig.textureAtlas && timelineConfig.allTextureAtlases.length)
				{
					timelineConfig.textureAtlas = timelineConfig.allTextureAtlases[0];
				}
			}

			if (!timelineConfig.textureAtlas && timelineConfig.allTextureAtlases.length)
			{
				timelineConfig.textureAtlas = timelineConfig.allTextureAtlases[0];
			}
		}

		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------

		public function get config(): GAFAssetConfig
		{
			return _config;
		}

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------

		private static function readStageConfig(tagContent: ByteArray, config: GAFAssetConfig): void
		{
			var stageConfig: CStage = new CStage();

			stageConfig.fps = tagContent.readByte();
			stageConfig.color = tagContent.readInt();
			stageConfig.width = tagContent.readUnsignedShort();
			stageConfig.height = tagContent.readUnsignedShort();

			config.stageConfig = stageConfig;
		}

		private static function readAnimationFrames(tagID: int, tagContent: ByteArray, timelineConfig: GAFTimelineConfig): void
		{
			var framesCount: uint = tagContent.readUnsignedInt();
			var frameNumber: uint;
			var hasChangesInDisplayList: Boolean;
			var hasActions: Boolean;
			var statesCount: uint;
			var hasColorTransform: Boolean;
			var hasMask: Boolean;
			var hasEffect: Boolean;
			var stateID: uint;
			var zIndex: int;
			var alpha: Number;
			var matrix: Matrix;
			var maskID: String;

			var animationConfigFrames: CAnimationFrames = new CAnimationFrames();
			var currentFrame: CAnimationFrame;
			var prevFrame: CAnimationFrame;
			var missedFrameNumber: uint;
			var instance: CAnimationFrameInstance;
			var filter: CFilter;

			var filterLength: int;
			var filterType: uint;

			var blurFilter: CBlurFilterData;
			var blurFilters: Object = {};

			if (framesCount)
			{
				for (var i: uint = 0; i < framesCount; i++)
				{
					frameNumber = tagContent.readUnsignedInt();

					if (tagID == BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_FRAMES)
					{
						hasChangesInDisplayList = true;
						hasActions = false;
					}
					else
					{
						hasChangesInDisplayList = tagContent.readBoolean();
						hasActions = tagContent.readBoolean();
					}

					if (prevFrame)
					{
						currentFrame = prevFrame.clone(frameNumber);

						for (missedFrameNumber = prevFrame.frameNumber + 1; missedFrameNumber < currentFrame.frameNumber; missedFrameNumber++)
						{
							animationConfigFrames.addFrame(prevFrame.clone(missedFrameNumber));
						}
					}
					else
					{
						currentFrame = new CAnimationFrame(frameNumber);

						if (currentFrame.frameNumber > 1)
						{
							for (missedFrameNumber = 1; missedFrameNumber < currentFrame.frameNumber; missedFrameNumber++)
							{
								animationConfigFrames.addFrame(new CAnimationFrame(missedFrameNumber));
							}
						}
					}

					if (hasChangesInDisplayList)
					{
						statesCount = tagContent.readUnsignedInt();

						for (var j: uint = 0; j < statesCount; j++)
						{
							hasColorTransform = tagContent.readBoolean();
							hasMask = tagContent.readBoolean();
							hasEffect = tagContent.readBoolean();

							stateID = tagContent.readUnsignedInt();
							zIndex = tagContent.readInt();
							alpha = tagContent.readFloat();
							if (alpha == 1)
							{
								alpha = CAnimationFrameInstance.MAX_ALPHA;
							}
							matrix = new Matrix(tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat(),
									tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat());

							filter = null;

							if (hasColorTransform)
							{
								var params: Vector.<Number> = new <Number>[
									tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat(),
									tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat(),
									tagContent.readFloat()];
								params.fixed = true;
								filter ||= new CFilter();
								filter.addColorTransform(params);
							}

							if (hasEffect)
							{
								filter ||= new CFilter();

								filterLength = tagContent.readByte();
								for (var k: uint = 0; k < filterLength; k++)
								{
									filterType = tagContent.readUnsignedInt();
									var warning: String;

									switch (filterType)
									{
										case BinGAFAssetConfigConverter.FILTER_DROP_SHADOW:
											warning = readDropShadowFilter(tagContent, filter);
											break;
										case BinGAFAssetConfigConverter.FILTER_BLUR:
											warning = readBlurFilter(tagContent, filter);
											blurFilter = filter.filterConfigs[filter.filterConfigs.length - 1] as CBlurFilterData;
											if (blurFilter.blurX >= 2 && blurFilter.blurY >= 2)
											{
												if (!(stateID in blurFilters))
												{
													blurFilters[stateID] = blurFilter;
												}
											}
											else
											{
												blurFilters[stateID] = null;
											}
											break;
										case BinGAFAssetConfigConverter.FILTER_GLOW:
											warning = readGlowFilter(tagContent, filter);
											break;
										case BinGAFAssetConfigConverter.FILTER_COLOR_MATRIX:
											warning = readColorMatrixFilter(tagContent, filter);
											break;
										default:
											trace(WarningConstants.UNSUPPORTED_FILTERS);
											break;
									}

									timelineConfig.addWarning(warning);
								}
							}

							if (hasMask)
							{
								maskID = tagContent.readUnsignedInt() + "";
							}
							else
							{
								maskID = "";
							}

							instance = new CAnimationFrameInstance(stateID + "");
							instance.update(zIndex, matrix, alpha, maskID, filter);

							if (maskID && filter)
							{
								timelineConfig.addWarning(WarningConstants.FILTERS_UNDER_MASK);
							}

							currentFrame.addInstance(instance);
						}

						currentFrame.sortInstances();
					}

					if (hasActions)
					{
						var action: CFrameAction;
						var count: int = tagContent.readUnsignedInt();
						for (var a: int = 0; a < count; a++)
						{
							action = new CFrameAction();
							action.type = tagContent.readUnsignedInt();

							if (action.type > 1) // if not stop(); or play(); and has params
							{
								var paramsCount: int = tagContent.readUnsignedInt();
								for (var p: int = 0; p < paramsCount; p++)
								{
									action.params.push(tagContent.readUTF());
								}
							}

							currentFrame.addAction(action);
						}
					}

					animationConfigFrames.addFrame(currentFrame);

					prevFrame = currentFrame;
				}

				for (missedFrameNumber = prevFrame.frameNumber + 1; missedFrameNumber <= timelineConfig.framesCount; missedFrameNumber++)
				{
					animationConfigFrames.addFrame(prevFrame.clone(missedFrameNumber));
				}

				for each (currentFrame in animationConfigFrames.frames)
				{
					for each (instance in currentFrame.instances)
					{
						if (blurFilters[instance.id] && instance.filter)
						{
							blurFilter = instance.filter.getBlurFilter();
							if (blurFilter && blurFilter.resolution == 1)
							{
								blurFilter.blurX *= 0.5;
								blurFilter.blurY *= 0.5;
								blurFilter.resolution = 0.75;
							}
						}
					}
				}
			}

			timelineConfig.animationConfigFrames = animationConfigFrames;
		}

		private static function readDropShadowFilter(source: ByteArray, filter: CFilter): String
		{
			var color: Array = readColorValue(source);
			var blurX: Number = source.readFloat();
			var blurY: Number = source.readFloat();
			var angle: Number = source.readFloat();
			var distance: Number = source.readFloat();
			var strength: Number = source.readFloat();
			var inner: Boolean = source.readBoolean();
			var knockout: Boolean = source.readBoolean();

			return filter.addDropShadowFilter(blurX, blurY, color[1], color[0], angle, distance);
		}

		private static function readBlurFilter(source: ByteArray, filter: CFilter): String
		{
			return filter.addBlurFilter(source.readFloat(), source.readFloat());
		}

		private static function readGlowFilter(source: ByteArray, filter: CFilter): String
		{
			var color: Array = readColorValue(source);
			var blurX: Number = source.readFloat();
			var blurY: Number = source.readFloat();
			var strength: Number = source.readFloat();
			var inner: Boolean = source.readBoolean();
			var knockout: Boolean = source.readBoolean();

			return filter.addGlowFilter(blurX, blurY, color[1], color[0]);
		}

		private static function readColorMatrixFilter(source: ByteArray, filter: CFilter): String
		{
			var matrix: Vector.<Number> = new Vector.<Number>(20, true);
			for (var i: uint = 0; i < 20; i++)
			{
				matrix[i] = source.readFloat();
			}

			return filter.addColorMatrixFilter(matrix);
		}

		private static function readFixed(source: ByteArray): Number
		{
			var value: int = source.readShort();

			return value / FIXED8_DIVISION;
		}

		private static function readColorValue(source: ByteArray): Array
		{
			var argbValue: uint = source.readUnsignedInt();
			var alpha: Number = int(((argbValue >> 24) & 0xFF) * 100 / 255) / 100;
			var color: uint = argbValue & 0xFFFFFF;

			return [alpha, color];
		}

		private static function readTextureAtlasConfig(tagID: int, tagContent: ByteArray, timelineConfig: GAFTimelineConfig,
		                                               defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN): void
		{
			var i: uint;
			var j: uint;

			var scale: Number = tagContent.readFloat();
			var textureAtlas: CTextureAtlasScale = new CTextureAtlasScale();
			textureAtlas.scale = scale;

			/////////////////////

			var contentScaleFactors: Vector.<CTextureAtlasCSF> = new Vector.<CTextureAtlasCSF>();
			var contentScaleFactor: CTextureAtlasCSF;

			/////////////////////

			function getContentScaleFactor(csf: Number): CTextureAtlasCSF
			{
				var item: CTextureAtlasCSF;

				for each (item in contentScaleFactors)
				{
					if (MathUtility.equals(item.csf, csf))
					{
						return item;
					}
				}

				item = new CTextureAtlasCSF(csf, scale);
				contentScaleFactors.push(item);

				if (!isNaN(defaultContentScaleFactor) && MathUtility.equals(defaultContentScaleFactor, csf))
				{
					textureAtlas.contentScaleFactor = item;
				}

				return item;
			};

			/////////////////////

			var atlasLength: int = tagContent.readByte();
			var atlasID: uint;
			var sourceLength: int;
			var csf: Number;
			var source: String;

			for (i = 0; i < atlasLength; i++)
			{
				atlasID = tagContent.readUnsignedInt();
				sourceLength = tagContent.readByte();
				for (j = 0; j < sourceLength; j++)
				{
					source = tagContent.readUTF();
					csf = tagContent.readFloat();

					contentScaleFactor = getContentScaleFactor(csf);
					contentScaleFactor.sources.push(new CTextureAtlasSource(atlasID + "", source));
				}
			}

			textureAtlas.allContentScaleFactors = contentScaleFactors;

			if (!textureAtlas.contentScaleFactor && contentScaleFactors.length)
			{
				textureAtlas.contentScaleFactor = contentScaleFactors[0];
			}

			/////////////////////

			var elementsLength: uint = tagContent.readUnsignedInt();
			var element: CTextureAtlasElement;
			var hasScale9Grid: Boolean;
			var scale9Grid: Rectangle;
			var pivot: Point;
			var topLeft: Point;
			var elementScale: Number;
			var elementWidth: Number;
			var elementHeight: Number;
			var elementAtlasID: uint;

			var elements: CTextureAtlasElements = new CTextureAtlasElements();

			for (i = 0; i < elementsLength; i++)
			{
				pivot = new Point(tagContent.readFloat(), tagContent.readFloat());
				topLeft = new Point(tagContent.readFloat(), tagContent.readFloat());
				elementScale = tagContent.readFloat();
				elementWidth = tagContent.readFloat();
				elementHeight = tagContent.readFloat();
				atlasID = tagContent.readUnsignedInt();
				elementAtlasID = tagContent.readUnsignedInt();
				if (tagID == BinGAFAssetConfigConverter.TAG_DEFINE_ATLAS2)
				{
					hasScale9Grid = tagContent.readBoolean();
					if (hasScale9Grid)
					{
						scale9Grid = new Rectangle(
								tagContent.readFloat(), tagContent.readFloat(),
								tagContent.readFloat(), tagContent.readFloat()
						);
					}
				}

				element = new CTextureAtlasElement(elementAtlasID + "", atlasID + "",
						new Rectangle(int(topLeft.x), int(topLeft.y), elementWidth, elementHeight),
						new Matrix(1 / elementScale, 0, 0, 1 / elementScale, -pivot.x / elementScale, -pivot.y / elementScale));
				element.scale9Grid = scale9Grid;
				elements.addElement(element);
			}

			for each (contentScaleFactor in contentScaleFactors)
			{
				contentScaleFactor.elements = elements;
			}

			timelineConfig.allTextureAtlases.push(textureAtlas);

			if (!isNaN(defaultScale) && MathUtility.equals(defaultScale, scale))
			{
				timelineConfig.textureAtlas = textureAtlas;
			}
		}

		private static function readAnimationMasks(tagID: int, tagContent: ByteArray, timelineConfig: GAFTimelineConfig): void
		{
			var length: int = tagContent.readUnsignedInt();
			var objectID: int;
			var regionID: int;
			var type: String;

			for (var i: uint = 0; i < length; i++)
			{
				objectID = tagContent.readUnsignedInt();
				regionID = tagContent.readUnsignedInt();
				if (tagID == BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_MASKS)
				{
					type = CAnimationObject.TYPE_TEXTURE;
				}
				else
				{
					type = getAnimationObjectTypeString(tagContent.readUnsignedShort());
				}
				timelineConfig.animationObjects.addAnimationObject(new CAnimationObject(objectID + "", regionID + "", type, true));
			}
		}

		private static function getAnimationObjectTypeString(type: uint): String
		{
			var typeString: String = CAnimationObject.TYPE_TEXTURE;
			switch (type)
			{
				case 0:
					typeString = CAnimationObject.TYPE_TEXTURE;
					break;
				case 1:
					typeString = CAnimationObject.TYPE_TEXTFIELD;
					break;
				case 2:
					typeString = CAnimationObject.TYPE_TIMELINE;
					break;
			}

			return typeString;
		}

		private static function readAnimationObjects(tagID: int, tagContent: ByteArray, timelineConfig: GAFTimelineConfig): void
		{
			var length: int = tagContent.readUnsignedInt();
			var objectID: int;
			var regionID: int;
			var type: String;

			for (var i: uint = 0; i < length; i++)
			{
				objectID = tagContent.readUnsignedInt();
				regionID = tagContent.readUnsignedInt();
				if (tagID == BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_OBJECTS)
				{
					type = CAnimationObject.TYPE_TEXTURE;
				}
				else
				{
					type = getAnimationObjectTypeString(tagContent.readUnsignedShort());
				}
				timelineConfig.animationObjects.addAnimationObject(new CAnimationObject(objectID + "", regionID + "", type, false));
			}
		}

		private static function readAnimationSequences(tagID: int, tagContent: ByteArray, timelineConfig: GAFTimelineConfig): void
		{
			var length: int = tagContent.readUnsignedInt();
			var sequenceID: String;
			var startFrameNo: int;
			var endFrameNo: int;

			for (var i: uint = 0; i < length; i++)
			{
				sequenceID = tagContent.readUTF();
				startFrameNo = tagContent.readShort();
				endFrameNo = tagContent.readShort();
				timelineConfig.animationSequences.addSequence(new CAnimationSequence(sequenceID, startFrameNo, endFrameNo));
			}
		}

		private static function readNamedParts(tagID: int, tagContent: ByteArray, timelineConfig: GAFTimelineConfig): void
		{
			timelineConfig.namedParts = {};

			var length: int = tagContent.readUnsignedInt();
			var partID: int;
			for (var i: uint = 0; i < length; i++)
			{
				partID = tagContent.readUnsignedInt();
				timelineConfig.namedParts[partID] = tagContent.readUTF();
			}
		}

		private static function readTextFields(tagID: int, tagContent: ByteArray, timelineConfig: GAFTimelineConfig): void
		{
			var length: int = tagContent.readUnsignedInt();
			var pivotX: Number;
			var pivotY: Number;
			var textFieldID: int;
			var width: Number;
			var height: Number;
			var text: String;
			var embedFonts: Boolean;
			var multiline: Boolean;
			var wordWrap: Boolean;
			var restrict: String;
			var editable: Boolean;
			var selectable: Boolean;
			var displayAsPassword: Boolean;
			var maxChars: uint;

			var textFormat: TextFormat;

			for (var i: uint = 0; i < length; i++)
			{
				textFieldID = tagContent.readUnsignedInt();
				pivotX = tagContent.readFloat();
				pivotY = tagContent.readFloat();
				width = tagContent.readFloat();
				height = tagContent.readFloat();

				text = tagContent.readUTF();

				embedFonts = tagContent.readBoolean();
				multiline = tagContent.readBoolean();
				wordWrap = tagContent.readBoolean();

				var hasRestrict: Boolean = tagContent.readBoolean();
				if (hasRestrict)
				{
					restrict = tagContent.readUTF();
				}

				editable = tagContent.readBoolean();
				selectable = tagContent.readBoolean();
				displayAsPassword = tagContent.readBoolean();
				maxChars = tagContent.readUnsignedInt();

				// read textFormat
				var alignFlag: uint = tagContent.readUnsignedInt();
				var align: String;
				switch (alignFlag)
				{
					case 0:
						align = TextFormatAlign.LEFT;
						break;
					case 1:
						align = TextFormatAlign.RIGHT;
						break;
					case 2:
						align = TextFormatAlign.CENTER;
						break;
					case 3:
						align = TextFormatAlign.JUSTIFY;
						break;
					case 4:
						align = TextFormatAlign.START;
						break;
					case 5:
						align = TextFormatAlign.END;
						break;
				}

				var blockIndent: Number = tagContent.readUnsignedInt();
				var bold: Boolean = tagContent.readBoolean();
				var bullet: Boolean = tagContent.readBoolean();
				var color: uint = tagContent.readUnsignedInt();

				var font: String = tagContent.readUTF();
				var indent: uint = tagContent.readUnsignedInt();
				var italic: Boolean = tagContent.readBoolean();
				var kerning: Boolean = tagContent.readBoolean();
				var leading: int = tagContent.readUnsignedInt();
				var leftMargin: Number = tagContent.readUnsignedInt();
				var letterSpacing: Number = tagContent.readFloat();
				var rightMargin: Number = tagContent.readUnsignedInt();
				var size: int = tagContent.readUnsignedInt();

				var l: uint = tagContent.readUnsignedInt();
				var tabStops: Array = [];
				for (var j: uint = 0; j < l; j++)
				{
					tabStops.push(tagContent.readUnsignedInt());
				}

				var target: String = tagContent.readUTF();
				var underline: Boolean = tagContent.readBoolean();
				var url: String = tagContent.readUTF();

				/* var display: String = tagContent.readUTF();*/

				textFormat = new TextFormat(font, size, color, bold, italic, underline, url, target, align, leftMargin,
						rightMargin, blockIndent, leading);
				textFormat.bullet = bullet;
				textFormat.kerning = kerning;
				//textFormat.display = display;
				textFormat.letterSpacing = letterSpacing;
				textFormat.tabStops = tabStops;
				textFormat.indent = indent;

				var textFieldObject: CTextFieldObject = new CTextFieldObject(textFieldID.toString(), text, textFormat,
						width, height);
				textFieldObject.pivotPoint.x = -pivotX;
				textFieldObject.pivotPoint.y = -pivotY;
				textFieldObject.embedFonts = embedFonts;
				textFieldObject.multiline = multiline;
				textFieldObject.wordWrap = wordWrap;
				textFieldObject.restrict = restrict;
				textFieldObject.editable = editable;
				textFieldObject.selectable = selectable;
				textFieldObject.displayAsPassword = displayAsPassword;
				textFieldObject.maxChars = maxChars;
				timelineConfig.textFields.addTextFieldObject(textFieldObject);
			}
		}
	}
}
