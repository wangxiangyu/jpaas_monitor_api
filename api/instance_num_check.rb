$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
require "rack/contrib"
require "digest"
module Acme
  class InstanceNumCheck < Grape::API
    use Rack::JSONP
    format :json
    helpers do
        def format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
        def get_random_hash
            SecureRandom.hex 16
        end
    end
        desc "add instances num monitor" 
        params do 
            requires :app_key, type: String, desc: "app_key" 
            requires :cluster, type: String, desc: "cluster"
            requires :mail, type: String, desc: "mail" 
            requires :sms, type: String, desc: "sms" 
        end 
        get '/add_instance_num_monitor' do 
            app_key=format(params['app_key'])
            mail=format(params['mail']) 
            sms=format(params['sms']) 
            cluster=format(params['cluster']).gsub(';',' ')
            result=AppBns.where(:app_key=>app_key)
            if result.empty?
                return {:rescode=>-1,:msg=>"Error: app_key:#{app_key} doesn't exist"}
            end
            bns_info=result.first
            app_name=bns_info.app_name
            org=bns_info.organization
            space=bns_info.space
            #add_raw
            raw={}
            raw['app_key']=app_key
            raw['name']="instance_num_check_#{app_name}_#{space}_#{org}"
            raw['cycle']=10
            raw['method']='exec'
            raw['target']="/usr/monitor/instance_num_check.sh #{app_name} #{space} #{org} #{cluster}"
            raw['raw_key']=get_random_hash
            if UserDefinedMonitorRaw.where(:app_key=>app_key,:name=>raw['name']).empty?
                    UserDefinedMonitorRaw.create(raw)
            else
                    return {:rescode=>-1,:msg=>"Error: You have added the same log raw"}
            end
            #add_rule
            rule={}
            rule['raw_key']=raw['raw_key']
            rule['name']="instance_num_check_#{app_name}_#{space}_#{org}_failed_caused_by_lack_of_instances"
            rule['monitor_item']="#{app_name}_#{space}_#{org}_result"
            rule['compare']="!="
            rule['threshold']="0"
            rule['filter']="3/3"
            rule['alert']="alert_"+raw['raw_key']
            rule['disable_time']="00:00:00-00:00:00"
            rule['rule_key']=get_random_hash
            UserDefinedMonitorRule.create(rule)
            #add_alert
            alert={}
            alert['raw_key']=raw['raw_key']
            alert['name']="alert_"+alert['raw_key']
            alert['max_alert_times']="5"
            alert['remind_interval_second']="900"
            alert['mail']=mail
            alert['sms']=sms
            UserDefinedMonitorAlert.create(alert)
            return {:rescode=>0,:raw_key=>raw['raw_key']}
        end 
        desc "update instances num monitor"
        params do
            requires :app_key, type: String, desc: "app_key"
            requires :cluster, type: String, desc: "cluster"
            requires :mail, type: String, desc: "mail"
            requires :sms, type: String, desc: "sms"
        end
        get "/update_instance_num_monitor" do
            app_key=format(params['app_key'])
            mail=format(params['mail'])
            sms=format(params['sms'])
            cluster=format(params['cluster']).gsub(';',' ')
            result=AppBns.where(:app_key=>app_key)
            if result.empty?
                return {:rescode=>-1,:msg=>"Error: app_key:#{app_key} doesn't exist"}
            end
            bns_info=result.first
            app_name=bns_info.app_name
            org=bns_info.organization
            space=bns_info.space
            name="instance_num_check_#{app_name}_#{space}_#{org}"
            raw={}
            raw['target']="/usr/monitor/instance_num_check.sh #{app_name} #{space} #{org} #{cluster}"
            result=UserDefinedMonitorRaw.where(:app_key=>app_key,:name=>name)
            if result.empty?
                return {:rescode=>-1,:msg=>"Error: #{app_name} #{space} #{org} doesn't exist"}
            else
                result.update_all(raw)
            end
            alert={}
            alert['mail']=mail
            alert['sms']=sms
            raw_key=result.first.raw_key
            UserDefinedMonitorAlert.where(:raw_key=>raw_key).update_all(alert)
            return {:rescode=>0,:raw_key=>raw_key}
        end

        desc "delete instances num monitor"
        params do
            requires :app_key, type: String, desc: "app_key"
        end
        get "/delete_instance_num_monitor" do
            app_key=format(params['app_key'])
            result=AppBns.where(:app_key=>app_key)
            if result.empty?
                return {:rescode=>-1,:msg=>"Error: app_key:#{app_key} doesn't exist"}
            end
            bns_info=result.first
            app_name=bns_info.app_name
            org=bns_info.organization
            space=bns_info.space
            name="instance_num_check_#{app_name}_#{space}_#{org}"
            result=UserDefinedMonitorRaw.where(:app_key=>app_key,:name=>name)
            if result.empty?
                return {:rescode=>-1,:msg=>"Error: #{app_name} #{space} #{org} doesn't exist"}
            end
            raw_key=result.first.raw_key
            UserDefinedMonitorAlert.where(:raw_key=>raw_key).destroy_all
            UserDefinedMonitorRule.where(:raw_key=>raw_key).destroy_all
            UserDefinedMonitorRaw.where(:raw_key=>raw_key).destroy_all
            return {:rescode=>0,:raw_key=>raw_key}
        end

        
        desc "get instances num monitor"
        params do
            requires :app_key, type: String, desc: "app_key"
        end
        get "/get_instance_num_monitor" do
            app_key=format(params['app_key'])
            result=AppBns.where(:app_key=>app_key)
            if result.empty?
                return {:rescode=>-1,:msg=>"Error: app_key:#{app_key} doesn't exist"}
            end
            bns_info=result.first
            app_name=bns_info.app_name
            org=bns_info.organization
            space=bns_info.space
            name="instance_num_check_#{app_name}_#{space}_#{org}"
            result=UserDefinedMonitorRaw.where(:app_key=>app_key,:name=>name)
            if result.empty?
                return {:rescode=>-1,:msg=>"Error: #{app_name} #{space} #{org} doesn't exist"}
            else
                instance_num_monitor={}
                raw_key=result.first.raw_key
                alarm=UserDefinedMonitorAlert.where(:raw_key=>raw_key).first
                raw=result.first
                instance_num_monitor['mail']=alarm.mail
                instance_num_monitor['sms']=alarm.sms
                instance_num_monitor['cluster']=raw.target.split(' ')[4..-1]
            end
            return {:rescode=>0,:instance_num_monitor=>instance_num_monitor}
        end

  end
end
