package com.catalystapps.gaf.data.config
{
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	/**
	 * @private
	 */
	public class CTextureAtlasElement
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
		
		private var _id: String;
		private var _atlasID: String;
		private var _region: Rectangle;
		private var _pivotMatrix: Matrix;
		private var _scale9Grid: Rectangle;
		
		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		public function CTextureAtlasElement(id: String, atlasID: String, region: Rectangle, pivotMatrix: Matrix)
		{
			this._id = id;
			this._atlasID = atlasID;
			this._region = region;
			this._pivotMatrix = pivotMatrix;
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		
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
		
		public function get id(): String
		{
			return _id;
		}

		public function get region(): Rectangle
		{
			return _region;
		}

		public function get pivotMatrix(): Matrix
		{
			return _pivotMatrix;
		}

		public function set pivotMatrix(pivotMatrix: Matrix): void
		{
			_pivotMatrix = pivotMatrix;
		}

		public function get atlasID(): String
		{
			return _atlasID;
		}

		public function get scale9Grid(): flash.geom.Rectangle
		{
			return _scale9Grid;
		}

		public function set scale9Grid(value: Rectangle): void
		{
			_scale9Grid = value;
		}
	}
}
