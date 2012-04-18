require 'simplecov'
SimpleCov.start 'rails'

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha'

include Amazon::MWS

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  #fixtures :all

  # Add more helper methods to be used by all tests here...

	def xml_for(name, code)
	  file = File.open(Pathname.new(File.dirname(__FILE__)).expand_path.dirname.join("test/fixtures/xml/#{name}.xml"),'rb')
	  mock_response(code, {:content_type=>'text/xml', :body=>file.read})
	end

	def mock_response(code, options={})
	  body = options[:body]
	  content_type = options[:content_type]
	  response = Net::HTTPResponse.send(:response_class, code.to_s).new("1.0", code.to_s, "message")
	  response.instance_variable_set(:@body, body)
	  response.instance_variable_set(:@read, true)
	  response.content_type = content_type
	  return response
	end

  class ActionController::TestCase
    include Devise::TestHelpers
  end
    
end

