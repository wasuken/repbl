class CreateRfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :rfiles do |t|
      t.string :contents
      t.references :path, null: false, foreign_key: true

      t.timestamps
    end
    add_foreign_key :rfiles, :paths, on_delete: :cascade, name: "fk_rfiles_paths"
  end
end
