package com.catalystapps.gaf.data.config
{
	/**
	 * @private
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
		
		public function initColorMatrixFilter(params: Array): void
		{
			var i: uint;
			
			if (this._colorTransformFilterParams)
			{
				i = 0;
				
				var tmpMatrix: Vector.<Number> = new Vector.<Number>();
				
	            for (var y:int=0; y<4; ++y)
	            {
	                for (var x:int=0; x<5; ++x)
	                {
	                    tmpMatrix[int(i+x)] = 
	                        _colorTransformFilterParams[i]        * params[x]           +
	                        _colorTransformFilterParams[int(i+1)] * params[int(x +  5)] +
	                        _colorTransformFilterParams[int(i+2)] * params[int(x + 10)] +
	                        _colorTransformFilterParams[int(i+3)] * params[int(x + 15)] +
	                        (x == 4 ? _colorTransformFilterParams[int(i+4)] : 0);
	                }
	                
	                i+=5;
	            }
				
				copyMatrix(tmpMatrix, _colorTransformFilterParams);
			}
			else
			{
				this._colorTransformFilterParams = new Vector.<Number>();
				
				for (i = 0; i < params.length; i++)
				{
					this._colorTransformFilterParams.push(params[i]);					
				}										
			}		
		}
		
		private function copyMatrix(from: Vector.<Number>, to: Vector.<Number>):void
        {
            for (var i: uint=0; i < 20; ++i)
			{
                to[i] = from[i];
			}
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
