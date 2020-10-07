# coding: utf-8
require 'test_helper'

class Api::V1::ReposControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_repos_index_url
    assert_response :success
  end
  test "should post repos" do
    post(api_v1_repos_index_url,
         params: {url: 'https://github.com/wasuken/nippo', title: '日報'})
    assert_response :success
  end
  test "should delete repos" do
    id = Repo.first.id
    delete("/api/v1/repo/#{id}")
    assert_response :success
    assert Repo.find(id).nil?
  end
end
