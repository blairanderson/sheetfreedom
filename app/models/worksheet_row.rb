class WorksheetRow < ActiveRecord::Base
  belongs_to :sheet, counter_cache: :worksheet_rows_count
  serialize :data, JSON
  # attr_encrypted :data, key: ENV['ATTR_ENCRYPTED_KEY'], unless: Rails.env.development?
  OFFSET = 1

  def self.index_with_offset(index=0)
    index + OFFSET
  end

  def self.update_or_create(attributes)
    assign_or_new(attributes).save
  end

  def self.update_or_create!(attributes)
    assign_or_new(attributes).save!
  end

  def self.assign_or_new(attributes)
    obj = first || new
    obj.assign_attributes(attributes)
    obj
  end
end
