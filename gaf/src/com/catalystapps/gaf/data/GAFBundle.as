package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.core.gaf_internal;
	import com.catalystapps.gaf.display.IGAFTexture;
	import com.catalystapps.gaf.sound.GAFSoundData;
	import com.catalystapps.gaf.sound.GAFSoundManager;

	/**
	 * GAFBundle is utility class that used to save all converted GAFTimelines from bundle in one place with easy access after conversion complete
	 */
	public class GAFBundle
	{
		//--------------------------------------------------------------------------
		//
		//  PUBLIC VARIABLES
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  PRIVATE VARIABLES
		//
		//--------------------------------------------------------------------------

		private var _name: String;
		private var _soundData: GAFSoundData;
		private var _gafAssets: Vector.<GAFAsset>;
		private var _gafAssetsDictionary: Object; // GAFAsset by SWF name

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/** @private */
		public function GAFBundle()
		{
			this._gafAssets = new Vector.<GAFAsset>();
			this._gafAssetsDictionary = {};
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * Disposes all assets in bundle
		 */
		public function dispose(): void
		{
			if (this._gafAssets)
			{
				GAFSoundManager.getInstance().stopAll();
				this._soundData.gaf_internal::dispose();
				this._soundData = null;
	
				for each (var gafAsset: GAFAsset in this._gafAssets)
				{
					gafAsset.dispose();
				}
				this._gafAssets = null;
				this._gafAssetsDictionary = null;
			}
		}

		/**
		 * Returns <code>GAFTimeline</code> from bundle by timelineID
		 * @param swfName is the name of swf file, used to create gaf file
		 * @return <code>GAFTimeline</code> on the stage of swf file
		 */
		[Deprecated(replacement="com.catalystapps.gaf.data.GAFBundle.getGAFTimeline()", since="5.0")]
		public function getGAFTimelineByID(swfName: String): GAFTimeline
		{
			var gafTimeline: GAFTimeline;
			var gafAsset: GAFAsset = this._gafAssetsDictionary[swfName] as GAFAsset;
			if (gafAsset && gafAsset.timelines.length)
			{
				gafTimeline = gafAsset.timelines[0];
			}

			return gafTimeline;
		}

		/**
		 * Returns <code>GAFTimeline</code> from bundle by linkage
		 * @param linkage linkage in a *.fla file library
		 * @return <code>GAFTimeline</code> from bundle
		 */
		[Deprecated(replacement="com.catalystapps.gaf.data.GAFBundle.getGAFTimeline()", since="5.0")]
		public function getGAFTimelineByLinkage(linkage: String): GAFTimeline
		{
			var i: uint;
			var gafAsset: GAFAsset;
			var gafTimeline: GAFTimeline;
			while (!gafAsset && i < this._gafAssets.length)
			{
				gafAsset = this._gafAssets[i++];
				gafTimeline = gafAsset.getGAFTimelineByLinkage(linkage);
			}

			return gafTimeline;
		}

		/**
		 * Returns <code>GAFTimeline</code> from bundle by <code>swfName</code> and <code>linkage</code>.
		 * @param swfName is the name of SWF file where original timeline was located (or the name of the *.gaf config file where it is located).
		 * @param linkage is the linkage name of the timeline. If you need to get the Main Timeline from SWF use the "rootTimeline" linkage name.
		 * @return <code>GAFTimeline</code> from bundle
		 */
		public function getGAFTimeline(swfName: String, linkage: String = "rootTimeline"): GAFTimeline
		{
			var gafTimeline: GAFTimeline;
			var gafAsset: GAFAsset = this._gafAssetsDictionary[swfName];
			if (gafAsset)
			{
				gafTimeline = gafAsset.getGAFTimelineByLinkage(linkage);
			}

			return gafTimeline;
		}

		/**
		 * Returns <code>IGAFTexture</code> (custom image) from bundle by <code>swfName</code> and <code>linkage</code>.
		 * Then it can be used to replace animation parts or create new animation parts.
		 * @param swfName is the name of SWF file where original Bitmap/Sprite was located (or the name of the *.gaf config file where it is located)
		 * @param linkage is the linkage name of the Bitmap/Sprite
		 * @param scale Texture atlas Scale that will be used for <code>IGAFTexture</code> creation. Possible values are values from converted animation config.
		 * @param csf Texture atlas content scale factor (CSF) that will be used for <code>IGAFTexture</code> creation. Possible values are values from converted animation config.
		 * @return <code>IGAFTexture</code> (custom image) from bundle.
		 * @see com.catalystapps.gaf.display.GAFImage
		 * @see com.catalystapps.gaf.display.GAFImage#changeTexture()
		 */
		public function getCustomRegion(swfName: String, linkage: String, scale: Number = NaN, csf: Number = NaN): IGAFTexture
		{
			var gafTexture: IGAFTexture;
			var gafAsset: GAFAsset = this._gafAssetsDictionary[swfName];
			if (gafAsset)
			{
				gafTexture = gafAsset.gaf_internal::getCustomRegion(linkage, scale, csf);
			}

			return gafTexture;
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * @private
		 */
		gaf_internal function getGAFTimelineBySWFNameAndID(swfName: String, id: String): GAFTimeline
		{
			var gafTimeline: GAFTimeline;
			var gafAsset: GAFAsset = this._gafAssetsDictionary[swfName];
			if (gafAsset)
			{
				gafTimeline = gafAsset.gaf_internal::getGAFTimelineByID(id);
			}

			return gafTimeline;
		}

		/**
		 * @private
		 */
		gaf_internal function addGAFAsset(gafAsset: GAFAsset): void
		{
			use namespace gaf_internal;

			if (!this._gafAssetsDictionary[gafAsset.id])
			{
				this._gafAssetsDictionary[gafAsset.id] = gafAsset;
				this._gafAssets.push(gafAsset);
			}
			else
			{
				throw new Error("Bundle error. More then one gaf asset use id: '" + gafAsset.id + "'");
			}
		}

		//--------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  EVENT HANDLERS
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  GETTERS AND SETTERS
		//
		//--------------------------------------------------------------------------

		/**
		 * Returns all <code>GAFTimeline's</code> from bundle as <code>Vector</code>
		 */
		[Deprecated(replacement="com.catalystapps.gaf.data.GAFBundle.getGAFTimeline()", since="5.0")]
		public function get timelines(): Vector.<GAFTimeline>
		{
			var gafAsset: GAFAsset;
			var timelines: Vector.<GAFTimeline> = new Vector.<GAFTimeline>();

			for (var i: uint = 0, al: uint = this._gafAssets.length; i < al; i++)
			{
				gafAsset = this._gafAssets[i];
				for (var j: uint = 0, tl: uint = gafAsset.timelines.length; j < tl; j++)
				{
					timelines.push(gafAsset.timelines[j]);
				}
			}

			return timelines;
		}

		/**
		 * @private
		 */
		public function get soundData(): GAFSoundData
		{
			return this._soundData;
		}

		/**
		 * @private
		 * @param soundData
		 */
		public function set soundData(soundData: GAFSoundData): void
		{
			this._soundData = soundData;
		}

		/** @private */
		public function get gafAssets(): Vector.<GAFAsset>
		{
			return this._gafAssets;
		}

		/**
		 * The name of the bundle. Used in GAFTimelinesManager to identify specific bundle.
		 * Should be specified by user using corresponding setter or by passing the name as second parameter in GAFTimelinesManager.addGAFBundle().
		 * The name can be auto-setted by ZipToGAFAssetConverter in two cases:
		 * 1) If ZipToGAFAssetConverter.id is not empty ZipToGAFAssetConverter sets the bundle name equal to it's id;
		 * 2) If ZipToGAFAssetConverter.id is empty, but gaf package (zip or folder) contain only one *.gaf config file,
		 * ZipToGAFAssetConverter sets the bundle name equal to the name of the *.gaf config file.
		 */
		public function get name(): String
		{
			return this._name;
		}

		public function set name(name: String): void
		{
			this._name = name;
		}
	}
}
