module Couchlogic

  class Client
   
    UUID_BATCH_COUNT = 1000
    BULK_SAVE_CACHE_LIMIT = 750
   
    @@connection = Couchlogic::Connection.new
    @@bulk_save_cache = []
    @@debug = false
    @@proxy = nil

    class << self

      # Set this to <tt>true</tt> to enable debug mode
      #
      # Debug mode will output the raw HTTP requests being sent to your CouchDB
      # server. This mode is only useful when developing Couchlogic.
      def debug=(debug_flag)
        @@debug = debug_flag
        @@connection.debug = @@debug if @@connection
      end

      # Displays whether or not Couchlogic is operating in debug mode.
      def debug
        @@debug
      end
      
      # Accepts a fully qualified proxy URI
      #
      # Couchlogic will use this proxy when sending HTTP requests to your
      # CouchDB server.
      def proxy=(proxy_uri)
        @@proxy = proxy_uri
        @@connection.proxy_uri = @@proxy if @@connection
      end
      
      # Access the connection directly
      def connection
        @@connection
      end
      
      # Retrive info about CouchDB
      def couchdb_info
        get Endpoint.root_uri
      end
      
      # Retrive info about the current database
      def database_info
        get Endpoint.endpoint_uri
      end
      
      # Save a document to CouchDB. This will use the <tt>_id</tt> field from
      # the document as the id for PUT, or request a new UUID from CouchDB, if
      # no <tt>_id</tt> is present on the document. 
      #
      # If <tt>bulk</tt> is set to true (false by default) the document is 
      # cached for bulk-saving later. Bulk saving is triggered automatically 
      # when #bulk_save_cache limit is exceded, or on the next non-bulk save.
      #
      # If <tt>batch</tt> is set to true (false by default) the document is
      # saved in batch mode whereby higher throughput is acheived at the cost
      # of lower guarantees. Saves sent using this option are not immediately
      # written to disk. Instead it is stored in memory on a per-user basis for 
      # a second or so (or after the number of docs in memory exceeds a defined
      # threshold). After the threshold has passed, the docs are committed to 
      # disk. Note: using batch mode is not suitable for crucial data, but it 
      # is ideal for applications, like logging, which can accept the risk that 
      # a small subset of updates could be lost in the event of server a crash.
      def save_doc(doc, bulk = false, batch = false)
        if doc['_attachments']
          doc['_attachments'] = encode_attachments(doc['_attachments'])
        end
        
        if bulk
          @@bulk_save_cache << doc
          bulk_save if @@bulk_save_cache.length >= BULK_SAVE_CACHE_LIMIT
          return { "ok" => true }
        elsif !bulk && @@bulk_save_cache.length > 0
          bulk_save
        end
        
        if doc['_id']
          slug = escape_docid(doc['_id'])    
          response = put(Endpoint.document_uri(slug, batch), doc)
        else
          slug = doc['_id'] = next_uuid
          response = put(Endpoint.document_uri(slug, batch), doc)
        end
        
        if response['ok']
          doc['_id'] = response['id']
          doc['_rev'] = response['rev']
        end
        
        response
      end
      
      # Save a document to CouchDB in bulk mode
      # See #save_doc's description of the +bulk+ argument
      def bulk_save_doc(doc)
        save_doc doc, true
      end

      # Save a document to CouchDB in batch mode
      # See #save_doc's description of the +batch+ argument
      def batch_save_doc(doc)
        save_doc doc, false, true
      end
      
      # Sends an array of documents to CouchDB for saving. 
      # If any of the documents are missing ids, one is automatically supplied.
      #
      # If called with no arguments, bulk_save will submit all of the documents
      # in the bulk save cache to CouchDB to be saved.
      def bulk_save(docs = nil, use_uuids = true)
        if docs.nil?
          docs = @@bulk_save_cache
          @@bulk_save_cache = []
        end
        
        if (use_uuids) 
          with_ids, without_ids = docs.partition { |d| d['_id'] }
          uuid_count = [without_ids.length, UUID_BATCH_COUNT].max
          without_ids.each do |doc|
            next_id = next_uuid(uuid_count) rescue nil
            doc['_id'] = nextid if nextid
          end
        end
        
        post Endpoint.bulk_docs_uri, { :docs => docs }
      end
      alias :bulk_delete :bulk_save
      
      # Fetches a document given a document ID
      def fetch_doc(id, params = {})
        slug = escape_docid(id)
        get Endpoint.document_uri(slug), params
      end

      # Deletes the specified document from CouchDB. 
      # The corresponding document must have matching <tt>_id</tt> and 
      # <tt>_rev</tt> attributes.
      #
      # If <tt>bulk</tt> is set to true (false by default) the deletion is 
      # cached for bulk-deletion. Bulk saving and deletion is triggered 
      # automatically when the #bulk_save_cache limit is exceded, or on the next 
      # non-bulk save.
      def delete_doc(doc, bulk = false)
        unless doc['_id'] && doc['_rev']
          raise ArgumentError, "_id and _rev are required for deleting" 
        end
             
        if bulk
          d = { '_id' => doc['_id'], '_rev' => doc['_rev'], '_deleted' => true }
          @@bulk_save_cache << d
          return bulk_save if @@bulk_save_cache.length >= BULK_SAVE_CACHE_LIMIT
          return { "ok" => true }
        end
        
        slug = escape_docid(doc['_id']) 
        params = { :rev => doc['_rev'] }       
        delete Endpoint.document_uri(slug), params
      end

      # Copies the specified document to a new id. If you are performing an
      # overwrite and the destination id already exists, a rev must be provided.
      #
      # The <tt>dest</tt> argument can take one of two forms if overwriting: 
      #   1. A string: "<id_to_overwrite>?rev=<revision>" or 
      #   2. The actual doc hash with a '_rev' key
      def copy_doc(doc, dest)
        unless doc['_id']
          raise ArgumentError, "_id is required for the document being copied"
        end
        
        slug = escape_docid(doc['_id'])        
        if dest.respond_to?(:has_key?) && dest['_id'] && dest['_rev']
          destination = "#{dest['_id']}?rev=#{dest['_rev']}"
        else
          destination = dest
        end
        
        copy Endpoint.document_uri(slug), destination
      end

      # Updates the specified document by yielding the current state of the doc
      # and trying to update <tt>update_limit</tt> times. Returns the new doc
      # if the doc was successfully updated before hitting the limit.
      def update_doc(doc_id, params = {}, update_limit = 10)
        response = { 'ok' => false }
        new_doc = nil
        last_fail = nil

        while response['ok'] || update_limit <= 0
          doc = get(Endpoint.document_uri(doc_id), params)
          new_doc = yield doc
          begin
            response = save_doc(new_doc)
          rescue Couchlogic::RequestFailed => e
            if e.http_code == 409
              update_limit -= 1
              last_fail = e
            else
              raise e
            end
          end
        end

        raise last_fail unless response['ok']
        
        new_doc
      end
      
      # Retrive an attachment directly from CouchDB
      def fetch_attachment(doc, attachment_name)
        get Endpoint.attachment_uri(doc, attachment_name)
      end

      # Upload an attachment directly to CouchDB
      def put_attachment(doc, attachment_name, attachment, options = {})
        # put Endpoint.attachment_uri(doc, attachment_name), attachment
      end

      # Delete an attachment directly from CouchDB
      def delete_attachment(doc, attachment_name)
        delete Endpoint.attachment_uri(doc, attachment_name)
      end

      # Query a CouchDB view as defined by a <tt>_design</tt> document. Accepts
      # paramaters as described in http://wiki.apache.org/couchdb/HttpViewApi
      #
      # This requires you to specify the name of the design document in addition
      # to the name of the view. Additional parameters are optional.
      def view(design_doc, view_name, params = {})
        keys = params.delete(:keys)
        url = Endpoint.view_uri(design_doc, view_name)
        if keys
          post url, { :keys => keys }
        else
          get url, params
        end
      end
      
      # Query the <tt>_all_docs</tt> view. 
      # Accepts all the same arguments as view.
      def documents(params = {})
        keys = params.delete(:keys)
        url = Endpoint.documents_uri
        if keys
          post url, { :keys => keys }
        else
          get url, params
        end
      end
      
      # Returns a set of documents specified by an array of document IDs
      def get_bulk(ids)
        documents(:keys => ids, :include_docs => true)
      end
      alias :bulk_load :get_bulk
      
      # Query a CouchDB-Lucene search view
      # /_fti/_design/YourDesign/by_name?include_docs=true&q=foobar*'
      def search(design_doc, view_name, params={})
        url = Endpoint.search_uri(design_doc, view_name)
        get url, params
      end
      
      # Run CoucDB compaction on the database
      # This removes old document revisions and optimizes space usage
      def compact!
        post Endpoint.compact_uri
      end
      
      # Triggers a CouchDB replication 
      # _from_ implies that the specified database will be _pulled_ from and
      # into the current Couchlogic database 
      #
      # Note: This makes no attempt to deal with conflicts.
      def replicate_from(other_db, continuous = false, create_target = false)
        replicate other_db, continuous, :target => name, 
                                        :create_target => create_target
      end

      # Triggers a CouchDB replication 
      # _to_ implies that the specified database will be _pushed_ to
      # using the current Couchlogic database 
      #
      # Note: This makes no attempt to deal with conflicts.
      def replicate_to(other_db, continuous = false, create_target = false)
        replicate other_db, continuous, :source => name, 
                                        :create_target => create_target
      end
      
      # Retrive an unused UUID from CouchDB
      #
      # This method will grab 1000 unused UUIDs from CouchDB, by default, and
      # hand them off one by one as needed to avoid continuously having to 
      # make requests for more
      def next_uuid(count = UUID_BATCH_COUNT)
        @@uuids ||= []
        if @@uuids.empty?
          params = { :count => count }
          @@uuids = get(Endpoint.uuid_uri, params)["uuids"]
        end
        @@uuids.pop
      end

      # Deletes the database itself!
      # This is not reversible and totally permanent. Use with care!
      #
      # To confirm the deletion, please pass in a confirm flag (any parameter
      # that is not false or nil)
      def delete!(confirm = false)
        if confirm
          delete Endpoint.endpoint_uri
        else
          false
        end
      end
      
      # Create the CouchDB database
      def create!
        put Endpoint.endpoint_uri
      end
      
      # Lists all databases on the server
      def databases
        get Endpoint.databases_uri
      end

      # Restart the CouchDB server
      def restart!
        post Endpoint.restart_uri
      end
      
    private
    
      def get(endpoint, data=nil)
        raise CouchDBURINotSpecified if @@connection.nil?
        @@connection.get endpoint, data
      end
      
      def delete(endpoint, data=nil)
        raise CouchDBURINotSpecified if @@connection.nil?
        @@connection.delete endpoint, data
      end
      
      def put(endpoint, data=nil)
        raise CouchDBURINotSpecified if @@connection.nil?
        @@connection.put endpoint, data
      end
      
      def post(endpoint, data=nil)
        raise CouchDBURINotSpecified if @@connection.nil?
        @@connection.post endpoint, data
      end
      
      def copy(endpoint, data=nil)
        raise CouchDBURINotSpecified if @@connection.nil?
        @@connection.copy endpoint, data
      end
      
      def replicate(other_db, continuous, options)
        unless options.key?(:target) || options.key?(:source)
          raise ArgumentError, "must provide a target or source database"
        end
        params = options
        if options.has_key?(:target)
          params[:source] = other_db
        else
          params[:target] = other_db
        end
        params[:continuous] = continuous
        
        post Endpoint.replicate_uri, params
      end
    
      def encode_attachments(attachments)
        attachments.each do |k, v|
          next if v['stub']
          v['data'] = Base64.encode64(v['data']).gsub(/\s/,'')
        end
        attachments
      end
      
      # Sanatize given URI paramter
      def s(param)
        URI.escape param
      end
      
      def escape_docid(id)      
        /^_design\/(.*)/ =~ id ? "_design/#{s($1)}" : s(id) 
      end

    end

  end

end
