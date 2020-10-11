require 'test_helper'

class Api::V1::RfilesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get api_v1_rfiles_show_url
    assert_response :success
  end

end
