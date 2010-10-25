require 'uri'
require 'yajl'
require 'curb'

# = Couchlogic, advanced Ruby interface for CouchDB
module Couchlogic
  
  class << self
    
    attr_reader :couchdb, :couch_server
    attr_accessor :username, :password, :uuid_batch_count
    
  end
  
  # Accepts:
  #   1. A fully qualified path to your CouchDB server, including port and 
  #      credential information, e.g. https://u:p@32.43.66.36:5984/my_db
  #   2. A database name for databases residing on your localhost running on the
  #      default CouchDB port (5984)
  def self.couchdb=(server_or_db_name)
    if server_or_db_name.match(%r{https?://})
      couchdb_uri = URI::parse(server_or_db_name)
      
      unless couchdb_uri.user.nil?
        @username = couchdb_uri.user
        @password = couchdb_uri.password
      end
      
      @couchdb = server_or_db_name
      @couch_server = strip_db_from_uri(couchdb_uri)
    else
      @couchdb = "http://127.0.0.1:5984/#{server_or_db_name}"
      @couch_server = "http://127.0.0.1:5984"
    end
  end
  
  # Returns the version of Couchlogic
  def self.version
    File.read(File.join(File.dirname(__FILE__), '..', 'VERSION'))
  end
  
private
  
  def self.strip_db_from_uri(uri)
    "#{uri.scheme}://#{uri.host}:#{uri.port}"
  end
  
end

require 'couchlogic/errors'
require 'couchlogic/helpers'

require 'couchlogic/client/response'
require 'couchlogic/client/connection'
require 'couchlogic/client/endpoint'
require 'couchlogic/client/client'
