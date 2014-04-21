ENV['RACK_ENV'] ||= "test"

require File.expand_path('../application', __FILE__)
require 'mysql'
require 'yaml'
