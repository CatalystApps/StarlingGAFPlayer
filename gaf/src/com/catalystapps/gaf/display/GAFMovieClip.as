package com.catalystapps.gaf.display
{
	import starling.core.Starling;
	import com.catalystapps.gaf.data.GAFAsset;
	import com.catalystapps.gaf.data.GAFDebugInformation;
	import com.catalystapps.gaf.data.config.CAnimationFrame;
	import com.catalystapps.gaf.data.config.CAnimationFrameInstance;
	import com.catalystapps.gaf.data.config.CAnimationObject;
	import com.catalystapps.gaf.data.config.CAnimationSequence;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.filter.GAFFilter;

	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	import starling.animation.IAnimatable;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.extensions.pixelmask.PixelMaskDisplayObject;
	import starling.textures.TextureSmoothing;

	/** Dispatched when playhead reached first frame of sequence, the data property of the event is the <code>CAnimationSequence</code> instance related to the event */
	[Event(name = "typeSequenceStart", type = "starling.events.Event")]
	/** Dispatched when playhead reached end frame of sequence, the data property of the event is the <code>CAnimationSequence</code> instance related to the event */
	[Event(name = "typeSequenceEnd", type = "starling.events.Event")]
	/** Dispatched when playhead skip first frame of sequence, the data property of the event is the <code>CAnimationSequence</code> instance related to the event */
	[Event(name = "typeSequenceSkipStart", type = "starling.events.Event")]
	/** Dispatched when playhead skip end frame of sequence, the data property of the event is the <code>CAnimationSequence</code> instance related to the event */
	[Event(name = "typeSequenceSkipEnd", type = "starling.events.Event")]
	/**
	 * GAFMovieClip represents animation display object that is ready to be used in Starling display list. It has
	 * all controls for animation familiar from standard MovieClip (<code>play</code>, <code>stop</code>, <code>gotoAndPlay,</code> etc.)
	 * and some more like <code>loop</code>, <code>nPlay</code>, <code>setSequence</code> that helps manage playback
	 */
	public class GAFMovieClip extends Sprite implements IAnimatable
	{
		public static const EVENT_TYPE_SEQUENCE_START: String = "typeSequenceStart";
		public static const EVENT_TYPE_SEQUENCE_END: String = "typeSequenceEnd";
		public static const EVENT_TYPE_SEQUENCE_SKIP_START: String = "typeSequenceSkipStart";
		public static const EVENT_TYPE_SEQUENCE_SKIP_END: String = "typeSequenceSkipEnd";
		// --------------------------------------------------------------------------
		//
		// PUBLIC VARIABLES
		//
		// --------------------------------------------------------------------------
		// --------------------------------------------------------------------------
		//
		// PRIVATE VARIABLES
		//
		// --------------------------------------------------------------------------
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
		private var _elapsedTime: Number = 0;
		// Hold the current time spent animating
		private var _lastFrameTime: Number = 0;
		private var _frameDuration: Number;
		private var _smoothing: String = TextureSmoothing.BILINEAR;
		private var _useClipping: Boolean;
		private var _reversePlayback: Boolean;
		private var _nextFrame : int;
		private var _startFrame : int;
		private var _finalFrame : int;

		// --------------------------------------------------------------------------
		//
		// CONSTRUCTOR
		//
		// --------------------------------------------------------------------------
		/**
		 * Creates a new GAFMovieClip instance.
		 *
		 * @param gafAsset <code>GAFAsset</code> from what <code>GAFMovieClip</code> will be created
		 * @param mappedAssetID To be defined. For now - use default value
		 * @param fps defines the frame rate of the movie clip. The default value is stage config frame rate.
		 */
		public function GAFMovieClip(gafAsset: GAFAsset, mappedAssetID: String = "", fps: int = -1)
		{
			this._gafAsset = gafAsset;

			this._mappedAssetID = mappedAssetID;

			this.scale = this._gafAsset.scale;

			this.initialize();

			if (fps > 0)
			{
				this.fps = fps;
			}

			this.draw();
		}

		// --------------------------------------------------------------------------
		//
		// PUBLIC METHODS
		//
		// --------------------------------------------------------------------------
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

			if (maskImage)
			{
				var frameConfig: CAnimationFrame = this._gafAsset.config.animationConfigFrames.frames[this._currentFrame];

				var maskInstance: CAnimationFrameInstance = frameConfig.getInstanceByID(id);

				if (maskInstance)
				{
					var maskTransformMatrix: Matrix = maskInstance.getTransformMatrix(maskImage.assetTexture.pivotMatrix, this.scale).clone();

					maskImage.transformationMatrix = maskTransformMatrix;

					// //////////////////////////////

					var cFilter: CFilter = new CFilter();
					cFilter.addColorMatrixFilter([1, 0, 0, 0, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0]);

					var gafFilter: GAFFilter = new GAFFilter();
					gafFilter.setConfig(cFilter, scale);

					maskImage.filter = gafFilter;

					// //////////////////////////////

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

			if (maskImage)
			{
				maskImage.transformationMatrix = new Matrix();
				maskImage.filter = null;

				if (maskImage.parent == this)
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
		 * @param play Play or not immediately. <code>true</code> - starts playing from sequence start frame. <code>false</code> - go to sequence start frame and stop
		 * @return
		 */
		public function setSequence(id: String, play: Boolean = true): CAnimationSequence
		{
			this.playingSequence = this._gafAsset.config.animationSequences.getSecuenceByID(id);
			if (this.playingSequence)
			{
				var startFrame: int = this._reversePlayback ? this.playingSequence.endFrameNo : this.playingSequence.startFrameNo;
				if (play)
				{
					this.gotoAndPlay(startFrame);
				}
				else
				{
					this.gotoAndStop(startFrame);
				}
			}

			return this.playingSequence;
		}

		/**
		 * Moves the playhead in the timeline of the movie clip.
		 */
		public function play(): void
		{
			if (this._totalFrames > 1)
			{
				this._inPlay = true;
			}
		}

		/**
		 * Stops the playhead in the movie clip.
		 */
		public function stop(): void
		{
			this._inPlay = false;
		}

		/**
		 * Brings the playhead to the specified frame of the movie clip and stops it there. First frame is "1"
		 *
		 * @param frame A number representing the frame number, or a string representing the label of the frame, to which the playhead is sent.
		 */
		public function gotoAndStop(frame: *): void
		{
			this.stop();
			this.checkAndSetCurrentFrame(frame);
			this.draw();
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

		// --------------------------------------------------------------------------
		//
		// PRIVATE METHODS
		//
		// --------------------------------------------------------------------------
		private function checkAndSetCurrentFrame(frame: *): void
		{
			if (frame is uint)
			{
				if (frame == 0)
				{
					throw new Error("'0' - is wrong start frame number. Like in AS3 MovieClip API frames numeration starts from '1'");
				}

				frame -= 1;
			}
			else
			{
				if (this._reversePlayback)
				{
					frame = this._gafAsset.config.animationSequences.getEndFrameNo(frame) || this.totalFrames - 1;
				}
				else
				{
					frame = this._gafAsset.config.animationSequences.getStartFrameNo(frame);
				}
				
			}

			if (frame <= this._totalFrames)
			{
				this._currentFrame = frame;
				this._lastFrameTime = this._elapsedTime;
			}

			if (this.playingSequence && !this.playingSequence.isSequenceFrame(this._currentFrame + 1))
			{
				this.playingSequence = null;
			}
		}

		private function clearDisplayList(): void
		{
			this.removeChildren();

			for each (var pixelMaskimage: PixelMaskDisplayObject in this.maskedImagesDictionary)
			{
				pixelMaskimage.removeChildren();
			}
		}

		private var tmpMaskTransformationMatrix: Matrix = new Matrix();

		private function draw(): void
		{
			var i: int;
			var pixelMaskDisplayObject: PixelMaskDisplayObject;
			
			if (_gafAsset.config.debugRegions)
			{
				// Non optimized way when there are debug regions
				this.clearDisplayList();
			}
			else
			{
				var displayObject: DisplayObject;
				// Just hide the children to avoir dispatching a lot of events and alloc temporary arrays
				for (i = (this.numChildren - 1); i >= 0; i--)
				{
					displayObject = this.getChildAt(i);
					displayObject.visible = false;
					displayObject.alpha = 0;
				}

				
				for each (pixelMaskDisplayObject in this.maskedImagesDictionary)
				{
					for (i = (pixelMaskDisplayObject.numChildren - 1); i >= 0; i--)
					{
						displayObject = pixelMaskDisplayObject.getChildAt(i);
						displayObject.visible = false;
						displayObject.alpha = 0;
					}
				}
			}

			var image: GAFImage;

			if (this._gafAsset.config.animationConfigFrames.frames.length > this._currentFrame)
			{
				var frameConfig: CAnimationFrame = this._gafAsset.config.animationConfigFrames.frames[this._currentFrame];
				var mustReorder: Boolean;
				var zIndex: uint;
				for each (var instance: CAnimationFrameInstance in frameConfig.instances)
				{
					image = this.imagesDictionary[instance.id];

					if (image)
					{
						image.alpha = instance.alpha;
						image.visible = true;

						if (instance.maskID)
						{
							var maskImage: GAFImage = this.masksDictionary[instance.maskID];
							if (maskImage)
							{
								pixelMaskDisplayObject = this.maskedImagesDictionary[instance.maskID];
								pixelMaskDisplayObject.visible = true;

								mustReorder ||= (pixelMaskDisplayObject.zIndex != zIndex);
								pixelMaskDisplayObject.zIndex = zIndex;
								pixelMaskDisplayObject.mustReorder ||= (image.zIndex != zIndex);

								if (image.parent != pixelMaskDisplayObject)
								{
									pixelMaskDisplayObject.addChild(image);
									mustReorder = true;
								}

								var maskInstance: CAnimationFrameInstance = frameConfig.getInstanceByID(instance.maskID);
								if (maskInstance)
								{
									instance.applyTransformMatrix(image.transformationMatrix, image.assetTexture.pivotMatrix, this.scale);

									maskInstance.applyTransformMatrix(tmpMaskTransformationMatrix, maskImage.assetTexture.pivotMatrix, this.scale);
									tmpMaskTransformationMatrix.invert();
									image.transformationMatrix.concat(tmpMaskTransformationMatrix);

									maskInstance.applyTransformMatrix(pixelMaskDisplayObject.transformationMatrix, maskImage.assetTexture.pivotMatrix, this.scale);
								}
								else
								{
									throw new Error("Unable to find mask with ID " + instance.maskID);
								}

								// !!! Currently it's not possible to use filters under mask. This limitation will be removed in a future Stage3D version.
								// TODO: uncomment this line when this limitation will be removed
								// this.updateFilter(image, instance, this.scale);

								image.filter = null;

								if (!pixelMaskDisplayObject.parent)
								{
									this.addChild(pixelMaskDisplayObject);
								}
							}
							else
							{
								throw new Error("Unable to find mask with ID " + instance.maskID);
							}
						}
						else
						{
							mustReorder ||= (image.zIndex != zIndex);

							instance.applyTransformMatrix(image.transformationMatrix, image.assetTexture.pivotMatrix, this.scale);
							this.updateFilter(image, instance, this.scale);

							if (image.parent != this)
							{
								this.addChild(image);
								mustReorder = true;
							}
						}
						image.zIndex = zIndex;
					}

					++zIndex;
				}
			}

			if (mustReorder)
			{
				sortChildren(sortDisplayObjects);
			}

			for each (pixelMaskDisplayObject in this.maskedImagesDictionary)
			{
				if (pixelMaskDisplayObject.mustReorder)
				{
					pixelMaskDisplayObject.mustReorder = false;
					pixelMaskDisplayObject.sortChildren(sortDisplayObjects);
				}
			}

			var debugView: Quad;
			for each (var debugRegion: GAFDebugInformation in _gafAsset.config.debugRegions)
			{
				switch (debugRegion.type)
				{
					case GAFDebugInformation.TYPE_POINT:
						debugView = new Quad(4, 4, debugRegion.color);
						debugView.x = debugRegion.point.x - 2;
						debugView.y = debugRegion.point.y - 2;
						debugView.alpha = debugRegion.alpha;
						break;
					case GAFDebugInformation.TYPE_RECT:
						debugView = new Quad(debugRegion.rect.width, debugRegion.rect.height, debugRegion.color);
						debugView.x = debugRegion.rect.x;
						debugView.y = debugRegion.rect.y;
						debugView.alpha = debugRegion.alpha;
						break;
				}

				addChild(debugView);
			}

			var sequence: CAnimationSequence;
			if (this.hasEventListener(EVENT_TYPE_SEQUENCE_START))
			{
				sequence = this._gafAsset.config.animationSequences.getSequenceStart(this._currentFrame + 1);
				if (sequence)
				{
					this.dispatchEventWith(EVENT_TYPE_SEQUENCE_START, false, sequence);
				}
			}
			if (this.hasEventListener(EVENT_TYPE_SEQUENCE_END))
			{
				sequence = this._gafAsset.config.animationSequences.getSequenceEnd(this._currentFrame + 1);
				if (sequence)
				{
					this.dispatchEventWith(EVENT_TYPE_SEQUENCE_END, false, sequence);
				}
			}
		}

		private function sortDisplayObjects(a: DisplayObject, b: DisplayObject): int
		{
			var aZindex: uint = a.hasOwnProperty('zIndex') ? a['zIndex'] : 0;
			var bZindex: uint = b.hasOwnProperty('zIndex') ? b['zIndex'] : 0;

			if (aZindex > bZindex)
				return 1;
			else if (aZindex < bZindex)
				return -1;
			else
				return 0;
		}

		private function updateFilter(image: Image, instance: CAnimationFrameInstance, scale: Number): void
		{
			var gafFilter: GAFFilter;

			if (!image.filter && !instance.filter)
			{
				// do nothing. Should be in most cases
				return;
			}
			else if (image.filter && instance.filter)
			{
				gafFilter = image.filter as GAFFilter;
				gafFilter.setConfig(instance.filter, scale);
			}
			else if (image.filter && !instance.filter)
			{
				image.filter.dispose();
				image.filter = null;
			}
			else if (!image.filter && instance.filter)
			{
				gafFilter = new GAFFilter();
				gafFilter.setConfig(instance.filter, scale);
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
			this.fps = this._gafAsset.config.stageConfig ? this._gafAsset.config.stageConfig.fps : 30;

			var animationObjectsDictionary: Object = this._gafAsset.config.animationObjects.animationObjectsDictionary;

			var image: GAFImage;
			for each (var animationObjectConfig: CAnimationObject in animationObjectsDictionary)
			{
				image = new GAFImage(this._gafAsset.textureAtlas.getTexture(animationObjectConfig.textureElementID, this._mappedAssetID));
				image.name = animationObjectConfig.instanceID;
				image.smoothing = this._smoothing;

				if (animationObjectConfig.mask)
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
			
			Starling.juggler.add(this);
		}

		// --------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		// --------------------------------------------------------------------------
		/**
		 * Disposes all resources of the display object instance. Note: this method won't delete used texture atlases from GPU memory.
		 * To delete texture atlases from GPU memory use <code>unloadFromVideoMemory()</code> method for <code>GAFAsset</code> instance
		 * from what <code>GAFMovieClip</code> was instantiated.
		 * Call this method every time before delete no longer required instance! Otherwise GPU memory leak may occur!
		 */
		override public function dispose(): void
		{
			this.stop();
			
			Starling.juggler.remove(this);

			this._gafAsset = null;

			var image: GAFImage;

			for each (image in this.imagesDictionary)
			{
				image.dispose();
			}

			for each (image in this.masksDictionary)
			{
				image.dispose();
			}

			for each (var pixelMaskDisplayObject: PixelMaskDisplayObject in this.maskedImagesDictionary)
			{
				pixelMaskDisplayObject.dispose();
			}

			super.dispose();
		}

		public function advanceTime(time: Number): void
		{
			if (_inPlay)
			{
				this._elapsedTime += time;

				var nbFrames: int = (this._elapsedTime - this._lastFrameTime) / _frameDuration;
				var isSkipping: Boolean;
				var sequence: CAnimationSequence;

				for (var i: int = 0; i < nbFrames; ++i)
				{
					isSkipping = (i + 1) != nbFrames;
					
					changeCurrentFrame();

					if (!isSkipping)
					{
						// Draw will trigger events if any
						this.draw();
					}
					else
					{
						// If we are skipping, we send our own events
						if (this.hasEventListener(EVENT_TYPE_SEQUENCE_SKIP_START))
						{
							sequence = this._gafAsset.config.animationSequences.getSequenceStart(this._currentFrame + 1);
							if (sequence)
							{
								this.dispatchEventWith(EVENT_TYPE_SEQUENCE_SKIP_START, false, sequence);
							}
						}
						if (this.hasEventListener(EVENT_TYPE_SEQUENCE_SKIP_END))
						{
							sequence = this._gafAsset.config.animationSequences.getSequenceEnd(this._currentFrame + 1);
							if (sequence)
							{
								this.dispatchEventWith(EVENT_TYPE_SEQUENCE_SKIP_END, false, sequence);
							}
						}
					}
				}
			}
		}

		private function changeCurrentFrame(): void
		{
			this._nextFrame = this._currentFrame + (this._reversePlayback ? -1 : 1);
			this._startFrame = (this.playingSequence ? this.playingSequence.startFrameNo : 1) - 1;
			this._finalFrame = (this.playingSequence ? this.playingSequence.endFrameNo : this._totalFrames) - 1;

			if (this._nextFrame >= this._startFrame && this._nextFrame <= this._finalFrame)
			{
				this._currentFrame = this._nextFrame;
				this._lastFrameTime = this._lastFrameTime + this._frameDuration;
			}
			else
			{
				if (!this._loop)
				{
					this.stop();
				}
				else
				{
					this._currentFrame = this._reversePlayback ? this._finalFrame : this._startFrame;
					this._lastFrameTime = this._lastFrameTime + this._frameDuration;
				}
			}
		}

		// --------------------------------------------------------------------------
		//
		// GETTERS AND SETTERS
		//
		// --------------------------------------------------------------------------
		/**
		 * Specifies the number of the frame in which the playhead is located in the timeline of the GAFMovieClip instance. First frame is "1"
		 */
		public function get currentFrame(): uint
		{
			return _currentFrame + 1;
			// Like in standart AS3 API for MovieClip first frame is "1" instead of "0" (but internally used "0")
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

		/**
		 * The smoothing filter that is used for the texture. Possible values are <code>TextureSmoothing.BILINEAR, TextureSmoothing.NONE, TextureSmoothing.TRILINEAR</code>
		 */
		public function set smoothing(value: String): void
		{
			if (TextureSmoothing.isValid(value))
			{
				this._smoothing = value;

				var image: GAFImage;

				for each (image in this.imagesDictionary)
				{
					image.smoothing = this._smoothing;
				}

				for each (image in this.masksDictionary)
				{
					image.smoothing = this._smoothing;
				}
			}
		}

		public function get smoothing(): String
		{
			return this._smoothing;
		}

		public function get useClipping(): Boolean
		{
			return this._useClipping;
		}

		/**
		 * Indicates whether movie clip is clipped (masked) by stage borders
		 */
		public function set useClipping(value: Boolean): void
		{
			this._useClipping = value;

			if (this._useClipping)
			{
				this.clipRect = new Rectangle(0, 0, this._gafAsset.config.stageConfig.width, this._gafAsset.config.stageConfig.height);
			}
			else
			{
				this.clipRect = null;
			}
		}

		public function get fps(): Number
		{
			return 1 / this._frameDuration;
		}

		/**
		 * Sets an individual frame rate for movie clip. If this value is lower than stage fps -  the movie clip will skip frames.
		 */
		public function set fps(value: Number): void
		{
			this._frameDuration = 1 / value;
		}

		public function get reversePlayback(): Boolean
		{
			return _reversePlayback;
		}

		/**
		 * Should animation play in reverse mode
		 */
		public function set reversePlayback(value: Boolean): void
		{
			_reversePlayback = value;
		}
	}
}
