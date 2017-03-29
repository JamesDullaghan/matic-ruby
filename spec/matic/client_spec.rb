require "spec_helper"

describe Matic::Client do
  let(:all_args) do
    {
      base_url: "http://matic-base-url.com",
      client_name: 'example',
      private_key: 'somesecretkey',
      post_body: "{some: 'body'}",
      request_method: "POST",
      api_endpoint: "/quotes"
    }
  end

  context "with missing arguments" do
    subject { described_class.new(args) }

    describe "#initialize" do
      [
        :base_url,
        :client_name,
        :private_key,
        :post_body,
        :request_method,
        :api_endpoint,
      ].each do |attr|
        context "missing base_url" do
          let(:args) { all_args.reject(attr) }

          it "raise an ArgumentError" do
            expect{subject}.to raise_error(ArgumentError)
          end
        end
      end
    end
  end
end
