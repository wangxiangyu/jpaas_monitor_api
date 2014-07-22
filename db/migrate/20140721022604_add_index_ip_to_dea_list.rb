class AddIndexIpToDeaList < ActiveRecord::Migration
    def change
        add_index(:dea_list, :ip)
    end
end
