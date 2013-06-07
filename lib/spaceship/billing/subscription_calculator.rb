module Spaceship
  module Billing
    class SubscriptionCalculator
      attr_accessor :subscription
      
      def initialize(subscription)
        self.subscription = subscription  
      end
          
      def amount(type = nil)
        self.amount_params(type).compact.collect{ |r| r[:amount] }.reduce(:+).to_f
      end
      
      def amount_spent(type = nil)
        self.amount_spent_params(type).compact.collect{ |r| r[:amount] }.reduce(:+).to_f        
      end

      def amount_unspent(type = nil)  
        return 0 if self.subscription.trial?
        self.amount - self.amount_spent
      end
      
      def amount_params(type = nil)
        results = []
        
        self.subscription.force_type(type) do      
          results << self.calculate_plan(self.subscription.previous_action_date, self.subscription.next_billing_date)          
          # results << self.calculate_additional_services(self.subscription.previous_action_date, self.subscription.next_billing_date)          
        end

        return results.flatten.compact
      end
      
      def amount_spent_params(type = nil)        
        results = []
        
        self.subscription.force_type(type) do
          results << self.calculate_plan(self.subscription.previous_action_date, Date.today)          
          # results << self.calculate_additional_services(self.subscription.previous_action_date, Date.today)          
        end

        return results.flatten.compact
      end
      
    protected

      def calculate_plan(start_date, stop_date)    
        { :amount => (self.subscription.plan.amount_in(self.subscription, start_date, stop_date)).round(2), :description => "#{self.subscription.plan.title} Plan", :key => :plan }
      end
      
      # def calculate_additional_services(start_date, stop_date)
      #   results = []
      #   self.subscription.additional_services_active_in(start_date, stop_date).each do |service|
      #     next unless service.class.billable?

      #     actual_start_date, actual_stop_date = self.normalize_dates(service, start_date, stop_date)                 
      #     if actual_start_date <= actual_stop_date                        
      #       amount = self.subscription.additional_service_amount_in(service, actual_start_date, actual_stop_date)
            
      #       partial = (actual_start_date != start_date) || (actual_stop_date != stop_date)
      #       description = partial ? service.description(actual_start_date, actual_stop_date) : service.description
                     
      #       results << { :amount => amount.round(2), :description => description, :key => service.class.key }
      #     end
      #   end
        
      #   return results
      # end

      # def normalize_dates(service, start_date, stop_date)
      #   actual_start_date = [start_date, service.subscription_date].max      
      #   actual_stop_date = service.unsubscription_date.present? ? [stop_date, service.unsubscription_date].min : stop_date

      #   [actual_start_date, actual_stop_date]
      # end
    end
  end
end