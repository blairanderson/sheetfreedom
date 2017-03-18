class SessionsController < ApplicationController

  def new
    if logged_in?
      if current_user.sheets.count > 0
        redirect_to sheets_path
      else
        redirect_to onboarding_index_path
      end

    end
  end

  def create
    @user = Authorization.user_from_auth_hash(auth_hash)
    if @user
      login_user(@user)
    else
      flash[:notice] = "There was an error"
    end
    redirect_to root_path
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: 'logged out'
  end

  def login_user(user)
    session[:user_id] = user.id
  end

  def auth_hash
    @auth ||= request.env['omniauth.auth'].to_hash
    unless @auth.has_key?('uid') && @auth.has_key?('provider')
      redirect_to root_path, notice: "Bad Auth, missing uid or provider"
      return
    end
    @auth
  end
end
