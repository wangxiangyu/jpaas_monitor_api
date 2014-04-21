class AddTableDomainMonitorItem < ActiveRecord::Migration
    def change
        create_table :domain_monitor_item do |t|
            t.string :raw_key
            t.string :name
            t.string :cycle
            t.string :req_content
            t.string :res_check
            t.string :mon_idc
            t.string :item_key
            t.timestamps
        end
    end
end
