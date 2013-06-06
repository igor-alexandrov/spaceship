# coding: UTF-8

class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.login_field = :email

    c.validate_password_field = true
    c.session_ids = [:public]
  end

  attr_accessible :first_name, :last_name, :email, :password, :password_confirmation

  validates :first_name, :presence => true
  validates :last_name, :presence => true  
end