# coding: utf-8
require 'test_helper'

class Api::V1::ReposControllerTest < ActionDispatch::IntegrationTest
  test "should_get_index" do
    get "/api/v1/repos"
    assert_response :success
  end
  test "should_post_repo" do
    post("/api/v1/repos",
         params: {url: 'https://github.com/wasuken/nippo/archive/master.zip', title: '日報'})
    assert_response :success
    repo = Repo.where(title: '日報').first
    assert !repo.nil?
  end
  test "should_delete_repo" do
    id = Repo.all.first.id
    delete("/api/v1/repo/#{id}")
    assert_response :success
    assert Repo.where(id: id).size.zero?
  end
end
