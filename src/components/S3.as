package components
{
	import com.adobe.webapis.awss3.*;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	
	[Bindable] 
	public dynamic class S3 extends AWSS3
	{
		static public var myaccessKey:String = "";
		static public var mysecretAccessKey:String = "";
		static public var mybucket:String = "";

		public static var s3errors:Array = [
			IOErrorEvent.IO_ERROR,
			AWSS3Event.ERROR,
			AWSS3Event.REQUEST_FORBIDDEN
		];

		public function S3() {
			var accessKey:String = S3.myaccessKey;
			var secretAccessKey:String = S3.mysecretAccessKey;
			super(accessKey, secretAccessKey);
		}

		public function delete_movie(m:Movie):void { // AWSS3Event.OBJECT_DELETED
			var this_obj:S3 = this;
			
			var mev:MetaEventDispatcher = new MetaEventDispatcher([AWSS3Event.OBJECT_DELETED,], s3errors);
			
			mev.addEventListener(AWSS3Event.OBJECT_DELETED, function(e:Event): void {
				this_obj.dispatchEvent(e);
			});
			
			for each(var err:String in s3errors) {
				mev.addEventListener(err, function(e:Event): void {
					this_obj.dispatchEvent(e);
				});
			}

			var s1:S3 = new S3();
			var s2:S3 = new S3();
			
			s1.deleteObject(S3.mybucket, m.txt.key);
			s2.deleteObject(S3.mybucket, m.png.key);
			
			mev.add_target(s1);
			mev.add_target(s2);

			var s:S3 = new S3()
			s.deleteObject(S3.mybucket, m.mp4.key);
			mev.add_target(s);
		}
		
	}
}
