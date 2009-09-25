class CreateHarvestBorrowers < ActiveRecord::Migration
  def self.up
    create_table :harvest_borrowers do |t|
      t.integer :borrower_id
      t.integer :type_id
      t.integer :status_id
      t.date :edit_date
    end

    add_index(:harvest_borrowers, :borrower_id)
    add_index(:harvest_borrowers, :edit_date)
    add_index(:harvest_borrowers, :type_id)
    add_index(:harvest_borrowers, :status_id)
  end

  def self.down
    drop_table :harvest_borrowers
  end
end
