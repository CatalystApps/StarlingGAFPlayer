package com.catalystapps.gaf.display
{
import com.catalystapps.gaf.filter.GAFFilterChain;
import com.catalystapps.gaf.filter.masks.GAFStencilMaskStyle;

import flash.errors.IllegalOperationError;
import flash.events.ErrorEvent;

import starling.display.Image;
import starling.display.MovieClip;

import starling.events.Event;
	import com.catalystapps.gaf.data.GAFAsset;
	import com.catalystapps.gaf.data.config.CSound;
	import com.catalystapps.gaf.data.GAF;
	import com.catalystapps.gaf.core.gaf_internal;
	import com.catalystapps.gaf.data.GAFDebugInformation;
	import com.catalystapps.gaf.data.GAFTimeline;
	import com.catalystapps.gaf.data.GAFTimelineConfig;
	import com.catalystapps.gaf.data.config.CAnimationFrame;
	import com.catalystapps.gaf.data.config.CAnimationFrameInstance;
	import com.catalystapps.gaf.data.config.CAnimationObject;
	import com.catalystapps.gaf.data.config.CAnimationSequence;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.data.config.CFrameAction;
	import com.catalystapps.gaf.data.config.CTextFieldObject;
	import com.catalystapps.gaf.data.config.CTextureAtlas;
	import com.catalystapps.gaf.utils.DebugUtility;

	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.animation.IAnimatable;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Quad;
	import starling.display.MeshBatch;
	import starling.display.Sprite;
	import starling.rendering.Painter;
	import starling.textures.TextureSmoothing;

	/** Dispatched when playhead reached first frame of sequence */
	[Event(name="typeSequenceStart", type="starling.events.Event")]

	/** Dispatched when playhead reached end frame of sequence */
	[Event(name="typeSequenceEnd", type="starling.events.Event")]

	/** Dispatched whenever the movie has displayed its last frame. */
	[Event(name="complete", type="starling.events.Event")]

	/**
	 * GAFMovieClip represents animation display object that is ready to be used in Starling display list. It has
	 * all controls for animation familiar from standard MovieClip (<code>play</code>, <code>stop</code>, <code>gotoAndPlay,</code> etc.)
	 * and some more like <code>loop</code>, <code>nPlay</code>, <code>setSequence</code> that helps manage playback
	 */
	dynamic public class GAFMovieClip extends Sprite implements IAnimatable, IGAFDisplayObject, IMaxSize
	{
		public static const EVENT_TYPE_SEQUENCE_START: String = "typeSequenceStart";
		public static const EVENT_TYPE_SEQUENCE_END: String = "typeSequenceEnd";

		private static const HELPER_MATRIX: Matrix = new Matrix();
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

		private var _smoothing: String = TextureSmoothing.BILINEAR;

		private var _displayObjectsDictionary: Object;
		private var _stencilMasksDictionary: Object;
		private var _displayObjectsVector: Vector.<IGAFDisplayObject>;
		private var _imagesVector: Vector.<IGAFImage>;
		private var _mcVector: Vector.<GAFMovieClip>;

		private var _playingSequence: CAnimationSequence;
		private var _timelineBounds: Rectangle;
		private var _maxSize: Point;
		private var _boundsAndPivot: MeshBatch;
		private var _config: GAFTimelineConfig;
		private var _gafTimeline: GAFTimeline;

		private var _loop: Boolean = true;
		private var _skipFrames: Boolean = true;
		private var _reset: Boolean;
		private var _masked: Boolean;
		private var _inPlay: Boolean;
		private var _hidden: Boolean;
		private var _reverse: Boolean;
		private var _started: Boolean;
		private var _disposed: Boolean;
		private var _hasFilter: Boolean;
		private var _useClipping: Boolean;
		private var _alphaLessMax: Boolean;
		private var _addToJuggler: Boolean;

		private var _scale: Number;
		private var _contentScaleFactor: Number;
		private var _currentTime: Number = 0;
		// Hold the current time spent animating
		private var _lastFrameTime: Number = 0;
		private var _frameDuration: Number;

		private var _nextFrame: int;
		private var _startFrame: int;
		private var _finalFrame: int;
		private var _currentFrame: uint;
		private var _totalFrames: uint;

        private var _filterChain:GAFFilterChain;
		private var _filterConfig: CFilter;
		private var _filterScale: Number;

		private var _pivotChanged: Boolean;

		/** @private */
		gaf_internal var __debugOriginalAlpha: Number = NaN;

		private var _orientationChanged: Boolean;

		private var _stencilMaskStyle:GAFStencilMaskStyle;

		// --------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/**
		 * Creates a new GAFMovieClip instance.
		 *
		 * @param gafTimeline <code>GAFTimeline</code> from what <code>GAFMovieClip</code> will be created
		 * @param fps defines the frame rate of the movie clip. If not set - the stage config frame rate will be used instead.
		 * @param addToJuggler if <code>true - GAFMovieClip</code> will be added to <code>Starling.juggler</code>
		 * and removed automatically on <code>dispose</code>
		 */
		public function GAFMovieClip(gafTimeline: GAFTimeline, fps: int = -1, addToJuggler: Boolean = true)
		{
			this._gafTimeline = gafTimeline;
			this._config = gafTimeline.config;
			this._scale = gafTimeline.scale;
			this._contentScaleFactor = gafTimeline.contentScaleFactor;
			this._addToJuggler = addToJuggler;

			this.initialize(gafTimeline.textureAtlas, gafTimeline.gafAsset);

			if (this._config.bounds)
			{
				this._timelineBounds = this._config.bounds.clone();
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

		/** @private
		 * Returns the child display object that exists with the specified ID. Use to obtain animation's parts
		 *
		 * @param id Child ID
		 * @return The child display object with the specified ID
		 */
		public function getChildByID(id: String): DisplayObject
		{
			return this._displayObjectsDictionary[id];
		}

		/** @private
		 * Returns the mask display object that exists with the specified ID. Use to obtain animation's masks
		 *
		 * @param id Mask ID
		 * @return The mask display object with the specified ID
		 */
		public function getMaskByID(id: String): DisplayObject
		{
			return this._stencilMasksDictionary[id];
		}

		/**
		 * Shows mask display object that exists with the specified ID. Used for debug purposes only!
		 *
		 * @param id Mask ID
		 */
		public function showMaskByID(id: String): void
		{
			var maskObject: IGAFDisplayObject = this._displayObjectsDictionary[id];
			var maskAsDisplayObject: DisplayObject = maskObject as DisplayObject;
			var stencilMaskObject:DisplayObject  = this._stencilMasksDictionary[id];
			if (maskObject && stencilMaskObject)
			{
                maskAsDisplayObject.mask = stencilMaskObject;
                this.addChild(stencilMaskObject);
                this.addChild(maskAsDisplayObject);
			}
			else
			{
				trace("WARNING: mask object is missing. It might be disposed.");
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
			var maskObject: IGAFDisplayObject = this._displayObjectsDictionary[id];
			var maskAsDisplayObject: DisplayObject = maskObject as DisplayObject;
			var stencilMaskObject: DisplayObject = this._stencilMasksDictionary[id];
			if (stencilMaskObject)
			{
				if (stencilMaskObject.parent == this)
				{
                    stencilMaskObject.parent.mask = null;
					this.removeChild(stencilMaskObject);
					this.removeChild(maskAsDisplayObject);
				}
			}
			else
			{
				trace("WARNING: mask object is missing. It might be disposed.");
			}
		}

		/**
		 * Clear playing sequence. If animation already in play just continue playing without sequence limitation
		 */
		public function clearSequence(): void
		{
			this._playingSequence = null;
		}

		/**
		 * Returns id of the sequence where animation is right now. If there is no sequences - returns <code>null</code>.
		 *
		 * @return id of the sequence
		 */
		public function get currentSequence(): String
		{
			var sequence: CAnimationSequence = this._config.animationSequences.getSequenceByFrame(this.currentFrame);
			if (sequence)
			{
				return sequence.id;
			}
			return null;
		}

		/**
		 * Set sequence to play
		 *
		 * @param id Sequence ID
		 * @param play Play or not immediately. <code>true</code> - starts playing from sequence start frame. <code>false</code> - go to sequence start frame and stop
		 * @return sequence to play
		 */
		public function setSequence(id: String, play: Boolean = true): CAnimationSequence
		{
			this._playingSequence = this._config.animationSequences.getSequenceByID(id);

			if (this._playingSequence)
			{
				var startFrame: uint = this._reverse ? this._playingSequence.endFrameNo - 1 : this._playingSequence.startFrameNo;
				if (play)
				{
					this.gotoAndPlay(startFrame);
				}
				else
				{
					this.gotoAndStop(startFrame);
				}
			}

			return this._playingSequence;
		}

		/**
		 * Moves the playhead in the timeline of the movie clip <code>play()</code> or <code>play(false)</code>.
		 * Or moves the playhead in the timeline of the movie clip and all child movie clips <code>play(true)</code>.
		 * Use <code>play(true)</code> in case when animation contain nested timelines for correct playback right after
		 * initialization (like you see in the original swf file).
		 * @param applyToAllChildren Specifies whether playhead should be moved in the timeline of the movie clip
		 * (<code>false</code>) or also in the timelines of all child movie clips (<code>true</code>).
		 */
		public function play(applyToAllChildren: Boolean = false): void
		{
			this._started = true;

			if (applyToAllChildren)
			{
				var i: uint = this._mcVector.length;
				while (i--)
				{
					this._mcVector[i]._started = true;
				}
			}

			this._play(applyToAllChildren, true);
		}

		/**
		 * Stops the playhead in the movie clip <code>stop()</code> or <code>stop(false)</code>.
		 * Or stops the playhead in the movie clip and in all child movie clips <code>stop(true)</code>.
		 * Use <code>stop(true)</code> in case when animation contain nested timelines for full stop the
		 * playhead in the movie clip and in all child movie clips.
		 * @param applyToAllChildren Specifies whether playhead should be stopped in the timeline of the
		 * movie clip (<code>false</code>) or also in the timelines of all child movie clips (<code>true</code>)
		 */
		public function stop(applyToAllChildren: Boolean = false): void
		{
			this._started = false;

			if (applyToAllChildren)
			{
				var i: uint = this._mcVector.length;
				while (i--)
				{
					this._mcVector[i]._started = false;
				}
			}

			this._stop(applyToAllChildren, true);
		}

		/**
		 * Brings the playhead to the specified frame of the movie clip and stops it there. First frame is "1"
		 *
		 * @param frame A number representing the frame number, or a string representing the label of the frame, to which the playhead is sent.
		 */
		public function gotoAndStop(frame: *): void
		{
			this.checkAndSetCurrentFrame(frame);

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

			this.play();
		}

		/**
		 * Set the <code>loop</code> value to the GAFMovieClip instance and for the all children.
		 */
		public function loopAll(loop: Boolean): void
		{
			this.loop = loop;

			var i: uint = this._mcVector.length;
			while (i--)
			{
				this._mcVector[i].loop = loop;
			}
		}

		/** @private
		 * Advances all objects by a certain time (in seconds).
		 * @see starling.animation.IAnimatable
		 */
		public function advanceTime(passedTime: Number): void
		{
			if (this._disposed)
			{
				trace("WARNING: GAFMovieClip is disposed but is not removed from the Juggler");
				return;
			}
			else if (this._config.disposed)
			{
				this.dispose();
				return;
			}

			if (this._inPlay && this._frameDuration != Number.POSITIVE_INFINITY)
			{
				this._currentTime += passedTime;

				var framesToPlay: int = (this._currentTime - this._lastFrameTime) / this._frameDuration;
				if (this._skipFrames)
				{
					//here we skip the drawing of all frames to be played right now, but the last one
					for (var i: int = 0; i < framesToPlay; ++i)
					{
						if (this._inPlay)
						{
							this.changeCurrentFrame((i + 1) != framesToPlay);
						}
						else //if a playback was interrupted by some action or an event
						{
							if (!this._disposed)
							{
								this.draw();
							}
							break;
						}
					}
				}
				else if (framesToPlay > 0)
				{
					this.changeCurrentFrame(false);
				}
			}
			if (this._mcVector)
			{
				for (i = 0; i < this._mcVector.length; i++)
				{
					this._mcVector[i].advanceTime(passedTime);
				}
			}
		}

		/** Shows bounds of a whole animation with a pivot point.
		 * Used for debug purposes.
		 */
		public function showBounds(value: Boolean): void
		{
			if (this._config.bounds)
			{
				if (!this._boundsAndPivot)
				{
					this._boundsAndPivot = new MeshBatch();
					this.updateBounds(this._config.bounds);
				}

				if (value)
				{
					this.addChild(this._boundsAndPivot);
				}
				else
				{
					this.removeChild(this._boundsAndPivot);
				}
			}
		}

		/**
		 * Disposes GAFMovieClip with config and all textures that was loaded with gaf file.
		 * Do not call this method if you have another GAFMovieClips that made from the same config
		 * or even loaded from the same gaf file.
		 */
		[Deprecated(replacement="com.catalystapps.gaf.data.GAFBundle.dispose()", since="5.0")]
		public function disposeWithTextures(): void
		{
			this._gafTimeline.unloadFromVideoMemory();
			this._gafTimeline = null;
			this._config.dispose();
			this.dispose();
		}

		/** @private */
		public function setFilterConfig(value: CFilter, scale: Number = 1): void
		{
			if (!Starling.current.contextValid)
			{
				return;
			}

			if (this._filterConfig != value || this._filterScale != scale)
			{
				if (value)
				{
					this._filterConfig = value;
					this._filterScale = scale;

                    if(this._filterChain)
                    {
                        _filterChain.dispose();
                    }
					else
					{
                        _filterChain = new GAFFilterChain();
					}

                    _filterChain.setFilterData(_filterConfig);

					this.filter = _filterChain;
				}
				else
				{
					if (this.filter)
					{
						this.filter.dispose();
						this.filter = null;
					}

					this._filterChain = null;
					this._filterConfig = null;
					this._filterScale = NaN;
				}
			}
		}

		/** @private */
		public function invalidateOrientation(): void
		{
			this._orientationChanged = true;
		}

		/**
		 * Creates a new instance of GAFMovieClip.
		 */
		public function copy(): GAFMovieClip
		{
			return new GAFMovieClip(this._gafTimeline, this.fps, this._addToJuggler);
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		// --------------------------------------------------------------------------

		private function _gotoAndStop(frame: *): void
		{
			this.checkAndSetCurrentFrame(frame);

			this._stop();
		}

		private function _play(applyToAllChildren: Boolean = false, calledByUser: Boolean = false): void
		{
			if (this._inPlay && !applyToAllChildren)
			{
				return;
			}

			var i: uint, l: uint;

			if (this._totalFrames > 1)
			{
				this._inPlay = true;
			}

			if (applyToAllChildren
					&& this._config.animationConfigFrames.frames.length > 0)
			{
				var frameConfig: CAnimationFrame = this._config.animationConfigFrames.frames[this._currentFrame];
				if (frameConfig.actions)
				{
					var action: CFrameAction;
					for (i = 0, l = frameConfig.actions.length; i < l; i++)
					{
						action = frameConfig.actions[i];
						if (action.type == CFrameAction.STOP
								|| (action.type == CFrameAction.GOTO_AND_STOP
								&& int(action.params[0]) == this.currentFrame))
						{
							this._inPlay = false;
							return;
						}
					}
				}

				var child: DisplayObjectContainer;
				var childMC: GAFMovieClip;
				for (i = 0, l = this.numChildren; i < l; i++)
				{
					child = this.getChildAt(i) as DisplayObjectContainer;
					if (child is GAFMovieClip)
					{
						childMC = child as GAFMovieClip;
						if (calledByUser)
						{
							childMC.play(true);
						}
						else
						{
							childMC._play(true);
						}
					}
				}
			}

			this.runActions();

			this._reset = false;
		}

		private function _stop(applyToAllChildren: Boolean = false, calledByUser: Boolean = false): void
		{
			this._inPlay = false;

			if (applyToAllChildren
			&& this._config.animationConfigFrames.frames.length > 0)
			{
				var child: DisplayObjectContainer;
				var childMC: GAFMovieClip;
				for (var i: int = 0; i < this.numChildren; i++)
				{
					child = this.getChildAt(i) as DisplayObjectContainer;
					if (child is GAFMovieClip)
					{
						childMC = child as GAFMovieClip;
						if (calledByUser)
						{
							childMC.stop(true);
						}
						else
						{
							childMC._stop(true);
						}
					}
				}
			}
		}

		private function checkPlaybackEvents(): void
		{
			var sequence: CAnimationSequence;
			if (this.hasEventListener(EVENT_TYPE_SEQUENCE_START))
			{
				sequence = this._config.animationSequences.getSequenceStart(this._currentFrame + 1);
				if (sequence)
				{
					this.dispatchEventWith(EVENT_TYPE_SEQUENCE_START, false, sequence);
				}
			}
			if (this.hasEventListener(EVENT_TYPE_SEQUENCE_END))
			{
				sequence = this._config.animationSequences.getSequenceEnd(this._currentFrame + 1);
				if (sequence)
				{
					this.dispatchEventWith(EVENT_TYPE_SEQUENCE_END, false, sequence);
				}
			}
			if (this.hasEventListener(Event.COMPLETE))
			{
				if (this._currentFrame == this._finalFrame)
				{
					this.dispatchEventWith(Event.COMPLETE);
				}
			}
		}

		private function runActions(): void
		{
			if (!this._config.animationConfigFrames.frames.length)
			{
				return;
			}

			var i: uint, l: uint;
			var actions: Vector.<CFrameAction> = this._config.animationConfigFrames.frames[this._currentFrame].actions;
			if (actions)
			{
				var action: CFrameAction;
				for (i = 0, l = actions.length; i < l; i++)
				{
					action = actions[i];
					switch (action.type)
					{
						case CFrameAction.STOP:
							this.stop();
							break;
						case CFrameAction.PLAY:
							this.play();
							break;
						case CFrameAction.GOTO_AND_STOP:
							this.gotoAndStop(action.params[0]);
							break;
						case CFrameAction.GOTO_AND_PLAY:
							this.gotoAndPlay(action.params[0]);
							break;
						case CFrameAction.DISPATCH_EVENT:
							var actionType: String = action.params[0];
							if (this.hasEventListener(actionType))
							{
								switch (action.params.length)
								{
									case 4:
										var data: Object = action.params[3];
									case 3:
									// cancelable param is not used
									case 2:
										var bubbles: Boolean = Boolean(action.params[1]);
										break;
								}
								this.dispatchEventWith(actionType, bubbles, data);
							}
							if (actionType == CSound.GAF_PLAY_SOUND
							&& GAF.autoPlaySounds)
							{
								this._gafTimeline.startSound(this.currentFrame);
							}
							break;
					}
				}
			}
		}

		private function checkAndSetCurrentFrame(frame: *): void
		{
			if (uint(frame) > 0)
			{
				if (frame > this._totalFrames)
				{
					frame = this._totalFrames;
				}
			}
			else if (frame is String)
			{
				var label: String = frame;
				frame = this._config.animationSequences.getStartFrameNo(label);

				if (frame == 0)
				{
					throw new ArgumentError("Frame label " + label + " not found");
				}
			}
			else
			{
				frame = 1;
			}

			if (this._playingSequence && !this._playingSequence.isSequenceFrame(frame))
			{
				this._playingSequence = null;
			}

			if (this._currentFrame != frame - 1)
			{
				this._currentFrame = frame - 1;
				this.runActions();
				//actions may interrupt playback and lead to content disposition
				if (!this._disposed)
				{
					this.draw();
				}
			}
		}

		private function clearDisplayList(): void
		{
			this.removeChildren();
		}

		private function draw(): void
		{
			var i: uint;
			var l: uint;

			if (this._config.debugRegions)
			{
				// Non optimized way when there are debug regions
				this.clearDisplayList();
			}
			else
			{
				// Just hide the children to avoid dispatching a lot of events and alloc temporary arrays
				for (i = 0, l = this._displayObjectsVector.length; i < l; i++)
				{
					this._displayObjectsVector[i].alpha = 0;
				}

				for (i = 0, l = this._mcVector.length; i < l; i++)
				{
					this._mcVector[i]._hidden = true;
				}
			}

			var frames: Vector.<CAnimationFrame> = this._config.animationConfigFrames.frames;
			if (frames.length > this._currentFrame)
			{
				var mc: GAFMovieClip;
				var objectPivotMatrix: Matrix;
				var displayObject: IGAFDisplayObject;
				var instance: CAnimationFrameInstance;
				var stencilMaskObject: DisplayObject;

				var animationObjectsDictionary: Object = this._config.animationObjects.animationObjectsDictionary;
				var frameConfig: CAnimationFrame = frames[this._currentFrame];
				var instances: Vector.<CAnimationFrameInstance> = frameConfig.instances;
				l = instances.length;
				i = 0;
				while (i < l)
				{
					instance = instances[i++];

					displayObject = this._displayObjectsDictionary[instance.id];
					if (displayObject)
					{
						objectPivotMatrix = getTransformMatrix(displayObject, HELPER_MATRIX);
						mc = displayObject as GAFMovieClip;
						if (mc)
						{
							if (instance.alpha < 0)
							{
								mc.reset();
							}
							else if (mc._reset && mc._started)
							{
								mc._play(true);
							}
							mc._hidden = false;
						}

						if (instance.alpha <= 0)
						{
							continue;
						}

						displayObject.alpha = instance.alpha;

						//if display object is not a mask
						if (!animationObjectsDictionary[instance.id].mask)
						{
							//if display object is under mask
							if (instance.maskID)
							{
								this.renderDebug(mc, instance, true);

                                stencilMaskObject = this._stencilMasksDictionary[instance.maskID];

								if (stencilMaskObject)
								{
                                    _stencilMaskStyle = new GAFStencilMaskStyle();
									(stencilMaskObject as GAFImage).style = _stencilMaskStyle;

									instance.applyTransformMatrix(displayObject.transformationMatrix, objectPivotMatrix, this._scale);
									displayObject.invalidateOrientation();

                                    (displayObject as DisplayObject).mask = stencilMaskObject;

									this.addChild(stencilMaskObject);
									this.addChild((displayObject as DisplayObject));

                                    _stencilMaskStyle.threshold = 1;
								}
							}
							else //if display object is not masked
							{
								this.renderDebug(mc, instance, this._masked);

								instance.applyTransformMatrix(displayObject.transformationMatrix, objectPivotMatrix, this._scale);
								displayObject.invalidateOrientation();
								displayObject.setFilterConfig(instance.filter, this._scale);

								this.addChild(displayObject as DisplayObject);
							}

							if (mc && mc._started)
							{
								mc._play(true);
							}

							if (DebugUtility.RENDERING_DEBUG && displayObject is IGAFDebug)
							{
								var colors: Vector.<uint> = DebugUtility.getRenderingDifficultyColor(
										instance, this._alphaLessMax, this._masked, this._hasFilter);
								(displayObject as IGAFDebug).debugColors = colors;
							}
						}
						else
						{
							var maskObject: IGAFDisplayObject = this._displayObjectsDictionary[instance.id];
							if (maskObject)
							{
								var maskInstance: CAnimationFrameInstance = frameConfig.getInstanceByID(instance.id);
								if (maskInstance)
								{
									getTransformMatrix(maskObject, HELPER_MATRIX);
									maskInstance.applyTransformMatrix(maskObject.transformationMatrix, HELPER_MATRIX, this._scale);
									maskObject.invalidateOrientation();
								}
								else
								{
									throw new Error("Unable to find mask with ID " + instance.id);
								}

								mc = maskObject as GAFMovieClip;
								if (mc && mc._started)
								{
									mc._play(true);
								}
							}
						}
					}
				}
			}

			if (this._config.debugRegions)
			{
				this.addDebugRegions();
			}

			this.checkPlaybackEvents();
		}

		private function renderDebug(mc: GAFMovieClip, instance: CAnimationFrameInstance, masked: Boolean): void
		{
			if (DebugUtility.RENDERING_DEBUG && mc)
			{
				var hasFilter: Boolean = (instance.filter != null) || this._hasFilter;
				var alphaLessMax: Boolean = instance.alpha < GAF.gaf_internal::maxAlpha || this._alphaLessMax;

				var changed: Boolean;
				if (mc._alphaLessMax != alphaLessMax)
				{
					mc._alphaLessMax = alphaLessMax;
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
		}

		private function addDebugRegions(): void
		{
			var debugView: Quad;
			for each (var debugRegion: GAFDebugInformation in this._config.debugRegions)
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

				this.addChild(debugView);
			}
		}

		private function reset(): void
		{
			this._gotoAndStop((this._reverse ? this._finalFrame : this._startFrame) + 1);
			this._reset = true;
			this._currentTime = 0;
			this._lastFrameTime = 0;

			var i: uint = this._mcVector.length;
			while (i--)
			{
				this._mcVector[i].reset();
			}
		}

		private function initialize(textureAtlas: CTextureAtlas, gafAsset: GAFAsset): void
		{
			this._displayObjectsDictionary = {};
			this._stencilMasksDictionary = {};
			this._displayObjectsVector = new <IGAFDisplayObject>[];
			this._imagesVector = new <IGAFImage>[];
			this._mcVector = new <GAFMovieClip>[];

			this._currentFrame = 0;
			this._totalFrames = this._config.framesCount;
			this.fps = this._config.stageConfig ? this._config.stageConfig.fps : Starling.current.nativeStage.frameRate;

			var animationObjectsDictionary: Object = this._config.animationObjects.animationObjectsDictionary;

			var displayObject: DisplayObject;
			for each (var animationObjectConfig: CAnimationObject in animationObjectsDictionary)
			{
				switch (animationObjectConfig.type)
				{
					case CAnimationObject.TYPE_TEXTURE:
						var texture: IGAFTexture = textureAtlas.getTexture(animationObjectConfig.regionID);
						if (texture is GAFScale9Texture && !animationObjectConfig.mask) // GAFScale9Image doesn't work as mask
						{
							displayObject = new GAFScale9Image(texture as GAFScale9Texture);
						}
						else
						{
							displayObject = new GAFImage(texture);
							(displayObject as GAFImage).textureSmoothing = this._smoothing;
						}
						break;
					case CAnimationObject.TYPE_TEXTFIELD:
						var tfObj: CTextFieldObject = this._config.textFields.textFieldObjectsDictionary[animationObjectConfig.regionID];
						displayObject = new GAFTextField(tfObj, this._scale, this._contentScaleFactor);
						break;
					case CAnimationObject.TYPE_TIMELINE:
						var timeline: GAFTimeline = gafAsset.gaf_internal::getGAFTimelineByID(animationObjectConfig.regionID);
						displayObject = new GAFMovieClip(timeline, this.fps, false);
						break;
				}

				if (animationObjectConfig.maxSize && displayObject is IMaxSize)
				{
					var maxSize: Point = new Point(
							animationObjectConfig.maxSize.x * this._scale,
							animationObjectConfig.maxSize.y * this._scale);
					(displayObject as IMaxSize).maxSize = maxSize;
				}

				this.addDisplayObject(animationObjectConfig.instanceID, displayObject);
				if (animationObjectConfig.mask)
				{
					this.addDisplayObject(animationObjectConfig.instanceID, displayObject, true);
				}

				if (this._config.namedParts != null)
				{
					var instanceName: String = this._config.namedParts[animationObjectConfig.instanceID];
					if (instanceName != null && !this.hasOwnProperty(instanceName))
					{
						this[this._config.namedParts[animationObjectConfig.instanceID]] = displayObject;
						displayObject.name = instanceName;
					}
				}
			}

			if (this._addToJuggler)
			{
				Starling.juggler.add(this);
			}
		}

		private function addDisplayObject(id: String, displayObject: DisplayObject, asMask:Boolean = false): void
		{
			if (asMask)
			{
				this._stencilMasksDictionary[id] = displayObject;
			}
			else
			{
				this._displayObjectsDictionary[id] = displayObject;
				this._displayObjectsVector[_displayObjectsVector.length] = displayObject as IGAFDisplayObject;
				if (displayObject is IGAFImage)
				{
					this._imagesVector[_imagesVector.length] = displayObject as IGAFImage;
				}
				else if (displayObject is GAFMovieClip)
				{
					this._mcVector[_mcVector.length] = displayObject as GAFMovieClip;
				}
			}
		}

		private function updateBounds(bounds: Rectangle): void
		{
			this._boundsAndPivot.clear();
			//bounds
			if (bounds.width > 0 &&  bounds.height > 0)
			{
				var quad: Quad = new Quad(bounds.width * this._scale, 2, 0xff0000);
				quad.x = bounds.x * this._scale;
				quad.y = bounds.y * this._scale;
				this._boundsAndPivot.addMesh(quad);
				quad = new Quad(bounds.width * this._scale, 2, 0xff0000);
				quad.x = bounds.x * this._scale;
				quad.y = bounds.bottom * this._scale - 2;
				this._boundsAndPivot.addMesh(quad);
				quad = new Quad(2, bounds.height * this._scale, 0xff0000);
				quad.x = bounds.x * this._scale;
				quad.y = bounds.y * this._scale;
				this._boundsAndPivot.addMesh(quad);
				quad = new Quad(2, bounds.height * this._scale, 0xff0000);
				quad.x = bounds.right * this._scale - 2;
				quad.y = bounds.y * this._scale;
				this._boundsAndPivot.addMesh(quad);
			}
			//pivot point
			quad = new Quad(5, 5, 0xff0000);
			this._boundsAndPivot.addMesh(quad);
		}

		/** @private */
		gaf_internal function __debugHighlight(): void
		{
			use namespace gaf_internal;

			if (isNaN(this.__debugOriginalAlpha))
			{
				this.__debugOriginalAlpha = this.alpha;
			}
			this.alpha = 1;
		}

		/** @private */
		gaf_internal function __debugLowlight(): void
		{
			use namespace gaf_internal;

			if (isNaN(this.__debugOriginalAlpha))
			{
				this.__debugOriginalAlpha = this.alpha;
			}
			this.alpha = .05;
		}

		/** @private */
		gaf_internal function __debugResetLight(): void
		{
			use namespace gaf_internal;

			if (!isNaN(this.__debugOriginalAlpha))
			{
				this.alpha = this.__debugOriginalAlpha;
				this.__debugOriginalAlpha = NaN;
			}
		}

		[Inline]
		private final function updateTransformMatrix(): void
		{
			if (this._orientationChanged)
			{
				this.transformationMatrix = this.transformationMatrix;
				this._orientationChanged = false;
			}
		}

		//--------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		//--------------------------------------------------------------------------

		/** Removes a child at a certain index. The index positions of any display objects above
         *  the child are decreased by 1. If requested, the child will be disposed right away. */
		override public function removeChildAt(index:int, dispose:Boolean=false): DisplayObject
		{
			if (dispose)
			{
				var key: String;
				var instanceName: String;
				var child: DisplayObject = this.getChildAt(index);
				if (child is IGAFDisplayObject)
				{
					var id: int = this._mcVector.indexOf(child as GAFMovieClip);
					if (id >= 0)
					{
						this._mcVector.splice(id, 1);
					}
					id = this._imagesVector.indexOf(child as IGAFImage);
					if (id >= 0)
					{
						this._imagesVector.splice(id, 1);
					}
					id = this._displayObjectsVector.indexOf(child as IGAFDisplayObject);
					if (id >= 0)
					{
						this._displayObjectsVector.splice(id, 1);

						for (key in this._displayObjectsDictionary)
						{
							if (this._displayObjectsDictionary[key] == child)
							{
								if (this._config.namedParts != null)
								{
									instanceName = this._config.namedParts[key];
									if (instanceName && this.hasOwnProperty(instanceName))
									{
										delete this[instanceName];
									}
								}

								delete this._displayObjectsDictionary[key];
								break;
							}
						}
					}

					for (key in this._stencilMasksDictionary)
					{
						if (this._stencilMasksDictionary[key] == child)
						{
							if (this._config.namedParts != null)
							{
								instanceName = this._config.namedParts[key];
								if (instanceName && this.hasOwnProperty(instanceName))
								{
									delete this[instanceName];
								}
							}

							delete this._stencilMasksDictionary[key];
							break;
						}
					}
				}
			}

			return super.removeChildAt(index, dispose);
		}

		/** Returns a child object with a certain name (non-recursively). */
		override public function getChildByName(name: String): DisplayObject
		{
			var numChildren: int = this._displayObjectsVector.length;
			for (var i: int = 0; i < numChildren; ++i)
				if (this._displayObjectsVector[i].name == name)
					return this._displayObjectsVector[i] as DisplayObject;

			return super.getChildByName(name);
		}

		/**
		 * Disposes all resources of the display object instance. Note: this method won't delete used texture atlases from GPU memory.
		 * To delete texture atlases from GPU memory use <code>unloadFromVideoMemory()</code> method for <code>GAFTimeline</code> instance
		 * from what <code>GAFMovieClip</code> was instantiated.
		 * Call this method every time before delete no longer required instance! Otherwise GPU memory leak may occur!
		 */
		override public function dispose(): void
		{
			if (this._disposed)
			{
				return;
			}
			this.stop();

			if (this._addToJuggler)
			{
				Starling.juggler.remove(this);
			}

			var i: uint, l: uint;
			for (i = 0, l = this._displayObjectsVector.length; i < l; i++)
			{
				this._displayObjectsVector[i].dispose();
			}

            for (var key:String in this._stencilMasksDictionary)
            {
                this._stencilMasksDictionary[key].dispose();
            }

			if (this._boundsAndPivot)
			{
				this._boundsAndPivot.dispose();
				this._boundsAndPivot = null;
			}

			this._displayObjectsDictionary = null;
			this._stencilMasksDictionary = null;
			this._displayObjectsVector = null;
			this._imagesVector = null;
			this._gafTimeline = null;
			this._mcVector = null;
			this._config = null;

			if (this.parent)
			{
				this.removeFromParent();
			}
			super.dispose();

			this._disposed = true;
		}

		/** @private */
		override public function render(painter:Painter): void
		{
			try
			{
				super.render(painter);
			}
			catch (error: Error)
			{
				if (error is IllegalOperationError
						&& (error.message as String).indexOf("not possible to stack filters") != -1)
				{
					if (this.hasEventListener(ErrorEvent.ERROR))
					{
						this.dispatchEventWith(ErrorEvent.ERROR, true, error.message);
					}
					else
					{
						throw error;
					}
				}
				else
				{
					throw error;
				}
			}
		}

		/** @private */
		override public function set pivotX(value: Number): void
		{
			this._pivotChanged = true;
			super.pivotX = value;
		}

		/** @private */
		override public function set pivotY(value: Number): void
		{
			this._pivotChanged = true;
			super.pivotY = value;
		}

		/** @private */
		override public function get x(): Number
		{
			updateTransformMatrix();
			return super.x;
		}

		/** @private */
		override public function get y(): Number
		{
			updateTransformMatrix();
			return super.y;
		}

		/** @private */
		override public function get rotation(): Number
		{
			updateTransformMatrix();
			return super.rotation;
		}

		/** @private */
		override public function get scaleX(): Number
		{
			updateTransformMatrix();
			return super.scaleX;
		}

		/** @private */
		override public function get scaleY(): Number
		{
			updateTransformMatrix();
			return super.scaleY;
		}

		/** @private */
		override public function get skewX(): Number
		{
			updateTransformMatrix();
			return super.skewX;
		}

		/** @private */
		override public function get skewY(): Number
		{
			updateTransformMatrix();
			return super.skewY;
		}

		//--------------------------------------------------------------------------
		//
		//  EVENT HANDLERS
		//
		//--------------------------------------------------------------------------

		private function changeCurrentFrame(isSkipping: Boolean): void
		{
			this._nextFrame = this._currentFrame + (this._reverse ? -1 : 1);
			this._startFrame = (this._playingSequence ? this._playingSequence.startFrameNo : 1) - 1;
			this._finalFrame = (this._playingSequence ? this._playingSequence.endFrameNo : this._totalFrames) - 1;

			if (this._nextFrame >= this._startFrame && this._nextFrame <= this._finalFrame)
			{
				this._currentFrame = this._nextFrame;
				this._lastFrameTime += this._frameDuration;
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
					this._lastFrameTime += this._frameDuration;
					var resetInvisibleChildren: Boolean = true;
				}
			}

			this.runActions();

			//actions may interrupt playback and lead to content disposition
			if (this._disposed)
			{
				return;
			}
			else if (this._config.disposed)
			{
				this.dispose();
				return;
			}

			if (!isSkipping)
			{
				// Draw will trigger events if any
				this.draw();
			}
			else
			{
				this.checkPlaybackEvents();
			}

			if (resetInvisibleChildren)
			{
				//reset timelines that aren't visible
				var i: uint = this._mcVector.length;
				while (i--)
				{
					if (this._mcVector[i]._hidden)
					{
						this._mcVector[i].reset();
					}
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

				var i: uint = this._imagesVector.length;
				while (i--)
				{
					this._imagesVector[i].textureSmoothing = this._smoothing;
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

		/** @private */
		public function get maxSize(): Point
		{
			return this._maxSize;
		}

		/** @private */
		public function set maxSize(value: Point): void
		{
			this._maxSize = value;
		}

		/**
		 * if set <code>true</code> - <code>GAFMivieclip</code> will be clipped with flash stage dimensions
		 */
		public function set useClipping(value: Boolean): void
		{
			this._useClipping = value;

			if (this._useClipping && this._config.stageConfig)
			{
				this.mask = new Quad(this._config.stageConfig.width * this._scale, this._config.stageConfig.height * this._scale);
			}
			else
			{
				this.mask = null;
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

			var i: uint = this._mcVector.length;
			while (i--)
			{
				this._mcVector[i].fps = value;
			}
		}

		public function get reverse(): Boolean
		{
			return this._reverse;
		}

		/**
		 * If <code>true</code> animation will be playing in reverse mode
		 */
		public function set reverse(value: Boolean): void
		{
			this._reverse = value;

			var i: uint = this._mcVector.length;
			while (i--)
			{
				this._mcVector[i]._reverse = value;
			}
		}

		public function get skipFrames(): Boolean
		{
			return this._skipFrames;
		}

		/**
		 * Indicates whether GAFMovieClip instance should skip frames when application fps drops down or play every frame not depending on application fps.
		 * Value false will force GAFMovieClip to play each frame not depending on application fps (the same behavior as in regular Flash Movie Clip).
		 * Value true will force GAFMovieClip to play animation "in time". And when application fps drops down it will start skipping frames (default behavior).
		 */
		public function set skipFrames(value: Boolean): void
		{
			this._skipFrames = value;

			var i: uint = this._mcVector.length;
			while (i--)
			{
				this._mcVector[i]._skipFrames = value;
			}
		}

		/** @private */
		public function get pivotMatrix(): Matrix
		{
			//HELPER_MATRIX.copyFrom(this._pivotMatrix);
			HELPER_MATRIX.identity();

			if (this._pivotChanged)
			{
				HELPER_MATRIX.tx = this.pivotX;
				HELPER_MATRIX.ty = this.pivotY;
			}

			return HELPER_MATRIX;
		}

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------

		[Inline]
		private static function getTransformMatrix(displayObject: IGAFDisplayObject, matrix: Matrix): Matrix
		{
			matrix.copyFrom(displayObject.pivotMatrix);

			return matrix;
		}
	}
}
