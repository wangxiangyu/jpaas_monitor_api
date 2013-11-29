require "logger"
module Collector
  # Singleton config used throughout
  class MyConfig
    class << self

      OPTIONS = [
        :mysql_host,
        :mysql_user,
        :mysql_passwd,
        :mysql_dbname,
        :logger,
      ]

      OPTIONS.each { |option| attr_accessor option }

      # Configures the various attributes
      #
      # @param [Hash] config the config Hash
      def configure()
        config_file = File.expand_path("../config/config.yml", File.dirname(__FILE__))
        config=YAML.load_file(config_file)
        @mysql_host=config['mysql_host']
        @mysql_user=config['mysql_user']
        @mysql_passwd=config['mysql_passwd']
        @mysql_dbname=config['mysql_dbname']
        @logger=Logger.new(config['logpath'])
      end
    end
  end
end
