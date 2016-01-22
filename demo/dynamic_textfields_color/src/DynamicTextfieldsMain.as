package 
{
	import starling.core.Starling;

	import flash.display.Sprite;
	
	[SWF(backgroundColor="#29213B", frameRate="60", width="400", height="300")]
	public class DynamicTextfieldsMain extends Sprite
	{
		private var _starling: Starling;
		
		public function DynamicTextfieldsMain()
		{
			_starling = new Starling(DynamicTextfieldsGame, stage);
			_starling.showStats = true;
       		_starling.start();
		}
	}
}
