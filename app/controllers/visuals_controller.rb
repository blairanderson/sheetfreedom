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
      redirect_to url_for(params.merge(date_index: first, date_group: params[:date_group] || "month"))
    end
  end

  def date_groups
    %w(
    year
    quarter
    month
    month_of_year
    day_of_month
    week
    day_of_week
    day
    hour_of_day)
  end

  helper_method :date_groups

  def show

  end

  def date_group_to_strftime
    @date_group_to_strftime ||= if params[:date_group].in?(date_groups)
                                  "group_by_#{params[:date_group]}".to_sym
                                else
                                  :group_by_month
                                end
  end

  def data
    date_index = if params[:date_index] && params[:date_index].to_i
                   params[:date_index].to_i
                 else
                   nil
                 end

    raw_data = @sheet.worksheet_rows.order("row ASC").pluck(:data)

    grouped_data = if params[:groupable] && groupable_index =  params[:groupable].to_i
                  raw_data.group_by{|a| a[groupable_index]}
                else
                  {"All" => raw_data}
                end

    json_data = grouped_data.map do |name, g_data|
      g_json = g_data.send(date_group_to_strftime) { |data| Time.parse(data[date_index]) }
                    .inject({}) do |memo, (group_name, data)|
        memo[group_name] = data.count { |_, i| i }
        memo
      end
      {
          name: name,
          data: g_json
      }
    end

    render json: json_data, root: false
  end

  private

  def set_sheet
    @sheet = current_user.sheets.find(params[:sheet_id])
  end
end
