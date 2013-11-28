package com.catalystapps.gaf.data
{
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
	 * @author mitvad
	 */
	public class GAFAssetConfig
	{
		//--------------------------------------------------------------------------
		//
		//  PUBLIC VARIABLES
		//
		//--------------------------------------------------------------------------
		
		//--------------------------------------------------------------------------
		//
		//  PRIVATE VARIABLES
		//
		//--------------------------------------------------------------------------
		
		private var _version: String;
		
		private var _allTextureAtlases: Vector.<CTextureAtlasScale>;
		private var _textureAtlas: CTextureAtlasScale;
		
		private var _animationConfigFrames: CAnimationFrames;
		private var _animationObjects: CAnimationObjects;
		private var _animationSequences: CAnimationSequences;
		
		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		public function GAFAssetConfig(version: String)
		{
			this._version = version;
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		
		public function dispose(): void
		{
			for each(var cTextureAtlasScale: CTextureAtlasScale in this._allTextureAtlases)
			{
				cTextureAtlasScale.dispose();
			}
		}
		
		public function getTextureAtlasForScale(scale: Number): CTextureAtlasScale
		{
			for each(var cTextureAtlas: CTextureAtlasScale in this._allTextureAtlases)
			{
				if(cTextureAtlas.scale == scale)
				{
					return cTextureAtlas;
				}
			}
			
			return null;
		}
		
		public static function convert(json: String, defaultScale: Number = NaN, defaultContentScaleFactor: Number = NaN): GAFAssetConfig
		{
			var jsonObject: Object = JSON.parse(json);
			
			var result: GAFAssetConfig = new GAFAssetConfig(jsonObject.version);
			
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
						
						item = new CTextureAtlasCSF(csf);
						contentScaleFactors.push(item);
						
						if(!isNaN(defaultContentScaleFactor) && defaultContentScaleFactor == csf)
						{
							textureAtlas.contantScaleFactor = item;
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
					
					if(!textureAtlas.contantScaleFactor && contentScaleFactors.length)
					{
						textureAtlas.contantScaleFactor = contentScaleFactors[0];
					}
					
					/////////////////////
					
					for each(var e: Object in ta.elements)
					{
						var element: CTextureAtlasElement = new CTextureAtlasElement(e.name, e.atlasID, new Rectangle(int(e.x), int(e.y), e.width, e.height), new Matrix(1/e.scale, 0, 0, 1/e.scale, -e.pivotX/e.scale, -e.pivotY/e.scale));
						textureAtlas.addElement(element);
					}
					
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
						
						if(state.hasOwnProperty("c"))
						{
							var params: Array = String(state["c"]).replace(" ", "").split(",");
							
							checkAndInitFilter();
							
							filter.initFilterColorTransform(params);
						}
						
						if(state.hasOwnProperty("e"))
						{
							for each (var filterConfig: Object in state["e"])
							{
								if (filterConfig["t"] == "Fblur")
								{
									checkAndInitFilter();
									
									filter.initFilterBlur(filterConfig["x"], filterConfig["y"]);
								}
							}							
						}
						
						stateConfig = state["st"];
						stateConfig = stateConfig.replace("{", "");
						stateConfig = stateConfig.replace("}", "");
						
						io = stateConfig.split(",");
						
						instance = new CAnimationFrameInstance(stateID);						
						instance.update(io[0], new Matrix(io[1], io[2], io[3], io[4], int(io[5]), int(io[6])), io[7], maskID, filter);
						
						currentFrame.addInstance(instance);
					}
					
					currentFrame.sortInstances();
					
					animationConfigFrames.addFrame(currentFrame);
					
					prevFrame = currentFrame;
				}
			}
			
			for(missedFrameNumber = prevFrame.frameNumber + 1; missedFrameNumber < jsonObject.animationFrameCount; missedFrameNumber++)
			{
				animationConfigFrames.addFrame(prevFrame.clone(missedFrameNumber));
			}

			result.animationConfigFrames = animationConfigFrames;
			
			///////////////////////////////////////////////////////////////
			
			return result;
		}
		
		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------
		
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
		
		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------
		
		public function get textureAtlas(): CTextureAtlasScale
		{
			return _textureAtlas;
		}

		public function set textureAtlas(textureAtlas: CTextureAtlasScale): void
		{
			_textureAtlas = textureAtlas;
		}

		public function get animationObjects(): CAnimationObjects
		{
			return _animationObjects;
		}

		public function set animationObjects(animationObjects: CAnimationObjects): void
		{
			_animationObjects = animationObjects;
		}

		public function get animationConfigFrames(): CAnimationFrames
		{
			return _animationConfigFrames;
		}

		public function set animationConfigFrames(animationConfigFrames: CAnimationFrames): void
		{
			_animationConfigFrames = animationConfigFrames;
		}

		public function get animationSequences(): CAnimationSequences
		{
			return _animationSequences;
		}

		public function set animationSequences(animationSequences: CAnimationSequences): void
		{
			_animationSequences = animationSequences;
		}

		public function get allTextureAtlases(): Vector.<CTextureAtlasScale>
		{
			return _allTextureAtlases;
		}

		public function set allTextureAtlases(allTextureAtlases: Vector.<CTextureAtlasScale>): void
		{
			_allTextureAtlases = allTextureAtlases;
		}

		public function get version(): String
		{
			return _version;
		}
		
	}
}
