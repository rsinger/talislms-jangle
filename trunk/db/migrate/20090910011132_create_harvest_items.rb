class CreateHarvestItems < ActiveRecord::Migration
  def self.up
    create_table :harvest_items do |t|
      t.integer :item_id
      t.integer :type_id
      t.integer :status_id
      t.date :edit_date
    end
    add_index(:harvest_items, :item_id)
    add_index(:harvest_items, :edit_date)
    add_index(:harvest_items, :type_id)
    add_index(:harvest_items, :status_id)
  end

  def self.down
    drop_table :harvest_items
  end
end
