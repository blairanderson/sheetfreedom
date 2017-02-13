puts ENV['GOOGLE_CLIENT_ID']
puts ENV['GOOGLE_CLIENT_SECRET']

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'],
           {
               name: 'google',
               scope: 'email, drive, spreadsheets,https://spreadsheets.google.com/feeds, https://docs.google.com/feeds',
               approval_prompt: 'force',
               prompt: 'consent',
               image_aspect_ratio: 'square',
               access_type: 'offline'
           }
end


OmniAuth.config.logger = Rails.logger