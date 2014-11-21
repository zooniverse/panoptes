exit unless Rails.env.development?
puts "You need to setup an Oauth client application to interact with the API."
puts "To do this you'll need a local admin user account, the following will setup both for you.\n\n"
puts "Please enter an password (min 8 chars) for the admin user, make it secure and you'll need to remember this!"
password = STDIN.noecho(&:gets).chomp
if password.length < 8
  abort("Failed: Password must be at least 8 characters long")
end

#setup an admin user
attrs = { display_name: 'Zooniverse Admin',
          password: password,
          login: 'zooniverse_admin',
          email: 'no-reply@zooniverse.org' }
admin = User.create(attrs) do |user|
  user.owner_name = OwnerName.new(name: user.login, resource: user)
end
puts "Admin details:"
puts "name: #{admin.login}"
puts "email: #{admin.email}"

#setup a doorkeeper first party oauth application with scopes for the client
app = Doorkeeper::Application.create do |da|
  da.owner = admin
  da.name = 'FigDevAppClient'
  #testing redirect URL
  da.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
  # zooniverse first-party app
  da.trust_level = 2
  #scoped resources this app has access to
  da.default_scope = ["public", "user", "project", "group", "collection", "classification"]
end
puts "Oauth Zooniverse first party app details:"
puts "client_id: #{app.uid}\n"
puts "Use the client ID above to interact with the api."
puts "You can reivew these settings via the Oauth Applications page at http(s)://<server_ip:port>//oauth/applications"
