class User < ApplicationRecord
  validates_presence_of :basic_auth_username
  validates :basic_auth_username, uniqueness: true
  validates_presence_of :basic_auth_password

  has_many :posts, foreign_key: :author_id, dependent: :destroy
  has_many :comments, foreign_key: :author_id, dependent: :destroy
  has_many :likes, foreign_key: :user_id, dependent: :destroy
  has_many :login_links, dependent: :destroy

  has_many :feeds, dependent: :destroy
  has_many :feed_entries, through: :feeds

  has_many :indie_auth_requests, dependent: :destroy
  has_many :indie_auth_tokens, dependent: :destroy

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:openid_connect]

  def self.from_omniauth(auth)
    # First, check if we already have a user with this OIDC identity
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    # Link OIDC identity to existing user with matching email
    user = find_by(email: auth.info.email)
    if user
      user.update!(provider: auth.provider, uid: auth.uid)
      return user
    end

    # Create a new user if no match found
    create!(
      provider: auth.provider,
      uid: auth.uid,
      email: auth.info.email,
      name: auth.info['name'].presence || auth.info['preferred_username'],
      password: Devise.friendly_token(40),
      admin: 0,
      basic_auth_username: Devise.friendly_token.first(10),
      basic_auth_password: Devise.friendly_token.first(10),
      image_password: Devise.friendly_token.first(20)
    )
  end

  def password_required?
    provider.blank? && super
  end

  def display_name
    if self.name.nil?
      return self.email
    elsif self.name.empty?
      return self.email
    else
      return self.name
    end
  end
end
