require "digest"
$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"
require "rack/contrib"
require "net/http"

module Acme
  class MonitorBlock < Grape::API
    use Rack::JSONP
    format :json
    helpers do
        def format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
    end
    namespace :monitor_block do
        desc "block monitor"
        params do
            requires :bns, type: String, desc: "bns"
            requires :time, type: Integer, desc: "time" 
        end
        get '/block' do
            bns=format(params['bns'])
            time=format(params['time'])
            result=`/home/work/dashboard/jpaas_monitor_api/lib/montool.py -b #{bns} -d #{time} 2>&1`
            if result=~/^OK/
                return {:rescode=>0,:msg=>"ok"}
            else
                return {:rescode=>-1,:msg=>"Failed: #{result.gsub("\n",' ').gsub("\t",' ')}"}
            end
        end

        desc "unblock monitor"
        params do
            requires :bns, type: String, desc: "bns"
        end
        get '/unblock' do
            bns=format(params['bns'])
            result=`/home/work/dashboard/jpaas_monitor_api/lib/montool.py -u #{bns} 2>&1`
            if result=~/^OK/
                return {:rescode=>0,:msg=>"ok"}
            else
                return {:rescode=>-1,:msg=>"Failed: #{result.gsub("\n",' ').gsub("\t",' ')}"}
            end
        end

        desc "query about monitor"
        params do
            requires :bns, type: String, desc: "bns"
        end
        get '/query' do
            bns=format(params['bns'])
            result=`/home/work/dashboard/jpaas_monitor_api/lib/montool.py -s #{bns} 2>&1`
            if result.include?("blocked") or result.include?("unblocked")
                if result.include?("unblocked")
                    return {:rescode=>0,:msg=>{:block=>'no'}}
                else
                    time=result.match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/).to_s
                    return {:rescode=>0,:msg=>{:block=>'yes',:time=>time}}
                end
            else
                return {:rescode=>-1,:msg=>"Failed: #{result.gsub("\n",' ').gsub("\t",' ')}"}
            end
        end

        desc "block domain monitor"
        params do
            requires :cluster, type: String, desc: "cluster"
            requires :time, type: Integer, desc: "time" 
        end
        get '/block_domain_monitor' do
            cluster=format(params['cluster'])
            time=format(params['time'])
	        domains=JSON.parse(Net::HTTP.get('10.50.34.43','/api/domains',8775))
            msg=[]
	        domains["datas"][cluster].each do |domain|
		    result=JSON.parse(Net::HTTP.get("monitor.jpaas.baidu.com","/monitor_block/block?bns=#{domain}&time=#{time}",8002))
		    msg << "#{domain}: #{result['msg']}"
	    end
	        return {:rescode=>0,:msg=>msg}
        end


        desc "unblock domain monitor"
        params do
            requires :cluster, type: String, desc: "cluster"
        end
        get '/unblock_domain_monitor' do
            cluster=format(params['cluster'])
	        domains=JSON.parse(Net::HTTP.get('10.50.34.43','/api/domains',8775))
            msg=[]
	        domains["datas"][cluster].each do |domain|
		    result=JSON.parse(Net::HTTP.get("monitor.jpaas.baidu.com","/monitor_block/unblock?bns=#{domain}",8002))
		    msg << "#{domain}: #{result['msg']}"
	    end
	        return {:rescode=>0,:msg=>msg}
        end

        desc "query domain monitor"
        params do
            requires :cluster, type: String, desc: "cluster"
        end
        get '/query_domain_monitor' do
            cluster=format(params['cluster'])
	        domains=JSON.parse(Net::HTTP.get('10.50.34.43','/api/domains',8775))
            msg=[]
	        domains["datas"][cluster].each do |domain|
		    result=JSON.parse(Net::HTTP.get("monitor.jpaas.baidu.com","/monitor_block/query?bns=#{domain}",8002))
		    msg << "#{domain}: #{result['msg']}"
	    end
	        return {:rescode=>0,:msg=>msg}
        end
    end
  end
end
