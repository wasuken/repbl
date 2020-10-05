class CreateRdirs < ActiveRecord::Migration[6.0]
  def change
    create_table :rdirs do |t|
      t.references :path, null: false, foreign_key: true

      t.timestamps
    end
  end
end
