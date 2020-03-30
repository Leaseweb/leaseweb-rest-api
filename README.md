leaseweb-rest-api
=================

Rubygem to talk to Leaseweb's API


Installation
------------

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


Usage
-----

Start by creating a new instance of the `LeasewebAPI` class, and passing your
api key, private key and private key password.

```ruby
api_key = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

api = LeasewebAPI.new
api.apiKeyAuth(api_key)
```

or via oAuth:

```ruby
client_id = 'sadasdasd.asdasdasd.com'
client_secret = 'a844f7c131a7b63e4129cbcf88352034ef11c86481e0cb2ed3653c07345a113b'

api = LeasewebAPI.new
api.getOauthToken(client_id, client_secret)
```

All return values are the direct JSON responses from Leaseweb converted into a
Hash.

See: [documentation](http://developer.leaseweb.com/docs/)


Managing servers
----------------

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


Contribute
----------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
