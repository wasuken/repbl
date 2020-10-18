# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_10_18_135440) do

  create_table "paths", force: :cascade do |t|
    t.string "name"
    t.integer "path_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["path_id"], name: "index_paths_on_path_id"
  end

  create_table "rdirs", force: :cascade do |t|
    t.integer "path_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["path_id"], name: "index_rdirs_on_path_id"
  end

  create_table "repo_paths", force: :cascade do |t|
    t.integer "repo_id", null: false
    t.integer "path_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["path_id"], name: "index_repo_paths_on_path_id"
    t.index ["repo_id"], name: "index_repo_paths_on_repo_id"
  end

  create_table "repos", force: :cascade do |t|
    t.string "title"
    t.string "url"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "rfiles", force: :cascade do |t|
    t.string "contents"
    t.integer "path_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["path_id"], name: "index_rfiles_on_path_id"
  end

  create_table "tokens", force: :cascade do |t|
    t.string "token", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "paths", "paths"
  add_foreign_key "rdirs", "paths"
  add_foreign_key "rdirs", "paths", on_delete: :cascade
  add_foreign_key "repo_paths", "paths"
  add_foreign_key "repo_paths", "paths", on_delete: :cascade
  add_foreign_key "repo_paths", "repos"
  add_foreign_key "repo_paths", "repos", on_delete: :cascade
  add_foreign_key "rfiles", "paths"
  add_foreign_key "rfiles", "paths", on_delete: :cascade
end
