require "digest"
$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"

module Acme
  class LogMonitor < Grape::API
    format :txt
    helpers do
        def get_raw_key_by_rule_key(item_key)
                raw_key=LogMonitorItem.where(:item_key=>item_key).first.raw_key
        end
        def format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
        def monitor_take_effect
            Noah3.checkout_config(MyConfig.tmp_dir,MyConfig.svn_path,MyConfig.svn_user,MyConfig.svn_passwd)
            Noah3.gen_log_config(MyConfig.tmp_dir)
            Noah3.commit_config(MyConfig.tmp_dir,"update monitor for jpaas",MyConfig.svn_user,MyConfig.svn_passwd)
        end
        def gen_response(params={},result={})
            callback=format(params['callback'])
            if callback.empty?
                    result.to_json
            else
                    callback.to_s+"("+result.to_json+")"
            end
        end
        def check_raw_duplicate?(app_key,raw)
            return false unless LogMonitorRaw.where(:app_key=>app_key,:name=>raw).empty?
            return false unless UserDefinedMonitorRaw.where(:app_key=>app_key,:name=>raw).empty?
            return true
        end
    end
    desc "add log monitor raw"
    get '/add_log_monitor_raw' do
            raw={}
	        raw['app_key']=format(params['app_key'])
            if AppBns.where(:app_key=>raw['app_key']).empty?
                result={:rescode=>-1,:msg=>"Error: app_key:#{raw['app_key']} doesn't exist"}
                return gen_response(params,result)
            end
	        raw['name']=format(params['name'])
	        raw['cycle']='60'
	        raw['method']='noah'
	        raw['target']='logmon'
	        raw['log_filepath']=format(params['log_filepath'])
	        raw['raw_key']=Digest::MD5.hexdigest("#{raw['app_key']}#{raw['name']}log_monitor")
	        raw['limit_rate']='10'
            log_name="#{raw['app_key']}_#{raw['name']}.conf"
            raw['params']="${ATTACHMENT_DIR}/#{log_name}"
            if LogMonitorRaw.where(:raw_key=>raw['raw_key']).empty?
                    LogMonitorRaw.create(raw)
                    result={:rescode=>0,:raw_key=>raw['raw_key']}
                    return gen_response(params,result)
            else
                    MyConfig.logger.warn("You have added the same log raw")
                    result={:rescode=>-1,:msg=>"Error: You have added the same log raw"}
                    return gen_response(params,result)
            end
    end
    
    get '/del_log_monitor_raw' do
        raw_key=format(params['raw_key'])
        if LogMonitorRaw.where(:raw_key=>raw_key).empty?
            result={:rescode=>-1,:msg=>"Error: raw:#{raw_key} doesn't exist"}
            return gen_response(params,result)
        else
            if LogMonitorItem.where(:raw_key=>raw_key).empty? 
                LogMonitorRaw.where(:raw_key=>raw_key).destroy_all   
                LogMonitorAlert.where(:raw_key=>raw_key).destroy_all   
                result={:rescode=>0,:msg=>"ok"}
                return gen_response(params,result)
            else
                result={:rescode=>-1,:msg=>"Error: please delete items related to this raw first"}
                return gen_response(params,result)
            end
        end
    end

    get '/add_log_monitor_item' do
            item={}
	        item['raw_key']=format(params['raw_key'])
            if LogMonitorRaw.where(:raw_key=>item['raw_key']).empty?
                result={:rescode=>-1,:msg=>"Error: raw_key:#{item['raw_key']} doesn't exist"}
                return gen_response(params,result)
            end
	        item['item_name_prefix']=format(params['name'])
	        item['cycle']=format(params['cycle'])
	        item['match_str']=format(params['match_str'])
	        item['item_key']=Digest::MD5.hexdigest("#{item['raw_key']}#{item['item_name_prefix']}")
            if LogMonitorItem.where(:item_key=>item['item_key']).empty?
                    LogMonitorItem.create(item)
                    result={:rescode=>0,:item_key=>item['item_key']}
                    return gen_response(params,result)
            else
                    MyConfig.logger.warn("You have added the same log item")
                    result={:rescode=>-1,:msg=>"Error: You have added the same log item"}
                    return gen_response(params,result)
            end
    end

    
    get '/del_log_monitor_item' do
        item_key=format(params['item_key'])
        if LogMonitorItem.where(:item_key=>item_key).empty?
            result={:rescode=>-1,:msg=>"Error: item:#{item_key} doesn't exist"}
            return gen_response(params,result)
        else
            if LogMonitorRule.where(:item_key=>item_key).empty? 
                LogMonitorItem.where(:item_key=>item_key).destroy_all   
                result={:rescode=>0,:msg=>"ok"}
                return gen_response(params,result)
            else
                result={:rescode=>-1,:msg=>"Error: please delete rules related to this item first"}
                return gen_response(params,result)
            end
        end
    end



    get '/add_log_monitor_rule' do
            rule={}
	        rule['item_key']=format(params['item_key'])
            if LogMonitorItem.where(:item_key=>rule['item_key']).empty?
                result={:rescode=>-1,:msg=>"Error: item_key:#{rule['item_key']} doesn't exist"}
                return gen_response(params,result)
            end
	        rule['name']=format(params['name'])
	        rule['compare']=format(params['compare'])
	        rule['threshold']=format(params['threshold'])
	        rule['filter']=format(params['filter'])
	        rule['alert']="alert_"+get_raw_key_by_rule_key(rule['item_key'])
	        rule['disable_time']=format(params['disable_time'])
	        rule['rule_key']=Digest::MD5.hexdigest("#{rule['item_key']}#{rule['name']}")
            if LogMonitorRule.where(:rule_key=>rule['rule_key']).empty?
                    LogMonitorRule.create(rule)
                    result={:rescode=>0,:rule_key=>rule['rule_key']}
                    return gen_response(params,result)
            else
                    MyConfig.logger.warn("You have added the same log rule ")
                    result={:rescode=>-1,:msg=>"Error: You have added the same log rule"}
                    return gen_response(params,result)
            end
    end

    get '/del_log_monitor_rule' do
        rule_key=format(params['rule_key'])
        if LogMonitorRule.where(:rule_key=>rule_key).empty?
            result={:rescode=>-1,:msg=>"Error: rule:#{rule_key} doesn't exist"}
            return gen_response(params,result)
        else
            LogMonitorRule.where(:rule_key=>rule_key).destroy_all   
            result={:rescode=>0,:msg=>"ok"}
            return gen_response(params,result)
        end
    end

    get '/add_log_monitor_alert' do
            alert={}
	        alert['raw_key']=format(params['raw_key'])
            if LogMonitorRaw.where(:raw_key=>alert['raw_key']).empty?
                result={:rescode=>-1,:msg=>"Error: raw_key:#{alert['raw_key']} doesn't exist"}
                return gen_response(params,result)
            end
	        alert['name']="alert_"+format(params['raw_key'])
	        alert['max_alert_times']=format(params['max_alert_times'])
	        alert['remind_interval_second']=format(params['remind_interval_second'])
	        alert['mail']=format(params['mail'])
	        alert['sms']=format(params['sms'])
            if LogMonitorAlert.where(:raw_key=>alert['raw_key']).empty?
                    LogMonitorAlert.create(alert)
                    result={:rescode=>0,:raw_key=>alert['raw_key']}
                    return gen_response(params,result)
            else
                    MyConfig.logger.warn("You have added the alarm")
                    result={:rescode=>-1,:msg=>"Error: You have added the alarm"}
                    return gen_response(params,result)
            end
    end

    get '/del_log_monitor_alert' do
        raw_key=format(params['raw_key'])
        if LogMonitorAlert.where(:raw_key=>raw_key).empty?
            result={:rescode=>-1,:msg=>"Error: alert related to raw:#{raw_key} doesn't exist"}
            return gen_response(params,result)
        else
            LogMonitorAlert.where(:raw_key=>raw_key).destroy_all
            result={:rescode=>0,:msg=>"ok"}
            return gen_response(params,result)
        end
    end

    get '/save_all_log' do
        raw_key=format(params['raw_key'])
        check_result=Noah3.log_raw_completed?(raw_key)
        if check_result[:rescode]==0
            out=monitor_take_effect
            if out==true
                result={:rescode=>0,:msg=>"ok"}
                return gen_response(params,result)
            else
                result={:rescode=>-1,:msg=>"hoho,,,,failed,please contact op: detail #{out}"}
                return gen_response(params,result)
            end
        else
            return gen_response(params,check_result)
        end
    end

    get '/get_raw_by_app_key'  do 
        app_key=format(params['app_key'])
        if AppBns.where(:app_key=>app_key).empty?
            result={:rescode=>-1,:msg=>"app_key: #{app_key} doesn't exist"}
            return gen_response(params,result)
        else
            raws=[]
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
                unless LogMonitorAlert.where(:raw_key=>raw_hash['raw_key']).empty?
                    alert_info=LogMonitorAlert.where(:raw_key=>raw_hash['raw_key']).first.serializable_hash
                    alert_info.delete('id')
                    alert_info.delete('raw_key')
                    alert_info.delete('name')
                    alert_info.delete('created_at')
                    alert_info.delete('updated_at')
                    raw_hash.merge!(alert_info)
                end
                raws.push(raw_hash)
            end
            result={:rescode=>0,:raws=>raws}
            return gen_response(params,result)
        end
    end

    get '/get_alert_by_raw_key' do
        raw_key=format(params['raw_key'])
        unless LogMonitorAlert.where(:raw_key=>raw_key).empty?
            alert_info=LogMonitorAlert.where(:raw_key=>raw_key).first.serializable_hash
            alert_info.delete('id')
            alert_info.delete('raw_key')
            alert_info.delete('name')
            alert_info.delete('created_at')
            alert_info.delete('updated_at')
            result={:rescode=>0,:alert=>alert_info}
            return gen_response(params,result)
        else
            result={:rescode=>-1,:msg=>"alert related to raw_key #{raw_key} doesn't exist"}
            return gen_response(params,result)
        end
    end

    get '/get_item_by_raw_key' do
        raw_key=format(params['raw_key'])
        items=[]
        LogMonitorItem.where(:raw_key=>raw_key).find_each do |item|
            item_hash=item.serializable_hash
            item_hash.delete('id')
            item_hash.delete('threshold')
            item_hash.delete('created_at')
            item_hash.delete('updated_at')
            items.push(item_hash)
        end
        result={:rescode=>0,:items=>items}
        return gen_response(params,result)
    end

    get '/get_rules_by_item_key' do
        item_key=format(params['item_key'])
        rules=[]
        LogMonitorRule.where(:item_key=>item_key).find_each do |rule|       
            rule_hash=rule.serializable_hash
            rule_hash.delete('id')
            rule_hash.delete('created_at')
            rule_hash.delete('updated_at')
            rule_hash.delete('alert')
            rules.push(rule_hash)
        end
        result={:rescode=>0,:rules=>rules}
        return gen_response(params,result)
    end
    get '/get_log_monitor_by_raw_key' do
        raw_key=format(params['raw_key'])
        if LogMonitorRaw.where(:raw_key=>raw_key).empty?
            result={:rescode=>-1,:msg=>"raw_key: #{raw_key} doesn't exist"}
            return gen_response(params,result)
        else
            raw_hash=LogMonitorRaw.where(:raw_key=>raw_key).first.serializable_hash
            raw_hash.delete('id')
            raw_hash.delete('cycle')
            raw_hash.delete('method')
            raw_hash.delete('target')
            raw_hash.delete('params')
            raw_hash.delete('limit_rate')
            raw_hash.delete('updated_at')
            raw_hash.delete('created_at')
            raw_hash['items']=[]
            raw_hash['alert']={}
            LogMonitorAlert.where(:raw_key=>raw_key).find_each do |alert|
                alert_info=alert.serializable_hash
                alert_info.delete('id')
                alert_info.delete('raw_key')
                alert_info.delete('name')
                alert_info.delete('created_at')
                alert_info.delete('updated_at')
                raw_hash['alert']=alert_info
            end
            LogMonitorItem.where(:raw_key=>raw_key).find_each do |item|
                item_hash=item.serializable_hash
                item_hash.delete('id')
                item_hash.delete('threshold')
                item_hash.delete('created_at')
                item_hash.delete('updated_at')
                item_hash.delete('filter_str')
                item_hash['rules']=[]
                LogMonitorRule.where(:item_key=>item.item_key).find_each do |rule|
                    rule_hash=rule.serializable_hash
                    rule_hash.delete('id')
                    rule_hash.delete('created_at')
                    rule_hash.delete('updated_at')
                    rule_hash.delete('alert')
                    item_hash['rules'].push(rule_hash)
                end
               raw_hash['items'].push(item_hash)
            end
            result={:rescode=>0,:raw=>raw_hash}
            return gen_response(params,result)
        end
    end
  end
end
