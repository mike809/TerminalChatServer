require 'socket'
require_relative 'chatroom.rb'

class Server

	attr_accessor :clients, :chatrooms, :usernames, :room_names

	def initialize
		@clients = {}
		@chatrooms = {}
		@usernames = Set.new
		@room_names = Set.new
	end

	def start 
		server = TCPServer.new 2000
		puts "Server Running on Port 2000"

		loop do

		  Thread.start(server.accept) do |user|
		  	puts "New user just connected."
		    client = Client.new(user)
		    client.puts "Type /help for help"
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
		    		clients[name] = client
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
				command, arg = self.parse_input(_input)

				case command
					when '/new',   '/n'
						self.add_chatroom(client, arg)			
					when '/del',   '/d'
						chatrooms[arg].delete(client)
						chatrooms.delete(arg)
					when '/users', '/u'
						self.display_users client
					when '/help',  '/h'
						client.puts help.join("\n")
					when '/leave', '/l'
						client.leave_room
					when '/rooms', '/r'
						self.show_chatrooms client
					when '/quit',  '/q'
						self.quit client
				    break
				  when '/chat',  '/c'
				  	self.private_chat(client, arg)
					when '/join',  '/j'
						self.join_chatroom(client, arg)
					else
						self.send_message client, _input
					end
			else
				self.send_message(client, _input)
			end
		end
	end

	def parse_input(_input)
		input = _input.split(' ')
		if input.length == 2
			return *input
		end
		input << ''
	end

	def send_message(client, input)
		if client.chatroom
			client.chatroom.broadcast(input, client)
		else
			client.puts "Join a room to send message."
		end
	end

	def display_users(client)
		if client.chatroom
			client.chatroom.show_users(client)
		else
			client.puts "You must be in a room the see their users."
		end
	end

	def quit(client)
		client.leave_room if client.chatroom
		usernames.delete(client.username)
    client.disconnect
	end
	
	def private_chat(client, arg)
		client.leave_room
  	other_user = clients[arg]
  	self.add_chatroom(
  		client, 
  		"Private chat: #{client.username} and #{other_user.username}",
  		true
  	)
  	self.join(other_user, client.chatroom.name)
	end

	def join_chatroom(client, arg)
		if @chatrooms.include?(arg)
			@chatrooms[arg].join(client, @chatrooms, arg)
		else
			puts "User #{client.username} tryed to join room #{arg}"
			client.puts "Room #{arg} does not currently exist."
		end
	end

	def add_chatroom(client, name, hidden = false)
		unless @chatrooms.include?(name)
			@chatrooms[name] = ChatRoom.new(name, client, hidden)
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
			next if room.hidden?
			client.puts "* #{name} (#{room.users.count})", false
		end
		client.puts "end of list."
	end

	def help
		puts "Displaying help"
		[ "All commans shortcuts are the /(initial letter of)",
			"/rooms to see active rooms",
			"/chat (user username)to private message user",
			"/join (chatname) to join an active room",
			"/leave to leave a chatroom",
			"/quit to close the chat",
			"/new to create new chatroom",
			"/del (room name) to delete a room",
		  "/users to see the users in a chatroom"]
	end
end