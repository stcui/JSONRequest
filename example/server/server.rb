require 'rubygems'
require 'sinatra'
require 'json'

set :environment, :developemnt

get '/' do
  path = File.dirname(__FILE__) << "/sample.json"
  sleep(1)
  File.open(path, "r").read
end
