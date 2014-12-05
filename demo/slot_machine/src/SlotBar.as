/**
 * Created by Nazar on 27.11.2014.
 */
/****************************************************************************
 This is the helper class for Slot Machine reel

  / \
 | A |
 |---|
 | B |
 |---|
 | C |
  \ /

 http://gafmedia.com/
 ****************************************************************************/
package
{
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public dynamic class SlotBar
	{
		private var _bar: GAFMovieClip;
		private var _slots: Vector.<GAFMovieClip>;
		private var _spinResult: Vector.<int>;
		private var _machineType: String;

		private var _sequence: SequencePlaybackInfo;
		private var _timer: Timer;

		public function SlotBar(slotBarMC: GAFMovieClip)
		{
			if (!slotBarMC) throw new ArgumentError("Error: slotBarMC cannot be null");

			_bar = slotBarMC;
			_slots = new Vector.<GAFMovieClip>(3, true);
			_timer = new Timer(0, 1);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);

			var name: String;
			var l: uint = _slots.length;
			for (var i: uint = 0; i < l; i++)
			{
				name = "fruit" + (i + 1);
				//_slots[i] = _bar.getChildByName(name) as GAFMovieClip;
				_slots[i] = _bar[name];

				if (!_slots[i])
					throw new Error("Cannot find slot movie.");
			}
		}

		public function playSequenceWithTimeout(sequence: SequencePlaybackInfo, timeout: Number): void
		{
			_sequence = sequence;
			_timer.reset();
			_timer.delay = timeout;
			_timer.start();
		}

		private function onTimerComplete(event: TimerEvent): void
		{
			_bar.loop = _sequence.looped;
			_bar.setSequence(_sequence.name);

			if (_sequence.name == "stop")
			{
				showSpinResult();
			}
		}

		public function randomizeSlots(maxTypes: int, machineType: String): void
		{
			var l: uint = _slots.length;
			var slotImagePos: uint;
			var seqName: String;
			for (var i: uint = 0; i < l; i++)
			{
				slotImagePos = Math.floor(Math.random() * maxTypes) + 1;
				seqName = slotImagePos + "_" + machineType;
				_slots[i].setSequence(seqName, false);
			}
		}

		public function setSpinResult(fruits: Vector.<int>, machineType: String): void
		{
			_spinResult = fruits;
			_machineType = machineType;
		}

		public function showSpinResult(): void
		{
			var l: uint = _slots.length;
			var seqName: String;
			for (var i: uint = 0; i < l; i++)
			{
				seqName = (_spinResult[i]) + "_" + _machineType;
				_slots[i].setSequence(seqName, false);
			}
		}

		public function switchSlotType(maxSlots: int): void
		{
			var l: uint = _slots.length;
			var curFrame: uint;
			var maxFrame: uint;
			for (var i: uint = 0; i < l; i++)
			{
				curFrame = _slots[i].currentFrame - 1;
				maxFrame = _slots[i].totalFrames;
				curFrame += maxSlots;
				if (curFrame >= maxFrame)
				{
					curFrame = curFrame % maxSlots;
				}

				_slots[i].gotoAndStop(curFrame + 1);
			}
		}

		public function getBar(): GAFMovieClip
		{
			return _bar;
		}
	}
}
