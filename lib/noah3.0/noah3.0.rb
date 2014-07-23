require "active_record"
$:.unshift(File.expand_path("../", File.dirname(__FILE__)))
require "mysvn"
require "database"
class Noah3
    class << self
        def checkout_config(work_path,svn_path,username,password)
            `rm -rf #{work_path} && mkdir -p #{work_path} && cd #{work_path}`
             Svn.checkout(svn_path,work_path,username,password)
        end

        def init_config_service(app_bns,work_path,username,password)
		    `mkdir -p #{work_path}/#{app_bns}`
             Svn.add_all("#{work_path}")
             Svn.del_all("#{work_path}/#{app_bns}")
             #Svn.commit(work_path,"delete",username,password)
        end
        
        def init_config_domain(domain_monitor_config,work_path,username,password)
             domain_monitor_config.each do |raw|
		        `mkdir -p #{work_path}/#{raw['domain']}`
                Svn.add_all("#{work_path}")
                Svn.del_all("#{work_path}/#{raw['domain']}")
             end
             #Svn.commit(work_path,"delete",username,password)
        end

        def commit_config(work_path,message,username,password)
            Svn.commit(work_path,message,username,password)
        end
        
        def log_raw_completed?(app_key) 
            LogMonitorRaw.where(:app_key=>app_key).find_each do  |raw|
                 if LogMonitorAlert.where(:raw_key=>raw.raw_key).empty?
                    return {:rescode=>-1,:msg=>"raw:#{raw.name} doesn't have any alert settings"}
                 end
                 if LogMonitorItem.where(:raw_key=>raw.raw_key).empty?
                    return {:rescode=>-1,:msg=>"raw:#{raw.name} doesn't have any item settings"}
                 else 
                    LogMonitorItem.where(:raw_key=>raw.raw_key).find_each do |item|
                       if LogMonitorRule.where(:item_key=>item.item_key).empty?
                            return {:rescode=>-1,:msg=>"item:#{item.item_name_prefix} doesn't have any rule settings"}
                       end
                    end
                 end  
            end
            return {:rescode=>0,:msg=>"ok"}
        end

        def domain_raw_completed?(app_key) 
            DomainMonitorRaw.where(:app_key=>app_key).find_each do  |raw|
                 if DomainMonitorAlert.where(:raw_key=>raw.raw_key).empty?
                    return {:rescode=>-1,:msg=>"raw:#{raw.name} doesn't have any alert settings"}
                 end
                 if DomainMonitorItem.where(:raw_key=>raw.raw_key).empty?
                    return {:rescode=>-1,:msg=>"raw:#{raw.name} doesn't have any item settings"}
                 else 
                    DomainMonitorItem.where(:raw_key=>raw.raw_key).find_each do |item|
                       if DomainMonitorRule.where(:item_key=>item.item_key).empty?
                            return {:rescode=>-1,:msg=>"item:#{item.name} doesn't have any rule settings"}
                       end
                    end
                 end  
            end
            return {:rescode=>0,:msg=>"ok"}
        end

        def user_defined_raw_completed?(app_key)
            UserDefinedMonitorRaw.where(:app_key=>app_key).find_each do  |raw|
                 if UserDefinedMonitorAlert.where(:raw_key=>raw.raw_key).empty?
                    return {:rescode=>-1,:msg=>"raw:#{raw.name} doesn't have any alert settings"}
                 end
                 if UserDefinedMonitorRule.where(:raw_key=>raw.raw_key).empty?
                    return {:rescode=>-1,:msg=>"raw:#{raw.name} doesn't have any rule settings"}
                 end
            end
            return {:rescode=>0,:msg=>"ok"}
        end
        
        def http_user_defined_raw_completed?(app_key)
            HttpUserDefinedMonitorRaw.where(:app_key=>app_key).find_each do  |raw|
                 if HttpUserDefinedMonitorAlert.where(:raw_key=>raw.raw_key).empty?
                    return {:rescode=>-1,:msg=>"raw:#{raw.name} doesn't have any alert settings"}
                 end
                 if HttpUserDefinedMonitorRule.where(:raw_key=>raw.raw_key).empty?
                    return {:rescode=>-1,:msg=>"raw:#{raw.name} doesn't have any rule settings"}
                 end
            end
            return {:rescode=>0,:msg=>"ok"}
        end

        def proc_raw_completed?(app_key)
            ProcMonitorRaw.where(:app_key=>app_key).find_each do  |raw|
                 if ProcMonitorAlert.where(:raw_key=>raw.raw_key).empty?
                    return {:rescode=>-1,:msg=>"raw:#{raw.name} doesn't have any alert settings"}
                 end
                 if ProcMonitorRule.where(:raw_key=>raw.raw_key).empty?
                    return {:rescode=>-1,:msg=>"raw:#{raw.name} doesn't have any rule settings"}
                 end
            end
            return {:rescode=>0,:msg=>"ok"}
        end

        def gen_log_monitor_raw_config(app_key)
            raws=[]
            LogMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                 raw_each={}
                 raw_each['name']=raw.name
                 raw_each['cycle']=raw.cycle
                 raw_each['method']=raw.method
                 raw_each['target']=raw.target
                 raw_each['params']=raw.params
                 raws<<raw_each
            end
            raws
        end
        def gen_log_monitor_item_config(app_key)
            items={}
            LogMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                log_item={}
                log_item['log_filepath']=raw.log_filepath
                log_item['limit_rate']=raw.limit_rate
                log_item['item']=[]
                LogMonitorItem.where("raw_key='#{raw.raw_key}'").find_each do |item|
                    item_each={}
                    item_each['item_name_prefix']=item.item_name_prefix
                    item_each['cycle']=item.cycle
                    item_each['match_str']=item.match_str
                    item_each['threshold']=item.threshold
                    item_each['filter_str']=item.filter_str
                    log_item['item'].push(item_each)
                end
                config_file="#{raw.raw_key}_#{raw.name}.conf"
                items[config_file]=log_item
            end
            items
        end
        def gen_log_monitor_rule_config(app_key)
            rules=[]
            LogMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                LogMonitorItem.where("raw_key='#{raw.raw_key}'").find_each do |item|
                    LogMonitorRule.where("item_key='#{item.item_key}'").find_each do |rule|
                        rule_each={}
                        rule_each['name']=rule.name
                        rule_each['formula']="${#{item.item_name_prefix}_cnt}#{rule.compare}#{rule.threshold}"
                        rule_each['filter']=rule.filter
                        rule_each['alert']=rule.alert
                        rules<<rule_each
                    end
                end
            end
            rules
        end
        def gen_log_monitor_alert_config(app_key)
            alerts=[]
            LogMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                LogMonitorAlert.where("raw_key='#{raw.raw_key}'").find_each do |alart|
                    alart_each={}
                    alart_each['name']=alart.name
                    alart_each['max_alert_times']=alart.max_alert_times
                    alart_each['remind_interval_second']=alart.remind_interval_second
                    alart_each['mail']=alart.mail
                    alart_each['sms']=alart.sms
                    alerts<<alart_each
                end
            end
            alerts
        end
        def gen_user_defined_monitor_raw_config(app_key) 
            raws=[]
            UserDefinedMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                 raw_each={}
                 raw_each['name']=raw.name
                 raw_each['cycle']=raw.cycle
                 raw_each['method']=raw.method
                 raw_each['target']=raw.target
                 raws<<raw_each
            end
            raws
        end
        def gen_user_defined_monitor_rule_config(app_key) 
            rules=[]
            UserDefinedMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                    UserDefinedMonitorRule.where("raw_key='#{raw.raw_key}'").find_each do |rule|
                        rule_each={}
                        rule_each['name']=rule.name
                        rule_each['formula']="${#{rule.monitor_item}}#{rule.compare}#{rule.threshold}"
                        rule_each['filter']=rule.filter
                        rule_each['alert']=rule.alert
                        rules<<rule_each
                    end
                end
            rules
        end
        def gen_user_defined_monitor_alert_config(app_key) 
            alerts=[]
            UserDefinedMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                UserDefinedMonitorAlert.where("raw_key='#{raw.raw_key}'").find_each do |alart|
                    alart_each={}
                    alart_each['name']=alart.name
                    alart_each['max_alert_times']=alart.max_alert_times
                    alart_each['remind_interval_second']=alart.remind_interval_second
                    alart_each['mail']=alart.mail
                    alart_each['sms']=alart.sms
                    alerts<<alart_each
                end
            end
            alerts
        end


        def gen_http_user_defined_monitor_raw_config(app_key) 
            raws=[]
            HttpUserDefinedMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                 raw_each={}
                 raw_each['name']=raw.name
                 raw_each['cycle']=raw.cycle
                 raw_each['method']=raw.method
                 raw_each['target']=raw.target
                 raws<<raw_each
            end
            raws
        end
        def gen_http_user_defined_monitor_rule_config(app_key) 
            rules=[]
            HttpUserDefinedMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                    HttpUserDefinedMonitorRule.where("raw_key='#{raw.raw_key}'").find_each do |rule|
                        rule_each={}
                        rule_each['name']=rule.name
                        rule_each['formula']="${#{rule.monitor_item}}#{rule.compare}#{rule.threshold}"
                        rule_each['filter']=rule.filter
                        rule_each['alert']=rule.alert
                        rules<<rule_each
                    end
                end
            rules
        end
        def gen_http_user_defined_monitor_alert_config(app_key) 
            alerts=[]
            HttpUserDefinedMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                HttpUserDefinedMonitorAlert.where("raw_key='#{raw.raw_key}'").find_each do |alart|
                    alart_each={}
                    alart_each['name']=alart.name
                    alart_each['max_alert_times']=alart.max_alert_times
                    alart_each['remind_interval_second']=alart.remind_interval_second
                    alart_each['mail']=alart.mail
                    alart_each['sms']=alart.sms
                    alerts<<alart_each
                end
            end
            alerts
        end


        def gen_proc_monitor_raw_config(app_key) 
            raws=[]
            ProcMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                 raw_each={}
                 raw_each['name']=raw.name
                 raw_each['cycle']=raw.cycle
                 raw_each['method']=raw.method
                 raw_each['target']=raw.target
                 raw_each['params']=raw.params
                 raws<<raw_each
            end
            raws
        end
        def gen_proc_monitor_rule_config(app_key) 
            rules=[]
            ProcMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                    ProcMonitorRule.where("raw_key='#{raw.raw_key}'").find_each do |rule|
                        rule_each={}
                        rule_each['name']=rule.name
                        rule_each['formula']="${#{rule.monitor_item}}#{rule.compare}#{rule.threshold}"
                        rule_each['filter']=rule.filter
                        rule_each['alert']=rule.alert
                        rules<<rule_each
                    end
                end
            rules
        end
        def gen_proc_monitor_alert_config(app_key) 
            alerts=[]
            ProcMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                ProcMonitorAlert.where("raw_key='#{raw.raw_key}'").find_each do |alart|
                    alart_each={}
                    alart_each['name']=alart.name
                    alart_each['max_alert_times']=alart.max_alert_times
                    alart_each['remind_interval_second']=alart.remind_interval_second
                    alart_each['mail']=alart.mail
                    alart_each['sms']=alart.sms
                    alerts<<alart_each
                end
            end
            alerts
        end

	    def gen_config_service(use_jpaas,app_bns,config_path,raw=[],rule=[],alert=[],log_monitor_item={})
		    path="#{config_path}/#{app_bns}"
		    #gen instance file content
		    instance_content={}
		    instance_content["started_mode"]="jpaas" if use_jpaas
		    instance_content["raw"]=raw
		    instance_content["rule"]=rule
		    instance_content["alert"]=alert
		    #gen file
		    ## for instance
		    instance_file = File.open("#{path}/instance","w")
            instance_file.write(JSON.pretty_generate(instance_content))
            instance_file.close
		    ##for log monitor item
		    log_monitor_item.each do |item_name,item_content|
		        item_file = File.open("#{path}/#{item_name}","w")
                item_file.write(JSON.pretty_generate(item_content))
                item_file.close
		    end
            #svn add
            Svn.add_all(path)
	    end
        def get_domain_by_app_key(app_key)
            domain=nil
            unless DomainMonitorRaw.where("app_key='#{app_key}'").empty?
                domain=DomainMonitorRaw.where("app_key='#{app_key}'").first.domain
            end
            domain
        end
        def gen_domain_monitor_config(app_key)
            raws=[]
            DomainMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                 raw_each={}
                 raw_each['name']=raw.name
                 raw_each['domain']=raw.domain
                 raw_each['item']=[]
                 raw_each['rule']=[]
                 DomainMonitorItem.where(:raw_key=>raw.raw_key).find_each do |item|
                    item_each={}
                    item_each['name']=item.name
                    item_each['cycle']=item.cycle
                    item_each['req_content']=item.req_content
                    item_each['res_check']=item.res_check
                    item_each['mon_idc']=item.mon_idc
                    item_each['req_type']=item.req_type
                    item_each['port']=item.port
                    item_each['host']=raw.domain
                    DomainMonitorRule.where(:item_key=>item.item_key).find_each do |rule|
                        rule_each={}
                        rule_each['name']=rule.name
                        rule_each['formula']="${#{rule.item_name}_err_percent}#{rule.compare}#{rule.threshold}"
                        rule_each['filter']=rule.filter
                        rule_each['alert']=rule.alert
                        raw_each['rule']<<rule_each
                    end
                    raw_each['item']<<item_each
                 end
                 raw_each['alert']=[]
                 DomainMonitorAlert.where("raw_key='#{raw.raw_key}'").find_each do |alert|
                    alert_each={}
                    alert_each['name']=alert.name
                    alert_each['mail']=alert.mail
                    alert_each['sms']=alert.sms
                    raw_each['alert']<<alert_each
                 end
                 raws<<raw_each
            end
            raws
        end
        def gen_config_domain(config_path,domain_monitor_config)
            domain_monitor_config.each do |raw|
                domain=raw['domain']
                `mkdir -p #{config_path}/#{domain}`
                file_content={}
                file_content['request']=raw['item']
                file_content['rule']=raw['rule']
                file_content['alert']=raw['alert']
                domain_file = File.open("#{config_path}/#{domain}/domain","w")
                domain_file.write(JSON.pretty_generate(file_content))
                domain_file.close
                Svn.add_all("#{config_path}/#{domain}")
            end
        end
    end
end
