wyozimc.Providers = {}

function wyozimc.AddProvider(tbl)
	table.insert(wyozimc.Providers, tbl)
end

function wyozimc.FindProvider(url)
	url = url:Trim()
	for _, provider in pairs(wyozimc.Providers) do
		local cbres = provider.UrlMatcher and provider.UrlMatcher(url) or nil
		if cbres then
			return provider, {Matches = {cbres}, WholeUrl = url}
		end
		for _, pattern in ipairs(provider.UrlPatterns) do
			local m = {url:match(pattern)}
			if m[1] then
				return provider, {Matches = m, WholeUrl = url}
			end
		end 
	end

	return nil
end

-- Not sure what this does but some black magic for sure
function wyozimc.JSEscape(str)
    return str:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\'", "\\'")
        :gsub("\r", "\\r"):gsub("\n", "\\n")
end

function wyozimc.URLEscape(s)
    s = tostring(s)
    local new = ""
    
    for i = 1, #s do
        local c = s:sub(i, i)
        local b = c:byte()
        if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or
            (b >= 48 and b <= 57) or
            c == "_" or c == "." or c == "~" then
            new = new .. c
        else
            new = new .. string.format("%%%X", b)
        end
    end
    
    return new
end


function wyozimc.URLUnEscape(str)
    return str:gsub("%%([A-Fa-f0-9][A-Fa-f0-9])", function(m)
        local n = tonumber(m, 16)
        if not n then return "" end -- Not technically required
        return string.char(n)
    end)
end


wyozimc.AddProvider({
	Name = "Youtube",
	UrlPatterns = {
    	"^https?://youtu%.be/([A-Za-z0-9_%-]+)",
    	"^https?://youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
    	"^https?://[A-Za-z0-9%.%-]*%.youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)#t=(%d+)",
    	"^https?://[A-Za-z0-9%.%-]*%.youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
    	"^https?://[A-Za-z0-9%.%-]*%.youtube%.com/v/([A-Za-z0-9_%-]+)",
    	"^https?://youtube%-nocookie%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
    	"^https?://[A-Za-z0-9%.%-]*%.youtube%-nocookie%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
	},
	QueryMeta = function(data, callback, failCallback)
		local uri = data.Matches[1]
	    
	    local url = Format("http://gdata.youtube.com/feeds/api/videos/%s?alt=json", uri)

	    wyozimc.Debug("Fetching query for " .. uri .. " from " .. url)

	    http.Fetch(url, function(result, size)
	        if size == 0 then
	            failCallback("HTTP request failed (size = 0)")
	            return
	        end

	        local data = {}
	        data["URL"] = "http://www.youtube.com/watch?v=" .. uri
	        
	        local jsontbl = util.JSONToTable(result)

	        if jsontbl and jsontbl.entry then
	        	local entry = jsontbl.entry
	        	data.Title = entry["title"]["$t"]
	       		data.Duration = tonumber(entry["media$group"]["yt$duration"]["seconds"])
	       	else
	       		data.Title = "ERROR"
	       		data.Duration = 60 -- lol wat
	        end

	        callback(data)

	    end)
	end,
	TranslateUrl = function(data, callback)
		local qualint = data.Quality or 0 -- TODO
		local vqstring = ""
		if qualint == 2 then
			vqstring = "hd1080"
		elseif qualint == 1 then
			vqstring = "hd720"
		end

		local startat = math.Round(data.StartAt or (data.Matches[2] and tonumber(data.Matches[2])) or 0)
		
		callback("http://www.youtube.com/watch_popup?v=" .. wyozimc.JSEscape(data.Matches[1]) .. "&vq=" .. vqstring .. "&start=" .. tostring(startat))
	end,
	FuncSetVolume = function(volume)
		return [[try {
		document.getElementById('player1').setVolume(]] .. (volume*100) .. [[);
		} catch (e) {}
		]]
	end
})
wyozimc.AddProvider({
	Name = "Vimeo",
	UrlPatterns = {
    	"^https?://www.vimeo.com/(%d*)/?",
    	"^https?://vimeo.com/(%d*)/?",
	},
	QueryMeta = function(data, callback, failCallback)
		local uri = data.Matches[1]
	    
	    local url = Format("http://vimeo.com/api/v2/video/%s.json", uri)

	    wyozimc.Debug("Fetching query for " .. uri .. " from " .. url)

	    http.Fetch(url, function(result, size)
	        if size == 0 then
	            failCallback("HTTP request failed (size = 0)")
	            return
	        end

	        local data = {}
	        data["URL"] = "http://www.vimeo.com/" .. uri
	        
	        local entry = util.JSONToTable(result)[1]

	        data.Title = entry["title"]
	        data.Duration = tonumber(entry["duration"])

	        callback(data)

	    end)
	end,
	TranslateUrl = function(data, callback)
		callback("http://player.vimeo.com/video/" .. tostring(data.Matches[1]) .. "?autoplay=1") -- #t=" .. tostring(math.Round(data.StartAt or 0)) .. "s" Doesnt seem to work properly on awesomium?
	end,
	FuncSetVolume = function(volume)
		return ""
	end
})
--http://player.vimeo.com/video/73605534?autoplay=1

