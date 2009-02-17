package managers
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	public class ConfigManager
	{
		private static const configDir:File = File.applicationStorageDirectory.resolvePath("config/");
		private static var instance:ConfigManager;

		public function ConfigManager() {}

		public static function getInstance():ConfigManager {
            if (instance == null)
            {
                instance = new ConfigManager();
            }

            return instance;
        }

		public static function getConfig(key:String, def:String=""):String {
			var cacheFile:File = new File(configDir.nativePath +File.separator+ key);
			var stream:FileStream = new FileStream();
			var result:String = def;
			try {
				stream.open(cacheFile, FileMode.READ);
				result = stream.readUTFBytes(stream.bytesAvailable);
				stream.close();
			} catch (e:*) {}
			return result;
		}
		
		public static function setConfig(key:String, val:String):void {
			var cacheFile:File = new File(configDir.nativePath +File.separator+ key);
			var stream:FileStream = new FileStream();
			try {
				stream.open(cacheFile, FileMode.WRITE);
				stream.writeUTFBytes(val);
				stream.close();
			} catch (e:*) {}
		}
	}
}