package
{
	import flash.geom.Rectangle;
	import starling.core.Starling;
	import flash.display.Sprite;

	/**
	 * @author mitvad
	 */
	[SWF(backgroundColor="#FFFFFF", frameRate="60", width="1024", height="768")]
	public class FiremanMain extends Sprite
	{
		private var _starling: Starling;
		
		public function FiremanMain()
		{
			_starling = new Starling(FiremanGame, stage, new Rectangle(0, 0, 1024, 768));
			_starling.showStats = true;
       		_starling.start();
		}
	}
}
