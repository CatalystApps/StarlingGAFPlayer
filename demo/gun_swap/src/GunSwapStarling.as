package
{
	import com.catalystapps.gaf.display.IGAFTexture;
	import com.catalystapps.gaf.display.GAFImage;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.Event;
	import flash.utils.ByteArray;

	/**
	 * @author Ivan Avdeenko
	 */
	public class GunSwapStarling extends Sprite
	{
		private var _gafMovieClip: GAFMovieClip;
		private var _gunSlot: GAFImage;
		private var _redGun: IGAFTexture;
		private var _blueGun: IGAFTexture;
		private var _currentGun: IGAFTexture;

		[Embed(source="../design/gun_swap.zip", mimeType="application/octet-stream")]
		private var asset: Class;

		public function GunSwapStarling()
		{
			var zip: ByteArray = new asset();
			var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
			converter.addEventListener(Event.COMPLETE, this.onConverted);
			converter.convert(zip);
		}

		private function onConverted(event: Event): void
		{
			var converter: ZipToGAFAssetConverter = event.target as ZipToGAFAssetConverter;

			this._gafMovieClip = new GAFMovieClip(converter.gafTimeline);
			this._gafMovieClip.play(true);
			this._gafMovieClip.setSequence("walk_right");
			this._gafMovieClip.x = stage.stageWidth / 2;
			this._gafMovieClip.y = stage.stageHeight / 2;

			this._gunSlot = this._gafMovieClip.getChildByName("GUN") as GAFImage;

			this._redGun  = converter.gafBundle.getCustomRegion(converter.gafTimeline.assetID, "gun");
			this._blueGun = converter.gafBundle.getCustomRegion(converter.gafTimeline.assetID, "gun2");
			//this is the texture, made from exported bitmap
			//thus we need to adjust its' pivot matrix
			this._blueGun.pivotMatrix.translate(-24.2, -41.55);

			this._currentGun = this._redGun;
			this.setGun(this._currentGun);

			this.addChild(this._gafMovieClip);

			stage.addEventListener(TouchEvent.TOUCH, this.onTouch);
		}

		private function onTouch(event: TouchEvent): void
		{
			var touch: Touch = event.getTouch(this, TouchPhase.BEGAN);
			if (touch)
			{
				if (this._currentGun == this._blueGun)
				{
					this._currentGun = this._redGun;
				}
				else
				{
					this._currentGun = this._blueGun;
				}
				setGun(this._currentGun);
			}
		}

		private function setGun(gun: IGAFTexture): void
		{
			this._gunSlot.changeTexture(gun);
		}
	}
}
