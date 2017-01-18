require 'pp'
require_relative '../lib/leaseweb-rest-api.rb'

apikey = '6d4f7055-ba60-4b38-9145-fb62d20ccf28'
privateKey = './id_rsa'
password = 'p(ivzDEmUubm2fezWr@AY8NEH'

count = 0

l = LeasewebAPI.new(apikey, privateKey, password)

pp l.getBareMetals
