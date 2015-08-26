package
{
	import com.catalystapps.gaf.data.GAFBundle;
	import feathers.controls.text.BitmapFontTextEditor;
	import feathers.core.ITextEditor;
	import feathers.text.BitmapFontTextFormat;

	import starling.display.Sprite;

	import com.catalystapps.gaf.core.ZipToGAFAssetConverter;
	import com.catalystapps.gaf.display.GAFMovieClip;

	import flash.events.Event;
	import flash.utils.ByteArray;

	import starling.text.BitmapFont;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;

	public class BitmapFontGame extends Sprite
	{
		[Embed(source="../design/atlas.png")]
		private static const ICONS_IMAGE:Class;

		[Embed(source="../design/atlas.xml",mimeType="application/octet-stream")]
		private static const ICONS_XML:Class;

		[Embed(source="../design/arial20.fnt",mimeType="application/octet-stream")]
		private static const FONT_XML:Class;

		[Embed(source="../design/bitmap_font.zip", mimeType="application/octet-stream")]
		private static const GAFAssetData: Class;

		private var _textureAtlas:TextureAtlas;
		private var _font: BitmapFont;

		public function BitmapFontGame()
		{
			this.initGAF();
		}

		private function initGAF(): void
		{
			this._textureAtlas = new TextureAtlas(Texture.fromBitmap(new ICONS_IMAGE(), false), XML(new ICONS_XML()));
			this._font = new BitmapFont(this._textureAtlas.getTexture("arial20_0"), XML(new FONT_XML()));

			var zip: ByteArray = new GAFAssetData();

			var converter: ZipToGAFAssetConverter = new ZipToGAFAssetConverter();
			converter.addEventListener(Event.COMPLETE, this.onGAFAssetConverted);
			converter.convert(zip);
		}

		private function onGAFAssetConverted(event: Event): void
		{
			var bundle: GAFBundle = (event.target as ZipToGAFAssetConverter).gafBundle;
			var mc: GAFMovieClip = new GAFMovieClip(bundle.getGAFTimeline("bitmap_font"));

			mc.tf.textEditorProperties = null; // clearing all properties that used by GAFTextFieldTextEditor
			mc.tf.textEditorFactory = textEditorRendererFactory; // assign BitmapFontTextEditor

			this.addChild(mc);
			mc.play();
		}

		private function textEditorRendererFactory(): ITextEditor
		{
			var renderer: BitmapFontTextEditor = new BitmapFontTextEditor();
			renderer.textFormat = new BitmapFontTextFormat(this._font, NaN, 0xFF0000);
			return renderer;
		}
	}
}
