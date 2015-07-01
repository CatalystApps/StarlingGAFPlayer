/**
 * Created by Nazar on 27.11.2014.
 */
package
{
	import com.catalystapps.gaf.data.GAFTimeline;
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.TimerEvent;
	import flash.utils.Timer;

	import starling.display.DisplayObject;
	import starling.events.Event;

	public dynamic class SlotMachine extends GAFMovieClip
	{
		public static const MACHINE_STATE_INITIAL: uint = 0;
		public static const MACHINE_STATE_ARM_TOUCHED: uint = 1;
		public static const MACHINE_STATE_SPIN: uint = 2;
		public static const MACHINE_STATE_SPIN_END: uint = 3;
		public static const MACHINE_STATE_WIN: uint = 4;
		public static const MACHINE_STATE_END: uint = 5;
		public static const MACHINE_STATE_COUNT: uint = 6;

		public static const PRIZE_NONE: uint = 0;
		public static const PRIZE_C1K: uint = 1;
		public static const PRIZE_C500K: uint = 2;
		public static const PRIZE_C1000K: uint = 3;
		public static const PRIZE_COUNT: uint = 4;

		private static const REWARD_COINS: String = "coins";
		private static const REWARD_CHIPS: String = "chips";
		private static const FRUIT_COUNT: int = 5;
		private static const BAR_TIMEOUT: Number = 0.2;

		private var _arm: GAFMovieClip;
		private var _switchMachineBtn: GAFMovieClip;
		private var _whiteBG: GAFMovieClip;
		private var _rewardText: GAFMovieClip;
		private var _bottomCoins: GAFMovieClip;
		private var _centralCoins: Vector.<GAFMovieClip>;
		private var _winFrame: GAFMovieClip;
		private var _spinningRays: GAFMovieClip;
		private var _bars: Vector.<SlotBar>;

		private var _state: uint;
		private var _rewardType: String;

		//private var _prizeSequence: Vector.<uint>;
		private var _prize: uint;

		private var _timer: Timer;

		public function SlotMachine(gafTimeline: GAFTimeline)
		{
			super(gafTimeline);
			play(true);

			_state = MACHINE_STATE_INITIAL;
			_rewardType = REWARD_CHIPS;

			//_prizeSequence = new <uint>[PRIZE_C1000K, PRIZE_NONE, PRIZE_C1000K, PRIZE_C1K, PRIZE_C1000K, PRIZE_C500K];
			_prize = 0;

			_centralCoins = new Vector.<GAFMovieClip>(3, true);
			_bars = new Vector.<SlotBar>(3, true);

			_timer = new Timer(0, 1);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);

			// Here we get pointers to inner Gaf objects for quick access
			// We use flash object instance name
			_arm = this.obj.arm;
			_switchMachineBtn = this.obj.swapBtn;
			_switchMachineBtn.stop();
			_switchMachineBtn.touchGroup = true;
			_whiteBG = this.obj.white_exit;
			_bottomCoins = this.obj.wincoins;
			_rewardText = this.obj.wintext;
			_winFrame = this.obj.frame;
			_spinningRays = this.obj.spinning_rays;

			// Sequence "start" will play once and callback SlotMachine::onFinishRaysSequence
			// will be called when last frame of "start" sequence shown
			_spinningRays.setSequence("start");
			_spinningRays.addEventListener(GAFMovieClip.EVENT_TYPE_SEQUENCE_END, onFinishRaysSequence);

			var i: uint;
			var l: uint = this.obj.numChildren;
			for (i = 0; i < l; i++)
			{
				var child: DisplayObject = this.obj.getChildAt(i);
				if (child != _arm && child != _switchMachineBtn)
				{
					child.touchable = false;
				}
			}

			l = _centralCoins.length;
			for (i = 0; i < l; i++)
			{
				var prize: uint = i + 1;
				_centralCoins[i] = this.obj[getTextByPrize(prize)];
			}

			l = _bars.length;
			var barName: String;
			for (i = 0; i < l; i++)
			{
				barName = "slot" + (i + 1);

				_bars[i] = new SlotBar(this.obj[barName]);
				_bars[i].randomizeSlots(FRUIT_COUNT, _rewardType);
			}

			defaultPlacing();
		}

		public function getArm(): GAFMovieClip
		{
			return _arm;
		}

		public function getSwitchMachineBtn(): GAFMovieClip
		{
			return _switchMachineBtn;
		}

		public function start(): void
		{
			if (_state == MACHINE_STATE_INITIAL)
			{
				nextState();
			}
		}

		// General callback for sequences
		// Used by Finite-state machine
		// see setAnimationStartedNextLoopDelegate and setAnimationFinishedPlayDelegate
		// for looped and non-looped sequences
		private function onFinishSequence(event: Event): void
		{
			nextState();
		}

		private function onTimerComplete(event: TimerEvent): void
		{
			nextState();
		}

		private function onFinishRaysSequence(event: Event): void
		{
			_spinningRays.removeEventListener(GAFMovieClip.EVENT_TYPE_SEQUENCE_END, onFinishRaysSequence);
			_spinningRays.setSequence("spin", true);
		}

		public function switchType(): void
		{
			if (_rewardType == REWARD_CHIPS)
			{
				_rewardType = REWARD_COINS;
			}
			else if (_rewardType == REWARD_COINS)
			{
				_rewardType = REWARD_CHIPS;
			}

			var state: uint = _state - 1;
			if (state < 0)
			{
				state = MACHINE_STATE_COUNT - 1;
			}
			_state = state;
			nextState();

			var l: uint = _bars.length;
			for (var i: uint = 0; i < l; i++)
			{
				_bars[i].switchSlotType(FRUIT_COUNT);
			}
		}

		private function defaultPlacing(): void
		{
			// Here we set default sequences if needed
			// Sequence names are used from flash labels
			_whiteBG.gotoAndStop("whiteenter");
			_winFrame.setSequence("stop");
			_arm.setSequence("stop");
			_bottomCoins.visible = false;
			_bottomCoins.loop = false;
			_rewardText.setSequence("notwin", true);

			var i: uint;
			var l: uint = _centralCoins.length;
			for (i = 0; i < l; i++)
			{
				_centralCoins[i].visible = false;
			}
			l = _bars.length;
			for (i = 0; i < l; i++)
			{
				_bars[i].getBar().setSequence("statics");
			}
		}

		/* This method describes Finite-state machine
		 * state switches in 2 cases:
		 * 1) specific sequence ended playing and callback called
		 * 2) by timer
		 */
		private function nextState(): void
		{
			++_state;
			if (_state == MACHINE_STATE_COUNT)
			{
				_state = MACHINE_STATE_INITIAL;
			}
			resetCallbacks();

			var i: uint;
			var l: uint;
			var sequence: SequencePlaybackInfo;
			switch (_state)
			{
				case MACHINE_STATE_INITIAL:
					defaultPlacing();
					break;

				case MACHINE_STATE_ARM_TOUCHED:
					_arm.setSequence("push");
					_arm.addEventListener(GAFMovieClip.EVENT_TYPE_SEQUENCE_END, onFinishSequence);
					break;

				case MACHINE_STATE_SPIN:
					_arm.setSequence("stop");
					_timer.reset();
					_timer.delay = 3000;
					_timer.start();
					l = _bars.length;
					var seqName: String;
					for (i = 0; i < l; i++)
					{
						seqName = "rotation_" + _rewardType;
						sequence = new SequencePlaybackInfo(seqName, true);
						_bars[i].playSequenceWithTimeout(sequence, BAR_TIMEOUT * i * 1000);
					}
					break;

				case MACHINE_STATE_SPIN_END:
					_timer.reset();
					_timer.delay = BAR_TIMEOUT * 4 * 1000;
					_timer.start();
					/*_prize = */
					generatePrize();
					var spinResult: Vector.<Vector.<int>> = generateSpinResult(_prize);
					l = _bars.length;
					for (i = 0; i < l; i++)
					{
						_bars[i].setSpinResult(spinResult[i], _rewardType);
						sequence = new SequencePlaybackInfo("stop", false);
						_bars[i].playSequenceWithTimeout(sequence, BAR_TIMEOUT * i * 1000);
					}
					break;

				case MACHINE_STATE_WIN:
					showPrize(_prize);
					break;

				case MACHINE_STATE_END:
					_whiteBG.play();
					_whiteBG.addEventListener(GAFMovieClip.EVENT_TYPE_SEQUENCE_END, onFinishSequence);
					break;

				default:
					break;
			}
		}

		private function resetCallbacks(): void
		{
			_whiteBG.removeEventListener(GAFMovieClip.EVENT_TYPE_SEQUENCE_END, onFinishSequence);
			_arm.removeEventListener(GAFMovieClip.EVENT_TYPE_SEQUENCE_END, onFinishSequence);
		}

		private function generatePrize(): uint
		{
			++_prize;
			if (_prize == PRIZE_COUNT)
			{
				_prize = 0;
			}

			return _prize;
		}

		/* Method returns machine spin result
		 *        4 3 1
		 *        2 2 2
		 *        1 1 5
		 * where numbers are fruit indexes
		 */
		private function generateSpinResult(prize: uint): Vector.<Vector.<int>>
		{
			var l: uint = 3;
			var result: Vector.<Vector.<int>> = new Vector.<Vector.<int>>(l, true);
			var i: uint;
			for (i = 0; i < l; i++)
			{
				result[i] = new Vector.<int>(l);
				result[i][0] = Math.floor(Math.random() * FRUIT_COUNT) + 1;
				result[i][2] = Math.floor(Math.random() * FRUIT_COUNT) + 1;
			}

			var centralFruit: int;
			switch (prize)
			{
				case PRIZE_NONE:
					centralFruit = Math.floor(Math.random() * FRUIT_COUNT) + 1;
					break;
				case PRIZE_C1K:
					centralFruit = Math.floor(Math.random() * (FRUIT_COUNT / 2)) + 1;
					break;
				case PRIZE_C500K:
					centralFruit = Math.floor(Math.random() * (FRUIT_COUNT / 2)) + FRUIT_COUNT / 2 + 1;
					break;
				case PRIZE_C1000K:
					centralFruit = FRUIT_COUNT - 1;
					break;
				default:
					break;
			}

			if (prize == PRIZE_NONE)
			{
				result[0][1] = centralFruit;
				result[1][1] = centralFruit;
				result[2][1] = centralFruit;
				while (result[2][1] == result[1][1])
				{
					result[2][1] = Math.floor(Math.random() * FRUIT_COUNT) + 1; // last fruit should be another
				}
			}
			else
			{
				for (i = 0; i < l; i++)
				{
					result[i][1] = centralFruit;
				}
			}

			return result;
		}

		// Here we switching to win animation
		private function showPrize(prize: uint): void
		{
			var coinsBottomState: String = getTextByPrize(prize) + "_" + _rewardType;
			_bottomCoins.visible = true;
			_bottomCoins.gotoAndStop(coinsBottomState);

			if (prize == PRIZE_NONE)
			{
				nextState();
				return;
			}

			_winFrame.setSequence("win", true);
			_rewardText.setSequence(getTextByPrize(prize));

			var idx: int = prize - 1;
			_centralCoins[idx].visible = true;
			_centralCoins[idx].play(true);
			_centralCoins[idx].setSequence(_rewardType);

			_timer.reset();
			_timer.delay = 2000;
			_timer.start();

		}

		private function getTextByPrize(prize: uint): String
		{
			switch (prize)
			{
				case PRIZE_NONE:
					return "notwin";

				case PRIZE_C1K:
					return "win1k";

				case PRIZE_C500K:
					return "win500k";

				case PRIZE_C1000K:
					return "win1000k";

				default:
					return "";
			}
		}
	}
}
