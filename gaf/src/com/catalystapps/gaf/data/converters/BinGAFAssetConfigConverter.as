package com.catalystapps.gaf.data.converters
{
	import com.catalystapps.gaf.data.GAFAssetConfig;
	import com.catalystapps.gaf.data.GAFAssetConfigs;
	import com.catalystapps.gaf.data.config.CAnimationFrame;
	import com.catalystapps.gaf.data.config.CAnimationFrameInstance;
	import com.catalystapps.gaf.data.config.CAnimationFrames;
	import com.catalystapps.gaf.data.config.CAnimationObject;
	import com.catalystapps.gaf.data.config.CAnimationObjects;
	import com.catalystapps.gaf.data.config.CAnimationSequence;
	import com.catalystapps.gaf.data.config.CAnimationSequences;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.data.config.CStage;
	import com.catalystapps.gaf.data.config.CTextFieldObject;
	import com.catalystapps.gaf.data.config.CTextFieldObjects;
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
	public class BinGAFAssetConfigConverter
	{
		private static const SIGNATURE_GAF: uint = 0x00474146;
		private static const SIGNATURE_GAC: uint = 0x00474143;
		private static const HEADER_LENGTH: uint = 36;

		private static const FIXED8_DIVISION: uint = 256;

		//tags
		private static const TAG_END: uint = 0;
		private static const TAG_DEFINE_ATLAS: uint = 1;
		private static const TAG_DEFINE_ANIMATION_MASKS: uint = 2;
		private static const TAG_DEFINE_ANIMATION_OBJECTS: uint = 3;
		private static const TAG_DEFINE_ANIMATION_FRAMES: uint = 4;
		private static const TAG_DEFINE_NAMED_PARTS: uint = 5;
		private static const TAG_DEFINE_SEQUENCES: uint = 6;
		private static const TAG_DEFINE_TEXT_FIELDS: uint = 7;
		private static const TAG_DEFINE_ATLAS2: uint = 8;

		private static const TAG_DEFINE_STAGE: uint = 9;

		//filters
		private static const FILTER_DROP_SHADOW: uint = 0;
		private static const FILTER_BLUR: uint = 1;
		private static const FILTER_GLOW: uint = 2;
		private static const FILTER_COLOR_MATRIX: uint = 6;

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		public static function convert(configID: String, bytes: ByteArray, defaultScale: Number = NaN,
		                               defaultContentScaleFactor: Number = NaN): GAFAssetConfigs
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
			var animationBounds: Rectangle = new Rectangle(bytes.readFloat(), bytes.readFloat(), bytes.readFloat(),
			                                               bytes.readFloat());
			var animationPoint: Point = new Point(bytes.readFloat(), bytes.readFloat());

			var result: GAFAssetConfig = new GAFAssetConfig(versionMajor + "." + versionMinor);
			result.allTextureAtlases = new Vector.<CTextureAtlasScale>();
			result.animationObjects = new CAnimationObjects();
			result.animationSequences = new CAnimationSequences();
			result.textFields = new CTextFieldObjects();

			while (bytes.bytesAvailable > 0)
			{
				readNextTag(bytes, result, framesCount, defaultScale, defaultContentScaleFactor);
			}

			if (!result.textureAtlas && result.allTextureAtlases.length)
			{
				result.textureAtlas = result.allTextureAtlases[0];
			}

			var configs: GAFAssetConfigs = new GAFAssetConfigs();
			configs.configs.push(result);
			return configs;
		}

		private static function decompressConfig(bytes: ByteArray): ByteArray
		{
			var uncompressedBA: ByteArray = new ByteArray();
			uncompressedBA.endian = Endian.LITTLE_ENDIAN;

			bytes.readBytes(uncompressedBA);

			uncompressedBA.uncompress(CompressionAlgorithm.ZLIB);

			return uncompressedBA;
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		private static function readNextTag(bytes: ByteArray, config: GAFAssetConfig, animationFramesCount: uint,
		                                    defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN): void
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
				case BinGAFAssetConfigConverter.TAG_DEFINE_ATLAS2:
					readTextureAtlasConfig(tagContent, config, defaultScale, defaultContentScaleFactor, tagID);
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
				case BinGAFAssetConfigConverter.TAG_DEFINE_TEXT_FIELDS:
					readTextFields(tagContent, config);
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

			trace(stageConfig.fps, stageConfig.color, stageConfig.width, stageConfig.height);
			config.stageConfig = stageConfig;
		}

		private static function readAnimationFrames(tagContent: ByteArray, config: GAFAssetConfig,
		                                            animationFramesCount: uint): void
		{
			var framesCount: uint = tagContent.readUnsignedInt();
			var frameNumber: uint;
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
					zIndex = tagContent.readInt();
					alpha = tagContent.readFloat();
					matrix = new Matrix(tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat(),
					                    tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat());

					///////////////////////////////////////////

					function checkAndInitFilter(): void
					{
						if (!filter)
						{
							filter = new CFilter();
						}
					};

					///////////////////////////////////////////

					filter = null;

					if (hasColorTransform)
					{
						var params: Vector.<Number> = new <Number>[tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat(),
							tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat(), tagContent.readFloat()];
						params.fixed = true;
						checkAndInitFilter();

						filter.addColorTransform(params);
					}

					if (hasEffect)
					{
						checkAndInitFilter();

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
						maskID = "";
					}

					instance = new CAnimationFrameInstance(stateID + "");
					instance.update(zIndex, matrix, alpha, maskID, filter);

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
			var matrix: Vector.<Number> = new Vector.<Number>(20, true);
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

		private static function readTextureAtlasConfig(tagContent: ByteArray, config: GAFAssetConfig,
		                                               defaultScale: Number = NaN,
		                                               defaultContentScaleFactor: Number = NaN,
		                                               tagID: uint = BinGAFAssetConfigConverter.TAG_DEFINE_ATLAS): void
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
				                                   new Rectangle(int(topLeft.x), int(topLeft.y), elementWidth,
				                                                 elementHeight),
				                                   new Matrix(1 / elementScale, 0, 0, 1 / elementScale,
				                                              -pivot.x / elementScale, -pivot.y / elementScale));
				element.scale9Grid = scale9Grid;
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
			var staticObjectID: int;
			var type: String;

			for (var i: uint = 0; i < length; i++)
			{
				objectID = tagContent.readUnsignedInt();
				staticObjectID = tagContent.readUnsignedInt();
				config.animationObjects.addAnimationObject(new CAnimationObject(objectID + "", staticObjectID + "", "texture", true));
			}
		}

		private static function readAnimationMasks2(tagContent: ByteArray, config: GAFAssetConfig): void
		{
			var length: int = tagContent.readUnsignedInt();
			var objectID: int;
			var staticObjectID: int;
			var type: String;

			for (var i: uint = 0; i < length; i++)
			{
				objectID = tagContent.readUnsignedInt();
				staticObjectID = tagContent.readUnsignedInt();
				var l: uint = tagContent.readShort();
				type = tagContent.readUTFBytes(l);
				config.animationObjects.addAnimationObject(new CAnimationObject(objectID + "", staticObjectID + "",
				                                                                type + "",
				                                                                true));
			}
		}

		private static function readAnimationObjects(tagContent: ByteArray, config: GAFAssetConfig): void
		{
			var length: int = tagContent.readUnsignedInt();
			var objectID: int;
			var staticObjectID: int;
			var type: String;

			for (var i: uint = 0; i < length; i++)
			{
				objectID = tagContent.readUnsignedInt();
				staticObjectID = tagContent.readUnsignedInt();
				config.animationObjects.addAnimationObject(new CAnimationObject(objectID + "", staticObjectID + "", "texture", false));
			}
		}

		private static function readAnimationObjects2(tagContent: ByteArray, config: GAFAssetConfig): void
		{
			var length: int = tagContent.readUnsignedInt();
			var objectID: int;
			var staticObjectID: int;
			var type: String;

			for (var i: uint = 0; i < length; i++)
			{
				objectID = tagContent.readUnsignedInt();
				staticObjectID = tagContent.readUnsignedInt();
				var l: uint = tagContent.readShort();
				type = tagContent.readUTFBytes(l);
				config.animationObjects.addAnimationObject(new CAnimationObject(objectID + "", staticObjectID + "",
								type + "",
						false));
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

		private static function readTextFields(tagContent: ByteArray, config: GAFAssetConfig): void
		{
			var length: int = tagContent.readUnsignedInt();
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
				width = tagContent.readFloat();
				height = tagContent.readFloat();

				var l: uint = tagContent.readShort();
				text = tagContent.readUTFBytes(l);

				embedFonts = tagContent.readBoolean();
				multiline = tagContent.readBoolean();
				wordWrap = tagContent.readBoolean();

				var hasRestrict: Boolean = tagContent.readBoolean();
				if (hasRestrict)
				{
					l = tagContent.readShort();
					restrict = tagContent.readUTFBytes(l);
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

				l = tagContent.readShort();
				var font: String = tagContent.readUTFBytes(l);
				var indent: uint = tagContent.readUnsignedInt();
				var italic: Boolean = tagContent.readBoolean();
				var kerning: Boolean = tagContent.readBoolean();
				var leading: int = tagContent.readUnsignedInt();
				var leftMargin: Number = tagContent.readUnsignedInt();
				var letterSpacing: Number = tagContent.readFloat();
				var rightMargin: Number = tagContent.readUnsignedInt();
				var size: int = tagContent.readUnsignedInt();

				l = tagContent.readUnsignedInt();
				var tabStops: Array = [];
				for (var j: uint = 0; j < l; j++)
				{
					tabStops.push(tagContent.readUnsignedInt());
				}

				l = tagContent.readShort();
				var target: String = tagContent.readUTFBytes(l);
				var underline: Boolean = tagContent.readBoolean();
				l = tagContent.readShort();
				var url: String = tagContent.readUTFBytes(l);

				/*l = tagContent.readShort();
				 var display: String = tagContent.readUTFBytes(l);*/

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
				textFieldObject.embedFonts = embedFonts;
				textFieldObject.multiline = multiline;
				textFieldObject.wordWrap = wordWrap;
				textFieldObject.restrict = restrict;
				textFieldObject.editable = editable;
				textFieldObject.selectable = selectable;
				textFieldObject.displayAsPassword = displayAsPassword;
				textFieldObject.maxChars = maxChars;
				config.textFields.addTextFieldObject(textFieldObject);
			}
		}
	}
}
