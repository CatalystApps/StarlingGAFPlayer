package com.catalystapps.gaf.display
{
	import com.catalystapps.gaf.data.GAFAsset;
	import com.catalystapps.gaf.data.GAFDebugInformation;
	import com.catalystapps.gaf.data.config.CAnimationFrame;
	import com.catalystapps.gaf.data.config.CAnimationFrameInstance;
	import com.catalystapps.gaf.data.config.CAnimationObject;
	import com.catalystapps.gaf.data.config.CAnimationSequence;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.data.config.CTextFieldObject;
	import com.catalystapps.gaf.event.SequenceEvent;
	import com.catalystapps.gaf.filter.GAFFilter;
	import com.catalystapps.gaf.utils.DebugUtility;

	import feathers.controls.text.TextFieldTextEditor;
	import feathers.core.ITextEditor;

	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.extensions.pixelmask.PixelMaskDisplayObject;
	import starling.textures.TextureSmoothing;

	/** Dispatched when playhead reached first frame of sequence */
	[Event(name="typeSequenceStart", type="com.catalystapps.gaf.event.SequenceEvent")]

	/** Dispatched when playhead reached end frame of sequence */
	[Event(name="typeSequenceEnd", type="com.catalystapps.gaf.event.SequenceEvent")]

	/**
	 * GAFMovieClip represents animation display object that is ready to be used in Starling display list. It has
	 * all controls for animation familiar from standard MovieClip (<code>play</code>, <code>stop</code>, <code>gotoAndPlay,</code> etc.)
	 * and some more like <code>loop</code>, <code>nPlay</code>, <code>setSequence</code> that helps manage playback
	 */
	dynamic public class GAFMovieClip extends Sprite
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

		private var staticObjectsDictionary: Object;
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
		public function getChildByID(id: String): DisplayObject
		{
			return this.staticObjectsDictionary[id];
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
				var frameConfig: CAnimationFrame = this._gafAsset.config.animationConfigFrames.frames[this._currentFrame];

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
		 * @param play Play or not immediately. <code>true</code> - starts playng from sequence start frame. <code>false</code> - go to sequence start frame and stop
		 *
		 * @return
		 */
		public function setSequence(id: String, play: Boolean = true): CAnimationSequence
		{
			this.playingSequence = this._gafAsset.config.animationSequences.getSecuenceByID(id);

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
				// For some unknown reason there is a case where "this" has no "ENTER_FRAME" listener but method "hasEventListener" returns true
				// Happens after call play(), stop() and play()
				// XXX TODO: find reason and fix it if possible (current realization doesn't break anything, just looks strange)
				if (this.hasEventListener(Event.ENTER_FRAME))
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
			if (this.hasEventListener(Event.ENTER_FRAME))
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
				frame = this._gafAsset.config.animationSequences.getStartFrameNo(frame);
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
			//this.removeChildren();

			for each (var pixelMaskImage: PixelMaskDisplayObject in
					this.maskedImagesDictionary)
			{
				pixelMaskImage.removeChildren();
			}
		}

		private function draw(): void
		{
			this.clearDisplayList();

			var staticObject: DisplayObject;
			var objectPivotMatrix: Matrix;
			var maskPivotMatrix: Matrix;

			function updateAlphaMaskedAndHasFilter(mc: GAFMovieClip, alphaLess1: Boolean, masked: Boolean, hasFilter: Boolean): void
			{
				var changed: Boolean;
				if (mc._alphaLess1 != alphaLess1)
				{
					mc.alphaLess1 = alphaLess1;
					changed = true;
				}
				if (mc._masked != masked)
				{
					mc.masked = masked;
					changed = true;
				}
				if (mc._hasFilter != hasFilter)
				{
					mc.hasFilter = hasFilter;
					changed = true;
				}

				if (changed)
				{
					mc.draw();
				}
			}

			if (this._gafAsset.config.animationConfigFrames.frames.length > this._currentFrame)
			{
				var frameConfig: CAnimationFrame = this._gafAsset.config.animationConfigFrames.frames[this._currentFrame];
				var firstStaticObject: DisplayObject;
				var instances: Vector.<CAnimationFrameInstance> = frameConfig.instances;
				var l: uint = instances.length;
				for (var i: int = 0; i < l; i++)
				{
					var instance: CAnimationFrameInstance = instances[i];
					staticObject = this.staticObjectsDictionary[instance.id];

					if (staticObject)
					{
						if (firstStaticObject == null)
						{
							firstStaticObject = staticObject;
						}

						if (staticObject is IGAFImage)
						{
							objectPivotMatrix = (staticObject as IGAFImage).assetTexture.pivotMatrix;
						}
						else
						{
							objectPivotMatrix = new Matrix();
						}

						staticObject.alpha = instance.alpha;

						if (instance.maskID)
						{
							if (DebugUtility.RENDERING_DEBUG && staticObject is GAFMovieClip)
							{
								updateAlphaMaskedAndHasFilter(
												staticObject as GAFMovieClip, instance.alpha < 1 || this._alphaLess1,
												true, (instance.filter != null) || this._hasFilter);
							}

							var maskObject: DisplayObject = this.masksDictionary[instance.maskID];

							if (maskObject)
							{
								if (maskObject is IGAFImage)
								{
									maskPivotMatrix = (maskObject as IGAFImage).assetTexture.pivotMatrix;
								}
								else
								{
									maskPivotMatrix = new Matrix();
								}

								var pixelMaskDisplayObject: PixelMaskDisplayObject = this.maskedImagesDictionary[instance.maskID];

								pixelMaskDisplayObject.addChild(staticObject);

								var maskInstance: CAnimationFrameInstance = frameConfig.getInstanceByID(instance.maskID);

								if (maskInstance)
								{
									var maskTransformMatrix: Matrix = maskInstance.getTransformMatrix(maskPivotMatrix,
											this.scale).clone();
									var imageTransformMatrix: Matrix = instance.getTransformMatrix(objectPivotMatrix,
											this.scale).clone();

									maskTransformMatrix.invert();
									imageTransformMatrix.concat(maskTransformMatrix);

									staticObject.transformationMatrix = imageTransformMatrix;

									pixelMaskDisplayObject.transformationMatrix = maskInstance.getTransformMatrix(maskPivotMatrix,
											this.scale);
								}
								else
								{
									throw new Error("Unable to find mask with ID " + instance.maskID);
								}

								// !!! Currently it's not possible to use filters under mask. This limitation will be removed in a future Stage3D version.
								// TODO: uncomment this line when this limitation will be removed
								// this.updateFilter(staticObject, instance, this.scale);

								staticObject.filter = null;

								this.addChild(pixelMaskDisplayObject);
							}
							else
							{
								throw new Error("Unable to find mask with ID " + instance.maskID);
							}
						}
						else
						{
							if (DebugUtility.RENDERING_DEBUG && staticObject is GAFMovieClip)
							{
								updateAlphaMaskedAndHasFilter(
												staticObject as GAFMovieClip, instance.alpha < 1 || this._alphaLess1,
												false || this._masked, (instance.filter != null) || this._hasFilter);
							}

							staticObject.transformationMatrix = instance.getTransformMatrix(objectPivotMatrix, this.scale);
							this.updateFilter(staticObject, instance, this.scale);

							this.addChild(staticObject);
						}

						if (DebugUtility.RENDERING_DEBUG && staticObject is IGAFDebug)
						{
							var colors: Vector.<uint> = DebugUtility.getRenderingDifficultyColor(
									instance, this._alphaLess1, this._masked, this._hasFilter);
							(staticObject as IGAFDebug).debugColors = colors;
						}
					}
				}
				if (firstStaticObject != null)
				{
					var firstStaticObjectIndex: int = this.getChildIndex(firstStaticObject);
					while (firstStaticObjectIndex > 0)
					{
						var child: DisplayObject = this.getChildAt(0);
						if (child is GAFTextField)
						{
							(child as GAFTextField).clearFocus();
						}
						this.removeChild(child);

						firstStaticObjectIndex--;
					}
				}
			}

			var debugView: Quad;
			for each (var debugRegion: GAFDebugInformation in
					_gafAsset.config.debugRegions)
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
		}

		private function updateFilter(image: DisplayObject, instance: CAnimationFrameInstance, scale: Number): void
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
			this.staticObjectsDictionary = new Object();
			this.masksDictionary = new Object();
			this.maskedImagesDictionary = new Object();

			this._currentFrame = 0;
			this._totalFrames = this._gafAsset.config.animationConfigFrames.frames.length;

			var animationObjectsDictionary: Object = this._gafAsset.config.animationObjects.animationObjectsDictionary;

			for each (var animationObjectConfig: CAnimationObject in animationObjectsDictionary)
			{
				var staticObject: DisplayObject;
				switch (animationObjectConfig.type)
				{
					case "texture":
						var texture: IGAFTexture = this._gafAsset.textureAtlas.getTexture(
								animationObjectConfig.staticObjectID, this._mappedAssetID);
						if (texture is GAFScale9Texture && !animationObjectConfig.mask) // GAFScale9Image doesn't work as mask
						{
							staticObject = new GAFScale9Image(texture as GAFScale9Texture);
						}
						else
						{
							staticObject = new GAFImage(texture);
							(staticObject as GAFImage).smoothing = this._smoothing;
						}
						staticObject.name = animationObjectConfig.instanceID;
						break;
					case "textField":
						var tfObj: CTextFieldObject = this._gafAsset.config.textFields.textFieldObjectsDictionary[animationObjectConfig.staticObjectID];
						var tf: GAFTextField = new GAFTextField(tfObj.width, tfObj.height);
						tf.name = animationObjectConfig.instanceID;
						//tf.prompt = tfObj.text
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
						staticObject = tf;
						break;
					case "timeline":
						var mc: GAFMovieClip = new GAFMovieClip(this._gafAsset.gafBundle.getGAFAssetByID(animationObjectConfig.staticObjectID));
						mc.name = animationObjectConfig.instanceID;
						mc.play();
						staticObject = mc;
						break;
				}

				if (animationObjectConfig.mask)
				{
					this.masksDictionary[animationObjectConfig.instanceID] = staticObject;

					var pixelMaskDisplayObject: PixelMaskDisplayObject = new PixelMaskDisplayObject();
					pixelMaskDisplayObject.mask = staticObject;

					this.maskedImagesDictionary[animationObjectConfig.instanceID] = pixelMaskDisplayObject;
				}
				else
				{
					this.staticObjectsDictionary[animationObjectConfig.instanceID] = staticObject;
				}

				if (this._gafAsset.config.namedParts != null)
				{
					var instanceName: String = this._gafAsset.config.namedParts[animationObjectConfig.instanceID];
					if (instanceName != null && !this.hasOwnProperty(instanceName))
					{
						this[this._gafAsset.config.namedParts[animationObjectConfig.instanceID]] = staticObject;
					}
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

			var staticObject: DisplayObject;

			for each(staticObject in
					this.staticObjectsDictionary)
			{
				staticObject.dispose();
			}

			for each(staticObject in
					this.masksDictionary)
			{
				staticObject.dispose();
			}

			for each(var pixelMaskDisplayObject: PixelMaskDisplayObject in
					this.maskedImagesDictionary)
			{
				pixelMaskDisplayObject.dispose();
			}

			super.dispose();
		}

		/**
		 * Invalidates textfields to correct display size
		 * @param matrix
		 */
		override public function set transformationMatrix(matrix: Matrix): void
		{
			super.transformationMatrix = matrix;

			for (var i: uint = 0;
					i < this.numChildren;
					i++)
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

		private function changeCurrentFrame(event: Event): void
		{
			if (this.playingSequence)
			{
				if (this._currentFrame + 1 >= this.playingSequence.startFrameNo && this._currentFrame + 1 < this.playingSequence.endFrameNo)
				{
					this._currentFrame++;
				}
				else
				{
					if (!this._loop)
					{
						this.stop();

						return;
					}

					this._currentFrame = this.playingSequence.startFrameNo - 1;
				}
			}
			else
			{
				if (this._currentFrame < this._totalFrames - 1)
				{
					this._currentFrame++;
				}
				else
				{
					if (!this._loop)
					{
						this.stop();

						return;
					}

					this._currentFrame = 0;
				}
			}

			this.draw();

			var sequenceEvent: SequenceEvent = this._gafAsset.config.animationSequences.hasEvent(this._currentFrame + 1);

			if (sequenceEvent)
			{
				if (this.hasEventListener(sequenceEvent.type))
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

		public function set alphaLess1(value: Boolean): void
		{
			this._alphaLess1 = value;
		}

		public function set masked(value: Boolean): void
		{
			this._masked = value;
		}

		public function set hasFilter(value: Boolean): void
		{
			this._hasFilter = value;
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

				for each(image in
						this.imagesDictionary)
				{
					image.smoothing = this._smoothing;
				}

				for each(image in
						this.masksDictionary)
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

		public function set useClipping(value: Boolean): void
		{
			this._useClipping = value;

			if (this._useClipping)
			{
				this.clipRect = new Rectangle(0,0, this._gafAsset.config.stageConfig.width, this._gafAsset.config.stageConfig.height);
			}
			else
			{
				this.clipRect = null;
			}
		}
	}
}
