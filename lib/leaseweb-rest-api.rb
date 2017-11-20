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
    @private_key = OpenSSL::PKey::RSA.new(File.read(privateKey), password)
  end

  def get(url)
    self.class.get(url, @options)
  end

  def get_paginated(url, key, offset = 0, limit = 50)
    data = []

    loop do
      response = self.class.get("#{url}&offset=#{offset}&limit=#{limit}", @options)
      total = response.parsed_response['_metadata']['totalCount']

      data += response.parsed_response[key]

      offset += limit
      break unless offset < total
    end

    data
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

  # Domains
  def getDomains
    self.class.get('/v1/domains', @options)
  end

  def getDomain(domain)
    self.class.get("/v1/domains/#{domain}", @options)
  end

  def updateDomain(domain, ttl)
    opt = @options.merge!(body: { ttl: ttl })

    self.class.put("/v1/domains/#{domain}", opt)
  end

  def getDNSRecords(domain)
    self.class.get("/v1/domains/#{domain}/dnsRecords", @options)
  end

  def createDNSRecords(domain, host, content, type, priority = nil)
    opt = @options.merge!(body: { host: host, content: content, type: type })

    if !priority.nil? && ((type == 'MX') || (type == 'SRV'))
      opt[:body][:priority] = priority
    end

    self.class.post("/v1/domains/#{domain}/dnsRecords", opt)
  end

  def getDNSRecord(domain, dnsRecordId)
    self.class.get("/v1/domains/#{domain}/dnsRecords/#{dnsRecordId}", @options)
  end

  def updateDNSRecord(domain, dnsRecordId, host, content, type, priority = nil)
    opt = @options.merge!(body: { id: dnsRecordId, host: host, content: content, type: type })

    if !priority.nil? && ((type == 'MX') || (type == 'SRV'))
      opt[:body][:priority] = priority
    end

    self.class.put("/v1/domains/#{domain}/dnsRecords/#{dnsRecordId}", opt)
  end

  def deleteDNSRecord(domain, dnsRecordId)
    self.class.delete("/v1/domains/#{domain}/dnsRecords/#{dnsRecordId}", @options)
  end

  # Rescue
  def getRescueImages
    self.class.get('/v1/rescueImages', @options)
  end

  # BareMetals
  def getBareMetals
    self.class.get('/v1/bareMetals', @options)
  end

  def getBareMetal(bareMetalId)
    self.class.get("/v1/bareMetals/#{bareMetalId}", @options)
  end

  def updateBareMetal(bareMetalId, reference)
    opt = @options.merge!(body: { reference: reference })

    self.class.put("/v1/bareMetals/#{bareMetalId}", opt)
  end

  def getSwitchPort(bareMetalId)
    self.class.get("/v1/bareMetals/#{bareMetalId}/switchPort", @options)
  end

  def postSwitchPortOpen(bareMetalId)
    self.class.post("/v1/bareMetals/#{bareMetalId}/switchPort/open", @options)
  end

  def postSwitchPortClose(bareMetalId)
    self.class.post("/v1/bareMetals/#{bareMetalId}/switchPort/close", @options)
  end

  def getPowerStatus(bareMetalId)
    self.class.get("/v1/bareMetals/#{bareMetalId}/powerStatus", @options)
  end

  def getIPs(bareMetalId)
    self.class.get("/v1/bareMetals/#{bareMetalId}/ips", @options)
  end

  def getIP(bareMetalId, ipAddress)
    self.class.get("/v1/bareMetals/#{bareMetalId}/ips/#{ipAddress}", @options)
  end

  def updateIP(bareMetalId, ipAddress, reverseLookup = '', nullRouted = 0)
    opt = @options.merge!(body: { reverseLookup: reverseLookup, nullRouted: nullRouted })

    self.class.put("/v1/bareMetals/#{bareMetalId}/ips/#{ipAddress}", opt)
  end

  def getIpmiCredentials(bareMetalId)
    self.class.get("/v1/bareMetals/#{bareMetalId}/ipmiCredentials", @options)
  end

  def getNetworkUsage(bareMetalId)
    self.class.get("/v1/bareMetals/#{bareMetalId}/networkUsage", @options)
  end

  def getNetworkUsageBandWidth(bareMetalId, dateFrom, dateTo, format = 'json')
    self.class.get("/v1/bareMetals/#{bareMetalId}/networkUsage/bandWidth", formatRequest(dateFrom, dateTo, format))
  end

  def getNetworkUsageDataTraffic(bareMetalId, dateFrom, dateTo, format = 'json')
    self.class.get("/v1/bareMetals/#{bareMetalId}/networkUsage/dataTraffic", formatRequest(dateFrom, dateTo, format))
  end

  def postReboot(bareMetalId)
    self.class.post("/v1/bareMetals/#{bareMetalId}/reboot", @options)
  end

  def installServer(bareMetalId, osId, hdd = [])
    opt = @options.merge!(body: { osId: osId, hdd: hdd }, query_string_normalizer: ->(h) { HashToURIConversion.new.to_params(h) })

    self.class.post("/v1/bareMetals/#{bareMetalId}/install", opt)
  end

  def postResqueMode(bareMetalId, osId)
    opt = @options.merge!(body: { osId: osId })

    self.class.post("/v1/bareMetals/#{bareMetalId}/rescueMode", opt)
  end

  def postV2RescueMode(serverId, rescueImageId, sshKey)
    opt = @options.merge!(body: { rescueImageId: rescueImageId, sshKeys: sshKey })

    self.class.post("/internal/bmpapi/v2/servers/#{serverId}/rescueMode", opt)
  end

  def getRootPassword(bareMetalId, format = 'json')
    opt = @options.merge!(headers: formatHeader(format))

    self.class.get("/v1/bareMetals/#{bareMetalId}/rootPassword", opt)
  end

  def getInstallationStatus(bareMetalId)
    response = self.class.get("/v1/bareMetals/#{bareMetalId}/installationStatus", @options)

    if response['installationStatus'].include?('initRootPassword')
      response['installationStatus']['initRootPassword'] = decrypt(response['installationStatus']['initRootPassword'])
    end

    if response['installationStatus'].include?('rescueModeRootPass')
      response['installationStatus']['rescueModeRootPass'] = decrypt(response['installationStatus']['rescueModeRootPass'])
    end

    response
  end

  def getLeases(bareMetalId)
    self.class.get("/v1/bareMetals/#{bareMetalId}/leases", @options)
  end

  def setLease(bareMetalId, bootFileName)
    opt = @options.merge!(body: { bootFileName: bootFileName })

    self.class.post("/v1/bareMetals/#{bareMetalId}/leases", opt)
  end

  def getLease(bareMetalId, macAddress)
    self.class.get("/v1/bareMetals/#{bareMetalId}/leases/#{macAddress}", @options)
  end

  def deleteLease(bareMetalId, macAddress)
    self.class.delete("/v1/bareMetals/#{bareMetalId}/leases/#{macAddress}", @options)
  end

  # Private Networks
  def getPrivateNetworks
    self.class.get('/v1/privateNetworks', @options)
  end

  # TODO: check post with name
  def createPrivateNetworks(name = '')
    opt = @options.merge!(body: { name: name })

    self.class.post('/v1/privateNetworks', opt)
  end

  def getPrivateNetwork(id)
    self.class.get("/v1/privateNetworks/#{id}", @options)
  end

  # TODO: Check with Jeroen if it works
  def updatePrivateNetwork(id, name = '')
    opt = @options.merge!(body: { name: name })

    self.class.put("/v1/privateNetworks/#{id}", opt)
  end

  def deletePrivateNetwork(id)
    self.class.delete("/v1/privateNetworks/#{id}", @options)
  end

  def createPrivateNetworksBareMetals(id, bareMetalId)
    opt = @options.merge!(body: { bareMetalId: bareMetalId })

    self.class.post("/v1/privateNetworks/#{id}/bareMetals", opt)
  end

  def deletePrivateNetworksBareMetals(id, bareMetalId)
    self.class.delete("/v1/privateNetworks/#{id}/bareMetals/#{bareMetalId}", @options)
  end

  # Operating Systems
  def getOperatingSystems
    self.class.get('/v1/operatingSystems', @options)
  end

  def getOperatingSystem(operatingSystemId)
    self.class.get("/v1/operatingSystems/#{operatingSystemId}", @options)
  end

  def getControlPanels(operatingSystemId)
    self.class.get("/v1/operatingSystems/#{operatingSystemId}/controlPanels", @options)
  end

  def getControlPanel(operatingSystemId, controlPanelId)
    self.class.get("/v1/operatingSystems/#{operatingSystemId}/controlPanels/#{controlPanelId}", @options)
  end

  def getPartitionSchema(operatingSystemId, bareMetalId)
    opt = @options.merge!(query: { serverPackId: bareMetalId })

    self.class.get("/v1/operatingSystems/#{operatingSystemId}/partitionSchema", opt)
  end

  # IPs
  def getIps
    self.class.get('/v1/ips', @options)
  end

  def getIp(ipAddress)
    self.class.get("/v1/ips/#{ipAddress}", @options)
  end

  def updateIp(ipAddress, reverseLookup = '', nullRouted = 0)
    opt = @options.merge!(body: { reverseLookup: reverseLookup, nullRouted: nullRouted })

    self.class.put("/v1/ips/#{ipAddress}", opt)
  end

  # Pay as you go
  def getPAYGInstances
    self.class.get('/v1/payAsYouGo/bareMetals/instances', @options)
  end

  def createPAYGInstance(modelId)
    opt = @options.merge!(model: modelId)

    self.class.post('/v1/payAsYouGo/bareMetals/instances', opt)
  end

  def getPAYGInstance(bareMetalId)
    self.class.get("/v1/payAsYouGo/bareMetals/instances/#{bareMetalId}", @options)
  end

  def destroyPAYGInstance(bareMetalId)
    self.class.post("/v1/payAsYouGo/bareMetals/instances/#{bareMetalId}/destroy", @options)
  end

  def getPAYGModels
    self.class.get('/v1/payAsYouGo/bareMetals/models', @options)
  end

  def getPAYGModelInstance(modelId)
    self.class.get("/v1/payAsYouGo/bareMetals/models/#{modelId}", @options)
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
