# coding: utf-8
require 'test_helper'
require 'json'

class Api::V1::ReposControllerTest < ActionDispatch::IntegrationTest
  test "should_get_index" do
    get("/api/v1/repos")
    assert_response :success
  end
  test "should_post_repo" do
    before_size = Path.all.size
    post("/api/v1/repos",
         params: {url: 'https://github.com/wasuken/nippo/archive/master.zip', title: '日報'})
    assert_response :success
    repo = Repo.where(title: '日報').first
    assert before_size < Path.all.size
    assert !repo.nil?
  end
  test "should_delete_repo" do
    id = Repo.create(url: "hoge", title: "hoge").id
    delete("/api/v1/repos/#{id}")
    assert_response :success
    assert Repo.where(id: id).size.zero?
  end
  test "should_get_show" do
    post("/api/v1/repos",
         params: {url: "https://github.com/wasuken/nation-memo/archive/master.zip",
                  title: '日報'})
    repo = Repo.all.first
    get("/api/v1/repos/#{repo.id}")
    assert_response :success
  end
end
