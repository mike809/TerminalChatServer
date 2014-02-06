require 'socket'
require_relative 'chatroom.rb'

class Server

	attr_accessor :clients, :chatrooms, :usernames, :room_names

	def initialize
		@clients = []
		@chatrooms = {}
		@usernames = Set.new
		@room_names = Set.new
	end

	def start 
		server = TCPServer.new 2000
		clients = []
		puts "Server Running on Port 2000"

		loop do

		  Thread.start(server.accept) do |user|
		  	puts "New user just connected."
		    client = Client.new(user)
		    client.puts help.join("\n")
		    client.puts "Welcome to the chat server\nLogin name?"
		    
		    loop do
		    	name = client.gets
		    	if name =~ /\/[a-zA-Z]+/
		    		client.puts "Username can not start with '/'"
		    		next 
		    	end
		    	unless usernames.include?(name)
		    		client.username = name
		    		usernames << name
		    		client.puts "Welcome #{client.username}!"
		    		puts "#{client.username} logged in."
		    		break
		    	end
			    client.puts "Sorry, name taken.\nLogin name?"
		    end
		    listen client
		  end
		end
	end

	def listen(client)
		puts "Listening"
		loop do
			_input = client.gets
			
			if _input =~ /\/[a-zA-Z]+/
				input = _input.split(' ')

				if input.length == 2
					command, arg = *input
				else
					command = input[0]
					arg = ""
				end

				case command
					when '/new'
						self.add_chatroom(client, arg)			

					when '/del'
						chatrooms[arg].delete(client)
						chatrooms.delete(arg)

					when '/users'
						if client.chatroom
							client.chatrooms.show_users
						else
							client.puts "You must be in a room the see their users."
						end

					when '/help'
						client.puts help.join("\n")

					when '/leave'
						client.leave_room

					when '/rooms'
						self.show_chatrooms client

					when '/quit'
						usernames.delete(client.username)
				    client.disconnect
				    break
				    
					when '/join'
						self.join(client, arg)
				
					else
						if client.chatroom
							client.chatroom.broadcast(input.join(' ') ,client)
						else
							client.puts "Join a room to send message."
						end
					end
			else
				if client.chatroom
					client.chatroom.broadcast(_input, client)
				else
					client.puts "Join a room to send message."
				end
			end
		end
	end

	def join(client, arg)
		if @chatrooms.include?(arg)

			client.chatroom = @chatrooms[arg]
			@chatrooms[arg].users << client

			client.puts "entering room: #{arg}", false
			@chatrooms[arg].show_users(client)

			puts "User #{client.username} joining room #{arg}"
		else
			puts "User #{client.username} tryed to join room #{arg}"
			client.puts "Room #{arg} does not currently exist."
		end
	end

	def add_chatroom(client, name)
		unless @chatrooms.include?(name)
			@chatrooms[name] = ChatRoom.new(name, client)
			client.chatroom = @chatrooms[name]
			client.puts "New room #{name}"
			puts "Room #{name} created by user #{client.username}"
		else
			puts "User #{client.usernaname} tried to create an already existent room."
			client.puts "Room #{name} already exist."
		end 
	end

	def show_chatrooms(client)
		puts "Displaying all rooms"
		client.puts "Active rooms are:", false
		chatrooms.each do |name, room|
			client.puts "* #{name} (#{room.users.count})", false
		end
		client.puts "end of list."
	end

	def help
		puts "Displaying help"
		["/rooms to see active rooms",
			"/join (chatname) to join an active room",
			"/leave to leave a chatroom",
			"/quit to close the chat",
			"/new to create new chatroom",
			"/del (room name) to delete a room",
		  "/users to see the users in a chatroom"]
	end
end