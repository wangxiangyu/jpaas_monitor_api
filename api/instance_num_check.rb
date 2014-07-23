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
            requires :app_name, type: String, desc: "app_name" 
            requires :org, type: String, desc: "org" 
            requires :space, type: String, desc: "space" 
            requires :cluster, type: String, desc: "cluster" 
            requires :mail, type: String, desc: "mail" 
            requires :sms, type: String, desc: "sms" 
        end 
        get '/add_instance_num_monitor' do 
            app_name=format(params['app_name']) 
            org=format(params['org']) 
            space=format(params['space']) 
            mail=format(params['mail']) 
            sms=format(params['sms']) 
            cluster=format(params['cluster']).gsub(';',' ') 
            #add_raw
            raw={}
            app_key="c9832ed4fa4aa0163d0455e82acfcae8"#Digest::MD5.hexdigest("instance_num_monitor")
            raw['app_key']=app_key
            raw['name']="instance_num_check_#{app_name}_#{space}_#{org}"
            raw['cycle']=10
            raw['method']='exec'
            raw['target']="/home/work/opbin/monitor/instance_num_check/instance_num_check.sh #{app_name} #{space} #{org} #{cluster}"
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
            rule['monitor_item']="result"
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
            requires :app_name, type: String, desc: "app_name"
            requires :org, type: String, desc: "org"
            requires :space, type: String, desc: "space"
            requires :cluster, type: String, desc: "cluster"
            requires :mail, type: String, desc: "mail"
            requires :sms, type: String, desc: "sms"
        end
        get "/update_instance_num_monitor" do
            app_name=format(params['app_name'])
            org=format(params['org'])
            space=format(params['space'])
            cluster=format(params['cluster']).gsub(';',' ')
            mail=format(params['mail'])
            sms=format(params['sms'])
            name="instance_num_check_#{app_name}_#{space}_#{org}"
            app_key='c9832ed4fa4aa0163d0455e82acfcae8'
            raw={}
            raw['target']="/home/work/opbin/monitor/instance_num_check/instance_num_check.sh #{app_name} #{space} #{org} #{cluster}"
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
            requires :app_name, type: String, desc: "app_name"
            requires :org, type: String, desc: "org"
            requires :space, type: String, desc: "space"
        end
        get "/delete_instance_num_monitor" do
            app_name=format(params['app_name'])
            org=format(params['org'])
            space=format(params['space'])
            name="instance_num_check_#{app_name}_#{space}_#{org}"
            app_key='c9832ed4fa4aa0163d0455e82acfcae8'
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
            requires :app_name, type: String, desc: "app_name"
            requires :org, type: String, desc: "org"
            requires :space, type: String, desc: "space"
        end
        get "/get_instance_num_monitor" do
            app_name=format(params['app_name'])
            org=format(params['org'])
            space=format(params['space'])
            name="instance_num_check_#{app_name}_#{space}_#{org}"
            app_key='c9832ed4fa4aa0163d0455e82acfcae8'
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
