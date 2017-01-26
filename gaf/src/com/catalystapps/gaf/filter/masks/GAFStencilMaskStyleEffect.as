/**
 * Created by Roman Lipovskiy on 16.01.2017.
 */
package com.catalystapps.gaf.filter.masks
{
    import flash.display3D.Context3D;

    import starling.rendering.MeshEffect;
    import starling.rendering.Program;
    import starling.rendering.VertexDataFormat;

    class GAFStencilMaskStyleEffect extends MeshEffect
    {
        public static const VERTEX_FORMAT:VertexDataFormat = GAFStencilMaskStyle.VERTEX_FORMAT;

        public function GAFStencilMaskStyleEffect()
        {
        }

        override protected function createProgram():Program
        {
            if (texture)
            {
                var vertexShader:String = [
                    "m44 op, va0, vc0", // 4x4 matrix transform to output clip-space
                    "mov v0, va1     ", // pass texture coordinates to fragment program
                    "mul v1, va2, vc4", // multiply alpha (vc4) with color (va2), pass to fp
                    "mov v2, va3     "  // pass threshold to fp
                ].join("\n");

                var fragmentShader:String = [
                    tex("ft0", "v0", 0, texture),
                    "sub ft1, ft0, v2.xxxx", // subtract threshold
                    "kil ft1.w            ", // abort if alpha < 0
                    "mul  oc, ft0, v1     "  // else multiply with color & copy to output buffer
                ].join("\n");

                return Program.fromSource(vertexShader, fragmentShader);
            }
            else
            {
                return super.createProgram();
            }
        }

        override protected function beforeDraw(context:Context3D):void
        {
            super.beforeDraw(context);
            if (texture)
            {
                vertexFormat.setVertexBufferAt(3, vertexBuffer, "threshold");
            }
        }

        override protected function afterDraw(context:Context3D):void
        {
            if (texture)
            {
                context.setVertexBufferAt(3, null);
            }
            super.afterDraw(context);
        }

        override public function get vertexFormat():VertexDataFormat
        {
            return VERTEX_FORMAT;
        }

    }
}
