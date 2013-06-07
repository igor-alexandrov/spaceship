class HomeController < ApplicationController
  before_filter :require_user
 
  def index
    @startup = Billing::Plan.find_by_key('startup')
    @hardcore = Billing::Plan.find_by_key('hardcore')
  end

  def subscribe
    
  end
end
