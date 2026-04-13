require 'test_helper'

class UploadsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def admin_user
    users(:washington)
  end

  test "rejects unauthenticated requests" do
    post "/uploads", params: { file: fixture_file_upload("test_image.png", "image/png") }
    assert_redirected_to new_user_session_path
  end

  test "returns 422 when no file is provided" do
    sign_in admin_user
    post "/uploads"
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal "No file provided", body["error"]
  end

  test "uploads image and returns url + html + type" do
    sign_in admin_user
    post "/uploads", params: { file: fixture_file_upload("test_image.png", "image/png") }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal "image", body["type"]
    assert_match %r{^/images/raw/\d+/test_image\.png$}, body["url"]
    assert_includes body["html"], "<img"
  end

  test "uploads audio and returns audio html" do
    sign_in admin_user
    post "/uploads", params: { file: fixture_file_upload("test_audio.mp3", "audio/mpeg") }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal "audio", body["type"]
    assert_includes body["html"], "<audio"
  end

  test "uploads video and returns video html" do
    sign_in admin_user
    post "/uploads", params: { file: fixture_file_upload("test_video.mp4", "video/mp4") }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal "video", body["type"]
    assert_includes body["html"], "<video"
  end
end
