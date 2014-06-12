$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
require "rack/contrib"

module Acme
  class App < Grape::API
    use Rack::JSONP
    format :json
    after do
         ActiveRecord::Base.clear_active_connections!
    end
    desc "get app list by space"
    params do
        requires :space, type: String, desc: "space name"
        requires :org, type: String, desc: "org name"
    end
    get '/xplat_get_apps_by_space' do
	    space=params[:space].to_s.gsub("\"",'').gsub("'",'')
	    org=params[:org].to_s.gsub("\"",'').gsub("'",'')
        apps=[]
        AppBns.where(:organization=>org,:space=>space).find_each do |app|
            app_info={}
            app_info['name']=app.app_name
            app_info['app_key']=app.app_key
            apps.push(app_info)
        end
        apps
    end
    desc "get instance list by app name"
    params do
        requires :space, type: String, desc: "space name"
        requires :org, type: String, desc: "org name"
        requires :app, type: String, desc: "app name without version"
    end
    get '/xplat_get_instances_by_app' do
	    space=params[:space].to_s.gsub("\"",'').gsub("'",'')
	    org=params[:org].to_s.gsub("\"",'').gsub("'",'')
	    app=params[:app].to_s.gsub("\"",'').gsub("'",'')
        instances=[]
        InstanceStatus.where("app_name like ? and organization = ?  and space = ?","#{app}\\_%",org,space).find_each do |instance|
                instance_hash=instance.serializable_hash
                instance_hash.delete("id")
                instance_hash.delete("created_at")
                instance_hash.delete("updated_at")
                port_info_json=JSON.parse(instance_hash['port_info'])
                instance_hash["port_info"]=port_info_json
                instances.push(instance_hash)
        end
        instances
    end
    desc "get instance list by org and space"
    params do
        requires :space, type: String, desc: "space name"
        requires :org, type: String, desc: "org name"
    end
    get '/xplat_get_instances_by_org_space' do
	    space=params[:space].to_s.gsub("\"",'').gsub("'",'')
	    org=params[:org].to_s.gsub("\"",'').gsub("'",'')
        instances=[]
        InstanceStatus.where("organization = ?  and space = ?",org,space).find_each do |instance|
                instance_hash=instance.serializable_hash
                instance_hash.delete("id")
                instance_hash.delete("created_at")
                instance_hash.delete("updated_at")
                port_info_json=JSON.parse(instance_hash['port_info'])
                instance_hash["port_info"]=port_info_json
                instances.push(instance_hash)
        end
        instances
    end
    desc "get app list by dea ip"
    params do
        requires :dea_ip, type: String, desc: "dea_ip"
    end
    get '/get_app_list_by_dea_ip' do
	    dea_ip=params[:dea_ip].to_s.gsub("\"",'').gsub("'",'')
        apps=[]
        InstanceStatus.where("host = ?",dea_ip).find_each do |instance|
            apps.push(instance.app_name) unless apps.include?(instance.app_name)
        end
        apps
    end
    desc "get app name by warden handle"
    params do
        requires :warden_handle, type: String, desc: "warden handle"
    end
    get '/get_instance_info_by_warden_handle' do
	    warden_handle=params[:warden_handle].to_s.gsub("\"",'').gsub("'",'')
        result=''
        InstanceStatus.where(:warden_handle=>warden_handle).find_each do |instance|
            instance_info=instance.serializable_hash
            app_name=instance_info['app_name'].split('_')[0]
            app_space=instance_info['space']
            app_org=instance_info['organization']
            app_cluster=instance_info['cluster_num']
            result=app_name+' '+app_space+' '+app_org+' '+app_cluster
        end
        result
    end
  end
end
