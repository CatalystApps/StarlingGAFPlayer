package com.catalystapps.gaf.display
{
	import com.catalystapps.gaf.core.gaf_internal;
	import com.catalystapps.gaf.data.config.CTextureAtlas;
	import starling.display.QuadBatch;
	import starling.core.Starling;
	import starling.animation.IAnimatable;
	import com.catalystapps.gaf.data.GAFBundle;
	import com.catalystapps.gaf.data.GAFTimeline;
	import com.catalystapps.gaf.data.GAFDebugInformation;
	import com.catalystapps.gaf.data.GAFTimelineConfig;
	import com.catalystapps.gaf.data.config.CAnimationFrame;
	import com.catalystapps.gaf.data.config.CAnimationFrameInstance;
	import com.catalystapps.gaf.data.config.CAnimationObject;
	import com.catalystapps.gaf.data.config.CAnimationSequence;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.data.config.CTextFieldObject;
	import com.catalystapps.gaf.filter.GAFFilter;
	import com.catalystapps.gaf.utils.DebugUtility;

	import feathers.controls.text.TextFieldTextEditor;
	import feathers.core.ITextEditor;

	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.textures.TextureSmoothing;

	/** Dispatched when playhead reached first frame of sequence */
	[Event(name="typeSequenceStart", type="com.catalystapps.gaf.event.SequenceEvent")]

	/** Dispatched when playhead reached end frame of sequence */
	[Event(name="typeSequenceEnd", type="com.catalystapps.gaf.event.SequenceEvent")]
	
	/** Dispatched when playhead skip first frame of sequence, the data property of the event is the <code>CAnimationSequence</code> instance related to the event */
	[Event(name = "typeSequenceSkipStart", type = "starling.events.Event")]
	
	/** Dispatched when playhead skip end frame of sequence, the data property of the event is the <code>CAnimationSequence</code> instance related to the event */
	[Event(name = "typeSequenceSkipEnd", type = "starling.events.Event")]

	/**
	 * GAFMovieClip represents animation display object that is ready to be used in Starling display list. It has
	 * all controls for animation familiar from standard MovieClip (<code>play</code>, <code>stop</code>, <code>gotoAndPlay,</code> etc.)
	 * and some more like <code>loop</code>, <code>nPlay</code>, <code>setSequence</code> that helps manage playback
	 */
	dynamic public class GAFMovieClip extends Sprite implements IAnimatable, IGAFDisplayObject
	{
		public static const EVENT_TYPE_SEQUENCE_START: String = "typeSequenceStart";
		public static const EVENT_TYPE_SEQUENCE_END: String = "typeSequenceEnd";
		public static const EVENT_TYPE_SEQUENCE_SKIP_START: String = "typeSequenceSkipStart";
		public static const EVENT_TYPE_SEQUENCE_SKIP_END: String = "typeSequenceSkipEnd";
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

		private var _mappedAssetID: String;

		private var scale: Number;

		private var displayObjectsDictionary: Object;
		private var masksDictionary: Object;
		private var maskedImagesDictionary: Object;

		private var playingSequence: CAnimationSequence;

		private var _currentFrame: uint;
		private var _totalFrames: uint;

		private var _inPlay: Boolean;
		private var _loop: Boolean = true;

		private var _smoothing: String = TextureSmoothing.BILINEAR;

		private var _alphaLess1: Boolean;
		private var _masked: Boolean;
		private var _hasFilter: Boolean;
		private var _useClipping: Boolean;
		
		private var _elapsedTime: Number = 0;
		// Hold the current time spent animating
		private var _lastFrameTime: Number = 0;
		private var _frameDuration: Number;
		private var _reverse: Boolean;
		private var _nextFrame: int;
		private var _startFrame: int;
		private var _finalFrame: int;
		private var _addToJuggler: Boolean;
		private var _zIndex: uint;
		private var boundsAndPivot: QuadBatch;
		private var config: GAFTimelineConfig;

		// --------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/**
		 * Creates a new GAFMovieClip instance.
		 *
		 * @param gafTimeline <code>GAFTimeline</code> from what <code>GAFMovieClip</code> will be created
		 * @param mappedAssetID To be defined. For now - use default value
		 * @param fps defines the frame rate of the movie clip. If not set - the stage config frame rate will be used instead.
		 * @param addToJuggler if <code>true - GAFMovieClip</code> will be added to <code>Starling.juggler</code>
		 * and removed automatically on <code>dispose</code>
		 */
		public function GAFMovieClip(gafTimeline: GAFTimeline, mappedAssetID: String = "", fps: int = -1, addToJuggler: Boolean = true)
		{
			this.scale = gafTimeline.scale;
			this.config = gafTimeline.config;
			this._addToJuggler = addToJuggler;
			this._mappedAssetID = mappedAssetID;
			
			this.initialize(gafTimeline.textureAtlas, gafTimeline.gafBundle);
			
			this.boundsAndPivot = new QuadBatch();
			if (this.config.bounds)
			{
				this.updateBounds(this.config.bounds);
			}
			if (fps > 0)
			{
				this.fps = fps;
			}

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
		public function getChildByID(id: String): DisplayObject
		{
			return this.displayObjectsDictionary[id];
		}

		/**
		 * Returns the mask display object that exists with the specified ID. Use to obtain animation's masks
		 *
		 * @param id Mask ID
		 * @return The mask display object with the specified ID
		 */
		public function getMaskByID(id: String): DisplayObject
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
			var maskObject: DisplayObject = this.masksDictionary[id];
			if (maskObject)
			{
				var frameConfig: CAnimationFrame = this.config.animationConfigFrames.frames[this._currentFrame];

				var maskInstance: CAnimationFrameInstance = frameConfig.getInstanceByID(id);
				if (maskInstance)
				{
					var maskPivotMatrix: Matrix;
					if (maskObject is IGAFImage)
					{
						maskPivotMatrix = (maskObject as IGAFImage).assetTexture.pivotMatrix;
					}
					else
					{
						maskPivotMatrix = new Matrix();
					}
					var maskTransformMatrix: Matrix = maskInstance.getTransformMatrix(maskPivotMatrix, this.scale).clone();

					maskObject.transformationMatrix = maskTransformMatrix;

					////////////////////////////////

					var cFilter: CFilter = new CFilter();
					var cmf: Vector.<Number> = new <Number>[1, 0, 0, 0, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0];
					cmf.fixed = true;
					cFilter.addColorMatrixFilter(cmf);

					var gafFilter: GAFFilter = new GAFFilter();
					gafFilter.setConfig(cFilter, scale);

					maskObject.filter = gafFilter;

					////////////////////////////////

					this.addChild(maskObject);
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
			var maskObject: DisplayObject = this.masksDictionary[id];
			if (maskObject)
			{
				maskObject.transformationMatrix = new Matrix();
				maskObject.filter = null;

				if (maskObject.parent == this)
				{
					this.removeChild(maskObject);
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
			this.playingSequence = this.config.animationSequences.getSecuenceByID(id);

			if (this.playingSequence)
			{
				if (play)
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
			if (this._totalFrames > 1)
			{
				this._inPlay = true;
			}
			
			var mc: GAFMovieClip;
			for (var i: int = 0; i < this.numChildren - 1; i++)
			{
				mc = this.getChildAt(i) as GAFMovieClip;
				if (mc)
				{
					mc.play();
				}
			}
		}

		/**
		 * Stops the playhead in the movie clip.
		 */
		public function stop(): void
		{
			this._inPlay = false;
			
			var mc: GAFMovieClip;
			for (var i: int = 0; i < this.numChildren - 1; i++)
			{
				mc = this.getChildAt(i) as GAFMovieClip;
				if (mc)
				{
					mc.stop();
				}
			}
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
		
		/** Advances all objects by a certain time (in seconds).
		 * @see starling.animation.IAnimatable
		 */
		public function advanceTime(time: Number): void
		{
			if (_inPlay && _frameDuration != Number.POSITIVE_INFINITY)
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
							sequence = this.config.animationSequences.getSequenceStart(this._currentFrame + 1);
							if (sequence)
							{
								this.dispatchEventWith(EVENT_TYPE_SEQUENCE_SKIP_START, false, sequence);
							}
						}
						if (this.hasEventListener(EVENT_TYPE_SEQUENCE_SKIP_END))
						{
							sequence = this.config.animationSequences.getSequenceEnd(this._currentFrame + 1);
							if (sequence)
							{
								this.dispatchEventWith(EVENT_TYPE_SEQUENCE_SKIP_END, false, sequence);
							}
						}
					}
				}
			}
		}
		
		/** Shows bounds of a whole animation with a pivot point.
		 * Used for debug purposes.
		 */
		public function showBounds(value: Boolean): void
		{
			if (value)
			{
				this.addChild(this.boundsAndPivot);
			}
			else
			{
				this.removeChild(this.boundsAndPivot);
			}
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

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
				frame = this.config.animationSequences.getStartFrameNo(frame);
			}

			if (frame <= this._totalFrames)
			{
				this._currentFrame = frame;
			}

			if (this.playingSequence && !this.playingSequence.isSequenceFrame(this._currentFrame + 1))
			{
				this.playingSequence = null;
			}
		}

		private function clearDisplayList(): void
		{
			this.removeChildren();

			for each (var pixelMaskImage: GAFPixelMaskDisplayObject in this.maskedImagesDictionary)
			{
				pixelMaskImage.removeChildren();
			}
		}
		
		private function updateAlphaMaskedAndHasFilter(mc: GAFMovieClip, alphaLess1: Boolean, masked: Boolean, hasFilter: Boolean): void
		{
			var changed: Boolean;
			if (mc._alphaLess1 != alphaLess1)
			{
				mc._alphaLess1 = alphaLess1;
				changed = true;
			}
			if (mc._masked != masked)
			{
				mc._masked = masked;
				changed = true;
			}
			if (mc._hasFilter != hasFilter)
			{
				mc._hasFilter = hasFilter;
				changed = true;
			}

			if (changed)
			{
				mc.draw();
			}
		}
		
		private var tmpMaskTransformationMatrix: Matrix = new Matrix();

		private function draw(): void
		{
			var i: int;
			var displayObject: IGAFDisplayObject;
			var maskedDisplayObject: GAFPixelMaskDisplayObject;
			
			if (config.debugRegions)
			{
				// Non optimized way when there are debug regions
				this.clearDisplayList();
			}
			else
			{
				// Just hide the children to avoir dispatching a lot of events and alloc temporary arrays
				for each (displayObject in this.displayObjectsDictionary)
				{
					displayObject.visible = false;
					displayObject.alpha = 0;
				}

				
				for each (maskedDisplayObject in this.maskedImagesDictionary)
				{
					for (i = (maskedDisplayObject.numChildren - 1); i >= 0; i--)
					{
						displayObject = maskedDisplayObject.getChildAt(i) as IGAFDisplayObject;
						displayObject.visible = false;
						displayObject.alpha = 0;
					}
				}
			}

			var objectPivotMatrix: Matrix;
			var maskPivotMatrix: Matrix;

			if (this.config.animationConfigFrames.frames.length > this._currentFrame)
			{
				var frameConfig: CAnimationFrame = this.config.animationConfigFrames.frames[this._currentFrame];
				var mustReorder: Boolean;
				var zIndex: uint;
				var instances: Vector.<CAnimationFrameInstance> = frameConfig.instances;
				var l: uint = instances.length;
				for (i = 0; i < l; i++)
				{
					var instance: CAnimationFrameInstance = instances[i];
					displayObject = this.displayObjectsDictionary[instance.id];
					
					objectPivotMatrix = getTransformMatrix(displayObject);

					if (displayObject)
					{
						displayObject.alpha = instance.alpha;
						displayObject.visible = true;

						if (instance.maskID)
						{
							if (DebugUtility.RENDERING_DEBUG && displayObject is GAFMovieClip)
							{
								updateAlphaMaskedAndHasFilter(
												displayObject as GAFMovieClip, instance.alpha < 1 || this._alphaLess1,
												true, (instance.filter != null) || this._hasFilter);
							}

							var maskObject: IGAFDisplayObject = this.masksDictionary[instance.maskID];
							if (maskObject)
							{
								maskedDisplayObject = this.maskedImagesDictionary[instance.maskID];
								maskedDisplayObject.visible = true;
								maskedDisplayObject.alpha = 1;

								mustReorder ||= (maskedDisplayObject.zIndex != zIndex);
								maskedDisplayObject.zIndex = zIndex;
								maskedDisplayObject.mustReorder ||= (displayObject.zIndex != zIndex);

								if (displayObject.parent != maskedDisplayObject)
								{
									maskedDisplayObject.addChild(displayObject as DisplayObject);
									mustReorder = true;
								}

								var maskInstance: CAnimationFrameInstance = frameConfig.getInstanceByID(instance.maskID);
								if (maskInstance)
								{
									maskPivotMatrix = getTransformMatrix(maskObject);
									displayObject.transformationMatrix = instance.calculateTransformMatrix(displayObject.transformationMatrix, objectPivotMatrix, this.scale);

									maskInstance.applyTransformMatrix(tmpMaskTransformationMatrix, maskPivotMatrix, this.scale);
									tmpMaskTransformationMatrix.invert();
									displayObject.transformationMatrix.concat(tmpMaskTransformationMatrix);

									maskedDisplayObject.transformationMatrix = maskInstance.calculateTransformMatrix(maskedDisplayObject.transformationMatrix, maskPivotMatrix, this.scale);
								}
								else
								{
									throw new Error("Unable to find mask with ID " + instance.maskID);
								}

								// !!! Currently it's not possible to use filters under mask. This limitation will be removed in a future Stage3D version.
								// TODO: uncomment this line when this limitation will be removed
								// this.updateFilter(displayObject, instance, this.scale);

								displayObject.filter = null;

								if (!maskedDisplayObject.parent)
								{
									this.addChild(maskedDisplayObject);
									mustReorder = true;
								}
							}
							else
							{
								throw new Error("Unable to find mask with ID " + instance.maskID);
							}
						}
						else
						{
							if (DebugUtility.RENDERING_DEBUG && displayObject is GAFMovieClip)
							{
								updateAlphaMaskedAndHasFilter(displayObject as GAFMovieClip,
															  instance.alpha < 1 || this._alphaLess1,
															  this._masked,
															  (instance.filter != null) || this._hasFilter);
							}

							mustReorder ||= (displayObject.zIndex != zIndex);

							displayObject.transformationMatrix = instance.calculateTransformMatrix(displayObject.transformationMatrix, objectPivotMatrix, this.scale);
							this.updateFilter(displayObject, instance, this.scale);

							if (displayObject.parent != this)
							{
								this.addChild(displayObject as DisplayObject);
								mustReorder = true;
							}
						}
						
						displayObject.zIndex = zIndex;

						if (DebugUtility.RENDERING_DEBUG && displayObject is IGAFDebug)
						{
							var colors: Vector.<uint> = DebugUtility.getRenderingDifficultyColor(
									instance, this._alphaLess1, this._masked, this._hasFilter);
							(displayObject as IGAFDebug).debugColors = colors;
						}
					}
					++zIndex;
				}
			}
			
			if (mustReorder)
			{
				sortChildren(sortDisplayObjects);
			}

			for each (maskedDisplayObject in this.maskedImagesDictionary)
			{
				if (maskedDisplayObject.mustReorder)
				{
					maskedDisplayObject.mustReorder = false;
					maskedDisplayObject.sortChildren(sortDisplayObjects);
				}
			}

			var debugView: Quad;
			for each (var debugRegion: GAFDebugInformation in config.debugRegions)
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
				sequence = this.config.animationSequences.getSequenceStart(this._currentFrame + 1);
				if (sequence)
				{
					this.dispatchEventWith(EVENT_TYPE_SEQUENCE_START, false, sequence);
				}
			}
			if (this.hasEventListener(EVENT_TYPE_SEQUENCE_END))
			{
				sequence = this.config.animationSequences.getSequenceEnd(this._currentFrame + 1);
				if (sequence)
				{
					this.dispatchEventWith(EVENT_TYPE_SEQUENCE_END, false, sequence);
				}
			}
		}

		private function getTransformMatrix(displayObject: IGAFDisplayObject): Matrix
		{
			if (displayObject is IGAFImage)
			{
				return (displayObject as IGAFImage).assetTexture.pivotMatrix;
			}
			else
			{
				return new Matrix();
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

		private function updateFilter(image: IGAFDisplayObject, instance: CAnimationFrameInstance, scale: Number): void
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

		private function initialize(textureAtlas : CTextureAtlas, gafBundle : GAFBundle): void
		{
			this.displayObjectsDictionary = {};
			this.masksDictionary = {};
			this.maskedImagesDictionary = {};

			this._currentFrame = 0;
			this._totalFrames = this.config.framesCount;
			this.fps = this.config.stageConfig ? this.config.stageConfig.fps : Starling.current.nativeStage.frameRate;

			var animationObjectsDictionary: Object = this.config.animationObjects.animationObjectsDictionary;

			for each (var animationObjectConfig: CAnimationObject in animationObjectsDictionary)
			{
				var displayObject: DisplayObject;
				switch (animationObjectConfig.type)
				{
					case CAnimationObject.TYPE_TEXTURE:
						var texture: IGAFTexture = textureAtlas.getTexture(animationObjectConfig.regionID, this._mappedAssetID);
						if (texture is GAFScale9Texture && !animationObjectConfig.mask) // GAFScale9Image doesn't work as mask
						{
							displayObject = new GAFScale9Image(texture as GAFScale9Texture);
						}
						else
						{
							displayObject = new GAFImage(texture);
							(displayObject as GAFImage).smoothing = this._smoothing;
						}
						break;
					case CAnimationObject.TYPE_TEXTFIELD:
						var tfObj: CTextFieldObject = this.config.textFields.textFieldObjectsDictionary[animationObjectConfig.regionID];
						var tf: GAFTextField = new GAFTextField(tfObj.width, tfObj.height);
						tf.text = tfObj.text;
						tf.restrict = tfObj.restrict;
						tf.isEditable = tfObj.editable;
						tf.displayAsPassword = tfObj.displayAsPassword;
						tf.maxChars = tfObj.maxChars;

						tf.textEditorProperties.textFormat = tfObj.textFormat;
						tf.textEditorProperties.embedFonts = tfObj.embedFonts;
						tf.textEditorProperties.multiline = tfObj.multiline;
						tf.textEditorProperties.wordWrap = tfObj.wordWrap;
						tf.textEditorFactory = function (): ITextEditor
						{
							return new TextFieldTextEditor();
						};
						displayObject = tf;
						break;
					case CAnimationObject.TYPE_TIMELINE:
						var mc: GAFMovieClip = new GAFMovieClip(gafBundle.gaf_internal::getGAFTimelineByID(this.config.assetID, animationObjectConfig.regionID));
						if (!mc.inPlay)
						{
							mc.play();
						}

						displayObject = mc;
						break;
				}

				if (animationObjectConfig.mask)
				{
					this.masksDictionary[animationObjectConfig.instanceID] = displayObject;

					var pixelMaskDisplayObject: GAFPixelMaskDisplayObject = new GAFPixelMaskDisplayObject();
					pixelMaskDisplayObject.mask = displayObject;

					this.maskedImagesDictionary[animationObjectConfig.instanceID] = pixelMaskDisplayObject;
				}
				else
				{
					this.displayObjectsDictionary[animationObjectConfig.instanceID] = displayObject;
				}

				if (this.config.namedParts != null)
				{
					var instanceName: String = this.config.namedParts[animationObjectConfig.instanceID];
					if (instanceName != null && !this.hasOwnProperty(instanceName))
					{
						this[this.config.namedParts[animationObjectConfig.instanceID]] = displayObject;
						displayObject.name = instanceName;
					}
				}
			}
			
			if (this._addToJuggler)
			{
				Starling.juggler.add(this);
			}
		}
		
		private function updateBounds(bounds: Rectangle): void
		{
			this.boundsAndPivot.reset();
			//bounds
			if (bounds.width > 0
			&&  bounds.height > 0)
			{
				var quad: Quad = new Quad(bounds.width * this.scale, 2, 0xff0000);
				quad.x = bounds.x * this.scale;
				quad.y = bounds.y * this.scale;
				this.boundsAndPivot.addQuad(quad);
				quad = new Quad(bounds.width * this.scale, 2, 0xff0000);
				quad.x = bounds.x * this.scale;
				quad.y = bounds.bottom * this.scale - 2;
				this.boundsAndPivot.addQuad(quad);
				quad = new Quad(2, bounds.height * this.scale, 0xff0000);
				quad.x = bounds.x * this.scale;
				quad.y = bounds.y * this.scale;
				this.boundsAndPivot.addQuad(quad);
				quad = new Quad(2, bounds.height * this.scale, 0xff0000);
				quad.x = bounds.right * this.scale - 2;
				quad.y = bounds.y * this.scale;
				this.boundsAndPivot.addQuad(quad);
			}
			//pivot point
			quad = new Quad(5, 5, 0xff0000);
			this.boundsAndPivot.addQuad(quad);
		}

		//--------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * Disposes all resources of the display object instance. Note: this method won't delete used texture atlases from GPU memory.
		 * To delete texture atlases from GPU memory use <code>unloadFromVideoMemory()</code> method for <code>GAFTimeline</code> instance
		 * from what <code>GAFMovieClip</code> was instantiated.
		 * Call this method every time before delete no longer required instance! Otherwise GPU memory leak may occur!
		 */
		override public function dispose(): void
		{
			this.stop();
			
			if (this._addToJuggler)
			{
				Starling.juggler.remove(this);
			}

			this.config = null;

			var displayObject: DisplayObject;

			for each(displayObject in this.displayObjectsDictionary)
			{
				displayObject.dispose();
			}

			for each(displayObject in this.masksDictionary)
			{
				displayObject.dispose();
			}

			for each(var pixelMaskDisplayObject: GAFPixelMaskDisplayObject in this.maskedImagesDictionary)
			{
				pixelMaskDisplayObject.dispose();
			}

			super.dispose();
		}

		/** @private
		 * Invalidates textfields to correct display size
		 * @param matrix
		 */
		override public function set transformationMatrix(matrix: Matrix): void
		{
			super.transformationMatrix = matrix;

			for (var i: uint = 0; i < this.numChildren; i++)
			{
				var child: GAFTextField = this.getChildAt(i) as GAFTextField;
				if (child)
				{
					child.invalidateSize();
				}
			}
		}

		//--------------------------------------------------------------------------
		//
		//  EVENT HANDLERS
		//
		//--------------------------------------------------------------------------

		private function changeCurrentFrame(): void
		{
			this._nextFrame = this._currentFrame + (this._reverse ? -1 : 1);
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
					this._currentFrame = this._reverse ? this._finalFrame : this._startFrame;
					this._lastFrameTime = this._lastFrameTime + this._frameDuration;
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
			return this._currentFrame + 1;// Like in standart AS3 API for MovieClip first frame is "1" instead of "0" (but internally used "0")
		}

		/**
		 * The total number of frames in the GAFMovieClip instance.
		 */
		public function get totalFrames(): uint
		{
			return this._totalFrames;
		}

		/**
		 * Indicates whether GAFMovieClip instance already in play
		 */
		public function get inPlay(): Boolean
		{
			return this._inPlay;
		}

		/**
		 * Indicates whether GAFMovieClip instance continue playing from start frame after playback reached animation end
		 */
		public function get loop(): Boolean
		{
			return this._loop;
		}

		public function set loop(loop: Boolean): void
		{
			this._loop = loop;
		}

		/**
		 * The smoothing filter that is used for the texture. Possible values are <code>TextureSmoothing.BILINEAR, TextureSmoothing.NONE, TextureSmoothing.TRILINEAR</code>
		 */
		public function set smoothing(value: String): void
		{
			if (TextureSmoothing.isValid(value))
			{
				this._smoothing = value;

				var image: IGAFDisplayObject;

				for each (image in this.displayObjectsDictionary)
				{
					if (image is GAFImage)
					{
						(image as GAFImage).smoothing = this._smoothing;
					}
				}

				for each (image in this.masksDictionary)
				{
					if (image is GAFImage)
					{
						(image as GAFImage).smoothing = this._smoothing;
					}
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
		 * if set <code>true</code> - <code>GAFMivieclip</code> will be clipped with flash stage dimensions
		 */
		public function set useClipping(value: Boolean): void
		{
			this._useClipping = value;

			if (this._useClipping && this.config.stageConfig)
			{
				this.clipRect = new Rectangle(0,0, this.config.stageConfig.width, this.config.stageConfig.height);
			}
			else
			{
				this.clipRect = null;
			}
		}
		
		public function get fps(): Number
		{
			if (this._frameDuration == Number.POSITIVE_INFINITY)
			{
				return 0;
			}
			return 1 / this._frameDuration;
		}

		/**
		 * Sets an individual frame rate for <code>GAFMovieClip</code>. If this value is lower than stage fps -  the <code>GAFMovieClip</code> will skip frames.
		 */
		public function set fps(value: Number): void
		{
			if (value <= 0)
			{
				this._frameDuration = Number.POSITIVE_INFINITY;
			}
			else
			{
				this._frameDuration = 1 / value;
			}
		}

		public function get reverse(): Boolean
		{
			return _reverse;
		}

		/**
		 * If <code>true</code> animation will be playing in reverse mode
		 */
		public function set reverse(value: Boolean): void
		{
			_reverse = value;
			
			var mc: GAFMovieClip;
			for (var i: int = 0; i < this.numChildren - 1; i++)
			{
				mc = this.getChildAt(i) as GAFMovieClip;
				if (mc)
				{
					mc.reverse = value;
				}
			}
		}
		
		/**
		 * Depth of display object in parent container
		 * @private
		 */
		public function get zIndex(): uint
		{
			return _zIndex;
		}

		/**
		 * Depth of display object in parent container
		 * @private
		 */
		public function set zIndex(value: uint): void
		{
			_zIndex = value;
		}
	}
}
