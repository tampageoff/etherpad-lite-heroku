#!/usr/bin/env ruby
require 'fileutils'
require 'json'
require 'uri'

# Create settings hash add merge in the user-provided JSON.
database_uri = URI.parse(ENV['DATABASE_URL'])
settings = {
  dbType: database_uri.scheme,
  dbSettings: {
    user: database_uri.user,
    host: database_uri.host,
    port: database_uri.port,
    password: database_uri.password,
    database: database_uri.path.sub(%r{^/}, ''),
    dbname: database_uri.path.sub(%r{^/}, '')
  },
  defaultPadText: '',
  editOnly: true,
  requireSession: true,
  title: '',
}.merge(JSON.parse(File.read(ENV.fetch('ETHERPAD_SETTINGS'))))

# Write the settings hash out as JSON.
File.open('./etherpad-lite/settings.json', 'w') { |f| f.write(settings.to_json) }

# Heroku uses an ephemeral file system. If etherpad generates the APIKey.txt by itself when it first runs, you cannot read the contents of the APIKey.txt file generated.
# Therefore, pass in your own ETHERPAD_API_KEY via the Heroku environment, so etherpad will use your key instead
# For more info, read http://etherpad.org/doc/v1.5.7/#index_authentication and source code node/handler/APIHandler.js
etherpad_api_key = ENV['ETHERPAD_API_KEY'];
unless etherpad_api_key.nil?
  File.open('./etherpad-lite/APIKEY.txt', 'w') { |f| f.write( etherpad_api_key ) } 
end

`./installPackages.sh`

if ENV['ETHERPAD_ALLOW_ROOT'] == '1'
exec('./etherpad-lite/bin/run.sh --root')
else
exec('./etherpad-lite/bin/run.sh')
end
