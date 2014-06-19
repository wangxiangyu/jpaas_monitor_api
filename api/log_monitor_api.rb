require "digest"
$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"
require "rack/contrib"
require "securerandom"

module Acme
  class LogMonitor < Grape::API
    use Rack::JSONP
    format :json
    helpers do
        def get_raw_key_by_rule_key(item_key)
                raw_key=LogMonitorItem.where(:item_key=>item_key).first.raw_key
        end
        def format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
        def get_random_hash
            SecureRandom.hex 16
        end
        def get_raws(app_key)
            raws=[]
            unless LogMonitorRaw.where(:app_key=>app_key).empty?
                LogMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                    raw_hash=raw.serializable_hash
                    raw_hash.delete('id')
                    raw_hash.delete('cycle')
                    raw_hash.delete('method')
                    raw_hash.delete('target')
                    raw_hash.delete('params')
                    raw_hash.delete('limit_rate')
                    raw_hash.delete('updated_at')
                    raw_hash.delete('created_at')
                    raws.push(raw_hash)
                end
            end
            raws
        end
        def get_items(raw_key)
            items=[]
            unless LogMonitorItem.where(:raw_key=>raw_key).empty?
                LogMonitorItem.where(:raw_key=>raw_key).find_each do |item|
                    item_hash=item.serializable_hash
                    item_hash.delete('id')
                    item_hash.delete('threshold')
                    item_hash.delete('created_at')
                    item_hash.delete('updated_at')
                    items.push(item_hash)
                end
            end
            items
        end
        def get_rules(item_key)
            rules=[]
            unless LogMonitorRule.where(:item_key=>item_key).empty?
                LogMonitorRule.where(:item_key=>item_key).find_each do |rule|
                    rule_hash=rule.serializable_hash
                    rule_hash.delete('id')
                    rule_hash.delete('created_at')
                    rule_hash.delete('updated_at')
                    rule_hash.delete('alert')
                    rules.push(rule_hash)
                end
            end
            rules
        end
        def get_alerts(raw_key)
            alert_info={}
            unless LogMonitorAlert.where(:raw_key=>raw_key).empty?
                alert_info=LogMonitorAlert.where(:raw_key=>raw_key).first.serializable_hash
                alert_info.delete('id')
                alert_info.delete('raw_key')
                alert_info.delete('name')
                alert_info.delete('created_at')
                alert_info.delete('updated_at')
            end
            alert_info
        end
    end
    namespace :log_monitor do
        after do
            ActiveRecord::Base.clear_active_connections!
        end
        desc "add log monitor raw"
        params do
            requires :app_key, type: String, desc: "app key"
            requires :name, type: String, desc: "log name"
            requires :log_filepath, type: String, desc: "log path"
        end
        get '/add_raw' do
            raw={}
	        raw['app_key']=format(params['app_key'])
            if AppBns.where(:app_key=>raw['app_key']).empty?
                return {:rescode=>-1,:msg=>"Error: app_key:#{raw['app_key']} doesn't exist"}
            end
	        raw['name']=format(params['name'])
	        raw['cycle']='60'
	        raw['method']='noah'
	        raw['target']='logmon'
	        raw['log_filepath']=format(params['log_filepath'])
	        raw['raw_key']=get_random_hash
	        raw['limit_rate']='10'
            log_name="#{raw['raw_key']}_#{raw['name']}.conf"
            raw['params']="${ATTACHMENT_DIR}/#{log_name}"
            if LogMonitorRaw.where(:app_key=> raw['app_key'],:name=>raw['name']).empty?
                    LogMonitorRaw.create(raw)
                    return {:rescode=>0,:raw_key=>raw['raw_key']}
            else
                    return {:rescode=>-1,:msg=>"Error: You have added the same log raw"}
            end
        end
    
        desc "del log monitor raw"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/del_raw' do
            raw_key=format(params['raw_key'])
            if LogMonitorRaw.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"Error: raw:#{raw_key} doesn't exist"}
            else
                if LogMonitorItem.where(:raw_key=>raw_key).empty? 
                    LogMonitorRaw.where(:raw_key=>raw_key).destroy_all   
                    LogMonitorAlert.where(:raw_key=>raw_key).destroy_all   
                    return {:rescode=>0,:msg=>"ok"}
                else
                    return {:rescode=>-1,:msg=>"Error: please delete items related to this raw first"}
                end
            end
        end

        desc "update log monitor raw"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/update_raw' do 
            raw={}
	    raw_key=format(params['raw_key'])
            if LogMonitorRaw.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"Error: raw:#{raw_key} doesn't exist"}
            end
	        raw['name']=format(params['name'])
	        raw['log_filepath']=format(params['log_filepath'])
            LogMonitorRaw.where(:raw_key=>raw_key).update_all(raw)
            return {:rescode=>0,:raw_key=>raw_key}
        end

        desc "add log monitor item"
        params do
            requires :raw_key, type: String, desc: "raw key"
            requires :name, type: String, desc: "item name"
            requires :cycle, type: String, desc: "monitor cycle"
            requires :match_str, type: String, desc: "match string in regex mode"
        end
        get '/add_item' do
            item={}
	        item['raw_key']=format(params['raw_key'])
            if LogMonitorRaw.where(:raw_key=>item['raw_key']).empty?
                return {:rescode=>-1,:msg=>"Error: raw_key:#{item['raw_key']} doesn't exist"}
            end
	        item['item_name_prefix']=format(params['name'])
	        item['cycle']=format(params['cycle'])
	        item['match_str']=format(params['match_str'])
	        item['item_key']=get_random_hash
            if LogMonitorItem.where(:raw_key=>item['raw_key'],:item_name_prefix=>item['item_name_prefix']).empty?
                    LogMonitorItem.create(item)
                    return {:rescode=>0,:item_key=>item['item_key']}
            else
                    MyConfig.logger.warn("You have added the same log item")
                    return {:rescode=>-1,:msg=>"Error: You have added the same log item"}
            end
        end

    
        desc "del log monitor item"
        params do
            requires :item_key, type: String, desc: "item key"
        end
        get '/del_item' do
            item_key=format(params['item_key'])
            if LogMonitorItem.where(:item_key=>item_key).empty?
                return {:rescode=>-1,:msg=>"Error: item:#{item_key} doesn't exist"}
            else
                if LogMonitorRule.where(:item_key=>item_key).empty? 
                    LogMonitorItem.where(:item_key=>item_key).destroy_all   
                    return {:rescode=>0,:msg=>"ok"}
                else
                    return {:rescode=>-1,:msg=>"Error: please delete rules related to this item first"}
                end
            end
        end

        desc "update log monitor item"
        params do
            requires :item_key, type: String, desc: "item key"
            requires :name, type: String, desc: "item name"
            requires :cycle, type: String, desc: "monitor cycle"
            requires :match_str, type: String, desc: "match string in regex mode"
        end
        get '/update_item' do 
            item={}
	        item_key=format(params['item_key'])
            if LogMonitorItem.where(:item_key=>item_key).empty?
                return {:rescode=>-1,:msg=>"Error: item:#{item_key} doesn't exist"}
            end
	        item['item_name_prefix']=format(params['name'])
	        item['cycle']=format(params['cycle'])
	        item['match_str']=format(params['match_str'])
            LogMonitorItem.where(:item_key=>item_key).update_all(item)
            return {:rescode=>0,:item_key=>item_key}
        end

        desc "add log_monitor rule"
        params do
            requires :item_key, type: String, desc: "item key"
            requires :name, type: String, desc: "rule name"
            requires :compare, type: String, desc: "compare conditions: eg < <= !=...."
            requires :threshold, type: String, desc: "threshold"
            requires :filter, type: String, desc: "setting for alarm strategy"
            requires :disable_time, type: String, desc: "disable time in one day"
        end
        get '/add_rule' do
            rule={}
	        rule['item_key']=format(params['item_key'])
            if LogMonitorItem.where(:item_key=>rule['item_key']).empty?
                return {:rescode=>-1,:msg=>"Error: item_key:#{rule['item_key']} doesn't exist"}
            end
	        rule['name']=format(params['name'])
	        rule['compare']=format(params['compare'])
	        rule['threshold']=format(params['threshold'])
	        rule['filter']=format(params['filter'])
	        rule['alert']="alert_"+get_raw_key_by_rule_key(rule['item_key'])
	        rule['disable_time']=format(params['disable_time'])
	        rule['rule_key']=get_random_hash
            if LogMonitorRule.where(:item_key=>rule['item_key'],:name=>rule['name']).empty?
                    LogMonitorRule.create(rule)
                    return {:rescode=>0,:rule_key=>rule['rule_key']}
            else
                    MyConfig.logger.warn("You have added the same log rule ")
                    return {:rescode=>-1,:msg=>"Error: You have added the same log rule"}
            end
        end

        desc "del log monitor rule"
        params do
            requires :rule_key, type: String, desc: "rule key"
        end
        get '/del_rule' do
            rule_key=format(params['rule_key'])
            if LogMonitorRule.where(:rule_key=>rule_key).empty?
                return {:rescode=>-1,:msg=>"Error: rule:#{rule_key} doesn't exist"}
            else
                LogMonitorRule.where(:rule_key=>rule_key).destroy_all   
                return {:rescode=>0,:msg=>"ok"}
            end
        end

        desc "update log monitor rule"
        params do
            requires :rule_key, type: String, desc: "rule key"
        end
        get '/update_rule' do 
            rule={}
	        rule_key=format(params['rule_key'])
            if LogMonitorRule.where(:rule_key=>rule_key).empty?
                return {:rescode=>-1,:msg=>"Error: rule:#{rule_key} doesn't exist"}
            end
	        rule['name']=format(params['name'])
	        rule['compare']=format(params['compare'])
	        rule['threshold']=format(params['threshold'])
	        rule['filter']=format(params['filter'])
	        rule['disable_time']=format(params['disable_time'])
            LogMonitorRule.where(:rule_key=>rule_key).update_all(rule)
            return {:rescode=>0,:rule_key=>rule_key}
        end


        desc "add log monitor alert"
        params do
            requires :raw_key, type: String, desc: "raw key"
            requires :max_alert_times, type: String, desc: "max alert times"
            requires :remind_interval_second, type: String, desc: " remind interval in seconds"
            requires :mail, type: String, desc: "mails of alarm receivers"
            requires :sms, type: String, desc: "phones of alarm receivers"
        end
        get '/add_alert' do
            alert={}
	        alert['raw_key']=format(params['raw_key'])
            if LogMonitorRaw.where(:raw_key=>alert['raw_key']).empty?
                return {:rescode=>-1,:msg=>"Error: raw_key:#{alert['raw_key']} doesn't exist"}
            end
	        alert['name']="alert_"+format(params['raw_key'])
	        alert['max_alert_times']=format(params['max_alert_times'])
	        alert['remind_interval_second']=format(params['remind_interval_second'])
	        alert['mail']=format(params['mail'])
	        alert['sms']=format(params['sms'])
            if LogMonitorAlert.where(:raw_key=>alert['raw_key']).empty?
                    LogMonitorAlert.create(alert)
                    return {:rescode=>0,:raw_key=>alert['raw_key']}
            else
                    MyConfig.logger.warn("You have added the alarm")
                    return {:rescode=>-1,:msg=>"Error: You have added the alarm"}
            end
        end
        
        desc "del log monitor alert"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/del_alert' do
            raw_key=format(params['raw_key'])
            if LogMonitorAlert.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"Error: alert related to raw:#{raw_key} doesn't exist"}
            else
                LogMonitorAlert.where(:raw_key=>raw_key).destroy_all
                return {:rescode=>0,:msg=>"ok"}
            end
        end
        
        
        desc "update log monitor alert"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/update_alert' do 
            alert={}
            raw_key=format(params['raw_key'])
            if LogMonitorAlert.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"Error: alert related to raw:#{raw_key} doesn't exist"}
            end
	        alert['max_alert_times']=format(params['max_alert_times'])
	        alert['remind_interval_second']=format(params['remind_interval_second'])
	        alert['mail']=format(params['mail'])
	        alert['sms']=format(params['sms'])
            LogMonitorAlert.where(:raw_key=>raw_key).update_all(alert)
            return {:rescode=>0,:raw_key=>raw_key}
        end


        desc "get raw by app key"
        params do
            requires :app_key, type: String, desc: "app key"
        end
        get '/get_raw_by_app_key'  do 
            app_key=format(params['app_key'])
            if AppBns.where(:app_key=>app_key).empty?
                return {:rescode=>-1,:msg=>"app_key: #{app_key} doesn't exist"}
            else
                raws=get_raws(app_key)
                return {:rescode=>0,:raws=>raws}
            end
        end
        
        desc "get alert by raw key"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/get_alert_by_raw_key' do
            raw_key=format(params['raw_key'])
            unless LogMonitorAlert.where(:raw_key=>raw_key).empty?
                alert_info=get_alerts(raw_key)
                return {:rescode=>0,:alert=>alert_info}
            else
                return {:rescode=>-1,:msg=>"alert related to raw_key #{raw_key} doesn't exist"}
            end
        end
        
        desc "get item by raw key"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/get_item_by_raw_key' do
            raw_key=format(params['raw_key'])
            if LogMonitorItem.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"items related to raw_key #{raw_key} doesn't exist"}
            else
                items=get_items(raw_key)
                return {:rescode=>0,:items=>items}
            end
        end
        
        desc "get_rules_by_item_key"
        params do
            requires :item_key, type: String, desc: "item key"
        end
        get '/get_rules_by_item_key' do
            item_key=format(params['item_key'])
            unless LogMonitorRule.where(:item_key=>item_key).empty?
                return {:rescode=>-1,:msg=>"rules related to item_key #{item_key} doesn't exist"}
            else
                rules=get_rules(item_key)
                return {:rescode=>0,:rules=>rules}
            end
        end
        
        desc "get_log_monitor_by_app_key"
        params do
            requires :app_key, type: String, desc: "app key"
        end
        get '/get_log_monitor_by_app_key' do
            app_key=format(params['app_key'])
            if AppBns.where(:app_key=>app_key).empty?
                return {:rescode=>-1,:msg=>"app_key: #{app_key} doesn't exist"}
            else
                raws=get_raws(app_key)
                raws.each do |raw|
                    raw['items']=get_items(raw['raw_key'])
                    raw['items'].each do |item|
                        item['rules']=get_rules(item['item_key'])
                    end
                    raw['alert']=get_alerts(raw['raw_key'])
                end
                return {:rescode=>0,:raw=>raws}
            end
        end
    end
  end
end
