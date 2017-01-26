/**
 * Created by Nazar on 17.03.2014.
 */
package com.catalystapps.gaf.display
{
	import com.catalystapps.gaf.core.gaf_internal;
	import com.catalystapps.gaf.data.GAF;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.data.config.CTextFieldObject;
	import com.catalystapps.gaf.filter.GAFFilterChain;
	import com.catalystapps.gaf.utils.DebugUtility;

	import feathers.controls.TextInput;
	import feathers.controls.text.TextFieldTextEditor;
	import feathers.core.ITextEditor;

	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextFormat;

	import starling.display.Image;
	import starling.textures.Texture;

	/**
	 * GAFTextField is a text entry control that extends functionality of the <code>feathers.controls.TextInput</code>
	 * for the GAF library needs.
	 * All dynamic text fields (including input text fields) in GAF library are instances of the GAFTextField.
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

		private static const HELPER_POINT: Point = new Point();
		private static const HELPER_MATRIX: Matrix = new Matrix();

		private var _pivotMatrix: Matrix;

        private var _filterChain:GAFFilterChain;
		private var _filterConfig: CFilter;
		private var _filterScale: Number;

		private var _maxSize: Point;

		private var _pivotChanged: Boolean;
		private var _scale: Number;
		private var _csf: Number;

		/** @private */
		gaf_internal var __debugOriginalAlpha: Number = NaN;

		private var _orientationChanged: Boolean;

		private var _config: CTextFieldObject;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/**
		 * @private
		 * GAFTextField represents text field that is part of the <code>GAFMovieClip</code>
		 * @param config
		 * @param scale
		 * @param csf
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
			this.isEnabled = this.isEditable || config.selectable; // editable text must be selectable anyway
			this.displayAsPassword = config.displayAsPassword;
			this.maxChars = config.maxChars;
			this.verticalAlign = TextInput.VERTICAL_ALIGN_TOP;

			this.textEditorProperties.textFormat = cloneTextFormat(config.textFormat);
			this.textEditorProperties.embedFonts = GAF.gaf_internal::useDeviceFonts ? false : config.embedFonts;
			this.textEditorProperties.multiline = config.multiline;
			this.textEditorProperties.wordWrap = config.wordWrap;
			this.textEditorFactory = function (): ITextEditor
			{
				return new GAFTextFieldTextEditor(_scale, _csf);
			};

			this.invalidateSize();

			this._config = config;
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * Creates a new instance of GAFTextField.
		 */
		public function copy(): GAFTextField
		{
			var clone: GAFTextField = new GAFTextField(this._config, this._scale, this._csf);
			clone.alpha = this.alpha;
			clone.visible = this.visible;
			clone.transformationMatrix = this.transformationMatrix;
			clone.textEditorFactory = this.textEditorFactory;
			clone.setFilterConfig(_filterConfig, _filterScale);

			return clone;
		}

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
			var t: Texture = Texture.fromColor(1, 1, DebugUtility.RENDERING_NEUTRAL_COLOR, 1, true);
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

				this.applyFilter();
			}
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		/** @private */
		private function applyFilter(): void
		{
			if (this.textEditor)
			{
				if (this.textEditor is GAFTextFieldTextEditor)
				{
					(this.textEditor as GAFTextFieldTextEditor).setFilterConfig(this._filterConfig, this._filterScale);
				}
				else if (this._filterConfig && !isNaN(this._filterScale))
				{
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
				else if (this.filter)
				{
					this.filter.dispose();
					this.filter = null;

					this._filterChain = null;
				}
			}
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

		/** @private */
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

		/** @private */
		override protected function createTextEditor():void
		{
			super.createTextEditor();

			this.applyFilter();
		}

		/** @private */
		override public function dispose(): void
		{
			super.dispose();
			this._config = null;
		}

		/** @private */
		override public function set transformationMatrix(matrix: Matrix): void
		{
			super.transformationMatrix = matrix;

			this.invalidateSize();
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

		/**
		 * The width of the text in pixels.
		 * @return {Number}
		 */
		public function get textWidth(): Number
		{
			this.validate();
			this.textEditor.measureText(HELPER_POINT);

			return HELPER_POINT.x;
		}

		/**
		 * The height of the text in pixels.
		 * @return {Number}
		 */
		public function get textHeight(): Number
		{
			this.validate();
			this.textEditor.measureText(HELPER_POINT);

			return HELPER_POINT.y;
		}

		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------

		/** @private */
		private function cloneTextFormat(textFormat: TextFormat): TextFormat
		{
			if (!textFormat) throw new ArgumentError("Argument \"textFormat\" must be not null.");

			var result: TextFormat = new TextFormat(
					textFormat.font,
					textFormat.size,
					textFormat.color,
					textFormat.bold,
					textFormat.italic,
					textFormat.underline,
					textFormat.url,
					textFormat.target,
					textFormat.align,
					textFormat.leftMargin,
					textFormat.rightMargin,
					textFormat.indent,
					textFormat.leading
			);

			return result;
		}
	}
}
