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

        def init_config(app_bns,work_path,username,password)
		    `mkdir -p #{work_path}/#{app_bns}`
             Svn.add_all("#{work_path}")
             Svn.del_all("#{work_path}/#{app_bns}")
             Svn.commit(work_path,"delete",username,password)
        end
        
        def commit_config(app_bns,work_path,message,username,password)
            Svn.add_all("#{work_path}/#{app_bns}")
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
                config_file="#{raw.app_key}_#{raw.name}.conf"
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

	    def gen_config(app_bns,config_path,raw=[],rule=[],alert=[],log_monitor_item={})
		    path="#{config_path}/#{app_bns}"
		    #gen instance file content
		    instance_content={}
		    instance_content["started_mode"]="jpaas"
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
	    end
        def gen_log_config(config_path)
            AppBns.find_each do |app|
                config={}
                config['raw']=[]
                config['rule']=[]
                config['alert']=[]
                path="#{config_path}/#{app.name}"
                `mkdir -p #{path}`
                LogMonitorRaw.where(:app_key=>app.app_key).find_each do |raw|
                    next if log_raw_completed?(raw.raw_key)[:rescode] !=0
                    raw_each={}
                    raw_each['name']=raw.name
                    raw_each['cycle']=raw.cycle
                    raw_each['method']=raw.method
                    raw_each['target']=raw.target
                    raw_each['params']=raw.params
                    config['raw'].push(raw_each)
                    config=gen_log_item(raw,config,path)
                    config=gen_alart(raw,config)
                end
                unless config['raw'].empty?
                    fconfig = File.open("#{path}/instance","w")
                    fconfig.write(JSON.pretty_generate(config))
                    fconfig.close
                end
            end
        end
        def gen_log_item(raw,config,path)
            log_item={}
            log_item['log_filepath']="${DEPLOY_DIR}"+"/tmp/rootfs"+raw.log_filepath
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
                config=gen_log_rule(item,config)
            end
            `mkdir -p #{path}`
            f_log_item = File.open("#{path}/#{raw.app_key}_#{raw.name}.conf","w")
            f_log_item.write(JSON.pretty_generate(log_item))
            f_log_item.close
            config
        end
        def gen_log_rule(item,config)
            LogMonitorRule.where("item_key='#{item.item_key}'").find_each do |rule|
                rule_each={}
                rule_each['name']=rule.name
                rule_each['formula']="${#{item.item_name_prefix}_cnt}#{rule.compare}#{rule.threshold}"
                rule_each['filter']=rule.filter
                rule_each['alert']=rule.alert
                config['rule'].push(rule_each)
            end
            config
        end
        def gen_alart(raw,config)
            LogMonitorAlert.where("raw_key='#{raw.raw_key}'").find_each do |alart|
                alart_each={}
                alart_each['name']=alart.name
                alart_each['max_alert_times']=alart.max_alert_times
                alart_each['remind_interval_second']=alart.remind_interval_second
                alart_each['mail']=alart.mail
                alart_each['sms']=alart.sms
                config['alert'].push(alart_each)
            end
            config
        end
    end
end
