class AddDiskUsageToInstanceStatus < ActiveRecord::Migration
  def change
      change_table :instance_status do |t|
          t.string :disk_usage
      end
  end
end
