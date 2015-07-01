/**
 * Created by Nazar on 27.11.2014.
 */
package
{
	import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
	import com.catalystapps.gaf.data.GAFTimeline;

	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.utils.ByteArray;

	import starling.display.Sprite;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	public class SlotMachineGame extends Sprite
	{
		private var _machine: SlotMachine;

		[Embed(source="../design/slot_machine_design.zip", mimeType="application/octet-stream")]
		private const SlotMachineZip: Class;

		public function SlotMachineGame()
		{
			var zip: ByteArray = new SlotMachineZip();

			var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
			converter.addEventListener(Event.COMPLETE, this.onConverted);
			converter.addEventListener(ErrorEvent.ERROR, this.onError);
			converter.convert(zip);
		}

		private function onConverted(event: Event): void
		{
			var timeline: GAFTimeline = (event.target as ZipToGAFAssetConverter).gafBundle.getGAFTimeline("slot_machine_design", "rootTimeline");

			_machine = new SlotMachine(timeline);

			this.addChild(_machine);

			_machine.play();

			_machine.getArm().addEventListener(TouchEvent.TOUCH, onArmTouched);
			_machine.getSwitchMachineBtn().addEventListener(TouchEvent.TOUCH, onSwitchMachineBtnTouched);
		}

		private function onArmTouched(event: TouchEvent): void
		{
			var touch: Touch = event.getTouch(_machine.getArm());
			if (touch)
			{
				if (touch.phase == TouchPhase.ENDED)
				{
					_machine.start();
				}
			}
		}

		private function onSwitchMachineBtnTouched(event: TouchEvent): void
		{
			var touch: Touch = event.getTouch(_machine.getSwitchMachineBtn());
			if (touch)
			{
				if (touch.phase == TouchPhase.HOVER)
				{
					_machine.getSwitchMachineBtn().setSequence("Over");
				}
				else if (touch.phase == TouchPhase.BEGAN)
				{
					_machine.getSwitchMachineBtn().setSequence("Down");
				}
				else if (touch.phase == TouchPhase.ENDED)
				{
					_machine.getSwitchMachineBtn().setSequence("Up");
					_machine.switchType();
				}
				else
				{
					_machine.getSwitchMachineBtn().setSequence("Up");
				}
			}
		}

		private function onError(event: ErrorEvent): void
		{
			trace(event);
		}
	}
}
