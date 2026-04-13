require "application_system_test_case"
require_relative 'systemtest_helpers.rb'

class MediaUploadTest < ApplicationSystemTestCase
  MEDIA_CASES = {
    "test_audio.mp3" => "audio",
    "test_video.mp4" => "video",
    "test_video.mov" => "video",
  }.freeze

  def admin_user
    { email: "george@washington.com", pass: "georgepass" }
  end

  MEDIA_CASES.each do |filename, tag|
    test "upload #{filename} and validate display" do
      log_in_with admin_user
      click_on "New Post Button"

      fill_in "post_title", with: "Media #{filename}"
      fill_in_editor "This is a test post with #{filename}."

      attach_media_file Rails.root.join('test', 'fixtures', 'files', filename),
                        match: filename

      click_on "Save Post"

      assert_selector "#{tag} source[src*='#{filename}']", visible: :all
      click_on "Logout"
    end
  end
end
