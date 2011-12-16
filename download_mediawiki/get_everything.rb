require 'rubygems'
require 'open-uri'
require 'pp'
require 'json'
require 'net/http'
require 'net/https'

# save a file

def save(fn,str)
    begin
      open("wiki/#{fn}", "w") { |file|
        file.write(str)
      }
    rescue Exception=>e
     puts "oops #{fn} #{e}"   
    end
end

# get a single page

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

        response, data = http.get(u.path, headers)

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


# recursively get the lists of pages by starting a-z0-9

def get_pages(cookie,titles,az,url)

  # pages to start with

  # get and parse each of these to get the pid
  az.each do |a|
    sleep(2)
    wiki_api_url ="#{url}?action=query&list=allpages&apfrom=#{a}&format=json"

    u =  URI.parse wiki_api_url
    http = Net::HTTP.new(u.host, u.port)
    http.use_ssl = true

    headers = {
     'Cookie' => cookie,
     'Content-Type' => 'application/x-www-form-urlencoded'
    }

    resp, data = http.get(u.path+"?"+u.query, headers)
    j = JSON.parse(resp.body)
    foo = j["query"]["allpages"]
    foo.each do |f|
      t = f["title"]
      t = t.gsub(/ /,"_")
      titles.push(t)
    end

    if(j["query-continue"] && j["query-continue"]["allpages"])
      query_cont =  j["query-continue"]["allpages"]["apfrom"]
      if(query_cont)
        qc = query_cont.gsub(" ","_")
        get_pages(cookie,titles,qc,url)      
      end 
    end 

  end
  return titles
  
end


#login

url = "https://example.com/wiki/api.php"
username = "yourusername"
password = "yourpassword"

form_data = {"action"=>"login","lgname"=>username,"lgpassword"=>password,"format"=>"json"}
      
useragent = "NotubeMiniCrawler/0.5"
u =  URI.parse url
http = Net::HTTP.new(u.host, u.port)
http.use_ssl = true

# login and get the cookie

req = Net::HTTP::Post.new(u.request_uri,{'User-Agent' =>useragent})
req.set_form_data(form_data)
response = http.request(req)
cookie = response.response['set-cookie']

j = JSON.parse(response.body)
token = j["login"]["lgtoken"]

headers = {
  'Cookie' => cookie,
  'Content-Type' => 'application/x-www-form-urlencoded'
}


# finish off the authentication

d = "action=login&lgname=#{username}&lgpassword=#{password}&lgtoken#{token}&format=json"
resp, data = http.post(u.path, d, headers)

titles = []
az = ["0"]

# starting at pages begining with 0, get all the pages titles recursively

pages = get_pages(cookie,titles,az,url);

# loop through the pages downloading them, with the cookie we got earlier

pages.each do |page|
  sleep 2
  page = "#{url}/#{page}"
  get_page(page,cookie,"")
end
