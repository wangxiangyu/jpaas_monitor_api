class AddReqTypeToDomainMonitorItem < ActiveRecord::Migration
    def change
        change_table :domain_monitor_item do |t|
            t.string :req_type
        end
    end
end
