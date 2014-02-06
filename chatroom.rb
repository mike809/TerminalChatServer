class ChatRoom

	attr_accessor :name, :users

	def initialize(name, client, hidden = false)
		@name = name
		@owner = client
		@users = Set.new [client]
		@hidden = hidden
	end

	def add_user(user)
		@users.inlcude?(user.username) ? false : @users << user.username
	end

	def broadcast(msg, client)
		users.each do |user|
			next if user == client
			user.puts "#{client.username}: #{msg}"
		end
	end

	def hidden?
		@hidden
	end

	def join(client, chatrooms, arg)
			client.leave_room if client.chatroom

			client.chatroom = chatrooms[arg]
			chatrooms[arg].users << client

			client.puts "entering room: #{arg}", false
			chatrooms[arg].show_users(client)

			puts "User #{client.username} joining room #{arg}"
	end

	def delete(client)
		if client == @owner
			users.each do |user|
				if user == client
					user.puts "You deleted chatroom #{name}"
				else
					user.puts "Chatroom #{name} deleted by owner."
				end
				user.chatroom = nil
			end
		else
			client.puts "You are not allowed to delete this room."
		end
	end

	def show_users(client)
		users.each do |user|
			if user == client
				client.puts "#{user.username} (** this is you)", false
			else
				client.puts "#{user.username}", false
			end
		end
		client.puts "end of list."
	end

end