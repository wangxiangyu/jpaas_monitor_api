$:.unshift(File.expand_path("./", File.dirname(__FILE__)))
require "myhttp"
require "json"

    class BNS
        class << self
            #params: parentPath,authKey,nodeName,runUser
            def create_bns(params)
                sleep 0.5
                params.merge!('r'=>'bns/Create')
                JSON.parse(Http.http_get("noah.baidu.com","/webfoot/index.php",params))
            end

            #params: serviceName,authKey,hostName,port,tag,disable,
            #        status,deployPath,runUser,healthCheckCmd,healthCheckType
            def add_instance_bns(params)
                sleep 0.5
                params.merge!('r'=>'bns/AddInstance')
                JSON.parse(Http.http_get("noah.baidu.com","/webfoot/index.php",params))
            end

            #params: serviceName,authKey,hostName,instanceId
            def del_instance_bns(params)
                sleep 0.5
                params.merge!('r'=>'bns/DeleteInstance')
                JSON.parse(Http.http_get("noah.baidu.com","/webfoot/index.php",params))
            end

            #params: serviceName,authKey,hostname,instanceId,port,tag,disable,
            #       status,deployPath,runUser,healthCheckCmd,healthCheckType
            #NOTE: we don't support bns update now, so if you change it 
            #       first del the old one,then add the new one
            def update_instance_bns(params)
                sleep 0.5
                params.merge!('r'=>'webfoot/ModifyInstanceInfo')
                params.merge!('operation'=>'update')
                instance_info_string=query_instance_string_bns(params)
                params.merge!('instanceInfo'=>instance_info_string)
                JSON.parse(Http.http_get("noah.baidu.com","/webfoot/index.php",params))
            end


            #params: serviceName,instanceId
            def query_instance_string_bns(params)
                sleep 0.5
                params.merge!('r'=>'webfoot/GetInstanceInfo')
                instanceStr=JSON.parse(Http.http_get("noah.baidu.com","/webfoot/index.php",params))['instanceStr']
                instanceStr_array=instanceStr.split("\n")
                instanceStr_array.each do |info|
                    return info if info.include?("instanceId=#{params[:instanceId]}")
                end
                ''
            end

            #params: serviceName,instanceId
            def query_instance_hash_bns(params)
                sleep 0.5
                params.merge!('r'=>'webfoot/GetInstanceInfo')
                instanceInfo=JSON.parse(Http.http_get("noah.baidu.com","/webfoot/index.php",params))['instanceInfo']
                instanceInfo.each do |info|
                    return info if info['offset'] ==params[:instanceId]
                end
                {}
            end

            #params: serviceName
            def query_all_instance_hash_bns(params)
                sleep 0.5
                params.merge!('r'=>'webfoot/GetInstanceInfo')
                JSON.parse(Http.http_get("noah.baidu.com","/webfoot/index.php",params))['instanceInfo']
            end
        end
    end

