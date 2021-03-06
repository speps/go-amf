require 'socket'
require 'rocketamf'

port = 4242
server = TCPServer.new port
puts "server created on port #{port}"

def bytes_to_hex(s)
  s.each_byte.map { |b| "%02x" % [b] }.join
end

def hex_to_bytes(s)
  s.scan(/../).map { |x| x.hex.chr }.join
end

def transform_noop(in_bytes)
  return in_bytes
end

def transform_amf(in_bytes, version)
  begin
    out = RocketAMF.deserialize(in_bytes, version)
    puts out.inspect
    result = RocketAMF.serialize(out, version)
    return result
  rescue StandardError => e
    puts e
    return ""
  end
end

amf_version = ARGV[0].to_i

loop do
	puts "waiting for client"
	client = server.accept
	puts "client connected"
	loop do
		begin
			puts "waiting for data"
			in_data = client.gets.chomp
			puts "got [#{in_data}]"
			if in_data == "exit"
				exit 0
			end
			in_bytes = hex_to_bytes(in_data)
			# out_bytes = transform_noop(in_bytes)
			out_bytes = transform_amf(in_bytes, amf_version)
			out_data = bytes_to_hex(out_bytes)
			puts "sending [#{out_data}]"
			client.write out_data
		rescue StandardError
			break
		end
	end
	puts "closing socket"
	client.close
end
