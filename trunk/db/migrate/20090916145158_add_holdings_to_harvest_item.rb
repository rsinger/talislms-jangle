class AddHoldingsToHarvestItem < ActiveRecord::Migration
  def self.up
    add_column :harvest_items, :location_id, :string
    add_column :harvest_items, :item_type, :string
    add_column :harvest_items, :holding_id, :integer
    add_column :harvest_items, :format_id, :string
    add_index(:harvest_items, :location_id)
    add_index(:harvest_items, :item_type)
    add_index(:harvest_items, :holding_id)
    add_index(:harvest_items, :format_id)
  end

  def self.down
    remove_column :harvest_items, :location_id, :string
    remove_column :harvest_items, :item_type, :string
    remove_column :harvest_items, :holding_id, :integer
    remove_column :harvest_items, :format_id, :string
    remove_index(:harvest_items, :location_id)
    remove_index(:harvest_items, :item_type)
    remove_index(:harvest_items, :holding_id)
    remove_index(:harvest_items, :format_id)    
  end
end