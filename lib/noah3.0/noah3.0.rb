require "active_record"
$:.unshift(File.expand_path("../", File.dirname(__FILE__)))
require "mysvn"
require "database"
    class Noah3
        class << self
            def checkout_config(work_path,svn_path,username,password)
                `rm -rf #{work_path} && mkdir -p #{work_path} && cd #{work_path}`
                 Svn.checkout(svn_path,work_path,username,password)
                 Svn.del_all(work_path)
            end
            
            def commit_config(work_path,message,username,password)
                Svn.add_all(work_path)
                Svn.commit(work_path,message,username,password)
            end
            
            def log_raw_completed?(raw_key) 
                if LogMonitorRaw.where(:raw_key=>raw_key).empty?
                     return {:rescode=>-1,:msg=>"#{raw_key} doesn't exist"}
                else raw=LogMonitorRaw.where(:raw_key=>raw_key).first
                     if MonitorAlert.where(:raw_key=>raw_key).empty?
                        return {:rescode=>-1,:msg=>"raw:#{raw.name} doesn't have any alert settings"}
                     end
                     if LogMonitorItem.where(:raw_key=>raw_key).empty?
                        return {:rescode=>-1,:msg=>"raw:#{raw.name} doesn't have any item settings"}
                     else 
                        LogMonitorItem.where(:raw_key=>raw_key).find_each do |item|
                           if LogMonitorRule.where(:item_key=>item.item_key).empty?
                                return {:rescode=>-1,:msg=>"item:#{item.item_name_prefix} doesn't have any rule settings"}
                           end
                        end
                     end  
                end
                return {:rescode=>0,:msg=>"ok"}
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
                    rule_each['formula']=rule.formula
                    rule_each['filter']=rule.filter
                    rule_each['alert']=rule.alert
                    config['rule'].push(rule_each)
                end
                config
            end
            def gen_alart(raw,config)
                MonitorAlert.where("raw_key='#{raw.raw_key}'").find_each do |alart|
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
