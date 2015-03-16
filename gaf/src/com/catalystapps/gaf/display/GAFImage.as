package com.catalystapps.gaf.display
{
	import com.catalystapps.gaf.core.gaf_internal;
	import com.catalystapps.gaf.data.config.CFilter;
	import com.catalystapps.gaf.filter.GAFFilter;

	import starling.core.Starling;

	import starling.display.Image;

	/**
	 * @private
	 */
	public class GAFImage extends Image implements IGAFImage, IGAFDebug
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

		private var _assetTexture: IGAFTexture;
		private var _zIndex: uint;

		private var _filterConfig: CFilter;
		private var _filterScale: Number;

		gaf_internal var __debugOriginalAlpha: Number = NaN;

		//--------------------------------------------------------------------------
		//
		//  CONSTRUCTOR
		//
		//--------------------------------------------------------------------------

		/**
		 * GAFImage represents display object that is part of the <code>GAFMovieClip</code>
		 * @param assetTexture The texture displayed by this image.
		 * @see com.catalystapps.gaf.display.GAFScale9Image
		 */
		public function GAFImage(assetTexture: IGAFTexture)
		{
			this._assetTexture = assetTexture.clone();

			super(this._assetTexture.texture);
		}

		//--------------------------------------------------------------------------
		//
		//  PUBLIC METHODS
		//
		//--------------------------------------------------------------------------

		public function invalidateSize(): void
		{
		}

		public function set debugColors(value: Vector.<uint>): void
		{
			var alpha0: Number;
			var alpha1: Number;

			switch (value.length)
			{
				case 1:
					this.color = value[0];
					this.alpha = (value[0] >>> 24) / 255;
					break;
				case 2:
					this.setVertexColor(0, value[0]);
					this.setVertexColor(1, value[0]);
					this.setVertexColor(2, value[1]);
					this.setVertexColor(3, value[1]);

					alpha0 = (value[0] >>> 24) / 255;
					alpha1 = (value[1] >>> 24) / 255;
					this.setVertexAlpha(0, alpha0);
					this.setVertexAlpha(1, alpha0);
					this.setVertexAlpha(2, alpha1);
					this.setVertexAlpha(3, alpha1);
					break;
				case 3:
					this.setVertexColor(0, value[0]);
					this.setVertexColor(1, value[0]);
					this.setVertexColor(2, value[1]);
					this.setVertexColor(3, value[2]);

					alpha0 = (value[0] >>> 24) / 255;
					this.setVertexAlpha(0, alpha0);
					this.setVertexAlpha(1, alpha0);
					this.setVertexAlpha(2, (value[1] >>> 24) / 255);
					this.setVertexAlpha(3, (value[2] >>> 24) / 255);
					break;
				case 4:
					this.setVertexColor(0, value[0]);
					this.setVertexColor(1, value[1]);
					this.setVertexColor(2, value[2]);
					this.setVertexColor(3, value[3]);

					this.setVertexAlpha(0, (value[0] >>> 24) / 255);
					this.setVertexAlpha(1, (value[1] >>> 24) / 255);
					this.setVertexAlpha(2, (value[2] >>> 24) / 255);
					this.setVertexAlpha(3, (value[3] >>> 24) / 255);
					break;
			}
		}

		public function changeTexture(newTexture: IGAFTexture): void
		{
			this.texture = newTexture.texture;
			this.readjustSize();
			this._assetTexture.copyFrom(newTexture);
		}

		/** @private */
		public function setFilterConfig(value: CFilter, scale: Number = 1): void
		{
			if (!Starling.current.contextValid)
			{
				return;
			}

			if (_filterConfig != value || _filterScale != scale)
			{
				if (value)
				{
					this._filterConfig = value;
					this._filterScale = scale;
					var gafFilter: GAFFilter;
					if (this.filter)
					{
						if (this.filter is GAFFilter)
						{
							gafFilter = this.filter as GAFFilter;
						}
						else
						{
							this.filter.dispose();
							gafFilter = new GAFFilter();
						}
					}
					else
					{
						gafFilter = new GAFFilter();
					}

					gafFilter.setConfig(this._filterConfig, this._filterScale);
					this.filter = gafFilter;
				}
				else
				{
					if (this.filter)
					{
						this.filter.dispose();
						this.filter = null;
					}
					this._filterConfig = null;
					this._filterScale = NaN;
				}
			}
		}

		//--------------------------------------------------------------------------
		//
		//  PRIVATE METHODS
		//
		//--------------------------------------------------------------------------

		gaf_internal function __debugHighlight(): void
		{
			use namespace gaf_internal;
			if (isNaN(__debugOriginalAlpha))
			{
				__debugOriginalAlpha = this.alpha;
			}
			this.alpha = 1;
		}

		gaf_internal function __debugLowlight(): void
		{
			use namespace gaf_internal;
			if (isNaN(__debugOriginalAlpha))
			{
				__debugOriginalAlpha = this.alpha;
			}
			this.alpha = .05;
		}

		gaf_internal function __debugResetLight(): void
		{
			use namespace gaf_internal;
			if (!isNaN(__debugOriginalAlpha))
			{
				this.alpha = __debugOriginalAlpha;
				__debugOriginalAlpha = NaN;
			}
		}

		//--------------------------------------------------------------------------
		//
		// OVERRIDDEN METHODS
		//
		//--------------------------------------------------------------------------

		/**
		 * Disposes all resources of the display object
		 */
		override public function dispose(): void
		{
			(this.filter) ? this.filter.dispose() : null;
			this.filter = null;

			super.dispose();
		}

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

		public function get assetTexture(): IGAFTexture
		{
			return _assetTexture;
		}

		public function get zIndex(): uint
		{
			return _zIndex;
		}

		public function set zIndex(value: uint): void
		{
			_zIndex = value;
		}
	}
}
