class ApiKeysController < ApplicationController
  def create
    sheet = current_user.sheets.find(params[:sheet_id])
    api_key = sheet.api_keys.create!
    redirect_to sheet_path(sheet)
  end
end
