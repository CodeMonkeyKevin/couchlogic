module Couchlogic
  
  class Response
    
    attr_reader :code, :header, :body, :message
    
    HTTP_RESPONSES = { '100' => 'Continue', 
                       '101' => 'SwitchProtocol', 
                       '200' => 'OK', 
                       '201' => 'Created', 
                       '202' => 'Accepted', 
                       '203' => 'NonAuthoritativeInformation', 
                       '204' => 'NoContent', 
                       '205' => 'ResetContent', 
                       '206' => 'PartialContent', 
                       '300' => 'MultipleChoice', 
                       '301' => 'MovedPermanently', 
                       '302' => 'Found', 
                       '303' => 'SeeOther', 
                       '304' => 'NotModified', 
                       '305' => 'UseProxy', 
                       '307' => 'TemporaryRedirect', 
                       '400' => 'BadRequest', 
                       '401' => 'Unauthorized', 
                       '402' => 'PaymentRequired', 
                       '403' => 'Forbidden', 
                       '404' => 'NotFound', 
                       '405' => 'MethodNotAllowed', 
                       '406' => 'NotAcceptable', 
                       '407' => 'ProxyAuthenticationRequired', 
                       '408' => 'RequestTimeOut', 
                       '409' => 'Conflict', 
                       '410' => 'Gone', 
                       '411' => 'LengthRequired', 
                       '412' => 'PreconditionFailed', 
                       '413' => 'RequestEntityTooLarge', 
                       '414' => 'RequestURITooLong', 
                       '415' => 'UnsupportedMediaType', 
                       '416' => 'RequestedRangeNotSatisfiable', 
                       '417' => 'ExpectationFailed', 
                       '500' => 'InternalServerError', 
                       '501' => 'NotImplemented', 
                       '502' => 'BadGateway', 
                       '503' => 'ServiceUnavailable', 
                       '504' => 'GatewayTimeOut', 
                       '505' => 'VersionNotSupported' }
    
    def initialize(http_client)
      @code = http_client.response_code
      if http_client.header_str.is_a?(String)
        @header = parse_headers(http_client.header_str) 
      else 
        @header = http_client.header_str
      end
      @body = http_client.body_str
      @message = HTTP_RESPONSES[@code.to_s]
    end
    
    def success?
      @code >= 200 && @code < 300
    end
    
  private
  
    def parse_headers(header_string)
      header_lines = header_string.split($/)
      header_lines.shift
      header_lines.inject({}) do |hsh, line|
        header, key, value = /^(.*?):\s*(.*)$/.match(line.chomp).to_a
        hsh[key] = value unless header.nil?
        hsh
      end
    end
    
  end
  
end
