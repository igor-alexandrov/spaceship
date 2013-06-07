class HomeController < ApplicationController
  before_filter :require_user
 
  def index
    @startup = Billing::Plan.find_by_key('startup')
    @power = Billing::Plan.find_by_key('power')
  end
end
