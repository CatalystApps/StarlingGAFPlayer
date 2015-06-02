package com.catalystapps.gaf.sound
{
	import flash.utils.ByteArray;
	import flash.net.URLRequest;
	import flash.events.IOErrorEvent;
	import flash.events.Event;
	import com.catalystapps.gaf.data.config.CSound;
	import flash.media.Sound;
	import com.catalystapps.gaf.data.config.CSoundData;
	/**
	 * @author Ivan Avdeenko
	 */
	public class SoundManager
	{
		private var _soundQueue: Vector.<CSoundData>;
		private var _sounds: Object;
		private var soundChannels: Object;
		private var onFail: Function;
		private var onSuccess: Function;	
	
		public function addSound(soundData: CSoundData, assetID: String, soundBytes: ByteArray): void
		{
			this._sounds ||= {};
			this._sounds[assetID] ||= {};
			this._sounds[assetID][soundData.soundID] = soundData;
			if (soundBytes)
			{
				soundData.sound = new Sound();

				if (soundData.format == CSoundData.WAV)
				{
					var rate: uint;
					switch (soundData.rate)
					{
						case 0: rate = 5500;  break;
						case 1: rate = 11025; break;
						case 2: rate = 22050; break;
						case 3: rate = 44100; break;
					}

					var wavBytes: ByteArray = new ByteArray();
					wavBytes.writeBytes(soundBytes, 44);
					wavBytes.position = 0;
					soundData.sound.loadPCMFromByteArray(wavBytes, soundData.sampleCount, "float", soundData.stereo, rate);
					wavBytes.clear();
					wavBytes = null;
				}
				else if (soundData.format == CSoundData.MP3)
				{
					soundData.sound.loadCompressedDataFromByteArray(soundBytes, soundBytes.length);
				}
			}
			else
			{
				this._soundQueue ||= new <CSoundData>[];
				this._soundQueue.push(soundData);
			}
		}

		public function loadSounds(onSuccess: Function, onFail: Function): void
		{
			this.onSuccess = onSuccess;
			this.onFail = onFail;
			this.loadSound();
		}

		public function startSound(soundConfig: CSound, assetID: String): void
		{
			var sound: Sound = _sounds[assetID][soundConfig.soundID]["sound"];
			switch (soundConfig.action)
			{
				case CSound.STOP:
					if (this.soundChannels
					&&  this.soundChannels[assetID]
					&&  this.soundChannels[assetID][soundConfig.soundID])
					{
						var channels: Vector.<SoundData> = this.soundChannels[assetID][soundConfig.soundID];
						for (var i: int = 0; i < channels.length; i++)
						{
							channels[i].stop();
						}
						this.soundChannels[assetID][soundConfig.soundID] = null;
						delete this.soundChannels[assetID][soundConfig.soundID];
					}
					break;
				case CSound.CONTINUE:
					if (this.soundChannels
					&&  this.soundChannels[assetID]
					&&  this.soundChannels[assetID][soundConfig.soundID])
					{
						break; //sound already in play - no need to launch it again
					}
				case CSound.START:
					var soundData: SoundData = new SoundData(soundConfig, assetID);
					soundData.soundChannel = sound.play(0, soundConfig.repeatCount);
					soundData.addEventListener(Event.SOUND_COMPLETE, onSoundPlayEnded);
					this.soundChannels ||= {};
					this.soundChannels[assetID] ||= {};
					this.soundChannels[assetID][soundConfig.soundID] ||= new <SoundData>[];
					this.soundChannels[assetID][soundConfig.soundID].push(soundData);
					break;
			}
		}

		private function onSoundPlayEnded(event: Event): void
		{
			var soundData: SoundData = event.target as SoundData;
			soundData.removeEventListener(Event.SOUND_COMPLETE, onSoundPlayEnded);

			this.soundChannels[soundData.assetID][soundData.config.soundID] = null;
			delete this.soundChannels[soundData.assetID][soundData.config.soundID];
		}

		private function loadSound(): void
		{
			var soundDataConfig: CSoundData = _soundQueue.pop();
			with (soundDataConfig)
			{
				sound = new Sound();
				sound.addEventListener(Event.COMPLETE, onSoundLoaded);
				sound.addEventListener(IOErrorEvent.IO_ERROR, onError);
				sound.load(new URLRequest(soundDataConfig.source));
			}
		}

		private function onSoundLoaded(event: Event): void
		{
			this.removeListeners(event);

			if (this._soundQueue.length > 0)
			{
				this.loadSound();
			}
			else
			{
				trace("this.onSuccess.length = ", this.onSuccess.length);
				this.onSuccess();
				this.onSuccess = null;
				this.onFail = null;
			}
		}

		private function onError(event: IOErrorEvent): void
		{
			this.removeListeners(event);
			this.onFail(event);
			this.onFail = null;
			this.onSuccess = null;
		}

		private function removeListeners(event: Event): void
		{
			var sound: Sound = event.target as Sound;
			sound.removeEventListener(Event.COMPLETE, onSoundLoaded);
			sound.removeEventListener(IOErrorEvent.IO_ERROR, onError);
		}

		public function get hasSoundsToLoad(): Boolean
		{
			return this._soundQueue && this._soundQueue.length > 0;
		}
	}
}
