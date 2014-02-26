require "digest"
$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"
require "rack/contrib"

module Acme
  class ProcMonitor < Grape::API
    use Rack::JSONP
    format :json
    helpers do
        def format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
        def check_cycle?(cycle)
            cycles=['10','60','600','3600','21600','86400']
            cycles.include?(cycle.to_s)
        end
        def check_name?(name)
            name.to_s=~/^[_a-zA-Z0-9]+$/
        end
    end
    desc "add proc monitor raw"
    params do
        requires :app_key, type: String, desc: "app key"
        requires :name, type: String, desc: "bin name"
        requires :cycle, type: String, desc: "monitor cycle"
        requires :params, type: String, desc: "bin path"
    end
    get '/add_proc_monitor_raw' do
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
	        raw['raw_key']=Digest::MD5.hexdigest("#{raw['app_key']}#{raw['name']}proc_monitor")
            if ProcMonitorRaw.where(:raw_key=>raw['raw_key']).empty?
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
    get '/del_proc_monitor_raw' do
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
    get '/add_proc_monitor_rule' do
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
	        rule['rule_key']=Digest::MD5.hexdigest("#{rule['raw_key']}#{rule['name']}#{rule['monitor_item']}")
            if ProcMonitorRule.where(:rule_key=>rule['rule_key']).empty?
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
    get '/del_proc_monitor_rule' do
        rule_key=format(params['rule_key'])
        if ProcMonitorRule.where(:rule_key=>rule_key).empty?
            return {:rescode=>-1,:msg=>"Error: rule:#{rule_key} doesn't exist"}
        else
            ProcMonitorRule.where(:rule_key=>rule_key).destroy_all   
            return {:rescode=>0,:msg=>"ok"}
        end
    end

    desc "add_proc_monitor_alert"
    params do
        requires :raw_key, type: String, desc: "raw key"
        requires :max_alert_times, type: String, desc: "max alert times"
        requires :remind_interval_second, type: String, desc: "remind interval in seconds"
        requires :mail, type: String, desc: "mails of alarm receivers"
        requires :sms, type: String, desc: "phones of alarm receivers"
    end
    get '/add_proc_monitor_alert' do
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
    get '/del_proc_monitor_alert' do
        raw_key=format(params['raw_key'])
        if ProcMonitorAlert.where(:raw_key=>raw_key).empty?
            return {:rescode=>-1,:msg=>"Error: alert related to raw:#{raw_key} doesn't exist"}
        else
            ProcMonitorAlert.where(:raw_key=>raw_key).destroy_all
            return {:rescode=>0,:msg=>"ok"}
        end
    end
  end
end
