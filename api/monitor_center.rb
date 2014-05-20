require "digest"
$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"
require "rack/contrib"

module Acme
  class MonitorCenter < Grape::API
    use Rack::JSONP
    format :json
    helpers do
        def format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
    end
    after do
        ActiveRecord::Base.clear_active_connections!
    end
    desc "monitor configration take effect for a specific app"
    params do
        requires :app_key, type: String, desc: "app key"
    end
    get '/take_effect' do
        app_key=format(params['app_key'])
	    app_bns_info=AppBns.where(:app_key=>app_key)
	    if app_bns_info.empty?
		    return {:rescode=>-1,:msg=>"Error: this app doesn't exist"}
	    else
	        app_bns=app_bns_info.first.name
	    end
        #for log monitor
        log_monitor_check_result=Noah3.log_raw_completed?(app_key)
        unless log_monitor_check_result[:rescode]==0
            return log_monitor_check_result
        end
        #for user defined monitor
        user_defined_monitor_check_result=Noah3.user_defined_raw_completed?(app_key)
        unless user_defined_monitor_check_result[:rescode]==0
            return user_defined_monitor_check_result
        end

        #for http user defined monitor
        http_user_defined_monitor_check_result=Noah3.http_user_defined_raw_completed?(app_key)
        unless http_user_defined_monitor_check_result[:rescode]==0
            return http_user_defined_monitor_check_result
        end

        #for proc defined monitor
        proc_monitor_check_result=Noah3.proc_raw_completed?(app_key)
        unless proc_monitor_check_result[:rescode]==0
            return proc_monitor_check_result
        end
        #for domain monitor    
        domain_monitor_check_result=Noah3.domain_raw_completed?(app_key)
        unless domain_monitor_check_result[:rescode]==0
            return domain_monitor_check_result
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

        #generate config for http user defined monitor
        raw+=Noah3.gen_http_user_defined_monitor_raw_config(app_key)
        rule+=Noah3.gen_http_user_defined_monitor_rule_config(app_key)
        alert+=Noah3.gen_http_user_defined_monitor_alert_config(app_key)

        #generate config for proc  monitor
        raw+=Noah3.gen_proc_monitor_raw_config(app_key)
        rule+=Noah3.gen_proc_monitor_rule_config(app_key)
        alert+=Noah3.gen_proc_monitor_alert_config(app_key)

        #generate config for domain monitor
        domain_monitor_config=Noah3.gen_domain_monitor_config(app_key)

	    Noah3.checkout_config(MyConfig.tmp_dir,MyConfig.svn_path,MyConfig.svn_user,MyConfig.svn_passwd)

	    #update service config  for app
	    Noah3.init_config_service(app_bns,"#{MyConfig.tmp_dir}/service",MyConfig.svn_user,MyConfig.svn_passwd)
	    Noah3.gen_config_service(app_bns,"#{MyConfig.tmp_dir}/service",raw,rule,alert,log_monitor_item)

        #update domain config for app
	    Noah3.init_config_domain(domain_monitor_config,"#{MyConfig.tmp_dir}/domain",MyConfig.svn_user,MyConfig.svn_passwd)
	    Noah3.gen_config_domain("#{MyConfig.tmp_dir}/domain",domain_monitor_config)

	    result=Noah3.commit_config(MyConfig.tmp_dir,"update monitor for jpaas",MyConfig.svn_user,MyConfig.svn_passwd)
	    if result[:rescode]==0
            return {:rescode=>0,:msg=>"ok"}
	    else
            return {:rescode=>-1,:msg=>result[:msg]}
	    end
    end
  end
end
