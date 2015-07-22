/**
 * Created by Nazar on 17.03.2014.
 */
package com.catalystapps.gaf.display
{
	import com.catalystapps.gaf.core.gaf_internal;
	import com.catalystapps.gaf.data.GAF;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.data.config.CTextFieldObject;
	import com.catalystapps.gaf.utils.DebugUtility;

	import feathers.controls.TextInput;
	import feathers.controls.text.TextFieldTextEditor;
	import feathers.core.ITextEditor;

	import flash.geom.Matrix;
	import flash.geom.Point;

	import starling.display.Image;
	import starling.textures.Texture;

	/**
	 * @private
	 */
	public class GAFTextField extends TextInput implements IGAFDebug, IMaxSize, IGAFDisplayObject
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

		private static const HELPER_MATRIX: Matrix = new Matrix();

		private var _pivotMatrix: Matrix;

		private var _filterConfig: CFilter;
		private var _filterScale: Number;

		private var _maxSize: Point;

		private var _pivotChanged: Boolean;
		private var _scale: Number;
		private var _csf: Number;

		gaf_internal var __debugOriginalAlpha: Number = NaN;

		private var _orientationChanged: Boolean;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/**
		 * GAFTextField represents text field that is part of the <code>GAFMovieClip</code>
		 * @param config
		 */
		public function GAFTextField(config: CTextFieldObject, scale: Number = 1, csf: Number = 1)
		{
			super();

			if (isNaN(scale)) scale = 1;
			if (isNaN(csf)) csf = 1;

			this._scale = scale;
			this._csf = csf;

			this._pivotMatrix = new Matrix();
			this._pivotMatrix.tx = config.pivotPoint.x;
			this._pivotMatrix.ty = config.pivotPoint.y;
			this._pivotMatrix.scale(scale, scale);

			if (!isNaN(config.width))
			{
				this.width = config.width;
			}

			if (!isNaN(config.height))
			{
				this.height = config.height;
			}

			this.text = config.text;
			this.restrict = config.restrict;
			this.isEditable = config.editable;
			this.displayAsPassword = config.displayAsPassword;
			this.maxChars = config.maxChars;
			this.verticalAlign = TextInput.VERTICAL_ALIGN_TOP;

			this.textEditorProperties.textFormat = config.textFormat;
			this.textEditorProperties.embedFonts = GAF.gaf_internal::useDeviceFonts ? false : config.embedFonts;
			this.textEditorProperties.multiline = config.multiline;
			this.textEditorProperties.wordWrap = config.wordWrap;
			this.textEditorFactory = function (): ITextEditor
			{
				var textEditor: GAFTextFieldTextEditor = new GAFTextFieldTextEditor(_scale, _csf);
				if (this._filterConfig && !isNaN(this._filterScale))
				{
					textEditor.setFilterConfig(this._filterConfig, this._filterScale);
				}
				return textEditor;
			};

			this.invalidateSize();
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
			if (this.textEditor && this.textEditor is TextFieldTextEditor)
			{
				(this.textEditor as TextFieldTextEditor).invalidate(INVALIDATION_FLAG_SIZE);
			}
			this.invalidate(INVALIDATION_FLAG_SIZE);
		}

		/** @private */
		public function invalidateOrientation(): void
		{
			this._orientationChanged = true;
		}

		/** @private */
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

		/** @private */
		public function setFilterConfig(value: CFilter, scale: Number = 1): void
		{
			if (this._filterConfig != value || this._filterScale != scale)
			{
				if (value)
				{
					this._filterConfig = value;
					this._filterScale = scale;
				}
				else
				{
					this._filterConfig = null;
					this._filterScale = NaN;
				}

				if (this.textEditor && this.textEditor is GAFTextFieldTextEditor)
				{
					(this.textEditor as GAFTextFieldTextEditor).setFilterConfig(value, scale);
				}
			}
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		gaf_internal function __debugHighlight(): void
		{
			use namespace gaf_internal;
			if (isNaN(this.__debugOriginalAlpha))
			{
				this.__debugOriginalAlpha = this.alpha;
			}
			this.alpha = 1;
		}

		gaf_internal function __debugLowlight(): void
		{
			use namespace gaf_internal;
			if (isNaN(this.__debugOriginalAlpha))
			{
				this.__debugOriginalAlpha = this.alpha;
			}
			this.alpha = .05;
		}

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
		private function updateTransformMatrix(): void
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

		override public function set transformationMatrix(matrix: Matrix): void
		{
			super.transformationMatrix = matrix;

			this.invalidateSize();
		}

		override public function set pivotX(value: Number): void
		{
			this._pivotChanged = true;
			super.pivotX = value;
		}

		override public function set pivotY(value: Number): void
		{
			this._pivotChanged = true;
			super.pivotY = value;
		}

		override public function get x(): Number
		{
			updateTransformMatrix();
			return super.x;
		}

		override public function get y(): Number
		{
			updateTransformMatrix();
			return super.y;
		}

		override public function get rotation(): Number
		{
			updateTransformMatrix();
			return super.rotation;
		}

		override public function get scaleX(): Number
		{
			updateTransformMatrix();
			return super.scaleX;
		}

		override public function get scaleY(): Number
		{
			updateTransformMatrix();
			return super.scaleY;
		}

		override public function get skewX(): Number
		{
			updateTransformMatrix();
			return super.skewX;
		}

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

		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------

		/** @private */
		public function get pivotMatrix(): Matrix
		{
			HELPER_MATRIX.copyFrom(this._pivotMatrix);

			if (this._pivotChanged)
			{
				HELPER_MATRIX.tx = this.pivotX;
				HELPER_MATRIX.ty = this.pivotY;
			}

			return HELPER_MATRIX;
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

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------
	}
}
