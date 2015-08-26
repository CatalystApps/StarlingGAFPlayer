package
{
	import flash.geom.Rectangle;
	import starling.core.Starling;
	import flash.display.Sprite;

	/**
	 * @author mitvad
	 */
	[SWF(backgroundColor="#FFFFFF", frameRate="60", width="768", height="1024")]
	public class SimpleMain extends Sprite
	{
		private var _starling: Starling;
		
		public function SimpleMain()
		{
			_starling = new Starling(SimpleGame, stage, new Rectangle(0, 0, stage.stageWidth, stage.stageHeight));
			_starling.showStats = true;
			_starling.start();
		}
	}
}
