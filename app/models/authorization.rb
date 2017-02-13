class Authorization < ActiveRecord::Base

  belongs_to :user
  validates :uid, :provider, presence: true
  # validates :uid, :scope => :provider, presence: true

  # find or create user by auth[provider ]and auth[uid]
  def self.user_from_auth_hash(auth_hash)
    auth = where(auth_hash.slice("uid", "provider")).first_or_create

    if auth.user
      user = auth.user
    else
      User.transaction do
        user = User.create!(auth_hash["info"].slice("name").merge(auth_hash["extra"]["raw_info"].slice("email")))
        auth.user_id = user.id
        auth.save!
      end
    end
    credentials = auth_hash['credentials']
    user.tokens.create!({
                           access_token: credentials['token'],
                           refresh_token: credentials['refresh_token'] || Token::NO_REFRESH_TOKEN,
                           expires_at: Time.at(credentials['expires_at']).to_datetime
                       })
    user
  end

end
