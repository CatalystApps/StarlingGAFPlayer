package com.catalystapps.gaf.data.converters
{
	import flash.utils.setTimeout;
	import flash.events.Event;
	import com.catalystapps.gaf.data.GAFAssetConfig;
	import flash.events.EventDispatcher;
	import com.catalystapps.gaf.data.GAFTimelineConfig;
	import com.catalystapps.gaf.data.config.CAnimationFrame;
	import com.catalystapps.gaf.data.config.CAnimationFrameInstance;
	import com.catalystapps.gaf.data.config.CAnimationFrames;
	import com.catalystapps.gaf.data.config.CAnimationObject;
	import com.catalystapps.gaf.data.config.CAnimationObjects;
	import com.catalystapps.gaf.data.config.CAnimationSequence;
	import com.catalystapps.gaf.data.config.CAnimationSequences;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.data.config.CFrameAction;
	import com.catalystapps.gaf.data.config.CStage;
	import com.catalystapps.gaf.data.config.CTextFieldObject;
	import com.catalystapps.gaf.data.config.CTextFieldObjects;
	import com.catalystapps.gaf.data.config.CTextureAtlasCSF;
	import com.catalystapps.gaf.data.config.CTextureAtlasElement;
	import com.catalystapps.gaf.data.config.CTextureAtlasElements;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;
	import com.catalystapps.gaf.data.config.CTextureAtlasSource;

	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.TextFormat;

	/**
	 * @private
	 */
	public class JsonGAFAssetConfigConverter extends EventDispatcher implements IGAFAssetConfigConverter
	{
		public static const FILTER_BLUR: String = "Fblur";
		public static const FILTER_COLOR_TRANSFORM: String = "Fctransform";
		public static const FILTER_DROP_SHADOW: String = "FdropShadowFilter";
		public static const FILTER_GLOW: String = "FglowFilter";
		
		private var _assetID: String;
		private var _json: String;
		private var _defaultScale: Number;
		private var _defaultContentScaleFactor: Number;
		private var jsonObject: Object;
		private var _config: GAFAssetConfig;

		// --------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		public function JsonGAFAssetConfigConverter(assetID: String, json: String, defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN)
		{
			_defaultContentScaleFactor = defaultContentScaleFactor;
			_defaultScale = defaultScale;
			_json = json;
			_assetID = assetID;
		}
		
		public function convert(): void
		{
			setTimeout(parse, 1);
		}

		private function parse(): void
		{
			jsonObject = JSON.parse(_json);
			
			_config = new GAFAssetConfig(_assetID);

			var timelineConfig: GAFTimelineConfig;

			if (jsonObject.animations)
			{
				for each (var configObject: Object in jsonObject.animations)
				{
					timelineConfig = new GAFTimelineConfig(jsonObject.version);
					timelineConfig.id = configObject.id;
					timelineConfig.assetID = _assetID;
					if (configObject.linkage)
					{
						timelineConfig.linkage = configObject.linkage;
					}
					convertConfig(timelineConfig);
					_config.timelines.push(timelineConfig);
				}
			}
			else
			{
				timelineConfig = new GAFTimelineConfig(jsonObject.version);
				timelineConfig.id = "0";
				timelineConfig.assetID = _assetID;
				convertConfig(timelineConfig);
				_config.timelines.push(timelineConfig);
			}

			if (jsonObject.stageConfig)
			{
				for each (timelineConfig in _config.timelines)
				{
					timelineConfig.stageConfig = new CStage().clone(jsonObject.stageConfig);
				}
			}

			///////////////////////////////////////////////////////////////

			dispatchEvent(new Event(Event.COMPLETE));
		}

		private function convertConfig(config: GAFTimelineConfig): void
		{
			var allTextureAtlases: Vector.<CTextureAtlasScale> = new Vector.<CTextureAtlasScale>();

			if (jsonObject.textureAtlas) // timeline has atlas
			{
				var textureAtlas: CTextureAtlasScale;

				for each (var ta: Object in jsonObject.textureAtlas)
				{
					var scale: Number = ta.scale;

					textureAtlas = new CTextureAtlasScale();
					textureAtlas.scale = scale;

					/////////////////////

					var elements: CTextureAtlasElements = new CTextureAtlasElements();

					for each (var e: Object in ta.elements)
					{
						var element: CTextureAtlasElement = new CTextureAtlasElement(e.name, e.atlasID,
								new Rectangle(int(e.x), int(e.y), e.width, e.height),
								new Matrix(1 / e.scale, 0, 0, 1 / e.scale, -e.pivotX / e.scale, -e.pivotY / e.scale));
						if (e.scale9Grid != undefined)
						{
							element.scale9Grid = new Rectangle(e.scale9Grid.x, e.scale9Grid.y, e.scale9Grid.width,
									e.scale9Grid.height);
						}
						elements.addElement(element);
					}

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
						item.elements = elements;

						contentScaleFactors.push(item);

						if (!isNaN(_defaultContentScaleFactor) && _defaultContentScaleFactor == csf)
						{
							textureAtlas.contentScaleFactor = item;
						}

						return item;
					};

					/////////////////////

					for each (var at: Object in ta.atlases)
					{
						for each (var atSource: Object in at.sources)
						{
							contentScaleFactor = getContentScaleFactor(atSource.csf);

							contentScaleFactor.sources.push(new CTextureAtlasSource(at.id, atSource.source));
						}
					}

					textureAtlas.allContentScaleFactors = contentScaleFactors;

					if (!textureAtlas.contentScaleFactor && contentScaleFactors.length)
					{
						textureAtlas.contentScaleFactor = contentScaleFactors[0];
					}

					/////////////////////

					allTextureAtlases.push(textureAtlas);

					if (!isNaN(_defaultScale) && _defaultScale == scale)
					{
						config.textureAtlas = textureAtlas;
					}
				}
			}
			else if (jsonObject.scales != null && jsonObject.csfs != null) // timeline hasn't atlas, create empty
			{
				for each (var scale: Number in jsonObject.scales)
				{
					textureAtlas = new CTextureAtlasScale();
					textureAtlas.scale = scale;

					textureAtlas.allContentScaleFactors = new Vector.<CTextureAtlasCSF>();
					for each (var csf: Number in jsonObject.csfs)
					{
						var item: CTextureAtlasCSF;
						item = new CTextureAtlasCSF(csf, scale);

						if ((!isNaN(_defaultContentScaleFactor) && _defaultContentScaleFactor == csf)
								|| !textureAtlas.contentScaleFactor)
						{
							textureAtlas.contentScaleFactor = item;
						}

						textureAtlas.allContentScaleFactors.push(item);
					}
					allTextureAtlases.push(textureAtlas);
					if (!isNaN(_defaultScale) && _defaultScale == scale)
					{
						config.textureAtlas = textureAtlas;
					}
				}
			}

			config.allTextureAtlases = allTextureAtlases;

			if (!config.textureAtlas && allTextureAtlases.length)
			{
				config.textureAtlas = allTextureAtlases[0];
			}

			///////////////////////////////////////////////////////////////

			var animationObjects: CAnimationObjects = new CAnimationObjects();
			var animObject: Object;

			if (jsonObject.animationObjects)
			{

				for (var ao: String in jsonObject.animationObjects)
				{
					animObject = jsonObject.animationObjects[ao];
					if (animObject is String) // old version
					{
						animationObjects.addAnimationObject(new CAnimationObject(ao, animObject as String,
								CAnimationObject.TYPE_TEXTURE, false));
					}
					else
					{
						animationObjects.addAnimationObject(new CAnimationObject(ao, jsonObject.animationObjects[ao].id,
								jsonObject.animationObjects[ao].type, false));
					}
				}
			}

			if (jsonObject.animationMasks)
			{
				for (var am: String in jsonObject.animationMasks)
				{
					animObject = jsonObject.animationMasks[am];
					if (animObject is String) // old version
					{
						animationObjects.addAnimationObject(new CAnimationObject(am, animObject as String,
								CAnimationObject.TYPE_TEXTURE, true));
					}
					else
					{
						animationObjects.addAnimationObject(new CAnimationObject(am, jsonObject.animationMasks[am].id,
								jsonObject.animationMasks[am].type, true));
					}

				}
			}

			config.animationObjects = animationObjects;

			///////////////////////////////////////////////////////////////

			var animationSequences: CAnimationSequences = new CAnimationSequences();

			if (jsonObject.animationSequences)
			{
				for each(var asq: Object in jsonObject.animationSequences)
				{
					animationSequences.addSequence(new CAnimationSequence(asq.id, asq.startFrameNo, asq.endFrameNo));
				}
			}

			config.animationSequences = animationSequences;

			///////////////////////////////////////////////////////////////

			var textFieldObjects: CTextFieldObjects = new CTextFieldObjects();

			if (jsonObject.textFields)
			{
				for each (var tf: Object in jsonObject.textFields)
				{
					var textFormatObj: Object = tf.textFormat;
					var textFormat: TextFormat = new TextFormat(
							textFormatObj.font,
							textFormatObj.size,
							textFormatObj.color,
							textFormatObj.bold,
							textFormatObj.italic,
							textFormatObj.underline,
							textFormatObj.url,
							textFormatObj.target,
							textFormatObj.align,
							textFormatObj.leftMargin,
							textFormatObj.rightMargin,
							textFormatObj.indent,
							textFormatObj.leading
					);
					textFormat.bullet = textFormatObj.bullet;
					textFormat.blockIndent = textFormatObj.blockIndent;
					textFormat.kerning = textFormatObj.kerning;
					textFormat.display = textFormatObj.display;
					textFormat.letterSpacing = textFormatObj.letterSpacing;
					textFormat.tabStops = textFormatObj.tabStops;

					var textFieldObject: CTextFieldObject = new CTextFieldObject(tf.id, tf.text, textFormat, tf.width, tf.height);
					textFieldObject.embedFonts = tf.embedFonts;
					textFieldObject.multiline = tf.multiline;
					textFieldObject.wordWrap = tf.wordWrap;
					textFieldObject.restrict = tf.restrict;
					textFieldObject.editable = tf.editable;
					textFieldObject.selectable = tf.selectable;
					textFieldObject.displayAsPassword = tf.displayAsPassword;
					textFieldObject.maxChars = tf.maxChars;
					textFieldObjects.addTextFieldObject(textFieldObject);
				}
			}

			config.textFields = textFieldObjects;

			///////////////////////////////////////////////////////////////

			config.namedParts = {};

			if (jsonObject.namedParts)
			{
				for (var id: String in jsonObject.namedParts)
				{
					config.namedParts[id] = jsonObject.namedParts[id];
				}
			}

			///////////////////////////////////////////////////////////////

			var animationConfigFrames: CAnimationFrames = new CAnimationFrames();

			var currentFrame: CAnimationFrame;
			var prevFrame: CAnimationFrame;
			var f: Object;
			var states: Object;

			var state: Object;
			var maskID: String;
			var filter: CFilter;
			var instance: CAnimationFrameInstance;
			var stateConfig: String;
			var missedFrameNumber: uint;
			var io: Array;

			if (jsonObject.animationConfigFrames && jsonObject.animationConfigFrames.length)
			{
				for each(f in jsonObject.animationConfigFrames)
				{
					if (prevFrame)
					{
						currentFrame = prevFrame.clone(f.frameNumber);

						for (missedFrameNumber = prevFrame.frameNumber + 1; missedFrameNumber < currentFrame.frameNumber; missedFrameNumber++)
						{
							animationConfigFrames.addFrame(prevFrame.clone(missedFrameNumber));
						}
					}
					else
					{
						currentFrame = new CAnimationFrame(f.frameNumber);

						if (currentFrame.frameNumber > 1)
						{
							for (missedFrameNumber = 1; missedFrameNumber < currentFrame.frameNumber; missedFrameNumber++)
							{
								animationConfigFrames.addFrame(new CAnimationFrame(missedFrameNumber));
							}
						}
					}

					states = f.state;

					for (var stateID: String in states)
					{
						state = states[stateID];

						maskID = "";
						if (state.hasOwnProperty("m"))
						{
							maskID = state["m"];
						}

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

						if (state.hasOwnProperty("c"))
						{
							var params: Vector.<Number> = Vector.<Number>(String(state["c"]).replace(" ", "").split(","));

							checkAndInitFilter();

							filter.addColorTransform(params);
						}

						if (state.hasOwnProperty("e"))
						{
							var warning: String;

							for each (var filterConfig: Object in state["e"])
							{
								switch (filterConfig["t"])
								{
									case JsonGAFAssetConfigConverter.FILTER_BLUR:
										checkAndInitFilter();
										warning = filter.addBlurFilter(filterConfig["x"], filterConfig["y"]);
										break;
									case JsonGAFAssetConfigConverter.FILTER_COLOR_TRANSFORM:
										checkAndInitFilter();
										warning = filter.addColorMatrixFilter(Vector.<Number>(filterConfig["matrix"]));
										break;
									case JsonGAFAssetConfigConverter.FILTER_DROP_SHADOW:
										checkAndInitFilter();
										warning = filter.addDropShadowFilter(filterConfig["x"], filterConfig["y"],
												filterConfig["color"],
												filterConfig["alpha"],
												filterConfig["angle"],
												filterConfig["distance"]);
										break;
									case JsonGAFAssetConfigConverter.FILTER_GLOW:
										checkAndInitFilter();
										warning = filter.addGlowFilter(filterConfig["x"], filterConfig["y"],
												filterConfig["color"], filterConfig["alpha"]);
										break;
									default:
										trace(WarningConstants.UNSUPPORTED_FILTERS);
										break;
								}

								config.addWarning(warning);
							}
						}

						stateConfig = state["st"];
						stateConfig = stateConfig.replace("{", "");
						stateConfig = stateConfig.replace("}", "");

						io = stateConfig.split(",");

						instance = new CAnimationFrameInstance(stateID);
						instance.update(io[0], new Matrix(io[1], io[2], io[3], io[4], io[5], io[6]), io[7], maskID,
								filter);

						if (maskID && filter)
						{
							config.addWarning(WarningConstants.FILTERS_UNDER_MASK);
						}

						currentFrame.addInstance(instance);
					}

					currentFrame.sortInstances();

					if (f.hasOwnProperty("actions"))
					{
						var action: CFrameAction;

						for (var i: int = 0; i < f.actions.length; i++)
						{
							action = new CFrameAction();
							action.type = f.actions[i].type;

							if (f.actions[i].type > 1) // if not stop(); or play(); and has params
							{
								for (var p: int = 0; p < f.actions[i].paramsCount; p++)
								{
									action.params[p] = f.actions[i].params[p];
								}
							}
						}
						currentFrame.addAction(action);
					}

					animationConfigFrames.addFrame(currentFrame);

					prevFrame = currentFrame;
				}

				for (missedFrameNumber = prevFrame.frameNumber + 1; missedFrameNumber <= jsonObject.animationFrameCount; missedFrameNumber++)
				{
					animationConfigFrames.addFrame(prevFrame.clone(missedFrameNumber));
				}
			}

			config.animationConfigFrames = animationConfigFrames;

			///////////////////////////////////////////////////////////////

			//debug info reading

//			var debugRegion: GAFDebugInformation;
//
//			if (jsonObject.pivotPoint)
//			{
//				debugRegion = new GAFDebugInformation();
//				debugRegion.type = GAFDebugInformation.TYPE_POINT;
//				debugRegion.point = new Point(jsonObject.pivotPoint.x, jsonObject.pivotPoint.y);
//				debugRegion.color = 0xff0000;
//				debugRegion.alpha = 0.8;
//				config.debugRegions.push(debugRegion);
//			}
//
//			if (jsonObject.boundingBox)
//			{
//				debugRegion = new GAFDebugInformation();
//				debugRegion.type = GAFDebugInformation.TYPE_RECT;
//				debugRegion.rect = new Rectangle(jsonObject.boundingBox.x, jsonObject.boundingBox.y, jsonObject.boundingBox.width, jsonObject.boundingBox.height);
//				debugRegion.color = 0x00ff00;
//				debugRegion.alpha = 0.3;
			// config.debugRegions.push(debugRegion);
			// }
		}

		public function get config(): GAFAssetConfig
		{
			return _config;
		}
	}
}
