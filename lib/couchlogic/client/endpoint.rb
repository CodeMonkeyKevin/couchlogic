module Couchlogic

  class Endpoint

    class << self
      
      # Constructs the path to the _all_documents view
      def documents_path
        "_all_docs"
      end
      
      # Constructs the fully qualified URI to the _all_documents view
      def documents_uri
        endpoint_uri documents_path
      end
      
      # Constructs the fully qualified URI to the bulk documents endpoint
      def bulk_docs_uri
        endpoint_uri '_bulk_docs'
      end
      
      # Constructs the fully qualified URI for a given document
      def document_uri(doc_id, batch = false)
        if batch
          endpoint_uri [doc_id, 'batch=ok'].join('?')
        else
          endpoint_uri doc_id
        end
      end
      
      # Constructs the path to a document's specified attachment
      def attachment_path(doc, attachment_name)
        doc_id = Client.escape_docid(doc['_id'])
        name = s(name)
        rev = "rev=#{doc['_rev']}"
        [doc_id, [name, rev].join('?') ].join('/')
      end
      
      # Constructs the fully qualified URI to a document's specified attachment
      def attachment_uri(doc, attachment_name)
        endpoint_uri attachment_path(doc, attachment_path)
      end
      
      # Constructs the path to a design document
      def design_path(design_doc)
        "_design/#{s design_doc}"
      end
      
      # Constructs the fully qualified URI for the given design document
      def design_uri(design_doc)
        endpoint_uri design_path(design_doc)
      end
      
      # Constructs the path to a view
      def view_path(design_doc, view_name)
        [design_path(design_doc), "_view/#{s view_name}"].join('/')
      end
      
      # Constructs the fully qualified URI for the given view of the given 
      # design document
      def view_uri(design_doc, view_name)
        endpoint_uri view_path(design_doc, view_name)
      end
      
      # Constructs the fully qualified URI for a Lucene search view
      def search_uri(design_doc, view_name)
        endpoint_uri ["_fti", design_path(design_doc), s(view_name)].join('/')
      end
      
      # Constructs the fully qualified URI for the built-in CouchDB compaction
      def compact_uri
        endpoint_uri '_compact'
      end
      
      # Constructs the fully qualified URI to the CouchDB databases endpoint
      def databases_uri
        root_uri '_all_dbs'
      end
      
      # Constructs the fully qualified URI for the built-in CouchDB replication
      def replicate_uri
        endpoint_uri '_replicate'
      end
      
      # Constructs the fully qualified URI for restarting the CouchDB server
      def restart_uri
        root_uri '_restart'
      end
      
      # Constructs the fully qualified URI for fetching UUIDs from CouchDB
      def uuid_uri
        root_uri '_uuids'
      end

      # Constructs the fully qualified CouchDB URI, including the database name
      def endpoint_uri(path = nil)
        if path
          [Couchlogic.couchdb, path].join('/')
        else
          Couchlogic.couchdb
        end
      end
      
      # Constructs the fully qualified URI to the CouchDB server
      def root_uri(path = nil)
        if path
          [Couchlogic.couch_server, path].join('/')
        else
          Couchlogic.couch_server
        end
      end

    end

  end

end