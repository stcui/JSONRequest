require 'rubygems'
require 'sinatra'
require 'json'

get '/' do
  path = File.dirname(__FILE__) << "/sample.json"
  File.open(path, "r").read
end