wyozimc.AddProvider({
	Name = "SoundCloud",
	UrlPatterns = {
    	"^https?://www.soundcloud.com/([A-Za-z0-9_%-]+)/([A-Za-z0-9_%-]+)/?",
    	"^https?://soundcloud.com/([A-Za-z0-9_%-]+)/([A-Za-z0-9_%-]+)/?",
	},
	QueryMeta = function(data, callback, failCallback)

	    local url = Format("http://api.soundcloud.com/resolve.json?url=http://soundcloud.com/%s/%s&client_id=YOUR_CLIENT_ID", data.Matches[1], data.Matches[2])

	    wyozimc.Debug("Fetching query from " .. url)

	    http.Fetch(url, function(result, size)
	        if size == 0 then
	            MsgN("HTTP request failed (size = 0)")
	            return
	        end

	        local entry = util.JSONToTable(result)

	        callback({
	        	Title = entry.title,
	        	Duration = tonumber(entry.duration) / 1000
	        })

	    end)
	end,
	SetHTML = function(data, url)
		return [[<!DOCTYPE html>
<html><head></head><body>
  <iframe 
  		  id="sciframe"
          width="100%"
          height="465"
          scrolling="no"
          frameborder="no">
  </iframe>

  <script src="http://w.soundcloud.com/player/api.js"></script>
  <script>
    var widgetUrl = "]] .. url .. [[";

    var iframe = document.getElementById("sciframe");
    iframe.src = "http://w.soundcloud.com/player/?url=" + widgetUrl;
    var widget = SC.Widget(iframe);

    //window.onload = function() {
	    var widgetOptions = {
	      "auto_advance": true,
	      "auto_play": true
	    };
	    widget.load(widgetUrl, widgetOptions);
	    widget.seekTo(]] .. tostring(math.Round(data.StartAt or 0 * 1000)) .. [[);
	//}

    function setSoundcloudVolume(vol) {
      widget.setVolume(vol);
    }
  </script></body></html>]]
	end,
	FuncSetVolume = function(volume)
		return "if (typeof setSoundcloudVolume !== \"undefined\") setSoundcloudVolume(" .. tostring(volume * 100) .. ")"
	end
})
wyozimc.AddProvider({
	Name = "Website",
	UrlPatterns = {
    	"^https?://(.*)%.mp3",
    	"^https?://(.*)%.ogg",
	},
	QueryMeta = function(data, callback, failCallback)
		callback({
        	Title = data.WholeUrl:match( "([^/]+)$" )
        })
	end,
	TranslateUrl = function(data, callback)
		callback(data.WholeUrl)
	end,
	FuncSetVolume = function(volume, soundchannel)
		if soundchannel then
			soundchannel:SetVolume(volume)
		end
		return ""
	end,
	UseGmodPlayer = true
})
wyozimc.AddProvider({
	Name = "Online Radio",
	UrlPatterns = {
    	"^https?://(.*)%.pls"
	},
	QueryMeta = function(data, callback, failCallback)
		callback({
        	Title = data.WholeUrl:match( "([^/]+)$" ),
        	Duration = -1 -- streaming
        })
	end,
	TranslateUrl = function(data, callback)
		callback(data.WholeUrl)
	end,
	FuncSetVolume = function(volume, soundchannel)
		if soundchannel then
			soundchannel:SetVolume(volume)
		end
		return ""
	end,
	UseGmodPlayer = true
})