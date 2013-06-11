class ApplicationController < ActionController::Base
  before_filter :store_location

  protect_from_forgery

  helper_method :current_user

protected

  def current_session(id = :public)
    if User.session_ids.include?(id)
      var = (id.nil? ? "@current_session" : "@current_#{id.to_s}_session")
      return instance_variable_get(var) if instance_variable_defined?(var)
      return instance_variable_set(var, Session.find(id))
    else
      return nil
    end
  end

  def current_user(id = :public)
    return @current_user if defined?(@current_user)
    if User.session_ids.include?(id)
      var = (id.nil? ? "@current_user" : "@current_#{id.to_s}_user")
      return instance_variable_get(var) if instance_variable_defined?(var)
      return instance_variable_set(var, current_session(id) && current_session(id).record)
    else
      return nil
    end    
  end

  def reset_current_session(id = :public)
    var = (id.nil? ? "@current_session" : "@current_#{id.to_s}_session")
    instance_variable_defined?(var) ? remove_instance_variable(var) : true
  end

  def reset_current_user(id = :public)
    var = (id.nil? ? "@current_user" : "@current_#{id.to_s}_user")
    instance_variable_defined?(var) ? remove_instance_variable(var) : true
  end

  def reset_authlogic(id = :public)
    self.reset_current_session(id)
    self.reset_current_user(id)
  end

  def require_user
    redirect_to(auth_url) and return false unless current_user
    return true
  end

  def require_user_with_billing_card
    return false if !self.require_user
    
    redirect_to(root_url) and return false if current_user.billing_card.blank?
    return true
  end

  def require_user_with_trial_subscription
    return false if !self.require_user
    
    redirect_to(root_url) and return false if current_user.billing_subscription.blank? || !current_user.billing_subscription.trial?
    return true
  end
  
  def require_no_user
    redirect_to(root_url) and return false if current_user
    return true
  end

  def redirect_back_or_default(default)
    return_to = session[:return_to].blank? ? default : session[:return_to]
    session[:return_to] = nil

    respond_to do |format|
      format.js { render :js => "window.location.href='#{return_to}';" }
      format.html { redirect_to return_to }
    end    
  end

  def store_location
    session[:return_to] = request.url if request.get? && !request.xhr?
    true
  end
end
