package com.catalystapps.gaf.sound
{
	import flash.net.URLRequest;
	import flash.media.Sound;
	import com.catalystapps.gaf.data.config.CFrameSound;
	import com.catalystapps.gaf.data.config.CSound;

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.utils.ByteArray;
	/** @private
	 * @author Ivan Avdeenko
	 */
	public class SoundManager
	{
		private var _soundQueue: Vector.<CSound>;
		private var _sounds: Object;
		private var soundChannels: Object;
		private var onFail: Function;
		private var onSuccess: Function;	
	
		public function addSound(soundData: CSound, assetID: String, soundBytes: ByteArray): Boolean
		{
			var sound: Sound = new Sound();
			if (soundBytes)
			{
				if (soundData.format == CSound.MP3)
				{
					sound.loadCompressedDataFromByteArray(soundBytes, soundBytes.length);
				}
//				else if (soundData.format == CSound.WAV)
//				{
					//TODO: play with as3wavSound
//				}
			}
			else
			{
				this._soundQueue ||= new <CSound>[];
				this._soundQueue.push(soundData);
			}

			soundData.sound = sound;

			this._sounds ||= {};
			this._sounds[assetID] ||= {};
			this._sounds[assetID][soundData.soundID] = sound;
			return true;
		}

		public function loadSounds(onSuccess: Function, onFail: Function): void
		{
			this.onSuccess = onSuccess;
			this.onFail = onFail;
			this.loadSound();
		}

		public function startSound(soundConfig: CFrameSound, assetID: String): void
		{
			var sound: Sound = _sounds[assetID][soundConfig.soundID];
			switch (soundConfig.action)
			{
				case CFrameSound.ACTION_STOP:
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
				case CFrameSound.ACTION_CONTINUE:
					if (this.soundChannels
					&&  this.soundChannels[assetID]
					&&  this.soundChannels[assetID][soundConfig.soundID])
					{
						break; //sound already in play - no need to launch it again
					}
				case CFrameSound.ACTION_START:
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

		public function stopAllSounds(): void
		{
			var channels: Vector.<SoundData>;
			for (var assetID: String in this.soundChannels)
			{
				for (var soundID: String in this.soundChannels[assetID])
				{
					channels = this.soundChannels[assetID][soundID];
					for (var i: int = 0; i < channels.length; i++)
					{
						channels[i].stop();
					}
				}
			}
			this.soundChannels = null;
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
			var soundDataConfig: CSound = _soundQueue.pop();
			with (soundDataConfig)
			{
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
