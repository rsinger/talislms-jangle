# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090916145158) do

  create_table "harvest_borrowers", :force => true do |t|
    t.integer "borrower_id"
    t.integer "type_id"
    t.integer "status_id"
    t.date    "edit_date"
  end

  add_index "harvest_borrowers", ["borrower_id"], :name => "index_harvest_borrowers_on_borrower_id"
  add_index "harvest_borrowers", ["edit_date"], :name => "index_harvest_borrowers_on_edit_date"
  add_index "harvest_borrowers", ["status_id"], :name => "index_harvest_borrowers_on_status_id"
  add_index "harvest_borrowers", ["type_id"], :name => "index_harvest_borrowers_on_type_id"

  create_table "harvest_items", :force => true do |t|
    t.integer "item_id"
    t.integer "type_id"
    t.integer "status_id"
    t.date    "edit_date"
    t.string  "location_id"
    t.string  "item_type"
    t.integer "holding_id"
    t.string  "format_id"
  end

  add_index "harvest_items", ["edit_date"], :name => "index_harvest_items_on_edit_date"
  add_index "harvest_items", ["format_id"], :name => "index_harvest_items_on_format_id"
  add_index "harvest_items", ["holding_id"], :name => "index_harvest_items_on_holding_id"
  add_index "harvest_items", ["item_id"], :name => "index_harvest_items_on_item_id"
  add_index "harvest_items", ["item_type"], :name => "index_harvest_items_on_item_type"
  add_index "harvest_items", ["location_id"], :name => "index_harvest_items_on_location_id"
  add_index "harvest_items", ["status_id"], :name => "index_harvest_items_on_status_id"
  add_index "harvest_items", ["type_id"], :name => "index_harvest_items_on_type_id"

  create_table "harvest_works", :force => true do |t|
    t.integer "work_meta_id"
    t.date    "edit_date"
    t.boolean "suppress_from_index"
    t.boolean "suppress_from_opac"
  end

  add_index "harvest_works", ["edit_date"], :name => "index_harvest_works_on_edit_date"
  add_index "harvest_works", ["suppress_from_index"], :name => "index_harvest_works_on_suppress_from_index"
  add_index "harvest_works", ["suppress_from_opac"], :name => "index_harvest_works_on_suppress_from_opac"
  add_index "harvest_works", ["work_meta_id"], :name => "index_harvest_works_on_work_meta_id"

end
