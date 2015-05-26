package
{
	import flash.geom.Rectangle;
	import starling.core.Starling;
	import flash.display.Sprite;

	[SWF(backgroundColor="#CCCCCC", frameRate="60", width="800", height="480")]
	public class BitmapFontMain extends Sprite
	{
		private var _starling: Starling;

		public function BitmapFontMain()
		{
			_starling = new Starling(BitmapFontGame, stage, new Rectangle(0, 0, 800, 480));
			_starling.showStats = true;
       		_starling.start();
		}
	}
}
