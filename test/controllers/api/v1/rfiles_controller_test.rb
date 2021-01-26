# coding: utf-8
require 'test_helper'

class Api::V1::RfilesControllerTest < ActionDispatch::IntegrationTest
  include Zfs
  def repo_insert(url, title)
    repo = Repo.create(url: url, title: title)
    zfs_insert(remote_zip_to_zfs(url, ".*.md$"), repo.id)
  end
  test "should_get_search_files" do
    repo_insert('https://github.com/wasuken/nippo/archive/master.zip', '日報')
    repo_id = Repo.all.first.id
    get("/api/v1/rfiles?query=git&repo_id=#{repo_id}")
    assert_response :success
  end
  test "should_get_search_files_fail" do
    repo_insert('https://github.com/wasuken/nippo/archive/master.zip', '日報')
    test_case_lst = [["", Repo.all.first.id], ["hoge"], [], "hoge", 9939024935943094353453]
    test_case_lst.each do |test_case|
      query, repo_id = test_case
      get("/api/v1/rfiles?query=#{query}&repo_id=#{repo_id}")
      assert_response 400
    end
  end
end
