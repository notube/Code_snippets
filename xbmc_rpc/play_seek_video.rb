require 'rubygems'
require 'pp'
require 'net/http'

# a few methods for using XBMC's json RPC calls
# http://wiki.xbmc.org/index.php?title=JSON_RPC
# http://forum.xbmc.org/archive/index.php/t-68263-p-3.html

# seek (number of seconds in)
  def seek(secs)
     host = "localhost"
     port = "8080"
     post_ws = "/jsonrpc"
     req = Net::HTTP::Post.new(post_ws, initheader = {'Content-Type' =>'application/json'})
     data = "{ \"jsonrpc\": \"2.0\", \"method\": \"VideoPlayer.SeekTime\", \"params\": #{secs}, \"id\": 1 }"
     puts data
     req.body = data
     response = Net::HTTP.new(host, port).start {|http| http.request(req) }
     puts "Response #{response.code} #{response.message}: #{response.body}"
  end


# play video
# can be a url or a file path
  def play(programme_url)
     host = "localhost"
     port = "8080"
     post_ws = "/jsonrpc"
     req = Net::HTTP::Post.new(post_ws, initheader = {'Content-Type' =>'application/json'})
     data = "{ \"jsonrpc\": \"2.0\", \"method\": \"XBMC.Play\", \"params\": \"#{programme_url}\", \"id\": 1 }"
     puts data
     req.body = data
     response = Net::HTTP.new(host, port).start {|http| http.request(req) }
     puts "Response #{response.code} #{response.message}: #{response.body}"
  end

        
begin
  programme_url="file://tmp/example.flv"
  play(programme_url)
  seek(240)
end    
