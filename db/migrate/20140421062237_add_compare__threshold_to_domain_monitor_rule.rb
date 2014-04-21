class AddCompareThresholdToDomainMonitorRule < ActiveRecord::Migration
  def change
      change_table :domain_monitor_rule do |t|
          t.string :compare
          t.string :threshold
      end
  end
end
