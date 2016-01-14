/**
 * Created by Nazar on 12.01.2016.
 */
package com.catalystapps.gaf.utils
{
	import com.catalystapps.gaf.data.tagfx.GAFATFData;

	import flash.display3D.Context3DTextureFormat;

	import flash.geom.Point;
	import flash.utils.IDataInput;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	/**
	 * @private
	 */
	public class FileUtils
	{
		private static const PNG_HEADER: Vector.<uint> = new <uint>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
		//private static const PNG_IHDR: Vector.<uint> = new <uint>[0x49, 0x48, 0x44, 0x52];
		/**
		 * Determines texture atlas size in pixels from file.
		 * @param file Texture atlas file.
		 */
		public static function getPNGSize(file: /*flash.filesystem::File*/ Object): Point
		{
			if (!file || getQualifiedClassName(file) != "flash.filesystem::File")
					throw new ArgumentError("Argument \"file\" is not \"flash.filesystem::File\" type.");

			var FileStreamClass: Class = getDefinitionByName("flash.filesystem::FileStream") as Class;
			var fileStream: * = new FileStreamClass();
			fileStream.open(file, "read");

			var size: Point;
			if (isPNGData(fileStream))
			{
				fileStream.position = 16;
				size = new Point(fileStream.readUnsignedInt(), fileStream.readUnsignedInt());
			}

			fileStream.close();

			return size;
		}

		public static function getATFData(file: /*flash.filesystem::File*/ Object): GAFATFData
		{
			if (!file || getQualifiedClassName(file) != "flash.filesystem::File")
				throw new ArgumentError("Argument \"file\" is not \"flash.filesystem::File\" type.");

			var FileStreamClass: Class = getDefinitionByName("flash.filesystem::FileStream") as Class;
			var fileStream: * = new FileStreamClass();
			fileStream.open(file, "read");

			if (isAtfData(fileStream))
			{
				fileStream.position = 6;
				if (fileStream.readUnsignedByte() == 255) // new file version
					fileStream.position = 12;
				else
					fileStream.position = 6;

				var atfData: GAFATFData = new GAFATFData();

				var format:uint = fileStream.readUnsignedByte();
				switch (format & 0x7f)
				{
					case  0:
					case  1: atfData.format = Context3DTextureFormat.BGRA; break;
					case 12:
					case  2:
					case  3: atfData.format = Context3DTextureFormat.COMPRESSED; break;
					case 13:
					case  4:
					case  5: atfData.format = "compressedAlpha"; break; // explicit string for compatibility
					default: throw new Error("Invalid ATF format");
				}

				atfData.width = Math.pow(2, fileStream.readUnsignedByte());
				atfData.height = Math.pow(2, fileStream.readUnsignedByte());
				atfData.numTextures = fileStream.readUnsignedByte();
				atfData.isCubeMap = (format & 0x80) != 0;

				return atfData;
			}

			return null;
		}

		/** Checks the first 3 bytes of the data for the 'ATF' signature. */
		public static function isAtfData(data: IDataInput): Boolean
		{
			if (data.bytesAvailable < 3) return false;
			else
			{
				var signature: String = String.fromCharCode(
						data.readUnsignedByte(), data.readUnsignedByte(), data.readUnsignedByte());
				return signature == "ATF";
			}
		}

		/** Checks the first 3 bytes of the data for the 'ATF' signature. */
		public static function isPNGData(data: IDataInput): Boolean
		{
			if (data.bytesAvailable < 16) return false;
			else
			{
				var i: uint, l: uint;
				for (i = 0, l = PNG_HEADER.length; i < l; ++i)
				{
					if (PNG_HEADER[i] != data.readUnsignedByte())
							return false;
				}

				data.readUnsignedInt(); // seek IHDR

				var ihdr: String = String.fromCharCode(
						data.readUnsignedByte(), data.readUnsignedByte(), data.readUnsignedByte(), data.readUnsignedByte());
				return ihdr == "IHDR";
			}
		}
	}
}
