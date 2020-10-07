class CreateRepoPaths < ActiveRecord::Migration[6.0]
  def change
    create_table :repo_paths do |t|
      t.references :repo, null: false, foreign_key: true
      t.references :path, null: false, foreign_key: true

      t.timestamps
    end
    add_foreign_key :repo_paths, :repos, on_delete: :cascade
    add_foreign_key :repo_paths, :paths, on_delete: :cascade
  end
end
