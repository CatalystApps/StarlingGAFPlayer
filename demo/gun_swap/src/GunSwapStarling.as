package
{
	import com.catalystapps.gaf.data.GAFTimeline;
	import com.catalystapps.gaf.data.GAFBundle;
	import com.catalystapps.gaf.display.IGAFTexture;
	import com.catalystapps.gaf.display.GAFImage;
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
			var gafBundle: GAFBundle = converter.gafBundle;
			var gafTimeline: GAFTimeline = gafBundle.getGAFTimeline("gun_swap", "robot");

			this._gafMovieClip = new GAFMovieClip(gafTimeline);
			this._gafMovieClip.play(true);
			this._gafMovieClip.setSequence("walk_right");

			this._gunSlot = this._gafMovieClip.getChildByName("GUN") as GAFImage;

			this._redGun  = gafBundle.getCustomRegion("gun_swap", "gun");
			this._blueGun = gafBundle.getCustomRegion("gun_swap", "gun2");
			//this is the texture, made from exported bitmap
			//thus we need to adjust its' pivot matrix
			this._blueGun.pivotMatrix.translate(-24.2, -41.55);

			this.setGun(this._redGun);

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
					this.setGun(this._redGun);
				}
				else
				{
					this.setGun(this._blueGun);
				}
			}
		}

		private function setGun(gun: IGAFTexture): void
		{
			this._currentGun = gun;
			this._gunSlot.changeTexture(gun);
		}
	}
}
