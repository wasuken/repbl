class CreateRdirs < ActiveRecord::Migration[6.0]
  def change
    create_table :rdirs do |t|
      t.references :path, null: false, foreign_key: true
      t.timestamps
    end
    add_foreign_key :rdirs, :paths, on_delete: :cascade
  end
end
