package com.catalystapps.gaf.filter
{
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.core.RenderSupport;
	import com.catalystapps.gaf.data.config.CBlurFilterData;
	import com.catalystapps.gaf.data.config.CColorMatrixFilterData;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.data.config.ICFilterData;
	import com.catalystapps.gaf.utils.VectorUtility;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.geom.Matrix;

	import starling.core.Starling;
	import starling.filters.FragmentFilter;
	import starling.filters.FragmentFilterMode;
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

		private static const NORMAL_PROGRAM_NAME: String = "BF_n";
		private static const TINTED_PROGRAM_NAME: String = "BF_t";
		private static const COLOR_TRANSFORM_PROGRAM_NAME: String = "CMF";
		private const MAX_SIGMA: Number = 2.0;
		private static const IDENTITY: Vector.<Number> = new <Number>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
		private static const MIN_COLOR: Vector.<Number> = new <Number>[0, 0, 0, 0.0001];

		// Unity-matching path (PetCity GAFBakedFilteredObjectImpl_Pro): the preview
		// must look like the game, not like Flash.
		private static const UNITY_COLOR_PROGRAM_NAME: String = "GAFU_color";
		private static const UNITY_GLOW_BLUR_PROGRAM_NAME: String = "GAFU_glowBlur";
		private static const UNITY_GLOW_FINAL_PROGRAM_NAME: String = "GAFU_glowFinal";
		private static const UNITY_BLUR_PROGRAM_NAME: String = "GAFU_blur";
		private static const UNITY_BLUR_FINAL_PROGRAM_NAME: String = "GAFU_blurFinal";
		private static const UNITY_MODE_COLOR: int = 0;
		private static const UNITY_MODE_GLOW: int = 1;
		private static const UNITY_MODE_BLUR: int = 2;
		private static const UNITY_BLUR_DIVIDER: Number = 8;
		private static const UNITY_KERNEL_SIZE: Number = 9;
		private static const UNITY_TAP_WEIGHTS: Vector.<Number> = new <Number>[0.05, 0.09, 0.12, 0.15, 0.18, 0.15, 0.12, 0.09, 0.05];
		private static const UNITY_TAP_CONSTANTS: Vector.<String> = new <String>["fc1.x", "fc1.y", "fc1.z", "fc1.w", "fc2.x", "fc1.w", "fc1.z", "fc1.y", "fc1.x"];

		private var mNormalProgram: Program3D;
		private var mTintedProgram: Program3D;
		private var cUserMatrix: Vector.<Number> = new Vector.<Number>(20, true);
		private var cShaderMatrix: Vector.<Number> = new Vector.<Number>(20, true);
		private var cShaderProgram: Program3D;

		private var mOffsets: Vector.<Number> = new <Number>[0, 0, 0, 0];
		private var mWeights: Vector.<Number> = new <Number>[0, 0, 0, 0];
		private var mColor: Vector.<Number> = new <Number>[1, 1, 1, 1];

		private var mBlurX: Number = 0;
		private var mBlurY: Number = 0;
		private var mUniformColor: Boolean;

		private var changeColor: Boolean;

		/** helper object */
		private static var sTmpWeights: Vector.<Number> = new Vector.<Number>(5, true);

		private var _currentScale: Number = 1;
		private var mResolution: Number = 1;

		private var _useUnityPath: Boolean;
		private var _unityMode: int;
		private var _unityBlurX: Number = 0;
		private var _unityBlurY: Number = 0;
		private var _unityStrength: Number = 1;
		private var _unityGlowColor: Vector.<Number> = new <Number>[1, 1, 1, 1];
		private var _unityColorMatrix: Vector.<Number> = new Vector.<Number>(20, true);
		private var _unityTint: Vector.<Number> = new Vector.<Number>(20, true);
		private var _unityStageUnitsPerTexelX: Number = 1;
		private var _unityStageUnitsPerTexelY: Number = 1;
		private var _unityAlpha: Number = 1;
		private var _unityObjectTexture: Texture;
		private var _unityConstants: Vector.<Number> = new Vector.<Number>(64, true);
		private var _unityColorProgram: Program3D;
		private var _unityGlowBlurProgram: Program3D;
		private var _unityGlowFinalProgram: Program3D;
		private var _unityBlurProgram: Program3D;
		private var _unityBlurFinalProgram: Program3D;

		private static var sHelperMatrix: Matrix = new Matrix();

		public function GAFFilter(resolution: Number = 1)
		{
			super(1, resolution);

			this.mode = "test";
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		public function setConfig(cFilter: CFilter, scale: Number): void
		{
			_currentScale = scale;
			_useUnityPath = updateUnityFilters(cFilter);
			if (!_useUnityPath)
			{
				updateFilters(cFilter);
			}
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		// Mirrors the Unity reader: the last Adjust Color plus the last blur/glow, Tint
		// kept apart and applied last. Drop shadow stays on the legacy path.
		private function updateUnityFilters(cFilter: CFilter): Boolean
		{
			var effect: CBlurFilterData;
			var colorMatrix: CColorMatrixFilterData;
			var tint: CColorMatrixFilterData;
			var colorMatrixAfterEffect: Boolean;

			for each (var filterConfig: ICFilterData in cFilter.filterConfigs)
			{
				if (filterConfig is CBlurFilterData)
				{
					effect = filterConfig as CBlurFilterData;
					if (effect.distance != 0)
					{
						return false;
					}
				}
				else if (filterConfig is CColorMatrixFilterData)
				{
					var matrixData: CColorMatrixFilterData = filterConfig as CColorMatrixFilterData;
					if (matrixData.isColorTransform)
					{
						tint = matrixData;
					}
					else
					{
						colorMatrix = matrixData;
						colorMatrixAfterEffect = effect != null;
					}
				}
			}

			VectorUtility.copyMatrix(_unityColorMatrix, colorMatrix ? colorMatrix.matrix : IDENTITY);
			VectorUtility.copyMatrix(_unityTint, tint ? tint.matrix : IDENTITY);

			if (!effect)
			{
				_unityMode = UNITY_MODE_COLOR;
				_unityBlurX = _unityBlurY = 0;
			}
			else
			{
				_unityMode = effect.color > -1 ? UNITY_MODE_GLOW : UNITY_MODE_BLUR;
				_unityBlurX = effect.blurX / UNITY_BLUR_DIVIDER;
				_unityBlurY = effect.blurY / UNITY_BLUR_DIVIDER;
				_unityStrength = effect.strength;
				_unityGlowColor[0] = Color.getRed(effect.color) / 255.0;
				_unityGlowColor[1] = Color.getGreen(effect.color) / 255.0;
				_unityGlowColor[2] = Color.getBlue(effect.color) / 255.0;
				_unityGlowColor[3] = effect.alpha;
				if (colorMatrix && colorMatrixAfterEffect)
				{
					applyColorMatrix(_unityColorMatrix, _unityGlowColor);
				}
			}

			mode = FragmentFilterMode.REPLACE;
			resolution = 1;
			numPasses = _unityMode == UNITY_MODE_COLOR ? 1 : 2;
			offsetX = offsetY = 0;
			return true;
		}

		private static function applyColorMatrix(matrix: Vector.<Number>, rgba: Vector.<Number>): void
		{
			var result: Vector.<Number> = new <Number>[0, 0, 0, 0];
			for (var row: int = 0; row < 4; row++)
			{
				var i: int = row * 5;
				var value: Number = matrix[i] * rgba[0] + matrix[i + 1] * rgba[1] + matrix[i + 2] * rgba[2]
						+ matrix[i + 3] * rgba[3] + matrix[i + 4];
				result[row] = Math.max(0, Math.min(1, value));
			}
			for (var c: int = 0; c < 4; c++)
			{
				rgba[c] = result[c];
			}
		}

		private function updateFilters(cFilter: CFilter): void
		{
			var i: uint;
			var l: uint = cFilter.filterConfigs.length;
			var filterConfig: ICFilterData;

			var blurUpdated: Boolean;
			var ctmUpdated: Boolean;

			mUniformColor = false;

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

		private function resetBlurFilter(): void
		{
			mOffsets[0] = mOffsets[1] = mOffsets[2] = mOffsets[3] = 0;
			mWeights[0] = mWeights[1] = mWeights[2] = mWeights[3] = 0;
			mColor[0] = mColor[1] = mColor[2] = mColor[3] = 1;
			mBlurX = 0;
			mBlurY = 0;
			mResolution = 1;
		}

		private function resetColorMatrixFilter(): void
		{
			VectorUtility.copyMatrix(cUserMatrix, IDENTITY);
			VectorUtility.copyMatrix(cShaderMatrix, IDENTITY);
			changeColor = false;
		}

		private function updateMarginsAndPasses(): void
		{
			if (mBlurX == 0 && mBlurY == 0)
			{
				mBlurX = 0.001;
			}

			numPasses = Math.ceil(mBlurX) + Math.ceil(mBlurY);
			marginX = (3 + Math.ceil(mBlurX)) / resolution + Math.abs(offsetX);
			marginY = (3 + Math.ceil(mBlurY)) / resolution + Math.abs(offsetY);

			if ((mBlurX > 0 || mBlurY > 0) && changeColor)
			{
				numPasses++;
			}
		}

		private function updateBlurFilter(cBlurFilterData: CBlurFilterData): void
		{
			mBlurX = cBlurFilterData.blurX * _currentScale;
			mBlurY = cBlurFilterData.blurY * _currentScale;

			var maxBlur: Number = Math.max(mBlurX, mBlurY);
			//resolution = 1 / Math.sqrt(maxBlur * 0.1);
			if (maxBlur <= 10)
			{
				resolution = 1 + (10 - maxBlur) * 0.1;
			}
			else
			{
				resolution = 1 - maxBlur * 0.01;
			}

			var angleInRadians: Number =  cBlurFilterData.angle * Math.PI / 180;
			offsetX = Math.cos(angleInRadians) * cBlurFilterData.distance * _currentScale;
			offsetY = Math.sin(angleInRadians) * cBlurFilterData.distance * _currentScale;

			setUniformColor((cBlurFilterData.color > -1), cBlurFilterData.color, cBlurFilterData.alpha * cBlurFilterData.strength);
		}

		/** A uniform color will replace the RGB values of the input color, while the alpha
		 *  value will be multiplied with the given factor. Pass <code>false</code> as the
		 *  first parameter to deactivate the uniform color. */
		public function setUniformColor(enable: Boolean, color: uint = 0x0, alpha: Number = 1.0): void
		{
			mColor[0] = Color.getRed(color) / 255.0;
			mColor[1] = Color.getGreen(color) / 255.0;
			mColor[2] = Color.getBlue(color) / 255.0;
			mColor[3] = alpha;
			mUniformColor = enable;
		}

		private function updateColorMatrixFilter(cColorMatrixFilterData: CColorMatrixFilterData): void
		{
			var value: Vector.<Number> = cColorMatrixFilterData.matrix;

			changeColor = false;

			if (value && value.length != 20)
			{
				throw new ArgumentError("Invalid matrix length: must be 20");
			}

			if (value == null)
			{
				VectorUtility.copyMatrix(cUserMatrix, IDENTITY);
			}
			else
			{
				changeColor = true;
				VectorUtility.copyMatrix(cUserMatrix, value);
			}

			updateShaderMatrix();
		}

		private function updateShaderMatrix(): void
		{
			// the shader needs the matrix components in a different order,
			// and it needs the offsets in the range 0-1.

			VectorUtility.fillMatrix(cShaderMatrix, cUserMatrix[0], cUserMatrix[1], cUserMatrix[2], cUserMatrix[3],
					cUserMatrix[5], cUserMatrix[6], cUserMatrix[7], cUserMatrix[8],
					cUserMatrix[10], cUserMatrix[11], cUserMatrix[12], cUserMatrix[13],
					cUserMatrix[15], cUserMatrix[16], cUserMatrix[17], cUserMatrix[18],
					cUserMatrix[4], cUserMatrix[9], cUserMatrix[14],
					cUserMatrix[19]);
		}

		/** @private */
		protected override function activate(pass: int, context: Context3D, texture: Texture): void
		{
			if (_useUnityPath)
			{
				activateUnity(pass, context, texture);
				return;
			}

			if (pass == numPasses - 1 && changeColor) //color transform filter
			{
				if (mode != FragmentFilterMode.REPLACE)
				{
					mode = FragmentFilterMode.REPLACE;
				}
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, cShaderMatrix);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 5, MIN_COLOR);
				context.setProgram(cShaderProgram);
			}
			else //blur, drop shadow or glow
			{
				if (mUniformColor)
				{
					mode = FragmentFilterMode.BELOW;
				}
				else
				{
					mode = FragmentFilterMode.REPLACE;
				}
				updateParameters(pass, texture.nativeWidth, texture.nativeHeight);

				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, mOffsets);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, mWeights);

				if (changeColor)
				{
					if (pass == numPasses - 2 && mUniformColor)
					{
						context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, mColor);
						context.setProgram(mTintedProgram);
					}
					else
					{
						context.setProgram(mNormalProgram);
					}
				}
				if (pass == numPasses - 1 && mUniformColor)
				{
					context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, mColor);
					context.setProgram(mTintedProgram);
				}
				else
				{
					context.setProgram(mNormalProgram);
				}
			}
		}

		// Fragment constants of the Unity programs:
		// fc0 step (uv), fc1-fc2.x tap weights, fc2.y 4, fc2.z 1, fc3 glow color,
		// fc4.x strength, fc4.y object alpha, fc5-fc8 + fc9 Adjust Color,
		// fc10-fc13 + fc14 Tint, fc15 minimal color used to un-premultiply.
		private function activateUnity(pass: int, context: Context3D, texture: Texture): void
		{
			if (pass == 0)
			{
				_unityObjectTexture = texture;
			}

			var pixelsPerStageUnit: Number = resolution * Starling.current.contentScaleFactor;
			var c: Vector.<Number> = _unityConstants;
			var horizontal: Boolean = pass == 0;
			c[0] = horizontal ? _unityBlurX * _unityStageUnitsPerTexelX * pixelsPerStageUnit / texture.nativeWidth : 0;
			c[1] = horizontal ? 0 : _unityBlurY * _unityStageUnitsPerTexelY * pixelsPerStageUnit / texture.nativeHeight;
			c[2] = c[3] = 0;
			c[4] = UNITY_TAP_WEIGHTS[0]; c[5] = UNITY_TAP_WEIGHTS[1]; c[6] = UNITY_TAP_WEIGHTS[2]; c[7] = UNITY_TAP_WEIGHTS[3];
			c[8] = UNITY_TAP_WEIGHTS[4]; c[9] = 4; c[10] = 1; c[11] = 0;
			c[12] = _unityGlowColor[0]; c[13] = _unityGlowColor[1]; c[14] = _unityGlowColor[2]; c[15] = _unityGlowColor[3];
			c[16] = _unityStrength; c[17] = _unityAlpha; c[18] = 0; c[19] = 0;
			writeMatrixConstants(_unityColorMatrix, c, 20);
			writeMatrixConstants(_unityTint, c, 40);
			c[60] = 0; c[61] = 0; c[62] = 0; c[63] = 0.0001;
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, c);

			var finalPass: Boolean = pass == numPasses - 1;
			if (_unityMode == UNITY_MODE_COLOR)
			{
				context.setProgram(_unityColorProgram);
			}
			else if (!finalPass)
			{
				context.setProgram(_unityMode == UNITY_MODE_GLOW ? _unityGlowBlurProgram : _unityBlurProgram);
			}
			else if (_unityMode == UNITY_MODE_GLOW)
			{
				context.setTextureAt(1, _unityObjectTexture.base);
				context.setProgram(_unityGlowFinalProgram);
			}
			else
			{
				context.setProgram(_unityBlurFinalProgram);
			}
		}

		// Row-major 4x5 color matrix -> 4 rows for m44, then the offset row.
		private static function writeMatrixConstants(matrix: Vector.<Number>, out: Vector.<Number>, start: int): void
		{
			for (var row: int = 0; row < 4; row++)
			{
				for (var column: int = 0; column < 4; column++)
				{
					out[start + row * 4 + column] = matrix[row * 5 + column];
				}
				out[start + 16 + row] = matrix[row * 5 + 4];
			}
		}

		/** @private */
		protected override function deactivate(pass: int, context: Context3D, texture: Texture): void
		{
			if (_useUnityPath && _unityMode == UNITY_MODE_GLOW && pass == numPasses - 1)
			{
				context.setTextureAt(1, null);
			}
		}

		override public function render(object: DisplayObject, support: RenderSupport, parentAlpha: Number): void
		{
			if (!_useUnityPath)
			{
				super.render(object, support, parentAlpha);
				return;
			}

			// Unity blurs in atlas texels and applies the object alpha after the filter.
			object.getTransformationMatrix(object.stage, sHelperMatrix);
			var scaleX: Number = Math.sqrt(sHelperMatrix.a * sHelperMatrix.a + sHelperMatrix.b * sHelperMatrix.b);
			var scaleY: Number = Math.sqrt(sHelperMatrix.c * sHelperMatrix.c + sHelperMatrix.d * sHelperMatrix.d);
			var image: Image = object as Image;
			var textureScale: Number = image && image.texture ? image.texture.scale : 1;
			_unityStageUnitsPerTexelX = scaleX / textureScale;
			_unityStageUnitsPerTexelY = scaleY / textureScale;
			marginX = Math.ceil(UNITY_KERNEL_SIZE * 0.5 * _unityBlurX * _unityStageUnitsPerTexelX) + 2;
			marginY = Math.ceil(UNITY_KERNEL_SIZE * 0.5 * _unityBlurY * _unityStageUnitsPerTexelY) + 2;

			var objectAlpha: Number = object.alpha;
			_unityAlpha = objectAlpha * parentAlpha;
			object.alpha = 1;
			super.render(object, support, 1);
			object.alpha = objectAlpha;
		}

		/** @private */
		protected override function createPrograms(): void
		{
			mNormalProgram = createProgram(false);
			mTintedProgram = createProgram(true);
			cShaderProgram = createCProgram();
			createUnityPrograms();
		}

		private function createUnityPrograms(): void
		{
			var unpremultiplyAndAdjust: String =
					"max ft4, ft4, fc15             \n" +
					"div ft4.xyz, ft4.xyz, ft4.www  \n" +
					"m44 ft5, ft4, fc5              \n" + // Adjust Color
					"add ft5, ft5, fc9              \n" +
					"sat ft4, ft5                   \n";
			var tintAndOutput: String =
					"m44 ft7, ft6, fc10             \n" + // Tint, applied last as in Unity
					"add ft7, ft7, fc14             \n" +
					"sat ft7, ft7                   \n" +
					"mul ft7.w, ft7.w, fc4.y        \n" + // object alpha
					"mul ft7.xyz, ft7.xyz, ft7.www  \n" + // premultiply
					"mov oc, ft7                    \n";

			_unityColorProgram = registerUnityProgram(UNITY_COLOR_PROGRAM_NAME,
					"tex ft4, v0, fs0 <2d, clamp, linear, mipnone> \n" +
					unpremultiplyAndAdjust +
					"mov ft6, ft4                   \n" +
					tintAndOutput);

			// Glow: blurred alpha, then the adjusted object over the glow color.
			_unityGlowBlurProgram = registerUnityProgram(UNITY_GLOW_BLUR_PROGRAM_NAME,
					blurTaps(true) +
					"mov oc, ft3                    \n");

			_unityGlowFinalProgram = registerUnityProgram(UNITY_GLOW_FINAL_PROGRAM_NAME,
					blurTaps(true) +
					"mul ft3.w, ft3.w, fc4.x        \n" + // strength
					"sat ft3.w, ft3.w               \n" +
					"mul ft3.w, ft3.w, fc3.w        \n" + // glow alpha
					"tex ft4, v0, fs1 <2d, clamp, linear, mipnone> \n" +
					unpremultiplyAndAdjust +
					"sub ft5.w, fc2.z, ft4.w        \n" + // 1 - object alpha
					"mul ft6.xyz, ft4.xyz, ft4.www  \n" + // rgb: object over glow (SrcAlpha, OneMinusSrcAlpha)
					"mul ft1.xyz, fc3.xyz, ft5.www  \n" +
					"add ft6.xyz, ft6.xyz, ft1.xyz  \n" +
					"mul ft6.w, ft3.w, ft5.w        \n" + // alpha: One, OneMinusSrcAlpha
					"add ft6.w, ft6.w, ft4.w        \n" +
					tintAndOutput);

			_unityBlurProgram = registerUnityProgram(UNITY_BLUR_PROGRAM_NAME,
					blurTaps(false) +
					"mov oc, ft3                    \n");

			_unityBlurFinalProgram = registerUnityProgram(UNITY_BLUR_FINAL_PROGRAM_NAME,
					blurTaps(false) +
					"mov ft4, ft3                   \n" +
					unpremultiplyAndAdjust +
					"mov ft6, ft4                   \n" +
					tintAndOutput);
		}

		// 9-tap kernel of the Unity GAFBlur/GAFGlow shaders along fc0.xy, summed into ft3.
		private static function blurTaps(alphaOnly: Boolean): String
		{
			var code: String =
					"mov ft0, v0                    \n" +
					"mov ft1, fc0                   \n" + // AGAL forbids two constant operands
					"mul ft1, ft1, fc2.yyyy         \n" +
					"sub ft0.xy, ft0.xy, ft1.xy     \n";
			for (var i: int = 0; i < UNITY_TAP_CONSTANTS.length; i++)
			{
				var weight: String = UNITY_TAP_CONSTANTS[i];
				if (i > 0)
				{
					code += "add ft0.xy, ft0.xy, fc0.xy     \n";
				}
				code += "tex ft2, ft0, fs0 <2d, clamp, linear, mipnone> \n";
				if (alphaOnly)
				{
					code += "mul ft2, ft2.wwww, " + weight + "\n";
				}
				else
				{
					code += "mul ft2, ft2, " + weight + "\n";
				}
				code += i == 0 ? "mov ft3, ft2                   \n" : "add ft3, ft3, ft2              \n";
			}
			return code;
		}

		private function registerUnityProgram(programName: String, fragmentProgramCode: String): Program3D
		{
			var target: Starling = Starling.current;
			if (target.hasProgram(programName))
			{
				return target.getProgram(programName);
			}
			return target.registerProgramFromSource(programName, STD_VERTEX_SHADER, fragmentProgramCode);
		}

		private function createProgram(tinted: Boolean): Program3D
		{
			var programName: String = tinted ? TINTED_PROGRAM_NAME : NORMAL_PROGRAM_NAME;
			var target: Starling = Starling.current;

			if (target.hasProgram(programName))
			{
				return target.getProgram(programName);
			}

			// vc0-3 - mvp matrix
			// vc4   - kernel offset
			// va0   - position
			// va1   - texture coords

			var vertexProgramCode: String =
					"m44 op, va0, vc0       \n" + // 4x4 matrix transform to output space
					"mov v0, va1            \n" + // pos:  0 |
					"sub v1, va1, vc4.zwxx  \n" + // pos: -2 |
					"sub v2, va1, vc4.xyxx  \n" + // pos: -1 | --> kernel positions
					"add v3, va1, vc4.xyxx  \n" + // pos: +1 |     (only 1st two parts are relevant)
					"add v4, va1, vc4.zwxx  \n";  // pos: +2 |

			// v0-v4 - kernel position
			// fs0   - input texture
			// fc0   - weight data
			// fc1   - color (optional)
			// ft0-4 - pixel color from texture
			// ft5   - output color

			var fragmentProgramCode: String =
					"tex ft0,  v0, fs0 <2d, clamp, linear, mipnone> \n" +  // read center pixel
					"mul ft5, ft0, fc0.xxxx                         \n" +  // multiply with center weight

					"tex ft1,  v1, fs0 <2d, clamp, linear, mipnone> \n" +  // read pixel -2
					"mul ft1, ft1, fc0.zzzz                         \n" +  // multiply with weight
					"add ft5, ft5, ft1                              \n" +  // add to output color

					"tex ft2,  v2, fs0 <2d, clamp, linear, mipnone> \n" +  // read pixel -1
					"mul ft2, ft2, fc0.yyyy                         \n" +  // multiply with weight
					"add ft5, ft5, ft2                              \n" +  // add to output color

					"tex ft3,  v3, fs0 <2d, clamp, linear, mipnone> \n" +  // read pixel +1
					"mul ft3, ft3, fc0.yyyy                         \n" +  // multiply with weight
					"add ft5, ft5, ft3                              \n" +  // add to output color

					"tex ft4,  v4, fs0 <2d, clamp, linear, mipnone> \n" +  // read pixel +2
					"mul ft4, ft4, fc0.zzzz                         \n";   // multiply with weight

			if (tinted)
			{
				fragmentProgramCode +=
						"add ft5, ft5, ft4                          \n" + // add to output color
						"mul ft5.xyz, fc1.xyz, ft5.www              \n" + // set rgb with correct alpha
						"mul oc, ft5, fc1.wwww                      \n";  // multiply alpha
			}

			else
			{
				fragmentProgramCode +=
						"add  oc, ft5, ft4                          \n";  // add to output color
			}

			return target.registerProgramFromSource(programName, vertexProgramCode, fragmentProgramCode);
		}

		private function createCProgram(): Program3D
		{
			var programName: String = COLOR_TRANSFORM_PROGRAM_NAME;
			var target: Starling = Starling.current;

			if (target.hasProgram(programName))
			{
				return target.getProgram(programName);
			}

			// fc0-3: matrix
			// fc4:   offset
			// fc5:   minimal allowed color value

			var fragmentProgramCode: String =
					"tex ft0, v0,  fs0 <2d, clamp, linear, mipnone>  \n" + // read texture color
					"max ft0, ft0, fc5              \n" + // avoid division through zero in next step
					"div ft0.xyz, ft0.xyz, ft0.www  \n" + // restore original (non-PMA) RGB values
					"m44 ft0, ft0, fc0              \n" + // multiply color with 4x4 matrix
					"add ft0, ft0, fc4              \n" + // add offset
					"mul ft0.xyz, ft0.xyz, ft0.www  \n" + // multiply with alpha again (PMA)
					"mov oc, ft0                    \n";  // copy to output

			return target.registerProgramFromSource(programName, STD_VERTEX_SHADER, fragmentProgramCode);
		}

		private function updateParameters(pass: int, textureWidth: int, textureHeight: int): void
		{
			// algorithm described here:
			// http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
			//
			// To run in constrained mode, we can only make 5 texture lookups in the fragment
			// shader. By making use of linear texture sampling, we can produce similar output
			// to what would be 9 lookups.

			var sigma: Number;
			var horizontal: Boolean = pass < mBlurX;
			var pixelSize: Number;

			if (horizontal)
			{
				sigma = Math.min(1.0, mBlurX - pass) * MAX_SIGMA;
				pixelSize = 1.0 / textureWidth;
			}
			else
			{
				sigma = Math.min(1.0, mBlurY - (pass - Math.ceil(mBlurX))) * MAX_SIGMA;
				pixelSize = 1.0 / textureHeight;
			}

			const twoSigmaSq: Number = 2 * sigma * sigma;
			const multiplier: Number = 1.0 / Math.sqrt(twoSigmaSq * Math.PI);

			// get weights on the exact pixels (sTmpWeights) and calculate sums (mWeights)

			for (var i: int = 0; i < 5; ++i)
			{
				sTmpWeights[i] = multiplier * Math.exp(-i * i / twoSigmaSq);
			}

			mWeights[0] = sTmpWeights[0];
			mWeights[1] = sTmpWeights[1] + sTmpWeights[2];
			mWeights[2] = sTmpWeights[3] + sTmpWeights[4];

			// normalize weights so that sum equals "1.0"

			var weightSum: Number = mWeights[0] + 2 * mWeights[1] + 2 * mWeights[2];
			var invWeightSum: Number = 1.0 / weightSum;

			mWeights[0] *= invWeightSum;
			mWeights[1] *= invWeightSum;
			mWeights[2] *= invWeightSum;

			// calculate intermediate offsets

			var offset1: Number = (  pixelSize * sTmpWeights[1] + 2 * pixelSize * sTmpWeights[2]) / mWeights[1];
			var offset2: Number = (3 * pixelSize * sTmpWeights[3] + 4 * pixelSize * sTmpWeights[4]) / mWeights[2];

			// depending on pass, we move in x- or y-direction

			if (horizontal)
			{
				mOffsets[0] = offset1;
				mOffsets[1] = 0;
				mOffsets[2] = offset2;
				mOffsets[3] = 0;
			}
			else
			{
				mOffsets[0] = 0;
				mOffsets[1] = offset1;
				mOffsets[2] = 0;
				mOffsets[3] = offset2;
			}
		}

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

	}
}
