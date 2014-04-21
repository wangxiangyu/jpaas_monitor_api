class AddTableDomainMonitorRule < ActiveRecord::Migration
    def change
        create_table :domain_monitor_rule do |t|
            t.string :item_key
            t.string :name
            t.string :item_name
            t.string :filter
            t.string :alert
            t.string :rule_key
            t.timestamps
        end
    end
end
