Billing::Plan.delete_all
# Billing::Subscription::Base.delete_all

startup = Billing::Plan.create do |plan|
  plan.key = 'startup'
  plan.title = 'Startup'
  plan.trial = 10

  plan.monthly_amount = 2500
  plan.annual_amount = 25000

  plan.maximum_email_requests_count = 40
  plan.maximum_phone_calls_count = 10

  plan.maximum_developers_count = 1
end

startup = Billing::Plan.create do |plan|
  plan.key = 'power'
  plan.title = 'Power'
  plan.trial = 10

  plan.monthly_amount = 4000
  plan.annual_amount = 40000

  plan.maximum_email_requests_count = nil
  plan.maximum_phone_calls_count = nil

  plan.maximum_developers_count = 3
end