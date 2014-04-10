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
            error_response({ message: "#{e.message}" })
        end
        desc "collect instance meta"
        params do
            requires :state, type: String, desc: "state"
            group :tags do
                requires :space_name, type: String, desc: "space_name"
                requires :org_name, type: String, desc: "org_name"
                requires :bns_node, type: String, desc: "bns_node"
            end
            requires :application_name, type: String, desc: "application_name"
            requires :application_uris, type: Array, desc: "uris"
            requires :instance_index, type: String, desc: "instance_index"
            #requires :host, type: String, desc: "host"
            requires :warden_handle, type: String, desc: "warden_handle"
            requires :warden_container_path, type: String, desc: "warden_container_path"
            requires :state_starting_timestamp, type: String, desc: "state_starting_timestamp"
            group :instance_meta do
                requires :prod_ports, type: Hash, desc: "prod_ports"
            end
            requires :noah_monitor_host_port, type: String, desc: "noah_monitor_host_port"
            requires :warden_host_ip, type: String, desc: "warden_host_ip"
            requires :instance_id, type: String, desc: "instance_id"
            group :limits do
                requires :disk, type: String, desc: "disk"
                requires :mem, type: String, desc: "mem"
                requires :fds, type: String, desc: "fds"
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
            instance_info['port_info']=params[:instance_meta][:prod_ports].to_json.to_s
            instance_info['noah_monitor_port']=params[:noah_monitor_host_port]
            instance_info['warden_host_ip']=params[:warden_host_ip]
            instance_info['instance_id']=params[:instance_id]
            instance_info['disk_quota']=params[:limits][:disk]
            instance_info['mem_quota']=params[:limits][:mem]
            instance_info['fds_quota']=params[:limits][:fds]
            InstanceStatus.where(
                :instance_id=>instance_info['instance_id']
            ).first_or_create.update_attributes(instance_info)
            return {:rescode=>0,:msg=>"ok"}
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
            result=InstanceStatus.where(:instance_id=>instance_info['instance_id'])
            if result.empty?
                return {:rescode=>-1,:msg=>"instance doesn't exist"}
            else
                result.first.update_attributes(instance_info)
                return {:rescode=>0,:msg=>"ok"}
            end
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
     
        desc "collect dea info"
        params do
            requires :uuid, type: String, desc: ""
            requires :ip, type: String, desc: ""
        end
        post '/collect_dea_info' do
           dea_info={}
           dea_info["uuid"]=params[:uuid]
           dea_info["ip"]=params[:ip]
           dea_info["cluster_num"]="unknown"
           dea_info["time"]=Time.now.to_i
           DeaList.where(
               :uuid=>dea_info["uuid"]
           ).first_or_create.update_attributes(dea_info)
           return {:rescode=>0,:msg=>"ok"}
        end

        route :any, '*path' do
            error! "unknown request: wiki http://wiki.babel.baidu.com/twiki/bin/view/Ps/OP/Xplat_mon_api"
        end
    end
  end
end
