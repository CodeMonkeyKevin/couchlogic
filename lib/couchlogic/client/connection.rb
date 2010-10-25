module Couchlogic
  
  class Connection

    attr_accessor :debug, :proxy_uri
    attr_reader :http_client

    def initialize
      @debug = false
      @proxy_uri = nil
      @headers = { 'User-Agent'    => "Couchlogic v#{Couchlogic.version}",
                   'Accept'        => 'application/json',
                   'Content-Type'  => 'application/json' }
      @http_client = Curl::Easy.new
    end

    def get(endpoint, data=nil)
      request :get, endpoint, data
    end
    
    def delete(endpoint, data=nil)
      request :delete, endpoint, data
    end

    def post(endpoint, data=nil)
      request :post, endpoint, data
    end

    def put(endpoint, data=nil)
      request :put, endpoint, data
    end
    
    def copy(endpoint, data=nil)
      request :copy, endpoint, data
    end

  private

    def request(method, endpoint, data)
      if debug
        puts "request: #{method.to_s.upcase} #{endpoint}"
        puts "headers:"
        @headers.each do |key, value|
          puts "#{key}=#{value}"
        end
      end
      
      case method
      when :get, :delete
        unless data.nil?
          endpoint = [endpoint, build_query(data)].join('?')
        end
        response = send_request(method, endpoint)
      when :copy
        response = send_request(method, endpoint, data)
      when :post, :put
        data = Yajl::Encoder.encode(data)
        response = send_request(method, endpoint, data)
      end

      if debug
        puts "\nresponse: #{response.code}"
        puts "headers:"
        response.header.each do |key, value|
          puts "#{key}=#{value}"
        end
        puts "body:"
        puts response.body
      end

      raise_errors(response)

      if response.body.empty?
        content = nil
      else
        begin
          content = Yajl::Parser.new.parse(response.body)
        rescue Yajl::ParseError
          raise DecodeError, "content: <#{response.body}>"
        end
      end

      content
    end

    def build_query(data)
      data = data.to_a if data.is_a?(Hash)
      data.map do |key, value|
        [key.to_s, URI.escape(value.to_s)].join('=')
      end.join('&')
    end
    
    def send_request(method, endpoint, data=nil)
      prepare_request(endpoint)
      
      unless Couchlogic.username.nil?
        @http_client.http_auth_types = :basic
        @http_client.username = Couchlogic.username
        @http_client.password = Couchlogic.password
      end
      
      begin
        case method
        when :get
          @http_client.http_get
        when :delete
          @http_client.http_delete
        when :post
          @http_client.http_post(data.to_s)
        when :put
          @http_client.http_put(data.to_s)
        when :copy
          @http_client.headers['Destination'] = data
          @http_client.http('COPY')
        end
      rescue => e
        raise_errors Response.new(@http_client)
      end
      
      Response.new(@http_client)
    end
    
    def prepare_request(uri)
      @http_client.url = uri
      @http_client.proxy_url = @proxy_uri if @proxy_uri
      @http_client.headers = @headers
    end

    def raise_errors(response)
      response_description = "(#{response.code}): #{response.message}"
      response_description += " - #{response.body}" unless response.body.empty?

      unless response.success?
        case response.code.to_i
        when 401
          raise Unauthorized
        when 404
          raise NotFound
        when 500
          raise ServerError, "CouchDB Error: #{response_description}"
        when 502..503
          raise Unavailable, response_description
        else
          raise CouchlogicError, response_description
        end
      end
    end
      
  end
  
end
