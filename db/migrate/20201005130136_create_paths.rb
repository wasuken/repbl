class CreatePaths < ActiveRecord::Migration[6.0]
  def change
    create_table :paths do |t|
      t.string :name
      t.references :path, null: true

      t.timestamps
    end
    add_foreign_key :paths, :paths
  end
end
