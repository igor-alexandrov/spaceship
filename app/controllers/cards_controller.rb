class CardsController < ApplicationController
  before_filter :require_user
 
  def new  
    @card = current_user.build_billing_card(params[:card])
    render :layout => false  
  end

  def create
    @card = current_user.build_billing_card(params[:card])
    if @card.ensure_braintree_customer_and_save
      flash[:success] = 'Credit card has been successfully assigned'
      respond_with_redirect :url => return_to
    else    
      respond_with_content :action => :new, :id => dom_id(@card), :partial => 'cards/form'
    end
  end

  def destroy
    current_user.credit_card.destroy
  end

protected
  
  def return_to
    params[:return_to] || request.referrer
  end
end
