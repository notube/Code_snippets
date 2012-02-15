require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'pp'
require 'json'
require 'net/http'
require 'net/https'


def save(fn,str)
    begin
      open("wiki/#{fn}", "w") { |file|
        file.write(str)
      }
    rescue Exception=>e
     puts "oops #{fn} #{e}"   
    end
end

def get_page(url,cookie,data)

      useragent = "NotubeMiniCrawler/0.5"

      u =  URI.parse url
      puts "fetching #{u.to_s}"
      begin

        headers = {
         'Cookie' => cookie,
         'Content-Type' => 'application/x-www-form-urlencoded'
        }

        http = Net::HTTP.new(u.host, u.port)
        http.use_ssl = true
        req = Net::HTTP::Get.new(u.request_uri,{'User-Agent' =>useragent})
        d = ""
        response, data = http.get(u.path, headers)
#        puts url.gsub(/.*\//,"")
#        puts response.body

#        save response body
        if(response && response.body)
          fn = url.gsub(/.*\//,"")
          save(fn,response.body)
        end
        return response.body
      rescue Timeout::Error=> e
        puts "timeout error #{e}"
        return 0 
      rescue URI::InvalidURIError=> e
        puts "invalid uri error #{e} #{url}"
        return 0
      rescue Exception=>e
        puts e
        puts e.backtrace
        puts "error #{url}"
        return 0
      end

  
end


def get_pages(cookie,titles,az)

  # pages to start with

  # get and parse each of these to get the pid
  az.each do |a|
    sleep(2)
    wiki_api_url ="https://notube.sti2.org/wiki/api.php?action=query&list=allimages&aifrom=#{a}&format=json&ailimit=500"
#    wiki_api_url ="https://notube.sti2.org/wiki/api.php?action=query&list=allimages&format=json&ailimit=500"

    puts wiki_api_url

    u =  URI.parse wiki_api_url
    http = Net::HTTP.new(u.host, u.port)
    http.use_ssl = true

    headers = {
     'Cookie' => cookie,
     'Content-Type' => 'application/x-www-form-urlencoded'
    }


    resp, data = http.get(u.path+"?"+u.query, headers)
    j = JSON.parse(resp.body)
    #pp j
    foo = j["query"]["allimages"]
    foo.each do |f|
      t = f["name"]
      u = f["url"]
      #t = t.gsub(/ /,"_")
      titles.push(u)
    end

#    puts "!!!!"
#    pp j

    if(j["query-continue"] && j["query-continue"]["allimages"])
puts "CONT"
    puts j["query-continue"]["allimages"]
      query_cont =  j["query-continue"]["allimages"]["aifrom"]

      if(query_cont)
        qc = query_cont.gsub(" ","_")
puts "OK"
puts query_cont
puts qc
        get_pages(cookie,titles,qc)      
      end 
    end 

  end
  return titles
  
end


#login


url = "https://notube.sti2.org/wiki/api.php"

# add username and password here
form_data = {"action"=>"login","lgname"=>"","lgpassword"=>"","format"=>"json"}
      
useragent = "NotubeMiniCrawler/0.5"
u =  URI.parse url
http = Net::HTTP.new(u.host, u.port)
http.use_ssl = true

req = Net::HTTP::Post.new(u.request_uri,{'User-Agent' =>useragent})
req.set_form_data(form_data)
response = http.request(req)
cookie = response.response['set-cookie']

j = JSON.parse(response.body)
token = j["login"]["lgtoken"]
pp token

headers = {
  'Cookie' => cookie,
  'Content-Type' => 'application/x-www-form-urlencoded'
}


# add username and password here
form_data = {"action"=>"login","lgname"=>"","lgpassword"=>"","lgtoken"=>token,"format"=>"json"}

d = "action=login&lgname=&lgpassword=&lgtoken#{token}&format=json"

resp, data = http.post(u.path, d, headers)

puts 'Code = ' + resp.code
puts 'Message = ' + resp.message
resp.each {|key, val| puts key + ' = ' + val}
#puts data


#url2 = "https://notube.sti2.org/wiki/index.php/Main_Page"

titles = []

#az = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9"]

az = ["0"]

pages = get_pages(cookie,titles,az);
puts "LENGTH"
puts pages.length
#pp pages

#=begin
pages.each do |page|
  sleep 2
#  page = "https://notube.sti2.org/wiki/index.php/#{page}"
  get_page(page,cookie,"")
end
#=end
