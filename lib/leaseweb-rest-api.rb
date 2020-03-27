#!/usr/bin/env ruby

require 'httparty'
require 'base64'
require 'time'
require 'json'

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
    @options = {
      headers: {
        'X-Lsw-Auth' => apikey,
        'Content-Type' => 'application/json'
      }
    }
  end

  def getOauthToken(client_id, client_secret)
    access_token = validate_token(client_id)

    if (access_token == false)
      response = self.class.post('https://auth.leaseweb.com/token', basic_auth: { username: client_id, password: client_secret }, body: { grant_type: 'client_credentials' })
      access_token = response.parsed_response['access_token']
      cache_token(client_id, access_token, response.parsed_response['expires_in'])
    end

    @options = {
      headers: {
        'Authorization' => "Bearer #{access_token}",
        'Content-Type' => 'application/json'
      }
    }
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

  def get_paginated(url, key, offset = 0, limit = 50)
    data = []

    loop do
      response = self.class.get("#{url}&offset=#{offset}&limit=#{limit}")
      total = response.parsed_response['_metadata']['totalCount']
      data += response.parsed_response[key]
      offset += limit

      break unless offset < total
    end

    data
  end

  def postV2Reboot(serverId)
    self.class.post("/bareMetals/v2/servers/#{serverId}/powerCycle", @options)
  end

  def postV2PowerOn(serverId)
    self.class.post("/bareMetals/v2/servers/#{serverId}/powerOn", @options)
  end

  def postV2RescueMode(serverId, rescueImageId, sshKey)
    self.class.post("/bareMetals/v2/servers/#{serverId}/cancelActiveJob", @options)

    opt = @options.merge!(body: { rescueImageId: rescueImageId, sshKeys: sshKey, powerCycle: true }.to_json)

    self.class.post("/bareMetals/v2/servers/#{serverId}/rescueMode", opt)
  end

  def getV2DedicatedServers(result = nil)
    partialSize = (result && result['servers'] && result['servers'].size) || 0
    partialResult = self.class.get("/bareMetals/v2/servers?offset=#{partialSize}&limit=50", @options)

    return partialResult if partialResult['errorMessage']

    if result == nil
      result = partialResult
    else
      result['servers'] += partialResult['servers']
      result['_metadata']['offset'] == 0
      result['_metadata']['limit'] = partialResult['_metadata']['totalCount']
    end

    if result['servers'].size < partialResult['_metadata']['totalCount']
      return getV2DedicatedServers(result)
    end

    return result
  end

  def getV2DedicatedServerByIp(ip)
    self.class.get("/internal/dedicatedserverapi/v2/servers?ip=#{ip}", @options)
  end

  def getV2DedicatedServer(serverId)
    self.class.get("/bareMetals/v2/servers/#{serverId}", @options)
  end

  def getV2DedicatedServerHardware(serverId)
    self.class.get("/bareMetals/v2/servers/#{serverId}/hardwareInfo", @options)
  end

  def postV2VirtualServerPowerOn(serverId)
    self.class.post("/cloud/v2/virtualServers/#{serverId}/powerOn", @options)
  end

  def postV2VirtualServerPowerOff(serverId)
    self.class.post("/cloud/v2/virtualServers/#{serverId}/powerOff", @options)
  end

  def postV2VirtualServerReboot(serverId)
    self.class.post("/cloud/v2/virtualServers/#{serverId}/reboot", @options)
  end

  def postV2VirtualServerReinstall(serverId)
    self.class.post("/cloud/v2/virtualServers/#{serverId}/reinstall", @options)
  end

  def getV2VirtualServers(result = nil)
    partialSize = (result && result['virtualServers'] && result['virtualServers'].size) || 0
    partialResult = self.class.get("/cloud/v2/virtualServers?offset=#{partialSize}&limit=50", @options)

    return partialResult if partialResult['errorMessage']

    if result == nil
      result = partialResult
    else
      result['virtualServers'] += partialResult['virtualServers']
      result['_metadata']['offset'] == 0
      result['_metadata']['limit'] = partialResult['_metadata']['totalCount']
    end

    if result['virtualServers'].size < partialResult['_metadata']['totalCount']
      return getV2VirtualServers(result)
    end

    return result
  end

  def getV2VirtualServer(serverId)
    self.class.get("/cloud/v2/virtualServers/#{serverId}", @options)
  end

  def getV2VirtualServerControlPanelCredentials(serverId)
    self.class.get("/cloud/v2/virtualServers/#{serverId}/credentials/CONTROL_PANEL", @options)
  end

  def getV2VirtualServerControlPanelCredentialsForUser(serverId, username)
    self.class.get("/cloud/v2/virtualServers/#{serverId}/credentials/CONTROL_PANEL/#{username}", @options)
  end

  def getV2VirtualServerOsCredentials(serverId)
    self.class.get("/cloud/v2/virtualServers/#{serverId}/credentials/OPERATING_SYSTEM", @options)
  end

  def getV2VirtualServerOsCredentialsForUser(serverId, username)
    self.class.get("/cloud/v2/virtualServers/#{serverId}/credentials/OPERATING_SYSTEM/#{username}", @options)
  end

  # Private Networks
  def getPrivateNetworks
    self.class.get('/bareMetals/v2/privateNetworks', @options)
  end

  # TODO: check post with name
  def createPrivateNetworks(name = '')
    opt = @options.merge!(body: { name: name }.to_json)

    self.class.post('/bareMetals/v2/privateNetworks', opt)
  end

  def getPrivateNetwork(id)
    self.class.get("/bareMetals/v2/privateNetworks/#{id}", @options)
  end

  # TODO: Check with Jeroen if it works
  def updatePrivateNetwork(id, name = '')
    opt = @options.merge!(body: { name: name }.to_json)

    self.class.put("/bareMetals/v2/privateNetworks/#{id}", opt)
  end

  def deletePrivateNetwork(id)
    self.class.delete("/bareMetals/v2/privateNetworks/#{id}", @options)
  end

  def createPrivateNetworksServers(id, serverId)
    opt = @options.merge!(body: { serverId: serverId }.to_json)

    self.class.post("/bareMetals/v2/privateNetworks/#{id}/servers", opt)
  end

  def deletePrivateNetworksServers(id, serverId)
    self.class.delete("/bareMetals/v2/privateNetworks/#{id}/servers/#{serverId}", @options)
  end

  # Operating Systems
  def getOperatingSystems
    self.class.get('/v2/operatingSystems', @options)
  end

  def getOperatingSystem(operatingSystemId)
    self.class.get("/v2/operatingSystems/#{operatingSystemId}", @options)
  end

  def getControlPanels(operatingSystemId)
    self.class.get("/v2/operatingSystems/#{operatingSystemId}/controlPanels", @options)
  end

  def getControlPanel(operatingSystemId, controlPanelId)
    self.class.get("/v2/operatingSystems/#{operatingSystemId}/controlPanels/#{controlPanelId}", @options)
  end

  # IPs
  def getIps
    self.class.get('/ipMgmt/v2/ips', @options)
  end

  def getIp(ipAddress)
    self.class.get("/ipMgmt/v2/ips/#{ipAddress}", @options)
  end

  def updateIp(ipAddress, reverseLookup = '', nullRouted = 0)
    opt = @options.merge!(body: { reverseLookup: reverseLookup, nullRouted: nullRouted }.to_json)

    self.class.put("/ipMgmt/v2/ips/#{ipAddress}", opt)
  end

  def getBandwidthMetrics(serverId, dateFrom, dateTo, format = 'json')
    self.class.get("/bareMetals/v2/servers/#{serverId}/metrics/bandwidth", formatRequestV2(dateFrom, dateTo, 'AVG', format))
  end

  def getDatatrafficMetrics(serverId, dateFrom, dateTo, format = 'json')
    self.class.get("/bareMetals/v2/servers/#{serverId}/metrics/datatraffic", formatRequestV2(dateFrom, dateTo, 'SUM', format))
  end

  protected

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

  def dateFormatV2(date)
    Date.parse(date).strftime('%Y-%m-%dT00:00:00Z')
  end

  def formatHeader(format)
    header = if format == 'json'
               { 'Accept' => 'application/json' }.merge!(@options[:headers])
             else
               { 'Accept' => 'image/png' }.merge!(@options[:headers])
             end
    header
  end

  def formatRequestV2(dateFrom, dateTo, aggregation, format)
    @options.merge!(query: { from: dateFormatV2(dateFrom), to: dateFormatV2(dateTo), aggregation: aggregation, granularity: 'DAY' }, headers: formatHeader(format))
  end
end
