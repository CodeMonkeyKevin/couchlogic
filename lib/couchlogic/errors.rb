module Couchlogic
  
  class CouchlogicError         < StandardError; end
  class Unauthorized            < CouchlogicError; end
  class NotFound                < CouchlogicError; end
  class ServerError             < CouchlogicError; end
  class Unavailable             < CouchlogicError; end
  class DecodeError             < CouchlogicError; end
  class CouchDBURINotSpecified  < CouchlogicError; end
  
end
