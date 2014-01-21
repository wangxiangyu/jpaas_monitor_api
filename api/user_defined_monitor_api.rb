require "digest"
$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"

module Acme
  class UserDefinedMonitor < Grape::API
    format :txt
    helpers do
        def format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
        def gen_response(params={},result={})
            callback=format(params['callback'])
            if callback.empty?
                    result.to_json
            else
                    callback.to_s+"("+result.to_json+")"
            end
        end
        def check_cycle?(cycle)
            cycles=['10','60','600','3600','21600','86400']
            cycles.include?(cycle.to_s)
        end
        def check_name?(name)
            name.to_s=~/^[_a-zA-Z0-9]+$/
        end
    end
    desc "add user defined monitor raw"
    get '/add_user_defined_monitor_raw' do
            raw={}
	        raw['app_key']=format(params['app_key'])
            if AppBns.where(:app_key=>raw['app_key']).empty?
                result={:rescode=>-1,:msg=>"Error: app_key:#{raw['app_key']} doesn't exist"}
                return gen_response(params,result)
            end
	        raw['name']=format(params['name'])
            unless check_name?(raw['name'])
                result={:rescode=>-1,:msg=>"Error: name must be consist of number,letter or _"}
                return gen_response(params,result)
            end
	        raw['cycle']=format(params['cycle'])
            unless check_cycle?(raw['cycle'])   
                result={:rescode=>-1,:msg=>"Error: cycle must be in '10','60','600','3600','21600','86400'"}
                return gen_response(params,result)
            end
	        raw['method']='exec'
	        raw['target']=format(params['target'])
	        raw['raw_key']=Digest::MD5.hexdigest("#{raw['app_key']}#{raw['name']}user_defined_monitor")
            if UserDefinedMonitorRaw.where(:raw_key=>raw['raw_key']).empty?
                    UserDefinedMonitorRaw.create(raw)
                    result={:rescode=>0,:raw_key=>raw['raw_key']}
                    return gen_response(params,result)
            else
                    result={:rescode=>-1,:msg=>"Error: You have added the same log raw"}
                    return gen_response(params,result)
            end
    end
    
    get '/del_user_defined_monitor_raw' do
        raw_key=format(params['raw_key'])
        if UserDefinedMonitorRaw.where(:raw_key=>raw_key).empty?
            result={:rescode=>-1,:msg=>"Error: raw:#{raw_key} doesn't exist"}
            return gen_response(params,result)
        else
            if UserDefinedMonitorRule.where(:raw_key=>raw_key).empty? 
                UserDefinedMonitorRaw.where(:raw_key=>raw_key).destroy_all   
                UserDefinedMonitorAlert.where(:raw_key=>raw_key).destroy_all   
                result={:rescode=>0,:msg=>"ok"}
                return gen_response(params,result)
            else
                result={:rescode=>-1,:msg=>"Error: please delete rules related to this raw first"}
                return gen_response(params,result)
            end
        end
    end

    get '/add_user_defined_monitor_rule' do
        raw_key=format(params['raw_key'])
        if UserDefinedMonitorRaw.where(:raw_key=>raw_key).empty?
            result={:rescode=>-1,:msg=>"Error: raw:#{raw_key} doesn't exist"}
            return gen_response(params,result)
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
            if UserDefinedMonitorRule.where(:rule_key=>rule['rule_key']).empty?
                    UserDefinedMonitorRule.create(rule)
                    result={:rescode=>0,:rule_key=>rule['rule_key']}
                    return gen_response(params,result)
            else
                    result={:rescode=>-1,:msg=>"Error: You have added the same  rule"}
                    return gen_response(params,result)
            end
        end
    end

    get '/del_user_defined_monitor_rule' do
        rule_key=format(params['rule_key'])
        if UserDefinedMonitorRule.where(:rule_key=>rule_key).empty?
            result={:rescode=>-1,:msg=>"Error: rule:#{rule_key} doesn't exist"}
            return gen_response(params,result)
        else
            UserDefinedMonitorRule.where(:rule_key=>rule_key).destroy_all   
            result={:rescode=>0,:msg=>"ok"}
            return gen_response(params,result)
        end
    end

    get '/add_user_defined_monitor_alert' do
            alert={}
	    alert['raw_key']=format(params['raw_key'])
            if UserDefinedMonitorRaw.where(:raw_key=>alert['raw_key']).empty?
                result={:rescode=>-1,:msg=>"Error: raw_key:#{alert['raw_key']} doesn't exist"}
                return gen_response(params,result)
            end
	        alert['name']="alert_"+alert['raw_key']
	        alert['max_alert_times']=format(params['max_alert_times'])
	        alert['remind_interval_second']=format(params['remind_interval_second'])
	        alert['mail']=format(params['mail'])
	        alert['sms']=format(params['sms'])
            if UserDefinedMonitorAlert.where(:raw_key=>alert['raw_key']).empty?
                    UserDefinedMonitorAlert.create(alert)
                    result={:rescode=>0,:raw_key=>alert['raw_key']}
                    return gen_response(params,result)
            else
                    result={:rescode=>-1,:msg=>"Error: You have added the alarm"}
                    return gen_response(params,result)
            end
    end

    get '/del_user_defined_monitor_alert' do
        raw_key=format(params['raw_key'])
        if UserDefinedMonitorAlert.where(:raw_key=>raw_key).empty?
            result={:rescode=>-1,:msg=>"Error: alert related to raw:#{raw_key} doesn't exist"}
            return gen_response(params,result)
        else
            UserDefinedMonitorAlert.where(:raw_key=>raw_key).destroy_all
            result={:rescode=>0,:msg=>"ok"}
            return gen_response(params,result)
        end
    end
  end
end
