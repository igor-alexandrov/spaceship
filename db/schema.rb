# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130607224056) do

  create_table "billing_invoices", :force => true do |t|
    t.integer  "user_id"
    t.decimal  "full_amount",      :precision => 8, :scale => 2
    t.decimal  "credit_deduction", :precision => 8, :scale => 2
    t.decimal  "amount",           :precision => 8, :scale => 2
    t.text     "params"
    t.datetime "paid_at"
    t.date     "issue_date"
    t.date     "due_date"
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.string   "title",                                          :null => false
  end

  add_index "billing_invoices", ["due_date"], :name => "index_billing_invoices_on_due_date"
  add_index "billing_invoices", ["issue_date"], :name => "index_billing_invoices_on_issue_date"
  add_index "billing_invoices", ["user_id"], :name => "index_billing_invoices_on_user_id"

  create_table "billing_plans", :force => true do |t|
    t.string   "title"
    t.string   "key"
    t.decimal  "monthly_amount",               :precision => 8, :scale => 2
    t.decimal  "annual_amount",                :precision => 8, :scale => 2
    t.integer  "trial"
    t.integer  "maximum_email_requests_count"
    t.integer  "maximum_phone_calls_count"
    t.integer  "maximum_developers_count"
    t.datetime "created_at",                                                 :null => false
    t.datetime "updated_at",                                                 :null => false
  end

  add_index "billing_plans", ["key"], :name => "index_billing_plans_on_key", :unique => true

  create_table "billing_subscriptions", :force => true do |t|
    t.string   "type",                                     :null => false
    t.integer  "user_id",                                  :null => false
    t.integer  "plan_id"
    t.integer  "developers_count",      :default => 1,     :null => false
    t.boolean  "trial",                 :default => false, :null => false
    t.date     "subscription_date",                        :null => false
    t.date     "unsubscription_date"
    t.datetime "billed_at"
    t.date     "previous_billing_date"
    t.date     "next_billing_date",                        :null => false
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
  end

  add_index "billing_subscriptions", ["user_id"], :name => "index_billing_subscriptions_on_user_id"

  create_table "billing_transactions", :force => true do |t|
    t.integer  "user_id"
    t.integer  "invoice_id"
    t.integer  "card_id"
    t.string   "action"
    t.decimal  "amount",        :precision => 8, :scale => 2
    t.boolean  "success"
    t.string   "authorization"
    t.string   "message"
    t.text     "params"
    t.boolean  "refunded"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
  end

  add_index "billing_transactions", ["card_id"], :name => "index_billing_transactions_on_card_id"
  add_index "billing_transactions", ["invoice_id"], :name => "index_billing_transactions_on_invoice_id"
  add_index "billing_transactions", ["user_id"], :name => "index_billing_transactions_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "persistence_token",                                                :null => false
    t.string   "perishable_token",                                                 :null => false
    t.integer  "login_count",                                     :default => 0,   :null => false
    t.datetime "last_request_at"
    t.datetime "last_login_at"
    t.datetime "current_login_at"
    t.string   "last_login_ip"
    t.string   "current_login_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "available_credit",  :precision => 8, :scale => 2, :default => 0.0, :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["perishable_token"], :name => "index_users_on_perishable_token"

end
