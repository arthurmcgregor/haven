require "application_system_test_case"
require_relative 'systemtest_helpers.rb'

class ContentSecurityPolicyTest < ApplicationSystemTestCase
  test_users = {
    washington: {email: "george@washington.com", pass: "georgepass"}, # admin
    jackson: {email: "andrew@jackson.com", pass: "jacksonpass"},      # publisher
    lincoln: {email: "abraham@lincoln.com", pass: "lincolnpass"}     # subscriber
  }

  ## Ensures CSP doesn't block the Milkdown editor bundle from loading on the
  ## post form. Historically this test guarded the Showdown inline preview;
  ## with Milkdown the editor is an external ESM bundle, so we just verify it
  ## initialises (ProseMirror mounts a .ProseMirror element inside [data-milkdown]).
  test "editor loads on the post form without CSP violations" do
    log_in_with test_users[:jackson]
    click_on "New Post Button"
    assert_selector "[data-milkdown] .ProseMirror"
    click_on "Logout"
  end
end
