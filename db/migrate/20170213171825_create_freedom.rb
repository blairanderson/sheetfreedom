class CreateFreedom < ActiveRecord::Migration
  def change
    enable_extension 'uuid-ossp'

    create_table :authorizations do |t|
      t.string :provider
      t.string :uid
      t.integer :user_id

      t.timestamps null: false
    end

    create_table :users do |t|
      t.string :name
      t.string :email

      t.timestamps null: false
    end

    create_table :sheets, id: :uuid do |t|
      t.integer :user_id, null: false
      t.string :title
      t.string :google_file_id, null: false
      t.string :google_worksheet_id, null: false
      t.datetime :google_updated
      t.integer :worksheet_rows_count, default: 0, null: false
      t.boolean :use_headers, default: false, null: false
      t.text :headers

      t.timestamps null: false
    end

    # these are used for google access
    create_table :tokens do |t|
      t.integer :user_id, null: false
      t.string :access_token, null: false
      t.string :refresh_token, null: false
      t.datetime :expires_at, null: false

      t.timestamps null: false
    end

    # these store the worksheet data, as a cache.
    # we encrypt the data
    create_table :worksheet_rows do |t|
      t.uuid :sheet_id, null: false
      t.integer :row, null: false
      t.text :data
      # t.text :encrypted_data
      # t.text :encrypted_data_iv

      t.timestamps null: false
    end

    create_table :api_keys, id: :uuid do |t|
      t.uuid :sheet_id
      t.integer :use_count, default: 0, null: false

      t.timestamps null: false
    end
  end
end
