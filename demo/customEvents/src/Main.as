package 
{
	import starling.core.Starling;

	import flash.display.Sprite;
	import flash.geom.Rectangle;

	[SWF(backgroundColor="#999999", frameRate="60", width="520", height="400")]
	public class Main extends Sprite
	{
		private var starling: Starling;
		
		public function Main()
		{
			Starling.handleLostContext = true;
			starling = new Starling(MainStarling, stage, new Rectangle(0, 0, stage.stageWidth, stage.stageHeight));
			starling.showStats = true;
       		starling.start();
		}
	}
}