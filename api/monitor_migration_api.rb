require "digest"
$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"
require "rack/contrib"

module Acme
  class MonitorMigration < Grape::API
    use Rack::JSONP
    format :json
    helpers do
      def format(s)
        s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
      end

      def get_random_hash
        SecureRandom.hex 16
      end

      def membrane(feed_hash, schema) 
        permeate = {}
        schema.each do |el|
          permeate[el] = feed_hash[el].clone
        end
        permeate
      end

      def clean_legacy(app_key)
        HttpUserDefinedMonitorRaw.where(:app_key => app_key).find_each do |raw|
          raw_hash = raw.serializable_hash
          HttpUserDefinedMonitorRule.where(:raw_key => raw_hash[:raw_key]).destroy_all
          HttpUserDefinedMonitorAlert.where(:raw_key => raw_hash[:raw_key]).destroy_all 
          raw.destroy 
        end
        UserDefinedMonitorRaw.where(:app_key => app_key).find_each do |raw|
          raw_hash = raw.serializable_hash
          UserDefinedMonitorRule.where(:raw_key => raw_hash[:raw_key]).destroy_all
          UserDefinedMonitorAlert.where(:raw_key => raw_hash[:raw_key]).destroy_all
          raw.destroy
        end
        ProcMonitorRaw.where(:app_key => app_key).find_each do |raw|
          raw_hash = raw.serializable_hash
          ProcMonitorRule.where(:raw_key => raw_hash[:raw_key]).destroy_all
          ProcMonitorAlert.where(:raw_key => raw_hash[:raw_key]).destroy_all
          raw.destroy
        end
        DomainMonitorRaw.where(:app_key => app_key).find_each do |raw|
          raw_hash = raw.serializable_hash
          DomainMonitorItem.where(:raw_key => raw_hash[:raw_key]).find_each do |item|
            item_hash = item.serializable_hash
            DomainMonitorRule.where(:item_key => item_hash[:item_key]).destroy_all
            item.destroy
          end
          DomainMonitorAlert.where(:raw_key => raw_hash[:raw_key]).destroy_all
          raw.destroy
        end
        LogMonitorRaw.where(:app_key => app_key).find_each do |raw|
          raw_hash = raw.serializable_hash
          LogMonitorItem.where(:raw_key => raw_hash[:raw_key]).find_each do |item|
            item_hash = item.serializable_hash
            LogMonitorRule.where(:item_key => item_hash[:item_key]).destroy_all
            item.destroy
          end
          LogMonitorAlert.where(:raw_key => raw_hash[:raw_key]).destroy_all
          raw.destroy
        end
      end

      def migrate_http_user_defined_monitor(oldkey, newkey)
        unless HttpUserDefinedMonitorRaw.where(:app_key=>oldkey).empty?
          HttpUserDefinedMonitorRaw.where(:app_key=>oldkey).find_each do |raw|
              raw_hash=raw.serializable_hash
              #insert raw
              raw = {}
              raw['app_key'] = newkey
              raw['method'] = 'http'
              raw['raw_key'] = get_random_hash
              raw.merge! membrane(raw_hash, ['name','cycle','target'])
              HttpUserDefinedMonitorRaw.create(raw)
              alert_info = HttpUserDefinedMonitorAlert.where(:raw_key=>raw_hash['raw_key']).first.serializable_hash
              #insert alert
              alert = {}
              alert['raw_key'] = raw['raw_key']
              alert['name'] = "alert_"+raw['raw_key']
              alert.merge! membrane(alert_info, ['max_alert_times', 'remind_interval_second', 'mail', 'sms'])
              HttpUserDefinedMonitorAlert.create(alert)
              HttpUserDefinedMonitorRule.where(:raw_key=>raw_hash['raw_key']).find_each do |rule|
                  rule_hash=rule.serializable_hash
                  #insert rule
                  rule = {}
                  rule['raw_key'] = raw['raw_key']
                  rule['alert'] = "alert_" + raw['raw_key']
                  rule['rule_key'] = get_random_hash
                  rule.merge! membrane(rule_hash, ['name', 'monitor_item', 'compare', 'threshold', 'filter', 'disable_time'])
                  HttpUserDefinedMonitorRule.create(rule)
              end #end_of_rule
          end #end_of_raw
        end #end_of_unless
      end #end_of_def

      def migrate_domain_monitor(oldkey, newkey)
        unless DomainMonitorRaw.where(:app_key=>oldkey).empty?
          DomainMonitorRaw.where(:app_key=>oldkey).find_each do |raw|
              raw_hash=raw.serializable_hash
              #insert raw
              raw = {}
              raw['app_key'] = newkey
              raw['raw_key'] = get_random_hash
              raw.merge! membrane(raw_hash, ['name','domain'])
              DomainMonitorRaw.create(raw)
              alert_info = DomainMonitorAlert.where(:raw_key=>raw_hash['raw_key']).first.serializable_hash
              #insert alert
              alert = {}
              alert['raw_key'] = raw['raw_key']
              alert['name'] = "alert_"+raw['raw_key']
              alert.merge! membrane(alert_info, ['mail', 'sms'])
              DomainMonitorAlert.create(alert)
              DomainMonitorItem.where(:raw_key => raw_hash['raw_key']).find_each do |item|
                item_hash = item.serializable_hash
                item = {}
                item['raw_key'] = raw['raw_key']
                item['cycle'] = '10'
                item['port'] = '80'
                item['req_type'] = 'http'
                item['mon_idc'] = 'jx,cq01,cq02,db01,m1,st01,tc,yf01'
                item['item_key'] = get_random_hash
                item.merge! membrane(item_hash, ['name', 'req_content', 'res_check'])
                DomainMonitorItem.create(item)
                DomainMonitorRule.where(:item_key => item_hash['item_key']).find_each do |rule|
                  rule_hash = rule.serializable_hash
                  rule = {}
                  rule['item_key'] = item['item_key']
                  rule['item_name'] = item['name']
                  rule['alert'] = "alert_" + raw['raw_key']
                  rule['rule_key'] = get_random_hash
                  rule['compare'] = '>'
                  rule['threshold'] = '0'
                  rule.merge! membrane(rule_hash, ['name', 'filter'])
                  DomainMonitorRule.create(rule)
                end
              end
          end #end_of_raw
        end #end_of_unless
      end #end_of_def

      def migrate_log_monitor(oldkey, newkey) 
        unless LogMonitorRaw.where(:app_key=>oldkey).empty?
          LogMonitorRaw.where(:app_key=>oldkey).find_each do |raw|
              raw_hash=raw.serializable_hash
              #insert raw
              raw = {}
              raw['app_key'] = newkey
              raw['method'] = 'noah'
              raw['target'] = 'logmon'
              raw['cycle'] = '60'
              raw['limit_rate'] = '10'
              raw['raw_key'] = get_random_hash
              raw.merge! membrane(raw_hash, ['name','log_filepath'])
              log_name="#{raw['raw_key']}_#{raw['name']}.conf"
              raw['params'] = "${ATTACHMENT_DIR}/#{log_name}"
              LogMonitorRaw.create(raw)
              alert_info = LogMonitorAlert.where(:raw_key=>raw_hash['raw_key']).first.serializable_hash
              #insert alert
              alert = {}
              alert['raw_key'] = raw['raw_key']
              alert['name'] = "alert_"+raw['raw_key']
              alert.merge! membrane(alert_info, ['max_alert_times', 'remind_interval_second', 'mail', 'sms'])
              LogMonitorAlert.create(alert)
              LogMonitorItem.where(:raw_key => raw_hash['raw_key']).find_each do |item|
                item_hash = item.serializable_hash
                item = {}
                item['raw_key'] = raw['raw_key']
                item['item_key'] = get_random_hash
                item.merge! membrane(item_hash, ['item_name_prefix', 'cycle', 'match_str'])
                LogMonitorItem.create(item)
                LogMonitorRule.where(:item_key => item_hash['item_key']).find_each do |rule|
                  rule_hash = rule.serializable_hash
                  rule = {}
                  rule['item_key'] = item['item_key']
                  rule['alert'] = "alert_" + raw['raw_key']
                  rule['rule_key'] = get_random_hash
                  rule.merge! membrane(rule_hash, ['name', 'filter', 'compare', 'threshold', 'disable_time'])
                  LogMonitorRule.create(rule)
                end #end_of_rule
              end #end_of_item
          end #end_of_raw
        end #end_of_unless
      end

      def migrate_user_defined_monitor(oldkey, newkey)
        unless UserDefinedMonitorRaw.where(:app_key=>oldkey).empty?
          UserDefinedMonitorRaw.where(:app_key=>oldkey).find_each do |raw|
              raw_hash=raw.serializable_hash
              #insert raw
              raw = {}
              raw['app_key'] = newkey
              raw['method'] = 'exec'
              raw['raw_key'] = get_random_hash
              raw.merge! membrane(raw_hash, ['name','cycle','target'])
              UserDefinedMonitorRaw.create(raw)
              alert_info = UserDefinedMonitorAlert.where(:raw_key=>raw_hash['raw_key']).first.serializable_hash
              #insert alert
              alert = {}
              alert['raw_key'] = raw['raw_key']
              alert['name'] = "alert_" + raw['raw_key']
              alert.merge! membrane(alert_info, ['max_alert_times', 'remind_interval_second', 'mail', 'sms'])
              UserDefinedMonitorAlert.create(alert)
              UserDefinedMonitorRule.where(:raw_key=>raw_hash['raw_key']).find_each do |rule|
                  rule_hash=rule.serializable_hash
                  #insert rule
                  rule = {}
                  rule['raw_key'] = raw['raw_key']
                  rule['alert'] = "alert_" + raw['raw_key']
                  rule['rule_key'] = get_random_hash
                  rule.merge! membrane(rule_hash, ['name', 'monitor_item', 'compare', 'threshold', 'filter', 'disable_time'])
                  UserDefinedMonitorRule.create(rule)
              end #end_of_rule
          end #end_of_raw
        end #end_of_unless
      end

      def migrate_proc_monitor(oldkey, newkey)
        unless ProcMonitorRaw.where(:app_key=>oldkey).empty?
          ProcMonitorRaw.where(:app_key=>oldkey).find_each do |raw|
              raw_hash=raw.serializable_hash
              #insert raw
              raw = {}
              raw['app_key'] = newkey
              raw['method'] = 'noah'
              raw['target'] = 'procmon'
              raw['raw_key'] = get_random_hash
              raw.merge! membrane(raw_hash, ['name', 'cycle', 'target'])
              ProcMonitorRaw.create(raw)
              alert_info = ProcMonitorAlert.where(:raw_key=>raw_hash['raw_key']).first.serializable_hash
              #insert alert
              alert = {}
              alert['raw_key'] = raw['raw_key']
              alert['name'] = "alert_" + raw['raw_key']
              alert.merge! membrane(alert_info, ['max_alert_times', 'remind_interval_second', 'mail', 'sms'])
              ProcMonitorAlert.create(alert)
              ProcMonitorRule.where(:raw_key=>raw_hash['raw_key']).find_each do |rule|
                  rule_hash=rule.serializable_hash
                  #insert rule
                  rule = {}
                  rule['raw_key'] = raw['raw_key']
                  rule['alert'] = "alert_" + raw['raw_key']
                  rule['rule_key'] = get_random_hash
                  rule.merge! membrane(rule_hash, ['name', 'monitor_item', 'compare', 'threshold', 'filter', 'disable_time'])
                  ProcMonitorRule.create(rule)
              end #end_of_rule
          end #end_of_raw
        end #end_of_unless
      end #end_of_def
    end #end_of_helpers

    namespace :monitor_migration do
      after do
        ActiveRecord::Base.clear_active_connections!
      end

      desc "for monitor migration from v2 to matrix"
      params do
        requires :v2_app_key, type: String, desc: "app key in v2"
        requires :matrix_app_key, type: String, desc: "app key in matrix"
      end
      post 'migration' do
        v2_app_key = format(params[:v2_app_key])
        matrix_app_key = format(params[:matrix_app_key])        
        begin
          clean_legacy matrix_app_key
          migrate_http_user_defined_monitor v2_app_key,matrix_app_key
          migrate_domain_monitor v2_app_key,matrix_app_key
          migrate_log_monitor v2_app_key,matrix_app_key
          migrate_user_defined_monitor v2_app_key,matrix_app_key
          migrate_proc_monitor v2_app_key,matrix_app_key
          return {:rescode => 0, :msg => "success"}
        rescue => e
          MyConfig.logger.warn(e.message)
          MyConfig.logger.warn(e.backtrace.join("\n"))
          error!({:rescode => -1, :msg=>"Error: inner service occurs an error."}, 400)
        end
      end
    end
  end
end
