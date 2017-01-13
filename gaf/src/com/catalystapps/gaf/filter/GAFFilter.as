package com.catalystapps.gaf.filter
{
	import com.catalystapps.gaf.data.config.CBlurFilterData;
	import com.catalystapps.gaf.data.config.CColorMatrixFilterData;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.data.config.ICFilterData;
	import com.catalystapps.gaf.utils.VectorUtility;

	import starling.filters.FragmentFilter;
import starling.filters.IFilterHelper;
import starling.rendering.FilterEffect;
import starling.rendering.Painter;
import starling.textures.Texture;
import starling.utils.Color;

	/**
	 * @private
	 */
	public class GAFFilter extends FragmentFilter
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
		private static const IDENTITY: Vector.<Number> = new <Number>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];

		private var _filterEffect:GAFFilterEffect = null;

		private var _currentScale: Number = 1;

		public function GAFFilter(inputResolution: Number = 1)
		{
			resolution = inputResolution;
			super();

			_filterEffect = super.effect as GAFFilterEffect;
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------
		/** A uniform color will replace the RGB values of the input color, while the alpha
		 *  value will be multiplied with the given factor. Pass <code>false</code> as the
		 *  first parameter to deactivate the uniform color. */
		public function setUniformColor(enable: Boolean, color: uint = 0x0, alpha: Number = 1.0): void
		{
			_filterEffect.mColor[0] = Color.getRed(color) / 255.0;
			_filterEffect.mColor[1] = Color.getGreen(color) / 255.0;
			_filterEffect.mColor[2] = Color.getBlue(color) / 255.0;
			_filterEffect.mColor[3] = alpha;
			_filterEffect.mUniformColor = enable;
		}

		public function setConfig(cFilter: CFilter, scale: Number): void
		{
			_currentScale = scale;
			updateFilters(cFilter);
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		private function updateFilters(cFilter: CFilter): void
		{
			var i: uint;
			var l: uint = cFilter.filterConfigs.length;
			var filterConfig: ICFilterData;

			var blurUpdated: Boolean;
			var ctmUpdated: Boolean;

			_filterEffect.mUniformColor = false;

			for (i = 0; i < l; i++)
			{
				filterConfig = cFilter.filterConfigs[i];

				if (filterConfig is CBlurFilterData)
				{
					updateBlurFilter(filterConfig as CBlurFilterData);
					blurUpdated = true;
				}
				else if (filterConfig is CColorMatrixFilterData)
				{
					updateColorMatrixFilter(filterConfig as CColorMatrixFilterData);
					ctmUpdated = true;
				}
			}

			if (!blurUpdated)
			{
				resetBlurFilter();
			}

			if (!ctmUpdated)
			{
				resetColorMatrixFilter();
			}

			updateMarginsAndPasses();
		}

		private function updateMarginsAndPasses(): void
		{
			if (_filterEffect.mBlurX == 0 && _filterEffect.mBlurY == 0)
			{
				_filterEffect.mBlurX = 0.001;
			}

            updatePadding();
		}

		private function updateBlurFilter(cBlurFilterData: CBlurFilterData): void
		{
			_filterEffect.mBlurX = cBlurFilterData.blurX * _currentScale;
			_filterEffect.mBlurY = cBlurFilterData.blurY * _currentScale;

			var maxBlur: Number = Math.max(_filterEffect.mBlurX, _filterEffect.mBlurY);

			if (maxBlur <= 10)
			{
				resolution = 1 + (10 - maxBlur) * 0.1;
			}
			else
			{
				resolution = 1 - maxBlur * 0.01;
			}

			setUniformColor((cBlurFilterData.color > -1), cBlurFilterData.color, cBlurFilterData.alpha * cBlurFilterData.strength);
		}

		private function updateColorMatrixFilter(cColorMatrixFilterData: CColorMatrixFilterData): void
		{
			var value: Vector.<Number> = cColorMatrixFilterData.matrix;

			_filterEffect.changeColor = false;

			if (value && value.length != 20)
			{
				throw new ArgumentError("Invalid matrix length: must be 20");
			}

			if (value == null)
			{
				VectorUtility.copyMatrix(_filterEffect.cUserMatrix, IDENTITY);
			}
			else
			{
				_filterEffect.changeColor = true;
				VectorUtility.copyMatrix(_filterEffect.cUserMatrix, value);
			}

			updateShaderMatrix();
		}

		private function updateShaderMatrix(): void
		{
			// the shader needs the matrix components in a different order,
			// and it needs the offsets in the range 0-1.

			VectorUtility.fillMatrix(_filterEffect.cShaderMatrix, _filterEffect.cUserMatrix[0], _filterEffect.cUserMatrix[1], _filterEffect.cUserMatrix[2], _filterEffect.cUserMatrix[3],
																  _filterEffect.cUserMatrix[5], _filterEffect.cUserMatrix[6], _filterEffect.cUserMatrix[7], _filterEffect.cUserMatrix[8],
																  _filterEffect.cUserMatrix[10], _filterEffect.cUserMatrix[11], _filterEffect.cUserMatrix[12], _filterEffect.cUserMatrix[13],
																  _filterEffect.cUserMatrix[15], _filterEffect.cUserMatrix[16],_filterEffect. cUserMatrix[17], _filterEffect.cUserMatrix[18],
																  _filterEffect.cUserMatrix[4],  _filterEffect.cUserMatrix[9],  _filterEffect.cUserMatrix[14], _filterEffect.cUserMatrix[19]);
		}

        private function updatePadding():void
        {
            var paddingX:Number = (_filterEffect.mBlurX ? Math.ceil(Math.abs(_filterEffect.mBlurX)) + 3 : 1) / resolution;
            var paddingY:Number = (_filterEffect.mBlurY ? Math.ceil(Math.abs(_filterEffect.mBlurY)) + 3 : 1) / resolution;

            padding.setTo(paddingX, paddingX, paddingY, paddingY);
        }

        private function resetBlurFilter(): void
        {
            _filterEffect.mOffsets[0] = _filterEffect.mOffsets[1] = _filterEffect.mOffsets[2] = _filterEffect.mOffsets[3] = 0;
            _filterEffect.mWeights[0] = _filterEffect.mWeights[1] = _filterEffect.mWeights[2] = _filterEffect.mWeights[3] = 0;
            _filterEffect.mColor[0] = _filterEffect.mColor[1] = _filterEffect.mColor[2] = _filterEffect.mColor[3] = 1;
            _filterEffect.mBlurX = 0;
            _filterEffect.mBlurY = 0;
        }

        private function resetColorMatrixFilter(): void
        {
            VectorUtility.copyMatrix(_filterEffect.cUserMatrix, IDENTITY);
            VectorUtility.copyMatrix(_filterEffect.cShaderMatrix, IDENTITY);
            _filterEffect.changeColor = false;
        }
		//--------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		//--------------------------------------------------------------------------

        override public function process(painter:Painter, helper:IFilterHelper,
                                         input0:Texture = null, input1:Texture = null,
                                         input2:Texture = null, input3:Texture = null):Texture
        {
			if (_filterEffect.mBlurX == 0 && _filterEffect.mBlurY == 0)
            {
                _filterEffect.strength = 0;
                return super.process(painter, helper, input0);
            }

            var blurX:Number = Math.abs(_filterEffect.mBlurX);
            var blurY:Number = Math.abs(_filterEffect.mBlurY);
            var outTexture:Texture = input0;
            var inTexture:Texture;

            _filterEffect.direction = GAFFilterEffect.HORIZONTAL;

            while (blurX > 0)
            {
                _filterEffect.strength = Math.min(1.0, blurX);

                blurX -= _filterEffect.strength;
                inTexture = outTexture;
                outTexture = super.process(painter, helper, inTexture);

                if (inTexture != input0) helper.putTexture(inTexture);
            }

            _filterEffect.direction = GAFFilterEffect.VERTICAL;

            while (blurY > 0)
            {
                _filterEffect.strength = Math.min(1.0, blurY);

                blurY -= _filterEffect.strength;
                inTexture = outTexture;
                outTexture = super.process(painter, helper, inTexture);

                if (inTexture != input0) helper.putTexture(inTexture);
            }

            return outTexture;
        }

        protected override function createEffect():FilterEffect
        {
            return (_filterEffect) ? _filterEffect : new GAFFilterEffect() ;
        }

		public override function get numPasses():int
		{
			var numPasses:int = 1;

			if(_filterEffect.mBlurX > 0 || _filterEffect.mBlurX > 0)
			{
				numPasses = Math.ceil(_filterEffect.mBlurX) + Math.ceil(_filterEffect.mBlurY);
				numPasses = (_filterEffect.changeColor) ? numPasses++ : numPasses;
			}

			return numPasses;
		}

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

	}
}
