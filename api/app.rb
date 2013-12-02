$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"

module Acme
  class App < Grape::API
    format :txt
    helpers do
      def remove_version(all)
          if all=~ /([^_]*)_(.*)/
               return /([^_]*)_(.*)/.match(all)[1]
          else
               return all
          end
      end
    end
    desc "get app list by space"
    get '/xplat_get_apps_by_space' do
	    space=params[:space].to_s.gsub("\"",'').gsub("'",'')
	    org=params[:org].to_s.gsub("\"",'').gsub("'",'')
        cc_db=Mysql.real_connect(MyConfig.ccdb_host,MyConfig.ccdb_user,MyConfig.ccdb_passwd,MyConfig.ccdb_name)
        org_id=cc_db.query("select * from organizations where name='#{org}'").fetch_hash['id']
        space_id=cc_db.query("select * from spaces where name='#{space}' and organization_id='#{org_id}'").fetch_hash['id']
        apps_info=cc_db.query("select * from apps where space_id='#{space_id}' and state='STARTED' and deleted_at is NULL")
        cc_db.close
        apps=[]
        while app=apps_info.fetch_hash
                app_info={}
                app_info['name']=app['name']
                app_info['app_key']=AppBns.where(:organization=>org,:space=>space,:app_name=>remove_version(app_info['name'])).first.app_key
                apps.push(app_info)
        end
        apps.to_json
    end
    desc "get instance list by app name"
    get '/xplat_get_instances_by_app' do
	    space=params[:space].to_s.gsub("\"",'').gsub("'",'')
	    org=params[:org].to_s.gsub("\"",'').gsub("'",'')
	    app=params[:app].to_s.gsub("\"",'').gsub("'",'')
        instances=[]
        InstanceStatus.where(:app_name=>app,:organization=>org,:space=>space).find_each do |instance|
                instance_hash=instance.serializable_hash
                instance_hash.delete("id")
                instance_hash.delete("created_at")
                instance_hash.delete("updated_at")
                port_info_json=JSON.parse(instance_hash['port_info'])
                instance_hash["port_info"]=port_info_json
                instances.push(instance_hash)
        end
        instances.to_json
    end
  end
end
