require File.expand_path('../config/environment', __FILE__)

NewRelic::Agent.manual_start

run Acme::App.new

