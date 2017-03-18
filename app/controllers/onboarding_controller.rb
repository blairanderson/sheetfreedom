class OnboardingController < ApplicationController
  before_filter :require_login

  def index
    @google = current_user.google_sheets.map.with_index do |sheet, index|
      if index == 0
        # binding.pry
      end
      {

          id: sheet.dig('id', '$t').split('private/full/').last,
          # updated: Time.at(sheet["updated"]["$t"]),
          author_name: sheet.dig('author', 0, 'name', '$t'),
          author_email: sheet.dig('author', 0, 'email', '$t'),
          title: sheet.dig('title', '$t'),
          updated_at: Time.parse(sheet.dig('updated', '$t'))
      }
    end
  end

  def show
    @sheet = current_user.fetch_google_sheet_by_key(params[:id])

    if @sheet[:worksheets].length == 1 && link = @sheet[:worksheets].first
      redirect_to worksheet_onboarding_path(params[:id], link[:id])
      return
    end

    respond_to do |format|
      format.html
      format.json { render json: @sheet }
    end
  end

  def worksheet
    raw_sheet = current_user.fetch_google_worksheet(params[:id], params[:worksheet_id])
    if raw_sheet == false
      redirect_to (!!params[:id] ? onboarding_path(params[:id]) : onboarding_index_path)
      return
    end

    # store these for specs
    # if Rails.env.development?
    #   File.open(File.join(Rails.root, "spec/#{[params[:id], params[:worksheet_id]].join("-")}.json"), "w") do |f|
    #     f.write(JSON.pretty_generate(raw_sheet))
    #   end
    # end

    @title = raw_sheet.dig("feed", "title", "$t")
    @worksheet = current_user.convert(raw_sheet, !!params[:headers])
    respond_to do |format|
      format.html
      format.json { render json: @worksheet }
    end
  end

  def create
    sheet_params = params.require(:sheet).permit(:id, :worksheet_id, :headers)
    resp = current_user.create_google_worksheet(sheet_params[:id], sheet_params[:worksheet_id], headers: !!sheet_params[:headers])
    errors, sheet = resp.values_at(:errors, :sheet)
    if errors
      flash[:error] = errors
      redirect_to(worksheet_onboarding_path(sheet_params[:id], sheet_params[:worksheet_id]))
    else
      redirect_to(sheet)
    end
  end
end
