#!/usr/bin/env ruby
#TODO:
#convert changable values to environment variables
#convert from pulling local html to calling the post method directly.
#optimize google api interactions
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'redis'
require 'json'
redis = Redis.new(:host => "127.0.0.1", :port => 6379, :db => 0)
page = Nokogiri::HTML(open("output2.html"))
google_url = "https://maps.googleapis.com/maps/api/geocode/json?address="
page_output = []
def get_name_description(page)
  #store nokogiri results in an array, appending on the end constantly
  results = []
  items = page.css('div.resultBlock')
  items.each do |item|
    name = item.css('h5').text
    info = item.css('p').text
    results << name.concat(info)
  end
  return results
end
records = get_name_description(page)
names_array = []
info_array = []
address_array = []
record_array = []
phones_array = []
#go through each record and split it up into names, addresses, phone numbers, and descriptions
records.each do |record|
  record_array = record.split("\r\n    \t        \t\t\t\t")
  names_array << record_array[0]
  info_array << record_array[2]
  record_array[1].split('|').each {|item| item.match(', TX'){address_array << item}}
  record_array[1].split('|').each {|item| item.match('Phone:'){phones_array << item}}
end
x = 0
#iterate over the arrays and add them to redis, for retrieval later. Set a unique number to each key, so they can be recalled in groups
while x <  names_array.size
  redis.set "names" + x.to_s, names_array[x].to_s
  redis.set "address" + x.to_s, address_array[x].to_s
  redis.set "phone" + x.to_s, phones_array[x].to_s
  redis.set "info" + x.to_s, info_array[x].to_s
  full_address = address_array[x].to_s
  #if there is an address present, convert it to a google friendly string and convert it to lat and long with the google maps api. Store in redis for later use.
  #This is the most time consuming part, maybe try to optimize it later.
  if full_address.length != 0
  response = URI.parse(google_url + full_address.gsub(/\s/, '+') + google_api_key).read
  response_hash = JSON.parse(response)
  redis.set "lat" + x.to_s, response_hash['results'][0]['geometry']['location']['lat'].inspect
  redis.set "lng" + x.to_s, response_hash['results'][0]['geometry']['location']['lng'].inspect
  end
  x += 1
end
