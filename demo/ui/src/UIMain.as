package
{
	import flash.geom.Rectangle;
	import starling.core.Starling;
	import flash.display.Sprite;

	/**
	 * @author mitvad
	 */
	public class UIMain extends Sprite
	{
		private var _starling: Starling;
		
		public function UIMain()
		{
			_starling = new Starling(UIGame, stage, new Rectangle(0, 0, 700, 600));
			_starling.showStats = true;
       		_starling.start();
		}
	}
}
