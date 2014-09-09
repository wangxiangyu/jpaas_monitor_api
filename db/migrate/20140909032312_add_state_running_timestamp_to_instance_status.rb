class AddStateRunningTimestampToInstanceStatus < ActiveRecord::Migration
  def change
      change_table :instance_status do |t|
          t.string :state_running_timestamp
      end
  end
end
