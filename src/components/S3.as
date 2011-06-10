package components
{
	import com.adobe.webapis.awss3.*;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	
	[Bindable] 
	public dynamic class S3 extends AWSS3
	{
		private var myaccessKey:String = "1KYC5FFXPQPJ2SFK6T02";
		private var mysecretAccessKey:String = "BD+hrKU0B9AaPwzGnA/+z5vMD3jo4wu2EfWhg1+V";

		public static var s3errors:Array = [
			IOErrorEvent.IO_ERROR,
			AWSS3Event.ERROR,
			AWSS3Event.REQUEST_FORBIDDEN
		];

		public function S3() {
			super(this.myaccessKey, this.mysecretAccessKey);
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
			
			s1.deleteObject("aubonbeurre", m.txt.key);
			s2.deleteObject("aubonbeurre", m.png.key);
			
			mev.add_target(s1);
			mev.add_target(s2);

			var s:S3;
			if(m.parts) {
				for each(var o:S3Object in m.parts) {
					s = new S3()
					s.deleteObject("aubonbeurre", o.key);
					mev.add_target(s);
				}
			}
			else {
				s = new S3()
				s.deleteObject("aubonbeurre", m.mp4.key);
				mev.add_target(s);
			}
		}
		
	}
}
