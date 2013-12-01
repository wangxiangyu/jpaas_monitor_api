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
    end
    desc "add log monitor raw"
    get '/add_log_monitor_raw' do
            raw={}
	        raw['app_key']=format(params['app_key'])
	        raw['name']=format(params['name'])
	        raw['cycle']='60'
	        raw['method']='noah'
	        raw['target']='logmon'
	        raw['log_filepath']="${DEPLOY_DIR}/"+format(params['log_filepath']).gsub(/^\//,"")
	        raw['raw_key']=Digest::MD5.hexdigest("#{raw['app_key']}#{raw['name']}#{raw['log_filepath']}")
	        raw['limit_rate']='10'
            log_name="#{raw['app_key']}_#{raw['name']}.conf"
            raw['params']="${ATTACHMENT_DIR}/#{log_name}"
            if LogMonitorRaw.where(:raw_key=>raw['raw_key']).empty?
                    LogMonitorRaw.create(raw)
                    raw['raw_key']
            else
                  #  MyConfig.logger.warn("You have added the same log raw")
                    "Error: You have added the same log raw"
            end
    end
    get '/add_log_monitor_item' do
            item={}
	        item['raw_key']=format(params['raw_key'])
	        item['item_name_prefix']=format(params['name'])
	        item['cycle']=format(params['cycle'])
	        item['match_str']=format(params['match_str'])
	        item['item_key']=Digest::MD5.hexdigest("#{item['raw_key']}#{item['item_name_prefix']}#{item['match_str']}")
            if LogMonitorItem.where(:item_key=>item['item_key']).empty?
                    LogMonitorItem.create(item)
                    item['item_key']
            else
                  #  MyConfig.logger.warn("You have added the same log item")
                    "Error: You have added the same log item"
            end
    end
    get '/add_log_monitor_rule' do
            rule={}
	        rule['item_key']=format(params['item_key'])
	        rule['name']=format(params['name'])
	        rule['formula']=format(params['formula'])
	        rule['filter']=format(params['filter'])
	        rule['alert']="alert_"+get_raw_key_by_rule_key(rule['item_key'])
	        rule['disable_time']=format(params['disable_time'])
	        rule['rule_key']=Digest::MD5.hexdigest("#{rule['item_key']}#{rule['name']}")
            if LogMonitorRule.where(:rule_key=>rule['rule_key']).empty?
                    LogMonitorRule.create(rule)
                    rule['rule_key']
            else
                  #  MyConfig.logger.warn("You have added the same log rule ")
                    "Error: You have added the same log rule"
            end
    end
    get '/add_monitor_alert' do
            alert={}
	        alert['raw_key']=format(params['raw_key'])
	        alert['name']="alert_"+format(params['raw_key'])
	        alert['max_alert_times']=format(params['max_alert_times'])
	        alert['remind_interval_second']=format(params['remind_interval_second'])
	        alert['mail']=format(params['mail'])
	        alert['sms']=format(params['sms'])
            if MonitorAlert.where(:raw_key=>alert['raw_key']).empty?
                    MonitorAlert.create(alert)
            else
               #     MyConfig.logger.warn("You have added the alarm")
                    "Error: You have added the alarm"
            end
    end
    get '/monitor_take_effect' do
            Noah3.checkout_config("/home/work/dashboard/jpaas_monitor_api/lib/noah3.0/tmp","http://svn.noah.baidu.com/svn/conf/online/JPaaS/service","wangxiangyu","wangxiangyu")
            Noah3.gen_log_config("/home/work/dashboard/jpaas_monitor_api/lib/noah3.0/tmp")
            Noah3.commit_config("/home/work/dashboard/jpaas_monitor_api/lib/noah3.0/tmp","update monitor for jpaas","wangxiangyu","wangxiangyu")
    end
  end
end
