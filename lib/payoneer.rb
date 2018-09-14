require 'net/http'
require 'net/https'
require 'logger'
require 'ostruct'
require 'nokogiri'
require_relative 'payoneer/exception'

class Payoneer
  SANDBOX_API_URL = 'https://api.sandbox.payoneer.com/Payouts/HttpApi/API.aspx'
  PRODUCTION_API_URL = 'https://api.payoneer.com/payouts/HttpAPI/API.aspx'

  attr_reader :username, :password, :partner_id, :member_name, :sandbox

  class << self
    attr_writer :logger

    def new_payee_link(partner_id, username, password, member_name)
      payoneer_api = self.new(partner_id, username, password)
      payoneer_api.payee_link(member_name)
    end

    def transfer_funds(partner_id, username, password, options)
      payoneer_api = self.new(partner_id, username, password)
      payoneer_api.transfer_funds(options)
    end

    def payee_exists?(partner_id, username, password, payee_id)
      payoneer_api = self.new(partner_id, username, password)
      payoneer_api.payee_exists?(payee_id)
    end
  end

  def initialize(partner_id:, username:, password:, sandbox: false)
    @partner_id = partner_id
    @username = username
    @password = password
    @sandbox = sandbox
  end

  def payee_signup_link(member_name)
    @member_name = member_name
    result = get_api_call(payee_signup_link_args)
    api_result(result)
  end

  def transfer_funds(options)
    result = get_api_call(transfer_funds_args(options))
    api_result(result)
  end

  def payee_exists?(payee_id)
    result = get_api_call(payee_exists_args(payee_id))
    api_result(result)
  end

  def payment_status(options)
    to_struct(get_api_call(payment_status_args(options)))
  end

  private

  def api_result(body)
    logger.debug "Payoneer Response: #{body}"
    if is_xml? body
      xml_response_result(body)
    else
      body
    end
  end

  def is_xml?(body)
    Nokogiri::XML.parse(body).errors.empty?
  end

  def xml_response_result(body)
    raise(PayoneerException, api_error_description(body)) if failure_api_response?(body)
    true
  end

  def failure_api_response?(body)
    xml = Nokogiri::XML.parse(body)
    status = xml.xpath('//*[self::Status or self::Code]')
    status.any? && status.text != '000'
  end

  def api_error_description(body)
    xml = Nokogiri::XML.parse(body)
    xml.xpath('//*[self::Description or self::Error]').text
  end

  def get_api_call(args_hash)
    uri = URI.parse(api_url)
    uri.query = URI.encode_www_form(args_hash)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    http.request(request).body
  end

  def payee_signup_link_args
    base_args.merge(
      'mname' => 'GetToken',
      'p4' => member_name,
    )
  end

  def transfer_funds_args(options)
    date = (options[:date] || Time.now).strftime('%m/%d/%Y %H:%M:%S')
    base_args.merge(
      'mname' => 'PerformPayoutPayment',
      'p4' => options[:program_id],
      'p5' => options[:internal_payment_id],
      'p6' => options[:internal_payee_id],
      'p7' => '%.2f' % options[:amount].to_f,
      'p8' => options[:description],
      'p9' => date,
    )
  end

  def payee_exists_args(payee_id)
    base_args.merge(
      'mname' => 'GetPayeeDetails',
      'p4' => payee_id,
    )
  end

  def payment_status_args(options)
    base_args.merge(
      'mname' => 'GetPaymentStatus',
      'p4' => options[:internal_payee_id],
      'p5' => options[:internal_payment_id],
    )
  end

  def base_args
    {
      'p1' => username,
      'p2' => password,
      'p3' => partner_id,
    }
  end

  def to_struct(xml)
    OpenStruct.new(
      Nokogiri::XML.parse(xml).xpath('/*/*').map do |node|
        [snake_case(node.name), node.text]
      end.to_h
    )
  end

  def snake_case(camel_case_string)
    camel_case_string.gsub(/[a-z][A-Z]/) do |match|
      "#{match[0]}_#{match[1]}"
    end.downcase
  end

  def api_url
    sandbox ? SANDBOX_API_URL : PRODUCTION_API_URL
  end

  def self.logger
    unless @logger
      @logger = Logger.new($stdout)
      @logger.formatter = Logger::Formatter.new
    end
    @logger
  end

  def logger
    self.class.logger
  end
end

