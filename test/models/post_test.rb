require 'test_helper'

class PostTest < ActiveSupport::TestCase
  test "should not save post without content" do
    p = Post.new
    assert_not p.save
  end

  test "to_param uses title-based slug when title present" do
    post = posts(:one)
    assert_match /^#{post.id}-test-post-title/, post.to_param
  end

  test "to_param falls back to content-based slug when title nil" do
    post = posts(:two)
    assert_match /^#{post.id}-/, post.to_param
    assert_no_match /test-post-title/, post.to_param
  end

  test "display_title returns title when present" do
    post = posts(:one)
    assert_equal "Test Post Title", post.display_title
  end

  test "display_title returns formatted date when title nil" do
    post = posts(:two)
    assert_equal post.datetime.strftime('%B %d, %Y'), post.display_title
  end

  test "excerpt strips markdown and truncates" do
    post = posts(:one)
    post.content = "# Heading\n\nThis is a paragraph with some **bold** text and a [link](http://example.com)."
    assert_equal "This is a paragraph with some bold text and a link.", post.excerpt
  end

  test "first_image_url extracts markdown image" do
    post = posts(:one)
    post.content = "Some text\n\n![alt](/images/test.jpg)\n\nMore text"
    assert_equal "/images/test.jpg", post.first_image_url
  end

  test "first_image_url returns nil when no image" do
    post = posts(:one)
    post.content = "Just text, no images"
    assert_nil post.first_image_url
  end

  test "older_than and newer_than scopes return adjacent posts" do
    older = posts(:one)
    newer = posts(:two)
    newer.update(datetime: older.datetime + 1.day)

    assert_includes Post.older_than(newer), older
    assert_includes Post.newer_than(older), newer
  end
end
