require 'spec_helper'
require_relative '../../lib/leaseweb-rest-api'

describe LeasewebAPI do
  let(:apikey) { 'e17b534d-3af6-4208-89e6-e43798b3c30f' }
  let(:privateKey) { File.expand_path('./test/id_rsa') }
  let(:password) { 'cdcHRt+,zVuZWtV2a7PkixZTn' }
  let(:request_headers) do
    { 'X-Lsw-Auth' => apikey }
  end

  subject do
    api = LeasewebAPI.new
    api.apiKeyAuth(apikey)
    api.readPrivateKey(privateKey, password)
    api
  end

  describe '#getDomains' do
    let(:response) { '{}' }

    it 'returns a list of all the domains assigned to the account' do
      stub_request(:get, 'https://api.leaseweb.com/v1/domains')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getDomains
    end
  end

  describe '#getDomain' do
    let(:response) { '{}' }

    it 'returns a representation of a domain resource' do
      stub_request(:get, 'https://api.leaseweb.com/v1/domains/example.com')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getDomain('example.com')
    end
  end

  describe '#updateDomain' do
    let(:response) { '{}' }

    it 'updates a domain' do
      body = 'ttl=86400'

      stub_request(:put, 'https://api.leaseweb.com/v1/domains/example.com')
        .with(headers: request_headers, body: body)
        .to_return(status: 200, body: response, headers: {})

      subject.updateDomain('example.com', 86_400)
    end
  end

  describe '#getDNSRecords' do
    let(:response) { '{}' }

    it 'returns a representation of a specific dnsRecords of a domain' do
      stub_request(:get, 'https://api.leaseweb.com/v1/domains/example.com/dnsRecords')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getDNSRecords('example.com')
    end
  end

  describe '#createDNSRecords' do
    let(:response) { '{}' }

    it 'creates a new dns record' do
      body = 'host=example.com&content=123.123.123.123&type=MX&priority=10'

      stub_request(:post, 'https://api.leaseweb.com/v1/domains/example.com/dnsRecords')
        .with(headers: request_headers, body: body)
        .to_return(status: 200, body: response, headers: {})

      subject.createDNSRecords('example.com', 'example.com', '123.123.123.123', 'MX', 10)
    end
  end

  describe '#getDNSRecord' do
    let(:response) { '{}' }

    it 'returns a representation of a specific dnsRecord of a domain' do
      stub_request(:get, 'https://api.leaseweb.com/v1/domains/example.com/dnsRecords/123')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getDNSRecord('example.com', 123)
    end
  end

  describe '#updateDNSRecord' do
    let(:response) { '{}' }

    it 'updates a dns record' do
      body = 'id=123&host=example.com&content=10.10.10.10&type=MX&priority=20'

      stub_request(:put, 'https://api.leaseweb.com/v1/domains/example.com/dnsRecords/123')
        .with(headers: request_headers, body: body)
        .to_return(status: 200, body: response, headers: {})

      subject.updateDNSRecord('example.com', '123', 'example.com', '10.10.10.10', 'MX', '20')
    end
  end

  describe '#deleteDNSRecord' do
    let(:response) { '{}' }

    it 'deletes a dns record for a domain' do
      stub_request(:delete, 'https://api.leaseweb.com/v1/domains/example.com/dnsRecords/123')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.deleteDNSRecord('example.com', '123')
    end
  end

  describe '#getRescueImages' do
    let(:response) do
      '{"rescueImages":[{"rescueImage":{"id":121,"name":"FreeBSD Rescue 2.1 (amd64)"}},{"rescueImage":{"id":122,"name":"FreeBSD Rescue 2.1 (x86)"}},{"rescueImage":{"id":137,"name":"Rescue 2.1 (amd64)"}},{"rescueImage":{"id":138,"name":"Rescue 2.1 (x86)"}}]}'
    end

    it 'returns all your available rescue images' do
      stub_request(:get, 'https://api.leaseweb.com/v1/rescueImages')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getRescueImages
    end
  end

  describe '#getBareMetals' do
    let(:response) do
      '{"bareMetals":[{"bareMetal":{"reference":null,"bareMetalId":"114916","serverName":"LSPG003","serverType":"Bare Metal"}},{"bareMetal":{"reference":null,"bareMetalId":"198969","serverName":"LSPG001","serverType":"Bare Metal"}},{"bareMetal":{"reference":null,"bareMetalId":"198970","serverName":"LSPG002","serverType":"Bare Metal"}}]}'
    end

    it 'returns the id of all your Bare Metal servers' do
      stub_request(:get, 'https://api.leaseweb.com/v1/bareMetals')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getBareMetals
    end
  end

  describe '#getBareMetal' do
    let(:response) do
      '{"bareMetal":{"reference":null,"location":{"site":"SFO-12","cabinet":"0209","rackspace":"-","combinationLock":"-"},"server":{"ram":"16GB","kvm":"No","serverType":"Preinstalled SFO12.300.0209 DL120 G7","processorType":"Intel Quad-Core Xeon E3-1230","processorSpeed":"3200 Mhz","numberOfCpus":1,"numberOfCores":4,"hardDisks":" 2x1TB ","hardwareRaid":"No"},"network":{"dataPack":"Connectivity - see other packs","ipsFreeOfCharge":"1","ipsAssigned":1,"excessIpsPrice":"0.00","dataPackExcess":{"type":"","value":"0.00","unit":""},"macAddresses":{"mac":["C8:CB:B8:C5:17:0C","C8:CB:B8:C5:17:0D"]}},"extras":{"extra":{"service":"Private network: 100Mbps"}},"bareMetalId":"114916","serverName":"LSPG003","serverType":"Bare Metal","serverHostingPack":{"reference":null,"bareMetalId":"114916","serverName":"LSPG003","serverType":"Bare Metal","startDate":"Jul 1, 2012","endDate":"","contractTerm":"3 month(s)"},"serverSpecifications":[],"serviceLevelAgreement":{"sla":"Basic - 24x7x24"},"datacenterAccessCards":{"accessCards":["0",[]]}}}'
    end

    it 'returns the data of your Bare Metal server' do
      stub_request(:get, 'https://api.leaseweb.com/v1/bareMetals/114916')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getBareMetal(114_916)
    end
  end

  describe '#updateBareMetal' do
    let(:response) { '{}' }

    it 'updates a bareMetal' do
      body = 'reference=test'

      stub_request(:put, 'https://api.leaseweb.com/v1/bareMetals/114916')
        .with(headers: request_headers, body: body)
        .to_return(status: 200, body: response, headers: {})

      subject.updateBareMetal(114_916, 'test')
    end
  end

  describe '#getSwitchPort' do
    let(:response) do
      '{"switchPort":{"status":"open","serverId":"114916","serverName":"LSPG003","switchNode":1}}'
    end

    it 'returns the switchport status of your Bare Metal server' do
      stub_request(:get, 'https://api.leaseweb.com/v1/bareMetals/114916/switchPort')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getSwitchPort(114_916)
    end
  end

  describe '#postSwitchPortOpen' do
    let(:response) { '{}' }

    it 'opens the switch port of your Bare Metal server' do
      stub_request(:post, 'https://api.leaseweb.com/v1/bareMetals/114916/switchPort/open')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.postSwitchPortOpen(114_916)
    end
  end

  describe '#postSwitchPortClose' do
    let(:response) { '{}' }

    it 'closes the switch port of your Bare Metal server' do
      stub_request(:post, 'https://api.leaseweb.com/v1/bareMetals/114916/switchPort/close')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.postSwitchPortClose(114_916)
    end
  end

  describe '#getPowerStatus' do
    let(:response) do
      '{"powerStatus":{"status":"on","serverId":"114916","serverName":"LSPG003"}}'
    end

    it 'returns the power status of your Bare Metal server' do
      stub_request(:get, 'https://api.leaseweb.com/v1/bareMetals/114916/powerStatus')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getPowerStatus(114_916)
    end
  end

  describe '#getIPs' do
    let(:response) do
      '{"ips":[{"ip":{"ip":"209.58.131.10","reverseLookup":"","ipDetails":{"gateway":"209.58.131.62","mask":"255.255.255.192"},"nullRouted":false,"billingInformation":{"price":"0.00","startDate":"Jun 1, 2015","endDate":null},"serverId":"114916","serverType":"Bare Metal","serverName":"LSPG003"}}]}'
    end

    it 'returns the ips of your Bare Metal server' do
      stub_request(:get, 'https://api.leaseweb.com/v1/bareMetals/114916/ips')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getIPs(114_916)
    end
  end

  describe '#getIP' do
    let(:response) do
      '{"ip":{"ip":"209.58.131.10","reverseLookup":"","ipDetails":{"gateway":"209.58.131.62","mask":"255.255.255.192"},"nullRouted":false,"billingInformation":{"price":"0.00","startDate":"Jun 1, 2015","endDate":null},"serverId":"114916","serverType":"Bare Metal","serverName":"LSPG003"}}'
    end

    it 'returns information about the ip of your Bare Metal server' do
      stub_request(:get, 'https://api.leaseweb.com/v1/bareMetals/114916/ips/209.58.131.10')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getIP(114_916, '209.58.131.10')
    end
  end

  describe '#updateIP' do
    let(:response) { '{}' }

    it 'updates information of the ip of your Bare Metal server' do
      stub_request(:put, 'https://api.leaseweb.com/v1/bareMetals/114916/ips/209.58.131.10')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.updateIP(114_916, '209.58.131.10', 'modified-by-api.leaseweb.com', 1)
    end
  end

  describe '#getNetworkUsage' do
    let(:response) do
      '{"bandwidth":{"measurement":{"node":{"in":"-","out":"-","total":"10.91 Kbps"},"total":"10.91 Kbps","average":"10.91 Kbps"},"overusage":"0 bps","serverId":114916,"serverName":"LSPG003","interval":{"from":"09-05-2015","to":"08-06-2015"},"monthlyThreshold":"0 Mbps"},"dataTraffic":{"measurement":{"node":{"in":"3.5 GB","out":"523.81 MB","total":"4.02 GB"},"total":"4.02 GB"},"overusage":"0 B","serverId":114916,"serverName":"LSPG003","interval":{"from":"09-05-2015","to":"08-06-2015"},"monthlyThreshold":"0 GB"}}'
    end

    it 'returns network usage details of a bareMetal server' do
      stub_request(:get, 'https://api.leaseweb.com/v1/bareMetals/114916/networkUsage')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getNetworkUsage(114_916)
    end
  end

  describe '#getNetworkUsageBandWidth' do
    let(:response) do
      '{"bandwidth":{"measurement":{"node":{"in":"-","out":"-","total":"10.91 Kbps"},"total":"10.91 Kbps","average":"10.91 Kbps"},"overusage":"0 bps","serverId":114916,"serverName":"LSPG003","interval":{"from":"09-05-2015","to":"08-06-2015"},"monthlyThreshold":"0 Mbps"},"dataTraffic":{"measurement":{"node":{"in":"3.5 GB","out":"523.81 MB","total":"4.02 GB"},"total":"4.02 GB"},"overusage":"0 B","serverId":114916,"serverName":"LSPG003","interval":{"from":"09-05-2015","to":"08-06-2015"},"monthlyThreshold":"0 GB"}}'
    end

    it 'returns network usage details of a bareMetal server' do
      stub_request(:get, 'https://api.leaseweb.com/v1/bareMetals/114916/networkUsage/bandWidth?dateFrom=06-04-2015&dateTo=06-05-2015')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getNetworkUsageBandWidth(114_916, '06-04-2015', '06-05-2015', 'json')
    end
  end

  describe '#getNetworkUsageDataTraffic' do
    let(:response) do
      '{"dataTraffic":{"measurement":{"node":{"in":"370.71 MB","out":"98.07 MB","total":"468.78 MB"},"total":"468.78 MB"},"overusage":"0 B","serverId":198969,"serverName":"LSPG001","interval":{"from":"06-04-2015","to":"06-05-2015"},"monthlyThreshold":"0 GB"}}'
    end

    it 'returns network usage details of a bareMetal server' do
      stub_request(:get, 'https://api.leaseweb.com/v1/bareMetals/114916/networkUsage/dataTraffic?dateFrom=06-04-2015&dateTo=06-05-2015')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getNetworkUsageDataTraffic(114_916, '06-04-2015', '06-05-2015', 'json')
    end
  end

  describe '#postReboot' do
    let(:response) { '{}' }

    it 'performs a reboot of the server' do
      stub_request(:post, 'https://api.leaseweb.com/v1/bareMetals/114916/reboot')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.postReboot(114_916)
    end
  end

  describe '#installServer' do
    let(:response) { '{}' }

    it 'performs a re-installation of the server' do
      body = 'osId=1899'

      stub_request(:post, 'https://api.leaseweb.com/v1/bareMetals/114916/install')
        .with(headers: request_headers, body: body)
        .to_return(status: 200, body: response, headers: {})

      subject.installServer(114_916, 1899)
    end
  end

  describe '#postResqueMode' do
    let(:response) { '{}' }

    it 'Launches the rescue mode for this bare metal server' do
      body = 'osId=121'

      stub_request(:post, 'https://api.leaseweb.com/v1/bareMetals/114916/rescueMode')
        .with(headers: request_headers, body: body)
        .to_return(status: 200, body: response, headers: {})

      subject.postResqueMode(114_916, 121)
    end
  end

  describe '#getRootPassword' do
    let(:response) do
      '{"dataTraffic":{"measurement":{"node":{"in":"370.71 MB","out":"98.07 MB","total":"468.78 MB"},"total":"468.78 MB"},"overusage":"0 B","serverId":198969,"serverName":"LSPG001","interval":{"from":"06-04-2015","to":"06-05-2015"},"monthlyThreshold":"0 GB"}}'
    end

    it 'returns the root password of the server' do
      stub_request(:get, 'https://api.leaseweb.com/v1/bareMetals/114916/rootPassword')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getRootPassword(114_916, 'json')
    end
  end

  describe '#getInstallationStatus' do
    let(:response) do
      '{"installationStatus":{"code":1000,"description":"Installing","serverPackId":"114916","serverName":"LSPG003"}}'
    end

    it 'returns the installation status of the server' do
      stub_request(:get, 'https://api.leaseweb.com/v1/bareMetals/114916/installationStatus')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getInstallationStatus(114_916)
    end
  end

  describe '#getLeases' do
    let(:response) do
      '{"_metadata":{"totalCount":1,"limit":10,"offset":0},"leases":[{"ip":"209.58.131.10","pop":"SFO-12","mac":"C8:CB:B8:C5:17:0C","scope":"209.58.131.0","options":[{"name":"Bootfile Name","optionId":"67","policyName":null,"type":"String","userClass":"","value":"undionly.kpxe","vendorClass":""},{"name":"DNS Servers","optionId":"6","policyName":null,"type":"IPv4Address","userClass":"","value":"209.58.128.22,209.58.135.185","vendorClass":""},{"name":"Boot Server Host Name","optionId":"66","policyName":null,"type":"String","userClass":"","value":"209.58.128.13","vendorClass":""},{"name":"Bootfile Name","optionId":"67","policyName":null,"type":"String","userClass":"gPXE","value":"http:\\/\\/95.211.51.8\\/server\\/getPxeConfig\\/serverId\\/58898\\/key\\/86504289080a3a914ac53912ea55336f","vendorClass":""}]}]}'
    end

    it 'returns a list of DHCP Leases for every MAC Address for a given bare metal' do
      stub_request(:get, 'https://api.leaseweb.com/v1/bareMetals/114916/leases')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getLeases(114_916)
    end
  end

  describe '#setLease' do
    let(:response) { '{}' }

    it 'Creates a new DHCP lease' do
      stub_request(:post, 'https://api.leaseweb.com/v1/bareMetals/114916/leases')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.setLease(114_916, 'http://example.com/boot.ipxe')
    end
  end

  describe '#getLease' do
    let(:response) do
      '{"ip":"209.58.131.10","pop":"SFO-12","mac":"C8:CB:B8:C5:17:0C","scope":"209.58.131.0","options":[{"name":"Bootfile Name","optionId":"67","policyName":null,"type":"String","userClass":"","value":"undionly.kpxe","vendorClass":""},{"name":"DNS Servers","optionId":"6","policyName":null,"type":"IPv4Address","userClass":"","value":"209.58.128.22,209.58.135.185","vendorClass":""},{"name":"Boot Server Host Name","optionId":"66","policyName":null,"type":"String","userClass":"","value":"209.58.128.13","vendorClass":""},{"name":"Bootfile Name","optionId":"67","policyName":null,"type":"String","userClass":"gPXE","value":"http:\\/\\/95.211.51.8\\/server\\/getPxeConfig\\/serverId\\/58898\\/key\\/86504289080a3a914ac53912ea55336f","vendorClass":""}]}'
    end

    it 'returns a DHCP Lease for every MAC Address for a bare metal with specific MAC address' do
      stub_request(:get, 'https://api.leaseweb.com/v1/bareMetals/114916/leases/C8:CB:B8:C5:17:0C')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getLease(114_916, 'C8:CB:B8:C5:17:0C')
    end
  end

  describe '#deleteLease' do
    let(:response) { '{}' }

    it 'deletes a DHCP lease for a specific mac address' do
      stub_request(:delete, 'https://api.leaseweb.com/v1/bareMetals/114916/leases/C8:CB:B8:C5:17:0C')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.deleteLease(114_916, 'C8:CB:B8:C5:17:0C')
    end
  end

  describe '#getPrivateNetworks' do
    let(:response) do
      '{"meta":{"first_page":1,"last_page":1,"previous_page":null,"current_page":1,"next_page":null,"total_results":1,"results_per_page":50},"results":[{"id":157,"name":""}]}'
    end

    it 'returns a list of all your privatenetworks' do
      stub_request(:get, 'https://api.leaseweb.com/v1/privateNetworks')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getPrivateNetworks
    end
  end

  describe '#createPrivateNetworks' do
    let(:response) { '{}' }

    it 'Creates a new private network' do
      stub_request(:post, 'https://api.leaseweb.com/v1/privateNetworks')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.createPrivateNetworks
    end
  end

  describe '#getPrivateNetworks' do
    let(:response) do
      '{"meta":{"first_page":1,"last_page":1,"previous_page":null,"current_page":1,"next_page":null,"total_results":1,"results_per_page":50},"results":[{"id":157,"name":""}]}'
    end

    it 'returns a list of all your privatenetworks' do
      stub_request(:get, 'https://api.leaseweb.com/v1/privateNetworks')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getPrivateNetworks
    end
  end

  describe '#getPrivateNetwork' do
    let(:response) do
      '{"id":157,"name":"","bareMetals":[{"id":198969,"status":"CONFIGURED","dataCenter":"SFO-12","CIDR":"10.29.0.32\\/27","broadcast":"10.29.0.63","gateway":"10.29.0.62","netmask":"255.255.255.224","portSpeed":100},{"id":198970,"status":"CONFIGURED","dataCenter":"SFO-12","CIDR":"10.29.0.32\\/27","broadcast":"10.29.0.63","gateway":"10.29.0.62","netmask":"255.255.255.224","portSpeed":100},{"id":114916,"status":"CONFIGURED","dataCenter":"SFO-12","CIDR":"10.29.0.32\\/27","broadcast":"10.29.0.63","gateway":"10.29.0.62","netmask":"255.255.255.224","portSpeed":100}]}'
    end

    it 'returns information about your private network and servers' do
      stub_request(:get, 'https://api.leaseweb.com/v1/privateNetworks/157')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getPrivateNetwork(157)
    end
  end

  describe '#updatePrivateNetwork' do
    let(:response) { '{}' }

    it 'updates the name of your private network' do
      body = 'name=test'

      stub_request(:put, 'https://api.leaseweb.com/v1/privateNetworks/157')
        .with(headers: request_headers, body: body)
        .to_return(status: 200, body: response, headers: {})

      subject.updatePrivateNetwork(157, 'test')
    end
  end

  describe '#deletePrivateNetwork' do
    let(:response) { '{}' }

    it 'deletes a private network' do
      stub_request(:delete, 'https://api.leaseweb.com/v1/privateNetworks/157')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.deletePrivateNetwork(157)
    end
  end

  describe '#createPrivateNetworks' do
    let(:response) { '{}' }

    it 'add a server to your private network' do
      body = 'bareMetalId=114916'

      stub_request(:post, 'https://api.leaseweb.com/v1/privateNetworks/157/bareMetals')
        .with(headers: request_headers, body: body)
        .to_return(status: 200, body: response, headers: {})

      subject.createPrivateNetworksBareMetals(157, 114_916)
    end
  end

  describe '#deletePrivateNetworksBareMetals' do
    let(:response) { '{}' }

    it 'delete server from your private network' do
      stub_request(:delete, 'https://api.leaseweb.com/v1/privateNetworks/157/bareMetals/114916')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.deletePrivateNetworksBareMetals(157, 114_916)
    end
  end

  describe '#getOperatingSystems' do
    let(:response) do
      '{"operatingSystems":[{"operatingSystem":{"id":664,"name":"CentOS 5 (i386)"}},{"operatingSystem":{"id":665,"name":"CentOS 5 (x86_64)"}},{"operatingSystem":{"id":867,"name":"CentOS 6 (i386)"}},{"operatingSystem":{"id":868,"name":"CentOS 6 (x86_64)"}},{"operatingSystem":{"id":1899,"name":"CentOS 7 (x86_64)"}},{"operatingSystem":{"id":921,"name":"CloudLinux 6.4 (i386)"}},{"operatingSystem":{"id":920,"name":"CloudLinux 6.4 (x86_64)"}},{"operatingSystem":{"id":532,"name":"Debian 6.0 (amd64)"}},{"operatingSystem":{"id":531,"name":"Debian 6.0 (x86)"}},{"operatingSystem":{"id":1566,"name":"Debian 7.0 (x86)"}},{"operatingSystem":{"id":1567,"name":"Debian 7.0 (x86_64)"}},{"operatingSystem":{"id":2142,"name":"Debian 8.0 (x86_64)"}},{"operatingSystem":{"id":873,"name":"ESXi 5.0 (x86_64)"}},{"operatingSystem":{"id":1039,"name":"ESXi 5.1 (x86_64)"}},{"operatingSystem":{"id":1864,"name":"ESXi 5.5 (x86_64)"}},{"operatingSystem":{"id":2143,"name":"ESXi 6.0 (x86_64)"}},{"operatingSystem":{"id":1953,"name":"FreeBSD 10.1 (amd64)"}},{"operatingSystem":{"id":1901,"name":"FreeBSD 10.1 (i386)"}},{"operatingSystem":{"id":764,"name":"FreeBSD 8.4 (amd64)"}},{"operatingSystem":{"id":765,"name":"FreeBSD 8.4 (x86)"}},{"operatingSystem":{"id":927,"name":"FreeBSD 9.3 (amd64)"}},{"operatingSystem":{"id":926,"name":"FreeBSD 9.3 (i386)"}},{"operatingSystem":{"id":946,"name":"Ubuntu 12.04 (amd64)"}},{"operatingSystem":{"id":945,"name":"Ubuntu 12.04 (x86)"}},{"operatingSystem":{"id":1789,"name":"Ubuntu 14.04 (amd64)"}},{"operatingSystem":{"id":1790,"name":"Ubuntu 14.04 (x86)"}},{"operatingSystem":{"id":672,"name":"Windows 2008 R2 Enterprise (x64)"}},{"operatingSystem":{"id":175,"name":"Windows 2008 R2 Standard (x64)"}},{"operatingSystem":{"id":539,"name":"Windows 2008 R2 Standard (2 CPU) (x64)"}},{"operatingSystem":{"id":165,"name":"Windows 2008 R2 Web (x64)"}},{"operatingSystem":{"id":538,"name":"Windows 2008 R2 Web (2 CPU) (x64)"}},{"operatingSystem":{"id":1610,"name":"Windows Server 2012 Datacenter (1 CPU) (x64)"}},{"operatingSystem":{"id":1611,"name":"Windows Server 2012 Datacenter (2 CPU) (x64)"}},{"operatingSystem":{"id":2002,"name":"Windows Server 2012 R2 Datacenter (1 CPU) (x64)"}},{"operatingSystem":{"id":2003,"name":"Windows Server 2012 R2 Datacenter (2 CPU) (x64)"}},{"operatingSystem":{"id":2000,"name":"Windows Server 2012 R2 Standard (1 CPU) (x64)"}},{"operatingSystem":{"id":2001,"name":"Windows Server 2012 R2 Standard (2 CPU) (x64)"}},{"operatingSystem":{"id":1603,"name":"Windows Server 2012 Standard (1 CPU) (x64)"}},{"operatingSystem":{"id":1604,"name":"Windows Server 2012 Standard (2 CPU) (x64)"}}]}'
    end

    it 'returns the list of available operatingSystems for installation' do
      stub_request(:get, 'https://api.leaseweb.com/v1/operatingSystems')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getOperatingSystems
    end
  end

  describe '#getOperatingSystem' do
    let(:response) do
      '{"operatingSystem":{"id":1899,"name":"CentOS 7 (x86_64)"}}'
    end

    it 'returns the details of an operating system for installation' do
      stub_request(:get, 'https://api.leaseweb.com/v1/operatingSystems/1899')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getOperatingSystem(1899)
    end
  end

  describe '#getControlPanels' do
    let(:response) do
      '{"controlPanels":[{"controlPanel":{"id":1868,"name":"Plesk 12 (10 Domains Linux)"}},{"controlPanel":{"id":1875,"name":"Plesk 12 (30 Domains Linux)"}},{"controlPanel":{"id":1878,"name":"Plesk 12 (Unlimited Domains Linux)"}}]}'
    end

    it 'returns the details of an operating system for installation' do
      stub_request(:get, 'https://api.leaseweb.com/v1/operatingSystems/1899/controlPanels')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getControlPanels(1899)
    end
  end

  describe '#getControlPanel' do
    let(:response) do
      '{"controlPanel":{"id":1868,"name":"Plesk 12 (10 Domains Linux)"}}'
    end

    it 'returns the details of available control panels for installation on a particular operating system' do
      stub_request(:get, 'https://api.leaseweb.com/v1/operatingSystems/1899/controlPanels/1868')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getControlPanel(1899, 1868)
    end
  end

  describe '#getPartitionSchema' do
    let(:response) do
      '{"partitionSchema":{"limit":7,"disks":{"disk":["\\/dev\\/sda","\\/dev\\/hda","\\/dev\\/cciss\\/c0d0"]},"suggestion":{"disk":"\\/dev\\/sda","bootable":0,"hdd":{"partition":[{"index":0,"size":"500","type":"ext2","mountpoint":"\\/boot"},{"index":1,"size":"4096","type":"swap","mountpoint":""},{"index":2,"size":"2048","type":"ext4","mountpoint":"\\/tmp"},{"index":3,"size":"*","type":"ext4","mountpoint":"\\/"}]}},"filesystemTypes":{"type":["ext2","ext3","ext4","xfs","swap"]}}}'
    end

    it 'returns the list of available partition schema\'s for installation' do
      stub_request(:get, 'https://api.leaseweb.com/v1/operatingSystems/1899/partitionSchema?serverPackId=114916')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getPartitionSchema(1899, 114_916)
    end
  end

  describe '#getIps' do
    let(:response) do
      '{"ips":[{"ip":{"ip":"209.58.131.10","reverseLookup":"","ipDetails":{"gateway":"209.58.131.62","mask":"255.255.255.192"},"nullRouted":false,"billingInformation":{"price":"0.00","startDate":"Jun 1, 2015","endDate":null},"serverId":"114916","serverType":"Bare Metal","serverName":"LSPG003"}},{"ip":{"ip":"209.58.128.85","reverseLookup":"","ipDetails":{"gateway":"209.58.128.126","mask":"255.255.255.192"},"nullRouted":false,"billingInformation":{"price":"0.00","startDate":"Mar 1, 2015","endDate":null},"serverId":"198969","serverType":"Bare Metal","serverName":"LSPG001"}},{"ip":{"ip":"209.58.128.148","reverseLookup":"","ipDetails":{"gateway":"209.58.128.190","mask":"255.255.255.192"},"nullRouted":false,"billingInformation":{"price":"0.00","startDate":"Mar 1, 2015","endDate":null},"serverId":"198970","serverType":"Bare Metal","serverName":"LSPG002"}}]}'
    end

    it 'returns all IPs associated to the account' do
      stub_request(:get, 'https://api.leaseweb.com/v1/ips')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getIps
    end
  end

  describe '#getIps' do
    let(:response) do
      '{"ip":{"ip":"209.58.131.10","reverseLookup":"","ipDetails":{"gateway":"209.58.131.62","mask":"255.255.255.192"},"nullRouted":false,"billingInformation":{"price":"0.00","startDate":"Jun 1, 2015","endDate":null},"serverId":"114916","serverType":"Bare Metal","serverName":"LSPG003"}}'
    end

    it 'returns information about the IP' do
      stub_request(:get, 'https://api.leaseweb.com/v1/ips/209.58.131.10')
        .with(headers: request_headers)
        .to_return(status: 200, body: response, headers: {})

      subject.getIp('209.58.131.10')
    end
  end

  describe '#updateIp' do
    let(:response) { '{}' }

    it 'Updates information about the IP' do
      body = 'reverseLookup=modified-by-api.leaseweb.com&nullRouted=1'

      stub_request(:put, 'https://api.leaseweb.com/v1/ips/209.58.131.10')
        .with(headers: request_headers, body: body)
        .to_return(status: 200, body: response, headers: {})

      subject.updateIp('209.58.131.10', 'modified-by-api.leaseweb.com', 1)
    end
  end
end
