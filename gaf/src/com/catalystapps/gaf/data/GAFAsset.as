/**
 * Created by Nazar on 11.06.2015.
 */
package com.catalystapps.gaf.data
{
	import com.catalystapps.gaf.utils.MathUtility;
	import com.catalystapps.gaf.core.gaf_internal;
	import com.catalystapps.gaf.data.config.CTextureAtlasCSF;
	import com.catalystapps.gaf.data.config.CTextureAtlasElement;
	import com.catalystapps.gaf.data.config.CTextureAtlasScale;
	import com.catalystapps.gaf.display.GAFScale9Texture;
	import com.catalystapps.gaf.display.GAFTexture;
	import com.catalystapps.gaf.display.IGAFTexture;

	import flash.geom.Matrix;

	import starling.textures.Texture;

	/** @private */
	public class GAFAsset
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

		private var _config: GAFAssetConfig;

		private var _timelines: Vector.<GAFTimeline>;
		private var _timelinesDictionary: Object = {};
		private var _timelinesByLinkage: Object = {};

		private var _scale: Number;
		private var _csf: Number;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		public function GAFAsset(config: GAFAssetConfig)
		{
			this._config = config;

			this._scale = config.defaultScale;
			this._csf = config.defaultContentScaleFactor;

			this._timelines = new Vector.<GAFTimeline>();
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
			if (this._timelines.length > 0)
			{
				for each (var timeline: GAFTimeline in this._timelines)
				{
					timeline.dispose();
				}
			}
			this._timelines = null;

			this._config.dispose();
			this._config = null;
		}

		/** @private */
		public function addGAFTimeline(timeline: GAFTimeline): void
		{
			use namespace gaf_internal;
			if (!this._timelinesDictionary[timeline.id])
			{
				this._timelinesDictionary[timeline.id] = timeline;
				this._timelines.push(timeline);

				if (timeline.config.linkage)
				{
					this._timelinesByLinkage[timeline.linkage] = timeline;
				}
			}
			else
			{
				throw new Error("Bundle error. More then one timeline use id: '" + timeline.id + "'");
			}
		}

		/**
		 * Returns <code>GAFTimeline</code> from gaf asset by linkage
		 * @param linkage linkage in a *.fla file library
		 * @return <code>GAFTimeline</code> from gaf asset
		 */
		public function getGAFTimelineByLinkage(linkage: String): GAFTimeline
		{
			var gafTimeline: GAFTimeline = this._timelinesByLinkage[linkage];

			return gafTimeline;
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		/** @private
		 * Returns <code>GAFTimeline</code> from gaf asset by ID
		 * @param id internal timeline id
		 * @return <code>GAFTimeline</code> from gaf asset
		 */
		gaf_internal function getGAFTimelineByID(id: String): GAFTimeline
		{
			return this._timelinesDictionary[id];
		}

		/** @private
		 * Returns <code>GAFTimeline</code> from gaf asset bundle by linkage
		 * @param linkage linkage in a *.fla file library
		 * @return <code>GAFTimeline</code> from gaf asset
		 */
		gaf_internal function getGAFTimelineByLinkage(linkage: String): GAFTimeline
		{
			return this._timelinesByLinkage[linkage];
		}

		gaf_internal function getCustomRegion(linkage: String, scale: Number = NaN, csf: Number = NaN): IGAFTexture
		{
			if (isNaN(scale)) scale = this._scale;
			if (isNaN(csf)) csf = this._csf;

			var gafTexture: IGAFTexture;
			var atlasScale: CTextureAtlasScale;
			var atlasCSF: CTextureAtlasCSF;
			var element: CTextureAtlasElement;
			for (var i: uint = 0, tasl: uint = this._config.allTextureAtlases.length; i < tasl; i++)
			{
				atlasScale = this._config.allTextureAtlases[i];
				if (atlasScale.scale == scale)
				{
					for (var j: uint = 0, tacsfl: uint = atlasScale.allContentScaleFactors.length; j < tacsfl; j++)
					{
						atlasCSF = atlasScale.allContentScaleFactors[j];
						if (atlasCSF.csf == csf)
						{
							element = atlasCSF.elements.getElementByLinkage(linkage);

							if (element)
							{
								var texture: Texture = atlasCSF.atlas.gaf_internal::getTextureByIDAndAtlasID(element.id, element.atlasID);
								var pivotMatrix: Matrix = element.pivotMatrix;
								if (element.scale9Grid != null)
								{
									gafTexture =  new GAFScale9Texture(id, texture, pivotMatrix, element.scale9Grid);
								}
								else
								{
									gafTexture =  new GAFTexture(id, texture, pivotMatrix);
								}
							}

							break;
						}
					}
					break;
				}
			}

			return gafTexture;
		}

		/** @private */
		gaf_internal function getValidScale(value: Number): Number
		{
			var index: int = MathUtility.getItemIndex(this._config.scaleValues, value);
			if (index != -1)
			{
				return this._config.scaleValues[index];
			}
			return NaN;
		}

		/** @private */
		gaf_internal function hasCSF(value: Number): Boolean
		{
			return MathUtility.getItemIndex(this._config.csfValues, value) >= 0;
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
		 * Returns all <code>GAFTimeline's</code> from gaf asset as <code>Vector</code>
		 * @return <code>GAFTimeline's</code> from gaf asset
		 */
		public function get timelines(): Vector.<GAFTimeline>
		{
			return this._timelines;
		}

		public function get id(): String
		{
			return this._config.id;
		}

		public function get scale(): Number
		{
			return this._scale;
		}

		public function set scale(value: Number): void
		{
			this._scale = value;
		}

		public function get csf(): Number
		{
			return this._csf;
		}

		public function set csf(value: Number): void
		{
			this._csf = value;
		}
	}
}
