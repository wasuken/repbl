class CreateRfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :rfiles do |t|
      t.string :contents
      t.references :path, null: false, foreign_key: true

      t.timestamps
    end
  end
end
