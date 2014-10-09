$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
require "rack/contrib"
require "digest"
require 'net/http'
require 'json'
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"
module Acme
  class MonitorCheck < Grape::API
    use Rack::JSONP
    format :json
    helpers do
        def format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
        def get_app_key(app,space,org)
            result=AppBns.where(:app_name=>app,:space=>space,:organization=>org)
            if result.empty?
                return nil
            else
                return result.first.app_key
            end
        end
        def web_app?(app,space,org)
            result=false
            instances=InstanceStatus.where("state = ? and app_name like ? and organization = ?  and space = ?",'RUNNING',"#{app}\\_%",org,space)
            instances.find_each do |instance|
                instance.uris.split(',').each do |uri|
                    return true unless uri=~/jpaas-\w+.baidu.com/ 
                end
            end
            return result
        end
        def add_domain_monitor?(app_key)
            result=DomainMonitorRaw.where(:app_key=>app_key)
            if result.empty?
                return false
            else
                return true
            end
        end

        def add_instance_num_check?(app,space,org)
            result=UserDefinedMonitorRaw.where(:app_key=>'c9832ed4fa4aa0163d0455e82acfcae8',:name=>"instance_num_check_#{app}_#{space}_#{org}")
            if result.empty?
                return false
            else
                return true
            end
        end
        def get_org_list
            list={}
            host="icf_2.jpaas-ng00.baidu.com"
            path="/api/orgs"
            http = Net::HTTP.new(host,80)
            headers = {
                'Authorization'=>"3FCPpbFZ5fAmES4YuMmtg1vGiT70vOgL3URTZmfb"
            }
            response=http.get(path, headers)
            result=JSON.parse response.body
            result.each do |org|
                next if org['name']=='idea-show'
                list[org['id']]=org['name']
            end
            list
        end
        def get_space_list(org_id)
            list={}
            host="icf_2.jpaas-ng00.baidu.com"
            path="/api/orgs/#{org_id}/spaces"
            http = Net::HTTP.new(host,80)
            headers = {
                'Authorization'=>"3FCPpbFZ5fAmES4YuMmtg1vGiT70vOgL3URTZmfb"
            }
            response=http.get(path, headers)
            result=JSON.parse response.body
            result.each do |space|
                next unless space['version']==2
                list[space['id']]=space['name']
            end
            list
        end
        def get_app_list(space_id)
            list={}
            host="icf_2.jpaas-ng00.baidu.com"
            path="/api/spaces/#{space_id}/apps"
            http = Net::HTTP.new(host,80)
            headers = {
                'Authorization'=>"3FCPpbFZ5fAmES4YuMmtg1vGiT70vOgL3URTZmfb"
            }
            response=http.get(path, headers)
            result=JSON.parse response.body
            result.each do |app|
                list[app['id']]=app['name']
            end
            list
        end
    end
    desc "check domain monitor coverage"
    get "/check/domain_monitor_check" do
        result={}
        orgs=get_org_list
        orgs.each do |org_id,org_name|
            spaces=get_space_list(org_id)
            result[org_name]||={}
            spaces.each do |space_id,space_name|
                result[org_name][space_name]||={}
                apps=get_app_list(space_id)
                apps.each do  |app_id,app_name|
                    next unless web_app?(app_name,space_name,org_name)
                    app_key=get_app_key(app_name,space_name,org_name)
                    if app_key.nil?
                      #  result[org_name][space_name][app_name]="WARNING: This app has't been online yet"
                        next
                    end
                    if add_domain_monitor?(app_key) and Noah3.domain_raw_completed?(app_key)
                      #  result[org_name][space_name][app_name]="OK, This app has domain monitor"
                    else
                        result[org_name][space_name][app_name]="WARNING, This app has't have any domain monitor yet"
                    end
                end
            end
        end
        return {:rescode=>0,:msg=>result}
    end
    desc "check instance num monitor coverage"
    get "/check/instance_num_monitor_check" do
        result={}
        orgs=get_org_list
        orgs.each do |org_id,org_name|
            spaces=get_space_list(org_id)
            result[org_name]||={}
            spaces.each do |space_id,space_name|
                result[org_name][space_name]||={}
                apps=get_app_list(space_id)
                apps.each do  |app_id,app_name|
                    app_key=get_app_key(app_name,space_name,org_name)
                    if app_key.nil?
                      #  result[org_name][space_name][app_name]="WARNING: This app has't been online yet"
                        next
                    end
                    if add_instance_num_check?(app_name,space_name,org_name) 
                      #  result[org_name][space_name][app_name]="OK, This app has instance num monitor"
                    else
                        result[org_name][space_name][app_name]="WARNING, This app has't have any instance num monitor yet"
                    end
                end
            end
        end
        return {:rescode=>0,:msg=>result}
    end

    desc "check if an app is under domain monitor"
    params do
        requires :space, type: String, desc: "space name"
        requires :org, type: String, desc: "org name"
        requires :app, type: String, desc: "app name without version"
    end
    get "/check/app_domain_monitor_check" do
        app_name=format(params['app'])
        space_name=format(params['space'])
        org_name=format(params['org'])
        app_key=get_app_key(app_name,space_name,org_name)
        if app_key.nil?
            return {:rescode=>-1,:msg=>"WARNING: This app has't been online yet"}
        end
        if add_domain_monitor?(app_key) and Noah3.domain_raw_completed?(app_key)
            return {:rescode=>0,:msg=>"true"}
        else
            return {:rescode=>0,:msg=>"false"}
        end
    end


    desc "check if an app is under instance num monitor"
    params do
        requires :space, type: String, desc: "space name"
        requires :org, type: String, desc: "org name"
        requires :app, type: String, desc: "app name without version"
    end
    get "/check/app_instance_num_check" do
        app_name=format(params['app'])
        space_name=format(params['space'])
        org_name=format(params['org'])
        app_key=get_app_key(app_name,space_name,org_name)
        if app_key.nil?
            return {:rescode=>-1,:msg=>"WARNING: This app has't been online yet"}
        end
        if add_instance_num_check?(app_name,space_name,org_name)
            return {:rescode=>0,:msg=>"true"}
        else
            return {:rescode=>0,:msg=>"false"}
        end
    end
    
    desc "instance num blance check between ng00 and ng01"
    get "/check/instance_num_blance_check_ng00_ng01" do
        result=[]
        running_apps_info=InstanceStatus.where(:state=>"RUNNING").where("cluster_num = ? or cluster_num = ? ","jpaas-ng00","jpaas-ng01")
        running_app_info=running_apps_info.select("distinct app_name,space,organization")
        running_app_info.each do |each_app|
            app_name=each_app.app_name
            organization=each_app.organization
            space=each_app.space
            instance_num_ng00=running_apps_info.where(:app_name=>app_name,:organization=>organization,:space=>space,:cluster_num=>"jpaas-ng00").count
            instance_num_ng01=running_apps_info.where(:app_name=>app_name,:organization=>organization,:space=>space,:cluster_num=>"jpaas-ng01").count
            if instance_num_ng00 != instance_num_ng01
               message={}
               message["app_name"]=app_name
               message["organization"]=organization
               message["space"]=space
               message["instance_num_ng00"]=instance_num_ng00
               message["instance_num_ng01"]=instance_num_ng01
               result << message
            end
        end
        result
    end

  end
end
