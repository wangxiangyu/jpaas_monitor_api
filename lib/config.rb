require "logger"
  # Singleton config used throughout
  class MyConfig
    class << self

      OPTIONS = [
        :mysql_host,
        :mysql_user,
        :mysql_passwd,
        :mysql_dbname,
        :logger,
        :tmp_dir,
        :svn_path,
        :svn_user,
        :svn_passwd,
        :ccdb_host,
        :ccdb_user,
        :ccdb_passwd,
        :ccdb_name
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
        @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
        @logger.formatter = proc do |severity, datetime, progname, msg|
            "[#{datetime}] #{severity} : #{msg}"
        end
        @tmp_dir=config['tmp_dir']
        @svn_path=config['svn_path']
        @svn_user=config['svn_user']
        @svn_passwd=config['svn_passwd']
        @ccdb_host=config['ccdb_host']
        @ccdb_user=config['ccdb_user']
        @ccdb_passwd=config['ccdb_passwd']
        @ccdb_name=config['ccdb_name']
      end
    end
  end
MyConfig.configure
