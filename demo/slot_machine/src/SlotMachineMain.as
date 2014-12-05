/**
 * Created by Nazar on 27.11.2014.
 */
package
{
	import flash.geom.Rectangle;
	import starling.core.Starling;
	import flash.display.Sprite;

	[SWF(backgroundColor="#FFFFFF", frameRate="60", width="432", height="768")]
	public class SlotMachineMain extends Sprite
	{
		private var _starling: Starling;

		public function SlotMachineMain()
		{
			_starling = new Starling(SlotMachineGame, stage, new Rectangle(0, 0, 432, 768));
			_starling.showStats = true;
       		_starling.start();
		}
	}
}
