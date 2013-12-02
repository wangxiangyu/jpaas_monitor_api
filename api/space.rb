$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"

module Acme
  class Space < Grape::API
    format :txt
    desc "get the spaces belong to one org"
    get '/xplat_get_space_by_org' do
        org=params[:org].to_s.gsub("\"",'').gsub("'",'')
        cc_db=Mysql.real_connect(MyConfig.ccdb_host,MyConfig.ccdb_user,MyConfig.ccdb_passwd,MyConfig.ccdb_name)
        org_id=cc_db.query("select * from organizations where name='#{org}'").fetch_hash['id']
        spaces_info=cc_db.query("select * from spaces where organization_id='#{org_id}'")
        cc_db.close
        spaces=[]
        while space=spaces_info.fetch_hash
                spaces.push(space['name'])
        end
        spaces.to_json
    end
  end
end
