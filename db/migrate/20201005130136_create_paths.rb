class CreatePaths < ActiveRecord::Migration[6.0]
  def change
    create_table :paths do |t|
      t.string :name
      t.references :path, null: false, foreign_key: true

      t.timestamps
    end
    add_foreign_key :paths, :paths, on_delete: :cascade
  end
end
