class AddTableDomainMonitorAlert < ActiveRecord::Migration
    def change
        create_table :domain_monitor_alarm do |t|
            t.string :raw_key
            t.string :name
            t.string :mail
            t.string :sms
            t.timestamps
        end
    end
end
