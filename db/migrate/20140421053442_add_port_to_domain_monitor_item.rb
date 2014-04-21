class AddPortToDomainMonitorItem < ActiveRecord::Migration
  def change
      change_table :domain_monitor_item do |t|
          t.string :port
      end
  end
end
