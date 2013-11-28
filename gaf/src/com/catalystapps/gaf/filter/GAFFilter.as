package com.catalystapps.gaf.filter
{
	import starling.filters.FragmentFilter;
	import starling.textures.Texture;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;

	/**
	 * @author p0d04Va
	 */
	public class GAFFilter extends FragmentFilter
	{
		private const MAX_SIGMA: Number = 2.0;
        private static const IDENTITY: Array = [1,0,0,0,0,  0,1,0,0,0,  0,0,1,0,0,  0,0,0,1,0];
		private static const MIN_COLOR: Vector.<Number> = new <Number>[0, 0, 0, 0.0001];
		 
        private var mNormalProgram: Program3D;
		private var cUserMatrix: Vector.<Number> = new Vector.<Number>();
        private var cShaderMatrix: Vector.<Number> = new Vector.<Number>();
		private var cShaderProgram: Program3D;
                
        private var mOffsets: Vector.<Number> = new <Number>[0, 0, 0, 0];
        private var mWeights: Vector.<Number> = new <Number>[0, 0, 0, 0];
       	        
        private var mBlurX: Number = 0;
        private var mBlurY: Number = 0;
				
		private var changeColor: Boolean;
                
        /** helper object */
        private var sTmpWeights:Vector.<Number> = new Vector.<Number>(5, true);
        
        /** Create a new BlurFilter. For each blur direction, the number of required passes is
         *  <code>Math.ceil(blur)</code>. 
         *  
         *  <ul><li>blur = 0.5: 1 pass</li>  
         *      <li>blur = 1.0: 1 pass</li>
         *      <li>blur = 1.5: 2 passes</li>
         *      <li>blur = 2.0: 2 passes</li>
         *      <li>etc.</li>
         *  </ul>
         *  
         *  <p>Instead of raising the number of passes, you should consider lowering the resolution.
         *  A lower resolution will result in a blurrier image, while reducing the rendering
         *  cost.</p>
         */
        public function GAFFilter(resolution:Number=1)
        {
            super(1, resolution);
        }      
        
		public function setBlurFilter(params: Vector.<Number>, scale: Number): void
		{
			if (params && params.length != 2)
			{
                throw new ArgumentError("Invalid matrix length: must be 2");
			}
			
			mBlurX = params[0] * scale;
			mBlurY = params[1] * scale;
			
			updateMarginsAndPasses();
		}
		
		public function setColorTransformFilter(value:Vector.<Number>):void
        {
			cUserMatrix = new Vector.<Number>();
			cShaderMatrix = new Vector.<Number>();
			changeColor = false;
			
            if (value && value.length != 20) 
                throw new ArgumentError("Invalid matrix length: must be 20");
            
            if (value == null)
            {
				cUserMatrix.length = 0;
                cUserMatrix.push.apply(cUserMatrix, IDENTITY);
            }
            else
            {
				changeColor = true;
                copyMatrix(value, cUserMatrix);
            }
            
            updateShaderMatrix();
			updateMarginsAndPasses();
        }
		
        /** @inheritDoc */
        public override function dispose():void
        {
            if (mNormalProgram) mNormalProgram.dispose();
			if (cShaderProgram) cShaderProgram.dispose();
                        
            super.dispose();
        }
        
        /** @private */
        protected override function createPrograms():void
        {
            mNormalProgram = createProgram(); 
			cShaderProgram = createCProgram();           
		}		
        
        private function createProgram():Program3D
        {
            // vc0-3 - mvp matrix
            // vc4   - kernel offset
            // va0   - position 
            // va1   - texture coords
            
            var vertexProgramCode:String =
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
            
            var fragmentProgramCode:String =
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

//            if (tinted) fragmentProgramCode +=
//                "add ft5, ft5, ft4                              \n" + // add to output color
//                "mul ft5.xyz, fc1.xyz, ft5.www                  \n" + // set rgb with correct alpha
//                "mul oc, ft5, fc1.wwww                          \n";  // multiply alpha
            
           // else 
           	  fragmentProgramCode +=
                "add  oc, ft5, ft4                              \n";   // add to output color
            
            return assembleAgal(fragmentProgramCode, vertexProgramCode);
        }
		
		private function createCProgram() : Program3D
		{
			// fc0-3: matrix
            // fc4:   offset
            // fc5:   minimal allowed color value
            
            var fragmentProgramCode:String =
                "tex ft0, v0,  fs0 <2d, clamp, linear, mipnone>  \n" + // read texture color
                "max ft0, ft0, fc5              \n" + // avoid division through zero in next step
                "div ft0.xyz, ft0.xyz, ft0.www  \n" + // restore original (non-PMA) RGB values
                "m44 ft0, ft0, fc0              \n" + // multiply color with 4x4 matrix
                "add ft0, ft0, fc4              \n" + // add offset
                "mul ft0.xyz, ft0.xyz, ft0.www  \n" + // multiply with alpha again (PMA)
                "mov oc, ft0                    \n";  // copy to output
            
           	return assembleAgal(fragmentProgramCode);			
		}
        
        /** @private */
        protected override function activate(pass:int, context:Context3D, texture:Texture):void
        {
			if (pass == numPasses - 1 && changeColor)
			{
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, cShaderMatrix);
            	context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 5, MIN_COLOR);
            	context.setProgram(cShaderProgram);
			}
			else
			{			
	            // already set by super class:
	            // 
	            // vertex constants 0-3: mvpMatrix (3D)
	            // vertex attribute 0:   vertex position (FLOAT_2)
	            // vertex attribute 1:   texture coordinates (FLOAT_2)
	            // texture 0:            input texture
	            
	            updateParameters(pass, texture.nativeWidth, texture.nativeHeight);
	            
	            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX,   4, mOffsets);
	            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, mWeights);
	            
	            context.setProgram(mNormalProgram); 
			}		          
        }
        
        private function updateParameters(pass:int, textureWidth:int, textureHeight:int):void
        {
            // algorithm described here: 
            // http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
            // 
            // To run in constrained mode, we can only make 5 texture lookups in the fragment
            // shader. By making use of linear texture sampling, we can produce similar output
            // to what would be 9 lookups.
            
            var sigma:Number;
            var horizontal:Boolean = pass < mBlurX;
            var pixelSize:Number;
            
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
            
            const twoSigmaSq:Number = 2 * sigma * sigma; 
            const multiplier:Number = 1.0 / Math.sqrt(twoSigmaSq * Math.PI);
            
            // get weights on the exact pixels (sTmpWeights) and calculate sums (mWeights)
            
            for (var i:int=0; i<5; ++i)
                sTmpWeights[i] = multiplier * Math.exp(-i*i / twoSigmaSq);
            
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
        
        private function updateMarginsAndPasses():void
        {
            if (mBlurX == 0 && mBlurY == 0) mBlurX = 0.001;
            
            numPasses = Math.ceil(mBlurX) + Math.ceil(mBlurY);
            marginX = 4 + Math.ceil(mBlurX);
            marginY = 4 + Math.ceil(mBlurY); 
						
			if ((mBlurX > 0 || mBlurY > 0) && changeColor)
			{
				numPasses++;
			}			
        }
        
		private function copyMatrix(from:Vector.<Number>, to:Vector.<Number>):void
        {
            for (var i:int=0; i<20; ++i)
                to[i] = from[i];
        }
        
        private function updateShaderMatrix():void
        {
            // the shader needs the matrix components in a different order, 
            // and it needs the offsets in the range 0-1.
            
            cShaderMatrix.length = 0;
            cShaderMatrix.push(
                cUserMatrix[0],  cUserMatrix[1],  cUserMatrix[2],  cUserMatrix[3],
                cUserMatrix[5],  cUserMatrix[6],  cUserMatrix[7],  cUserMatrix[8],
                cUserMatrix[10], cUserMatrix[11], cUserMatrix[12], cUserMatrix[13], 
                cUserMatrix[15], cUserMatrix[16], cUserMatrix[17], cUserMatrix[18],
                cUserMatrix[4],  cUserMatrix[9],  cUserMatrix[14],  
                cUserMatrix[19]
            );
        }
    }
}
