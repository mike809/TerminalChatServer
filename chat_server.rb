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
				break if self.route(_input, client)
			else
				self.send_message(client, _input)
			end
		end
		self.quit client
	end

	def route(_input, client)
		command, args = *self.parse_input(_input)

		case command
			when '/new',      '/n'
				self.add_chatroom(client, *args)			
			when '/del',      '/d'
				chatrooms[args[0]].delete(client)
				chatrooms.delete(args[0])
			when '/users',    '/u'
				self.display_users client
			when '/help',     '/h'
				client.puts help.join("\n")
			when '/leave',    '/l'
				client.leave_room
			when '/rooms',    '/r'
				self.show_chatrooms client
			when '/password', '/p'
				client.chatroom.show_password(client)
			when '/quit',     '/q'
				return true
		  when '/chat',     '/c'
		  	self.private_chat(client, args[0])
			when '/join',     '/j'
				self.join_chatroom(client, *args)
			else
				self.send_message(client, _input)
			end
			false
	end

	def parse_input(_input)
		input = _input.split(' ')
		[input[0], input[1..-1]]
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
		other_user = clients[arg]
		# return unless other_user.accept_private_chat(client)
		client.leave_room
  	self.add_chatroom(
  		client, 
  		"Private chat: #{client.username} and #{other_user.username}",
  		true
  	)
  	self.join_chatroom(other_user, client.chatroom.name)
	end

	def join_chatroom(client, name, password = '')
		if @chatrooms.include?(name)
			@chatrooms[name].join(client, @chatrooms, name, password)
		else
			puts "User #{client.username} tryed to join room #{name}"
			client.puts "Room #{arg} does not currently exist."
		end
	end

	def add_chatroom(client, name, hidden = false, password = '')
		unless @chatrooms.include?(name)
			@chatrooms[name] = ChatRoom.new(name, client, hidden, password)
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
		client.puts "Active rooms are:"
		chatrooms.each do |name, room|
			next if room.hidden?
			client.puts "* #{name} (#{room.users.count}) #{'private' if room.password != ""}"
		end
		client.puts "end of list."
	end

	def help
		puts "Displaying help"
		[ "All commans shortcuts are the /(initial letter of)",
			"/rooms to see active rooms",
			"/password to see the password of the room you are in if you own the room",
			"/chat (user username)to private message user",
			"/join (chatname) (password) if applies to join an active room",
			"/leave to leave a chatroom",
			"/quit to close the chat",
			"/new to create new chatroom",
			"/del (room name) to delete a room",
		  "/users to see the users in a chatroom"
		]
	end
end