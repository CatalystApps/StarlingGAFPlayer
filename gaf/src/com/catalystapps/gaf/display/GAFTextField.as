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

	import starling.display.Image;
	import starling.textures.Texture;

	/**
	 * @private
	 */
	public class GAFTextField extends TextInput implements IGAFDebug, IGAFDisplayObject
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

		private var _zIndex: uint;

		private var _pivotMatrix: Matrix;

		private var _filterConfig: CFilter;
		private var _filterScale: Number;

		gaf_internal var __debugOriginalAlpha: Number = NaN;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/**
		 * GAFTextField represents text field that is part of the <code>GAFMovieClip</code>
		 * @param config
		 */
		public function GAFTextField(config: CTextFieldObject)
		{
			super();

			_pivotMatrix = new Matrix();
			_pivotMatrix.tx = config.pivotPoint.x;
			_pivotMatrix.ty = config.pivotPoint.y;

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
				var textEditor: GAFTextFieldTextEditor = new GAFTextFieldTextEditor();
				if (_filterConfig && !isNaN(_filterScale))
				{
					textEditor.setFilterConfig(_filterConfig, _filterScale);
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
			if (_filterConfig != value || _filterScale != scale)
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
			if (isNaN(__debugOriginalAlpha))
			{
				__debugOriginalAlpha = this.alpha;
			}
			this.alpha = 1;
		}

		gaf_internal function __debugLowlight(): void
		{
			use namespace gaf_internal;
			if (isNaN(__debugOriginalAlpha))
			{
				__debugOriginalAlpha = this.alpha;
			}
			this.alpha = .05;
		}

		gaf_internal function __debugResetLight(): void
		{
			use namespace gaf_internal;
			if (!isNaN(__debugOriginalAlpha))
			{
				this.alpha = __debugOriginalAlpha;
				__debugOriginalAlpha = NaN;
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

		public function get pivotMatrix(): Matrix
		{
			return _pivotMatrix;
		}
		//--------------------------------------------------------------------------
		//
		//  STATIC METHODS
		//
		//--------------------------------------------------------------------------
	}
}
