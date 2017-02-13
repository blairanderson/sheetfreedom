class SheetsController < ApplicationController
  before_filter :require_login, except: [:show]

  def index
    @sheets = current_user.sheets.includes(:api_keys)
  end

  def show
    if current_user
      @sheet = current_user.sheets.find(params[:id])
    elsif params[:token]
      key = ApiKey.where(sheet_id: params[:id], id: params[:token]).first!
      @sheet = key.sheet
      key.increment!(:use_count)
    end

    rows = @sheet.worksheet_rows.order('row ASC').paginate(page: params[:page], per_page: 100)

    args = {only: [:title, :use_count]}
    if @sheet.use_headers
      args[:only] ||= []
      args[:only] << :headers
    end

    respond_to do |format|
      format.html
      format.json { render json: @sheet.as_json(args).merge(rows: rows.pluck(:data), meta: pagination_dict(rows)) }
    end
  end

  def pagination_dict(collection)
    {
        current_page: collection.current_page,
        next_page: collection.next_page,
        total_pages: collection.total_pages
    }
  end

end
