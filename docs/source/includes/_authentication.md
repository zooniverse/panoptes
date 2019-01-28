# Authentication

Panoptes API provides an OAuth 2.0 authentication mechanism. (TODO: Describe
Authentication Workflow).

## How do I authenticate with the Zooniverse API?

Some requests to the Zooniverse API will respond without supplied authentication details as they are public but most require an authentication token to be supplied to access our systems as a known user.

This authentication token is known as a bearer token and is usually supplied as a HTTP `Authorization` header with the value prefixed by `Bearer` and then the token data. For example:

`Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c`

The bearer tokens we produce are actually [JWT tokens](https://jwt.io/) in and of themselves. This means that if you have a bearer token, you can unpack it, verify that it was signed by our servers, and find your user ID, your permissions and some other things.

## Tools to interact with the API

You can use Postman, Paw, cURL or one of our official Zooniverse libraries to authenticate and create requests to the API:

+ Python
  + https://github.com/zooniverse/panoptes-python-client
+ JavaScript
  + https://github.com/zooniverse/panoptes-javascript-client
+ Ruby
  + https://github.com/zooniverse/panoptes-client.rb


## Example using Postman

[Postman](https://www.getpostman.com/) is a graphical tool to help you make API calls.

### How do you get a token?

```http
POST /oauth/token HTTP/1.1
Content-Type: application/json

{
  "grant_type": "client_credentials",
  "client_id": "YOUR_CLIENT_ID",
  "client_secret": "YOUR_CLIENT_SECRET"
}
```

```ruby
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
```

There are multiple ways to get an OAuth bearer token from our authentication system, we support most of the OAuth grant types to convert credentials to a token. However our system restricts non-vetted apps from using particular flows, e.g. password (mostly to stop phishing sites harvesting our user credentials).

The easiest to get started with is to use OAuth and the client credentials OAuth flow. To do this you will need to [create an OAuth application with our system](https://signin.zooniverse.org/oauth/applications/new).

Complete the form like the image below:
![OAuth Application](/images/authentication/oauth_application.png)

Tick all the resource scopes you'll be needing access to (start with all). Once setup note your client ID and secret for that app and that this app will be linked to your user account. It is **imperative that you do not share the OAuth application secret** as it can gain access to your Zooniverse account as if you were using the system.

There are other OAuth flows that can be used to get bearer tokens, please [email contact@zooniverse.org](mailto:contact@zooniverse.org) to find out more.

### Setup postman to use the client credentials to get API bearer tokens

I won’t go into details on how to setup postman, there are lots of [docs that help with this](https://www.getpostman.com/docs/v6/).

You will need to setup a request to `https://signin.zooniverse.org/api/me` and under the authorization tab, select OAuth 2.0, and click the ‘Get New Access Token’ button. Complete the forms like the images below:

![initial postman req](/images/authentication/initial_postman_req.png)

![get new access token](/images/authentication/get_new_access_token.png)

1. Token name is used to identify the token in Postman, this is for your reference only
0. Select the grant type to be ‘Client Credentials’
0. Use the client ID from the OAuth application you setup at signin.zooniverse.org
0. Same for client secret
0. Scope is a lowercase, space separated list of all OAuth application scopes you selected at signin.zooniverse.org, in the image above for my testing app i only ticked user scope.
  + All scopes - user project group collection classification subject medium organization  translation public
0. Client authentication - send credentials in the request body
0. Press ‘Request Token’ button
  + If you can’t get a token and get a 422 response from the API ensure your scopes match exactly the list you selected for the app at signin.zooniverse.org earlier.
  + Use the Postman console to debug the requests
0. If successful you’ll see a screen with an access token, scroll down and press the ‘Use Token’ button

![access token](/images/authentication/access_token.png)

Now the request will have the authentication token setup for use in postman.

![req with access token](/images/authentication/req_with_access_token.png)


### Add extra Zooniverse API headers for each request

The Zooniverse API requires some extra headers to access the API endpoints, specifically setting the Accept and Content-Type headers.

Click on the ‘Headers’ tab and set the following header key value pairs as per the image below.

1. `Accept: application/vnd.api+json; version=1`
0. `Content-Type: application/json`

![add extra req headers](/images/authentication/api_headers.png)

Without the above extra headers any response to API endpoints will return a HTTP 404 response status code.

### Ready to send requests to the Zooniverse API

The request is now ready to run, click the ‘Send’ button to send the request to the Zooniverse API, you should see the response show up.

This response is to the https://signin.zooniverse.org/api/me endpoint and requests the information about the owner of the bearer token, i.e. ‘me’.

![api me response](/images/authentication/api_me_response.png)


### Debugging requests and responses

Again any request failures can be debugged using the postman console, here you get a detailed view each request / response that postman is sending.

![postman console](/images/authentication/postman_console.png)

Some common failure modes:
1. Can’t get a bearer token from OAuth application credentials
  + Ensure the app id and secret match exactly what is showing in https://signin.zoonivese.org/oauth/applications
  + Ensure the scopes match exactly, OAuth app has user selected, scopes should be ‘user public’
0. Get a 404 on /api/* endpoints request
  + Ensure the extra Accept and content-type headers are set on the requests, without them the API won’t route requests properly.
