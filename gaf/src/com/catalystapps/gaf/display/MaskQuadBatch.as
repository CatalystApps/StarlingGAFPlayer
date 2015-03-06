/**
 * Created by Nazar on 27.02.2015.
 */
package com.catalystapps.gaf.display
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.errors.IllegalOperationError;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;

	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.core.starling_internal;
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.QuadBatch;
	import starling.display.Sprite;
	import starling.display.Sprite3D;
	import starling.errors.MissingContextError;
	import starling.events.Event;
	import starling.filters.FragmentFilter;
	import starling.filters.FragmentFilterMode;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	import starling.utils.VertexData;

	use namespace starling_internal;

	public class MaskQuadBatch extends QuadBatch
	{
		/** The maximum number of quads that can be displayed by one QuadBatch. */
		public static const MAX_NUM_QUADS: int = 16383;

		private static const QUAD_PROGRAM_NAME: String = "MQB_q";

		private var mNumQuads: int;
		private var mSyncRequired: Boolean;
		private var mBatchable: Boolean;

		private var mTinted: Boolean;
		private var mTexture: Texture;
		private var mSmoothing: String;

		private var mVertexBuffer: VertexBuffer3D;
		private var mIndexData: Vector.<uint>;
		private var mIndexBuffer: IndexBuffer3D;

		/** Helper objects. */
		private static var sHelperMatrix: Matrix = new Matrix();
		private static var sRenderAlpha: Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];
		private static var sCalcConstants: Vector.<Number> = new <Number>[0.0, 0.5, 1.0, 2.0];
		private static var sProgramNameCache: Dictionary = new Dictionary();

		public function MaskQuadBatch()
		{
			mIndexData = new <uint>[];
			mNumQuads = 0;
			mTinted = false;
			mSyncRequired = false;
			mBatchable = false;

			super();

			// Handle lost context. We use the conventional event here (not the one from Starling)
			// so we're able to create a weak event listener; this avoids memory leaks when people
			// forget to call "dispose" on the QuadBatch.
			Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE,
					onContextCreated, false, 0, true);
		}

		/** Disposes vertex- and index-buffer. */
		public override function dispose(): void
		{
			Starling.current.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			destroyBuffers();

			mVertexData.numVertices = 0;
			mIndexData.length = 0;
			mNumQuads = 0;

			super.dispose();
		}

		private function onContextCreated(event: Object): void
		{
			createBuffers();
		}

		/** Call this method after manually changing the contents of 'mVertexData'. */
		override protected function onVertexDataChanged(): void
		{
			mSyncRequired = true;
		}

		/** Creates a duplicate of the QuadBatch object. */
		override public function clone(): QuadBatch
		{
			var clone: MaskQuadBatch = new MaskQuadBatch();
			clone.mVertexData = mVertexData.clone(0, mNumQuads * 4);
			clone.mIndexData = mIndexData.slice(0, mNumQuads * 6);
			clone.mNumQuads = mNumQuads;
			clone.mTinted = mTinted;
			clone.mTexture = mTexture;
			clone.mSmoothing = mSmoothing;
			clone.mSyncRequired = true;
			clone.blendMode = blendMode;
			clone.alpha = alpha;
			return clone;
		}

		private function expand(): void
		{
			var oldCapacity: int = this.capacity;

			if (oldCapacity >= MAX_NUM_QUADS)
			{
				throw new Error("Exceeded maximum number of quads!");
			}

			this.capacity = oldCapacity < 8 ? 16 : oldCapacity * 2;
		}

		private function createBuffers(): void
		{
			destroyBuffers();

			var numVertices: int = mVertexData.numVertices;
			var numIndices: int = mIndexData.length;
			var context: Context3D = Starling.context;

			if (numVertices == 0)
			{
				return;
			}
			if (context == null)
			{
				throw new MissingContextError();
			}

			mVertexBuffer = context.createVertexBuffer(numVertices, VertexData.ELEMENTS_PER_VERTEX);
			mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, numVertices);

			mIndexBuffer = context.createIndexBuffer(numIndices);
			mIndexBuffer.uploadFromVector(mIndexData, 0, numIndices);

			mSyncRequired = false;
		}

		private function destroyBuffers(): void
		{
			if (mVertexBuffer)
			{
				mVertexBuffer.dispose();
				mVertexBuffer = null;
			}

			if (mIndexBuffer)
			{
				mIndexBuffer.dispose();
				mIndexBuffer = null;
			}
		}

		/** Uploads the raw data of all batched quads to the vertex buffer. */
		private function syncBuffers(): void
		{
			if (mVertexBuffer == null)
			{
				createBuffers();
			}
			else
			{
				// as last parameter, we could also use 'mNumQuads * 4', but on some
				// GPU hardware (iOS!), this is slower than updating the complete buffer.
				mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, mVertexData.numVertices);
				mSyncRequired = false;
			}
		}

		/** Renders the current batch with custom settings for model-view-projection matrix, alpha
		 *  and blend mode. This makes it possible to render batches that are not part of the
		 *  display list. */
		override public function renderCustom(mvpMatrix: Matrix3D, parentAlpha: Number = 1.0,
											  blendMode: String = null): void
		{
			if (mNumQuads == 0)
			{
				return;
			}
			if (mSyncRequired)
			{
				syncBuffers();
			}

			var pma: Boolean = mVertexData.premultipliedAlpha;
			var context: Context3D = Starling.context;
			var tinted: Boolean = mTinted || (parentAlpha != 1.0);

			sRenderAlpha[0] = sRenderAlpha[1] = sRenderAlpha[2] = pma ? parentAlpha : 1.0;
			sRenderAlpha[3] = parentAlpha;

			RenderSupport.setBlendFactors(pma, blendMode ? blendMode : this.blendMode);

			context.setProgram(getProgram(tinted));
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, sRenderAlpha, 1);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, mvpMatrix, true);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, sCalcConstants, 1);
			context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET,
					Context3DVertexBufferFormat.FLOAT_2);

			if (mTexture == null || tinted)
			{
				context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET,
						Context3DVertexBufferFormat.FLOAT_4);
			}

			if (mTexture)
			{
				context.setTextureAt(0, mTexture.base);
				context.setVertexBufferAt(2, mVertexBuffer, VertexData.TEXCOORD_OFFSET,
						Context3DVertexBufferFormat.FLOAT_2);
			}

			context.drawTriangles(mIndexBuffer, 0, mNumQuads * 2);

			if (mTexture)
			{
				context.setTextureAt(0, null);
				context.setVertexBufferAt(2, null);
			}

			context.setVertexBufferAt(1, null);
			context.setVertexBufferAt(0, null);
		}

		/** Resets the batch. The vertex- and index-buffers remain their size, so that they
		 *  can be reused quickly. */
		override public function reset(): void
		{
			mNumQuads = 0;
			mTexture = null;
			mSmoothing = null;
			mSyncRequired = true;
		}

		/** Adds an image to the batch. This method internally calls 'addQuad' with the correct
		 *  parameters for 'texture' and 'smoothing'. */
		override public function addImage(image: Image, parentAlpha: Number = 1.0, modelViewMatrix: Matrix = null,
										  blendMode: String = null): void
		{
			addQuad(image, parentAlpha, image.texture, image.smoothing, modelViewMatrix, blendMode);
		}

		/** Adds a quad to the batch. The first quad determines the state of the batch,
		 *  i.e. the values for texture, smoothing and blendmode. When you add additional quads,
		 *  make sure they share that state (e.g. with the 'isStateChange' method), or reset
		 *  the batch. */
		override public function addQuad(quad: Quad, parentAlpha: Number = 1.0, texture: Texture = null,
										 smoothing: String = null, modelViewMatrix: Matrix = null,
										 blendMode: String = null): void
		{
			if (modelViewMatrix == null)
			{
				modelViewMatrix = quad.transformationMatrix;
			}

			var alpha: Number = parentAlpha * quad.alpha;
			var vertexID: int = mNumQuads * 4;

			if (mNumQuads + 1 > mVertexData.numVertices / 4)
			{
				expand();
			}
			if (mNumQuads == 0)
			{
				this.blendMode = blendMode ? blendMode : quad.blendMode;
				mTexture = texture;
				mTinted = texture ? (quad.tinted || parentAlpha != 1.0) : false;
				mSmoothing = smoothing;
				mVertexData.setPremultipliedAlpha(quad.premultipliedAlpha);
			}

			quad.copyVertexDataTransformedTo(mVertexData, vertexID, modelViewMatrix);

			if (alpha != 1.0)
			{
				mVertexData.scaleAlpha(vertexID, alpha, 4);
			}

			mSyncRequired = true;
			mNumQuads++;
		}

		/** Adds another QuadBatch to this batch. Just like the 'addQuad' method, you have to
		 *  make sure that you only add batches with an equal state. */
		override public function addQuadBatch(quadBatch: QuadBatch, parentAlpha: Number = 1.0,
											  modelViewMatrix: Matrix = null, blendMode: String = null): void
		{
			var maskQuadBatch: MaskQuadBatch = quadBatch as MaskQuadBatch;
			if (modelViewMatrix == null)
			{
				modelViewMatrix = maskQuadBatch.transformationMatrix;
			}

			var tinted: Boolean = maskQuadBatch.mTinted || parentAlpha != 1.0;
			var alpha: Number = parentAlpha * maskQuadBatch.alpha;
			var vertexID: int = mNumQuads * 4;
			var numQuads: int = maskQuadBatch.numQuads;

			if (mNumQuads + numQuads > capacity)
			{
				capacity = mNumQuads + numQuads;
			}
			if (mNumQuads == 0)
			{
				this.blendMode = blendMode ? blendMode : maskQuadBatch.blendMode;
				mTexture = maskQuadBatch.mTexture;
				mTinted = tinted;
				mSmoothing = maskQuadBatch.mSmoothing;
				mVertexData.setPremultipliedAlpha(maskQuadBatch.mVertexData.premultipliedAlpha, false);
			}

			maskQuadBatch.mVertexData.copyTransformedTo(mVertexData, vertexID, modelViewMatrix,
					0, numQuads * 4);

			if (alpha != 1.0)
			{
				mVertexData.scaleAlpha(vertexID, alpha, numQuads * 4);
			}

			mSyncRequired = true;
			mNumQuads += numQuads;
		}

		/** Indicates if specific quads can be added to the batch without causing a state change.
		 *  A state change occurs if the quad uses a different base texture, has a different
		 *  'tinted', 'smoothing', 'repeat' or 'blendMode' setting, or if the batch is full
		 *  (one batch can contain up to 8192 quads). */
		override public function isStateChange(tinted: Boolean, parentAlpha: Number, texture: Texture,
											   smoothing: String, blendMode: String, numQuads: int = 1): Boolean
		{
			if (mNumQuads == 0)
			{
				return false;
			}
			else if (mNumQuads + numQuads > MAX_NUM_QUADS)
			{
				return true;
			}// maximum buffer size
			else if (mTexture == null && texture == null)
			{
				return this.blendMode != blendMode;
			}
			else if (mTexture != null && texture != null)
			{
				return mTexture.base != texture.base ||
						mTexture.repeat != texture.repeat ||
						mSmoothing != smoothing ||
						mTinted != (tinted || parentAlpha != 1.0) ||
						this.blendMode != blendMode;
			}
			else
			{
				return true;
			}
		}

		// utility methods for manual vertex-modification

		/** Transforms the vertices of a certain quad by the given matrix. */
		override public function transformQuad(quadID: int, matrix: Matrix): void
		{
			mVertexData.transformVertex(quadID * 4, matrix, 4);
			mSyncRequired = true;
		}

		/** Returns the color of one vertex of a specific quad. */
		override public function getVertexColor(quadID: int, vertexID: int): uint
		{
			return mVertexData.getColor(quadID * 4 + vertexID);
		}

		/** Updates the color of one vertex of a specific quad. */
		override public function setVertexColor(quadID: int, vertexID: int, color: uint): void
		{
			mVertexData.setColor(quadID * 4 + vertexID, color);
			mSyncRequired = true;
		}

		/** Returns the alpha value of one vertex of a specific quad. */
		override public function getVertexAlpha(quadID: int, vertexID: int): Number
		{
			return mVertexData.getAlpha(quadID * 4 + vertexID);
		}

		/** Updates the alpha value of one vertex of a specific quad. */
		override public function setVertexAlpha(quadID: int, vertexID: int, alpha: Number): void
		{
			mVertexData.setAlpha(quadID * 4 + vertexID, alpha);
			mSyncRequired = true;
		}

		/** Returns the color of the first vertex of a specific quad. */
		override public function getQuadColor(quadID: int): uint
		{
			return mVertexData.getColor(quadID * 4);
		}

		/** Updates the color of a specific quad. */
		override public function setQuadColor(quadID: int, color: uint): void
		{
			for (var i: int = 0; i < 4; ++i)
			{
				mVertexData.setColor(quadID * 4 + i, color);
			}

			mSyncRequired = true;
		}

		/** Returns the alpha value of the first vertex of a specific quad. */
		override public function getQuadAlpha(quadID: int): Number
		{
			return mVertexData.getAlpha(quadID * 4);
		}

		/** Updates the alpha value of a specific quad. */
		override public function setQuadAlpha(quadID: int, alpha: Number): void
		{
			for (var i: int = 0; i < 4; ++i)
			{
				mVertexData.setAlpha(quadID * 4 + i, alpha);
			}

			mSyncRequired = true;
		}

		/** Replaces a quad or image at a certain index with another one. */
		override public function setQuad(quadID: Number, quad: Quad): void
		{
			var matrix: Matrix = quad.transformationMatrix;
			var alpha: Number = quad.alpha;
			var vertexID: int = quadID * 4;

			quad.copyVertexDataTransformedTo(mVertexData, vertexID, matrix);
			if (alpha != 1.0)
			{
				mVertexData.scaleAlpha(vertexID, alpha, 4);
			}

			mSyncRequired = true;
		}

		/** Calculates the bounds of a specific quad, optionally transformed by a matrix.
		 *  If you pass a 'resultRect', the result will be stored in this rectangle
		 *  instead of creating a new object. */
		override public function getQuadBounds(quadID: int, transformationMatrix: Matrix = null,
											   resultRect: Rectangle = null): Rectangle
		{
			return mVertexData.getBounds(transformationMatrix, quadID * 4, 4, resultRect);
		}

		// display object methods

		/** @inheritDoc */
		public override function getBounds(targetSpace: DisplayObject, resultRect: Rectangle = null): Rectangle
		{
			if (resultRect == null)
			{
				resultRect = new Rectangle();
			}

			var transformationMatrix: Matrix = targetSpace == this ?
					null : getTransformationMatrix(targetSpace, sHelperMatrix);

			return mVertexData.getBounds(transformationMatrix, 0, mNumQuads * 4, resultRect);
		}

		/** @inheritDoc */
		public override function render(support: RenderSupport, parentAlpha: Number): void
		{
			if (mNumQuads)
			{
				if (mBatchable)
				{
					support.batchQuadBatch(this, parentAlpha);
				}
				else
				{
					support.finishQuadBatch();
					support.raiseDrawCount();
					renderCustom(support.mvpMatrix3D, alpha * parentAlpha, support.blendMode);
				}
			}
		}

		// compilation (for flattened sprites)

		/** Analyses an object that is made up exclusively of quads (or other containers)
		 *  and creates a vector of QuadBatch objects representing it. This can be
		 *  used to render the container very efficiently. The 'flatten'-method of the Sprite
		 *  class uses this method internally. */
		public static function compile(object: DisplayObject,
									   quadBatches: Vector.<QuadBatch>): void
		{
			compileObject(object, quadBatches, -1, new Matrix());
		}

		/** Naively optimizes a list of batches by merging all that have an identical state.
		 *  Naturally, this will change the z-order of some of the batches, so this method is
		 *  useful only for specific use-cases. */
		public static function optimize(quadBatches: Vector.<QuadBatch>): void
		{
			var batch1: QuadBatch, batch2: QuadBatch;
			for (var i: int = 0; i < quadBatches.length; ++i)
			{
				batch1 = quadBatches[i];
				for (var j: int = i + 1; j < quadBatches.length;)
				{
					batch2 = quadBatches[j];
					if (!batch1.isStateChange(batch2.tinted, 1.0, batch2.texture,
									batch2.smoothing, batch2.blendMode))
					{
						batch1.addQuadBatch(batch2);
						batch2.dispose();
						quadBatches.splice(j, 1);
					}
					else
					{
						++j;
					}
				}
			}
		}

		private static function compileObject(object: DisplayObject,
											  quadBatches: Vector.<QuadBatch>,
											  quadBatchID: int,
											  transformationMatrix: Matrix,
											  alpha: Number = 1.0,
											  blendMode: String = null,
											  ignoreCurrentFilter: Boolean = false): int
		{
			if (object is Sprite3D)
			{
				throw new IllegalOperationError("Sprite3D objects cannot be flattened");
			}

			var i: int;
			var quadBatch: QuadBatch;
			var isRootObject: Boolean = false;
			var objectAlpha: Number = object.alpha;

			var container: DisplayObjectContainer = object as DisplayObjectContainer;
			var quad: Quad = object as Quad;
			var batch: MaskQuadBatch = object as MaskQuadBatch;
			var filter: FragmentFilter = object.filter;

			if (quadBatchID == -1)
			{
				isRootObject = true;
				quadBatchID = 0;
				objectAlpha = 1.0;
				blendMode = object.blendMode;
				ignoreCurrentFilter = true;
				if (quadBatches.length == 0)
				{
					quadBatches.push(new QuadBatch());
				}
				else
				{
					quadBatches[0].reset();
				}
			}
			else
			{
				if (object.mask)
				{
					trace("[Starling] Masks are ignored on children of a flattened sprite.");
				}

				if ((object is Sprite) && (object as Sprite).clipRect)
				{
					trace("[Starling] ClipRects are ignored on children of a flattened sprite.");
				}
			}

			if (filter && !ignoreCurrentFilter)
			{
				if (filter.mode == FragmentFilterMode.ABOVE)
				{
					quadBatchID = compileObject(object, quadBatches, quadBatchID,
							transformationMatrix, alpha, blendMode, true);
				}

				quadBatchID = compileObject(filter.compile(object), quadBatches, quadBatchID,
						transformationMatrix, alpha, blendMode);

				if (filter.mode == FragmentFilterMode.BELOW)
				{
					quadBatchID = compileObject(object, quadBatches, quadBatchID,
							transformationMatrix, alpha, blendMode, true);
				}
			}
			else if (container)
			{
				var numChildren: int = container.numChildren;
				var childMatrix: Matrix = new Matrix();

				for (i = 0; i < numChildren; ++i)
				{
					var child: DisplayObject = container.getChildAt(i);
					if (child.hasVisibleArea)
					{
						var childBlendMode: String = child.blendMode == BlendMode.AUTO ?
								blendMode : child.blendMode;
						childMatrix.copyFrom(transformationMatrix);
						RenderSupport.transformMatrixForObject(childMatrix, child);
						quadBatchID = compileObject(child, quadBatches, quadBatchID, childMatrix,
								alpha * objectAlpha, childBlendMode);
					}
				}
			}
			else if (quad || batch)
			{
				var texture: Texture;
				var smoothing: String;
				var tinted: Boolean;
				var numQuads: int;

				if (quad)
				{
					var image: Image = quad as Image;
					texture = image ? image.texture : null;
					smoothing = image ? image.smoothing : null;
					tinted = quad.tinted;
					numQuads = 1;
				}
				else
				{
					texture = batch.mTexture;
					smoothing = batch.mSmoothing;
					tinted = batch.mTinted;
					numQuads = batch.mNumQuads;
				}

				quadBatch = quadBatches[quadBatchID];

				if (quadBatch.isStateChange(tinted, alpha * objectAlpha, texture,
								smoothing, blendMode, numQuads))
				{
					quadBatchID++;
					if (quadBatches.length <= quadBatchID)
					{
						quadBatches.push(new QuadBatch());
					}
					quadBatch = quadBatches[quadBatchID];
					quadBatch.reset();
				}

				if (quad)
				{
					quadBatch.addQuad(quad, alpha, texture, smoothing, transformationMatrix, blendMode);
				}
				else
				{
					quadBatch.addQuadBatch(batch, alpha, transformationMatrix, blendMode);
				}
			}
			else
			{
				throw new Error("Unsupported display object: " + getQualifiedClassName(object));
			}

			if (isRootObject)
			{
				// remove unused batches
				for (i = quadBatches.length - 1; i > quadBatchID; --i)
				{
					quadBatches.pop().dispose();
				}
			}

			return quadBatchID;
		}

		// properties

		/** Returns the number of quads that have been added to the batch. */
		override public function get numQuads(): int
		{
			return mNumQuads;
		}

		/** Indicates if any vertices have a non-white color or are not fully opaque. */
		override public function get tinted(): Boolean
		{
			return mTinted;
		}

		/** The texture that is used for rendering, or null for pure quads. Note that this is the
		 *  texture instance of the first added quad; subsequently added quads may use a different
		 *  instance, as long as the base texture is the same. */
		override public function get texture(): Texture
		{
			return mTexture;
		}

		/** The TextureSmoothing used for rendering. */
		override public function get smoothing(): String
		{
			return mSmoothing;
		}

		/** Indicates if the rgb values are stored premultiplied with the alpha value. */
		override public function get premultipliedAlpha(): Boolean
		{
			return mVertexData.premultipliedAlpha;
		}

		/** Indicates if the batch itself should be batched on rendering. This makes sense only
		 *  if it contains only a small number of quads (we recommend no more than 16). Otherwise,
		 *  the CPU costs will exceed any gains you get from avoiding the additional draw call.
		 *  @default false */
		override public function get batchable(): Boolean
		{
			return mBatchable;
		}

		override public function set batchable(value: Boolean): void
		{
			mBatchable = value;
		}

		/** Indicates the number of quads for which space is allocated (vertex- and index-buffers).
		 *  If you add more quads than what fits into the current capacity, the QuadBatch is
		 *  expanded automatically. However, if you know beforehand how many vertices you need,
		 *  you can manually set the right capacity with this method. */
		override public function get capacity(): int
		{
			return mVertexData.numVertices / 4;
		}

		override public function set capacity(value: int): void
		{
			var oldCapacity: int = capacity;

			if (value == oldCapacity)
			{
				return;
			}
			else if (value == 0)
			{
				throw new Error("Capacity must be > 0");
			}
			else if (value > MAX_NUM_QUADS)
			{
				value = MAX_NUM_QUADS;
			}
			if (mNumQuads > value)
			{
				mNumQuads = value;
			}

			mVertexData.numVertices = value * 4;
			mIndexData.length = value * 6;

			for (var i: int = oldCapacity; i < value; ++i)
			{
				mIndexData[int(i * 6)] = i * 4;
				mIndexData[int(i * 6 + 1)] = i * 4 + 1;
				mIndexData[int(i * 6 + 2)] = i * 4 + 2;
				mIndexData[int(i * 6 + 3)] = i * 4 + 1;
				mIndexData[int(i * 6 + 4)] = i * 4 + 3;
				mIndexData[int(i * 6 + 5)] = i * 4 + 2;
			}

			destroyBuffers();
			mSyncRequired = true;
		}

		// program management

		private function getProgram(tinted: Boolean): Program3D
		{
			var target: Starling = Starling.current;
			var programName: String = QUAD_PROGRAM_NAME;

			if (mTexture)
			{
				programName = getImageProgramName(tinted, mTexture.mipMapping,
						mTexture.repeat, mTexture.format, mSmoothing);
			}

			var program: Program3D = target.getProgram(programName);

			if (!program)
			{
				// this is the input data we'll pass to the shaders:
				//
				// va0 -> position
				// va1 -> color
				// va2 -> texCoords
				// vc0 -> alpha
				// vc1 -> mvpMatrix
				// fñ0 -> <0.0, 0.5, 1.0, 2.0>
				// fs0 -> texture

				var vertexShader: String;
				var fragmentShader: String;

				if (!mTexture) // Quad-Shaders
				{
					vertexShader =
							"m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
							"mul v0, va1, vc0 \n";  // multiply alpha (vc0) with color (va1)

					fragmentShader =
							"mov oc, v0       \n";  // output color
				}
				else // Image-Shaders
				{
					vertexShader = tinted ?
							"m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
							"mul v0, va1, vc0 \n" + // multiply alpha (vc0) with color (va1)
							"mov v1, va2      \n"   // pass texture coordinates to fragment program*/
									:
							"m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
							"mov v1, va2      \n";  // pass texture coordinates to fragment program*/

					fragmentShader =
							"tex ft1, v1, fs0 <???>     \n" +  // sample texture 0
							(tinted ? "mul ft1, ft1, v0 \n" : "") + // multiply color with texel color
							"mov ft2, ft1               \n" +
							// in the register fñ0 is stored the vector (0.0, 0.5, 1.0, 2.0), which is used for any calculations
							// the register ft2 receives 0 or 1 by alpha value (1 - if pixel alpha == 0, 0 - otherwise)
							"seq ft2.x, ft1.w, fc0.x    \n" +
							// subtract that value from the pixel alpha, pixels with alpha == 0 get -1.
							"sub ft2.z, ft1.w, ft2.x    \n" +
							// kil command removes from processing the pixels, if value obtained in the previous step is -1
							"kil ft2.z                  \n" +
							// set alpha of all remaining mask pixels to 0 (to mask couldn't be seen)
							"mov ft1.xyzw, fc0.xxxx     \n" +
							"mov oc, ft1                \n";  // sample texture 0

					fragmentShader = fragmentShader.replace("<???>",
							RenderSupport.getTextureLookupFlags(
									mTexture.format, mTexture.mipMapping, mTexture.repeat, smoothing));
				}

				program = target.registerProgramFromSource(programName,
						vertexShader, fragmentShader);
			}

			return program;
		}

		private static function getImageProgramName(tinted: Boolean, mipMap: Boolean = true,
													repeat: Boolean = false, format: String = "bgra",
													smoothing: String = "bilinear"): String
		{
			var bitField: uint = 0;

			if (tinted)
			{
				bitField |= 1;
			}
			if (mipMap)
			{
				bitField |= 1 << 1;
			}
			if (repeat)
			{
				bitField |= 1 << 2;
			}

			if (smoothing == TextureSmoothing.NONE)
			{
				bitField |= 1 << 3;
			}
			else if (smoothing == TextureSmoothing.TRILINEAR)
			{
				bitField |= 1 << 4;
			}

			if (format == Context3DTextureFormat.COMPRESSED)
			{
				bitField |= 1 << 5;
			}
			else if (format == "compressedAlpha")
			{
				bitField |= 1 << 6;
			}

			var name: String = sProgramNameCache[bitField];

			if (name == null)
			{
				name = "MQB_i." + bitField.toString(16);
				sProgramNameCache[bitField] = name;
			}

			return name;
		}
	}
}
