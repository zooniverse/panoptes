require 'rest-client' 
require 'json'

client_id = ENV.fetch(CLIENT_ID, '')
client_secret = ENV.fetch(CLIENT_SECRET, '')

auth_hash = {
  grant_type: 'client_credentials',
  client_id: client_id,
  client_secret: client_secret
}

response = RestClient.post('https://signin.zooniverse.org/oauth/token', auth_hash)

json_response = JSON.parse(response)
puts json_response

token = json_response["access_token"]
puts token
