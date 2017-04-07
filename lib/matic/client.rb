require 'net/http'
require 'uri'

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
                :method,
                :request_method,
                :api_endpoint

    def initialize(opts = {})
      @base_url       = Matic::Client.base_url || opts.fetch(:base_url) { missing_argument(:base_url) }
      @client_name    = Matic::Client.client_name || opts.fetch(:client_name) { missing_argument(:client_name) }
      @private_key    = Matic::Client.private_key || opts.fetch(:private_key) { missing_argument(:private_key) }
      @post_body      = opts.fetch(:post_body, "")
      # PROVIDE AN UPPERCASE REQUEST METHOD
      @method         = opts.fetch(:method) { :get }
      @request_method = opts.fetch(:request_method) { @method.upcase }
      @api_endpoint   = opts.fetch(:api_endpoint) { missing_argument(:api_endpoint) }
    end

    def self.get(path)
      perform(path, :get)
    end

    def self.post(path, body)
      perform(path, :post, body: body)
    end

    def self.put(path, body, opts = {})
      meth = if opts[:method]
        :patch
      else
        :put
      end

      perform(path, meth, body: body)
    end

    def self.delete(path, body = nil)
      perform(path, :delete, body: body)
    end

    def perform
      uri = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)
      klass = "Net::HTTP::#{method.to_s.capitalize}"

      request = Object.const_get(klass).new(uri.request_uri)

      case method
      when :post, :put, :patch, :delete
        request.body = post_body
      end

      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request["X-Client"] = client_name
      request["X-Timestamp"] = timestamp
      request["X-Signature"] = signature
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'

      if verified?
        http.request(request)
      else
        raise Matic::UnexpectedResponseBody, "Cannot verify signature"
      end
    end

    private

    def self.perform(path, method, opts = {})
      # if opts[:body] && !opts[:body].is_a?(String)
      #   fail Matic::UnexpectedResponseBody, "body should be nil or a JSON string"
      # end

      client = ::Matic::Client.new(
        post_body: opts[:body],
        method: method,
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
      @timestamp ||= Time.now.to_i.to_s
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
      @signature ||= key.sign(digest, secret_string).unpack('H*').first
    end

    def verified?
      verified_signature = [signature].pack('H*')

      key.verify(digest, verified_signature, secret_string)
    end

    def missing_argument(key)
      raise ArgumentError, "Please supply a #{key.to_s}"
    end
  end
end

class Matic::UnexpectedResponseBody < StandardError
end
