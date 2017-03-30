module Matic
  class Client
    class << self
      attr_accessor :base_url,
                    :client_name,
                    :private_key
    end

    attr_reader :base_url,
                :client_name,
                :private_key,
                :post_body,
                :curl_method,
                :request_method,
                :api_endpoint

    def initialize(opts = {})
      @base_url    = Matic::Client.base_url || opts.fetch(:base_url) { missing_argument(:base_url) }
      @client_name = Matic::Client.client_name || opts.fetch(:client_name) { missing_argument(:client_name) }
      @private_key = Matic::Client.private_key || opts.fetch(:private_key) { missing_argument(:private_key) }
      @post_body   = opts.fetch(:post_body, "")
      # PROVIDE AN UPPERCASE REQUEST METHOD
      @curl_method    = opts.fetch(:curl_method) { :get }
      @request_method = opts.fetch(:request_method) { "GET" }
      @api_endpoint   = opts.fetch(:api_endpoint) { missing_argument(:api_endpoint) }
    end

    def self.get(path)
      perform(path, :get)
    end

    def self.post(path, body)
      perform(path, :post, body: body)
    end

    def self.put(path, body, opts = {})
      perform(path, :put, opts.merge(body: body))
    end

    def self.delete(path, body = nil)
      perform(path, :delete, body: body)
    end

    def perform
      c = Curl::Easy.new(url)
      c.headers = default_headers

      case curl_method
      when :put, :delete
        c.put_data = post_body
      when :post
        c.multipart_form_post = true
        c.post_body = post_body
      end

      if verified?
        c.http(curl_method)
        c
      else
        raise Matic::UnexpectedResponseBody, "Cannot verify signature"
      end
    end

    private

    def self.perform(path, method, opts = {})
      formatted_method = case method
                         when :post then "POST"
                         when :put then "PUT"
                         when :delete then "DELETE"
                         when :get then "GET"
                         end

      if opts[:body] && !opts[:body].is_a?(String)
        fail Matic::UnexpectedResponseBody, "body should be nil or a JSON string"
      end

      client = ::Matic::Client.new(
        post_body: opts[:body],
        curl_method: method,
        request_method: formatted_method,
        api_endpoint: path,
      )

      client.perform
    end

    # Full Url
    #
    # @return [String]
    def url
      base_url + api_endpoint
    end

    # Secret string required for authentication
    # Looks like an oauth token
    #
    # @return [String]
    def secret_string
      [
        client_name,
        request_method,
        api_endpoint,
        post_body,
        timestamp
      ].join(':')
    end

    # Unix Timestamp
    #
    # @return [Integer]
    def timestamp
      @timestamp ||= Time.now.to_i
    end

    # Private Key
    def key
      @key ||= OpenSSL::PKey::RSA.new(private_key)
    end

    def digest
      @digest ||= OpenSSL::Digest::SHA256.new
    end

    # Signed Key
    def signature
      @signature ||= key.sign(digest, secret_string)
    end

    def verified?
      key.verify(digest, signature, secret_string)
    end

    # API Service expects following headers along every request:
    # X-Client: client_name from example above
    # X-Timestamp: timestamp from example above
    # X-Signature: signature from example above
    # Authentication headers must be sent on each request
    #
    # @return [Hash]
    def auth_headers
      {
        'X-Client' => client_name,
        'X-Timestamp' => timestamp,
        'X-Signature' => signature
      }
    end

    # Default headers sent with each request
    #
    # @return [Hash]
    def default_headers
      {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }.merge(auth_headers)
    end

    def missing_argument(key)
      raise ArgumentError, "Please supply a #{key.to_s}"
    end
  end
end

class Matic::UnexpectedResponseBody < StandardError
end
