/**
 * Created by Roman Lipovskiy on 16.01.2017.
 */
package com.catalystapps.gaf.filter.masks
{

    import starling.display.Mesh;
    import starling.rendering.MeshEffect;
    import starling.rendering.VertexDataFormat;
    import starling.styles.MeshStyle;

    public class GAFStencilMaskStyle extends MeshStyle
    {
            public static const VERTEX_FORMAT:VertexDataFormat = MeshStyle.VERTEX_FORMAT.extend("threshold:float1");

            private var _threshold:Number;

            public function GAFStencilMaskStyle(threshold:Number = 0.5)
            {
                _threshold = threshold;
            }

            override public function copyFrom(meshStyle:MeshStyle):void
            {
                var otherStyle:GAFStencilMaskStyle = meshStyle as GAFStencilMaskStyle;
                if (otherStyle) _threshold = otherStyle._threshold;

                super.copyFrom(meshStyle);
            }

            override public function createEffect():MeshEffect
            {
                return new GAFStencilMaskStyleEffect();
            }

            override public function get vertexFormat():VertexDataFormat
            {
                return VERTEX_FORMAT;
            }

            override protected function onTargetAssigned(target:Mesh):void
            {
                updateVertices();
            }

            private function updateVertices():void
            {
                var numVertices:int = vertexData.numVertices;
                for (var i:int = 0; i < numVertices; ++i)
                {
                    vertexData.setFloat(i, "threshold", _threshold);
                }

                setRequiresRedraw();
            }

            // properties

            public function get threshold():Number
            {
                return _threshold;
            }

            public function set threshold(value:Number):void
            {
                if (_threshold != value && target)
                {
                    _threshold = value;
                    updateVertices();
                }
            }
        }
}



