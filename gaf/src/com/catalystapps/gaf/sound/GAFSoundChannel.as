package com.catalystapps.gaf.sound
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.media.SoundChannel;

	/**
	 * @author Ivan Avdeenko
	 * @private
	 */
	public class GAFSoundChannel extends EventDispatcher
	{
		private var _soundChannel: SoundChannel;
		private var _soundID: uint;
		private var _swfName: String;

		public function GAFSoundChannel(swfName: String, soundID: uint)
		{
			this._swfName = swfName;
			this._soundID = soundID;
		}

		public function stop(): void
		{
			this._soundChannel.stop();
		}

		public function get soundChannel(): SoundChannel
		{
			return this._soundChannel;
		}

		public function set soundChannel(soundChannel: SoundChannel): void
		{
			if (this._soundChannel)
			{
				this._soundChannel.removeEventListener(Event.SOUND_COMPLETE, onComplete);
			}
			this._soundChannel = soundChannel;
			this._soundChannel.addEventListener(Event.SOUND_COMPLETE, onComplete);
		}

		private function onComplete(event: Event): void
		{
			this.dispatchEvent(event);
		}

		public function get soundID(): uint
		{
			return this._soundID;
		}

		public function get swfName(): String
		{
			return this._swfName;
		}
	}
}
