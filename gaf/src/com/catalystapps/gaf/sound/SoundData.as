package com.catalystapps.gaf.sound
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import com.catalystapps.gaf.data.config.CFrameSound;
	import flash.media.SoundChannel;

	/**
	 * @author Ivan Avdeenko
	 */
	public class SoundData extends EventDispatcher
	{
		private var _soundChannel: SoundChannel;
		private var _assetID: String;
		private var _config: CFrameSound;

		public function SoundData(config: CFrameSound, assetID: String)
		{
			this._config = config;
			this._assetID = assetID;
		}

		public function stop(): void
		{
			 this._soundChannel.stop();
		}

		public function get assetID(): String
		{
			return this._assetID;
		}

		public function get config(): CFrameSound
		{
			return this._config;
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
	}
}
