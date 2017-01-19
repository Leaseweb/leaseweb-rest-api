leaseweb-rest-api
=====================

Rubygem to talk to Leaseweb's API

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'leaseweb-rest-api'
```

And then execute:

```
$ bundle
```

Or install it yourself:

```
$ gem install leaseweb-rest-api
```

## Generating a public/private keypair

Make sure you add a strong password to your SSH key!

```
ssh-keygen -t rsa -b 4096 -C "test@example.com" -f id_rsa
openssl rsa -in  id_rsa -pubout > id_rsa.pub.pem
rm id_rsa.pub
```

Copy the content of id_rsa.pub.pem to the 'Public RSA Key'-field your [SSC API page](https://secure.leaseweb.nl/en/sscApi). Click 'Show API key' for your API key. Keep your id_rsa file private.

## Usage

Start by creating a new instance of the `LeasewebAPI` class, and passing your api key, private key and private key password.

```ruby
api_key = 'e12b534e-3bf6-4208-89e6-e43798b3c30f'
privateKeyFile = './id_rsa'
password = 'my_super_strong_s3cr3t_passw0rd'
api = LeasewebAPI.new(api_key, privateKeyFile, password)
```

All return values are the direct JSON responses from Leaseweb converted into a Hash.

See: [documentation](http://developer.leaseweb.com/docs/)

### Managing servers

List my baremetal servers:

```
servers = api.getBareMetals()
```

List all operating systems:

```
api.getOperatingSystems
```

Install a server:

```ruby
params = []
params << { "type" => "ext2", "size" => 500, "mountpoint" => "/boot" }
params << { "type" => "swap", "size" => 4096 }
params << { "type" => "ext4", "size" => 2048, "mountpoint" => "/tmp" }
params << { "type" => "ext4", "size" => "*", "mountpoint" => "/" }

hdd = { "disk" => "/dev/sda", "params" => params, "bootable" => 0 }

puts api.installServer(serverid, osid, hdd)
```

Check the status of the install:

```
puts api.getInstallationStatus(bareMetalId)
```

Reboot a server:

```
puts api.postReboot(bareMetalId)
```

Set iPXE lease:

```
puts api.setLease(bareMetalId, 'http://pxe.example.com/boot.ipxe')
```

List all my domains:

```
puts api.getDomains
```

## Contribute

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
