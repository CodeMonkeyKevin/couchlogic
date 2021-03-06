$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'couchlogic'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

unless defined?(FIXTURE_PATH)
  FIXTURE_PATH = File.join(File.dirname(__FILE__), '/fixtures')
  SCRATCH_PATH = File.join(File.dirname(__FILE__), '/tmp')

  TESTDB        = 'couchlogic-test'
  TESTDB2       = 'couchlogic-test-2'
  REPLICATIONDB = 'couchlogic-test-replication'
end

def reset_test_db!    
  Couchlogic::Client.delete!(true) rescue nil
  Couchlogic::Client.create! rescue nil
end

RSpec.configure do |config|  
  config.before(:all) do
    Couchlogic.couchdb = TESTDB
    Couchlogic::Client.proxy = nil
    Couchlogic::Client.debug = false
    reset_test_db!
  end
  
  config.before(:each) do
    Couchlogic.couchdb = TESTDB
    Couchlogic::Client.proxy = nil
    Couchlogic::Client.debug = false
  end
  
  config.after(:suite) { Couchlogic::Client.delete!(true) }
end

def couchdb_lucene_available?
  lucene_path = "http://localhost:5985/"
  url = URI.parse(lucene_path)
  req = Net::HTTP::Get.new(url.path)
  res = Net::HTTP.new(url.host, url.port).start { |http| http.request(req) }
  true
 rescue Exception => e
  false
end
