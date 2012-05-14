require 'rubygems'
require 'sinatra'
require 'json'

set :environment, :developemnt

get '/' do
  path = File.dirname(__FILE__) << "/sample.json"
  sleep(1)
  File.open(path, "r").read
end

post '/upload' do
  msg = ""
  File.open('uploads/' + params['file'][:filename], "w") do |f|
    file = params['file'][:tempfile].read
    f.write(file)
    msg << params['file'].to_s
  end
  return {:msg => msg}.to_json
end
