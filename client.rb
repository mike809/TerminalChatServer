require 'set'

class Client

	attr_accessor :client, :username, :chatroom

	def initialize(client)
		@client = client
	end

	def puts(str, eom = true)
		@client.puts "\r" + (" "*30)
		@client.puts "\r<= #{str.strip}"
		@client.print "=>"# if eom
	end

	def gets
		input = @client.gets.strip
		@client.print "=>"
		input
	end

	# def accept_private_chat(other_user)
	# 	self.puts "#{other_user.username} wants talk privately. Do you accept? y/n"
	# 	self.client.stop
	# 	loop do
	# 		choice = self.client.gets.downcase
	# 		debugger
	# 		if choice == 'y'
	# 			self.client.start
	# 			return true
	# 		elsif choice == 'n'
	# 			self.client.start
	# 			return false
	# 		end
	# 		self.client.puts "Invalid choice."
	# 	end
	# end

	def disconnect
		if username
			puts "Disconecting #{self.username}"
		else
			puts "Disconecting user."
		end
		client.close
	end

	def leave_room
		puts "Client #{self.username} left room #{self.chatroom.name}"
		self.chatroom.broadcast "I left the room.", self
		self.chatroom.users.delete(self)
		chatroom = nil
	end

end