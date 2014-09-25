require "yaml"
require "logger"
  # Singleton config used throughout
  class MyConfig
    class << self

      OPTIONS = [
        :mysql_host,
        :mysql_user,
        :mysql_passwd,
        :mysql_dbname,
        :mysql_port,
        :mysql_cluster_host,
        :mysql_cluster_user,
        :mysql_cluster_passwd,
        :mysql_cluster_dbname,
        :mysql_cluster_port,
        :logger,
        :tmp_dir,
        :svn_path,
        :svn_user,
        :svn_passwd,
        :bns_passwd,
        :routerlist1,
        :routerlist2
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
        @mysql_port=config['mysql_port'] || 3306
        @mysql_cluster_host=config['mysql_cluster_host']
        @mysql_cluster_user=config['mysql_cluster_user']
        @mysql_cluster_passwd=config['mysql_cluster_passwd']
        @mysql_cluster_dbname=config['mysql_cluster_dbname']
        @mysql_cluster_port=config['mysql_cluster_port'] || 3306
        @logger=Logger.new(config['logpath'])
        @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
        @logger.formatter = proc do |severity, datetime, progname, msg|
            "[#{datetime}] #{severity} : #{msg} \n"
        end
        @tmp_dir=config['tmp_dir']
        @svn_path=config['svn_path']
        @svn_user=config['svn_user']
        @svn_passwd=config['svn_passwd']
        @bns_passwd=config['bns_passwd']
        @routerlist1=config['routerlist1']
        @routerlist2=config['routerlist2']
      end
    end
  end
MyConfig.configure
