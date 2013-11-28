package
{
	import flash.geom.Rectangle;
	import starling.core.Starling;
	import flash.display.Sprite;

	/**
	 * @author mitvad
	 */
	public class BundleMain extends Sprite
	{
		private var _starling: Starling;
		
		public function BundleMain()
		{
			_starling = new Starling(BundleGame, stage, new Rectangle(0, 0, 700, 600));
			_starling.showStats = true;
       		_starling.start();
		}
	}
}
