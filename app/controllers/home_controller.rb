class HomeController < ApplicationController
  before_filter :require_user
 
  def index
    self.fetch_plans
  end

  def subscribe
    @subscription = Billing::Subscription::Base.build(params[:subscription])
    if @subscription.subscribe(current_user)
      flash[:success] = "Tariff plan was successfully changed."
      redirect_to root_path
    else
      self.fetch_plans
      render :action => :index    
    end    
  end

protected
  
  def fetch_plans
    @startup = Billing::Plan.find_by_key('startup')
    @hardcore = Billing::Plan.find_by_key('hardcore')
  end
  
end
