package com.catalystapps.gaf.display
{
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

	
	/** Dispatched when playhead reached first frame of sequence */
    [Event(name="typeSequenceStart", type="com.catalystapps.gaf.event.SequenceEvent")]
	
	/** Dispatched when playhead reached end frame of sequence */
    [Event(name="typeSequenceEnd", type="com.catalystapps.gaf.event.SequenceEvent")]
	
	/**
	 * GAFMovieClip represents animation display object that is ready to be used in Starling display list. It has 
	 * all controls for animation familiar from standard MovieClip (<code>play</code>, <code>stop</code>, <code>gotoAndPlay,</code> etc.) 
	 * and some more like <code>loop</code>, <code>nPlay</code>, <code>setSequence</code> that helps manage playback
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
		
		/**
		 * Creates a new GAFMovieClip instance.
		 * 
		 * @param gafAsset <code>GAFAsset</code> from what <code>GAFMovieClip</code> will be created
		 * @param mappedAssetID To be defined. For now - use default value
		 */
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
		
		/**
		 * Returns the child display object that exists with the specified ID. Use to obtain animation's parts
		 * 
		 * @param id Child ID
		 * @return The child display object with the specified ID
		 */
		public function getChildByID(id: String): GAFImage
		{
			return this.imagesDictionary[id];
		}
		
		/**
		 * Returns the mask display object that exists with the specified ID. Use to obtain animation's masks
		 * 
		 * @param id Mask ID
		 * @return The mask display object with the specified ID
		 */
		public function getMaskByID(id: String): GAFImage
		{
			return this.masksDictionary[id];
		}
		
		/**
		 * Shows mask display object that exists with the specified ID. Used for debug purposes only!
		 * 
		 * @param id Mask ID
		 */
		public function showMaskByID(id: String): void
		{
			var maskImage: GAFImage = this.masksDictionary[id];
			
			if(maskImage)
			{
				var frameConfig: CAnimationFrame = this._gafAsset.config.animationConfigFrames.frames[this._currentFrame];
				
				var maskInstance: CAnimationFrameInstance = frameConfig.getInstanceByID(id);
				
				if(maskInstance)
				{
					var maskTransformMatrix: Matrix = maskInstance.getTransformMatrix(maskImage.assetTexture.pivotMatrix, this.scale).clone();
					
					maskImage.transformationMatrix = maskTransformMatrix;
					
					////////////////////////////////
					
					var filterProperties: Vector.<Number> = new Vector.<Number>();
					filterProperties.push(1,0,0,0,255, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,1,0);
					
					var gafFilter: GAFFilter = new GAFFilter();
					gafFilter.setColorTransformFilter(filterProperties);
					
					maskImage.filter = gafFilter;
					
					////////////////////////////////
					
					this.addChild(maskImage);
				}
			}
		}
		/**
		 * Hides mask display object that previously has been shown using <code>showMaskByID</code> method. 
		 * Used for debug purposes only!
		 * 
		 * @param id Mask ID
		 */
		public function hideMaskByID(id: String): void
		{
			var maskImage: GAFImage = this.masksDictionary[id];
			
			if(maskImage)
			{
				maskImage.transformationMatrix = new Matrix();
				maskImage.filter = null;
				
				if(maskImage.parent == this)
				{
					this.removeChild(maskImage);
				}
			}
		}
		
		/**
		 * Clear playing sequence. If animation already in play just continue playing without sequence limitation
		 */
		public function clearSequence(): void
		{
			this.playingSequence = null;
		}
		
		/**
		 * Set sequence to play
		 * 
		 * @param id Sequence ID
		 * @param play Play or not immediately. <code>true</code> - starts playng from sequence start frame. <code>false</code> - go to sequence start frame and stop
		 * 
		 * @return 
		 */
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
		
		/**
		 * Moves the playhead in the timeline of the movie clip.
		 */
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
		
		/**
		 * Stops the playhead in the movie clip. 
		 */
		public function stop(): void
		{
			if(this.hasEventListener(Event.ENTER_FRAME))
			{
				this.removeEventListener(Event.ENTER_FRAME, this.changeCurrentFrame);
			}
			
			this._inPlay = false;
		}
		
		/**
		 * Brings the playhead to the specified frame of the movie clip and stops it there. First frame is "1"
		 * 
		 * @param frame A number representing the frame number, or a string representing the label of the frame, to which the playhead is sent.
		 */
		public function gotoAndStop(frame: *): void
		{
			this.checkAndSetCurrentFrame(frame);
			
			this.draw();
			
			this.stop();
		}
		
		/**
		 * Starts playing animation at the specified frame. First frame is "1"
		 * 
		 * @param frame A number representing the frame number, or a string representing the label of the frame, to which the playhead is sent.
		 */
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
								
								image.filter = null;
								
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
				image.filter.dispose();
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
		
		/**
		 * Disposes all resources of the display object instance. Note: this method won't delete used texture atlases from GPU memory.
		 * To delete texture atlases from GPU memory use <code>unloadFromVideoMemory()</code> method for <code>GAFAsset</code> instance
		 * from what <code>GAFMovieClip</code> was instantiated.
		 * Call this method every time before delete no longer required instance! Otherwise GPU memory leak may occur!
		 */
		override public function dispose(): void
		{
			this.stop();
			
			this._gafAsset = null;
			
			var image: GAFImage;
			
			for each(image in this.imagesDictionary)
			{
				image.dispose();
			}
			
			for each(image in this.masksDictionary)
			{
				image.dispose();
			}
			
			for each(var pixelMaskDisplayObject: PixelMaskDisplayObject in this.maskedImagesDictionary)
			{
				pixelMaskDisplayObject.dispose();
			}
			
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
			
			var sequenceEvent: SequenceEvent = this._gafAsset.config.animationSequences.hasEvent(this._currentFrame + 1);
			
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
		
		/**
		 * Specifies the number of the frame in which the playhead is located in the timeline of the GAFMovieClip instance. First frame is "1"
		 */
		public function get currentFrame(): uint
		{
			return _currentFrame + 1;// Like in standart AS3 API for MovieClip first frame is "1" instead of "0" (but internally used "0")
		}
		
		/**
		 * The total number of frames in the GAFMovieClip instance. 
		 */
		public function get totalFrames(): uint
		{
			return _totalFrames;
		}
		
		/**
		 * Indicates whether GAFMovieClip instance already in play
		 */
		public function get inPlay(): Boolean
		{
			return _inPlay;
		}
		
		/**
		 * Indicates whether GAFMovieClip instance continue playing from start frame after playback reached animation end
		 */
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
