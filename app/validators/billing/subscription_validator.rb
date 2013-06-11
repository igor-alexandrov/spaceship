class Billing::SubscriptionValidator < ActiveModel::Validator
  def validate(subscription)


    unless subscription.forced?
      if subscription.plan_id_changed? && subscription.plan.present? && subscription.user.present?
                
        # Get the old subscription from the database because the Company instance
        # # that we have here only knows about the new subscription.
        # user = subscription.company
        # old_subscription = Billing::Subscription::Base.where(:company_id => company.id).first

        # if company.active_users_count > subscription.maximum_users_count.to_i
        #   subscription.errors.add(:base, :account_has_too_many_users)
        # end        

        # if company.active_attorneys_count > subscription.maximum_attorneys_count.to_i
        #   subscription.errors.add(:base, :account_has_too_many_attorneys)
        # end

        if subscription.plan.maximum_developers_count.present? && subscription.developers_count > subscription.plan.maximum_developers_count
          subscription.errors.add(:base, :too_many_developers)
        end
      
        # if subscription.additional_services.any? { |service| service.class.requires_billing_card? } && subscription.user.billing_card.blank?
        #   subscription.errors.add(:base, :account_should_have_billing_card)
        # end
      end
    
      if subscription.new_record? && subscription.user.present? && subscription.user.billing_invoices.unpaid.count > 0
        subscription.errors.add(:base, :user_has_unpaid_invoices)
      end
    
      if subscription.subscription_date.present? && subscription.next_billing_date.present?
        subscription.errors[:next_billing_date] << "cannot be before 'subscription_date'" if subscription.next_billing_date < subscription.subscription_date 
      end
    end
  end
end
