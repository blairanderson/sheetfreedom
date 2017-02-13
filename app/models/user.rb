class User < ActiveRecord::Base
  has_many :authorizations
  has_many :sheets
  has_many :tokens

  CELLS = "https://spreadsheets.google.com/feeds/cells/".freeze
  WORKSHEETS = "https://spreadsheets.google.com/feeds/worksheets/".freeze
  ALTJSON = "private/basic?alt=json".freeze

  def google_sheets
    @gsheets ||= fetch_google_sheets
  end

  def fetch_google_sheets
    fetch("https://spreadsheets.google.com/feeds/spreadsheets/private/full?alt=json").dig("feed", "entry")
  end

  def fetch(url)
    bearer = tokens.last.fresh_token
    response = Faraday.get(url) do |req|
      req.headers['authorization'] = "Bearer #{bearer}"
    end
    JSON.parse(response.body)
  end

  def fetch_google_sheet_by_key(sheet_key=nil)
    return false if sheet_key.blank?
    fetch("#{WORKSHEETS}#{sheet_key}/#{ALTJSON}").dig("feed", "entry").map do |sheet|
      {
          title: sheet["title"]['$t'],
          worksheets: sheet["link"].map do |link|
            next unless link["rel"] == "http://schemas.google.com/spreadsheets/2006#cellsfeed"
            key, id = link["href"].gsub(CELLS, "").gsub("/private/basic", "").split("/")
            {key: key, id: id}
          end.compact
      }
    end.first
  end

  def create_google_worksheet(google_file_id=nil, google_worksheet_id=nil, headers: false)
    worksheet = fetch_google_worksheet(google_file_id, google_worksheet_id)

    return {errors: "sheet not found", sheet: nil} if worksheet == false

    title = worksheet.dig("feed", "title", "$t") || "Untitled"
    worksheet_data = convert(worksheet, headers)
    sheet = nil
    User.transaction do
      sheet = self.sheets
                  .where(google_file_id: google_file_id, google_worksheet_id: google_worksheet_id)
                  .first_or_create!(title: title)

      sheet.update!({
                        title: title,
                        google_updated: worksheet.dig("feed", "updated", "$t"),
                        use_headers: headers,
                        headers: worksheet_data[:headers]
                    })

      worksheet_data[:rows].each_with_index do |data, index|
        sheet.worksheet_rows.where(row: WorksheetRow.index_with_offset(index)).update_or_create!({data: data})
      end
    end

    if sheet.valid?
      # Sheet.reset_counters(sheet.id, :worksheet_rows)
      {errors: nil, sheet: sheet}
    else
      {errors: sheet.errors.full_messages.join(", "), sheet: sheet}
    end
  end

  def fetch_google_worksheet(google_file_id=nil, google_worksheet_id=nil)
    return false if (google_file_id.blank? || google_worksheet_id.blank?)
    fetch("#{CELLS}#{google_file_id}/#{google_worksheet_id}/#{ALTJSON}")
  end

  def convert(worksheet_hash, with_headers=false)
    table = {}
    # google IGNORES empty columns.
    # we have to fill in the blanks by keep track of the longest column and appending nils
    max_index = 0
    worksheet_hash.dig('feed', 'entry').each do |entry|
      # https://developers.google.com/sheets/api/v3/data#work_with_cell-based_feeds
      # WE USE R1C1 NOTATION BECAUSE IT TELLS US EXACTLY WHICH ROW/COLUMN THE DATA COMES FROM.
      # API SKIPS EMPTY CELLS WHICH ESSENTIALLY RANDOMIZE THE DATA AND PROVIDES A MAP BACK.
      #       In a cell feed, each entry represents a single cell. Cells are referred to by position.
      #
      #       There are two positioning notations used in Google Sheets.
      #       The first, called A1 notation, uses characters from the Latin alphabet to
      #       indicate the column, and integers to indicate the row of a cell.
      #
      #       The second, called R1C1 notation, uses integers to represent both the column and the row,
      #       and precedes each by a corresponding R or C, to indicate row or column number.
      #       The addresses A1 and R1C1 are equivalent, as are the addresses B5 and R5C2.
      #
      #       Cell ranges also have notations in Google Sheets, but those are less relevant here.
      #
      #       Formulas often refer to other cells or cell ranges by their position.
      #       The cells feed allows formulas to be set on cells. However, the API always returns
      #       cell addresses for formulas on cells in R1C1 notation, even if the formula was set with A1 notation.
      #
      #       The title of a cell entry is always the A1 position of the cell.
      #
      #       The id URI of a cell entry always contains the R1C1 position of the cell.
      row_number, column_number = entry.dig("id", "$t").match(/R(\d+)C(\d+)$/).to_a.slice(1, 2)
      # convert to zero based arrays
      row_number = row_number.to_i - 1
      column_number = column_number.to_i - 1
      max_index = [max_index, column_number].max
      # would be cool to add a default value of the array.
      # table[row_number] ||= Array.new { "column_#{self.index}" }
      table[row_number] ||= Array.new
      table[row_number][column_number] = entry.dig("content", "$t").strip
    end

    table_rows = table.values

    # google IGNORES empty columns so we have to fill in the blanks
    # table_rows.each { |row| row[max_index] ||= nil }
    table_rows.each do |row|
      last_index = row.length - 1
      (last_index..max_index).to_a.each { |index| row[index] ||= "COLUMN_#{index+1}" }
    end

    response = {}
    response[:headers] = table_rows.shift if with_headers
    response[:rows] = table_rows
    response
  end

end
