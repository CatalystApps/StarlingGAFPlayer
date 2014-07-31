/**
 * Created by Nazar on 17.03.2014.
 */
package com.catalystapps.gaf.display
{
	import com.catalystapps.gaf.utils.DebugUtility;

	import feathers.controls.TextInput;
	import feathers.controls.text.TextFieldTextEditor;

	import flash.geom.Matrix;

	import starling.display.Image;
	import starling.textures.Texture;

	/**
	 * @private
	 */
	public class GAFTextField extends TextInput implements IGAFDebug, IGAFDisplayObject
	{
		private var _zIndex: uint;
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

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/**
		 * GAFTextField represents text field that is part of the <code>GAFMovieClip</code>
		 * @param width
		 * @param height
		 */
		public function GAFTextField(width: Number = NaN, height: Number = NaN)
		{
			super();

			if (!isNaN(width))
			{
				this.width = width;
			}

			if (!isNaN(height))
			{
				this.height = height;
			}
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * @private
		 * We need to update the textField size after the textInput was transformed
		 */
		public function invalidateSize(): void
		{
			if (this.textEditor)
			{
				(this.textEditor as TextFieldTextEditor).invalidate(INVALIDATION_FLAG_SIZE);
			}
			this.invalidate(INVALIDATION_FLAG_SIZE);
		}

		public function set debugColors(value: Vector.<uint>): void
		{
			var t: Texture = Texture.fromColor(1, 1, DebugUtility.RENDERING_NEUTRAL_COLOR, true);
			var bgImage: Image = new Image(t);
			var alpha0: Number;
			var alpha1: Number;

			switch (value.length)
			{
				case 1:
					bgImage.color = value[0];
					bgImage.alpha = (value[0] >>> 24) / 255;
					break;
				case 2:
					bgImage.setVertexColor(0, value[0]);
					bgImage.setVertexColor(1, value[0]);
					bgImage.setVertexColor(2, value[1]);
					bgImage.setVertexColor(3, value[1]);

					alpha0 = (value[0] >>> 24) / 255;
					alpha1 = (value[1] >>> 24) / 255;
					bgImage.setVertexAlpha(0, alpha0);
					bgImage.setVertexAlpha(1, alpha0);
					bgImage.setVertexAlpha(2, alpha1);
					bgImage.setVertexAlpha(3, alpha1);
					break;
				case 3:
					bgImage.setVertexColor(0, value[0]);
					bgImage.setVertexColor(1, value[0]);
					bgImage.setVertexColor(2, value[1]);
					bgImage.setVertexColor(3, value[2]);

					alpha0 = (value[0] >>> 24) / 255;
					bgImage.setVertexAlpha(0, alpha0);
					bgImage.setVertexAlpha(1, alpha0);
					bgImage.setVertexAlpha(2, (value[1] >>> 24) / 255);
					bgImage.setVertexAlpha(3, (value[2] >>> 24) / 255);
					break;
				case 4:
					bgImage.setVertexColor(0, value[0]);
					bgImage.setVertexColor(1, value[1]);
					bgImage.setVertexColor(2, value[2]);
					bgImage.setVertexColor(3, value[3]);

					bgImage.setVertexAlpha(0, (value[0] >>> 24) / 255);
					bgImage.setVertexAlpha(1, (value[1] >>> 24) / 255);
					bgImage.setVertexAlpha(2, (value[2] >>> 24) / 255);
					bgImage.setVertexAlpha(3, (value[3] >>> 24) / 255);
					break;
			}

			this.backgroundSkin = bgImage;
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

		override public function set transformationMatrix(matrix: Matrix): void
		{
			super.transformationMatrix = matrix;

			this.invalidateSize();
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
		public function get zIndex(): uint
		{
			return _zIndex;
		}

		public function set zIndex(value: uint): void
		{
			_zIndex = value;
		}
		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------
	}
}