package com.catalystapps.gaf.data.converters
{
	import com.catalystapps.gaf.data.config.CStage;

	import flash.utils.CompressionAlgorithm;

	import com.catalystapps.gaf.data.config.CTextureAtlasElements;
	import com.catalystapps.gaf.data.config.CAnimationSequence;
	import com.catalystapps.gaf.data.config.CAnimationSequences;
	import com.catalystapps.gaf.data.config.CAnimationObject;
	import com.catalystapps.gaf.data.config.CTextureAtlasElement;
	import com.catalystapps.gaf.data.config.CTextureAtlasSource;
	import com.catalystapps.gaf.data.config.CTextureAtlasCSF;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.data.config.CAnimationFrameInstance;
	import com.catalystapps.gaf.data.config.CAnimationFrame;
	import com.catalystapps.gaf.data.config.CAnimationFrames;

	import flash.geom.Matrix;

	import com.catalystapps.gaf.data.config.CAnimationObjects;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;

	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Endian;

	import com.catalystapps.gaf.data.GAFAssetConfig;

	import flash.utils.ByteArray;

	/**
	 * @private
	 */
	public class BinGAFAssetConfigConverter
	{
		private static const SIGNATURE_GAF: uint = 0x00474146;
		private static const SIGNATURE_GAC: uint = 0x00474143;
		private static const HEADER_LENGTH: uint = 36;
		private static const FIXED8_DIVISION: uint = 256;
		// tags
		private static const TAG_END: uint = 0;
		private static const TAG_DEFINE_ATLAS: uint = 1;
		private static const TAG_DEFINE_ANIMATION_MASKS: uint = 2;
		private static const TAG_DEFINE_ANIMATION_OBJECTS: uint = 3;
		private static const TAG_DEFINE_ANIMATION_FRAMES: uint = 4;
		private static const TAG_DEFINE_NAMED_PARTS: uint = 5;
		private static const TAG_DEFINE_SEQUENCES: uint = 6;
		private static const TAG_DEFINE_STAGE: uint = 9;
		// filters
		private static const FILTER_DROP_SHADOW: uint = 0;
		private static const FILTER_BLUR: uint = 1;
		private static const FILTER_GLOW: uint = 2;
		private static const FILTER_COLOR_MATRIX: uint = 6;

		// --------------------------------------------------------------------------
		//
		// PUBLIC METHODS
		//
		// --------------------------------------------------------------------------
		public static function convert(bytes: ByteArray, defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN): GAFAssetConfig
		{
			bytes.endian = Endian.LITTLE_ENDIAN;

			var header: int = bytes.readInt();
			var versionMajor: int = bytes.readByte();
			var versionMinor: int = bytes.readByte();
			var fileLength: uint = bytes.readUnsignedInt();

			switch (header)
			{
				case SIGNATURE_GAC:
					bytes = decompressConfig(bytes);
					break;
			}

			var framesCount: uint = bytes.readShort();
			var animationBounds: Rectangle = new Rectangle(bytes.readFloat(), bytes.readFloat(), bytes.readFloat(), bytes.readFloat());
			var animationPoint: Point = new Point(bytes.readFloat(), bytes.readFloat());

			var result: GAFAssetConfig = new GAFAssetConfig(versionMajor + "." + versionMinor);
			result.allTextureAtlases = new Vector.<CTextureAtlasScale>();
			result.animationObjects = new CAnimationObjects();
			result.animationSequences = new CAnimationSequences();

			while (bytes.bytesAvailable > 0)
			{
				readNextTag(bytes, result, framesCount, defaultScale, defaultContentScaleFactor);
			}

			if (!result.textureAtlas && result.allTextureAtlases.length)
			{
				result.textureAtlas = result.allTextureAtlases[0];
			}

			return result;
		}

		private static function decompressConfig(bytes: ByteArray): ByteArray
		{
			var uncompressedBA: ByteArray = new ByteArray();
			uncompressedBA.endian = Endian.LITTLE_ENDIAN;

			bytes.readBytes(uncompressedBA);
			bytes.clear();
			
			uncompressedBA.uncompress(CompressionAlgorithm.ZLIB);

			return uncompressedBA;
		}

		// --------------------------------------------------------------------------
		//
		// PRIVATE METHODS
		//
		// --------------------------------------------------------------------------
		private static function readNextTag(bytes: ByteArray, config: GAFAssetConfig, animationFramesCount: uint, defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN): void
		{
			var tagID: int = bytes.readShort();
			var tagLength: uint = bytes.readUnsignedInt();
			var tagContent: ByteArray = new ByteArray();
			tagContent.endian = Endian.LITTLE_ENDIAN;
			bytes.readBytes(tagContent, 0, tagLength);
			tagContent.position = 0;

			switch (tagID)
			{
				case BinGAFAssetConfigConverter.TAG_DEFINE_STAGE:
					readStageConfig(tagContent, config);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_ATLAS:
					readTextureAtlasConfig(tagContent, config, defaultScale, defaultContentScaleFactor);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_MASKS:
					readAnimationMasks(tagContent, config);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_OBJECTS:
					readAnimationObjects(tagContent, config);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_ANIMATION_FRAMES:
					readAnimationFrames(tagContent, config, animationFramesCount);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_NAMED_PARTS:
					readNamedParts(tagContent, config);
					break;
				case BinGAFAssetConfigConverter.TAG_DEFINE_SEQUENCES:
					readAnimationSequences(tagContent, config);
					break;
				case BinGAFAssetConfigConverter.TAG_END:
					break;
				default:
					trace(WarningConstants.UNSUPPORTED_TAG);
					break;
			}
		}

		private static function readStageConfig(tagContent: ByteArray, config: GAFAssetConfig): void
		{
			var stageConfig: CStage = new CStage();

			stageConfig.fps = tagContent.readByte();
			stageConfig.color = tagContent.readInt();
			stageConfig.width = tagContent.readUnsignedShort();
			stageConfig.height = tagContent.readUnsignedShort();

			config.stageConfig = stageConfig;
		}

		private static function readAnimationFrames(tagContent: ByteArray, config: GAFAssetConfig, animationFramesCount: uint): void
		{
			var framesCount: uint = tagContent.readUnsignedInt();
			var frameNumber: uint;
			var statesCount: uint;
			var hasColorTransform: Boolean;
			var hasMask: Boolean;
			var hasEffect: Boolean;
			var stateID: uint;
			var zindex: int;
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

			for (var i: uint = 0; i < framesCount; i++)
			{
				frameNumber = tagContent.readUnsignedInt();
				statesCount = tagContent.readUnsignedInt();

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

				for (var j: uint = 0; j < statesCount; j++)
				{
					hasColorTransform = tagContent.readBoolean();
					hasMask = tagContent.readBoolean();
					hasEffect = tagContent.readBoolean();

					stateID = tagContent.readUnsignedInt();
					zindex = tagContent.readInt();
					alpha = tagContent.readFloat();
					matrix = new Matrix(tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat());

					filter = null;

					if (hasColorTransform)
					{
						var params: Array = [tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat()];

						filter = !filter ? new CFilter() : filter;

						filter.addColorTransform(params);

						alpha = Math.max(Math.min(alpha + params[0], 1), 0);
					}

					if (hasEffect)
					{
						filter = !filter ? new CFilter() : filter;

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

							config.addWarning(warning);
						}
					}

					if (hasMask)
					{
						maskID = tagContent.readUnsignedInt() + "";
					}
					else
					{
						maskID = null;
					}

					instance = new CAnimationFrameInstance(stateID + "");
					instance.update(zindex, matrix, alpha, maskID, filter);

					if (maskID && filter)
					{
						config.addWarning(WarningConstants.FILTERS_UNDER_MASK);
					}

					currentFrame.addInstance(instance);
				}

				currentFrame.sortInstances();

				animationConfigFrames.addFrame(currentFrame);

				prevFrame = currentFrame;
			}

			for (missedFrameNumber = prevFrame.frameNumber + 1; missedFrameNumber <= animationFramesCount; missedFrameNumber++)
			{
				animationConfigFrames.addFrame(prevFrame.clone(missedFrameNumber));
			}

			config.animationConfigFrames = animationConfigFrames;
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
			var matrix: Array = [];
			for (var i: uint = 0; i < 20; i++)
			{
				matrix.push(source.readFloat());
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

		private static function readTextureAtlasConfig(tagContent: ByteArray, config: GAFAssetConfig, defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN): void
		{
			var i: uint;
			var j: uint;

			var scale: Number = tagContent.readFloat();
			var textureAtlas: CTextureAtlasScale = new CTextureAtlasScale();
			textureAtlas.scale = scale;

			// ///////////////////

			var contentScaleFactors: Vector.<CTextureAtlasCSF> = new Vector.<CTextureAtlasCSF>();
			var contentScaleFactor: CTextureAtlasCSF;

			// ///////////////////
				
			function getContentScaleFactor(csf: Number): CTextureAtlasCSF
			{
				var item: CTextureAtlasCSF;

				for each (item in contentScaleFactors)
				{
					if (item.csf == csf)
					{
						return item;
					}
				}

				item = new CTextureAtlasCSF(csf, scale);
				contentScaleFactors.push(item);

				if (!isNaN(defaultContentScaleFactor) && defaultContentScaleFactor == csf)
				{
					textureAtlas.contentScaleFactor = item;
				}

				return item;
			}
			;

			// ///////////////////

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

			// ///////////////////

			var elementsLength: uint = tagContent.readUnsignedInt();
			var element: CTextureAtlasElement;
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

				element = new CTextureAtlasElement(elementAtlasID + "", atlasID + "", new Rectangle(int(topLeft.x), int(topLeft.y), elementWidth, elementHeight), new Matrix(1 / elementScale, 0, 0, 1 / elementScale, -pivot.x / elementScale, -pivot.y / elementScale));
				elements.addElement(element);
			}

			for each (contentScaleFactor in contentScaleFactors)
			{
				contentScaleFactor.elements = elements;
			}

			config.allTextureAtlases.push(textureAtlas);

			if (!isNaN(defaultScale) && defaultScale == scale)
			{
				config.textureAtlas = textureAtlas;
			}
		}

		private static function readAnimationMasks(tagContent: ByteArray, config: GAFAssetConfig): void
		{
			var length: int = tagContent.readUnsignedInt();
			var objectID: int;
			var atlasRegionID: int;

			for (var i: uint = 0; i < length; i++)
			{
				objectID = tagContent.readUnsignedInt();
				atlasRegionID = tagContent.readUnsignedInt();
				config.animationObjects.addAnimationObject(new CAnimationObject(objectID + "", atlasRegionID + "", true));
			}
		}

		private static function readAnimationObjects(tagContent: ByteArray, config: GAFAssetConfig): void
		{
			var length: int = tagContent.readUnsignedInt();
			var objectID: int;
			var atlasRegionID: int;

			for (var i: uint = 0; i < length; i++)
			{
				objectID = tagContent.readUnsignedInt();
				atlasRegionID = tagContent.readUnsignedInt();
				config.animationObjects.addAnimationObject(new CAnimationObject(objectID + "", atlasRegionID + "", false));
			}
		}

		private static function readAnimationSequences(tagContent: ByteArray, config: GAFAssetConfig): void
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
				config.animationSequences.addSequence(new CAnimationSequence(sequenceID, startFrameNo, endFrameNo));
			}
		}

		private static function readNamedParts(tagContent: ByteArray, config: GAFAssetConfig): void
		{
		}
	}
}
