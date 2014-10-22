$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
require "rack/contrib"

module Acme
  class App < Grape::API
    use Rack::JSONP
    format :json
    helpers do
        def params_format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
    end
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
        optional :state, type: String, desc: "app state", default: "RUNNING"
        optional :cluster, type: String, desc: "cluster"
        optional :start, type: String, desc: "result start index",default: "0"
        optional :end, type: String, desc: "result end index",default: "99999999"
        optional :result_size, type: String, desc: "need result size or not, not nil for yes",default: nil
    end
    get '/xplat_get_instances_by_app' do
	    space=params[:space].to_s.gsub("\"",'').gsub("'",'')
	    org=params[:org].to_s.gsub("\"",'').gsub("'",'')
	    app=params[:app].to_s.gsub("\"",'').gsub("'",'')
        cluster=params[:cluster].nil? ? nil : params[:cluster].to_s.gsub("\"",'').gsub("'",'')
        state=params[:state].nil? ? "RUNNING" : params[:state].to_s.gsub("\"",'').gsub("'",'')
        start_index=params_format(params[:start])
        end_index=params_format(params[:end])
        result_size=params[:result_size]
        instances=[]
        if cluster.nil?
            instances_result=InstanceStatus.where("state = ? and app_name like ? and organization = ?  and space = ?",state,"#{app}\\_%",org,space).order('created_at DESC').all
        else
            instances_result=InstanceStatus.where("cluster_num = ? and state = ? and app_name like ? and organization = ?  and space = ?",cluster,state,"#{app}\\_%",org,space).order('created_at DESC').all
        end
        size=instances_result.size
        instances_result[start_index.to_i..end_index.to_i].to_a.each do |instance|
                instance_hash=instance.serializable_hash
                instance_hash.delete("id")
                instance_hash.delete("created_at")
                instance_hash.delete("updated_at")
		        port_info_json={}
                port_info_json=JSON.parse(instance_hash['port_info']) if instance_hash['port_info']!='null'
                instance_hash["port_info"]=port_info_json
                instances.push(instance_hash)
        end
        instances
        if result_size.nil?
            return instances
        else
            return {:size=>size,:data=>instances}
        end
    end
    desc "get instance list by org and space"
    params do
        requires :space, type: String, desc: "space name"
        requires :org, type: String, desc: "org name"
    end
    get '/xplat_get_instances_by_org_space' do
	    space=params[:space].to_s.gsub("\"",'').gsub("'",'')
	    org=params[:org].to_s.gsub("\"",'').gsub("'",'')
        cluster=params[:cluster].nil? ? nil : params[:cluster].to_s.gsub("\"",'').gsub("'",'')
        state=params[:state].nil? ? "RUNNING" : params[:state].to_s.gsub("\"",'').gsub("'",'')
        instances=[]
        if cluster.nil?
            instances_result=InstanceStatus.where("state = ? and organization = ?  and space = ?",state,org,space)
        else
            instances_result=InstanceStatus.where("cluster_num = ? and state = ? and organization = ?  and space = ?",cluster,state,org,space)
        end
        instances_result.find_each do |instance|
                instance_hash=instance.serializable_hash
                instance_hash.delete("id")
                instance_hash.delete("created_at")
                instance_hash.delete("updated_at")
		port_info_json={}
                port_info_json=JSON.parse(instance_hash['port_info']) if instance_hash['port_info']!='null'
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
        InstanceStatus.where("state = ? and host = ?",'RUNNING',dea_ip).find_each do |instance|
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

    desc "get app name by warden handle"
    params do
        requires :warden_handle, type: String, desc: "warden handle"
    end
    get '/get_detail_instance_info_by_warden_handle' do
	    warden_handle=params[:warden_handle].to_s.gsub("\"",'').gsub("'",'')
        result=''
        if params[:matrix]
            InstanceStatus.where(:warden_handle=>warden_handle,:state=>"RUNNING").find_each do |instance|
                result=instance.serializable_hash
                result.delete("id")
                result.delete("created_at")
                result.delete("updated_at")
                port_info_json={}
                port_info_json=JSON.parse(result['port_info']) if result['port_info']!='null'
                result["port_info"]=port_info_json
            end
        else
            InstanceStatus.where(:warden_handle=>warden_handle).find_each do |instance|
                result=instance.serializable_hash
                result.delete("id")
                result.delete("created_at")
                result.delete("updated_at")
	        port_info_json={}
                port_info_json=JSON.parse(result['port_info']) if result['port_info']!='null'
                result["port_info"]=port_info_json
            end
        end
        result
    end

    desc "get app name by instance id"
    params do
        requires :instance_id, type: String, desc: "instance id"
    end
    get '/get_resource_usage_info_by_instance_id' do
	    instance_id=params[:instance_id].to_s.gsub("\"",'').gsub("'",'')
        result=''
        InstanceStatus.where(:instance_id=>instance_id).find_each do |instance|
            disk_quota_MB=instance.disk_quota.to_f
            mem_quota_MB=instance.mem_quota.to_f
            cpu_usage_percentage=format("%.2f",instance.cpu_usage.to_f*100).to_f
            mem_usage_MB=format("%.2f",instance.mem_usage.to_f).to_f
            disk_usage_MB=format("%.2f",instance.disk_usage.to_f/1024).to_f
            mem_usage_percentage=format("%.2f",mem_usage_MB/mem_quota_MB*100).to_f
            disk_usage_percentage=format("%.2f",disk_usage_MB/disk_quota_MB*100).to_f
            result=["mem_quota_MB:#{mem_quota_MB}","disk_quota_MB:#{disk_quota_MB}","cpu_usage_percentage:#{cpu_usage_percentage}","mem_usage_MB:#{mem_usage_MB}","disk_usage_MB:#{disk_usage_MB}","mem_usage_percentage:#{mem_usage_percentage}","disk_usage_percentage:#{disk_usage_percentage}"].join(" ")
        end
        result
    end

    desc "get app bns by app key"
    params do
        requires :app_key, type: String, desc: "app key"
    end
    get '/get_app_bns_by_app_key' do
	    app_key=params[:app_key].to_s.gsub("\"",'').gsub("'",'')
        app_bns_info=AppBns.where(:app_key=>app_key)
        if app_bns_info.empty?
            return {:rescode=>-1,:msg=>"Error: the app doesn't exist"}
        else
            app_bns=app_bns_info.first.name
            return {:rescode=>0,:msg=>{:app_bns=>app_bns}}
        end
    end

    desc "get app name by application_id"
    params do
        requires :application_id, type: String, desc: "application id"
    end
    get '/get_app_name_by_application_id' do
	    application_id=params[:application_id].to_s.gsub("\"",'').gsub("'",'')
        app_info=InstanceStatus.where(:application_id=>application_id)
        if app_info.empty?
            return {:rescode=>-1,:msg=>"Error: the app doesn't exist"}
        else
            app_name=app_info.first.app_name
            return {:rescode=>0,:msg=>{:app_name=>app_name}}
        end
    end
    

  end
end
