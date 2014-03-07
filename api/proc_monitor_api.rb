require "digest"
$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"
require "rack/contrib"
require "securerandom"

module Acme
  class ProcMonitor < Grape::API
    use Rack::JSONP
    format :json
    helpers do
        def format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
        def get_random_hash
            SecureRandom.hex 16
        end
        def get_raws(app_key)
            raws=[]
            unless ProcMonitorRaw.where(:app_key=>app_key).empty?
                ProcMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                    raw_hash=raw.serializable_hash
                    raw_hash.delete('id')
                    raw_hash.delete('cycle')
                    raw_hash.delete('method')
                    raw_hash.delete('target')
                    raw_hash.delete('updated_at')
                    raw_hash.delete('created_at')
                    raws.push(raw_hash)
                end
            end
            raws
        end
        def get_alerts(raw_key)
            alert_info={}
            unless ProcMonitorAlert.where(:raw_key=>raw_key).empty?
                alert_info=ProcMonitorAlert.where(:raw_key=>raw_key).first.serializable_hash
                alert_info.delete('id')
                alert_info.delete('raw_key')
                alert_info.delete('name')
                alert_info.delete('created_at')
                alert_info.delete('updated_at')
            end
            alert_info
        end
        def get_rules(raw_key)
            rules=[]
            unless ProcMonitorRule.where(:raw_key=>raw_key).empty?
                ProcMonitorRule.where(:raw_key=>raw_key).find_each do |rule|
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
    end
    namespace :proc_monitor do
        after do
            ActiveRecord::Base.clear_active_connections!
        end
        desc "add proc monitor raw"
        params do
            requires :app_key, type: String, desc: "app key"
            requires :name, type: String, desc: "bin name"
            requires :cycle, type: String, desc: "monitor cycle"
            requires :params, type: String, desc: "bin path"
        end
        get '/add_raw' do
            raw={}
	        raw['app_key']=format(params['app_key'])
            if AppBns.where(:app_key=>raw['app_key']).empty?
                return {:rescode=>-1,:msg=>"Error: app_key:#{raw['app_key']} doesn't exist"}
            end
	        raw['name']=format(params['name'])
	        raw['cycle']=format(params['cycle'])
	        raw['method']='noah'
	        raw['target']='procmon'
	        raw['params']=format(params['params'])
	        raw['raw_key']=get_random_hash
            if ProcMonitorRaw.where(:app_key=>raw['app_key'],:name=>raw['name']).empty?
                    ProcMonitorRaw.create(raw)
                    return {:rescode=>0,:raw_key=>raw['raw_key']}
            else
                    return {:rescode=>-1,:msg=>"Error: You have added the same log raw"}
            end
        end
    
        desc "del proc monitor raw"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/del_raw' do
            raw_key=format(params['raw_key'])
            if ProcMonitorRaw.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"Error: raw:#{raw_key} doesn't exist"}
            else
                if ProcMonitorRule.where(:raw_key=>raw_key).empty? 
                    ProcMonitorRaw.where(:raw_key=>raw_key).destroy_all   
                    ProcMonitorAlert.where(:raw_key=>raw_key).destroy_all   
                    return {:rescode=>0,:msg=>"ok"}
                else
                    return {:rescode=>-1,:msg=>"Error: please delete rules related to this raw first"}
                end
            end
        end

        desc "update proc monitor raw"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/update_raw' do
            raw={}
            raw_key=format(params['raw_key'])
            if ProcMonitorRaw.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"Error: raw:#{raw_key} doesn't exist"}
            end
	        raw['name']=format(params['name'])
	        raw['cycle']=format(params['cycle'])
	        raw['params']=format(params['params'])
            ProcMonitorRaw.where(:raw_key=>raw_ke).update_attribute(raw)
            return {:rescode=>0,:raw_key=>raw_key}
        end

        desc "add proc monitor rule"
        params do
            requires :raw_key, type: String, desc: "raw key"
            requires :name, type: String, desc: "rule name"
            requires :monitor_item, type: String, desc: "monitor_item"
            requires :compare, type: String, desc: "compare conditions: eg < <= !=...."
            requires :threshold, type: String, desc: "threshold"
            requires :filter, type: String, desc: "setting for alarm strategy"
            requires :disable_time, type: String, desc: "disable time in one day"
        end
        get '/add_rule' do
            raw_key=format(params['raw_key'])
            if ProcMonitorRaw.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"Error: raw:#{raw_key} doesn't exist"}
            else
                rule={}
                rule['raw_key']=raw_key
	            rule['name']=format(params['name'])
	            rule['monitor_item']=format(params['monitor_item'])
	            rule['compare']=format(params['compare'])
	            rule['threshold']=format(params['threshold'])
	            rule['filter']=format(params['filter'])
	            rule['alert']="alert_"+raw_key
	            rule['disable_time']=format(params['disable_time'])
	            rule['rule_key']=get_random_hash
                if ProcMonitorRule.where(:rule_key=>rule['rule_key'],:name=>rule['name'],:monitor_item=>rule['monitor_item']).empty?
                    ProcMonitorRule.create(rule)
                    return {:rescode=>0,:rule_key=>rule['rule_key']}
                else
                    return {:rescode=>-1,:msg=>"Error: You have added the same  rule"}
                end
            end
        end

        desc "del proc monitor rule"
        params do
            requires :rule_key, type: String, desc: "rule key"
        end
        get '/del_rule' do
            rule_key=format(params['rule_key'])
            if ProcMonitorRule.where(:rule_key=>rule_key).empty?
                return {:rescode=>-1,:msg=>"Error: rule:#{rule_key} doesn't exist"}
            else
                ProcMonitorRule.where(:rule_key=>rule_key).destroy_all   
                return {:rescode=>0,:msg=>"ok"}
            end
        end

        desc "update proc monitor rule"
        params do
            requires :rule_key, type: String, desc: "rule key"
        end
        get '/update_rule' do
            rule={}
            rule_key=format(params['rule_key'])
            if ProcMonitorRule.where(:rule_key=>rule_key).empty?
                return {:rescode=>-1,:msg=>"Error: rule:#{rule_key} doesn't exist"}
            end
	        rule['name']=format(params['name'])
	        rule['monitor_item']=format(params['monitor_item'])
	        rule['compare']=format(params['compare'])
	        rule['threshold']=format(params['threshold'])
	        rule['filter']=format(params['filter'])
	        rule['disable_time']=format(params['disable_time'])
            ProcMonitorRule.where(:rule_key=>rule_key).update_attribute(rule)
            return {:rescode=>0,:rule_key=>rule_key}
        end

        desc "add_proc_monitor_alert"
        params do
            requires :raw_key, type: String, desc: "raw key"
            requires :max_alert_times, type: String, desc: "max alert times"
            requires :remind_interval_second, type: String, desc: "remind interval in seconds"
            requires :mail, type: String, desc: "mails of alarm receivers"
            requires :sms, type: String, desc: "phones of alarm receivers"
        end
        get '/add_alert' do
            alert={}
	        alert['raw_key']=format(params['raw_key'])
            if ProcMonitorRaw.where(:raw_key=>alert['raw_key']).empty?
                return {:rescode=>-1,:msg=>"Error: raw_key:#{alert['raw_key']} doesn't exist"}
            end
	        alert['name']="alert_"+alert['raw_key']
	        alert['max_alert_times']=format(params['max_alert_times'])
	        alert['remind_interval_second']=format(params['remind_interval_second'])
	        alert['mail']=format(params['mail'])
	        alert['sms']=format(params['sms'])
            if ProcMonitorAlert.where(:raw_key=>alert['raw_key']).empty?
                    ProcMonitorAlert.create(alert)
                    return {:rescode=>0,:raw_key=>alert['raw_key']}
            else
                    return {:rescode=>-1,:msg=>"Error: You have added the alarm"}
            end
        end

        desc "del proc monitor alert"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/del_alert' do
            raw_key=format(params['raw_key'])
            if ProcMonitorAlert.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"Error: alert related to raw:#{raw_key} doesn't exist"}
            else
                ProcMonitorAlert.where(:raw_key=>raw_key).destroy_all
                return {:rescode=>0,:msg=>"ok"}
            end
        end

        desc "update proc monitor alert"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/update_alert' do
            alert={}
            raw_key=format(params['raw_key'])
            if ProcMonitorAlert.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"Error: alert related to raw:#{raw_key} doesn't exist"}
            end
	        alert['max_alert_times']=format(params['max_alert_times'])
	        alert['remind_interval_second']=format(params['remind_interval_second'])
	        alert['mail']=format(params['mail'])
	        alert['sms']=format(params['sms'])
            ProcMonitorAlert.where(:raw_key=>raw_key).update_attribute(alert)
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
            unless ProcMonitorAlert.where(:raw_key=>raw_key).empty?
                alert_info=get_alerts(raw_key)
                return {:rescode=>0,:alert=>alert_info}
            else
                return {:rescode=>-1,:msg=>"alert related to raw_key #{raw_key} doesn't exist"}
            end
        end

        desc "get_rules_by_raw_key"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/get_rules_by_raw_key' do
            raw_key=format(params['raw_key'])
            rules=[]
            unless ProcMonitorRule.where(:raw_key=>raw_key).empty?
                rules=get_rules(raw_key)
                return {:rescode=>0,:rules=>rules}
            else
                return {:rescode=>-1,:msg=>"rule related to raw_key #{raw_key} doesn't exist"}
            end
        end

        params do
            requires :app_key, type: String, desc: "app key"
        end
        get '/get_proc_monitor_by_app_key' do
            app_key=format(params['app_key'])
            if AppBns.where(:app_key=>app_key).empty?
                return {:rescode=>-1,:msg=>"app_key: #{app_key} doesn't exist"}
            else
                raws=get_raws(app_key)
                raws.each do |raw|
                    raw['alert']=get_alerts(raw['raw_key'])
                    raw['rules']=get_rules(raw['raw_key'])
                end
                return {:rescode=>0,:raws=>raws}
            end
        end
    end
  end
end
