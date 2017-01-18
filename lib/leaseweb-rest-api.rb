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

  base_uri 'https://api.leaseweb.com/v1'

  def initialize(apikey = nil, privateKey = nil, password = nil, clientId = nil, clientSecret = nil)
    @auth_token_url = 'https://auth.leaseweb.com/token'
    if !apikey.nil?
      @options = { headers: { 'X-Lsw-Auth' => apikey } }
    elsif !clientId.nil? && !clientSecret.nil?
      access_token = getOauthToken(clientId, clientSecret)['access_token']
      @options = { headers: { 'Authorization' => "Bearer #{access_token}" } }
    else
      puts 'Your API credentials are required.'
      exit
    end
    @private_key = OpenSSL::PKey::RSA.new(File.read(privateKey), password) unless privateKey.nil? || password.nil?
  end

  def getOauthToken(clientId, clientSecret)
    auth = { username: clientId, password: clientSecret }
    self.class.post(@auth_token_url, basic_auth: auth, body: { grant_type: 'client_credentials' })
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

  # Domains
  def getDomains
    self.class.get('/domains', @options)
  end

  def getDomain(domain)
    self.class.get("/domains/#{domain}", @options)
  end

  def updateDomain(domain, ttl)
    opt = @options.merge!(body: { ttl: ttl })

    self.class.put("/domains/#{domain}", opt)
  end

  def getDNSRecords(domain)
    self.class.get("/domains/#{domain}/dnsRecords", @options)
  end

  def createDNSRecords(domain, host, content, type, priority = nil)
    opt = @options.merge!(body: { host: host, content: content, type: type })

    if !priority.nil? && ((type == 'MX') || (type == 'SRV'))
      opt[:body][:priority] = priority
    end

    self.class.post("/domains/#{domain}/dnsRecords", opt)
  end

  def getDNSRecord(domain, dnsRecordId)
    self.class.get("/domains/#{domain}/dnsRecords/#{dnsRecordId}", @options)
  end

  def updateDNSRecord(domain, dnsRecordId, host, content, type, priority = nil)
    opt = @options.merge!(body: { id: dnsRecordId, host: host, content: content, type: type })

    if !priority.nil? && ((type == 'MX') || (type == 'SRV'))
      opt[:body][:priority] = priority
    end

    self.class.put("/domains/#{domain}/dnsRecords/#{dnsRecordId}", opt)
  end

  def deleteDNSRecord(domain, dnsRecordId)
    self.class.delete("/domains/#{domain}/dnsRecords/#{dnsRecordId}", @options)
  end

  # Rescue
  def getRescueImages
    self.class.get('/rescueImages', @options)
  end

  # BareMetals
  def getBareMetals
    self.class.get('/bareMetals', @options)
  end

  def getBareMetal(bareMetalId)
    self.class.get("/bareMetals/#{bareMetalId}", @options)
  end

  def updateBareMetal(bareMetalId, reference)
    opt = @options.merge!(body: { reference: reference })

    self.class.put("/bareMetals/#{bareMetalId}", opt)
  end

  def getSwitchPort(bareMetalId)
    self.class.get("/bareMetals/#{bareMetalId}/switchPort", @options)
  end

  def postSwitchPortOpen(bareMetalId)
    self.class.post("/bareMetals/#{bareMetalId}/switchPort/open", @options)
  end

  def postSwitchPortClose(bareMetalId)
    self.class.post("/bareMetals/#{bareMetalId}/switchPort/close", @options)
  end

  def getPowerStatus(bareMetalId)
    self.class.get("/bareMetals/#{bareMetalId}/powerStatus", @options)
  end

  def getIPs(bareMetalId)
    self.class.get("/bareMetals/#{bareMetalId}/ips", @options)
  end

  def getIP(bareMetalId, ipAddress)
    self.class.get("/bareMetals/#{bareMetalId}/ips/#{ipAddress}", @options)
  end

  def updateIP(bareMetalId, ipAddress, reverseLookup = '', nullRouted = 0)
    opt = @options.merge!(body: { reverseLookup: reverseLookup, nullRouted: nullRouted })

    self.class.put("/bareMetals/#{bareMetalId}/ips/#{ipAddress}", opt)
  end

  def getIpmiCredentials(bareMetalId)
    self.class.get("/bareMetals/#{bareMetalId}/ipmiCredentials", @options)
  end

  def getNetworkUsage(bareMetalId)
    self.class.get("/bareMetals/#{bareMetalId}/networkUsage", @options)
  end

  def getNetworkUsageBandWidth(bareMetalId, dateFrom, dateTo, format = 'json')
    self.class.get("/bareMetals/#{bareMetalId}/networkUsage/bandWidth", formatRequest(dateFrom, dateTo, format))
  end

  def getNetworkUsageDataTraffic(bareMetalId, dateFrom, dateTo, format = 'json')
    self.class.get("/bareMetals/#{bareMetalId}/networkUsage/dataTraffic", formatRequest(dateFrom, dateTo, format))
  end

  def postReboot(bareMetalId)
    self.class.post("/bareMetals/#{bareMetalId}/reboot", @options)
  end

  def installServer(bareMetalId, osId, hdd = [])
    opt = @options.merge!(body: { osId: osId, hdd: hdd }, query_string_normalizer: ->(h) { HashToURIConversion.new.to_params(h) })

    self.class.post("/bareMetals/#{bareMetalId}/install", opt)
  end

  def postResqueMode(bareMetalId, osId)
    opt = @options.merge!(body: { osId: osId })

    self.class.post("/bareMetals/#{bareMetalId}/rescueMode", opt)
  end

  def getRootPassword(bareMetalId, format = 'json')
    opt = @options.merge!(headers: formatHeader(format))

    self.class.get("/bareMetals/#{bareMetalId}/rootPassword", opt)
  end

  def getInstallationStatus(bareMetalId)
    response = self.class.get("/bareMetals/#{bareMetalId}/installationStatus", @options)

    if response['installationStatus'].include?('initRootPassword')
      response['installationStatus']['initRootPassword'] = decrypt(response['installationStatus']['initRootPassword'])
    end

    if response['installationStatus'].include?('rescueModeRootPass')
      response['installationStatus']['rescueModeRootPass'] = decrypt(response['installationStatus']['rescueModeRootPass'])
    end

    response
  end

  def getLeases(bareMetalId)
    self.class.get("/bareMetals/#{bareMetalId}/leases", @options)
  end

  def setLease(bareMetalId, bootFileName)
    opt = @options.merge!(body: { bootFileName: bootFileName })

    self.class.post("/bareMetals/#{bareMetalId}/leases", opt)
  end

  def getLease(bareMetalId, macAddress)
    self.class.get("/bareMetals/#{bareMetalId}/leases/#{macAddress}", @options)
  end

  def deleteLease(bareMetalId, macAddress)
    self.class.delete("/bareMetals/#{bareMetalId}/leases/#{macAddress}", @options)
  end

  # New install call
  def install(bareMetalId, operatingSystemId, options = {})
    options[:operatingSystemId] = operatingSystemId
    opt = @options.merge!(body: options.to_json)

    self.class.post("/bmpapi/bareMetals/#{bareMetalId}/install", opt)
  end

  # Private Networks
  def getPrivateNetworks
    self.class.get('/privateNetworks', @options)
  end

  # TODO: check post with name
  def createPrivateNetworks(name = '')
    opt = @options.merge!(body: { name: name })

    self.class.post('/privateNetworks', opt)
  end

  def getPrivateNetwork(id)
    self.class.get("/privateNetworks/#{id}", @options)
  end

  # TODO: Check with Jeroen if it works
  def updatePrivateNetwork(id, name = '')
    opt = @options.merge!(body: { name: name })

    self.class.put("/privateNetworks/#{id}", opt)
  end

  def deletePrivateNetwork(id)
    self.class.delete("/privateNetworks/#{id}", @options)
  end

  def createPrivateNetworksBareMetals(id, bareMetalId)
    opt = @options.merge!(body: { bareMetalId: bareMetalId })

    self.class.post("/privateNetworks/#{id}/bareMetals", opt)
  end

  def deletePrivateNetworksBareMetals(id, bareMetalId)
    self.class.delete("/privateNetworks/#{id}/bareMetals/#{bareMetalId}", @options)
  end

  # Operating Systems
  def getOperatingSystems
    self.class.get('/operatingSystems', @options)
  end

  def getOperatingSystem(operatingSystemId)
    self.class.get("/operatingSystems/#{operatingSystemId}", @options)
  end

  def getControlPanels(operatingSystemId)
    self.class.get("/operatingSystems/#{operatingSystemId}/controlPanels", @options)
  end

  def getControlPanel(operatingSystemId, controlPanelId)
    self.class.get("/operatingSystems/#{operatingSystemId}/controlPanels/#{controlPanelId}", @options)
  end

  def getPartitionSchema(operatingSystemId, bareMetalId)
    opt = @options.merge!(query: { serverPackId: bareMetalId })

    self.class.get("/operatingSystems/#{operatingSystemId}/partitionSchema", opt)
  end

  # IPs
  def getIps
    self.class.get('/ips', @options)
  end

  def getIp(ipAddress)
    self.class.get("/ips/#{ipAddress}", @options)
  end

  def updateIp(ipAddress, reverseLookup = '', nullRouted = 0)
    opt = @options.merge!(body: { reverseLookup: reverseLookup, nullRouted: nullRouted })

    self.class.put("/ips/#{ipAddress}", opt)
  end

  # Pay as you go
  def getPAYGInstances
    self.class.get('/payAsYouGo/bareMetals/instances', @options)
  end

  def createPAYGInstance(modelId)
    opt = @options.merge!(model: modelId)

    self.class.post('/payAsYouGo/bareMetals/instances', opt)
  end

  def getPAYGInstance(bareMetalId)
    self.class.get("/payAsYouGo/bareMetals/instances/#{bareMetalId}", @options)
  end

  def destroyPAYGInstance(bareMetalId)
    self.class.post("/payAsYouGo/bareMetals/instances/#{bareMetalId}/destroy", @options)
  end

  def getPAYGModels
    self.class.get('/payAsYouGo/bareMetals/models', @options)
  end

  def getPAYGModelInstance(modelId)
    self.class.get("/payAsYouGo/bareMetals/models/#{modelId}", @options)
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
