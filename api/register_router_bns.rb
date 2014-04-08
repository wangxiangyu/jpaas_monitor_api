$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "bns"
require "config"
require "rack/contrib"

module Acme
  class RegisterRouterBns < Grape::API
    use Rack::JSONP
    format :json
    helpers do
        def format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
        def add_service_unit(service_noah_path,service_unit)
            result=BNS.create_bns({:parentPath=>service_noah_path,:authKey=>MyConfig.bns_passwd,:nodeName=>service_unit,:runUser=>'work'})
            if result['retCode'] == 0
               return {:rescode=>0,:msg=>"Successfully create service unit: #{service_unit} under service: #{service_noah_path}. "}
            else
               return {:rescode=>-1,:msg=>"Error: failed to create service unit: #{service_unit} under service: #{service_noah_path}: #{result['msg']}. "}
            end
        end
        def add_instance_to_service_unit(host,disable,service_unit)
            result=BNS.add_instance_bns({:serviceName=>service_unit,
                                :authKey=>MyConfig.bns_passwd,
                                :hostName=>host,
                                :port=>{"main"=>80}.to_json,
                                :tag=>'interface:clientip,keepalive:0,weight:10',
                                :disable=>disable,
                                :status=>0,
                                :deployPath=>'',
                                :runUser=>'work',
                                :healthCheckCmd=>'port:80',
                                :healthCheckType=>'proc'
                                })
                if result["retCode"] == 0
                    return {:rescode=>0,:msg=>"Successfully add #{host} to service unit #{service_unit}. "}
                else
                    return {:rescode=>0,:msg=>"Error: failed to add #{host} to service unit #{service_unit}: #{result['msg']}. "}
                end
        end
    end

    after do
        ActiveRecord::Base.clear_active_connections!
    end
    desc "register bns of router for new app"
    params do
        requires :service_name, type: String, desc: "app name without version"
    end
    get '/register_router_bns_for_app' do
        service_name=format(params['service_name'])
        if service_name.empty?
            return {:rescode=>-1,:msg=>"please specify service_name"}
        end
        response=""
        rescode=0
        service_noah_path="BAIDU_ECOM_SDC_JPaaS_APP_"+service_name.upcase 
        service_unit1="#{service_name.downcase}-jpaas01.JPaaS.all"
        service_unit2="#{service_name.downcase}-jpaas02.JPaaS.all"
        result=add_service_unit(service_noah_path,service_unit1)
        rescode=-1 if result[:rescode] !=0
        response << result[:msg]
        result=add_service_unit(service_noah_path,service_unit2)
        rescode=-1 if result[:rescode] !=0
        response << result[:msg]
        MyConfig.routerlist1.each do |host,disable|       
                result=add_instance_to_service_unit(host,disable,service_unit1)
                rescode=-1 if result[:rescode] !=0
                response << result[:msg]
        end
        MyConfig.routerlist2.each do |host,disable|       
                result=add_instance_to_service_unit(host,disable,service_unit2)
                rescode=-1 if result[:rescode] !=0
                response << result[:msg]
        end
        return {:rescode=>rescode,:msg=>response}
    end
  end
end
