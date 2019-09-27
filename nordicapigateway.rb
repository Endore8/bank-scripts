#!/usr/bin/env ruby

require 'httparty'
require 'pg'
require 'colorize'

NORDIC_API_GATEWAY_CLIENT_ID = "CLIENT_ID"
NORDIC_API_GATEWAY_CLIENT_SECRET = "CLIENT_SECRET"
DATABASE_HOST = "localhost"
DATABASE_PORT = "5432"
DATABASE_NAME = "nordicapigateway"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = ""

class NordicAPIGateway
  include HTTParty
  base_uri 'https://api.nordicapigateway.com/v1/'

  def initialize()
    @options = {
      query: {},
      headers: {
        "Content-Type": "application/json",
        "X-Client-ID": NORDIC_API_GATEWAY_CLIENT_ID,
        "X-Client-Secret": NORDIC_API_GATEWAY_CLIENT_SECRET
      }
    }
  end

  def auth_url(user_hash = "test-user")
    puts ""
    puts "Getting auth url..."

    body = { "userHash": user_hash, "redirectUrl": "https://httpbin.org/anything" }.to_json
    options = @options.merge!({ body: body })
    response = self.class.post("/authentication/initialize", options)
    debug_response(response)

    url = response["authUrl"]
    if url.nil?
      raise "No auth url!".red
    end

    puts "Got auth url"
    puts ""

    url
  end

  def access_token(code)
    if code.nil?
      raise "No auth code!".red
    end

    puts "Getting access token"

    body = { "code": code }.to_json
    options = @options.merge!({ body: body })
    response = self.class.post("/authentication/tokens", options)
    debug_response(response)

    token = response["session"]["accessToken"]
    if token.nil?
      raise "No access token!".red
    end

    puts "Got access token"

    token
  end

  def accounts(access_token)
    puts "Getting accounts"

    headers = @options[:headers].merge!({ "Authorization": "Bearer #{access_token}" })
    options = @options.merge!({ headers: headers })
    response = self.class.get("/accounts", options)
    debug_response(response)

    accounts = response["accounts"]
    if accounts.nil?
      raise "No accounts!".red
    end

    puts "Got accounts"

    accounts
  end

  def transactions(account_id, access_token)
    puts "Getting transactions"

    headers = @options[:headers].merge!({ "Authorization": "Bearer #{access_token}" })
    query = { "withDetails": true }
    options = @options.merge!({ headers: headers, query: query })
    response = self.class.get("/accounts/#{account_id}/transactions", options)
    debug_response(response)

    transactions = response["transactions"]
    if transactions.nil?
      raise "No transactions!".red
    end

    puts "Got transactions"

    transactions
  end

  def debug_response(response)
    message = "Response: #{response.message} - #{response.code}"
    if response.success?
      puts message
    else
      puts message.red
    end
  end
end

def authorize(api)
  auth_url = api.auth_url

  puts "Opening auth url for login".blue
  `open #{auth_url}`

  puts "Enter the code from the json response:".blue
  code = gets.chomp

  api.access_token(code)
end

def store(db, company_id, transactions)
  db.exec("CREATE TABLE IF NOT EXISTS transactions (
    id serial,
    company_id varchar(64),
    original_id varchar(64),
    date varchar(64),
    type varchar(64),
    state varchar(64),
    amount float,
    currency varchar(64),
    category_id int,
    category_set_id varchar(64),
    details_message varchar(64),
    details_value_date varchar(64),
    details_reward_type varchar(64),
    details_reward_amount float,
    details_reward_currency varchar(64),
    details_reward_points varchar(64),
    details_source varchar(64),
    details_destination varchar(64),
    details_identifiers varchar(64),
    details_currency_conversion varchar(64),
    PRIMARY KEY (id)
    )")

  db.prepare('transaction_statement', 'insert into transactions (
                                                      company_id,
                                                      original_id, date, type, state, amount, currency,
                                                      category_id, category_set_id,
                                                      details_message, details_value_date,
                                                      details_reward_type, details_reward_amount, details_reward_currency, details_reward_points,
                                                      details_source, details_destination, details_identifiers, details_currency_conversion)
                                                    values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)')
  puts "Saving #{transactions.count} transactions"

  transactions.each { |tr|
    t = tr.to_h
    params = [
       company_id,
       t["id"], t["date"], t["type"], t["state"], t["amount"], t["currency"],
       t["category"].to_h["id"], t["category"].to_h["setId"],
       t["details"].to_h["message"], t["details"].to_h["valueDate"],
       t["details"].to_h["reward"].to_h["type"], t["details"].to_h["reward"].to_h["amount"].to_h["value"], t["details"].to_h["reward"].to_h["amount"].to_h["currency"], t["details"].to_h["reward"].to_h["points"],
       t["details"].to_h["source"], t["details"].to_h["destination"], t["details"].to_h["identifiers"], t["details"].to_h["currencyConversion"]
     ]
    db.exec_prepared('transaction_statement', params)
  }

  puts "Transactions saved!"
end

# -------------------------------------------------------

puts ""
puts "NordicAPIGateway".blue.underline
puts ""

api = NordicAPIGateway.new()
db = PG.connect(:host=>DATABASE_HOST, :port=>DATABASE_PORT, :dbname=>DATABASE_NAME, :user=>DATABASE_USER, :password=>DATABASE_PASSWORD)

if ENV["ACCESS_TOKEN"].nil? == false
  access_token = ENV["ACCESS_TOKEN"]
else
  access_token = authorize(api)
end

puts "NordicAPIGateway Access Token:"
puts access_token.green

accounts = api.accounts(access_token)

if accounts.count == 0
  raise "Got zero accounts!".blue
end

puts ""
puts "Enter company id (optional):".blue
company_id = gets.chomp

puts ""
puts "Available accounts:".blue
accounts.each_with_index { |a, i|
  puts "#{i} - #{a["name"]} #{a["currency"]}".blue
}

puts ""
puts "Choose account to pull transactions for:".blue
puts "(enter number)".blue
account_index = gets.chomp.to_i
account_id = accounts[account_index]["id"]

transactions = api.transactions(account_id, access_token)
store(db, company_id, transactions)

puts ""
puts "Done!".green
