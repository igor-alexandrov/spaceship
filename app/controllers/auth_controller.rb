class AuthController < ApplicationController
  before_filter :require_no_user
  def index
    @user = User.new
    @session = Session.new
  end

  def sign_in
    @session = Session.new(params[:session])
    @session.id = :public
    
    if @session.save
      redirect_back_or_default(root_url)
    else
      @user = User.new
      render :action => :index
    end    
  end

  def sign_up
    @user = User.new(params[:user])
    if @user.save
      Session.create(@user, true, :public)
      redirect_to root_url
    else
      @session = Session.new
      render :action => :index
    end
  end
end
