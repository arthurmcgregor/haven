class Post < ApplicationRecord
  belongs_to :author, class_name: :User, inverse_of: :posts
  has_many :comments, foreign_key: :post_id, dependent: :destroy
  has_many :likes, foreign_key: :post_id, dependent: :destroy

  scope :older_than, ->(post) { where('datetime < ? OR (datetime = ? AND id < ?)', post.datetime, post.datetime, post.id).order(datetime: :desc, id: :desc) }
  scope :newer_than, ->(post) { where('datetime > ? OR (datetime = ? AND id > ?)', post.datetime, post.datetime, post.id).order(datetime: :asc, id: :asc) }

  def to_param
    return nil unless persisted?
    slug = if title.present?
             PostsController.sanitize(title)[0..50].downcase
           else
             PostsController.make_slug(content)
           end
    [id, slug].join('-')
  end

  def display_title
    title.presence || datetime&.strftime('%B %d, %Y') || 'Untitled'
  end

  def excerpt(max_length = 200)
    stripped = ActionController::Base.helpers.strip_tags(content.to_s)
    plain = stripped
      .gsub(/!\[.*?\]\(.*?\)/, '')
      .gsub(/^\s*#+\s+.*$/, '')
      .gsub(/\[([^\]]*)\]\([^)]*\)/, '\1')
      .gsub(/(\*{1,2}|_{1,2})(.+?)\1/, '\2')
      .strip
    first_para = plain.split(/\n\n/).reject(&:blank?).first.to_s.gsub(/\s+/, ' ').strip
    first_para.length > max_length ? "#{first_para[0...max_length]}..." : first_para
  end

  def first_image_url
    if content =~ /!\[.*?\]\((.+?)\)/
      $1
    elsif content =~ /<img[^>]+src="([^"]+)"/
      $1
    end
  end

  def like_text
    reactions = Hash.new{|h,k| h[k] = []}
    likes.each do |like|
      reactions[like.reaction] << like.user.name
    end
    text = ""
    reactions.each do |reaction, names|
      text << "\n" unless text == ""
      text << "#{reaction} from"
      names.each do |name|
        text << " #{name},"
      end
    end
    return text[0...-1] # remove trailing comma
  end

  def likes_from(user)
    user_likes = []
    likes.each do |like|
      user_likes << like if like.user == user
    end
    return user_likes
  end
end
