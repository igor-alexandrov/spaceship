class InvoicesController < ApplicationController
  before_filter :require_user
  before_filter :require_user_with_billing_card, :only => :pay
 
  def index    
    @invoices = current_user.billing_invoices.page(params[:page])
  end

  def show
    @invoice = current_user.billing_invoices.find(params[:id])
    render :layout => false
  end

  def pay
    @invoice = current_user.billing_invoices.unpaid.find(params[:id])
    begin
      @invoice.pay!
      flash[:success] = "An invoice was successfully paid"
    rescue => e
      flash[:error] = "An error occured during payment: #{e.message}"
    end  

    redirect_to invoices_url
  end
end
