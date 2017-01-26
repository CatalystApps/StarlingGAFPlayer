/**
 * Created by Roman Lipovskiy on 18.01.2017.
 */
package
{
    import flash.geom.Rectangle;
    import starling.core.Starling;
    import flash.display.Sprite;

    [SWF(backgroundColor="#FFFFFF", frameRate="60", width="432", height="768")]
    public class AnimatedFiltersMain extends Sprite
    {
        private var _starling: Starling;

        public function AnimatedFiltersMain()
        {
            _starling = new Starling( AnimatedFiltersDemo , stage, new Rectangle(0, 0, 432, 768));
            _starling.showStats = true;
            _starling.start();
        }
    }
}
