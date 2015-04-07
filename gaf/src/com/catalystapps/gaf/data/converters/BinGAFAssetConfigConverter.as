package com.catalystapps.gaf.data.converters
{
	import com.catalystapps.gaf.data.GAFAssetConfig;
	import com.catalystapps.gaf.data.GAFTimelineConfig;
	import com.catalystapps.gaf.data.config.CAnimationFrame;
	import com.catalystapps.gaf.data.config.CAnimationFrameInstance;
	import com.catalystapps.gaf.data.config.CAnimationFrames;
	import com.catalystapps.gaf.data.config.CAnimationObject;
	import com.catalystapps.gaf.data.config.CAnimationSequence;
	import com.catalystapps.gaf.data.config.CBlurFilterData;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.data.config.CFrameAction;
	import com.catalystapps.gaf.data.config.CStage;
	import com.catalystapps.gaf.data.config.CTextFieldObject;
	import com.catalystapps.gaf.data.config.CTextureAtlasCSF;
	import com.catalystapps.gaf.data.config.CTextureAtlasElement;
	import com.catalystapps.gaf.data.config.CTextureAtlasElements;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;
	import com.catalystapps.gaf.data.config.CTextureAtlasSource;
	import com.catalystapps.gaf.utils.MathUtility;

	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;

	import starling.utils.RectangleUtil;

	/**
	 * @private
	 */
	public class BinGAFAssetConfigConverter extends EventDispatcher implements IGAFAssetConfigConverter
	{
		private static const SIGNATURE_GAF: uint = 0x00474146;
		private static const SIGNATURE_GAC: uint = 0x00474143;
		private static const HEADER_LENGTH: uint = 36;

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

		private static const sHelperRectangle: Rectangle = new Rectangle();
		private static const sHelperMatrix: Matrix = new Matrix();

		private var _assetID: String;
		private var _bytes: ByteArray;
		private var _defaultScale: Number;
		private var _defaultContentScaleFactor: Number;
		private var _config: GAFAssetConfig;
		private var _textureElementSizes: Object; // Point by texture element id

		private var time: uint;
		private var isTimeline: Boolean;


		// --------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		public function BinGAFAssetConfigConverter(assetID: String, bytes: ByteArray, defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN)
		{
			this._defaultContentScaleFactor = defaultContentScaleFactor;
			this._defaultScale = defaultScale;
			this._bytes = bytes;
			this._assetID = assetID;

			this._textureElementSizes = {};
		}

		public function convert(): void
		{
			this.time = getTimer();
			setTimeout(this.parseStart, 1);
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		private function parseStart(): void
		{
			this._bytes.endian = Endian.LITTLE_ENDIAN;

			this._config = new GAFAssetConfig(this._assetID);
			this._config.compression = this._bytes.readInt();
			this._config.versionMajor = this._bytes.readByte();
			this._config.versionMinor = this._bytes.readByte();
			this._config.fileLength = this._bytes.readUnsignedInt();

			if (this._config.versionMajor > GAFAssetConfig.MAX_VERSION)
			{
				this.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, WarningConstants.UNSUPPORTED_FILE +
				"Library version: " + GAFAssetConfig.MAX_VERSION + ", file version: " + this._config.versionMajor));
				return;
			}

			switch (this._config.compression)
			{
				case SIGNATURE_GAC:
					this.decompressConfig();
					break;
			}

			var timelineConfig: GAFTimelineConfig;
			if (this._config.versionMajor < 4)
			{
				timelineConfig = new GAFTimelineConfig(this._config.versionMajor + "." + this._config.versionMinor);
				timelineConfig.id = "0";
				timelineConfig.assetID = this._assetID;
				timelineConfig.framesCount = this._bytes.readShort();
				timelineConfig.bounds = new Rectangle(this._bytes.readFloat(), this._bytes.readFloat(), this._bytes.readFloat(), this._bytes.readFloat());
				timelineConfig.pivot = new Point(this._bytes.readFloat(), this._bytes.readFloat());
				this._config.timelines.push(timelineConfig);
			}
			else
			{
				var i: int;
				var l: uint = this._bytes.readUnsignedInt();
				for (i = 0; i < l; i++)
				{
					this._config.scaleValues.push(this._bytes.readFloat());
				}

				l = this._bytes.readUnsignedInt();
				for (i = 0; i < l; i++)
				{
					this._config.csfValues.push(this._bytes.readFloat());
				}
			}

			this.readNextTag();
		}

		private function decompressConfig(): void
		{
			var uncompressedBA: ByteArray = new ByteArray();
			uncompressedBA.endian = Endian.LITTLE_ENDIAN;

			this._bytes.readBytes(uncompressedBA);
			this._bytes.clear();

			uncompressedBA.uncompress(CompressionAlgorithm.ZLIB);

			this._bytes = uncompressedBA;
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

		private function readNextTag(): void
		{
			var tagID: int = this._bytes.readShort();
			var tagLength: uint = this._bytes.readUnsignedInt();

			var timelineConfig: GAFTimelineConfig;
			if (this._config.timelines.length > 0)
			{
				timelineConfig = this._config.timelines[this._config.timelines.length - 1];
			}

			switch (tagID)
			{
				case BinGAFAssetConfigConverter.TAG_DEFINE_STAGE:
					readStageConfig(this._bytes, this._config);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_ATLAS:
				case BinGAFAssetConfigConverter.TAG_DEFINE_ATLAS2:
					readTextureAtlasConfig(tagID, this._bytes, timelineConfig, this._defaultScale,
							this._defaultContentScaleFactor, this._textureElementSizes);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_MASKS:
				case BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_MASKS2:
					readAnimationMasks(tagID, this._bytes, timelineConfig);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_OBJECTS:
				case BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_OBJECTS2:
					readAnimationObjects(tagID, this._bytes, timelineConfig);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_FRAMES:
				case BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_FRAMES2:
					readAnimationFrames(tagID);
					return;
				case BinGAFAssetConfigConverter.TAG_DEFINE_NAMED_PARTS:
					readNamedParts(this._bytes, timelineConfig);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_SEQUENCES:
					readAnimationSequences(this._bytes, timelineConfig);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_TEXT_FIELDS:
					readTextFields(this._bytes, timelineConfig);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_TIMELINE:
					readTimeline();
					break;
				case BinGAFAssetConfigConverter.TAG_END:
					if (this.isTimeline)
					{
						this.isTimeline = false;
						this.endParsingTimeline(timelineConfig);
					}
					else
					{
						this._bytes.position = this._bytes.length;
						this.endParsing(timelineConfig);
						return;
					}
					break;
				default:
					trace(WarningConstants.UNSUPPORTED_TAG);
					this._bytes.position += tagLength;
					break;
			}

			delayedReadNextTag();
		}

		private function delayedReadNextTag(): void
		{
			if (getTimer() - this.time >= 20)
			{
				this.time = getTimer();
				setTimeout(this.readNextTag, 1);
			}
			else
			{
				this.readNextTag();
			}
		}

		private function readTimeline(): void
		{
			var timelineConfig: GAFTimelineConfig = new GAFTimelineConfig(this._config.versionMajor + "." + _config.versionMinor);
			timelineConfig.id = this._bytes.readUnsignedInt().toString();
			timelineConfig.assetID = this._config.id;
			timelineConfig.framesCount = this._bytes.readUnsignedInt();
			timelineConfig.bounds = new Rectangle(this._bytes.readFloat(), this._bytes.readFloat(), this._bytes.readFloat(), this._bytes.readFloat());
			timelineConfig.pivot = new Point(this._bytes.readFloat(), this._bytes.readFloat());

			var hasLinkage: Boolean = this._bytes.readBoolean();
			if (hasLinkage)
			{
				timelineConfig.linkage = this._bytes.readUTF();
			}

			this._config.timelines.push(timelineConfig);

			this.isTimeline = true;
		}

		private function readMaskMaxSizes(): void
		{
			for each (var timeline: GAFTimelineConfig in this._config.timelines)
			{
				for each (var frame: CAnimationFrame in timeline.animationConfigFrames.frames)
				{
					for each (var frameInstance: CAnimationFrameInstance in frame.instances)
					{
						var animationObject: CAnimationObject = timeline.animationObjects.getAnimationObject(frameInstance.id);
						if (animationObject.mask)
						{
							if (!animationObject.maxSize)
							{
								animationObject.maxSize = new Point();
							}

							var maxSize: Point = animationObject.maxSize;

							if (animationObject.type == CAnimationObject.TYPE_TEXTURE)
							{
								sHelperRectangle.copyFrom(this._textureElementSizes[animationObject.regionID]);
							}
							else if (animationObject.type == CAnimationObject.TYPE_TIMELINE)
							{
								var maskTimeline: GAFTimelineConfig;
								for each (maskTimeline in this._config.timelines)
								{
									if (maskTimeline.id == frameInstance.id)
									{
										break;
									}
								}
								sHelperRectangle.copyFrom(maskTimeline.bounds);
							}
							else if (animationObject.type == CAnimationObject.TYPE_TEXTFIELD)
							{
								var textField: CTextFieldObject = timeline.textFields.textFieldObjectsDictionary[animationObject.regionID];
								sHelperRectangle.setTo(
										-textField.pivotPoint.x,
										-textField.pivotPoint.y,
										textField.width,
										textField.height);
							}
							RectangleUtil.getBounds(sHelperRectangle, frameInstance.matrix, sHelperRectangle);
							maxSize.setTo(
									Math.max(maxSize.x, Math.abs(sHelperRectangle.width)),
									Math.max(maxSize.y, Math.abs(sHelperRectangle.height)));
						}
					}
				}
			}
		}

		private function endParsingTimeline(timelineConfig: GAFTimelineConfig): void
		{
			if (!timelineConfig.allTextureAtlases.length && this._config.scaleValues != null && this._config.csfValues != null) // timeline hasn't atlas, create empty
			{
				var textureAtlas: CTextureAtlasScale;
				for each (var scale: Number in this._config.scaleValues)
				{
					textureAtlas = new CTextureAtlasScale();
					textureAtlas.scale = scale;

					textureAtlas.allContentScaleFactors = new Vector.<CTextureAtlasCSF>();
					for each (var csf: Number in this._config.csfValues)
					{
						var item: CTextureAtlasCSF;
						item = new CTextureAtlasCSF(csf, scale);

						if ((!isNaN(this._defaultContentScaleFactor)
								&& MathUtility.equals(this._defaultContentScaleFactor, csf))
								|| !textureAtlas.contentScaleFactor)
						{
							textureAtlas.contentScaleFactor = item;
						}

						textureAtlas.allContentScaleFactors.push(item);
					}
					timelineConfig.allTextureAtlases.push(textureAtlas);
					if (!isNaN(this._defaultScale) && MathUtility.equals(this._defaultScale, scale))
					{
						timelineConfig.textureAtlas = textureAtlas;
					}
				}
			}

			if (!timelineConfig.textureAtlas && timelineConfig.allTextureAtlases.length)
			{
				timelineConfig.textureAtlas = timelineConfig.allTextureAtlases[0];
			}
		}

		private function endParsing(timelineConfig: GAFTimelineConfig): void
		{
			this._bytes.clear();
			this._bytes = null;

			this.readMaskMaxSizes();

			if (this._config.versionMajor < 4)
			{
				if (!timelineConfig.textureAtlas && timelineConfig.allTextureAtlases.length)
				{
					timelineConfig.textureAtlas = timelineConfig.allTextureAtlases[0];
				}

				this._config.timelines[0].stageConfig = this._config.stageConfig;

				this.checkForMissedRegions(timelineConfig);
			}
			else
			{
				for each (timelineConfig in this._config.timelines)
				{
					timelineConfig.stageConfig = this._config.stageConfig;

					this.checkForMissedRegions(timelineConfig);
				}
			}

			this.dispatchEvent(new Event(Event.COMPLETE));
		}

		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------

		public function get config(): GAFAssetConfig
		{
			return this._config;
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

		private function readAnimationFrames(tagID: int, startIndex: uint = 0, framesCount: Number = NaN, prevFrame: CAnimationFrame = null): void
		{
			if (isNaN(framesCount))
			{
				framesCount = this._bytes.readUnsignedInt();
			}
			var missedFrameNumber: uint;
			var filterLength: int;
			var frameNumber: uint;
			var statesCount: uint;
			var filterType: uint;
			var stateID: uint;
			var zIndex: int;
			var alpha: Number;
			var matrix: Matrix;
			var maskID: String;
			var hasMask: Boolean;
			var hasEffect: Boolean;
			var hasActions: Boolean;
			var hasColorTransform: Boolean;
			var hasChangesInDisplayList: Boolean;

			var timelineConfig: GAFTimelineConfig = this._config.timelines[this._config.timelines.length - 1];
			var instance: CAnimationFrameInstance;
			var currentFrame: CAnimationFrame;
			var blurFilter: CBlurFilterData;
			var blurFilters: Object = {};
			var filter: CFilter;

			var cycleTime: uint = getTimer();

			if (framesCount)
			{
				for (var i: uint = startIndex; i < framesCount; i++)
				{
					if (getTimer() - cycleTime >= 20)
					{
						setTimeout(readAnimationFrames, 1, tagID, i, framesCount, prevFrame);
						return;
					}

					frameNumber = this._bytes.readUnsignedInt();

					if (tagID == BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_FRAMES)
					{
						hasChangesInDisplayList = true;
						hasActions = false;
					}
					else
					{
						hasChangesInDisplayList = this._bytes.readBoolean();
						hasActions = this._bytes.readBoolean();
					}

					if (prevFrame)
					{
						currentFrame = prevFrame.clone(frameNumber);

						for (missedFrameNumber = prevFrame.frameNumber + 1; missedFrameNumber < currentFrame.frameNumber; missedFrameNumber++)
						{
							timelineConfig.animationConfigFrames.addFrame(prevFrame.clone(missedFrameNumber));
						}
					}
					else
					{
						currentFrame = new CAnimationFrame(frameNumber);

						if (currentFrame.frameNumber > 1)
						{
							for (missedFrameNumber = 1; missedFrameNumber < currentFrame.frameNumber; missedFrameNumber++)
							{
								timelineConfig.animationConfigFrames.addFrame(new CAnimationFrame(missedFrameNumber));
							}
						}
					}

					if (hasChangesInDisplayList)
					{
						statesCount = this._bytes.readUnsignedInt();

						for (var j: uint = 0; j < statesCount; j++)
						{
							hasColorTransform = this._bytes.readBoolean();
							hasMask = this._bytes.readBoolean();
							hasEffect = this._bytes.readBoolean();

							stateID = this._bytes.readUnsignedInt();
							zIndex = this._bytes.readInt();
							alpha = this._bytes.readFloat();
							if (alpha == 1)
							{
								alpha = CAnimationFrameInstance.MAX_ALPHA;
							}
							matrix = new Matrix(this._bytes.readFloat(), this._bytes.readFloat(), this._bytes.readFloat(),
									this._bytes.readFloat(), this._bytes.readFloat(), this._bytes.readFloat());

							filter = null;

							if (hasColorTransform)
							{
								var params: Vector.<Number> = new <Number>[
									this._bytes.readFloat(), this._bytes.readFloat(), this._bytes.readFloat(),
									this._bytes.readFloat(), this._bytes.readFloat(), this._bytes.readFloat(),
									this._bytes.readFloat()];
								params.fixed = true;
								filter ||= new CFilter();
								filter.addColorTransform(params);
							}

							if (hasEffect)
							{
								filter ||= new CFilter();

								filterLength = this._bytes.readByte();
								for (var k: uint = 0; k < filterLength; k++)
								{
									filterType = this._bytes.readUnsignedInt();
									var warning: String;

									switch (filterType)
									{
										case BinGAFAssetConfigConverter.FILTER_DROP_SHADOW:
											warning = readDropShadowFilter(this._bytes, filter);
											break;
										case BinGAFAssetConfigConverter.FILTER_BLUR:
											warning = readBlurFilter(this._bytes, filter);
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
											warning = readGlowFilter(this._bytes, filter);
											break;
										case BinGAFAssetConfigConverter.FILTER_COLOR_MATRIX:
											warning = readColorMatrixFilter(this._bytes, filter);
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
								maskID = this._bytes.readUnsignedInt() + "";
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
						var count: int = this._bytes.readUnsignedInt();
						for (var a: int = 0; a < count; a++)
						{
							action = new CFrameAction();
							action.type = this._bytes.readUnsignedInt();
							action.scope = this._bytes.readUTF();

							var paramsLength: uint = this._bytes.readUnsignedInt();
							if (paramsLength > 0)
							{
								var paramsBA: ByteArray = new ByteArray();
								paramsBA.endian = Endian.LITTLE_ENDIAN;
								this._bytes.readBytes(paramsBA, 0, paramsLength);
								paramsBA.position = 0;

								while (paramsBA.bytesAvailable > 0)
								{
									action.params.push(paramsBA.readUTF());
								}
							}

							currentFrame.addAction(action);
						}
					}

					timelineConfig.animationConfigFrames.addFrame(currentFrame);

					prevFrame = currentFrame;
				} //end loop

				for (missedFrameNumber = prevFrame.frameNumber + 1; missedFrameNumber <= timelineConfig.framesCount; missedFrameNumber++)
				{
					timelineConfig.animationConfigFrames.addFrame(prevFrame.clone(missedFrameNumber));
				}

				for each (currentFrame in timelineConfig.animationConfigFrames.frames)
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
			} //end condition

			this.delayedReadNextTag();
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

			return filter.addDropShadowFilter(blurX, blurY, color[1], color[0], angle, distance, strength, inner, knockout);
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

			return filter.addGlowFilter(blurX, blurY, color[1], color[0], strength, inner, knockout);
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

		private static function readColorValue(source: ByteArray): Array
		{
			var argbValue: uint = source.readUnsignedInt();
			var alpha: Number = int(((argbValue >> 24) & 0xFF) * 100 / 255) / 100;
			var color: uint = argbValue & 0xFFFFFF;

			return [alpha, color];
		}

		private static function readTextureAtlasConfig(tagID: int, tagContent: ByteArray, timelineConfig: GAFTimelineConfig,
													   defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN,
													   textureElementSizes: Object = null): void
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

				sHelperRectangle.setTo(0, 0, elementWidth, elementHeight);
				sHelperMatrix.copyFrom(element.pivotMatrix);
				var invertScale: Number = 1 / scale;
				sHelperMatrix.scale(invertScale, invertScale);
				RectangleUtil.getBounds(sHelperRectangle, sHelperMatrix, sHelperRectangle);

				if (!textureElementSizes[elementAtlasID])
				{
					textureElementSizes[elementAtlasID] = sHelperRectangle.clone();
				}
				else
				{
					textureElementSizes[elementAtlasID] = textureElementSizes[elementAtlasID].union(sHelperRectangle);
				}
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
				else // BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_MASKS2
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

		private static function readAnimationSequences(tagContent: ByteArray, timelineConfig: GAFTimelineConfig): void
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

		private static function readNamedParts(tagContent: ByteArray, timelineConfig: GAFTimelineConfig): void
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

		private static function readTextFields(tagContent: ByteArray, timelineConfig: GAFTimelineConfig): void
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
