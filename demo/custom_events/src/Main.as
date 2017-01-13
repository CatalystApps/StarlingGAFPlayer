package 
{
	import starling.core.Starling;

	import flash.display.Sprite;
	import flash.geom.Rectangle;

	[SWF(frameRate="60", width="700", height="400")]
	public class Main extends Sprite
	{
		private var starling: Starling;
		
		public function Main()
		{
			starling = new Starling(MainStarling, stage, new Rectangle(0, 0, stage.stageWidth, stage.stageHeight));
			starling.showStats = true;
			starling.skipUnchangedFrames = true; //TODO - дописать почему!)
       		starling.start();
		}
	}
}