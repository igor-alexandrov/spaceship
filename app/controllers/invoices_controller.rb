class InvoicesController < ApplicationController
  before_filter :require_user
 
  def index    
    @invoices = current_user.billing_invoices.page(params[:page])
  end
end
