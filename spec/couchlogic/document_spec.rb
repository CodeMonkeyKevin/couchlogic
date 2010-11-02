require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Couchlogic client" do
  
  before(:each) do
    @client = Couchlogic::Client
  end
  
  describe "managing documents" do
    
    it "should show a list of all documents" do
      @client.documents['rows'].should be_an_instance_of(Array)
    end
    
    it "should persist a document" do
      @client.documents['total_rows'].should == 0
      @client.save_doc({ 'first_name' => 'ayrton', 'last_name' => 'senna' })
      @client.documents['total_rows'].should == 1
    end
    
    it "should be able to fetch a document given an id" do
      doc = @client.save_doc({ 'foo' => 'bar' })
      doc['id'].should_not be_nil
      fetched_doc = @client.fetch_doc(doc['id'])
      fetched_doc['foo'].should == 'bar'
    end
    
    it "should persist a document with a custom id" do
      doc = { 'name' => 'Ayrton Senna', '_id' => "o_melhor" }
      @client.save_doc(doc)
      @client.fetch_doc('o_melhor')['name'].should == "Ayrton Senna"
    end
    
    it "should delete an existing document" do
      doc = @client.save_doc({ 'foo' => 'bar' })
      actual_doc = @client.fetch_doc(doc['id'])
      doc['id'].should == actual_doc['_id']
      @client.delete_doc(actual_doc)
      lambda {
        @client.fetch_doc(actual_doc['_id'])
      }.should raise_error(Couchlogic::NotFound)
    end
    
    it "should update a document" do
      doc = @client.save_doc({ 'foo' => 'bar' })
      @client.update_doc(doc['id']) do |d|
        d['foo'] = 'baz'
        d
      end
      @client.fetch_doc(doc['id'])['foo'].should == 'baz'
    end
    
  end
  
end