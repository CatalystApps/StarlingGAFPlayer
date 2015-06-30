package com.catalystapps.gaf.sound
{
	import com.catalystapps.gaf.core.gaf_internal;
	import com.catalystapps.gaf.data.config.CSound;

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.media.Sound;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	/** @private
	 * @author Ivan Avdeenko
	 * @private
	 */
	public class GAFSoundData
	{
		private var onFail: Function;
		private var onSuccess: Function;
		private var _sounds: Object;
		private var _soundQueue: Vector.<CSound>;

		public function getSoundByLinkage(linkage: String): Sound
		{
			if (this._sounds)
			{
				return this._sounds[linkage];
			}
			return null;
		}

		gaf_internal function addSound(soundData: CSound, swfName: String, soundBytes: ByteArray): void
		{
			var sound: Sound = new Sound();
			if (soundBytes)
			{
				if (soundBytes.position > 0)
				{
					soundData.sound = this._sounds[soundData.linkageName];
					return;
				}
				else
				{
					sound.loadCompressedDataFromByteArray(soundBytes, soundBytes.length);
				}
			}
			else
			{
				this._soundQueue ||= new Vector.<CSound>();
				this._soundQueue.push(soundData);
			}

			soundData.sound = sound;

			this._sounds ||= {};
			if (soundData.linkageName.length > 0)
			{
				this._sounds[soundData.linkageName] = sound;
			}
			else
			{
				this._sounds[swfName] ||= {};
				this._sounds[swfName][soundData.soundID] = sound;
			}
		}

		gaf_internal function getSound(soundID: uint, swfName: String): Sound
		{
			if (this._sounds)
			{
				return this._sounds[swfName][soundID];
			}
			return null;
		}

		gaf_internal function loadSounds(onSuccess: Function, onFail: Function): void
		{
			this.onSuccess = onSuccess;
			this.onFail = onFail;
			this.loadSound();
		}

		gaf_internal function dispose(): void
		{
			for each (var sound: Sound in this._sounds)
			{
				sound.close();
			}
		}

		private function loadSound(): void
		{
			var soundDataConfig: CSound = _soundQueue.pop();
			with (soundDataConfig.sound)
			{
				addEventListener(Event.COMPLETE, onSoundLoaded);
				addEventListener(IOErrorEvent.IO_ERROR, onError);
				load(new URLRequest(soundDataConfig.source));
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

		gaf_internal function get hasSoundsToLoad(): Boolean
		{
			return this._soundQueue && this._soundQueue.length > 0;
		}
	}
}
