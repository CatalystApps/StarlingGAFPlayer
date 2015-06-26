package
{
	import starling.core.Starling;

	import flash.display.Sprite;
	import flash.geom.Rectangle;

	[SWF(backgroundColor="#FFFFFF", frameRate="60", width="1024", height="768")]
	public class GunSwapMain extends Sprite
	{
		private var _starling: Starling;

		public function GunSwapMain()
		{
			_starling = new Starling(GunSwapStarling, stage, new Rectangle(0, 0, 1024, 768));
			_starling.showStats = true;
			_starling.start();
		}
	}
}
