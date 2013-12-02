$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
module Acme
  class Org < Grape::API
    format :txt
    desc "get organization list"
    get '/xplat_get_org_list' do
        cc_db=Mysql.real_connect(MyConfig.ccdb_host,MyConfig.ccdb_user,MyConfig.ccdb_passwd,MyConfig.ccdb_name)
        result=cc_db.query("select * from organizations")
        cc_db.close
        orgs=[]
        while org=result.fetch_hash
                orgs.push(org['name'])
        end
        orgs.to_json
    end
  end
end
