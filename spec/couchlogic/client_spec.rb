require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Couchlogic client" do
  
  before(:each) do
    @client = Couchlogic::Client
  end
  
  describe "connection settings" do
    
    it "should accept a proxy URI to use when connecting to CouchDB" do
      @client.connection.proxy_uri.should == nil
      proxy_uri = "http://localhost:8080"
      @client.proxy = proxy_uri
      @client.connection.proxy_uri.should == proxy_uri
    end
    
    it "should perform in debug mode when specified" do
      @client.connection.debug.should == false
      @client.debug = true
      @client.connection.debug.should == true
    end
    
  end 
  
  describe "retrieve information about the CouchDB server" do
    
    it "should list databases" do
      @client.databases.should be_an_instance_of(Array)
    end
    
    it "should get info" do
      response = @client.couchdb_info
      response["couchdb"].should == "Welcome"
      response.class.should == Hash   
    end
    
  end
  
  describe "managing the CouchDB server" do
    
    #it "should restart" do
    #  @client.restart!
    #  begin
    #    @client.database_info
    #  rescue
    #    sleep 0.2
    #    retry
    #  end
    #end
  
    it "should provide a uuid when requested" do
      @client.next_uuid.should_not be_nil
    end
    
  end
  
end