#!/usr/bin/env ruby
require 'redis'
require 'sinatra'
require 'haml'
require 'tilt/haml'
#set :bind, '0.0.0.0'
class RenderPage < Sinatra::Base
  attr_accessor :redis, :x
  @x = 0
  @redis = Redis.new(:host => "127.0.0.1", :port => 6379, :db => 0)
  keyspace = @redis.scan(0, :match => "address*", :count => 10000)
  keyspace[1].each do |item|
    @x += 1
  end
  class OutputRedis
    def initialize(counts, redis_conn)
      @y = counts
      @redis_connection = redis_conn
    end
    def each
      @y.times do |iter|
         name = @redis_connection.get("names" + iter.to_s).to_s + "<br>"
         address = @redis_connection.get("address" + iter.to_s).to_s + "<br>"
         phone = @redis_connection.get("phone" + iter.to_s).to_s + "<br>"
         info = @redis_connection.get("info" + iter.to_s).to_s + "<p>"
         yield name + address + phone + info
#          yield name
#         redis.get("address" + iter.to_s)
#         redis.get("phone" + iter.to_s)
#         redis.get("info" + iter.to_s)
    end
  end
end
output = OutputRedis.new(@x, @redis)
get '/' do
  output
end
end
