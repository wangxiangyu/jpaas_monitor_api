class AddTableInstanceNumExpected < ActiveRecord::Migration
    def change
        create_table :instance_num_expected do |t|
            t.integer :app_id
            t.string :app_name
            t.string :cluster_num
            t.string :organization
            t.string :space
            t.integer :instance_num_expected
            t.timestamps
        end
    end
end
