require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Couchlogic" do
  
  before(:each) do
    @client = Couchlogic::Client
  end
  
  it "should return the version of the gem" do
    Couchlogic.version.should =~ /[0-9].[0-9].[0-9]/
  end
  
  describe "intializing the gem" do
    
    it "should use localhost if only a db name is given" do
      Couchlogic.couchdb = "some_db"
      Couchlogic.couchdb.should == "http://127.0.0.1:5984/some_db"
      Couchlogic.couch_server.should == "http://127.0.0.1:5984"
    end
    
    it "should initialize when a full URI to the couch is provided" do
      Couchlogic.couchdb = "http://couchdb.apache.org:5984/some_db"
      Couchlogic.couchdb.should == "http://couchdb.apache.org:5984/some_db"
      Couchlogic.couch_server.should == "http://couchdb.apache.org:5984"
    end
    
    it "should parse the HTTP credentials when specified" do
      Couchlogic.couchdb = "https://joe:pass@couchdb.apache.org:5984/some_db"
      Couchlogic.couch_server.should == "https://couchdb.apache.org:5984"
      Couchlogic.username.should == "joe"
      Couchlogic.password.should == "pass"
    end
    
  end
  
end
