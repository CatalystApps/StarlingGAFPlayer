package com.catalystapps.gaf.sound
{
	import com.catalystapps.gaf.core.gaf_internal;

	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundTransform;

	/**
	 * @author Ivan Avdeenko
	 */

	/**
	 * The <code>GAFSoundManager</code> provides an interface to control GAF sound playback.
	 * All adjustments made through <code>GAFSoundManager</code> affects all GAF sounds.
	 */
	public class GAFSoundManager
	{
		private var volume: Number = 1;
		private var soundChannels: Object;
		private static var _getInstance: GAFSoundManager;

		/**
		 * @private
		 * @param singleton
		 */
		public function GAFSoundManager(singleton: Singleton)
		{
			if (!singleton)
			{
				throw new Error("GAFSoundManager is Singleton. Use GAFSoundManager.instance or GAF.soundManager instead");
			}
		}

		/**
		 * The volume of the GAF sounds, ranging from 0 (silent) to 1 (full volume).
		 * @param volume the volume of the sound
		 */
		public function setVolume(volume: Number): void
		{
			this.volume = volume;

			var channels: Vector.<GAFSoundChannel>;
			for (var swfName: String in soundChannels)
			{
				for (var soundID: String in soundChannels[swfName])
				{
					channels = soundChannels[swfName][soundID];
					for (var i: int = 0; i < channels.length; i++)
					{
						channels[i].soundChannel.soundTransform = new SoundTransform(volume);
					}
				}
			}
		}

		/**
		 * Stops all GAF sounds currently playing
		 */
		public function stopAll(): void
		{
			var channels: Vector.<GAFSoundChannel>;
			for (var swfName: String in soundChannels)
			{
				for (var soundID: String in soundChannels[swfName])
				{
					channels = soundChannels[swfName][soundID];
					for (var i: int = 0; i < channels.length; i++)
					{
						channels[i].stop();
					}
				}
			}
			soundChannels = null;
		}

		/**
		 * @private
		 * @param sound
		 * @param soundID
		 * @param soundOptions
		 * @param swfName
		 */
		gaf_internal function play(sound: Sound, soundID: uint, soundOptions: Object, swfName: String): void
		{
			if (soundOptions["continue"]
			&&  soundChannels
			&&  soundChannels[swfName]
			&&  soundChannels[swfName][soundID])
			{
				return; //sound already in play - no need to launch it again
			}
			var soundData: GAFSoundChannel = new GAFSoundChannel(swfName, soundID);
			soundData.soundChannel = sound.play(0, soundOptions["repeatCount"], new SoundTransform(this.volume));
			soundData.addEventListener(Event.SOUND_COMPLETE, onSoundPlayEnded);
			soundChannels ||= {};
			soundChannels[swfName] ||= {};
			soundChannels[swfName][soundID] ||= new <GAFSoundChannel>[];
			Vector.<GAFSoundChannel>(soundChannels[swfName][soundID]).push(soundData);
		}

		/**
		 * @private
		 * @param soundID
		 * @param swfName
		 */
		gaf_internal function stop(soundID: uint, swfName: String): void
		{
			if (soundChannels
			&&  soundChannels[swfName]
			&&  soundChannels[swfName][soundID])
			{
				var channels: Vector.<GAFSoundChannel> = soundChannels[swfName][soundID];
				for (var i: int = 0; i < channels.length; i++)
				{
					channels[i].stop();
				}
				soundChannels[swfName][soundID] = null;
				delete soundChannels[swfName][soundID];
			}
		}

		/**
		 * @private
		 * @param event
		 */
		private function onSoundPlayEnded(event: Event): void
		{
			var soundChannel: GAFSoundChannel = event.target as GAFSoundChannel;
			soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundPlayEnded);

			soundChannels[soundChannel.swfName][soundChannel.soundID] = null;
			delete soundChannels[soundChannel.swfName][soundChannel.soundID];
		}

		/**
		 * The instance of the <code>GAFSoundManager</code> (singleton)
		 * @return The instance of the <code>GAFSoundManager</code>
		 */
		public static function getInstance(): GAFSoundManager
		{
			_getInstance ||= new GAFSoundManager(new Singleton());
			return _getInstance;
		}
	}
}
/** @private */
internal class Singleton
{
}
