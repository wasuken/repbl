# coding: utf-8
require 'test_helper'
require 'json'

class Api::V1::ReposControllerTest < ActionDispatch::IntegrationTest
  include Zfs
  def repo_insert(url, title)
    repo = Repo.create(url: url, title: title)
    zfs_insert(remote_zip_to_zfs(url, ".*.md$"), repo.id)
  end
  test "should_get_index" do
    get("/api/v1/repos")
    assert_response :success
  end
  test "should_get_recommended" do
    repo_insert('https://github.com/wasuken/nippo/archive/master.zip', '日報')
    repo = Repo.all.first
    rf = Rfile
           .joins(:path)
           .joins("inner join repo_paths on repo_paths.path_id = paths.id")
           .where('repo_paths.repo_id = ?', repo.id)
           .select('rfiles.id as id')
           .first
    get("/api/v1/repos/recommended/#{repo.id}/#{rf.id}")
    assert_response :success
  end
  test "should_delete_repo" do
    tk = Token.gen_token.token
    id = Repo.create(url: "hoge", title: "hoge").id
    delete("/api/v1/repos/#{id}", params: {token: tk})
    assert_response :success
    assert Repo.where(id: id).size.zero?
  end
  test "should_post_repo" do
    tk = Token.gen_token.token
    before_size = Path.all.size
    post("/api/v1/repos",
         params: {url: 'https://github.com/wasuken/nippo/archive/master.zip',
                  title: '日報',
                  token: tk})
    assert_response :success
    repo = Repo.where(title: '日報').first
    assert before_size < Path.all.size
    assert !repo.nil?
  end
  test "should_post_repo_fail" do
    before_size = Path.all.size
    post("/api/v1/repos",
         params: {url: 'https://github.com/wasuken/nippo/archive/master.zip',
                  title: '日報'})
    assert_response 400
    repo = Repo.where(title: '日報').first
    assert before_size == Path.all.size
    assert repo.nil?
  end
  test "should_delete_repo_fail" do
    id = Repo.create(url: "hoge", title: "hoge").id
    delete("/api/v1/repos/#{id}")
    assert_response 400
    assert !Repo.where(id: id).size.zero?
  end
  test "should_get_show" do
    repo_insert('https://github.com/wasuken/nippo/archive/master.zip', '日報')
    repo = Repo.all.first
    get("/api/v1/repos/#{repo.id}")
    assert_response :success
  end
end
