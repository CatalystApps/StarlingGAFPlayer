package com.catalystapps.gaf.data.config
{
	import flash.geom.Matrix;

	/**
	 * @private
	 */
	public class CAnimationFrameInstance
	{
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
		private var _id: String;
		private var _zIndex: uint;
		private var _matrix: Matrix;
		private var _alpha: Number;
		private var _maskID: String;
		private var _filter: CFilter;

		private static var tx: Number, ty: Number;

		// --------------------------------------------------------------------------
		//
		// CONSTRUCTOR
		//
		// --------------------------------------------------------------------------
		public function CAnimationFrameInstance(id: String)
		{
			this._id = id;
		}

		// --------------------------------------------------------------------------
		//
		// PUBLIC METHODS
		//
		// --------------------------------------------------------------------------
		public function clone(): CAnimationFrameInstance
		{
			var result: CAnimationFrameInstance = new CAnimationFrameInstance(this._id);

			var filterCopy: CFilter = null;

			if (this._filter)
			{
				filterCopy = this._filter.clone();
			}

			result.update(this._zIndex, this._matrix.clone(), this._alpha, this._maskID, filterCopy);

			return result;
		}

		public function update(zIndex: uint, matrix: Matrix, alpha: Number, maskID: String, filter: CFilter): void
		{
			this._zIndex = zIndex;
			this._matrix = matrix;
			this._alpha = alpha;
			this._maskID = maskID;
			this._filter = filter;
		}

		public function getTransformMatrix(pivotMatrix: Matrix, scale: Number): Matrix
		{
			var result: Matrix = pivotMatrix.clone();
			tx = this._matrix.tx;
			ty = this._matrix.ty;
			this._matrix.tx *= scale;
			this._matrix.ty *= scale;
			result.concat(this._matrix);
			this._matrix.tx = tx;
			this._matrix.ty = ty;

			return result;
		}

		public function applyTransformMatrix(transformationMatrix: Matrix, pivotMatrix: Matrix, scale: Number): void
		{
			transformationMatrix.copyFrom(pivotMatrix);
			tx = this._matrix.tx;
			ty = this._matrix.ty;
			this._matrix.tx *= scale;
			this._matrix.ty *= scale;
			transformationMatrix.concat(this._matrix);
			this._matrix.tx = tx;
			this._matrix.ty = ty;
		}

		public function calculateTransformMatrix(transformationMatrix: Matrix, pivotMatrix: Matrix, scale: Number): Matrix
		{
			applyTransformMatrix(transformationMatrix, pivotMatrix, scale);
			return transformationMatrix;
		}

		// --------------------------------------------------------------------------
		//
		// PRIVATE METHODS
		//
		// --------------------------------------------------------------------------
		// --------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		// --------------------------------------------------------------------------
		// --------------------------------------------------------------------------
		//
		// EVENT HANDLERS
		//
		// --------------------------------------------------------------------------
		// --------------------------------------------------------------------------
		//
		// GETTERS AND SETTERS
		//
		// --------------------------------------------------------------------------
		public function get id(): String
		{
			return this._id;
		}

		public function get matrix(): Matrix
		{
			return this._matrix;
		}

		public function get alpha(): Number
		{
			return this._alpha;
		}

		public function get maskID(): String
		{
			return this._maskID;
		}

		public function get filter(): CFilter
		{
			return this._filter;
		}

		public function get zIndex(): uint
		{
			return this._zIndex;
		}
	}
}
