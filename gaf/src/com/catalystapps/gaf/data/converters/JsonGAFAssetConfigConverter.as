package com.catalystapps.gaf.data.converters
{
	import com.catalystapps.gaf.data.config.CBlurFilterData;
	import flash.events.ErrorEvent;
	import flash.geom.Point;
	import com.catalystapps.gaf.data.GAFAssetConfig;
	import flash.utils.setTimeout;
	import flash.events.Event;
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
		private var assetID: String;
		private var json: String;
		private var defaultScale: Number;
		private var defaultContentScaleFactor: Number;
		private var _config: GAFAssetConfig;

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		public function JsonGAFAssetConfigConverter(assetID: String, json: String, defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN)
		{
			this.defaultContentScaleFactor = defaultContentScaleFactor;
			this.defaultScale = defaultScale;
			this.json = json;
			this.assetID = assetID;
		}
		
		private static function convertConfig(timelineConfig: GAFTimelineConfig, jsonObject: Object, defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN, scales: Array = null, csfs: Array = null): GAFTimelineConfig
		{
			if (jsonObject.stageConfig)
			{
				jsonObject.stageConfig = new CStage().clone(jsonObject.stageConfig);
			}
			
			///////////////////////////////////////////////////////////////
			
			var scale: Number;
			var allTextureAtlases: Vector.<CTextureAtlasScale> = new Vector.<CTextureAtlasScale>();
			
			if (jsonObject.textureAtlas) // timeline has atlas
			{
				var textureAtlas: CTextureAtlasScale;
				
				for each(var ta: Object in jsonObject.textureAtlas)
				{
					scale = ta.scale;
					
					textureAtlas = new CTextureAtlasScale();
					textureAtlas.scale = scale;
					
					/////////////////////
					
					var elements: CTextureAtlasElements = new CTextureAtlasElements();
					
					for each(var e: Object in ta.elements)
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
						
						for each(item in contentScaleFactors)
						{
							if(item.csf == csf)
							{
								return item;
							}
						}
						
						item = new CTextureAtlasCSF(csf, scale);
						item.elements = elements;
						
						contentScaleFactors.push(item);
						
						if(!isNaN(defaultContentScaleFactor) && defaultContentScaleFactor == csf)
						{
							textureAtlas.contentScaleFactor = item;
						}
						
						return item;
					};
					
					/////////////////////
					
					for each(var at: Object in ta.atlases)
					{
						for each(var atSource: Object in at.sources)
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
					
					if(!isNaN(defaultScale) && defaultScale == scale)
					{
						timelineConfig.textureAtlas = textureAtlas;
					}
				}
			}
			else if (scales != null && csfs != null) // timeline hasn't atlas, create empty
			{
				for each (scale in scales)
				{
					textureAtlas = new CTextureAtlasScale();
					textureAtlas.scale = scale;
			
					textureAtlas.allContentScaleFactors = new Vector.<CTextureAtlasCSF>();
					for each (var csf: Number in csfs)
					{
						var item: CTextureAtlasCSF;
						item = new CTextureAtlasCSF(csf, scale);
			
						if ((!isNaN(defaultContentScaleFactor) && defaultContentScaleFactor == csf)
								|| !textureAtlas.contentScaleFactor)
						{
							textureAtlas.contentScaleFactor = item;
						}
			
						textureAtlas.allContentScaleFactors.push(item);
					}
					allTextureAtlases.push(textureAtlas);
					if (!isNaN(defaultScale) && defaultScale == scale)
					{
						timelineConfig.textureAtlas = textureAtlas;
					}
				}
			}

			timelineConfig.allTextureAtlases = allTextureAtlases;

			if (!timelineConfig.textureAtlas && allTextureAtlases.length)
			{
				timelineConfig.textureAtlas = allTextureAtlases[0];
			}

			///////////////////////////////////////////////////////////////
			
			var animationObjects: CAnimationObjects = new CAnimationObjects();
			var regionDef: Object;
			var regionID: String;
			var regionType: String = CAnimationObject.TYPE_TEXTURE;
			
			if(jsonObject.animationObjects)
			{
				for(var ao: String in jsonObject.animationObjects)
				{
					regionDef = jsonObject.animationObjects[ao];
					if (regionDef is String) // old version
					{
						regionID = regionDef as String;
					}
					else
					{
						regionID = regionDef.id;
						regionType = regionDef.type;
					}
					animationObjects.addAnimationObject(new CAnimationObject(ao, regionID, regionType, false));
					
					checkForMissedRegions(timelineConfig, regionType, regionID);
				}
			}
			
			if(jsonObject.animationMasks)
			{
				for(var am: String in jsonObject.animationMasks)
				{
					regionDef = jsonObject.animationMasks[am];
					if (regionDef is String) // old version
					{
						regionID = regionDef as String;
					}
					else
					{
						regionID = regionDef.id;
						regionType = regionDef.type;
					}
					animationObjects.addAnimationObject(new CAnimationObject(am, regionID, regionType, true));
					
					checkForMissedRegions(timelineConfig, regionType, regionID);
				}
			}
			
			timelineConfig.animationObjects = animationObjects;

			///////////////////////////////////////////////////////////////
			
			var animationSequences: CAnimationSequences = new CAnimationSequences();
			
			if(jsonObject.animationSequences)
			{
				for each(var asq: Object in jsonObject.animationSequences)
				{
					animationSequences.addSequence(new CAnimationSequence(asq.id, asq.startFrameNo, asq.endFrameNo));
				}
			}
			
			timelineConfig.animationSequences = animationSequences;
			
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

			timelineConfig.textFields = textFieldObjects;

			///////////////////////////////////////////////////////////////

			timelineConfig.namedParts = {};

			if (jsonObject.namedParts)
			{
				for (var id: String in jsonObject.namedParts)
				{
					timelineConfig.namedParts[id] = jsonObject.namedParts[id];
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
			
			var blurFilter: CBlurFilterData;
			var blurFilters: Object = {};
			
			timelineConfig.framesCount = jsonObject.animationFrameCount;
			
			if (jsonObject.animationConfigFrames && jsonObject.animationConfigFrames.length)
			{
				for each(f in jsonObject.animationConfigFrames)
				{
					if(prevFrame)
					{
						currentFrame = prevFrame.clone(f.frameNumber);
						
						for(missedFrameNumber = prevFrame.frameNumber + 1; missedFrameNumber < currentFrame.frameNumber; missedFrameNumber++)
						{
							animationConfigFrames.addFrame(prevFrame.clone(missedFrameNumber));
						}
					}
					else
					{
						currentFrame = new CAnimationFrame(f.frameNumber);
						
						if(currentFrame.frameNumber > 1)
						{
							for(missedFrameNumber = 1; missedFrameNumber < currentFrame.frameNumber; missedFrameNumber++)
							{
								animationConfigFrames.addFrame(new CAnimationFrame(missedFrameNumber));
							}
						}
					}
					
					states = f.state;
					
					for(var stateID: String in states)
					{
						state = states[stateID];						
						
						maskID = "";
						if(state.hasOwnProperty("m"))
						{
							maskID = state["m"];
						}
						
						filter = null;
						
						stateConfig = state["st"];
						stateConfig = stateConfig.replace("{", "");
						stateConfig = stateConfig.replace("}", "");
						
						io = stateConfig.split(",");
						
						var alpha: Number = io[7];// 
						
						if(state.hasOwnProperty("c"))
						{
							var params: Vector.<Number> = Vector.<Number>(String(state["c"]).replace(" ", "").split(","));
							alpha = Math.max(Math.min(alpha + params[0], 1), 0);
							
							filter = new CFilter();
							filter.addColorTransform(params);
						}
						
						if(state.hasOwnProperty("e"))
						{
							var warning: String;
							
							filter ||= new CFilter();

							for each (var filterConfig: Object in state["e"])
							{
								switch (filterConfig["t"])
								{
									case JsonGAFAssetConfigConverter.FILTER_BLUR:
										warning = filter.addBlurFilter(filterConfig["x"], filterConfig["y"]);
										if (filterConfig["x"] >= 2 && filterConfig["y"] >= 2)
										{
											if (!(stateID in blurFilters))
											{
												blurFilters[stateID] = filter;
											}
										}
										else
										{
											blurFilters[stateID] = null;
										}
										break;
									case JsonGAFAssetConfigConverter.FILTER_COLOR_TRANSFORM:
										warning = filter.addColorMatrixFilter(Vector.<Number>(filterConfig["matrix"]));
										break;
									case JsonGAFAssetConfigConverter.FILTER_DROP_SHADOW:
										warning = filter.addDropShadowFilter(filterConfig["x"], filterConfig["y"],
												filterConfig["color"],
												filterConfig["alpha"],
												filterConfig["angle"],
												filterConfig["distance"]);
										break;
									case JsonGAFAssetConfigConverter.FILTER_GLOW:
										warning = filter.addGlowFilter(filterConfig["x"], filterConfig["y"],
												filterConfig["color"], filterConfig["alpha"]);
										break;
									default:
										trace(WarningConstants.UNSUPPORTED_FILTERS);
										break;
								}

								timelineConfig.addWarning(warning);
							}
						}
						
						if (alpha == 1)
						{
							alpha = CAnimationFrameInstance.MAX_ALPHA;
						}
						
						instance = new CAnimationFrameInstance(stateID);
						instance.update(io[0], new Matrix(io[1], io[2], io[3], io[4], io[5], io[6]), alpha, maskID, filter);
						
						if(maskID && filter)
						{
							timelineConfig.addWarning(WarningConstants.FILTERS_UNDER_MASK);
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
			
				for (missedFrameNumber = prevFrame.frameNumber + 1; missedFrameNumber <= timelineConfig.framesCount; missedFrameNumber++)
				{
					animationConfigFrames.addFrame(prevFrame.clone(missedFrameNumber));
				}
				
				for each (currentFrame in animationConfigFrames.frames)
				{
					for each (instance in currentFrame.instances)
					{
						if (blurFilters[instance.id])
						{
							blurFilter = instance.filter.getBlurFilter();
							if (blurFilter.resolution == 1)
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
//				config.debugRegions.push(debugRegion);
//			}
			
			return timelineConfig;
		}

		public function convert(): void
		{
			setTimeout(parse, 1);
		}
		
		public function get config(): GAFAssetConfig
		{
			return _config;
		}

		private function parse(): void
		{
			var jsonObject: Object = JSON.parse(json);
			
			if (jsonObject.version && String(jsonObject.version).split(".")[0] > GAFAssetConfig.MAX_VERSION)
			{
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, WarningConstants.UNSUPPORTED_FILE +
							"Library version: " + GAFAssetConfig.MAX_VERSION + ", file version: " + jsonObject.version));
			}

			_config = new GAFAssetConfig(assetID);

			var timelineConfig: GAFTimelineConfig;

			if (jsonObject.animations)
			{
				for each (var configObject: Object in jsonObject.animations)
				{
					timelineConfig = new GAFTimelineConfig(jsonObject.version);
					timelineConfig.id = configObject.id;
					timelineConfig.assetID = assetID;
					if (configObject.linkage)
					{
						timelineConfig.linkage = configObject.linkage;
					}
					convertConfig(timelineConfig, configObject, defaultScale, defaultContentScaleFactor, jsonObject.scale, jsonObject.csf);
					_config.timelines.push(timelineConfig);
				}
			}
			else
			{
				timelineConfig = new GAFTimelineConfig(jsonObject.version);
				timelineConfig.id = "0";
				timelineConfig.assetID = assetID;
				convertConfig(timelineConfig, jsonObject, defaultScale, defaultContentScaleFactor);
				_config.timelines.push(timelineConfig);
			}
			
			if (jsonObject.stageConfig)
			{
				var stageConfig: CStage = new CStage().clone(jsonObject.stageConfig);
			}
			if (jsonObject.pivotPoint)
			{
				var pivotPoint: Point = new Point(jsonObject.pivotPoint.x, jsonObject.pivotPoint.y);
			}
			if (jsonObject.boundingBox)
			{
				var boundingBox: Rectangle = new Rectangle(jsonObject.boundingBox.x, jsonObject.boundingBox.y, jsonObject.boundingBox.width, jsonObject.boundingBox.height);
			}
			
			for each (timelineConfig in _config.timelines)
			{
				timelineConfig.stageConfig = stageConfig;
				timelineConfig.pivot ||= pivotPoint;
				timelineConfig.bounds ||= boundingBox; 
			}

			///////////////////////////////////////////////////////////////
			
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		// find region in textureAtlas. If it's missing - show warning
		private static function checkForMissedRegions(timelineConfig: GAFTimelineConfig, regionType: String, regionID: String): void
		{
			if (regionType == CAnimationObject.TYPE_TEXTURE
			&&  timelineConfig.textureAtlas.contentScaleFactor.elements
			&& !timelineConfig.textureAtlas.contentScaleFactor.elements.getElement(regionID))
			{
				timelineConfig.addWarning(WarningConstants.REGION_NOT_FOUND);
			}
		}
	}
}
