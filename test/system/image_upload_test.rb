require "application_system_test_case"
require_relative 'systemtest_helpers.rb'

class ImageUploadTest < ApplicationSystemTestCase
  test "upload image and validate display" do
    admin_user = { email: "george@washington.com", pass: "georgepass" }

    log_in_with admin_user
    click_on "New Post Button"

    fill_in "post_title", with: "Image test"
    fill_in_editor "This is a test post with an image."

    attach_media_file Rails.root.join('test', 'fixtures', 'files', 'test_image.png'),
                      match: "test_image.png"

    click_on "Save Post"

    assert_selector "img[src*='test_image.png']"

    click_on "Logout"
  end
end
