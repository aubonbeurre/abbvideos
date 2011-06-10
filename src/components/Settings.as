package components
{
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.errors.SQLError;
	import flash.filesystem.File;
	import flash.net.NetConnection;	
	import flash.net.FileReference;	

	public class Settings
	{
		private var db:SQLConnection = new SQLConnection();
		
		[Bindable]
		public var username:String;
		[Bindable]
		public var password:String;
		
		public function Settings()
		{
			super();
			
			var dbFile:File = File.applicationStorageDirectory.resolvePath("settings.db");

			try
			{
			    db.open(dbFile, SQLMode.CREATE);
			    
			    // start a transaction
				db.begin();
			    var dbStatement:SQLStatement = new SQLStatement();
			    dbStatement.sqlConnection = db;
				dbStatement.text = "CREATE TABLE IF NOT EXISTS settings ( name TEXT PRIMARY KEY, value TEXT )";
        		dbStatement.execute();
        		
        		// if we've gotten to this point without errors, commit the transaction
 				db.commit();

			}
			catch (error:SQLError)
			{
			    trace("Error message:", error.message);
			    trace("Details:", error.details);
			    throw error;
			}

			username = getsetting("username");
			password = getsetting("password");
		}
		
		public function getsetting(name:String):String
		{
		    // start a transaction
			db.begin();

		    var dbStatement:SQLStatement  = new SQLStatement();
		    dbStatement.sqlConnection = db;
		    dbStatement.parameters[":name"] = name;
			dbStatement.text = "SELECT value FROM settings WHERE name=:name";
    		dbStatement.execute();
    		
    		var res:SQLResult = dbStatement.getResult();
    		if(res.data && res.data[0])
    			return res.data[0].value;

			return null;
		}
		
		public function setsetting(name:String, value:String):void
		{
		    // start a transaction
			db.begin();

		    var dbStatement:SQLStatement = new SQLStatement();
		    dbStatement.sqlConnection = db;
		    dbStatement.parameters[":name"] = name;
			dbStatement.text = "DELETE FROM settings where name=:name";
    		dbStatement.execute();
    		
		    dbStatement = new SQLStatement();
		    dbStatement.sqlConnection = db;
		    dbStatement.parameters[":name"] = name;
		    dbStatement.parameters[":value"] = value;
			dbStatement.text = "INSERT INTO settings (name, value) VALUES(:name, :value)";
    		dbStatement.execute();
		}

		public function deletesettings():void
		{
		    // start a transaction
			db.begin();

		    var dbStatement:SQLStatement = new SQLStatement();
		    dbStatement.sqlConnection = db;
			dbStatement.text = "DELETE FROM settings";
    		dbStatement.execute();
		}

		 public function setAuthentication(uname:String, pword:String):void {
			setsetting("username", username);
			setsetting("password", password);
		}
	}
}