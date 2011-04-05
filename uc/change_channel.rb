require 'rubygems'
require 'net/http'

def change_channel(sid)
    puts "Changing to channel #{sid}"
    url = "http://localhost:48875/uc/outputs/0?sid=#{sid}"
    u = URI.parse(url)
    req = Net::HTTP::Post.new( u.path+ '?' + u.query )
    begin
      res2 = Net::HTTP.new(u.host, u.port).start {|http|http.request(req) }
      puts res2
    rescue Exception=>e
      puts e
    end
end

 
# e.g. ruby change_channel.rb 1001
change_channel(ARGV[0]) 
