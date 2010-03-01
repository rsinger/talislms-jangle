class CreateHarvestWorks < ActiveRecord::Migration
  def self.up
    create_table :harvest_works do |t|
      t.integer :work_meta_id
      t.date :edit_date
      t.boolean :suppress_from_index
      t.boolean :suppress_from_opac      
    end
    add_index(:harvest_works, :work_meta_id)
    add_index(:harvest_works, :edit_date)
    add_index(:harvest_works, :suppress_from_index)
    add_index(:harvest_works, :suppress_from_opac)

  end

  def self.down
    drop_table :harvest_works
  end
end
