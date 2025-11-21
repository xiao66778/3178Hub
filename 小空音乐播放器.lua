local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/xiao66778/xGB/main/91UI.lua"))()

local Window = WindUI:CreateWindow({
    Title = "小空音乐播放器 ", 
    Icon = "crown", 
    Author = "作者:晓空", 
    Folder = "xiaokongHub", 
    Size = UDim2.fromOffset(400, 300), 
    Transparent = false, 
    Theme = "Dark", 
    Resizable = true, 
    SideBarWidth = 200, 
    Background = "https://raw.githubusercontent.com/xiao66778/xGB/refs/heads/main/%E3%80%90%E5%93%B2%E9%A3%8E%E5%A3%81%E7%BA%B8%E3%80%91%E5%A4%AA%E7%A9%BA-%E5%AE%87%E5%AE%99-%E6%98%9F%E7%A9%BA.png",
    BackgroundImageTransparency = 0.42, 
    HideSearchBar = false, 
    ScrollBarEnabled = false, 
    User = { 
        Enabled = true, 
        Anonymous = false, 
        Callback = function() end,
    },
})

Window:EditOpenButton({ 
    Title = "小空音乐播放器 ", 
    Icon = "monitor-smartphone", 
    CornerRadius = UDim.new(0,32), 
    StrokeThickness = 3, 
    Color = ColorSequence.new(
        Color3.fromHex("0ECCFE"),  
        Color3.fromHex("FFFFFF") 
    ), 
    OnlyMobile = false, 
    Enabled = true, 
    Draggable = true, 
})

local MusicTab = Window:Tab({ 
    Title = "音乐播放器", 
    Icon = "music",
    Locked = false, 
})

local Button = Tab:Button({
    Title = "重要提示",
    Desc = "在第一次搜索时需要收缩一下搜索与结果的/n菜单栏再展开才能显示搜索结果",
    Locked = false,
    Callback = function()
        -- ...
    end
})

local HttpService = game:GetService("HttpService")
local CurrentSound = nil
local SearchButtons = {} 
local DownloadedFiles = {} 
local CacheFolder = ".SystemTemp_Cache"
local IsLooping = false 
local http_request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)

if not isfolder(CacheFolder) then makefolder(CacheFolder) end

local function PlayMusic(id, songName, artistName)
    if CurrentSound then CurrentSound:Destroy() CurrentSound = nil end

    local randomName = ""
    for i = 1, 10 do randomName = randomName .. string.char(math.random(97, 122)) end
    local filePath = CacheFolder .. "/" .. randomName .. ".tmp"
    local url = "https://music.163.com/song/media/outer/url?id=" .. id .. ".mp3"

    local response = http_request({
        Url = url, Method = "GET",
        Headers = {
            ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0.4472.124 Safari/537.36",
            ["Referer"] = "https://music.163.com/"
        }
    })

    if response.StatusCode == 200 and #response.Body > 5000 then
        writefile(filePath, response.Body)
        table.insert(DownloadedFiles, filePath)
        
        local sound = Instance.new("Sound")
        sound.Name = "WindMusicDriver"
        sound.SoundId = getcustomasset(filePath)
        sound.Volume = 2
        sound.Looped = IsLooping
        sound.Parent = workspace
        sound:Play()
        CurrentSound = sound
    else
    end
end

local ControlSection = MusicTab:Section({ Title = "播放控制", }) 

ControlSection:Button({
    Title = "停止播放",
    Color = Color3.fromHex("#a2ff30"),
    Justify = "Center", 
    IconAlign = "Left", 
    Icon = "stop-circle", 
    Callback = function()
        if CurrentSound then
            CurrentSound:Destroy()
            CurrentSound = nil
        end
    end
})

ControlSection:Button({
    Title = "继续 / 暂停播放",
    Color = Color3.fromHex("#a2ff30"),
    Justify = "Center", 
    IconAlign = "Left", 
    Icon = "pause", 
    Callback = function()
        if CurrentSound then
            if CurrentSound.IsPlaying then
                CurrentSound:Pause()
            else
                CurrentSound:Resume()
            end
        end
    end
})

ControlSection:Toggle({
    Title = "单曲循环",
    Desc = "开启后歌曲将无限循环",
    Icon = "repeat", 
    Type = "Checkbox", 
    Value = IsLooping, 
    Callback = function(state)  
        IsLooping = state
        if CurrentSound then
            CurrentSound.Looped = state
        end
    end
})

ControlSection:Button({
    Title = "清空搜索列表",
    Color = Color3.fromHex("#a2ff30"), 
    Justify = "Center", 
    IconAlign = "Left", 
    Icon = "trash-2", 
    Callback = function()
        local count = 0
        for _, btn in pairs(SearchButtons) do 
            pcall(function() btn:Destroy() end)
            count = count + 1
        end
        SearchButtons = {}
    end
})

ControlSection:Button({
    Title = "清除音乐缓存",
    Color = Color3.fromHex("#a2ff30"), 
    Justify = "Center", 
    IconAlign = "Left", 
    Icon = "hard-drive", 
    Callback = function()
        local count = 0
        if listfiles then
            for _, file in pairs(listfiles(CacheFolder)) do
                delfile(file)
                count = count + 1
            end
        end
        DownloadedFiles = {}
    end
})

local SearchSection = MusicTab:Section({ Title = "搜索与结果", }) 

SearchSection:Input({
    Title = "搜索音乐",
    Desc = "输入歌名，按回车开始搜索",
    Value = "",
    InputIcon = "search",
    Type = "Input",
    Placeholder = "Enter Song Name...",
    Callback = function(text) 
        if text == "" then return end
        
        for _, btn in pairs(SearchButtons) do pcall(function() btn:Destroy() end) end
        SearchButtons = {}

        spawn(function()
            local searchUrl = "http://music.163.com/api/search/get/web?s=" .. HttpService:UrlEncode(text) .. "&type=1&offset=0&total=true&limit=8"
            local success, result = pcall(function() return game:HttpGet(searchUrl) end)

            if success then
                local data = HttpService:JSONDecode(result)
                if data and data.result and data.result.songs then
                    
                    for _, song in pairs(data.result.songs) do
                        local artist = song.artists[1].name or "未知歌手"
                        local songName = song.name
                        local songId = tostring(song.id)

                        local ButtonInstance = SearchSection:Button({ 
                            Title = songName, 
                            Desc = "歌手: " .. artist, 
                            Color = Color3.fromHex("#ffffff"),
                            Justify = "Left",
                            IconAlign = "Right", 
                            Icon = "play",
                            Callback = function()
                                PlayMusic(songId, songName, artist)
                            end
                        })
                        table.insert(SearchButtons, ButtonInstance)
                    end
                else
                end
            else
            end
        end)
    end
})
