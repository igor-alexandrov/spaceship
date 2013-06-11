class HomeController < ApplicationController
  before_filter :require_user
 
  def index
    @subscription = Billing::Subscription::Base.build(params[:subscription])
    @plans = Billing::Plan.all
  end

  def subscribe
    @subscription = Billing::Subscription::Base.build(params[:subscription])
    if @subscription.subscribe(current_user)
      flash[:success] = "Tariff plan was successfully changed."
      redirect_to root_path
    else
      @plans = Billing::Plan.all
      render :action => :index    
    end    
  end  
end
