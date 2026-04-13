
  def log_in_with(u) # u is a hash with fields email: and pass:
    visit root_url
    fill_in "user_email", with: u[:email]
    fill_in "user_password", with: u[:pass]
    click_on "Log in"
  end

  # Milkdown mounts on a contenteditable; the hidden #post_content textarea is
  # the source of truth for form submission. Write directly to it from JS so
  # tests don't need to drive the ProseMirror view.
  def fill_in_editor(content)
    page.execute_script("document.getElementById('post_content').value = arguments[0]", content)
  end

  # Upload a file through the form's async media-attach button. Waits until the
  # returned HTML snippet is mirrored into the hidden textarea.
  def attach_media_file(path, match:)
    attach_file("media-attach", path)
    click_on "Attach Media"
    deadline = Time.now + Capybara.default_max_wait_time
    loop do
      current = page.evaluate_script("document.getElementById('post_content').value")
      break if current.to_s.include?(match)
      raise Capybara::ExpectationNotMet, "textarea never contained #{match.inspect} (was #{current.inspect})" if Time.now > deadline
      sleep 0.1
    end
  end

  # when a user is already logged in
  def make_post(content)
    click_on "Home"
    click_on "New Post Button"
    fill_in_editor content
    click_on "Save Post"
    assert_text content
  end
