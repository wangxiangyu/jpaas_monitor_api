$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
require "rack/contrib"
module Acme
  class Collector < Grape::API
    use Rack::JSONP
    format :json
    namespace :collector do
        after do
            ActiveRecord::Base.clear_active_connections!
        end
        rescue_from :all do |e|
            error_response({ message: "Error occur: #{e.class.name}: #{e.message}" })
        end
        desc "collect instance meta"
        params do
            requires :state, type: String, desc: ""
            group :tags do
                requires :space_name, type: String, desc: ""
                requires :org_name, type: String, desc: ""
                requires :bns_node, type: String, desc: ""
            end
            requires :application_name, type: String, desc: ""
            requires :uris, type: Array, desc: ""
            requires :instance_index, type: String, desc: ""
            #requires :host, type: String, desc: ""
            #requires :cluster_num, type: String, desc: ""
            requires :warden_handle, type: String, desc: ""
            requires :warden_container_path, type: String, desc: ""
            requires :state_starting_timestamp, type: String, desc: ""
            group :params do
                requires :prod_ports, type: Hash, desc: ""
            end
            requires :noah_monitor_host_port, type: String, desc: ""
            requires :warden_host_ip, type: String, desc: ""
            requires :instance_id, type: String, desc: ""
            group :limits do
                requires :disk, type: String, desc: ""
                requires :mem, type: String, desc: ""
                requires :fds, type: String, desc: ""
            end
        end
        post '/collect_instance_meta' do
            instance_info={}
            instance_info['state']=params[:state]
            instance_info['time']=Time.now.to_i
            instance_info['host']="0.0.0.0"
            instance_info['space']=params[:tags][:space_name]
            instance_info['organization']=params[:tags][:org_name]
            instance_info['bns_node']=params[:tags][:bns_node]
            instance_info['app_name']=params[:application_name]
            instance_info['uris']=params[:application_uris].join(",")
            instance_info['instance_index']=params[:instance_index]
            instance_info['cluster_num']="unknown"
            instance_info['warden_handle']=params[:warden_handle]
            instance_info['warden_container_path']=params[:warden_container_path]
            instance_info['state_starting_timestamp']=params[:state_starting_timestamp]
            instance_info['port_info']=params[:params][:prod_ports].to_json.to_s
            instance_info['noah_monitor_port']=params[:noah_monitor_host_port]
            instance_info['warden_host_ip']=params[:warden_host_ip]
            instance_info['instance_id']=params[:instance_id]
            instance_info['disk_quota']=params[:limits][:disk]
            instance_info['mem_quota']=params[:limits][:mem]
            instance_info['fds_quota']=params[:limits][:fds]
            InstanceStatus.where(
                :instance_id=>instance_info['instance_id']
            ).first_or_create.update_attributes(instance_info)
        end
        desc "collect instance resource"
        params do
            requires :instance_id, type: String, desc: ""
            group :usage do
                requires :cpu, type: String, desc: ""
                requires :mem, type: String, desc: ""
                requires :fds, type: String, desc: ""
            end
        end
        post '/collect_instance_resource' do
            instance_info={}
            instance_info['instance_id']=params[:instance_id]
            instance_info['time']=Time.now.to_i
            instance_info['cpu_usage']=params[:usage][:cpu]
            instance_info['mem_usage']=params[:usage][:mem]
            instance_info['fds_usage']=params[:usage][:fds]
            InstanceStatus.where(
                :instance_id=>instance_info['instance_id']
            ).update_attributes(instance_info)
        end
        
        desc "instance existence check"
        params do
            requires :instance_id, type: String, desc: ""
        end
        get '/instance_existence_check' do
            instance_id=params[:instance_id]
            if InstanceStatus.where(:instance_id=>instance_id).empty?
                return {"status"=>"bad"}
            else
                return {"status"=>"ok"}
            end
        end
     
        route :any, '*path' do
            error! "unknown request: wiki http://wiki.babel.baidu.com/twiki/bin/view/Ps/OP/Xplat_mon_api"
        end
    end
  end
end
