# coding: UTF-8

class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.login_field = :email
    c.validate_login_field = false
    c.transition_from_restful_authentication = true
    c.require_password_confirmation = false
    c.validate_password_field = true
    c.merge_validates_length_of_password_field_options :minimum => 4
    c.ignore_blank_passwords = false
    c.logged_in_timeout = 15.minutes
    c.session_ids = [:public, :admin]
  end
end