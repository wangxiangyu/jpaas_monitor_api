$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "bns"
require "config"

module Acme
  class FlowTransfer < Grape::API
    format :txt
    helpers do
        def format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
        
        def add_host(all_hosts, host)
            if all_hosts == ""
                all_hosts = host
            else
                all_hosts = all_hosts + "," + host 
            end
	    end

       	def enable_service_instance(service_unit, machines, enable)
		    result=BNS.enable_instance({:serviceName=>service_unit,
                                :authKey=>MyConfig.bns_passwd,
				:machines=>machines                                
                                }, enable)
        end
    end

    desc "register bns of router for new app"
    get '/flow_transfer' do
      service_name=format(params['service_name'])
      flow_tansfer_to = format(params['cluster'])
      if service_name.empty?
        return {:rescode=>-1,:msg=>"please specify service_name"}.to_json
      end
      service_unit1="#{service_name.downcase}-jpaas01.JPaaS.all"
      service_unit2="#{service_name.downcase}-jpaas02.JPaaS.all" 
      to_be_enable1 = to_be_disable1 = to_be_enable2 = to_be_disable2 = ""
      if flow_tansfer_to == "0"
          MyConfig.routerlist1.each do |host,disable|
            if disable == 1
                to_be_disable1 = add_host(to_be_disable1, host)
            elsif disable == 0
                to_be_enable1 = add_host(to_be_enable1, host)
            end
          end
          MyConfig.routerlist2.each do |host,disable|
              if disable == 1
                  to_be_disable2 = add_host(to_be_disable2, host)
              elsif disable == 0
                  to_be_enable2 = add_host(to_be_enable2, host)
              end
          end
      elsif flow_tansfer_to == "1"
          MyConfig.routerlist1.each do |host,disable|
            if disable == 1
                to_be_disable1 = add_host(to_be_disable1, host)
            elsif disable == 0
                to_be_enable1 = add_host(to_be_enable1, host)
            end
          end
          MyConfig.routerlist2.each do |host,disable|
	          if disable == 1
                  to_be_enable2 = add_host(to_be_enable2, host) 
              elsif disable == 0
                  to_be_disable2 = add_host(to_be_disable2, host)
              end
	      end
      elsif flow_tansfer_to == "2"
          MyConfig.routerlist1.each do |host,disable|
             if disable == 1
                 to_be_enable1 = add_host(to_be_enable1, host)
             elsif disable == 0
                to_be_disable1 = add_host(to_be_disable1, host)
             end 
          end
          MyConfig.routerlist2.each do |host,disable|
             if disable == 1
                 to_be_disable2 = add_host(to_be_disable2, host)
             elsif disable == 0
                 to_be_enable2 = add_host(to_be_enable2, host)
             end
          end
      end
      result1 = enable_service_instance(service_unit1, to_be_enable1, "enable")
      result2 = enable_service_instance(service_unit1, to_be_disable1, "disable")
      result3 = enable_service_instance(service_unit2, to_be_enable2, "enable")
      result4 = enable_service_instance(service_unit2, to_be_disable2, "disable")
      if result1["retCode"] == 0 && result2["retCode"] == 0 && result3["retCode"] == 0 && result4["retCode"] == 0
          return {:rescode=>0,:msg=>"Successfully update service unit. "}.to_json
      else
          return {:rescode=>-1,:msg=>"Error: failed to update service unit."}.to_json
      end
    end

  end
end
