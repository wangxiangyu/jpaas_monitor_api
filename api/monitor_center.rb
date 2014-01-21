require "digest"
$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"

module Acme
  class MonitorCenter < Grape::API
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
    end
    get '/save_all' do
        app_key=format(params['app_key'])
	app_bns_info=AppBns.where(:app_key=>app_key)
	if app_bns_info.empty?
		result={:rescode=>-1,:msg=>"Error: this app doesn't exist"}
		return gen_response(params,result)
	else
	   app_bns=app_bns_info.first.name
	end
        #for log monitor
        log_monitor_check_result=Noah3.log_raw_completed?(app_key)
        unless log_monitor_check_result[:rescode]==0
            return gen_response(params,log_monitor_check_result)
        end
        #for user defined monitor
        user_defined_monitor_check_result=Noah3.user_defined_raw_completed?(app_key)
        unless user_defined_monitor_check_result[:rescode]==0
            return gen_response(params,user_defined_monitor_check_result)
        end
        #for proc defined monitor
        proc_monitor_check_result=Noah3.proc_raw_completed?(app_key)
        unless proc_monitor_check_result[:rescode]==0
            return gen_response(params,proc_monitor_check_result)
        end
        #generate config
        raw=[]
        rule=[]
        alert=[]
	    log_monitor_item={}
        #generate config for log monitor
        raw+=Noah3.gen_log_monitor_raw_config(app_key)
        log_monitor_item=Noah3.gen_log_monitor_item_config(app_key)
        rule+=Noah3.gen_log_monitor_rule_config(app_key)
        alert+=Noah3.gen_log_monitor_alert_config(app_key)

        #generate config for user defined monitor
        raw+=Noah3.gen_user_defined_monitor_raw_config(app_key)
        rule+=Noah3.gen_user_defined_monitor_rule_config(app_key)
        alert+=Noah3.gen_user_defined_monitor_alert_config(app_key)


        #generate config for proc  monitor
        raw+=Noah3.gen_proc_monitor_raw_config(app_key)
        rule+=Noah3.gen_proc_monitor_rule_config(app_key)
        alert+=Noah3.gen_proc_monitor_alert_config(app_key)

	#update config  for app
	Noah3.checkout_config(MyConfig.tmp_dir,MyConfig.svn_path,MyConfig.svn_user,MyConfig.svn_passwd)
	Noah3.init_config(app_bns,MyConfig.tmp_dir,MyConfig.svn_user,MyConfig.svn_passwd)
	Noah3.gen_config(app_bns,MyConfig.tmp_dir,raw,rule,alert,log_monitor_item)
	result=Noah3.commit_config(app_bns,MyConfig.tmp_dir,"update monitor for jpaas",MyConfig.svn_user,MyConfig.svn_passwd)
	if result[:rescode]==0
        update_config_result={:rescode=>0,:msg=>"ok"}
		gen_response(params,update_config_result)
	else
        update_config_result={:rescode=>-1,:msg=>result[:msg]}
		gen_response(params,update_config_result)
	end
    end

  end
end
