package com.catalystapps.gaf.display
{
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.extensions.pixelmask.PixelMaskDisplayObject;

	import com.catalystapps.gaf.data.GAFAsset;
	import com.catalystapps.gaf.data.config.CAnimationFrame;
	import com.catalystapps.gaf.data.config.CAnimationFrameInstance;
	import com.catalystapps.gaf.data.config.CAnimationObject;
	import com.catalystapps.gaf.data.config.CAnimationSequence;
	import com.catalystapps.gaf.event.SequenceEvent;
	import com.catalystapps.gaf.filter.GAFFilter;

	import flash.geom.Matrix;

	/**
	 * @author mitvad
	 */
	public class GAFMovieClip extends Sprite
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
		
		private var _gafAsset: GAFAsset;
		
		private var _mappedAssetID: String;
		
		private var scale: Number;
		
		private var imagesDictionary: Object;
		private var masksDictionary: Object;
		private var maskedImagesDictionary: Object;
		
		private var playingSequence: CAnimationSequence;
		
		private var _currentFrame: uint;
		private var _totalFrames: uint;
		
		private var _inPlay: Boolean;
		private var _loop: Boolean = true;
		
		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		public function GAFMovieClip(gafAsset: GAFAsset, mappedAssetID: String = "")
		{
			this._gafAsset = gafAsset;
			
			this._mappedAssetID = mappedAssetID;
			
			this.scale = this._gafAsset.scale;
			
			this.initialize();
			
			this.draw();
		}
		
		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		
		public function getChildByID(id: String): DisplayObject
		{
			return this.imagesDictionary[id];
		}
		
		public function clearSequence(): void
		{
			this.playingSequence = null;
		}
		
		public function setSequence(id: String, play: Boolean = true): CAnimationSequence
		{
			this.playingSequence = this._gafAsset.config.animationSequences.getSecuenceByID(id);
			
			if(this.playingSequence)
			{
				if(play)
				{
					this.gotoAndPlay(this.playingSequence.startFrameNo);
				}
				else
				{
					this.gotoAndStop(this.playingSequence.startFrameNo);
				}
			}
			
			return this.playingSequence;
		}
		
		public function play(): void
		{
			if(this._totalFrames > 1)
			{
				// For some unknown reason there is a case where "this" has no "ENTER_FRAME" listener but method "hasEventListener" returns true
				// Happens after call play(), stop() and play()
				// XXX TODO: find reason and fix it if possible (current realization doesn't break anything, just looks strange)
				if(this.hasEventListener(Event.ENTER_FRAME))
				{
					this.removeEventListener(Event.ENTER_FRAME, this.changeCurrentFrame);
				}
				
				this.addEventListener(Event.ENTER_FRAME, this.changeCurrentFrame);
				
				this._inPlay = true;
			}
		}

		public function stop(): void
		{
			if(this.hasEventListener(Event.ENTER_FRAME))
			{
				this.removeEventListener(Event.ENTER_FRAME, this.changeCurrentFrame);
			}
			
			this._inPlay = false;
		}
		
		public function gotoAndStop(frame: *): void
		{
			this.checkAndSetCurrentFrame(frame);
			
			this.draw();
			
			this.stop();
		}
		
		public function gotoAndPlay(frame: *): void
		{
			this.checkAndSetCurrentFrame(frame);
			
			this.draw();
			
			this.play();
		}
		
		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------
		
		private function checkAndSetCurrentFrame(frame: *): void
		{
			if(frame is uint)
			{
				if(frame == 0)
				{
					throw new Error("'0' - is wrong start frame number. Like in AS3 MovieClip API frames numeration starts from '1'");
				}
				
				frame -= 1;
			}
			else
			{
				frame = this._gafAsset.config.animationSequences.getStartFrameNo(frame);
			}
			
			if(frame <= this._totalFrames)
			{
				this._currentFrame = frame;
			}
			
			if(this.playingSequence && !this.playingSequence.isSequenceFrame(this._currentFrame + 1))
			{
				this.playingSequence = null;
			}
		}
		
		private function clearDisplayList(): void
		{
			this.removeChildren();
			
			for each(var pixelMaskimage: PixelMaskDisplayObject in this.maskedImagesDictionary)
			{
				pixelMaskimage.removeChildren();
			}
		}
		
		private function draw(): void
		{
			this.clearDisplayList();
			
			var image: GAFImage;
			
			if(this._gafAsset.config.animationConfigFrames.frames.length > this._currentFrame)
			{
				var frameConfig: CAnimationFrame = this._gafAsset.config.animationConfigFrames.frames[this._currentFrame];
				
				for each(var instance: CAnimationFrameInstance in frameConfig.instances)
				{
					image = this.imagesDictionary[instance.id];
					
					if(image)
					{
						image.alpha = instance.alpha;
						
						if(instance.maskID)
						{
							var maskImage: GAFImage = this.masksDictionary[instance.maskID];
							
							if(maskImage)
							{
								var pixelMaskDisplayObject: PixelMaskDisplayObject = this.maskedImagesDictionary[instance.maskID];
								
								pixelMaskDisplayObject.addChild(image);
								
								var maskInstance: CAnimationFrameInstance = frameConfig.getInstanceByID(instance.maskID);
								
								if(maskInstance)
								{
									var maskTransformMatrix: Matrix = maskInstance.getTransformMatrix(maskImage.assetTexture.pivotMatrix, this.scale).clone();
									var imageTransformMatrix: Matrix = instance.getTransformMatrix(image.assetTexture.pivotMatrix, this.scale).clone();
									
									maskTransformMatrix.invert();
									imageTransformMatrix.concat(maskTransformMatrix);
									
									image.transformationMatrix = imageTransformMatrix;
									
									pixelMaskDisplayObject.transformationMatrix = maskInstance.getTransformMatrix(maskImage.assetTexture.pivotMatrix, this.scale);
								}
								else
								{
									throw new Error("Unable to find mask with ID " + instance.maskID);
								}
								
								// !!! Currently it's not possible to use filters under mask. This limitation will be removed in a future Stage3D version.
								// TODO: uncomment this line when this limitation will be removed
								// this.updateFilter(image, instance, this.scale);
								
								this.addChild(pixelMaskDisplayObject);
							}
							else
							{
								throw new Error("Unable to find mask with ID " + instance.maskID);
							}
						}
						else
						{
							image.transformationMatrix = instance.getTransformMatrix(image.assetTexture.pivotMatrix, this.scale);
							this.updateFilter(image, instance, this.scale);
						
							this.addChild(image);
						}
					}
				}
			}
		}
		
		private function updateFilter(image: Image, instance: CAnimationFrameInstance, scale: Number): void
		{
			var gafFilter: GAFFilter;
			
			if(!image.filter && !instance.filter)
			{
				// do nothing. Should be in most cases
				return;
			}
			else if(image.filter && instance.filter)
			{
				gafFilter = image.filter as GAFFilter;
				gafFilter.setColorTransformFilter(instance.filter.colorTransformFilterParams);
				gafFilter.setBlurFilter(instance.filter.blurFilterParams, scale);
			}
			else if(image.filter && !instance.filter)
			{
				image.filter = null;
			}
			else if(!image.filter && instance.filter)
			{
				gafFilter = new GAFFilter();
				gafFilter.setColorTransformFilter(instance.filter.colorTransformFilterParams);
				gafFilter.setBlurFilter(instance.filter.blurFilterParams, scale);
				image.filter = gafFilter;
			}
		}
		
		private function initialize(): void
		{
			this.imagesDictionary = new Object();
			this.masksDictionary = new Object();
			this.maskedImagesDictionary = new Object();
			
			this._currentFrame = 0;
			this._totalFrames = this._gafAsset.config.animationConfigFrames.frames.length;
			
			var animationObjectsDictionary: Object = this._gafAsset.config.animationObjects.animationObjectsDictionary;
			
			var image: GAFImage;
			
			for each(var animationObjectConfig: CAnimationObject in animationObjectsDictionary)
			{
				image = new GAFImage(this._gafAsset.textureAtlas.getTexture(animationObjectConfig.textureElementID, this._mappedAssetID));
				image.name = animationObjectConfig.instanceID;
				
				if(animationObjectConfig.mask)
				{
					this.masksDictionary[animationObjectConfig.instanceID] = image;
					
					var pixelMaskDisplayObject: PixelMaskDisplayObject = new PixelMaskDisplayObject();
					pixelMaskDisplayObject.mask = image;
								
					this.maskedImagesDictionary[animationObjectConfig.instanceID] = pixelMaskDisplayObject;
				}
				else
				{
					this.imagesDictionary[animationObjectConfig.instanceID] = image;
				}
			}
		}
		
		//--------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		//--------------------------------------------------------------------------
		
		override public function dispose(): void
		{
			this.stop();
			
			this._gafAsset = null;
			
			super.dispose();
		}
		
		//--------------------------------------------------------------------------
		//
		//  EVENT HANDLERS
		//
		//--------------------------------------------------------------------------
		
		private function changeCurrentFrame(event: Event): void
		{
			if(this.playingSequence)
			{
				if(this._currentFrame + 1 >= this.playingSequence.startFrameNo && this._currentFrame + 1 < this.playingSequence.endFrameNo)
				{
					this._currentFrame++;
				}
				else
				{
					if(!this._loop)
					{
						this.stop();
						
						return;
					}
					
					this._currentFrame = this.playingSequence.startFrameNo - 1;
				}
			}
			else
			{
				if(this._currentFrame < this._totalFrames - 1)
				{
					this._currentFrame++;
				}
				else
				{
					if(!this._loop)
					{
						this.stop();
						
						return;
					}
					
					this._currentFrame = 0;
				}
			}
			
			this.draw();
			
			var sequenceEvent: SequenceEvent = this._gafAsset.config.animationSequences.hasEvent(this._currentFrame);
			
			if(sequenceEvent)
			{
				if(this.hasEventListener(sequenceEvent.type))
				{
					this.dispatchEvent(sequenceEvent);
				}
			}
		}

		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------
		
		public function get currentFrame(): uint
		{
			return _currentFrame + 1;// Like in standart AS3 API for MovieClip first frame is "1" instead of "0" (but internally used "0")
		}

		public function get totalFrames(): uint
		{
			return _totalFrames;
		}

		public function get inPlay(): Boolean
		{
			return _inPlay;
		}

		public function get loop(): Boolean
		{
			return _loop;
		}

		public function set loop(loop: Boolean): void
		{
			_loop = loop;
		}
		
	}
}
