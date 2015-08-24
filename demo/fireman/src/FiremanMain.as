package
{
	import flash.geom.Rectangle;
	import starling.core.Starling;
	import flash.display.Sprite;

	/**
	 * @author mitvad
	 */
	[SWF(backgroundColor="#FFFFFF", frameRate="60", width="800", height="480")]
	public class FiremanMain extends Sprite
	{
		private var _starling: Starling;
		
		public function FiremanMain()
		{
			_starling = new Starling(FiremanGame, stage, new Rectangle(0, 0, 800, 480));
			_starling.showStats = true;
			_starling.start();
		}
	}
}
