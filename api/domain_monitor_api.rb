require "digest"
$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"
require "rack/contrib"
require "securerandom"

module Acme
  class DomainMonitor < Grape::API
    use Rack::JSONP
    format :json
    helpers do
        def format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
        def get_random_hash
            SecureRandom.hex 16
        end
        def get_raw_key_by_item_key(item_key)
                raw_key=DomainMonitorItem.where(:item_key=>item_key).first.raw_key
        end
        def get_raws(app_key)
            raws=[]
            unless DomainMonitorRaw.where(:app_key=>app_key).empty?
                DomainMonitorRaw.where(:app_key=>app_key).find_each do |raw|
                    raw_hash=raw.serializable_hash
                    raw_hash.delete('id')
                    raw_hash.delete('updated_at')
                    raw_hash.delete('created_at')
                    raws.push(raw_hash)
                end
            end
            raws
        end
        def get_alerts(raw_key)
            alert_info={}
            unless DomainMonitorAlert.where(:raw_key=>raw_key).empty?
                alert_info=DomainMonitorAlert.where(:raw_key=>raw_key).first.serializable_hash
                alert_info.delete('id')
                alert_info.delete('raw_key')
                alert_info.delete('name')
                alert_info.delete('created_at')
                alert_info.delete('updated_at')
            end
            alert_info
        end
        def get_items(raw_key)
            items=[]
            unless DomainMonitorItem.where(:raw_key=>raw_key).empty?
                DomainMonitorItem.where(:raw_key=>raw_key).find_each do |item|
                    item_hash=item.serializable_hash
                    item_hash.delete('id')
                    item_hash.delete('req_type')
                    item_hash.delete('cycle')
                    item_hash.delete('mon_idc')
                    item_hash.delete('created_at')
                    item_hash.delete('updated_at')
                    items.push(item_hash)
                end
            end
            items
        end
        def get_rules(item_key)
            rules=[]
            unless DomainMonitorRule.where(:item_key=>item_key).empty?
                DomainMonitorRule.where(:item_key=>item_key).find_each do |rule|
                    rule_hash=rule.serializable_hash
                    rule_hash.delete('id')
                    rule_hash.delete('created_at')
                    rule_hash.delete('updated_at')
                    rule_hash.delete('alert')
                    rules.push(rule_hash)
                end
            end
            rules
        end
    end
    namespace :domain_monitor do
        after do
            ActiveRecord::Base.clear_active_connections!
        end
        desc "add domain monitor raw"
        params do
            requires :app_key, type: String, desc: "app key"
            requires :name, type: String, desc: "name"
            requires :domain, type: String, desc: "domain"
        end
        get '/add_raw' do
            raw={}
	        raw['app_key']=format(params['app_key'])
            if AppBns.where(:app_key=>raw['app_key']).empty?
                return {:rescode=>-1,:msg=>"Error: app_key:#{raw['app_key']} doesn't exist"}
            end
	        raw['name']=format(params['name'])
	        raw['domain']=format(params['domain'])
	        raw['raw_key']=get_random_hash
            if DomainMonitorRaw.where(:app_key=>raw['app_key'],:name=>raw['name']).empty?
                    DomainMonitorRaw.create(raw)
                    return {:rescode=>0,:raw_key=>raw['raw_key']}
            else
                    return {:rescode=>-1,:msg=>"Error: You have added the same raw"}
            end
        end
    
        desc "del domain monitor raw"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/del_raw' do
            raw_key=format(params['raw_key'])
            if DomainMonitorRaw.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"Error: raw:#{raw_key} doesn't exist"}
            else
                if DomainMonitorItem.where(:raw_key=>raw_key).empty? 
                    DomainMonitorRaw.where(:raw_key=>raw_key).destroy_all   
                    DomainMonitorAlert.where(:raw_key=>raw_key).destroy_all   
                    return {:rescode=>0,:msg=>"ok"}
                else
                    return {:rescode=>-1,:msg=>"Error: please delete items related to this raw first"}
                end
            end
        end

        desc "update domain monitor raw"
        params do
            requires :raw_key, type: String, desc: "raw key"
            requires :name, type: String, desc: "name"
            requires :domain, type: String, desc: "domain"
        end
        get '/update_raw' do
            raw={}
            raw_key=format(params['raw_key'])
            if DomainMonitorRaw.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"Error: raw:#{raw_key} doesn't exist"}
            end
	        raw['name']=format(params['name'])
	        raw['domain']=format(params['domain'])
            DomainMonitorRaw.where(:raw_key=>raw_key).update_attribute(raw)
            return {:rescode=>0,:raw_key=>raw_key}
        end

        desc "add domain monitor item"
        params do
            requires :raw_key, type: String, desc: "raw key"
            requires :name, type: String, desc: "item name"
            requires :req_content, type: String, desc: "req_content"
            requires :res_check, type: String, desc: "res_check"
        end
        get '/add_item' do
            raw_key=format(params['raw_key'])
            if DomainMonitorRaw.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"Error: raw:#{raw_key} doesn't exist"}
            else
                item={}
                item['raw_key']=raw_key
	            item['name']=format(params['name'])
	            item['cycle']='60'
	            item['port']='80'
	            item['req_type']='http'
	            item['req_content']=format(params['req_content'])
	            item['res_check']=format(params['res_check'])
	            item['mon_idc']='all'
	            item['item_key']=get_random_hash
                if DomainMonitorItem.where(:raw_key=>item['raw_key'],:name=>item['name']).empty?
                    DomainMonitorItem.create(item)
                    return {:rescode=>0,:item_key=>item['item_key']}
                else
                    return {:rescode=>-1,:msg=>"Error: You have added the item for this domain monitor"}
                end
            end
        end

        desc "del domain monitor item"
        params do
            requires :item_key, type: String, desc: "item key"
        end
        get '/del_item' do
            item_key=format(params['item_key'])
            if DomainMonitorItem.where(:item_key=>item_key).empty?
                return {:rescode=>-1,:msg=>"Error: item:#{item_key} doesn't exist"}
            else
                if DomainMonitorRule.where(:item_key=>item_key).empty?
                    DomainMonitorItem.where(:item_key=>item_key).destroy_all
                    return {:rescode=>0,:msg=>"ok"}
                else
                    return {:rescode=>-1,:msg=>"Error: please delete rules related to this item first"}
                end
            end
        end


        desc "update domain monitor item"
        params do
            requires :item_key, type: String, desc: "item key"
            requires :name, type: String, desc: "item name"
            requires :req_content, type: String, desc: "req_content"
            requires :res_check, type: String, desc: "res_check"
        end
        get '/update_item' do
            item={}
	        item['name']=format(params['name'])
	        item['req_content']=format(params['req_content'])
	        item['res_check']=format(params['res_check'])
            if DomainMonitorItem.where(:item_key=>item_key).empty?
                return {:rescode=>-1,:msg=>"Error: item:#{item_key} doesn't exist"}
            end
            DomainMonitorItem.where(:item_key=>item_key).update_attribute(item)
            return {:rescode=>0,:item_key=>item_key}
        end

        desc "add domain monitor rule"
        params do
            requires :item_key, type: String, desc: "item key"
            requires :name, type: String, desc: "rule name"
            requires :item_name, type: String, desc: "item name"
            requires :filter, type: String, desc: "setting for alarm strategy"
        end
        get '/add_rule' do
            item_key=format(params['item_key'])
            if DomainMonitorItem.where(:item_key=>item_key).empty?
                return {:rescode=>-1,:msg=>"Error: item:#{item_key} doesn't exist"}
            else
                rule={}
                rule['item_key']=item_key
	            rule['name']=format(params['name'])
	            rule['filter']=format(params['filter'])
                rule['item_name']="#{format(params['item_name'])}"
                rule['compare']='>'
                rule['threshold']='50'
	            rule['alert']="alert_"+get_raw_key_by_item_key(rule['item_key'])
	            rule['rule_key']=get_random_hash
                if DomainMonitorRule.where(:item_key=>rule['item_key']).empty?
                    DomainMonitorRule.create(rule)
                    return {:rescode=>0,:rule_key=>rule['rule_key']}
                else
                    return {:rescode=>-1,:msg=>"Error: You have added the rule for this item"}
                end
            end
        end

        desc "del domain monitor rule"
        params do
            requires :rule_key, type: String, desc: "rule key"
        end
        get '/del_rule' do
            rule_key=format(params['rule_key'])
            if  DomainMonitorRule.where(:rule_key=>rule_key).empty?
                return {:rescode=>-1,:msg=>"Error: rule:#{rule_key} doesn't exist"}
            else
                DomainMonitorRule.where(:rule_key=>rule_key).destroy_all   
                return {:rescode=>0,:msg=>"ok"}
            end
        end

        desc "update domain monitor rule"
        params do
            requires :rule_key, type: String, desc: "rule key"
            requires :name, type: String, desc: "name"
            requires :item_name, type: String, desc: "item name"
            requires :filter, type: String, desc: "filter"
        end
        get '/update_rule' do
            rule={}
            rule_key=format(params['rule_key'])
            unless DomainMonitorRule.where(:rule_key=>rule_key).empty?
                return {:rescode=>-1,:msg=>"Error: rule:#{rule_key} doesn't exist"}
            else
                rule['name']=format(params['name'])
                rule['filter']=format(params['filter'])
                rule['item_name']="#{format(params['item_name'])}"
                DomainMonitorRule.where(:rule_key=>rule_key).update_attribute(rule)
                return {:rescode=>0,:rule_key=>rule_key}
            end
        end

        desc "add domain monitor alert"
        params do
            requires :raw_key, type: String, desc: "raw key"
            requires :mail, type: String, desc: "mails of alarm receivers"
            requires :sms, type: String, desc: "phones of alarm receivers"
        end
        get '/add_alert' do
            alert={}
	        alert['raw_key']=format(params['raw_key'])
            if DomainMonitorRaw.where(:raw_key=>alert['raw_key']).empty?
                return {:rescode=>-1,:msg=>"Error: raw_key:#{alert['raw_key']} doesn't exist"}
            end
	        alert['name']="alert_"+alert['raw_key']
	        alert['mail']=format(params['mail'])
	        alert['sms']=format(params['sms'])
            if DomainMonitorAlert.where(:raw_key=>alert['raw_key']).empty?
                    DomainMonitorAlert.create(alert)
                    return {:rescode=>0,:raw_key=>alert['raw_key']}
            else
                    return {:rescode=>-1,:msg=>"Error: You have added the alarm"}
            end
        end

        desc "del domain monitor alert"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/del_alert' do
            raw_key=format(params['raw_key'])
            if DomainMonitorAlert.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"Error: alert related to raw:#{raw_key} doesn't exist"}
            else
                DomainMonitorAlert.where(:raw_key=>raw_key).destroy_all
                return {:rescode=>0,:msg=>"ok"}
            end
        end

        desc "update domain monitor alert"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/update_alert' do
            alert={}
            raw_key=format(params['raw_key'])
            if DomainMonitorAlert.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"Error: alert related to raw:#{raw_key} doesn't exist"}
            end
	        alert['mail']=format(params['mail'])
	        alert['sms']=format(params['sms'])
            DomainMonitorAlert.where(:raw_key=>raw_key).update_attribute(alert)
            return {:rescode=>0,:raw_key=>raw_key}
        end

        desc "get raw by app key"
        params do
            requires :app_key, type: String, desc: "app key"
        end
        get '/get_raw_by_app_key'  do
            app_key=format(params['app_key'])
            if AppBns.where(:app_key=>app_key).empty?
                return {:rescode=>-1,:msg=>"app_key: #{app_key} doesn't exist"}
            else
                raws=get_raws(app_key)
                return {:rescode=>0,:raws=>raws}
            end
        end

        desc "get alert by raw key"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/get_alert_by_raw_key' do
            raw_key=format(params['raw_key'])
            unless DomainMonitorAlert.where(:raw_key=>raw_key).empty?
                alert_info=get_alerts(raw_key)
                return {:rescode=>0,:alert=>alert_info}
            else
                return {:rescode=>-1,:msg=>"alert related to raw_key #{raw_key} doesn't exist"}
            end
        end

        desc "get item by raw key"
        params do
            requires :raw_key, type: String, desc: "raw key"
        end
        get '/get_item_by_raw_key' do
            raw_key=format(params['raw_key'])
            if DomainMonitorItem.where(:raw_key=>raw_key).empty?
                return {:rescode=>-1,:msg=>"items related to raw_key #{raw_key} doesn't exist"}
            else
                items=get_items(raw_key)
                return {:rescode=>0,:items=>items}
            end
        end

        desc "get_rules_by_item_key"
        params do
            requires :item_key, type: String, desc: "item key"
        end
        get '/get_rules_by_item_key' do
            item_key=format(params['item_key'])
            if DomainMonitorRule.where(:item_key=>item_key).empty?
                return {:rescode=>-1,:msg=>"rules related to item_key #{item_key} doesn't exist"}
            else
                rules=get_rules(item_key)
                return {:rescode=>0,:rules=>rules}
            end
        end

        desc "get_domain_monitor_by_app_key"
        params do
            requires :app_key, type: String, desc: "app key"
        end
        get '/get_domain_monitor_by_app_key' do
            app_key=format(params['app_key'])
            if AppBns.where(:app_key=>app_key).empty?
                return {:rescode=>-1,:msg=>"app_key: #{app_key} doesn't exist"}
            else
                raws=get_raws(app_key)
                raws.each do |raw|
                    raw['items']=get_items(raw['raw_key'])
                    raw['items'].each do |item|
                        item['rules']=get_rules(item['item_key'])
                    end
                    raw['alert']=get_alerts(raw['raw_key'])
                end
                return {:rescode=>0,:raw=>raws}
            end
        end
    end
  end
end
