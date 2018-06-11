#!/usr/bin/env ruby

require 'httparty'
require 'base64'
require 'time'
require 'json'
require_relative 'hash-to-uri-conversion'

class LeasewebAPI
  include HTTParty
  format :json
  # debug_output $stderr

  base_uri 'https://api.leaseweb.com'

  def initialize
    @tmpdir = "/tmp/lsw-rest-api"
    Dir.mkdir(@tmpdir) unless Dir.exist?(@tmpdir)
  end

  def apiKeyAuth(apikey)
    @options = { headers: { 'X-Lsw-Auth' => apikey, 'Content-Type' => 'application/json' } }
  end

  def getOauthToken(client_id, client_secret)
    access_token = validate_token(client_id)

    if (access_token == false)
      response = self.class.post('https://auth.leaseweb.com/token', basic_auth: { username: client_id, password: client_secret }, body: { grant_type: 'client_credentials' })
      access_token = response.parsed_response['access_token']
      cache_token(client_id, access_token, response.parsed_response['expires_in'])
    end

    @options = { headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' } }
  end

  def getPasswordToken(username, password, client_id, client_secret)
    access_token = validate_token(client_id)

    if (access_token == false)
      response = self.class.post('https://auth.leaseweb.com/token', basic_auth: { username: client_id, password: client_secret }, body: { grant_type: 'password', username: username, password: password })
      access_token = response.parsed_response['access_token']
      cache_token(client_id, access_token, response.parsed_response['expires_in'])
    end

    @options = { headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' } }
  end

  def validate_token(client_id)
    begin
      file = "#{@tmpdir}/#{client_id}.json"
      content = JSON.parse(File.read(file))
      expires_at = DateTime.parse(content['expires_at'])

      if expires_at > DateTime.now
        return content['access_token']
      else
        File.delete(file)
      end
    rescue
      return false
    end

    return false
  end

  def cache_token(client_id, access_token, expires_in)
    file = "#{@tmpdir}/#{client_id}.json"
    content = { access_token: access_token, expires_at: Time.now.getutc + expires_in }.to_json
    File.write(file, content)
  end

  def readPrivateKey(privateKey, password)
    if password
      @private_key = OpenSSL::PKey::RSA.new(File.read(privateKey), password)
    else
      @private_key = OpenSSL::PKey::RSA.new(File.read(privateKey))
    end
  end

  def get(url)
    self.class.get(url, @options)
  end

  def post(url, body)
    opt = @options.merge!(body: body)
    self.class.post(url, opt)
  end

  def put(url, body)
    opt = @options.merge!(body: body)
    self.class.put(url, opt)
  end

  def delete(url)
    self.class.delete(url, @options)
  end

  def postV2Reboot(bareMetalId)
    self.class.post("https://api.leaseweb.com/bareMetals/v2/servers/#{bareMetalId}/powerCycle", @options)
  end

  def postV2PowerOn(bareMetalId)
    self.class.post("https://api.leaseweb.com/bareMetals/v2/servers/#{bareMetalId}/powerOn", @options)
  end

  def postV2RescueMode(serverId, rescueImageId, sshKey)
    opt = @options.merge!(body: { rescueImageId: rescueImageId, sshKeys: sshKey, powerCycle: true }.to_json)

    self.class.post("https://api.leaseweb.com/bareMetals/v2/servers/#{serverId}/rescueMode", opt)
  end

  def getV2DedicatedServers
    self.class.get("https://api.leaseweb.com/bareMetals/v2/servers?limit=100000", @options)
  end

  def getV2DedicatedServerByIp(ip)
    self.class.get("https://api.leaseweb.com/internal/dedicatedserverapi/v2/servers?ip=#{ip}", @options)
  end

  def getV2DedicatedServer(serverId)
    self.class.get("https://api.leaseweb.com/bareMetals/v2/servers/#{serverId}", @options)
  end

  protected

  def decrypt(string)
    @private_key.private_decrypt(Base64.decode64(string))
  end

  def dateFormat(date)
    Date.parse(date).strftime('%d-%m-%Y')
  end

  def formatHeader(format)
    header = if format == 'json'
               { 'Accept' => 'application/json' }.merge!(@options[:headers])
             else
               { 'Accept' => 'image/png' }.merge!(@options[:headers])
             end

    header
  end

  def formatRequest(dateFrom, dateTo, format)
    @options.merge!(query: { dateFrom: dateFormat(dateFrom), dateTo: dateFormat(dateTo) }, headers: formatHeader(format))
  end
end
