ENV['PAYONEER_PARTNER_ID'] ||= 'payoneer-partner-id'
ENV['PAYONEER_USERNAME'] ||= 'payoneer-username'
ENV['PAYONEER_PASSWORD'] ||= 'payoneer-password'
ENV['PAYONEER_API_URL'] ||= 'https://payoneer-api-url/api'

require 'vcr'
require './lib/payoneer'
Dir['spec/support/*.rb'].each { |rb| require "./#{rb}" }

Payoneer.logger = Logger.new('./log/payoneer_test.log')
Payoneer.logger.formatter = Logger::Formatter.new

RSpec.configure do |config|
  config.include PayoneerClient
end

VCR.configure do |c|
  c.configure_rspec_metadata!
  c.cassette_library_dir = "spec/fixtures/vcr"
  c.hook_into :webmock
  c.filter_sensitive_data('payoneer-partner-id') { ENV['PAYONEER_PARTNER_ID'] }
  c.filter_sensitive_data('payoneer-username') { ENV['PAYONEER_USERNAME'] }
  c.filter_sensitive_data('payoneer-password') { ENV['PAYONEER_PASSWORD'] }
  c.filter_sensitive_data('https://payoneer-api-url/api') { Payoneer::SANDBOX_API_URL }
  c.default_cassette_options = { match_requests_on: [:method, :uri, :body] }
  c.debug_logger = File.open('log/vcr.log', 'w')
end

