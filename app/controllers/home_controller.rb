class HomeController < ApplicationController
  before_filter :require_user
  before_filter :require_user_with_trial_subscription, :only => :finish_trial
 
  def index
    @subscription = Billing::Subscription::Base.build(params[:subscription])
    @plans = Billing::Plan.all
  end

  def subscribe
    @subscription = Billing::Subscription::Base.build(params[:subscription])
    if @subscription.subscribe(current_user)
      flash[:success] = "Tariff plan was successfully changed"
      redirect_to root_path
    else
      @plans = Billing::Plan.all
      render :action => :index
    end
  end

  def finish_trial
    if current_user.billing_subscription.finish_trial && current_user.billing_subscription.bill
      flash[:success] = "Trial was successfully finished. Find your first invoice in 'Invoices' section."
      redirect_to root_path
    else
      flash[:error] = "Internal error occured"
    end
  end
end
