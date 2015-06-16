exit unless Rails.env.development?

require 'io/console'

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end
def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end
def yellow(text); colorize(text, 33); end

panoptes = %{
______  ___   _   _ ___________ _____ _____ _____
| ___ \\/ _ \\ | \\ | |  _  | ___ \\_   _|  ___/  ___|
| |_/ / /_\\ \\|  \\| | | | | |_/ / | | | |__ \\ `--.
|  __/|  _  || . ` | | | |  __/  | | |  __| `--. \\
| |   | | | || |\\  \\ \\_/ / |     | | | |___/\\__/ /
\\_|   \\_| |_/\\_| \\_/\\___/\\_|     \\_/ \\____/\\____/
}

puts yellow("\n\n---------------------------------------------------------------------")
puts yellow(panoptes)
puts "\nYou need to setup an Oauth client application to interact with the API."
puts "In turn this requires a local admin user account."
puts "This script will setup both for you.\n\n"
puts yellow("Please enter an password (min 8 chars) for the admin user, make it secure and you'll need to remember this!")
password = STDIN.noecho(&:gets).chomp
if password.length < 8
  abort(red("Failed: Password must be at least 8 characters long\n"))
end
puts yellow("Please re-enter your password")
second_password = STDIN.noecho(&:gets).chomp
unless password == second_password
  abort(red("Failed: passwords do not match!\n"))
end

#setup an admin user
attrs = { admin: true,
          password: password,
          login: 'zooniverse_admin',
          email: 'no-reply@zooniverse.org' }
admin = User.create(attrs) do |user|
  user.build_identity_group
end
puts "\nAdmin details:"
puts "login: #{green(admin.login)}"
puts "email: #{green(admin.email)}\n"

#setup a doorkeeper first party oauth application with scopes for the client
app = Doorkeeper::Application.create do |da|
  da.owner = admin
  da.name = 'FigDevAppClient'
  #testing redirect URL
  da.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
  # zooniverse first-party app
  da.trust_level = 2
  #scoped resources this app has access to
  scopes = [:public] | Doorkeeper::PanoptesScopes.optional
  da.default_scope = scopes.map(&:to_s)
end
puts "\nOauth Zooniverse first party app details:"
puts "client_id: #{green(app.uid)}\n"
puts "Use the client ID above to interact with the api."
puts "You can review these settings via the Oauth Applications page on your server at:"
puts yellow("http(s)://<server_ip:port>//oauth/applications\n\n")
