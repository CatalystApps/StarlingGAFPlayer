/**
 * Created by Roman Lipovskiy on 12.12.2016.
 */
package com.catalystapps.gaf.filter {
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Program3D;

import starling.core.Starling;

import starling.rendering.FilterEffect;
import starling.rendering.Program;
import starling.utils.MathUtil;

public class GAFFilterEffect extends FilterEffect
{
    private static const NORMAL_PROGRAM_NAME: String = "BF_n";
    private static const TINTED_PROGRAM_NAME: String = "BF_t";
    private static const COLOR_TRANSFORM_PROGRAM_NAME: String = "CMF";

    public static const HORIZONTAL:String = "horizontal";
    public static const VERTICAL:String = "vertical";

    private static const MIN_COLOR: Vector.<Number> = new <Number>[0, 0, 0, 0.0001];
    private const MAX_SIGMA: Number = 2.0;

    private var mNormalProgram: Program;
    private var mTintedProgram: Program;
    private var cShaderProgram: Program;

    /** helper object */
    private static var sTmpWeights: Vector.<Number> = new Vector.<Number>(5, true);

    private var _cUserMatrix: Vector.<Number> = new Vector.<Number>(20, true);
    private var _cShaderMatrix: Vector.<Number> = new Vector.<Number>(20, true);

    private var _strength:Number;
    private var _direction:String;

    private var _mOffsets: Vector.<Number> = new <Number>[0, 0, 0, 0];
    private var _mWeights: Vector.<Number> = new <Number>[0, 0, 0, 0];
    private var _mColor: Vector.<Number> = new <Number>[1, 1, 1, 1];

    private var _mBlurX: Number = 0;
    private var _mBlurY: Number = 0;
    private var _mUniformColor: Boolean;

    private var _changeColor:Boolean;

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
    public function GAFFilterEffect()
    {

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
    private function createCustomProgram(tinted: Boolean): Program
    {
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

        return Program.fromSource(vertexProgramCode, fragmentProgramCode);
    }

    private function createCProgram(): Program
    {
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

        return Program.fromSource(STD_VERTEX_SHADER, fragmentProgramCode);
    }

    private function updateParameters():void
    {
        // algorithm described here:
        // http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
        //
        // To run in constrained mode, we can only make 5 texture look-ups in the fragment
        // shader. By making use of linear texture sampling, we can produce similar output
        // to what would be 9 look-ups.

        var sigma:Number;
        var pixelSize:Number;

        if (_direction == HORIZONTAL)
        {
            sigma = _strength * MAX_SIGMA;
            pixelSize = 1.0 / texture.root.width;
        }
        else
        {
            sigma = _strength * MAX_SIGMA;
            pixelSize = 1.0 / texture.root.height;
        }

        const twoSigmaSq:Number = 2 * sigma * sigma;
        const multiplier:Number = 1.0 / Math.sqrt(twoSigmaSq * Math.PI);

        // get weights on the exact pixels (sTmpWeights) and calculate sums (_weights)

        for (var i:int = 0; i < 5; ++i)
        {
            sTmpWeights[i] = multiplier * Math.exp(-i*i / twoSigmaSq);
        }

        mWeights[0] = sTmpWeights[0];
        mWeights[1] = sTmpWeights[1] + sTmpWeights[2];
        mWeights[2] = sTmpWeights[3] + sTmpWeights[4];

        // normalize weights so that sum equals "1.0"

        var weightSum:Number = mWeights[0] + 2*mWeights[1] + 2*mWeights[2];
        var invWeightSum:Number = 1.0 / weightSum;

        mWeights[0] *= invWeightSum;
        mWeights[1] *= invWeightSum;
        mWeights[2] *= invWeightSum;

        // calculate intermediate offsets

        var offset1:Number = (  pixelSize * sTmpWeights[1] + 2*pixelSize * sTmpWeights[2]) / mWeights[1];
        var offset2:Number = (3*pixelSize * sTmpWeights[3] + 4*pixelSize * sTmpWeights[4]) / mWeights[2];

        // depending on pass, we move in x- or y-direction

        if (_direction == HORIZONTAL)
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
    override protected function createProgram():Program
    {
        mNormalProgram = createCustomProgram(false);
        mTintedProgram = createCustomProgram(true);
        cShaderProgram = createCProgram();

        //TODO RECREATE THIS SHIT
        return mNormalProgram;
    }

    override protected function beforeDraw(context:Context3D):void
    {
        super.beforeDraw(context);


        if (/*pass == numPasses - 1 &&*/ _changeColor) //color transform filter
        {
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _cShaderMatrix);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 5, MIN_COLOR);
//            context.setProgram(cShaderProgram);
        }
        else //blur, drop shadow or glow
        {
            updateParameters();

            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _mOffsets);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _mWeights);

            if (_changeColor)
            {
                if (/*pass == numPasses - 2 &&*/ _mUniformColor)
                {
                    context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _mColor);
                    context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _mColor);
//                    context.setProgram(mTintedProgram);
                }
                else
                {
//                    context.setProgram(mNormalProgram);
                }
            }
            if (/*pass == numPasses - 1 &&*/ _mUniformColor)
            {
                context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _mColor);
//                context.setProgram(mTintedProgram);
            }
            else
            {
//                context.setProgram(mNormalProgram);
            }
        }
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

    public function get mColor():Vector.<Number> { return _mColor; }
    public function set mColor(value:Vector.<Number>):void { _mColor = value; }

    public function get mOffsets():Vector.<Number> { return _mOffsets; }
    public function set mOffsets(value:Vector.<Number>):void { _mOffsets = value; }

    public function get mWeights():Vector.<Number> { return _mWeights; }
    public function set mWeights(value:Vector.<Number>):void { _mWeights = value; }

    public function get mBlurX():Number { return _mBlurX; }
    public function set mBlurX(value:Number):void { _mBlurX = value; }

    public function get mBlurY():Number { return _mBlurY; }
    public function set mBlurY(value:Number):void { _mBlurY = value; }

    public function get mUniformColor():Boolean { return _mUniformColor; }
    public function set mUniformColor(value:Boolean):void { _mUniformColor = value; }

    public function get changeColor():Boolean { return _changeColor; }

    public function set changeColor(value:Boolean):void { _changeColor = value; }

    public function get cUserMatrix():Vector.<Number> { return _cUserMatrix; }

    public function set cUserMatrix(value:Vector.<Number>):void { _cUserMatrix = value; }

    public function get cShaderMatrix():Vector.<Number> { return _cShaderMatrix; }

    public function set cShaderMatrix(value:Vector.<Number>):void { _cShaderMatrix = value; }

    public function get direction():String { return _direction; }
    public function set direction(value:String):void { _direction = value; }

    public function get strength():Number { return _strength; }
    public function set strength(value:Number):void
    {
        _strength = MathUtil.clamp(value, 0, 1);
    }
}
}
