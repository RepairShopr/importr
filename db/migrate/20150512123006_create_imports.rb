class CreateImports < ActiveRecord::Migration
  def change
    create_table :imports do |t|
      t.string :api_key
      t.string :resource_type
      t.text :mapping
      t.integer :record_count
      t.integer :success_count
      t.integer :error_count

      t.timestamps null: false
    end
  end
end
