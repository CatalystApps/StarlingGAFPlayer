package com.catalystapps.gaf.data.config {
	import flash.geom.Matrix;

	/**
	 * @private
	 */
	public class CAnimationFrameInstance {
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

		private var _id : String;
		private var _zIndex : uint;
		private var _matrix : Matrix;
		private var _alpha : Number;
		private var _maskID : String;
		private var _filter : CFilter;
		private var matrixCopy : Matrix;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function CAnimationFrameInstance(id : String) {
			this._id = id;
			this.matrixCopy = new Matrix();
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		public function clone() : CAnimationFrameInstance {
			var result : CAnimationFrameInstance = new CAnimationFrameInstance(this._id);

			var filterCopy : CFilter = null;

			if (this._filter) {
				filterCopy = this._filter.clone();
			}

			result.update(this._zIndex, this._matrix.clone(), this._alpha, this._maskID, filterCopy);

			return result;
		}

		public function update(zIndex : uint, matrix : Matrix, alpha : Number, maskID : String, filter : CFilter) : void {
			this._zIndex = zIndex;
			this._matrix = matrix;
			this._alpha = alpha;
			this._maskID = maskID;
			this._filter = filter;
		}

		public function getTransformMatrix(pivotMatrix : Matrix, scale : Number) : Matrix {
			var result : Matrix = pivotMatrix.clone();
			var matrixCopy : Matrix = this._matrix.clone();

			matrixCopy.tx = matrixCopy.tx * scale;
			matrixCopy.ty = matrixCopy.ty * scale;
			result.concat(matrixCopy);

			return result;
		}

		public function applyTransformMatrix(transformationMatrix : Matrix, pivotMatrix : Matrix, scale : Number) : void {
			transformationMatrix.copyFrom(pivotMatrix);
			this.matrixCopy.copyFrom(this._matrix);
			this.matrixCopy.tx *= scale;
			this.matrixCopy.ty *= scale;
			transformationMatrix.concat(this.matrixCopy);
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

		public function get id() : String {
			return _id;
		}

		public function get matrix() : Matrix {
			return _matrix;
		}

		public function get alpha() : Number {
			return _alpha;
		}

		public function get maskID() : String {
			return _maskID;
		}

		public function get filter() : CFilter {
			return _filter;
		}

		public function get zIndex() : uint {
			return _zIndex;
		}
	}
}
