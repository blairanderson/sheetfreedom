require 'net/http'
require 'json'

class Token < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :access_token, :refresh_token
  NO_REFRESH_TOKEN = "NO-REFRESH-TOKEN"

  def request_token_from_google
    url = URI("https://accounts.google.com/o/oauth2/token")
    refresh_data = {
        'refresh_token' => refresh_token,
        'client_id' => ENV['GOOGLE_CLIENT_ID'],
        'client_secret' => ENV['GOOGLE_CLIENT_SECRET'],
        'grant_type' => 'refresh_token'
    }
    puts refresh_data
    Net::HTTP.post_form(url, refresh_data)
  end

  def refresh!
    response = request_token_from_google
    data = JSON.parse(response.body)
    Rails.logger.info("Token#refresh! #{self.inspect}")
    update_attributes({
                          access_token: data['access_token'],
                          expires_at: (Time.current + data['expires_in'].to_i.seconds)
                      })
  end

  def expired?
    expires_at < Time.current
  end

  def fresh_token
    refresh! if expired?
    access_token
  end
end
