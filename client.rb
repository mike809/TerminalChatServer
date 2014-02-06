require 'set'

class Client

	attr_accessor :client, :username, :chatroom

	def initialize(client)
		@client = client
	end

	def puts(str, eom = true)
		@client.puts "<= #{str.strip}"
		@client.print "=>" if eom
	end

	def gets
		@client.gets.strip
	end

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
		self.chatroom.users.delete(self)
		chatroom = nil
	end

end