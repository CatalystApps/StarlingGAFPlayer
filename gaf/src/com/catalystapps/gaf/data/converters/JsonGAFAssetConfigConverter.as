package com.catalystapps.gaf.data.converters
{
	import com.catalystapps.gaf.data.config.CStage;
	import com.catalystapps.gaf.data.config.CTextureAtlasElements;
	import com.catalystapps.gaf.data.GAFAssetConfig;
	import com.catalystapps.gaf.data.config.CAnimationFrame;
	import com.catalystapps.gaf.data.config.CAnimationFrameInstance;
	import com.catalystapps.gaf.data.config.CAnimationFrames;
	import com.catalystapps.gaf.data.config.CAnimationObject;
	import com.catalystapps.gaf.data.config.CAnimationObjects;
	import com.catalystapps.gaf.data.config.CAnimationSequence;
	import com.catalystapps.gaf.data.config.CAnimationSequences;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.data.config.CTextureAtlasCSF;
	import com.catalystapps.gaf.data.config.CTextureAtlasElement;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;
	import com.catalystapps.gaf.data.config.CTextureAtlasSource;

	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	/**
	 * @private
	 */
	public class JsonGAFAssetConfigConverter
	{
		public static const FILTER_BLUR: String = "Fblur";
		public static const FILTER_COLOR_TRANSFORM: String = "Fctransform";
		public static const FILTER_DROP_SHADOW: String = "FdropShadowFilter";
		public static const FILTER_GLOW: String = "FglowFilter";
		
		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		
		public static function convert(json: String, defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN): GAFAssetConfig
		{
			var jsonObject: Object = JSON.parse(json);
			
			var result: GAFAssetConfig = new GAFAssetConfig(jsonObject.version);
			
			///////////////////////////////////////////////////////////////
			
			if (jsonObject.stageConfig)
			{
				result.stageConfig = new CStage().clone(jsonObject.stageConfig);
			}
			
			///////////////////////////////////////////////////////////////
			
			var allTextureAtlases: Vector.<CTextureAtlasScale> = new Vector.<CTextureAtlasScale>();
			
			if(jsonObject.textureAtlas)
			{
				var textureAtlas: CTextureAtlasScale;
				
				for each(var ta: Object in jsonObject.textureAtlas)
				{
					var scale: Number = ta.scale;
					
					textureAtlas = new CTextureAtlasScale();
					textureAtlas.scale = scale;
					
					/////////////////////
					
					var elements: CTextureAtlasElements = new CTextureAtlasElements();
					
					for each(var e: Object in ta.elements)
					{
						var element: CTextureAtlasElement = new CTextureAtlasElement(e.name, e.atlasID, new Rectangle(int(e.x), int(e.y), e.width, e.height), new Matrix(1/e.scale, 0, 0, 1/e.scale, -e.pivotX/e.scale, -e.pivotY/e.scale));
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
					
					if(!textureAtlas.contentScaleFactor && contentScaleFactors.length)
					{
						textureAtlas.contentScaleFactor = contentScaleFactors[0];
					}
					
					/////////////////////
					
					allTextureAtlases.push(textureAtlas);
					
					if(!isNaN(defaultScale) && defaultScale == scale)
					{
						result.textureAtlas = textureAtlas;
					}
				}
			}
			
			result.allTextureAtlases = allTextureAtlases;
			
			if(!result.textureAtlas && allTextureAtlases.length)
			{
				result.textureAtlas = allTextureAtlases[0];
			}
			
			///////////////////////////////////////////////////////////////
			
			var animationObjects: CAnimationObjects = new CAnimationObjects();
			
			if(jsonObject.animationObjects)
			{
				for(var ao: String in jsonObject.animationObjects)
				{
					animationObjects.addAnimationObject(new CAnimationObject(ao, jsonObject.animationObjects[ao], false));
				}
			}
			
			if(jsonObject.animationMasks)
			{
				for(var am: String in jsonObject.animationMasks)
				{
					animationObjects.addAnimationObject(new CAnimationObject(am, jsonObject.animationMasks[am], true));
				}
			}
			
			result.animationObjects = animationObjects;
			
			///////////////////////////////////////////////////////////////
			
			var animationSequences: CAnimationSequences = new CAnimationSequences();
			
			if(jsonObject.animationSequences)
			{
				for each(var asq: Object in jsonObject.animationSequences)
				{
					animationSequences.addSequence(new CAnimationSequence(asq.id, asq.startFrameNo, asq.endFrameNo));
				}
			}
			
			result.animationSequences = animationSequences;
			
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
			
			if(jsonObject.animationConfigFrames)
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
						
						///////////////////////////////////////////
						
						function checkAndInitFilter(): void
						{
							if(!filter)
							{
								filter = new CFilter();
							}
						};
						
						///////////////////////////////////////////
						
						filter = null;
						
						stateConfig = state["st"];
						stateConfig = stateConfig.replace("{", "");
						stateConfig = stateConfig.replace("}", "");
						
						io = stateConfig.split(",");
						
						var alpha: Number = io[7];// 
						
						if(state.hasOwnProperty("c"))
						{
							var params: Array = String(state["c"]).replace(" ", "").split(",");
							alpha = Math.max(Math.min(alpha + params[0], 1), 0);
							
							checkAndInitFilter();
							
							filter.addColorTransform(params);
						}
						
						if(state.hasOwnProperty("e"))
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
										warning = filter.addColorMatrixFilter(filterConfig["matrix"]);
										break;
									case JsonGAFAssetConfigConverter.FILTER_DROP_SHADOW:
										checkAndInitFilter();
										warning = filter.addDropShadowFilter(filterConfig["x"], filterConfig["y"], filterConfig["color"], filterConfig["alpha"], filterConfig["angle"], filterConfig["distance"]);
										break;
									case JsonGAFAssetConfigConverter.FILTER_GLOW:
										checkAndInitFilter();
										warning = filter.addGlowFilter(filterConfig["x"], filterConfig["y"], filterConfig["color"], filterConfig["alpha"]);										
										break;
									default:
										trace(WarningConstants.UNSUPPORTED_FILTERS);
										break;
								}	
								
								result.addWarning(warning);							
							}							
						}
						
						instance = new CAnimationFrameInstance(stateID);						
//						instance.update(io[0], new Matrix(io[1], io[2], io[3], io[4], io[5], io[6]), io[7], maskID, filter);
						instance.update(io[0], new Matrix(io[1], io[2], io[3], io[4], io[5], io[6]), alpha, maskID, filter);
						
						if(maskID && filter)
						{
							result.addWarning(WarningConstants.FILTERS_UNDER_MASK);
						}
						
						currentFrame.addInstance(instance);
					}
					
					currentFrame.sortInstances();
					
					animationConfigFrames.addFrame(currentFrame);
					
					prevFrame = currentFrame;
				}
			}
			
			for(missedFrameNumber = prevFrame.frameNumber + 1; missedFrameNumber <= jsonObject.animationFrameCount; missedFrameNumber++)
			{
				animationConfigFrames.addFrame(prevFrame.clone(missedFrameNumber));
			}

			result.animationConfigFrames = animationConfigFrames;			
			
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
//				result.debugRegions.push(debugRegion);
//			}
//			
//			if (jsonObject.boundingBox)
//			{
//				debugRegion = new GAFDebugInformation();
//				debugRegion.type = GAFDebugInformation.TYPE_RECT;
//				debugRegion.rect = new Rectangle(jsonObject.boundingBox.x, jsonObject.boundingBox.y, jsonObject.boundingBox.width, jsonObject.boundingBox.height);
//				debugRegion.color = 0x00ff00;
//				debugRegion.alpha = 0.3;
//				result.debugRegions.push(debugRegion);
//			}
			
			return result;
		}
	}
}
