require 'rubygems'
require 'net/http'
require 'uri'
require 'open-uri'
require 'hpricot'
require 'pp'

# parse file (pid, ct, st), tab separated
# - if core-title
# - if without stopwords it's one word, try the core and series title, both in inverted ocmmas
# - if it's 2 word or more, just use the title
# - pick the first result
# - grab the n3


#<div id="content">
#  <ul id="search-results">
#    <li class="result">
#      <span class="title"><a href="/titles/List_of_Two_Pints_of_Lager_and_a_Packet_of_Crisps_episodes">
# which redirects, at that point you can get the n3 version

def do_search(q)
 q = URI.encode(q)
 u = "http://dbpedialite.org/search?term=#{q}"
 id = nil
 title = nil

 STDERR.puts "u is #{u}"

 begin
   doc = open(u) { |f| Hpricot(f) }

 #puts doc
   href = doc.at("//li[@class='result']/span[@class='title']/a")["href"]
   if(href)
     STDERR.puts "http://dbpedialite.org#{href}"
     title =  href.gsub("/titles/","")
     STDERR.puts "TITLE #{title}"

=begin
     # this segment gets the id and saves the n3
     # then follow the redirect
     id,r = follow_redirect("http://dbpedialite.org#{href}") 

     # and grab the n3 from that(result is the n3)
     ##puts "result is #{id}"

     # and save the n3 using page id
     open("n3/#{id}.n3", "w") do |file|
         file.write(r)
     end
=end   

   end
 rescue Exception=>e
   STDERR.puts "error #{e}"
 end

 # and save the title and page id
 # which title? actually we want pid
 # if no href return nil so we can do another search
 # return id,title

# return title,id
 return title
end

def follow_redirect(u)

   uu = nil
   url = URI.parse u

   begin

     req = Net::HTTP::Get.new(url.request_uri)
     req.initialize_http_header({"User-Agent" => "NoTube Crawler 0.4"})
     res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }

     body = res.body
     case res
     when Net::HTTPRedirection
       uu = res['Location']
       STDERR.puts "Found a redirection to #{uu}.n3"
       return resolve_n3_url("#{uu}.n3")
     end
   rescue SocketError
     STDERR.puts "socket error\n"
     return nil
   rescue Exception => f
     STDERR.puts "exception fetching url: #{f}\n"
     return nil
   end
end

def resolve_n3_url(u)
     id = u.gsub("http://dbpedialite.org/things/","")
     id.gsub!(".n3","")
     url = URI.parse u

     req = Net::HTTP::Get.new(url.request_uri)
     req.initialize_http_header({"User-Agent" => "NoTube Crawler 0.4"})
     res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }

     n3 = res.body
     return id,n3
end


filen="pids_detail_all.txt"

ids={}
titles={}
approx=[]

file = File.new(filen, "r")
while (line = file.gets)
    line.chomp!
    arr = line.split("\t")
    pid=arr[0].chomp()
    ct=arr[6]
    st=arr[7]
    if(ct)
      ct = ct.chomp()
      ct.gsub!(/\,(\S)/,", \\1")
      ct.gsub!(/\.(\S)/,". \\1")
    end
    if(st)
      st = st.chomp()
      st.gsub!(/\,(\S)/,", \\1")
      st.gsub!(/\.(\S)/,". \\1")
    end
#    puts "ct #{ct}"
#    puts "st #{st}"

    if(ct && ct!="")
      t = ct.split(" ")
      if(st && st!="" && t.size==1)
         # - if without stopwords it's one word, try the core and series title, both in inverted ocmmas
         q = "#{ct} \"#{st}\""
         STDERR.puts "q1 is #{q}\n"
      elsif (t.size>1)
         q = "\"#{ct}\""
         STDERR.puts "q2 is #{q}\n"
      end
    else
      if(st && st!="")
         q = "\"#{st}\""
         STDERR.puts "q3 is #{q}\n"
      end
    end

    title = do_search(q)
=begin
# if those both fail, try a cmbination with no inverted commas
# not finding this works too well
    if(id==nil)
      title = do_search("#{ct} #{st}")
      approx.push(id)
      sleep 1
    end
    #ids[pid]=id
=end
    if(title!=nil)
      titles[pid]=title
    end
    sleep 1
end
#pp ids
pp titles


open('dbp_titles.txt', 'w') { |f|
  titles.each do |pid,title|
    f << "#{pid}\t#{title}\n"
  end
}


#do_search(ARGV[0])
