require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Managing a database" do
  
  before(:each) do
    @client = Couchlogic::Client
  end
  
  it "should get info about the current database" do
    response = @client.database_info
    response.should be_an_instance_of(Hash)
    response['db_name'].should == TESTDB
  end

  it "should create a database" do
    Couchlogic.couchdb = TESTDB2
    @client.databases.should_not include(TESTDB2)
    @client.create!
    @client.databases.should include(TESTDB2)
    @client.delete!(true)
  end

  it "should NOT delete a database unless a confirm flag is present" do
    @client.databases.should include(TESTDB)
    @client.delete!
    @client.databases.should include(TESTDB)
  end

  it "should delete a database when a confirm flag is present" do
    @client.databases.should include(TESTDB)
    @client.delete!(true)
    @client.databases.should_not include(TESTDB)
  end

  it "should compact a database" do
    @client.create! rescue nil
    @client.compact!
  end
  
end