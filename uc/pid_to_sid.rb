require 'rubygems'
require 'json/pure'
require 'pp'
require 'uri'
require 'cgi'
require 'net/http'


  def get_url(url)
    #first get the crid from the resolver
    uu = "http://services.notu.be/resolve?uri\[\]=#{url}"
    crid = get_crid(uu)    
    puts "FOUND CRID #{crid}"
# here interact with UC
    if(crid)
      uc = "http://localhost:48875/uc/"
      c_enc = CGI.escape(crid)
      uuu = "#{uc}search/global-content-id/#{c_enc}"
      sid,cid = get_sid(uuu)
      puts "SID #{sid}"
    end 

  end      


  def get_crid(url)
              useragent = "NotubeMiniCrawler/0.6"
              u =  URI.parse url
              req = Net::HTTP::Get.new(u.request_uri,{'User-Agent' => useragent})
              begin
                res2 = Net::HTTP.new(u.host, u.port).start {|http|http.request(req) }
              end

              r = nil
              begin
                 r = res2.body
              rescue OpenURI::HTTPError=>e
                 case e.to_s
                    when /^404/
                       r = nil
                       raise 'Not Found'
                    when /^304/
                       r = nil
                       raise 'No Info'
                    end
              end

              j = nil
              crid = nil
              if(r)
                 j = JSON.parse(r)
                 crid = j[0]["crid"]
              end
              return crid

  end


  def get_sid(url)
              useragent = "NotubeMiniCrawler/0.6"
              u =  URI.parse url
              req = Net::HTTP::Get.new(u.request_uri,{'User-Agent' => useragent})
              begin
                res2 = Net::HTTP.new(u.host, u.port).start {|http|http.request(req) }
              end
              r = nil
              begin
                 r = res2.body
              rescue OpenURI::HTTPError=>e
                 case e.to_s
                    when /^404/
                       r = nil
                       raise 'Not Found'
                    when /^304/
                       r = nil
                       raise 'No Info'
                    end
              end

              j = nil
              cid = nil
              sid = nil
              if(r)
# <content sid="1001" cid="2011-04-04T17%3a00%3a00Z" 
                 aa = r.gsub(/.*<content sid=\"/,"")              
                 aa.gsub!(/\" cid=.*/,"")
                 sid=aa
              end
              return sid,cid
  end


# e.g. ruby pid_to_sid.rb http://www.bbc.co.uk/programmes/b00zqfn5
get_url(ARGV[0])


