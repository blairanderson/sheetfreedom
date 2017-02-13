class Sheet < ActiveRecord::Base
  belongs_to :user
  has_many :worksheet_rows
  has_many :api_keys
end
