require 'rubygems'
require 'uri'
require 'net/http'


def resolve(u)
   # initial values to return
   url = u
   found = url

   # the usual ruby GET stuff
   begin
     puts "Checking url #{u}"
     url = URI.parse u
   rescue URI::InvalidURIError
     puts "invalid uri"
   rescue Exception => e
     puts "problem checking url: #{e}"
   end
   req = Net::HTTP::Get.new(url.request_uri)

   # look for redirection headers
   begin
     res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
     body = res.body
     case res
     when Net::HTTPRedirection
       found = res['Location']
       puts "Found a redirection #{found}"
       #return resolve(found) #this is recursive so may want to stop it doing that too many times
     end
   rescue SocketError
     puts "socket error"
   rescue Exception => f
     puts "exception fetching url: #{f}"
   end
   return found
end

if(ARGV[0])
   url = resolve(ARGV[0])
   puts "result #{url}"
else
   puts "usage ruby url_resolver.rb url"
   puts "e.g ruby url_resolver.rb http://bit.ly/a0cbeS"
end

