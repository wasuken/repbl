class CreatePaths < ActiveRecord::Migration[6.0]
  def change
    create_table :paths do |t|
      t.string :name
      t.references :path, null: false, foreign_key: true

      t.timestamps
    end
  end
end
