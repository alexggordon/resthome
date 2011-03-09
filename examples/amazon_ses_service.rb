require 'resthome'
require 'digest/sha2'
require 'base64'

class AmazonSESService < RESTHome
  base_uri 'https://email.us-east-1.amazonaws.com'
  
  @@digest256 = OpenSSL::Digest::Digest.new("sha256")

  route :verify_email_address, '/', :body => {'Action' => 'VerifyEmailAddress', 'EmailAddress' => :arg1}, :method => :post, :expected_status => 200, :no_body => true do |res|
    res['VerifyEmailAddressResponse']
  end

  route :list_verified_email_addresses, '/', :body => {'Action' => 'ListVerifiedEmailAddresses'}, :method => :post, :expected_status => 200, :no_body => true do |res|
    res['ListVerifiedEmailAddressesResponse']['ListVerifiedEmailAddressesResult']
  end

  route :delete_verified_email_address, '/', :body => {'Action' => 'DeleteVerifiedEmailAddress', 'EmailAddress' => :arg1}, :method => :post, :expected_status => 200, :no_body => true do |res|
    res['DeleteVerifiedEmailAddressResponse']
  end

  route :get_send_quota, '/', :body => {'Action' => 'GetSendQuota'}, :method => :post, :expected_status => 200, :no_body => true do |res|
    res['GetSendQuotaResponse']
  end

  route :get_send_statistics, '/', :body => {'Action' => 'GetSendStatistics'}, :method => :post, :expected_status => 200, :no_body => true do |res|
    res['GetSendStatisticsResponse']
  end

  route :send_email, '/', :body => {'Action' => 'SendEmail'}, :method => :post, :expected_status => 200 do |res|
    res['SendEmailResponse']
  end

  route :send_text_email, '/', :body => {'Action' => 'SendEmail', 'Destination.ToAddresses.member.1' => :arg1, 'Message.Subject.Data' => :arg2, 'Message.Body.Text.Data' => :arg3, 'Source' => :arg4}, :method => :post, :expected_status => 200, :no_body => true do |res|
    res['SendEmailResponse']
  end

  route :send_html_email, '/', :body => {'Action' => 'SendEmail', 'Destination.ToAddresses.member.1' => :arg1, 'Message.Subject.Data' => :arg2, 'Message.Body.Html.Data' => :arg3, 'Source' => :arg4}, :method => :post, :expected_status => 200, :no_body => true do |res|
    res['SendEmailResponse']
  end

  route :send_raw_email, '/', :body => {'Action' => 'SendRawEmail', 'RawMessage' => :arg1}, :method => :post, :expected_status => 200, :no_body => true do |res|
    res['SendRawEmailResponse']
  end

  def initialize(access_key, secret)
    @access_key = access_key
    @secret = secret
  end

  def build_options!(options)
    @error_response = nil
    date = Time.now.getutc.httpdate
    options[:headers] ||= {}
    options[:headers]['Date'] = date
    options[:headers]['X-Amzn-Authorization'] = "AWS3-HTTPS AWSAccessKeyId=#{@access_key},Algorithm=HMACSHA256,Signature=#{AmazonSESService.sign_request(@secret, date)}"
  end

  def self.sign_request(secret, date)
    Base64.encode64(OpenSSL::HMAC.digest(@@digest256, secret, date)).gsub("\n","")
  end

  def error_response
    @error_response ||= HTTParty::Parser.call self.response.body, HTTParty::Parser.format_from_mimetype(self.response.headers['content-type'])
  end
end
