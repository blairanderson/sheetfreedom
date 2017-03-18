class VisualsController < ApplicationController
  before_filter :set_sheet

  def index
    row = @sheet.worksheet_rows.offset(rand(@sheet.worksheet_rows.count)).limit(1).pluck(:data).first
    @column_types = row.map do |column_data|
      data_type = if (column_data.length < 30 && Float(column_data) rescue false)
                    Float
                  elsif (column_data.length < 30 && Integer(column_data) rescue false)
                    Integer
                  elsif (column_data.length < 30 && Time.parse(column_data) rescue false)
                    Time
                  elsif (column_data.length < 30 && Date.parse(column_data) rescue false)
                    Date
                  else
                    String
                  end

      [data_type.to_s, column_data]
    end

    if params[:date_index].blank? && first = @column_types.index { |type, _| type.in?(["Time", "Date"]) }
      flash[:notice] = "Did we find the correct date column?"
      redirect_to url_for(params.merge(date_index: first))
    end
  end

  def date_groups
    ["year", "month", "date"]
  end

  helper_method :date_groups

  def show

  end

  def date_group_to_strftime
    @date_group_to_strftime ||= Hash.new("%B %Y").merge({
                                                            "year" => "%Y",
                                                            "month" => "%B %Y",
                                                            "date" => "%D"
                                                        })[params[:date_group]]

  end

  def data
    date_index = if params[:date_index] && params[:date_index].to_i
                   params[:date_index].to_i
                 else
                   nil
                 end

    raw_data = @sheet.worksheet_rows.order("row ASC").pluck(:data)

    json_data = if date_index
                  raw_data.group_by do |data|
                    Time.parse(data[date_index]).strftime(date_group_to_strftime)
                  end.inject({}) do |memo, (group_name, data)|
                    memo[group_name] = data.count { |_, i| i }
                    memo
                  end
                end

    # grouped_data = grouped_data.map do |group, data|
    #   {
    #       name: group,
    #       data: data.group_by { |data| Time.parse(data[1]).strftime("%B %Y") }.map { |date, data|}
    #   }
    # end
    #
    # binding.pry
    #
    # json_data = grouped_data.map do |title, title_group|
    #
    #   this_group_data = {}
    #   title_group.group_by do |data|
    #   end.each do |group, data|
    #     this_group_data[group] = data.count { |_, b| b }
    #   end
    #
    #   {
    #       name: title,
    #       data: this_group_data
    #   }
    # end

    render json: json_data
  end

  private

  def set_sheet
    @sheet = current_user.sheets.find(params[:sheet_id])
  end
end
