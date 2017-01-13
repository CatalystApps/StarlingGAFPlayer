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
		private var _gun1: IGAFTexture;
		private var _gun2: IGAFTexture;
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
			var gafBundle: GAFBundle = (event.target as ZipToGAFAssetConverter).gafBundle;
			//"gun_swap" - the name of the SWF which was converted to GAF
			var gafTimeline: GAFTimeline = gafBundle.getGAFTimeline("gun_swap", "rootTimeline");

			this._gafMovieClip = new GAFMovieClip(gafTimeline);
			this._gafMovieClip.play(true);

			this._gunSlot = this._gafMovieClip.getChildByName("GUN") as GAFImage;

			this._gun1 = gafBundle.getCustomRegion("gun_swap", "gun1");
			this._gun2 = gafBundle.getCustomRegion("gun_swap", "gun2");
			//"gun2" texture is made from Bitmap
			//thus we need to adjust its' pivot matrix
			this._gun2.pivotMatrix.translate(-24.2, -41.55);

			this.setGun(this._gun1);

			this.addChild(this._gafMovieClip);

			stage.addEventListener(TouchEvent.TOUCH, this.onTouch);
		}

		private function onTouch(event: TouchEvent): void
		{
			var touch: Touch = event.getTouch(this as Sprite, TouchPhase.BEGAN);
			if (touch)
			{
				if (this._currentGun == this._gun2)
				{
					setGun(this._gun1);
				}
				else
				{
					setGun(this._gun2);
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
