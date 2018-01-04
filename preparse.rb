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
#Move to the folder where ep-lite is installed
cd `dirname $0`

#Was this script started in the bin folder? if yes move out
if [ -d "../bin" ]; then
  cd "../"
fi

ignoreRoot=0
for ARG in $*
do
  if [ "$ARG" = "--root" ]; then
    ignoreRoot=1
  fi
done

#Stop the script if its started as root
if [ "$(id -u)" -eq 0 ] && [ $ignoreRoot -eq 0 ]; then
   echo "You shouldn't start Etherpad as root!"
   echo "Please type 'Etherpad rocks my socks' or supply the '--root' argument if you still want to start it as root"
   read rocks
   if [ ! $rocks = "Etherpad rocks my socks" ]
   then
     echo "Your input was incorrect"
     exit 1
   fi
fi

#prepare the enviroment
bin/installDeps.sh $* || exit 1

#Move to the node folder and start
echo "Started Etherpad..."

SCRIPTPATH=`pwd -P`
node $SCRIPTPATH/node_modules/ep_etherpad-lite/node/server.js $*

end
