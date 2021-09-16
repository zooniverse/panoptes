# frozen_string_literal: true

# A sample Guardfile
# More info at https://github.com/guard/guard#readme

# ignore files (avoid high CPU use for FS events)
ignore([%r{^bin/*}, %r{^db/*}, %r{^log/*}, %r{^public/*}, %r{^tmp/*}, %r{^.git/*}, %r{^docs/*}])

default_watch_proc = proc do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }

  # Rails example
  watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/(.*)(\.erb|\.haml|\.slim)$})          { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
  watch('config/routes.rb')                           { "spec/routing" }
  watch('app/controllers/application_controller.rb')  { "spec/controllers" }
end

group :focus do
  guard 'rspec', cmd: "bin/rspec --tag focus --fail-fast", all_on_start: true, all_after_pass: false, notification: false do
    default_watch_proc.call
  end
end

guard 'rspec', cmd: "bin/rspec --fail-fast", all_on_start: true, all_after_pass: false, notification: false do
  default_watch_proc.call
end

scope groups: 'default'
