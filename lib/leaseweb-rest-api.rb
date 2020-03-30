# frozen_string_literal: true

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
    @tmpdir = '/tmp/lsw-rest-api'
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

    if access_token == false
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

  def rebootDedicatedServer(server_id)
    self.class.post("/bareMetals/v2/servers/#{server_id}/powerCycle", @options)
  end

  def powerOnDedicatedServer(server_id)
    self.class.post("/bareMetals/v2/servers/#{server_id}/powerOn", @options)
  end

  def launchRescueModeDedicatedServer(server_id, rescue_image_id, ssh_key)
    self.class.post("/bareMetals/v2/servers/#{server_id}/cancelActiveJob", @options)

    opt = @options.merge!(body: { rescueImageId: rescue_image_id, sshKeys: ssh_key, powerCycle: true }.to_json)

    self.class.post("/bareMetals/v2/servers/#{server_id}/rescueMode", opt)
  end

  def getDedicatedServers(result = nil)
    partialSize = (result && result['servers'] && result['servers'].size) || 0
    partialResult = self.class.get("/bareMetals/v2/servers?offset=#{partialSize}&limit=50", @options)

    return partialResult if partialResult['errorMessage']

    if result.nil?
      result = partialResult
    else
      result['servers'] += partialResult['servers']
      result['_metadata']['offset'] = 0
      result['_metadata']['limit'] = partialResult['_metadata']['totalCount']
    end

    return getDedicatedServers(result) if result['servers'].size < partialResult['_metadata']['totalCount']

    result
  end

  def getDedicatedServerByIp(ip)
    self.class.get("/internal/dedicatedserverapi/v2/servers?ip=#{ip}", @options)
  end

  def getDedicatedServer(server_id)
    self.class.get("/bareMetals/v2/servers/#{server_id}", @options)
  end

  def getDedicatedServerHardware(server_id)
    self.class.get("/bareMetals/v2/servers/#{server_id}/hardwareInfo", @options)
  end

  def getDedicatedServerDhcpReservation(server_id)
    result = self.class.get("/bareMetals/v2/servers/#{server_id}/leases", @options)
    result['leases'].pop
  end

  def createDedicatedServerDhcpReservation(server_id, boot_file_name)
    opt = @options.merge!(body: { bootFileName: boot_file_name }.to_json)
    self.class.post("/bareMetals/v2/servers/#{server_id}/leases", opt)
  end

  def removeDedicatedServerDhcpReservation(server_id)
    self.class.delete("/bareMetals/v2/servers/#{server_id}/leases", @options)
  end

  def powerOnVirtualServer(server_id)
    self.class.post("/cloud/v2/virtualServers/#{server_id}/powerOn", @options)
  end

  def powerOffVirtualServer(server_id)
    self.class.post("/cloud/v2/virtualServers/#{server_id}/powerOff", @options)
  end

  def rebootVirtualServer(server_id)
    self.class.post("/cloud/v2/virtualServers/#{server_id}/reboot", @options)
  end

  def reinstallVirtualServer(server_id)
    self.class.post("/cloud/v2/virtualServers/#{server_id}/reinstall", @options)
  end

  def getVirtualServers(result = nil)
    partialSize = (result && result['virtualServers'] && result['virtualServers'].size) || 0
    partialResult = self.class.get("/cloud/v2/virtualServers?offset=#{partialSize}&limit=50", @options)

    return partialResult if partialResult['errorMessage']

    if result.nil?
      result = partialResult
    else
      result['virtualServers'] += partialResult['virtualServers']
      result['_metadata']['offset'] = 0
      result['_metadata']['limit'] = partialResult['_metadata']['totalCount']
    end

    return getVirtualServers(result) if result['virtualServers'].size < partialResult['_metadata']['totalCount']

    result
  end

  def getVirtualServer(server_id)
    self.class.get("/cloud/v2/virtualServers/#{server_id}", @options)
  end

  def getVirtualServerControlPanelCredentials(server_id)
    self.class.get("/cloud/v2/virtualServers/#{server_id}/credentials/CONTROL_PANEL", @options)
  end

  def getVirtualServerControlPanelCredentialsForUser(server_id, username)
    self.class.get("/cloud/v2/virtualServers/#{server_id}/credentials/CONTROL_PANEL/#{username}", @options)
  end

  def getVirtualServerOsCredentials(server_id)
    self.class.get("/cloud/v2/virtualServers/#{server_id}/credentials/OPERATING_SYSTEM", @options)
  end

  def getVirtualServerOsCredentialsForUser(server_id, username)
    self.class.get("/cloud/v2/virtualServers/#{server_id}/credentials/OPERATING_SYSTEM/#{username}", @options)
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

  def addDedicatedServerToPrivateNetwork(id, server_id)
    opt = @options.merge!(body: { serverId: server_id }.to_json)

    self.class.post("/bareMetals/v2/privateNetworks/#{id}/servers", opt)
  end

  def removeDedicatedServerFromPrivateNetwork(id, server_id)
    self.class.delete("/bareMetals/v2/privateNetworks/#{id}/servers/#{server_id}", @options)
  end

  # Operating Systems
  def getOperatingSystems
    self.class.get('/bareMetals/v2/operatingSystems', @options)
  end

  def getOperatingSystem(operating_system_id)
    self.class.get("/bareMetals/v2/operatingSystems/#{operating_system_id}", @options)
  end

  def getControlPanels(operating_system_id)
    self.class.get("/bareMetals/v2/operatingSystems/#{operating_system_id}/controlPanels", @options)
  end

  def getControlPanel(operating_system_id, control_panel_id)
    self.class.get("/bareMetals/v2/operatingSystems/#{operating_system_id}/controlPanels/#{control_panel_id}", @options)
  end

  # IPs
  def getIps
    self.class.get('/ipMgmt/v2/ips', @options)
  end

  def getIp(ip)
    self.class.get("/ipMgmt/v2/ips/#{ip}", @options)
  end

  def updateIp(ip, reverse_lookup = '', null_routed = 0)
    opt = @options.merge!(body: { reverseLookup: reverse_lookup, nullRouted: null_routed }.to_json)

    self.class.put("/ipMgmt/v2/ips/#{ip}", opt)
  end

  def getDedicatedServerBandwidthMetrics(server_id, date_from, date_to, format = 'json')
    self.class.get("/bareMetals/v2/servers/#{server_id}/metrics/bandwidth", formatRequest(date_from, date_to, 'AVG', format))
  end

  def getDedicatedServerDatatrafficMetrics(server_id, date_from, date_to, format = 'json')
    self.class.get("/bareMetals/v2/servers/#{server_id}/metrics/datatraffic", formatRequest(date_from, date_to, 'SUM', format))
  end

  protected

  def validate_token(client_id)
    begin
      file = "#{@tmpdir}/#{client_id}.json"
      content = JSON.parse(File.read(file))
      expires_at = DateTime.parse(content['expires_at'])

      return content['access_token'] if expires_at > DateTime.now

      File.delete(file)
    rescue
      return false
    end

    false
  end

  def cache_token(client_id, access_token, expires_in)
    file = "#{@tmpdir}/#{client_id}.json"
    content = { access_token: access_token, expires_at: Time.now.getutc + expires_in }.to_json
    File.write(file, content)
  end

  def dateFormat(date)
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

  def formatRequest(date_from, date_to, aggregation, format)
    @options.merge!(query: { from: dateFormat(date_from), to: dateFormat(date_to), aggregation: aggregation, granularity: 'DAY' }, headers: formatHeader(format))
  end
end
