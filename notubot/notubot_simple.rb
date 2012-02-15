# simple ruby logger bot based on yail that also puts links into delicious

require 'rubygems'
require 'net/yail'
require 'cgi'
require 'socket'
require 'time'
require 'uri'
require 'open-uri'
require 'net/http'
require 'net/https'

include Socket::Constants


class Bot 


 @@user = 'notubot2'             # irc nick. Required
 @@password = ''                # password for irc, can be blank
 @@name = 'notubot2'             # name. Required
 @@server = 'irc.freenode.net'  # server. Required
 @@channel = '#notube2'         # channel. Required

 # url that it logs to, can be blank (it's for the help message)
 @@logurl = 'http://dev.notu.be/2011/01/notubot/'

 # if you want to send all urls posted to delicious (unless [off] is used)
 @@deliciousTags = 'notube' # space-delimited tags
 @@deliciousUsername = ""#required
 @@deliciousPassword = ""#required

 def self.user
    @@user
 end
 def self.password
    @@password
 end
 def self.name
    @@name
 end
 def self.server
    @@server
 end
 def self.channel
    @@channel
 end
 def self.logurl
    @@logurl
 end

 def self.deliciousTags
    @@deliciousTags
 end
 def self.deliciousUsername
    @@deliciousUsername
 end
 def self.deliciousPassword
    @@deliciousPassword
 end


 def Bot.log(message,nick,irc,sendToDelicious)
        t = Time.now
        t1 = t.getutc
        t2 = t1.strftime("%H-%M-%S") 
        t3 = t1.strftime("%H:%M:%S") 
        t4 = t1.strftime("%Y-%m-%dT%H:%M:%S") 
        t5 = t1.strftime("%Y-%m-%d") 
        filen = t1.strftime("%Y-%m-%d")

        text = message

        if text =~ /^\[off\]/

        else
          if text =~ /^#{name}, help/ || text =~ /^#{name}, halp/
             #puts "help asked for"

             m = "I'm a logger bot. I currently log to #{logurl}. I respect [off] at the start of a line and do not log it. Commands are #{name}, help. Any urls placed in the text go to http://delicious.com/notube. Urls with @twitter on the same line go to the @notube twitter account - please use responsibly!"

             irc.msg(channel, m)
          end

          if text =~ /((http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/\S*)?)/
             x = $1
             # puts "#{x} ..."
             str = x.to_s
             desc = text.gsub("@twitter","")
             desc.gsub!(str,"")

             #puts "Sending to delicious [1] #{x} ... #{nick},,,#{deliciousTags}"
             Thread.new do
                 u,title = resolve(str.strip)
                 sendToDelicious(u,title,nick,desc)
             end
          end

          doc = "#{t4}\s<#{nick}>\s#{text}\n"
          #puts "#{nick} #{text} #{t1}"        
          File.open("#{filen}.txt", 'a+') {|f| f.write(doc) }

          if File.exists?("#{filen}.html")
            File.delete("#{filen}.html")
          end  

          # we also want to have current versions
          cFilen = "latest"

          if File.exists?("#{cFilen}.txt")
            File.delete("#{cFilen}.txt")
          end  

          if File.exists?("#{cFilen}.html")
            File.delete("#{cFilen}.html")
          end  
  
          f2 = File.open("#{filen}.txt", 'r') 

          latestTxt = ""
          doc2 = "<html><body><h2>#{name} logs for #{t5}</h2>\n<p>Last updated <a href='#T#{t2}'>#{t4}</a></p>\n"
          while (line = f2.gets)
            latestTxt << line + "\n"
            arr = line.split(" ")
            user = arr[1]
            user.gsub!(/</,"&lt;")
            user.gsub!(/>/,"&gt;")
            d1 = Time.parse(arr[0])
            d2 = d1.strftime("%H-%M-%S") 
            d3 = d1.strftime("%H:%M:%S") 
            txt = arr[2, arr.length].join(" ")
            txt = CGI.escapeHTML(txt)
            z = "<p><span class='time' id='T#{d2}'><a href='#T#{d2}'>#{d3}</a></span> <span class='nick'>#{user}</span> <span class='comment'>#{txt}</span></p>\n"
            doc2 << z
          end

          doc2 << '</body></html>'

          File.open("#{cFilen}.txt", 'a+') {|f| f.write(latestTxt) }
          File.open("#{filen}.html", 'a+') {|f| f.write(doc2) }
          File.open("#{cFilen}.html", 'a+') {|f| f.write(doc2) }

        end
 end

 # Tries to get the title of a url

 def Bot.resolve(u)
   u = u.sub(/\.$/,'')
   url = u
   title = u.to_s

   begin
     #puts "Checking url #{u}"
     url = URI.parse u
   rescue URI::InvalidURIError
     puts "invalid uri"
     return u,title
   rescue Exception => e
     puts "problem checking url: #{e}"
     return u,title
   end
   req = Net::HTTP::Get.new(url.request_uri)
   begin
     res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
     body = res.body           
     case res
     when Net::HTTPRedirection
       uu = res['Location']
       #puts "Found a redirection"
       return resolve(uu)
     when Net::HTTPSuccess
       if body!=nil
          body.gsub!(/\n/,'')
          body.gsub!(/\r/,'')
          #puts "BODY #{body}"
          if body =~ /<title>(.*?)</
            title = $1
            title.gsub!(/"/,"'")
            #puts "TITLE found #{title}"
          end
       else
         #puts "BODY is nil #{body}"
       end
       if title==nil || title.strip=="" || title =~ /302 Found/
          title = url
       end         
       return url, title
     else
       puts "url is crud"
       return u,title
     end
   rescue SocketError
     puts "socket error"
     return u,title
   rescue Exception => f
     puts "exception fetching url: #{f}"
     return u,title
   end
 end

 def Bot.sendToDelicious(myurl,title,nick,desc)
   begin
      #puts "Sending update to delicious #{myurl}, #{title}, #{deliciousTags} #{nick}.."
      t = URI.escape(title.to_s)
      r = URI.escape(myurl.to_s)
      http = Net::HTTP.new('api.del.icio.us', 443)
      http.use_ssl = true
      if (desc && desc!="")
        desc = URI.escape(desc.to_s)
      else
        desc=""
      end
      nick.gsub!("-","")
      deliciousTags = CGI::escape("#{deliciousTags} #{nick}")
      z = "/v1/posts/add?url=#{r}&description=#{t}&extended=#{desc}&tags=#{deliciousTags}"
      #puts z
      agent = 'NoTube irc bot v0.1'
      xml = http.start { |http|
        req = Net::HTTP::Get.new(z, {'User-Agent' => agent})
        #puts "req #{req}"
        req.basic_auth(deliciousUsername, deliciousPassword)
        response = http.request(req)
        #puts "resp #{response}"
        #puts http.request(req).body
      }
   rescue Exception => f
     puts "exception posting to delicious: #{f}"
     #puts f.backtrace
   end
       
 end
end


# b = Bot.new
# Bot.sendToDelicious("http://twitrratr.com/search/eurovision","eurovision | twitrratr")

# puts b.resolve('http://www.google.com')
# puts b.resolve('http://jkfhdjksfhkdshf')


begin

  def welcome(text, args)
     @irc.join(Bot.channel)
     return false
  end

  def logMsg(fullactor, user, channel, text)
     #puts "user is #{user}"
     Bot.log(text,user,@irc,true)

    # check if this is a /msg command, or normal channel talk
#    if text =~ /#{@bot_name}/
#      incoming_private_message(user, text)
#    else
#      incoming_channel_message(user, channel, text)
#    end
  end

  def logMsgAct(fullactor, user, channel, text)
     #puts "user is #{user}"
     Bot.log(text,user,@irc,false)

  end

  def incoming_private_message(user, text)
    case text
      when /\bhelp\b/i
   
      return
    end
    @irc.msg(user, "enter \"HELP\"")
  end
   
  def incoming_channel_message(user, channel, text)
    log_channel_message(user, channel, "<#{user}> #{text}")
  end

        
  def log_channel_message(user, channel, text)
#    puts "LOG: #{text}"
  end


  b = Bot.new

  @irc = Net::YAIL.new(
     :address    => Bot.server,
     :username   => Bot.user,
     :server_passname => Bot.password,
     :realname   => Bot.name,
     :nicknames  => [Bot.user]
  ) 

   @irc.prepend_handler :incoming_welcome, method(:welcome)
   @irc.prepend_handler :incoming_msg, method(:logMsg)
   @irc.prepend_handler :incoming_act, method(:logMsgAct)
   @irc.start_listening

   while @irc.dead_socket == false
     # Avoid major CPU overuse by taking a very short nap
     sleep 0.05
   end


end


