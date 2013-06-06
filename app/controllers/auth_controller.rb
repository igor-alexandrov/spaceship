class AuthController < ApplicationController
  def index
    @user = User.new
    @session = Session.new
  end

  def sign_in
  end

  def sign_up
  end
end
