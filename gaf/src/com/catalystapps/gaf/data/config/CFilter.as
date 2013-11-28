package com.catalystapps.gaf.data.config
{
	/**
	 * @author mitvad
	 */
	public class CFilter
	{
		//--------------------------------------------------------------------------
		//
		//  PUBLIC VARIABLES
		//
		//--------------------------------------------------------------------------
		
		public static const FILTER_BLUR: String = "Fblur";
		public static const FILTER_COLOR_TRANSFORM: String = "Fctransform";
		
		//--------------------------------------------------------------------------
		//
		//  PRIVATE VARIABLES
		//
		//--------------------------------------------------------------------------
		
		private var _blurFilterParams: Vector.<Number>;
		private var _colorTransformFilterParams: Vector.<Number>;
		
		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		public function CFilter()
		{
			this._blurFilterParams = new Vector.<Number>();
			this._blurFilterParams.push(0, 0);
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		
		public function clone(): CFilter
		{
			var result: CFilter = new CFilter();
			result.blurFilterParams = this._blurFilterParams;
			result.colorTransformFilterParams = this._colorTransformFilterParams;
			
			return result;
		}
		
		public function initFilterColorTransform(params: Array): void
		{
			this._colorTransformFilterParams = new Vector.<Number>();
			
			this._colorTransformFilterParams.push(params[1], 0, 0, 0, params[2],
												  0,params[3], 0, 0, params[4],
												  0, 0, params[5], 0, params[6],
												  0, 0, 0, 1, params[0]);
			
		}
		
		public function initFilterBlur(blurX: Number, blurY: Number): void
		{
			this._blurFilterParams = new Vector.<Number>();
			this._blurFilterParams.push(blurX, blurY);
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
		
		public function get blurFilterParams(): Vector.<Number> 
		{
			return _blurFilterParams;
		}

		public function set blurFilterParams(blurFilterParams: Vector.<Number>): void 
		{
			_blurFilterParams = blurFilterParams;
		}

		public function get colorTransformFilterParams(): Vector.<Number> 
		{
			return _colorTransformFilterParams;
		}

		public function set colorTransformFilterParams(colorTransformFilterParams: Vector.<Number>) : void
		{
			_colorTransformFilterParams = colorTransformFilterParams;
		}
		
	}
}
