class AddToDelCntToInstanceStatus < ActiveRecord::Migration
  def change
      change_table :instance_status do |t|
          t.integer :to_del_cnt, default: 3
      end
  end
end
