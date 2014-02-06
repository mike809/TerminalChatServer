require 'debugger'
require_relative 'client.rb'
require_relative 'chat_server'


server = Server.new
puts "Starting server...."
server.start

