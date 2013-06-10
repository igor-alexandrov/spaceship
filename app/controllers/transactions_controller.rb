class TransactionsController < ApplicationController
  before_filter :require_user
 
  def index   
    @transactions = current_user.billing_transactions.page(params[:page])
  end
end