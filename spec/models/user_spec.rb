require 'rails_helper'

RSpec.describe User, type: :model do
  let(:google_hash) { JSON.parse(File.read(File.join(Rails.root, "spec/google_hash.json"))) }
  let(:product_hash) { JSON.parse(File.read(File.join(Rails.root, "spec/1wYQGqa6qm8CtOrbef_7lni_Ww4rqbNIBmJ4IFc7k_vQ-od6.json"))) }
  describe 'convert_with_headers' do
    it 'converts with headers' do
      expect(User.new.convert(google_hash, true)).to eq({
                                                            headers: ["First Name", "Last Name", "Job"],
                                                            rows: [
                                                                ["oscar", "linares", "Padawan"],
                                                                ["blair", "anderson", "Jedi"]
                                                            ]
                                                        })
    end

    it 'works with nil values' do
      expected = {
          headers: ["Company", "interest", "status", "Position", "URL"],
          rows: [
              ["Seedco", "1", "APPLIED", "REMOTE - React/GO", "https://stackoverflow.com/jobs/115075/frontend-engineer-seed"],
              ["Auth0", "3", nil, "REMOTE - Node.js/React Engineer", "https://weworkremotely.com/jobs/3156-node-js-react-engineer"]
          ]
      }
      converted = User.new.convert(product_hash, true)
      expect(converted[:headers]).to eq(expected[:headers])
      converted[:rows].first(2).each_with_index do |row, index|
        expect(row).to eq(expected[:rows][index])
      end
    end
  end

  describe 'convert_without_headers' do
    it 'converts without headers' do
      expect(User.new.convert(google_hash, false)).to eq({
                                                             rows: [
                                                                 ["First Name", "Last Name", "Job"],
                                                                 ["oscar", "linares", "Padawan"],
                                                                 ["blair", "anderson", "Jedi"]
                                                             ]
                                                         })
    end

    it 'works with nil values' do
      expected = {
          rows: [
              ["Company", "interest", "status", "Position", "URL"],
              ["Seedco", "1", "APPLIED", "REMOTE - React/GO", "https://stackoverflow.com/jobs/115075/frontend-engineer-seed"],
              ["Auth0", "3", nil, "REMOTE - Node.js/React Engineer", "https://weworkremotely.com/jobs/3156-node-js-react-engineer"]
          ]
      }
      converted = User.new.convert(product_hash, false)
      rows = converted[:rows].first(3)
      expected[:rows].each_with_index do |row, index|
        expect(rows[index]).to eq(row)
      end
    end
  end
end
