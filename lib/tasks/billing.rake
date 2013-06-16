namespace :billing do
  desc "Find subscriptions that should be billed and bill them"
  task :run => :environment do
    # Should be done async in production
    Billing::Subscription::Base.should_be_billed.each do |subscription|    
      subscription.bill
    end
  end
end