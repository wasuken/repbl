class CreateRepoPaths < ActiveRecord::Migration[6.0]
  def change
    create_table :repo_paths do |t|
      t.references :repo, null: false, foreign_key: true
      t.references :path, null: false, foreign_key: true

      t.timestamps
    end
  end
end
