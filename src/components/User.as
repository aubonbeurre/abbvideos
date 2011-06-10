package components
{
	import com.adobe.webapis.awss3.*;
	
	import flash.errors.EOFError;
	
	import mx.utils.StringUtil;

	public class User
	{
		public var name:String;
		public var passwd:String;
		public var root:Boolean;
		
		public function User(n:String, p:String, r:Boolean)
		{
			name = n;
			passwd = p;
			root = r;
		}

		static public function parseCredentials(txt:S3Object):Array {
			if(txt == null)
				return null;
				
			var reader:ByteArrayReader = new ByteArrayReader(txt.bytes);

			var pattern:RegExp = /(.*):(.*):(.*)/i;
			var res:Array = new Array();
			var reg:Array;
			try {
				while(1) {
					var line:String = reader.readLine();
					line = StringUtil.trim(line);
					reg = pattern.exec(line);
					if(reg) {
						res.push(new User(reg[1], reg[2], reg[3] == 'S'));
					}
				}
			} catch(e:EOFError) {
				
			}
			return res;
		}
	}
}