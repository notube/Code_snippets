require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'pp'
require 'json/pure'
require 'net/http'


def save(fn,str)
    begin
      open(fn, "w") { |file|
        file.write(str)
      }
    rescue Exception
     puts "oops #{fn}"   
    end
end

def get_rdf(pid,pref)

  useragent = "NotubeMiniCrawler/0.5"
  url = "http://www.bbc.co.uk/programmes/#{pid}.rdf"

  response = nil

  begin

    u =  URI.parse url
    puts "fetching #{u.to_s}"
    fn = "rdf/#{pref}/#{pid}.rdf"
    puts "fn #{fn}"

    req = Net::HTTP::Get.new(u.path,{'User-Agent' =>useragent})
    response = Net::HTTP.new(u.host, u.port).start { |http|
      http.request(req)
    }

    puts "okk #{fn}"
    begin
      open(fn, "w") { |file|
        file.write(response.body)
      }
    rescue Exception
     puts "oops #{fn}"
    end
  rescue Timeout::Error=> e
    puts "timeout error #{e}"
    return 0 
  rescue URI::InvalidURIError=> e
    puts "invalid uri error #{e} #{url}"
    return 0
  rescue
    puts "error #{url}"
    return 0
  end
  
end


def get_pids(iplayer_url,pref)

  # pages to start with
  az = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]

  #az = ["a","b","zz"]

  # get and parse each of these to get the pid

  #<li>
  #<a href="/iplayer/episode/b0112bxb/Ace_and_Vis_NBA_Star_Jeff_Adrien_Drops_By_For_Sunday_Dinner!/" title="Ace & Vis" 
  #class="episode">Ace & Vis</a></li>

  results = {}
  az.each do |alph|
    begin
      sleep 5
      u = "#{iplayer_url}#{alph}"
      puts u
      doc = Hpricot.XML(open(u))
      (doc/"li/a").each do |a|
        url = a.attributes['href']
        if(x = url.match("/iplayer/episode/(.*?)/"))
          pid =  x[1]
          title = a.attributes['title']
          results[pid] = title
        end
      end
      pid_str = JSON.pretty_generate(results)
      save("az/#{pref}/#{alph}.js",pid_str)
    rescue
      puts "oops"
    end
  end
  return results
end


iplayer_tv_url ="http://www.bbc.co.uk/iplayer/tv/a-z/"
iplayer_radio_url ="http://www.bbc.co.uk/iplayer/radio/a-z/"


tv_pids =  get_pids(iplayer_tv_url,"tv")
tv_pid_str = JSON.pretty_generate(tv_pids)
save("az/a-z_tv.js",tv_pid_str)

tv_pids.each do |k,v|
  sleep 2
  get_rdf(k,"tv")
end


radio_pids =  get_pids(iplayer_radio_url,"radio")
radio_pid_str = JSON.pretty_generate(radio_pids)
save("az/a-z_radio.js",radio_pid_str)

radio_pids.each do |k,v|
  sleep 2
  get_rdf(k,"radio")
end
