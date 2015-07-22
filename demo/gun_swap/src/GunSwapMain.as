package
{
	import starling.core.Starling;

	import flash.display.Sprite;
	import flash.geom.Rectangle;

	[SWF(backgroundColor="#999999", frameRate="60", width="800", height="600")]
	public class GunSwapMain extends Sprite
	{
		private var _starling: Starling;

		public function GunSwapMain()
		{
			_starling = new Starling(GunSwapStarling, stage, new Rectangle(0, 0, 800, 600));
			_starling.showStats = true;
			_starling.start();
		}
	}
}
