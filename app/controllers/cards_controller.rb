class CardsController < ApplicationController
  before_filter :require_user
 
  def new  
    @card = current_user.build_billing_card(params[:card])
    render :layout => false  
  end

  def create
    @card = current_user.build_billing_card(params[:card])
    if @card.ensure_braintree_customer_and_save
      flash[:success] = 'Credit card was successfully assigned'
      respond_with_redirect :url => return_to
    else    
      respond_with_content :action => :new, :id => dom_id(@card), :partial => 'cards/form'
    end
  end

  def destroy
    if current_user.billing_card.destroy
      flash[:success] = 'Credit card was successfully removed'
    else
      flash[:error] = 'An error occured during credit card removal'
    end
    respond_with_redirect :url => return_to
  end

protected
  
  def return_to
    params[:return_to] || request.referrer
  end
end
