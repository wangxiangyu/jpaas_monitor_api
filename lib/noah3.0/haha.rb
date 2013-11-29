require "active_record"
require "/home/work/dashboard/collector/lib/collector/database"
require "/home/work/dashboard/collector/lib/collector/noah3.0/noah3.0"
require "pp"
#params={}
#params['app_key']='123456'
#params['name']='test'
#params['cycle']='10'
#params['method']='noah'
#params['target']='logmon'
#params['params']='${ATTACHMENT_DIR}/log.conf'
#params['log_filepath']='${DEPLOY_DIR}/haha/error.log'
#params['raw_key']='678910'
#params['limit_rate']='10'
#LogMonitorRaw.create(params)


#params={}
#params['raw_key']='678910'
#params['item_name_prefix']='test1'
#params['cycle']='60'
#params['match_str']='FATAL'
#params['item_key']='abcdef'
#LogMonitorItem.create(params)

#params={}
#params['item_key']='abcdef'
#params['name']='test_fatal'
#params['formula']='test1_cnt>15'
#params['filter']='2/4'
#params['alert']='hahawang'
#LogMonitorRule.create(params)

result=LogMonitorRaw.where("app_key=123456").find_each do |rec|
        pp rec.to_json
end
#pp result.class
