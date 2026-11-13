local BootStart = os.clock()
getgenv()._TapologyBootStart = BootStart
print("[Tapology] Loading...")

local ModuleUrls = {
    library = "https://raw.githubusercontent.com/krispykills1914-sketch/probablyhereorsomethinghahahhaa/main/library.lua",
    weather = "https://raw.githubusercontent.com/krispykills1914-sketch/probablyhereorsomethinghahahhaa/main/weather.lua",
    hiteffect = "https://raw.githubusercontent.com/krispykills1914-sketch/probablyhereorsomethinghahahhaa/main/hiteffect.lua",
    killeffect = "https://raw.githubusercontent.com/krispykills1914-sketch/probablyhereorsomethinghahahhaa/main/killeffect.lua",
    tracer = "https://raw.githubusercontent.com/krispykills1914-sketch/probablyhereorsomethinghahahhaa/main/tracer.lua",
}

local OOVArrowAsset = "rbxassetid://132789080271579"

local function patchLibrary(src)
    src = src:gsub("\r\n", "\n")
    local function swap(old, new)
        old = old:gsub("\r\n", "\n")
        new = new:gsub("\r\n", "\n")
        local i, j = string.find(src, old, 1, true)
        if not i then
            return false
        end
        src = string.sub(src, 1, i - 1) .. new .. string.sub(src, j + 1)
        return true
    end
    local hits = {}
    if swap([=[function UI.Draggable(frame, handle)
    handle = handle or frame
    local dragging, startMouse, startPosition
    connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, startMouse, startPosition = true, input.Position, frame.Position
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startMouse
            frame.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
end]=], [=[local dragJobs = {}
local dragBound = false
local function bindDrag()
    if dragBound then
        return
    end
    dragBound = true
    connect(RunService.RenderStepped, function()
        for frame, job in dragJobs do
            local pending = job.pending
            if job.dragging and pending and job.startMouse and job.startPosition then
                job.pending = nil
                local delta = pending - job.startMouse
                if delta.X ~= 0 or delta.Y ~= 0 then
                    local pos = job.startPosition
                    frame.Position = UDim2.new(pos.X.Scale, pos.X.Offset + delta.X, pos.Y.Scale, pos.Y.Offset + delta.Y)
                end
            end
        end
    end)
end
function UI.Draggable(frame, handle)
    handle = handle or frame
    local job = dragJobs[frame]
    if not job then
        job = { dragging = false }
        dragJobs[frame] = job
        bindDrag()
    end
    local function apply()
        local pending = job.pending
        if job.dragging and pending and job.startMouse and job.startPosition then
            job.pending = nil
            local delta = pending - job.startMouse
            local pos = job.startPosition
            frame.Position = UDim2.new(pos.X.Scale, pos.X.Offset + delta.X, pos.Y.Scale, pos.Y.Offset + delta.Y)
        end
    end
    connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not job.dragging then
                job.dragging = true
                job.startMouse = input.Position
                job.startPosition = frame.Position
                job.pending = nil
            end
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            apply()
            job.dragging = false
            job.pending = nil
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if job.dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            job.pending = input.Position
        end
    end)
end]=]) then
        hits[#hits + 1] = "drag"
    end
    if swap('    connect(frame:GetPropertyChangedSignal("AbsolutePosition"), fit)\n', "") then
        hits[#hits + 1] = "guides"
    end
    if swap('        connect(box:GetPropertyChangedSignal("AbsolutePosition"), refit)\n', "") then
        hits[#hits + 1] = "list"
    end
    if swap('                connect(page:GetPropertyChangedSignal("AbsoluteSize"), refit)\n', '                connect(page:GetPropertyChangedSignal("AbsoluteSize"), refit)\n                connect(page:GetPropertyChangedSignal("CanvasPosition"), refit)\n') then
        hits[#hits + 1] = "scroll"
    end
    if not string.find(src, 'local hasLabel = type(text) == "string"', 1, true) then
        if swap(
            "function UI.Dropdown(parent, text, options, callback)\n    options = options or {}\n    local values, multi = options.Values or {}, options.Multi\n",
            "function UI.Dropdown(parent, text, options, callback)\n    options = options or {}\n    local values, multi = options.Values or {}, options.Multi\n    local hasLabel = type(text) == \"string\" and text ~= \"\"\n    if not hasLabel then\n        text = \"Dropdown\"\n    end\n"
        ) then
            hits[#hits + 1] = "droplabel"
        end
    end
    getgenv()._TapologyLibraryPatch = table.concat(hits, ",")
    return src
end

local ModuleRoots = {
    "tapology/modules",
    "tapology\\modules",
    "modules",
    "c:/Users/1223/Downloads/roblox resources/Tapology Resources/Visuals/modules",
    "C:/Users/1223/Downloads/roblox resources/Tapology Resources/Visuals/modules",
    [[C:\Users\1223\Downloads\roblox resources\Tapology Resources\Visuals\modules]],
}

local function moduleAlreadyLoaded(name)
    if name == "library" then
        local ui = getgenv().Tapology or getgenv().Library
        return type(ui) == "table" and type(ui.Unload) == "function" and ui.Gui ~= nil and type(ui.WindowDraggable) == "function"
    elseif name == "weather" then
        return type(getgenv().Weather) == "table" and type(getgenv().Weather.SetMode) == "function"
    elseif name == "hiteffect" then
        return type(getgenv().HitEffects) == "table"
    elseif name == "killeffect" then
        return type(getgenv().KillEffects) == "table"
    elseif name == "tracer" then
        return type(getgenv().Tracers) == "table"
    elseif name == "rage" then
        local rage = getgenv().Rage
        return type(rage) == "table"
            and type(rage.SetEnabled) == "function"
            and type(rage.Config) == "table"
            and rage.Config.FirePositionScanning ~= nil
            and type(rage.Runtime) == "table"
    end
    return false
end

local function readLocalModule(name)
    if type(readfile) ~= "function" then
        return nil
    end
    local names = { name }
    if name == "rage" then
        table.insert(names, "ragebot")
    end
    local paths = {}
    for _, root in ModuleRoots do
        for _, fileName in names do
            table.insert(paths, `{root}/{fileName}.lua`)
            table.insert(paths, `{root}\\{fileName}.lua`)
        end
    end
    -- Also allow ragebot.lua beside modules/.
    if name == "rage" then
        table.insert(paths, "c:/Users/1223/Downloads/roblox resources/Tapology Resources/Visuals/ragebot.lua")
        table.insert(paths, [[C:\Users\1223\Downloads\roblox resources\Tapology Resources\Visuals\ragebot.lua]])
    end
    for _, path in paths do
        local okLocal, data = pcall(readfile, path)
        if okLocal and type(data) == "string" and #data > 200 then
            return data, path
        end
    end
    return nil
end

getgenv()._TapologyForceLocalModules = true
getgenv()._TapologyUseLocalModules = true

local function ensureExecutorWorkspace()
    if type(makefolder) == "function" then
        pcall(makefolder, "tapology")
        pcall(makefolder, "tapology/modules")
    end
    local pre = getgenv()._TapologyPreloadModules
    if type(pre) ~= "table" or type(writefile) ~= "function" then
        return
    end
    for name, src in pre do
        if type(name) == "string" and type(src) == "string" and #src > 200 then
            local path = "tapology/modules/" .. name .. ".lua"
            local needWrite = true
            if type(isfile) == "function" then
                local okFile, exists = pcall(isfile, path)
                if okFile and exists and type(readfile) == "function" then
                    local okRead, current = pcall(readfile, path)
                    if okRead and type(current) == "string" and #current == #src then
                        needWrite = false
                    end
                end
            end
            if needWrite then
                pcall(writefile, path, src)
            end
        end
    end
end

local function loadRemote(name)
    local forceLocal = getgenv()._TapologyForceLocalModules ~= false
    if forceLocal and moduleAlreadyLoaded(name) then
        getgenv()._TapologyModuleSource = getgenv()._TapologyModuleSource or {}
        getgenv()._TapologyModuleSource[name] = "local"
        print("[Tapology] Loaded module:", name)
        return
    end
    ensureExecutorWorkspace()
    local src
    local data, localPath = readLocalModule(name)
    if (not data or #data < 200) and type(getgenv()._TapologyPreloadModules) == "table" then
        local pre = getgenv()._TapologyPreloadModules[name]
        if type(pre) == "string" and #pre > 200 then
            data, localPath = pre, "preload:" .. name
            if type(writefile) == "function" then
                pcall(writefile, "tapology/modules/" .. name .. ".lua", pre)
            end
        end
    end
    if data and #data > 200 then
        src = data
        getgenv()._TapologyModuleSource = getgenv()._TapologyModuleSource or {}
        getgenv()._TapologyModuleSource[name] = "local"
        getgenv()._TapologyModulePath = getgenv()._TapologyModulePath or {}
        getgenv()._TapologyModulePath[name] = localPath
    end
    if not src and not forceLocal then
        local url = ModuleUrls[name]
        if type(url) ~= "string" or url:find("YOUR_HOST", 1, true) then
            warn("[Tapology]", name, "url is not set")
            return
        end
        local bust = tostring(math.floor(os.clock() * 1000))
        local fetchUrl = url .. (string.find(url, "?", 1, true) and "&" or "?") .. "t=" .. bust
        local ok, remote = pcall(function()
            return game:HttpGet(fetchUrl)
        end)
        if (not ok or type(remote) ~= "string" or #remote < 20) and fetchUrl ~= url then
            ok, remote = pcall(function()
                return game:HttpGet(url)
            end)
        end
        if not ok or type(remote) ~= "string" or #remote < 20 then
            warn("[Tapology]", name, "download failed:", remote)
            return
        end
        src = remote
        getgenv()._TapologyModuleSource = getgenv()._TapologyModuleSource or {}
        getgenv()._TapologyModuleSource[name] = "remote"
        if name == "library" then
            src = patchLibrary(src)
        end
    end
    if not src then
        warn("[Tapology]", name, "local module missing")
        return
    end
    local fn, err = loadstring(src, "@" .. name)
    if not fn then
        warn("[Tapology]", name, "did not compile:", err)
        return
    end
    local ran, result = pcall(fn)
    if not ran then
        warn("[Tapology]", name, "failed:", result)
    else
        print("[Tapology] Loaded module:", name)
    end
end

do
    local prevServer = getgenv()._TapologyServer
    if type(prevServer) == "table" and type(prevServer.Stop) == "function" then
        pcall(prevServer.Stop)
    end
    local function purgeTapologyGuis(keep)
        local players = game:GetService("Players")
        local localPlayer = players.LocalPlayer
        local parents = {
            game:GetService("CoreGui"),
            localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui"),
        }
        if typeof(gethui) == "function" then
            local okHui, host = pcall(gethui)
            if okHui and typeof(host) == "Instance" then
                parents[#parents + 1] = host
            end
        end
        for _, parent in parents do
            if typeof(parent) == "Instance" then
                for _, child in parent:GetChildren() do
                    if child.Name == "Tapology" and child:IsA("ScreenGui") and child ~= keep then
                        pcall(child.Destroy, child)
                    end
                end
            end
        end
    end
    getgenv()._TapologyPurgeGuis = purgeTapologyGuis
    local ui = getgenv().Tapology or getgenv().Library
    local keepLibrary = type(ui) == "table"
        and type(ui.Unload) == "function"
        and ui.Gui ~= nil
        and type(ui.PolishOverlay) == "function"
    if keepLibrary then
        purgeTapologyGuis(ui.Gui)
    else
        for _, key in { "Tapology", "Library" } do
            local stub = getgenv()[key]
            if type(stub) == "table" and type(stub.Unload) == "function" then
                pcall(stub.Unload)
            end
            getgenv()[key] = nil
        end
        purgeTapologyGuis(nil)
    end
end
loadRemote("library")
do
    local ui = getgenv().Tapology or getgenv().Library
    local purge = getgenv()._TapologyPurgeGuis
    if type(purge) == "function" then
        purge(ui and ui.Gui)
    end
end
local Library = getgenv().Library or getgenv().Tapology
do

local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local HttpService = cloneref(game:GetService("HttpService"))

local Config = {
    ShowBoxes = false,
    ShowNames = false,
    ShowWeapon = false,
    ShowDistance = false,
    ShowHealth = false,
    BoxColor = Color3.fromRGB(255, 255, 255),
    BoxTransparency = 0,
    OutlineColor = Color3.fromRGB(0, 0, 0),
    OutlineTransparency = 0,
    InlineColor = Color3.fromRGB(0, 0, 0),
    InlineTransparency = 0,
    NameColor = Color3.fromRGB(255, 255, 255),
    NameTransparency = 0,
    WeaponColor = Color3.fromRGB(255, 255, 255),
    WeaponTransparency = 0,
    DistanceColor = Color3.fromRGB(255, 255, 255),
    DistanceTransparency = 0,
    HealthColor = Color3.fromRGB(120, 255, 120),
    HealthTransparency = 0,
    HealthLowColor = Color3.fromRGB(255, 70, 70),
    TextOutlineColor = Color3.fromRGB(0, 0, 0),
    TextOutline = true,
    TextSize = 12,
    BoxOutline = true,
    HealthOutline = true,
    Snaplines = false,
    SnaplineColor = Color3.fromRGB(255, 255, 255),
    SnaplineTransparency = 0,
    SnaplineOutline = true,
    OOV = false,
    OOVRadius = 180,
    OOVSize = 16,
    OOVColor = Color3.fromRGB(255, 255, 255),
    OOVTransparency = 0,
    OOVImage = OOVArrowAsset,
    ChamsMode = "highlight",
    AdornmentType = "solid",
    AdornmentGlow = 1,
    HighlightPerPart = false,
    Highlight = false,
    HighlightVisible = true,
    HighlightOccluded = true,
    HighlightVisibleFillColor = Color3.fromRGB(108, 147, 255),
    HighlightVisibleFillTransparency = 0.5,
    HighlightVisibleOutlineColor = Color3.fromRGB(255, 255, 255),
    HighlightVisibleOutlineTransparency = 0,
    HighlightOccludedFillColor = Color3.fromRGB(255, 105, 180),
    HighlightOccludedFillTransparency = 0.5,
    HighlightOccludedOutlineColor = Color3.fromRGB(255, 255, 255),
    HighlightOccludedOutlineTransparency = 0,
    UseDisplayName = false,
    MaxDistance = math.huge,
    TeamCheck = true,
}

local env = getgenv and getgenv() or _G
if env.ESP then
    env.ESP.Unload()
end

local LocalPlayer = Players.LocalPlayer
local hui = gethui and gethui()

local FontFolder = "tapology/fonts"
local FontName = "ProggyClean"
local FontUrl = "https://raw.githubusercontent.com/bluescan/proggyfonts/master/ProggyOriginal/ProggyClean.ttf"

local function loadFont()
    for _, folder in { "tapology", FontFolder } do
        if not isfolder(folder) then
            makefolder(folder)
        end
    end
    local fontPath = `{FontFolder}/{FontName}.ttf`
    local familyPath = `{FontFolder}/{FontName}.json`
    if not isfile(fontPath) then
        writefile(fontPath, game:HttpGet(FontUrl))
    end
    writefile(familyPath, HttpService:JSONEncode({
        name = FontName,
        faces = {
            { name = "Regular", weight = 400, style = "normal", assetId = getcustomasset(fontPath) },
        },
    }))
    return Font.new(getcustomasset(familyPath), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end

local fontLoaded, TextFont = pcall(loadFont)
if not fontLoaded then
    warn("[ESP] couldn't load ProggyClean, using the built-in font:", TextFont)
    TextFont = Font.fromEnum(Enum.Font.SourceSans)
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "ESP"
Gui.IgnoreGuiInset = true
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = (hui and not hui:IsA("LayerCollector")) and hui or CoreGui

local Boxes = {}
local Connections = {}

local function ring(parent, inset, zindex)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Position = UDim2.fromOffset(inset, inset)
    frame.Size = UDim2.new(1, -inset * 2, 1, -inset * 2)
    frame.ZIndex = zindex
    frame.Parent = parent

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode = Enum.LineJoinMode.Miter
    stroke.Parent = frame
    return stroke
end

local function outlinedText(parent, name)
    local text = Instance.new("TextLabel")
    text.Name = name
    text.BackgroundTransparency = 1
    text.Size = UDim2.fromOffset(0, Config.TextSize)
    text.AutomaticSize = Enum.AutomaticSize.X
    text.FontFace = TextFont
    text.TextSize = Config.TextSize
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.ZIndex = 5
    text.Parent = parent
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.LineJoinMode = Enum.LineJoinMode.Miter
    stroke.Parent = text
    return { Label = text, Stroke = stroke }
end

local function newBox(key)
    local holder = Instance.new("Frame")
    holder.Name = key
    holder.BackgroundTransparency = 1
    holder.Visible = false
    holder.Parent = Gui

    local healthBack = Instance.new("Frame")
    healthBack.Name = "Health"
    healthBack.BorderSizePixel = 0
    healthBack.ZIndex = 1
    healthBack.Parent = holder
    local healthFill = Instance.new("Frame")
    healthFill.Name = "Fill"
    healthFill.BorderSizePixel = 0
    healthFill.ZIndex = 2
    healthFill.Parent = healthBack

    return {
        Holder = holder,
        Outline = ring(holder, -1, 1),
        Box = ring(holder, 0, 2),
        Inline = ring(holder, 1, 3),
        Name = outlinedText(holder, "NameLabel"),
        Weapon = outlinedText(holder, "WeaponLabel"),
        Distance = outlinedText(holder, "DistanceLabel"),
        HealthBack = healthBack,
        HealthFill = healthFill,
    }
end

local function removeBox(key)
    local box = Boxes[key]
    if not box then return end
    Boxes[key] = nil
    box.Holder:Destroy()
end

local PhantomForces = game.PlaceId == 292439477 or game.PlaceId == 299659045

local function isEnemy(player)
    if not Config.TeamCheck or not player then return true end
    if player.Team and LocalPlayer.Team then
        return player.Team ~= LocalPlayer.Team
    end

    if PhantomForces then
        return player.TeamColor ~= LocalPlayer.TeamColor
    end
    if player.Neutral or LocalPlayer.Neutral then
        return true
    end
    return player.TeamColor ~= LocalPlayer.TeamColor
end

local function displayName(player, fallback)
    if not player then return fallback end
    return Config.UseDisplayName and player.DisplayName or player.Name
end

local function robloxTargets(list)
    for _, player in Players:GetPlayers() do
        if player ~= LocalPlayer and isEnemy(player) then
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if root and humanoid and humanoid.Health > 0 then
                local parts = {}
                for _, part in character:GetChildren() do
                    if part:IsA("BasePart") and part.Transparency < 1 then
                        table.insert(parts, part)
                    end
                end
                local tool = character:FindFirstChildOfClass("Tool")
                table.insert(list, {
                    Key = player.Name,
                    Player = player,
                    Name = displayName(player, player.Name),
                    Root = root,
                    Head = character:FindFirstChild("Head"),
                    Model = character,
                    Parts = parts,
                    Health = humanoid.MaxHealth > 0 and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) or nil,
                    Weapon = tool and tool.Name,
                })
            end
        end
    end
end

local modelCache = setmetatable({}, { __mode = "k" })

local function phantomModel(model)
    local info = modelCache[model]
    if info and info.Tag.Parent and info.Root.Parent then
        return info
    end
    local tag = model:FindFirstChild("NameTagGui", true)
    local label = tag and tag:FindFirstChild("PlayerTag")
    if not label then return end
    local body = model:FindFirstChildOfClass("Folder")
    if not body then return end
    local parts, root, rootVolume = {}, nil, 0
    for _, part in body:GetChildren() do
        if part:IsA("BasePart") then
            table.insert(parts, part)
            local volume = part.Size.X * part.Size.Y * part.Size.Z
            if volume > rootVolume then
                root, rootVolume = part, volume
            end
        end
    end
    if not root then return end
    info = { Tag = tag, Label = label, Parts = parts, Root = root }
    modelCache[model] = info
    return info
end

local Replication = { Class = nil, Entries = nil, NextSearch = 0 }

local function findReplication()

    if not getgc or (getactors and #getactors() > 0) then return end
    local class = Replication.Class
    if not class then
        for _, value in getgc(true) do
            if type(value) == "table" and type(rawget(value, "getHealth")) == "function"
                and type(rawget(value, "getWeaponObject")) == "function" and type(rawget(value, "isAlive")) == "function" then
                class = value
                break
            end
        end
        if not class then return end
        Replication.Class = class
    end
    for _, value in getgc(true) do
        if type(value) == "table" then
            local key, entry = next(value)
            if typeof(key) == "Instance" and key:IsA("Player") and type(entry) == "table" and getmetatable(entry) == class then
                Replication.Entries = value
                return
            end
        end
    end
end

local function replicationOf(player)
    local entries = Replication.Entries
    if not entries then
        local now = os.clock()
        if PhantomForces and now >= Replication.NextSearch then
            Replication.NextSearch = now + 3
            pcall(findReplication)
        end
        return
    end
    local entry = player and entries[player]
    if not entry then return end
    local class = Replication.Class
    local info = { Enemy = rawget(entry, "_isEnemy"), Alive = rawget(entry, "_alive") }
    local okHealth, health, maxHealth = pcall(class.getHealth, entry)
    if okHealth and type(health) == "number" then
        info.Health = math.clamp(health / (type(maxHealth) == "number" and maxHealth > 0 and maxHealth or 100), 0, 1)
    end
    local okWeapon, weapon = pcall(class.getWeaponObject, entry)
    if okWeapon and type(weapon) == "table" and type(rawget(weapon, "weaponName")) == "string" then
        info.Weapon = weapon.weaponName
    end
    return info
end

if PhantomForces and getfflag and setfflag then
    pcall(function()
        if tostring(getfflag("DebugRunParallelLuaOnMainThread")):lower() ~= "true" then
            setfflag("DebugRunParallelLuaOnMainThread", "True")
        end
    end)
end

local function phantomHealth(tag)
    local frame = tag:FindFirstChild("Health", true)
    local percent = frame and frame:FindFirstChild("Percent")
    if not percent then return end
    local value = percent.Size.X.Scale
    return value == value and math.clamp(value, 0, 1) or nil
end

env.ESPLastWeapon = env.ESPLastWeapon or {}
local lastWeapon = env.ESPLastWeapon
local function phantomWeapon(name, model)
    for _, child in model:GetChildren() do
        if child:IsA("Model") then
            local gun = child.Name:match("^(.-)%s*Main$")
            if gun and gun ~= "" then
                lastWeapon[name] = gun
                return gun
            end
        end
    end
    return lastWeapon[name]
end

local function replicationPosition(entry)
    if type(entry) ~= "table" then
        return
    end
    local class = Replication.Class
    if class and type(class.getPosition) == "function" then
        local ok, pos = pcall(class.getPosition, entry)
        if ok and typeof(pos) == "Vector3" and pos.Magnitude > 1 then
            return pos
        end
    end
    local smooth = rawget(entry, "_smoothPosition")
    if type(smooth) == "table" then
        local v = rawget(smooth, "_value1") or rawget(smooth, "_value0")
        if typeof(v) == "Vector3" and v.Magnitude > 1 then
            return v
        end
    end
    local spring = rawget(entry, "_posspring")
    if type(spring) == "table" then
        local p = rawget(spring, "p") or rawget(spring, "_p0") or rawget(spring, "_p1")
        if typeof(p) == "Vector3" and p.Magnitude > 1 then
            return p
        end
    end
end

local function phantomTargets(list)
    local root = workspace:FindFirstChild("Players")
    if root then
        for _, folder in root:GetChildren() do
            for _, model in folder:GetChildren() do
                local info = phantomModel(model)
                local name = info and info.Label.Text
                if name and name ~= "" and name ~= LocalPlayer.Name and not list[name] then
                    local player = Players:FindFirstChild(name)
                    local live = replicationOf(player)
                    local enemy
                    if live and live.Enemy ~= nil then
                        enemy = live.Enemy or not Config.TeamCheck
                    else
                        enemy = isEnemy(player)
                    end
                    if enemy and not (live and live.Alive == false) then
                        list[name] = true
                        local weapon = live and live.Weapon
                        if weapon then
                            lastWeapon[name] = weapon
                        end
                        local entry = Replication.Entries and player and Replication.Entries[player]
                        table.insert(list, {
                            Key = name,
                            Player = player,
                            Name = displayName(player, name),
                            Root = info.Root,
                            World = info.Root and info.Root.Position or replicationPosition(entry),
                            Head = info.Tag.Parent,
                            Model = model,
                            Parts = info.Parts,
                            Health = live and live.Health or phantomHealth(info.Tag),
                            Weapon = weapon or phantomWeapon(name, model),
                        })
                    end
                end
            end
        end
    end
    local entries = Replication.Entries
    if not entries then
        pcall(findReplication)
        entries = Replication.Entries
    end
    if type(entries) ~= "table" then
        return
    end
    for player, entry in pairs(entries) do
        if typeof(player) == "Instance" and player:IsA("Player") and player ~= LocalPlayer and not list[player.Name] then
            local live = replicationOf(player)
            local enemy
            if live and live.Enemy ~= nil then
                enemy = live.Enemy or not Config.TeamCheck
            else
                enemy = isEnemy(player)
            end
            local world = replicationPosition(entry)
            if enemy and world and not (live and live.Alive == false) then
                list[player.Name] = true
                table.insert(list, {
                    Key = player.Name,
                    Player = player,
                    Name = displayName(player, player.Name),
                    Root = nil,
                    World = world,
                    Head = nil,
                    Model = nil,
                    Parts = {},
                    Health = live and live.Health,
                    Weapon = live and live.Weapon or lastWeapon[player.Name],
                })
            end
        end
    end
end

local function bodyBounds(root, parts)
    local rootCFrame = root.CFrame
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

    for _, part in parts do
        if part.Parent then
            local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = rootCFrame:ToObjectSpace(part.CFrame):GetComponents()
            local size = part.Size * 0.5
            local ex = math.abs(r00) * size.X + math.abs(r01) * size.Y + math.abs(r02) * size.Z
            local ey = math.abs(r10) * size.X + math.abs(r11) * size.Y + math.abs(r12) * size.Z
            local ez = math.abs(r20) * size.X + math.abs(r21) * size.Y + math.abs(r22) * size.Z
            minX, maxX = math.min(minX, x - ex), math.max(maxX, x + ex)
            minY, maxY = math.min(minY, y - ey), math.max(maxY, y + ey)
            minZ, maxZ = math.min(minZ, z - ez), math.max(maxZ, z + ez)
        end
    end

    if minX == math.huge then return end
    return rootCFrame, Vector3.new(minX, minY, minZ), Vector3.new(maxX, maxY, maxZ)
end

local corners = table.create(8)
local function screenRect(camera, rootCFrame, low, high)
    corners[1] = Vector3.new(low.X, low.Y, low.Z)
    corners[2] = Vector3.new(high.X, low.Y, low.Z)
    corners[3] = Vector3.new(low.X, high.Y, low.Z)
    corners[4] = Vector3.new(high.X, high.Y, low.Z)
    corners[5] = Vector3.new(low.X, low.Y, high.Z)
    corners[6] = Vector3.new(high.X, low.Y, high.Z)
    corners[7] = Vector3.new(low.X, high.Y, high.Z)
    corners[8] = Vector3.new(high.X, high.Y, high.Z)

    local left, top, right, bottom = math.huge, math.huge, -math.huge, -math.huge
    for _, corner in corners do
        local point = camera:WorldToViewportPoint(rootCFrame * corner)
        if point.Z <= 0 then return end
        left, right = math.min(left, point.X), math.max(right, point.X)
        top, bottom = math.min(top, point.Y), math.max(bottom, point.Y)
    end
    return math.floor(left + 0.5), math.floor(top + 0.5), math.floor(right + 0.5), math.floor(bottom + 0.5)
end

local function textOutlined(slot)
    local value = Config[slot .. "Outline"]
    if value == nil then
        return Config.TextOutline ~= false
    end
    return value and true or false
end

local function placeText(text, value, shown, width, y, color, transparency, slot)
    local label = text.Label
    shown = shown and value ~= nil
    label.Visible = shown
    if not shown then return 0 end
    label.Text = value
    label.TextSize = Config.TextSize
    label.Size = UDim2.fromOffset(0, Config.TextSize)
    label.Position = UDim2.fromOffset(math.floor((width - label.TextBounds.X) / 2 + 0.5), y)
    label.TextColor3, label.TextTransparency = color, transparency
    local outline = textOutlined(slot)
    text.Stroke.Enabled = outline
    text.Stroke.Color = Config.TextOutlineColor
    text.Stroke.Transparency = outline and transparency or 1
    return Config.TextSize
end

local MaxHighlights = 31
local Highlights = {}
local HighlightParent = hui or CoreGui
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local Adornments = {}
local PartHighlights = {}

local function removeHighlight(key)
    local highlight = Highlights[key]
    if highlight then
        Highlights[key] = nil
        highlight:Destroy()
    end
    local parts = PartHighlights[key]
    if parts then
        PartHighlights[key] = nil
        for _, inst in parts do
            inst:Destroy()
        end
    end
    local adorns = Adornments[key]
    if adorns then
        Adornments[key] = nil
        if adorns.Clones then
            for _, inst in adorns.Clones do
                inst:Destroy()
            end
            for _, inst in adorns.Glow or {} do
                inst:Destroy()
            end
        else
            for _, inst in adorns do
                if typeof(inst) == "Instance" then
                    inst:Destroy()
                end
            end
        end
    end
end

local function adornLook(kind, glow)
    local always = kind == "xray" or kind == "xray shaded" or kind == "plasma" or kind == "glow" or kind == "glow 2x"
    local transparency = 0.2
    if kind == "shaded" or kind == "xray shaded" then
        transparency = 0.62
    elseif kind == "glow" then
        transparency = 0.4
    elseif kind == "glow 2x" then
        transparency = 0.28
    elseif kind == "plasma" then
        transparency = 0.42 + math.sin(os.clock() * 6) * 0.18
    elseif kind == "solid" then
        transparency = 0.12
    end
    local factor = math.clamp(tonumber(glow) or 1, 0.25, 4)
    if kind == "glow" or kind == "glow 2x" or kind == "plasma" then
        transparency = math.clamp(transparency / factor, 0, 0.9)
    end
    return always, transparency
end

local AdornFolder = Instance.new("Folder")
AdornFolder.Name = "TapologyAdornments"
AdornFolder.Parent = workspace.CurrentCamera or workspace
table.insert(Connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera and AdornFolder.Parent ~= workspace.CurrentCamera then
        AdornFolder.Parent = workspace.CurrentCamera
    end
end))

local AdornMaxParts = 14
local AdornUpdateHz = 20
local function adornPartsFor(target)
    local parts = {}
    local seenPart = {}
    local function push(part)
        if part and part.Parent and part:IsA("BasePart") and not seenPart[part] and part.Transparency < 0.95 and part.Size.Magnitude > 0.05 then
            seenPart[part] = true
            parts[#parts + 1] = part
        end
    end
    for _, part in target.Parts or {} do
        push(part)
    end
    if target.Model and target.Model.Parent then
        for _, desc in target.Model:GetDescendants() do
            push(desc)
        end
    end
    if #parts > AdornMaxParts then
        table.sort(parts, function(a, b)
            return a.Size.Magnitude > b.Size.Magnitude
        end)
        while #parts > AdornMaxParts do
            parts[#parts] = nil
        end
    end
    return parts
end

local function makeAdornClone(part)
    local clone = Instance.new("Part")
    clone.Name = "Adorn"
    clone.Shape = part:IsA("Part") and part.Shape or Enum.PartType.Block
    clone.Anchored = true
    clone.CanCollide = false
    clone.CanQuery = false
    clone.CanTouch = false
    clone.CastShadow = false
    clone.Massless = true
    clone.Material = Enum.Material.ForceField
    if part:IsA("MeshPart") then
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        pcall(function()
            mesh.MeshId = part.MeshId
        end)
        mesh.TextureId = ""
        mesh.Scale = Vector3.new(1, 1, 1)
        mesh.Parent = clone
    else
        local mesh = part:FindFirstChildOfClass("SpecialMesh")
        if mesh then
            local copy = mesh:Clone()
            copy.TextureId = ""
            copy.Parent = clone
        end
    end
    clone.Parent = AdornFolder
    return clone
end

local function applyAdornments(target, visible)
    local key = target.Key
    local list = Adornments[key]
    if not list then
        list = { Clones = {}, Glow = {}, Last = 0 }
        Adornments[key] = list
    end
    local now = os.clock()
    local due = (now - (list.Last or 0)) >= (1 / AdornUpdateHz)
    if not due and next(list.Clones) then
        local kind = Config.AdornmentType
        local plasmaT
        if kind == "plasma" then
            plasmaT = math.clamp(0.42 + math.sin(now * 6) * 0.18, 0, 0.95)
        end
        for part, clone in list.Clones do
            if part.Parent and clone.Parent then
                clone.CFrame = part.CFrame
                if plasmaT then
                    clone.Transparency = plasmaT
                end
            end
        end
        for part, glow in list.Glow do
            if part.Parent and glow.Parent then
                glow.CFrame = part.CFrame
            end
        end
        return
    end
    list.Last = now
    local mode = visible and "HighlightVisible" or "HighlightOccluded"
    local color = Config[mode .. "FillColor"]
    local fillAlpha = Config[mode .. "FillTransparency"]
    local always, lookTransparency = adornLook(Config.AdornmentType, Config.AdornmentGlow)
    local transparency = math.clamp(math.max(tonumber(fillAlpha) or 0, lookTransparency), 0, 0.95)
    local kind = Config.AdornmentType
    local material = Enum.Material.ForceField
    if kind == "solid" then
        material = Enum.Material.SmoothPlastic
    elseif kind == "glow" or kind == "glow 2x" or kind == "plasma" then
        material = Enum.Material.Neon
    elseif kind == "shaded" or kind == "xray shaded" then
        material = Enum.Material.ForceField
    end
    local parts = adornPartsFor(target)
    local used = {}
    for _, part in parts do
        local clone = list.Clones[part]
        if not clone or not clone.Parent then
            clone = makeAdornClone(part)
            list.Clones[part] = clone
        end
        used[part] = true
        clone.CFrame = part.CFrame
        clone.Size = part.Size
        clone.Color = color
        clone.Transparency = transparency
        clone.Material = always and Enum.Material.ForceField or material
        clone.LocalTransparencyModifier = 0
        if kind == "glow 2x" then
            local glow = list.Glow[part]
            if not glow or not glow.Parent then
                glow = makeAdornClone(part)
                list.Glow[part] = glow
            end
            glow.CFrame = part.CFrame
            glow.Size = part.Size * 1.06
            glow.Color = color
            glow.Transparency = math.clamp(transparency + 0.22, 0, 0.95)
            glow.Material = Enum.Material.Neon
        elseif list.Glow[part] then
            list.Glow[part]:Destroy()
            list.Glow[part] = nil
        end
    end
    for part, clone in list.Clones do
        if not used[part] then
            clone:Destroy()
            list.Clones[part] = nil
            if list.Glow[part] then
                list.Glow[part]:Destroy()
                list.Glow[part] = nil
            end
        end
    end
end

local function inSight(cameraPosition, target)
    local ignore = { workspace.CurrentCamera, target.Model }
    if PhantomForces then
        table.insert(ignore, workspace:FindFirstChild("Players"))
        table.insert(ignore, workspace:FindFirstChild("Ignore"))
    elseif LocalPlayer.Character then
        table.insert(ignore, LocalPlayer.Character)
    end
    rayParams.FilterDescendantsInstances = ignore
    for _, part in { target.Head, target.Root } do
        if part and part.Parent then
            local hit = workspace:Raycast(cameraPosition, part.Position - cameraPosition, rayParams)
            if not hit or (hit.Instance.Transparency >= 0.9 and not hit.Instance.CanCollide) then
                return true
            end
        end
    end
    return false
end

local function updateHighlight(target, rank, cameraPosition)
    local key = target.Key
    local wanted = Config.Highlight and rank <= MaxHighlights and (Config.HighlightVisible or Config.HighlightOccluded)
        and target.Model and target.Model.Parent
    if wanted and Config.ChamsMode == "adornment" then
        local highlight = Highlights[key]
        if highlight then
            Highlights[key] = nil
            highlight:Destroy()
        end
        local visible = inSight(cameraPosition, target)
        local parts = PartHighlights[key]
        if parts then
            PartHighlights[key] = nil
            for _, inst in parts do
                inst:Destroy()
            end
        end
        if (visible and Config.HighlightVisible) or (not visible and Config.HighlightOccluded) then
            applyAdornments(target, visible)
        else
            local adorns = Adornments[key]
            if adorns and adorns.Clones then
                for _, inst in adorns.Clones do
                    inst.Transparency = 1
                end
                for _, inst in adorns.Glow or {} do
                    inst.Transparency = 1
                end
            end
        end
        return
    end
    local adorns = Adornments[key]
    if adorns then
        Adornments[key] = nil
        if adorns.Clones then
            for _, inst in adorns.Clones do
                inst:Destroy()
            end
            for _, inst in adorns.Glow or {} do
                inst:Destroy()
            end
        else
            for _, inst in adorns do
                if typeof(inst) == "Instance" then
                    inst:Destroy()
                end
            end
        end
    end
    local mode, depth
    if wanted then
        local visible = inSight(cameraPosition, target)
        if visible and Config.HighlightVisible then
            mode = "HighlightVisible"

            depth = Config.HighlightOccluded and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        elseif not visible and Config.HighlightOccluded then
            mode = "HighlightOccluded"
            depth = Enum.HighlightDepthMode.AlwaysOnTop
        else
            wanted = false
        end
    end
    if not wanted then
        removeHighlight(key)
        return
    end
    local highlight = Highlights[key]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = key
        highlight.Parent = HighlightParent
        Highlights[key] = highlight
    end
    if highlight.Adornee ~= target.Model then
        highlight.Adornee = target.Model
    end
    highlight.DepthMode = depth
    highlight.FillColor, highlight.FillTransparency = Config[mode .. "FillColor"], Config[mode .. "FillTransparency"]
    highlight.OutlineColor, highlight.OutlineTransparency = Config[mode .. "OutlineColor"], Config[mode .. "OutlineTransparency"]
    local oldParts = PartHighlights[key]
    if Config.HighlightPerPart then
        local made = oldParts or {}
        PartHighlights[key] = made
        local count = 0
        for _, part in target.Parts or {} do
            if part and part.Parent and part:IsA("BasePart") and count < 8 then
                count += 1
                local piece = made[count]
                if not piece then
                    piece = Instance.new("Highlight")
                    piece.Name = key
                    piece.Parent = HighlightParent
                    made[count] = piece
                end
                piece.Adornee = part
                piece.DepthMode = depth
                piece.FillColor, piece.FillTransparency = highlight.FillColor, highlight.FillTransparency
                piece.OutlineColor, piece.OutlineTransparency = highlight.OutlineColor, highlight.OutlineTransparency
            end
        end
        for index = count + 1, #made do
            made[index]:Destroy()
            made[index] = nil
        end
    elseif oldParts then
        PartHighlights[key] = nil
        for _, inst in oldParts do
            inst:Destroy()
        end
    end
end

local Snaplines = {}
local Arrows = {}

local function snapline(key)
    local line = Snaplines[key]
    if line then
        return line
    end
    local frame = Instance.new("Frame")
    frame.Name = "snap"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = 4
    frame.Parent = Gui
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame
    line = { Frame = frame, Stroke = stroke }
    Snaplines[key] = line
    return line
end

local function arrowFor(key)
    local arrow = Arrows[key]
    if arrow then
        return arrow
    end
    local holder = Instance.new("Frame")
    holder.Name = "oov"
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.fromOffset(18, 18)
    holder.Visible = false
    holder.ZIndex = 5
    holder.Parent = Gui
    local function bar(rot, x)
        local piece = Instance.new("Frame")
        piece.Name = "Arm"
        piece.AnchorPoint = Vector2.new(0.5, 0.5)
        piece.Position = UDim2.new(0.5, x, 0.5, 0)
        piece.Size = UDim2.fromOffset(3, 11)
        piece.Rotation = rot
        piece.BorderSizePixel = 0
        piece.ZIndex = 6
        piece.Parent = holder
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = piece
        return piece
    end
    local image = Instance.new("ImageLabel")
    image.Name = "Chevron"
    image.BackgroundTransparency = 1
    image.AnchorPoint = Vector2.new(0.5, 0.5)
    image.Position = UDim2.fromScale(0.5, 0.5)
    image.Size = UDim2.fromScale(1, 1)
    image.Image = tostring(Config.OOVImage or OOVArrowAsset)
    image.ScaleType = Enum.ScaleType.Fit
    image.ImageColor3 = Config.OOVColor
    image.ZIndex = 7
    image.Parent = holder
    arrow = { Holder = holder, Image = image, A = bar(36, -3), B = bar(-36, 3) }
    Arrows[key] = arrow
    return arrow
end

local function placeSnap(key, from, to)
    local line = snapline(key)
    if not Config.Snaplines then
        line.Frame.Visible = false
        return
    end
    local delta = to - from
    local length = delta.Magnitude
    if length < 2 then
        line.Frame.Visible = false
        return
    end
    local mid = (from + to) * 0.5
    line.Frame.Visible = true
    line.Frame.Position = UDim2.fromOffset(mid.X, mid.Y)
    line.Frame.Size = UDim2.fromOffset(length, 1)
    line.Frame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    line.Frame.BackgroundColor3 = Config.SnaplineColor
    line.Frame.BackgroundTransparency = Config.SnaplineTransparency
    line.Stroke.Enabled = Config.SnaplineOutline ~= false
    line.Stroke.Color = Color3.new(0, 0, 0)
    line.Stroke.Transparency = Config.SnaplineTransparency
end

local function placeArrow(key, camera, world)
    local arrow = arrowFor(key)
    if not Config.OOV or typeof(world) ~= "Vector3" then
        arrow.Holder.Visible = false
        return
    end
    local vs = camera.ViewportSize
    local center = Vector2.new(vs.X * 0.5, vs.Y * 0.5)
    local size = math.clamp(tonumber(Config.OOVSize) or 16, 8, 40)
    local pad = math.max(size * 0.5 + 4, 10)
    local screen = camera:WorldToViewportPoint(world)
    local sx, sy, sz = screen.X, screen.Y, screen.Z
    if sz <= 0 then
        sx = center.X * 2 - sx
        sy = center.Y * 2 - sy
    end
    local onScreen = sz > 0 and sx >= pad and sx <= vs.X - pad and sy >= pad and sy <= vs.Y - pad
    if onScreen then
        arrow.Holder.Visible = false
        return
    end
    local dx, dy = sx - center.X, sy - center.Y
    if math.abs(dx) < 0.001 and math.abs(dy) < 0.001 then
        dx, dy = 0, -1
    end
    local angle = math.atan2(dy, dx)
    local maxRadius = math.max(48, math.min(center.X, center.Y, vs.X - center.X, vs.Y - center.Y) - pad)
    local radius = math.clamp(tonumber(Config.OOVRadius) or 180, 40, maxRadius)
    local pos = Vector2.new(center.X + math.cos(angle) * radius, center.Y + math.sin(angle) * radius)
    pos = Vector2.new(math.clamp(pos.X, pad, vs.X - pad), math.clamp(pos.Y, pad, vs.Y - pad))
    local color = Config.OOVColor or Color3.new(1, 1, 1)
    local alpha = math.clamp(tonumber(Config.OOVTransparency) or 0, 0, 1)
    arrow.Holder.Visible = true
    arrow.Holder.Position = UDim2.fromOffset(pos.X, pos.Y)
    arrow.Holder.Size = UDim2.fromOffset(size, size)
    arrow.Holder.Rotation = math.deg(angle)
    if arrow.Image then
        local id = tostring(Config.OOVImage or OOVArrowAsset)
        if arrow.Image.Image ~= id then
            arrow.Image.Image = id
        end
        arrow.Image.ImageColor3 = color
        arrow.Image.ImageTransparency = alpha
        arrow.Image.Rotation = 0
        arrow.Image.Visible = true
        if arrow.A then
            arrow.A.Visible = arrow.Image.IsLoaded ~= true
            arrow.B.Visible = arrow.Image.IsLoaded ~= true
        end
    end
    if arrow.A then
        arrow.A.BackgroundColor3 = color
        arrow.B.BackgroundColor3 = color
        arrow.A.BackgroundTransparency = alpha
        arrow.B.BackgroundTransparency = alpha
        local armH = math.max(7, math.floor(size * 0.62 + 0.5))
        local armW = math.max(2, math.floor(size * 0.18 + 0.5))
        arrow.A.Size = UDim2.fromOffset(armW, armH)
        arrow.B.Size = UDim2.fromOffset(armW, armH)
        arrow.A.Position = UDim2.new(0.5, -math.floor(armW * 0.9), 0.5, 0)
        arrow.B.Position = UDim2.new(0.5, math.floor(armW * 0.9), 0.5, 0)
    end
end

local targets = {}
local seen = {}
local function update()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local cameraPosition = camera.CFrame.Position
    for _, line in Snaplines do
        line.Frame.Visible = false
    end
    for _, arrow in Arrows do
        arrow.Holder.Visible = false
    end

    table.clear(targets)
    if PhantomForces then
        phantomTargets(targets)
    else
        robloxTargets(targets)
    end

    for _, target in ipairs(targets) do
        local world = (target.Root and target.Root.Parent and target.Root.Position) or target.World
        target.World = world
        target.Distance = world and (world - cameraPosition).Magnitude or math.huge
    end
    table.sort(targets, function(a, b)
        return a.Distance < b.Distance
    end)

    table.clear(seen)
    for rank, target in ipairs(targets) do
        local distance = target.Distance
        local world = target.World
        if target.Root then
            updateHighlight(target, distance <= Config.MaxDistance and rank or math.huge, cameraPosition)
        end
        local rootCFrame, low, high
        if target.Root and distance <= Config.MaxDistance then
            rootCFrame, low, high = bodyBounds(target.Root, target.Parts)
        end
        local left, top, right, bottom
        if rootCFrame then
            left, top, right, bottom = screenRect(camera, rootCFrame, low, high)
        end

        if left then
            seen[target.Key] = true
            local box = Boxes[target.Key]
            if not box then
                box = newBox(target.Key)
                Boxes[target.Key] = box
            end
            local width, height = math.max(right - left, 3), math.max(bottom - top, 3)
            box.Holder.Position = UDim2.fromOffset(left, top)
            box.Holder.Size = UDim2.fromOffset(width, height)
            box.Holder.Visible = true

            local boxes = Config.ShowBoxes
            local outline = boxes and Config.BoxOutline ~= false
            box.Outline.Parent.Visible = outline
            box.Inline.Parent.Visible = outline
            box.Box.Parent.Visible = boxes
            box.Box.Color, box.Box.Transparency = Config.BoxColor, Config.BoxTransparency
            box.Outline.Color, box.Outline.Transparency = Config.OutlineColor, Config.OutlineTransparency
            box.Inline.Color, box.Inline.Transparency = Config.InlineColor, Config.InlineTransparency

            local nameY = -4 - Config.TextSize
            placeText(box.Name, target.Name, Config.ShowNames, width, nameY, Config.NameColor, Config.NameTransparency, "Name")
            local belowY = height + 4
            belowY += placeText(box.Weapon, target.Weapon and target.Weapon:lower(), Config.ShowWeapon, width, belowY, Config.WeaponColor, Config.WeaponTransparency, "Weapon")
            placeText(box.Distance, `{math.floor(distance + 0.5)}st`, Config.ShowDistance, width, belowY, Config.DistanceColor, Config.DistanceTransparency, "Distance")

            local health = target.Health
            local showHealth = Config.ShowHealth and health ~= nil
            box.HealthBack.Visible = showHealth
            if showHealth then
                local fillSpan = height + 2
                local fill = math.floor(fillSpan * health + 0.5)
                box.HealthBack.Position = UDim2.fromOffset(-6, -2)
                box.HealthBack.Size = UDim2.fromOffset(3, height + 4)
                box.HealthBack.BackgroundColor3 = Config.OutlineColor
                box.HealthBack.BackgroundTransparency = Config.HealthOutline == false and 1 or Config.HealthTransparency
                box.HealthFill.Position = UDim2.fromOffset(1, 1 + fillSpan - fill)
                box.HealthFill.Size = UDim2.fromOffset(1, fill)
                box.HealthFill.BackgroundColor3 = Config.HealthLowColor:Lerp(Config.HealthColor, health)
                box.HealthFill.BackgroundTransparency = Config.HealthTransparency
            end
            local viewport = camera.ViewportSize
            placeSnap(target.Key, Vector2.new(viewport.X * 0.5, viewport.Y), Vector2.new((left + right) * 0.5, bottom))
            placeArrow(target.Key, camera, world)
        else
            local line = Snaplines[target.Key]
            if line then
                line.Frame.Visible = false
            end
            if world then
                seen[target.Key] = true
                placeArrow(target.Key, camera, world)
            end
        end
    end

    for key, box in Boxes do
        if not seen[key] then
            box.Holder.Visible = false
            if not Players:FindFirstChild(key) then
                removeBox(key)
                lastWeapon[key] = nil
                local line = Snaplines[key]
                if line then
                    Snaplines[key] = nil
                    line.Frame:Destroy()
                end
                local arrow = Arrows[key]
                if arrow then
                    Arrows[key] = nil
                    arrow.Holder:Destroy()
                end
            end
        end
    end
    for key, arrow in Arrows do
        if not seen[key] then
            arrow.Holder.Visible = false
            if not Players:FindFirstChild(key) then
                Arrows[key] = nil
                arrow.Holder:Destroy()
            end
        end
    end
    for key in Highlights do
        local listed = false
        for _, target in ipairs(targets) do
            if target.Key == key then
                listed = true
                break
            end
        end
        if not listed then
            removeHighlight(key)
        end
    end
end

local ESP_STEP = "TapologyESP"
pcall(RunService.UnbindFromRenderStep, RunService, ESP_STEP)
RunService:BindToRenderStep(ESP_STEP, Enum.RenderPriority.Camera.Value + 3, update)

env.ESP = {
    Config = Config,
    Font = TextFont,
    PhantomForces = PhantomForces,

    SetColor = function(slot, color, transparency)
        Config[slot .. "Color"] = color
        if transparency then
            Config[slot .. "Transparency"] = transparency
        end
    end,
    Unload = function()
        pcall(RunService.UnbindFromRenderStep, RunService, ESP_STEP)
        for _, connection in Connections do
            connection:Disconnect()
        end
        table.clear(Connections)

        for key in Boxes do
            removeBox(key)
        end
        for key in Highlights do
            removeHighlight(key)
        end
        for key in Adornments do
            removeHighlight(key)
        end
        if AdornFolder then
            AdornFolder:Destroy()
        end
        Gui:Destroy()
        env.ESP = nil
    end,
}

end
loadRemote("weather")
do

local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local Config = {
    Enabled = false,
    Mode = "mouse",
    Mouse = false,
    MouseFOV = 120,
    MouseShowFOV = false,
    MouseFOVOrigin = "crosshair",
    MouseFOVColor = Color3.fromRGB(255, 255, 255),
    MouseFOVTransparency = 0,
    Smoothness = 0.6,
    MouseKey = "right mouse",

    Silent = false,
    SilentFOV = 160,
    SilentShowFOV = false,
    SilentFOVOrigin = "screen",
    SilentFOVColor = Color3.fromRGB(108, 147, 255),
    SilentFOVTransparency = 0,
    HitChance = 100,

    TargetPart = "head",
    VisibleCheck = false,
    MaxDistance = 1000,
    MouseEnabled = false,
    SilentEnabled = false,
    Class = "assault rifle",
}

local function syncMode()
    Config.Mouse = Config.MouseEnabled and true or false
    Config.Silent = Config.SilentEnabled and true or false
    Config.Enabled = Config.Mouse or Config.Silent
    if Config.Silent and not Config.Mouse then
        Config.Mode = "silent"
    elseif Config.Mouse then
        Config.Mode = "mouse"
    end
end
syncMode()

local WeaponClasses = {
    "global",
    "assault rifle",
    "battle rifle",
    "carbine",
    "pdw",
    "lmg",
    "dmr",
    "sniper rifle",
    "shotgun",
    "pistol",
    "machine pistol",
    "revolver",
    "other",
}

local ClassAliases = {
    assault = "assault rifle",
    ["assault rifles"] = "assault rifle",
    ["assault rifle"] = "assault rifle",
    ar = "assault rifle",
    battle = "battle rifle",
    ["battle rifles"] = "battle rifle",
    ["battle rifle"] = "battle rifle",
    br = "battle rifle",
    carbine = "carbine",
    carbines = "carbine",
    pdw = "pdw",
    pdws = "pdw",
    smg = "pdw",
    ["personal defense weapon"] = "pdw",
    ["personal defense weapons"] = "pdw",
    lmg = "lmg",
    lmgs = "lmg",
    ["light machine gun"] = "lmg",
    ["light machine guns"] = "lmg",
    dmr = "dmr",
    dmrs = "dmr",
    ["designated marksman rifle"] = "dmr",
    ["designated marksman rifles"] = "dmr",
    sniper = "sniper rifle",
    snipers = "sniper rifle",
    ["sniper rifle"] = "sniper rifle",
    ["sniper rifles"] = "sniper rifle",
    shotgun = "shotgun",
    shotguns = "shotgun",
    pistol = "pistol",
    pistols = "pistol",
    ["machine pistol"] = "machine pistol",
    ["machine pistols"] = "machine pistol",
    revolver = "revolver",
    revolvers = "revolver",
    other = "other",
}

local function normalizeWeaponClass(value)
    if type(value) ~= "string" or value == "" then
        return nil
    end
    local key = string.lower((value:gsub("[%s%-%_/]+", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")))
    return ClassAliases[key]
end

local function weaponNameKey(value)
    if type(value) ~= "string" then
        return ""
    end
    return string.upper((value:gsub("[^%w]+", "")))
end

local WeaponClassByName = {}
local function registerClassWeapons(className, names)
    for _, name in names do
        local key = weaponNameKey(name)
        if key ~= "" then
            WeaponClassByName[key] = className
        end
    end
end

registerClassWeapons("assault rifle", {
    "AK-12", "VZ.806", "VZ 806", "AN-94", "AS VAL", "MK16 SOCOM", "UAR A1", "M16A4", "AR36", "M16A1", "M16A3",
    "TYPE 20", "F90 MBR", "K2", "FAMAS G2", "AK-47", "AK47", "L85A2", "M416", "AK-74", "FAMAS F1", "QBZ-95",
    "AKM", "QBZ-97A", "AK-103", "TAR-21", "TYPE 88", "M231", "C7A2", "AK-12M", "MAC-15", "STG-44", "IA2 AR",
    "VZ.808", "VZ 808", "L85A3", "AK-15", "SPEAR LT", "VHS-D2", "AK-19", "M38A7", "AEK-971", "M16A2E2 ACR",
    "GERAT 90", "GOLDEN XM16E1", "XM16E1", "G36", "AUG A1", "AUG A2", "AUG A3", "SCAR-L", "FAMAS", "HK416",
})
registerClassWeapons("pdw", {
    "SMX-9K", "PDX-45", "AR36C", "X46A2", "MAC-10", "MAC10", "P90", "MP-9", "MP9", "MK16 SOCOM CQB", "MARS",
    "SMX-9", "XM633 DOE", "L2A3", "SMX-9SD", "HONEY BADGER", "SMX-10", "M3A1", "SMX-9/10", "UZI", "UAR A3 PARA",
    "K7", "AKS-74U", "PPSH-41", "PPSH", "FAL PARA SHORTY", "PP-19 BIZON", "PP19", "BIZON", "VECTOR 45", "VECTOR",
    "KRISS", "MP40", "X95 SMG", "TOMMY GUN", "TOMMY", "RAMA 1130", "MAC-31", "IA2 SMG", "BWC9 A", "FIVE-0",
    "LUTY", "M416C", "RATTLER", "FAMAS COMMANDO", "MP5", "MP5K", "MP7", "MP10", "UMP", "UMP45", "SR-3",
})
registerClassWeapons("lmg", {
    "LSV M/04", "M249 SAW", "M249", "M60E6", "M60", "UAR HBAR", "HBAR", "IAR36", "RPK-12", "L86A2 LSW", "L86",
    "AK-12BR", "RPK", "MG80", "HAMR IAR", "HAMR", "RPK-74", "QJB-95 LSW", "MG3KWS", "MG3", "FALO 50.41",
    "M1918A2", "M27 IAR", "RPK-16", "PKP PECHENEG", "PECHENEG", "MGV-176", "PKM", "STONER 96", "AEK-999",
    "ChainSAW", "MG42", "REAPR-338", "KORD-R", "COLT LMG", "HK21", "MG36",
})
registerClassWeapons("sniper rifle", {
    "INTERVENTION", "MODEL 700", "REMINGTON 700", "CS/LR-3", "AWS", "BFG 50", "BFG", "AWM", "TRG-42", "TRG",
    "MOSIN NAGANT", "MOSIN", "DRAGUNOV SVDS", "SVDS", "M110A1 CSASS", "CSASS", "CS/LR-4A", "THE FIX", "M1903",
    "K14", "RCS-10/22", "HECATE II", "HECATE", "FT300", "M82A1", "M82", "BALLISTA", "SCOUT RIFLE", "SCOUT",
    "WA2000", "TIMBERWOLF", "NTW-20", "DSR-50", "VKS", "OBREZ",
})
registerClassWeapons("carbine", {
    "M4A1", "C25", "AR36K", "M4", "L22A2", "AK-12U", "GROZA-1", "OTS-126", "AK-9", "UAR A3", "PDC-45", "K1A",
    "SR-3M", "MK16 SOCOM SC", "GROZA-4", "STG-89C", "1858 CARBINE", "SA58 OSW", "AK-105", "JURY", "R SQUARED",
    "GYROJET CARBINE", "C8A3", "X95R", "SALTY WEASEL", "M337", "MG89B", "VIRTUS", "MINI FIX", "EF88",
    "AEK-973S", "COLA CANNON", "PKP BYCHOK", "MTS-569", "G36C", "AK105",
})
registerClassWeapons("dmr", {
    "QBU-88", "MK11", "SKS", "PL8", "DRAGUNOV SVU", "SVU", "VSS VINTOREZ", "VSS", "JG-90", "M21", "NEOWULF TCR",
    "SA58 SPR", "MK20 SSR", "R-10/22", "SAIGA SAR", "SVK-12", "VZ.806 PPS", "UAR A3M2", "REGULATOR", "M28 GDMR",
    "MK12 SPR", "MSG90", "SR-25",
})
registerClassWeapons("battle rifle", {
    "M14", "NEOWULF ECR", "MK17 SOCOM", "STG-59H", "GUSTAV 66", "M417A2", "FAL 50.63 PARA", "HENRY 45-70",
    "FAL 50.00", "FAL", "VZ.806 BR", "AK-308", "IA2 BR", "M7 NGSW", "HCAR", "DOOMBOX", "SHAK-12",
    "MK17 ULTRALIGHT", "RM 277", "SCAR-H", "G3", "HK417", "BEOWULF",
})
registerClassWeapons("shotgun", {
    "KSG 12", "KSG", "MODEL 870", "REMINGTON 870", "AK-12/76", "M37 12G", "TERMINATOR 12G", "KS-23M", "KS-23",
    "KS23", "SAIGA-12", "SAIGA", "STEVENS DB", "STEVENS", "E-GUN", "SSG-410", "SCX-12", "AA-12", "SPAS-12",
    "SPAS", "DT11", "USAS-12", "USAS", "ORIGIN 12", "DBV",
})
registerClassWeapons("pistol", {
    "M9", "G17", "M1911A1", "M1911", "M17", "DEAGLE L5", "DEAGLE", "G21", "G23", "M45A1", "G40", "KG-99", "G50",
    "FIVE SEVEN", "FIVESEVEN", "ZIP 22", "GI M1", "HARDBALLER", "IZHEVSK PB", "MAKAROV PM", "MAKAROV", "GB-22",
    "DEAGLE XIX", "AUTOMAG III", "GSH-18", "GYROJET MARK I", "GSP GRIZZLY", "M2011", "U-416/22", "ALIEN",
    "AF2011-A1", "BOXY BUSTER", "MP412", "SERBU", "SFG",
})
registerClassWeapons("machine pistol", {
    "MAC-11", "G18C", "G18", "93R", "PP-2000", "TEC-9", "TEC9", "MICRO UZI", "SKORPION", "ŠKORPION", "VZ.61",
    "ASMI", "MP1911", "ARM PISTOL", "AEK-919K",
})
registerClassWeapons("revolver", {
    "MP412 REX", "REX", "MATEBA 6", "MATEBA", "1858 NEW ARMY", "RH-44", "JUDGE", "EXECUTIONER", "RSH-12",
})
registerClassWeapons("other", {
    "SUPER SHORTY", "STAKEOUT", "SFG 50", "M79 THUMPER", "SAWED OFF", "SAIGA-12U", "COILGUN", "SASS 308", "THUNDER",
})

local function profileFrom(source)
    return {
        MouseEnabled = source.MouseEnabled and true or false,
        SilentEnabled = source.SilentEnabled and true or false,
        MouseFOV = source.MouseFOV,
        MouseShowFOV = source.MouseShowFOV,
        MouseFOVOrigin = source.MouseFOVOrigin,
        SilentFOV = source.SilentFOV,
        SilentShowFOV = source.SilentShowFOV,
        SilentFOVOrigin = source.SilentFOVOrigin,
        Smoothness = source.Smoothness,
        MouseKey = source.MouseKey,
        HitChance = source.HitChance,
        TargetPart = source.TargetPart,
        VisibleCheck = source.VisibleCheck,
        MaxDistance = source.MaxDistance,
    }
end
Config.Profiles = {}
do
    local legacy = {
        assault = "assault rifle",
        sniper = "sniper rifle",
        pdw = "pdw",
        lmg = "lmg",
        shotgun = "shotgun",
        pistol = "pistol",
    }
    local existing = {}
    if type(Config.Profiles) == "table" then
        for name, profile in Config.Profiles do
            existing[name] = profile
        end
    end
    for _, name in WeaponClasses do
        local from = existing[name]
        if not from then
            for oldName, newName in legacy do
                if newName == name and existing[oldName] then
                    from = existing[oldName]
                    break
                end
            end
        end
        Config.Profiles[name] = from and profileFrom(from) or profileFrom(Config)
    end
end

local function resolveWeaponClass(weapon)
    if type(weapon) ~= "table" and typeof(weapon) ~= "Instance" then
        return nil
    end
    local data = weapon._weaponData or weapon.weaponData or weapon._data
    if type(data) == "table" then
        for _, key in {
            "type", "Type", "category", "Category", "weaponType", "WeaponType", "weapontype",
            "guntype", "GunType", "class", "Class", "slot", "Slot",
        } do
            local mapped = normalizeWeaponClass(data[key])
            if mapped then
                return mapped
            end
        end
        for _, key in { "displayname", "displayName", "name", "Name", "gunname", "GunName" } do
            local label = data[key]
            if type(label) == "string" then
                local exact = WeaponClassByName[weaponNameKey(label)]
                if exact then
                    return exact
                end
                local mapped = normalizeWeaponClass(label)
                if mapped then
                    return mapped
                end
            end
        end
    end
    for _, key in { "_name", "_weaponName", "Name", "name" } do
        local label = weapon[key]
        if type(label) == "string" then
            local exact = WeaponClassByName[weaponNameKey(label)]
            if exact then
                return exact
            end
        end
    end
    local blob = ""
    if type(data) == "table" then
        blob = tostring(data.displayname or data.displayName or data.name or data.Name or data.type or "")
    end
    if blob == "" and type(weapon._name) == "string" then
        blob = weapon._name
    end
    local upper = string.upper(blob)
    if upper == "" then
        return nil
    end
    local exact = WeaponClassByName[weaponNameKey(upper)]
    if exact then
        return exact
    end
    local tokenGroups = {
        { "machine pistol", { "MACHINE PISTOL", "G18", "TEC-9", "TEC9", "MAC-11", "MICRO UZI", "SKORPION", "93R", "PP-2000" } },
        { "revolver", { "REVOLVER", "REX", "MATEBA", "JUDGE", "RH-44", "RSH-12", "EXECUTIONER" } },
        { "pistol", { "PISTOL", "M9", "G17", "M1911", "DEAGLE", "FIVE SEVEN", "MAKAROV", "ZIP" } },
        { "shotgun", { "SHOTGUN", "KSG", "SAIGA", "SPAS", "AA-12", "USAS", "KS-23", "870", "ORIGIN 12" } },
        { "sniper rifle", { "SNIPER", "INTERVENTION", "AWM", "BFG", "HECATE", "MOSIN", "TRG", "WA2000", "NTW" } },
        { "dmr", { "DMR", "MK11", "SKS", "VSS", "SVU", "MK12", "MK20", "GDMR", "MSG90" } },
        { "lmg", { "LMG", "M249", "M60", "RPK", "MG3", "MG42", "HBAR", "PECHENEG", "PKM", "HAMR" } },
        { "pdw", { "PDW", "SMG", "MP5", "MP7", "P90", "VECTOR", "UMP", "PPSH", "BIZON", "UZI", "TOMMY" } },
        { "battle rifle", { "BATTLE RIFLE", "FAL", "SCAR-H", "MK17", "HCAR", "G3", "HK417", "SHAK-12", "M14" } },
        { "carbine", { "CARBINE", "M4A1", "G36C", "AK-12U", "AK-105", "GROZA", "SR-3M", "C8A3" } },
        { "assault rifle", { "ASSAULT", "AK-12", "M16", "FAMAS", "SCAR-L", "HK416", "AEK", "TAR-21" } },
        { "other", { "SHORTY", "THUMPER", "OBREZ", "COILGUN", "STAKEOUT" } },
    }
    for _, group in tokenGroups do
        for _, token in group[2] do
            if string.find(upper, token, 1, true) then
                return group[1]
            end
        end
    end
    return "assault rifle"
end

local function copyProfileInto(target, source)
    if not (target and source) then
        return
    end
    target.MouseEnabled = source.MouseEnabled and true or false
    target.SilentEnabled = source.SilentEnabled and true or false
    target.MouseFOV = source.MouseFOV
    target.MouseShowFOV = source.MouseShowFOV
    target.MouseFOVOrigin = source.MouseFOVOrigin
    target.SilentFOV = source.SilentFOV
    target.SilentShowFOV = source.SilentShowFOV
    target.SilentFOVOrigin = source.SilentFOVOrigin
    target.Smoothness = source.Smoothness
    target.MouseKey = source.MouseKey
    target.HitChance = source.HitChance
    target.TargetPart = source.TargetPart
    target.VisibleCheck = source.VisibleCheck
    target.MaxDistance = source.MaxDistance
end

local function applyHeldProfile()
    local held = normalizeWeaponClass((getgenv and getgenv().TapologyWeaponClass) or Config.Class) or "assault rifle"
    if held == "global" or Config.Profiles[held] == nil then
        held = "assault rifle"
    end
    local profile = Config.Profiles[held]
    if not profile then
        return
    end
    Config.Class = held
    copyProfileInto(Config, profile)
end

local env = getgenv and getgenv() or _G
if env.Aim then
    env.Aim.Unload()
end

env.__TapologyGameNetworkSend = nil

local LocalPlayer = Players.LocalPlayer
local hui = gethui and gethui()
local PhantomForces = game.PlaceId == 292439477 or game.PlaceId == 299659045
local Connections = {}
local Restores = {}

local Modules
local function findModules()
    if not getgc or (getactors and #getactors() > 0) then return end
    for _, value in getgc(true) do
        if type(value) == "table" and rawget(value, "ScreenCull") and rawget(value, "NetworkClient") then
            local modules = {}
            for name, data in value do
                modules[name] = type(data) == "table" and data.module ~= nil and data.module or data
            end
            return modules
        end
    end
end
if PhantomForces then
    local ok, found = pcall(findModules)
    Modules = ok and found or nil
end

local partNames = { head = "Head", torso = "Torso" }
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function visible(part, character)
    local camera = workspace.CurrentCamera
    local origin = camera.CFrame.Position
    local ignore = { camera, character }
    if PhantomForces then
        table.insert(ignore, workspace:FindFirstChild("Players"))
        table.insert(ignore, workspace:FindFirstChild("Ignore"))
    elseif LocalPlayer.Character then
        table.insert(ignore, LocalPlayer.Character)
    end
    rayParams.FilterDescendantsInstances = ignore
    local hit = workspace:Raycast(origin, part.Position - origin, rayParams)
    return not hit or (hit.Instance.Transparency >= 0.9 and not hit.Instance.CanCollide)
end

local function enemies()
    local list = {}
    local wanted = partNames[Config.TargetPart] or "Head"
    if Modules and Modules.ReplicationInterface and Modules.ReplicationInterface.operateOnAllEntries then
        local ok = pcall(function()
            Modules.ReplicationInterface.operateOnAllEntries(function(player, entry)
                local thirdPerson = entry._thirdPersonObject
                local hash = thirdPerson and thirdPerson._characterModelHash
                local part = hash and hash[wanted]
                if part and entry._isEnemy and entry._alive ~= false then
                    table.insert(list, { Player = player, Part = part, Character = thirdPerson._characterModel })
                end
            end)
        end)
        if ok and #list > 0 then
            return list
        end
    end
    if PhantomForces then
        local root = workspace:FindFirstChild("Players")
        for _, folder in root and root:GetChildren() or {} do
            for _, model in folder:GetChildren() do
                local tag = model:FindFirstChild("NameTagGui", true)
                local player = tag and tag:FindFirstChild("PlayerTag") and Players:FindFirstChild(tag.PlayerTag.Text)
                if player and player ~= LocalPlayer and player.TeamColor ~= LocalPlayer.TeamColor then
                    local part = tag.Parent
                    if wanted == "Torso" then
                        local body, volume = model:FindFirstChildOfClass("Folder"), 0
                        for _, piece in body and body:GetChildren() or {} do
                            if piece:IsA("BasePart") and piece.Size.X * piece.Size.Y * piece.Size.Z > volume then
                                part, volume = piece, piece.Size.X * piece.Size.Y * piece.Size.Z
                            end
                        end
                    end
                    table.insert(list, { Player = player, Part = part, Character = model })
                end
            end
        end
        return list
    end
    for _, player in Players:GetPlayers() do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local sameTeam = player.Team and player.Team == LocalPlayer.Team or (not player.Neutral and not LocalPlayer.Neutral and player.TeamColor == LocalPlayer.TeamColor)
        if player ~= LocalPlayer and humanoid and humanoid.Health > 0 and not sameTeam then
            local part = wanted == "Head" and character:FindFirstChild("Head")
                or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
            if part then
                table.insert(list, { Player = player, Part = part, Character = character })
            end
        end
    end
    return list
end

local MovementCache = { position = {}, time = {} }
local ChanceOne = 100

local function updateMovementCache()
    local now = os.clock()
    if Modules and Modules.ReplicationInterface and Modules.ReplicationInterface.operateOnAllEntries then
        pcall(function()
            Modules.ReplicationInterface.operateOnAllEntries(function(player, entry)
                if not entry._isEnemy then
                    return
                end
                local hash = entry._thirdPersonObject and entry._thirdPersonObject._characterModelHash
                local head = hash and hash.Head
                if not head then
                    return
                end
                local samples = MovementCache.position[player]
                if not samples then
                    samples = {}
                    MovementCache.position[player] = samples
                end
                table.insert(samples, 1, head.Position)
                table.remove(samples, 16)
            end)
        end)
    end
    table.insert(MovementCache.time, 1, now)
    table.remove(MovementCache.time, 16)
    for player in MovementCache.position do
        if not player.Parent then
            MovementCache.position[player] = nil
        end
    end
end

local function velocityOf(player)
    local samples = MovementCache.position[player]
    local times = MovementCache.time
    if not samples or not times then
        return Vector3.zero
    end
    local oldest = math.min(#samples, #times)
    if oldest < 2 then
        return Vector3.zero
    end
    local dt = times[oldest] - times[1]
    if dt == 0 then
        return Vector3.zero
    end
    return (samples[oldest] - samples[1]) / dt
end

local function fovOrigin(which)
    local key = which == "silent" and Config.SilentFOVOrigin or Config.MouseFOVOrigin
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(0, 0)
    local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    if key == "screen" or which == "silent" then

        if which == "silent" and key == "crosshair" then
            local mouse = UserInputService:GetMouseLocation()
            if (mouse - center).Magnitude >= 3 then
                return mouse
            end
        end
        return center
    end
    if Modules then
        local weapons = Modules.WeaponControllerInterface
        local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
        local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
        local barrel = weapon and not weapon._aiming and weapon._barrelPart
        if barrel and camera then
            local tip = camera:WorldToViewportPoint(barrel.CFrame * Vector3.new(0, 0, -100))
            if tip.Z > 0 then
                return Vector2.new(tip.X, tip.Y)
            end
        end
    end
    local mouse = UserInputService:GetMouseLocation()

    if (mouse - center).Magnitude < 3 then
        return center
    end
    return mouse
end

local function closest(list, radius, which)
    local camera = workspace.CurrentCamera
    local origin = fovOrigin(which or "mouse")
    local best, bestDistance = nil, radius
    for _, target in list do
        local position = target.Part.Position
        if (position - camera.CFrame.Position).Magnitude <= Config.MaxDistance then
            local screen = camera:WorldToViewportPoint(position)
            if screen.Z > 0 then
                local distance = (Vector2.new(screen.X, screen.Y) - origin).Magnitude
                if distance < bestDistance and (not Config.VisibleCheck or visible(target.Part, target.Character)) then
                    best, bestDistance = target, distance
                end
            end
        end
    end
    return best
end

local function solve(a, b, c, d, e)
    if not a then
        return
    elseif a > -1.0E-10 and a < 1.0E-10 then
        return solve(b, c, d, e)
    elseif e then
        local k = -b / (4 * a)
        local p = (c + k * (3 * b + 6 * a * k)) / a
        local q = (d + k * (2 * c + k * (3 * b + 4 * a * k))) / a
        local r = (e + k * (d + k * (c + k * (b + a * k)))) / a
        if q > -1.0E-10 and q < 1.0E-10 then
            local s1, s2 = solve(1, p, r)
            if not s2 or s2 < 0 then return end
            local r1, r2 = math.sqrt(s1), math.sqrt(s2)
            return k - r2, k - r1, k + r1, k + r2
        end
        local y1, _, y3 = solve(1, 2 * p, p * p - 4 * r, -q * q)
        local y = y3 or y1
        local m = math.sqrt(y)
        local u1, u2 = solve(1, m, (y + p - q / m) / 2)
        local v1, v2 = solve(1, -m, (y + p + q / m) / 2)
        if u1 and v1 then
            return k + u1, k + u2, k + v1, k + v2
        elseif u1 then
            return k + u1, k + u2
        elseif v1 then
            return k + v1, k + v2
        end
    elseif d then
        local k = -b / (3 * a)
        local p = -(c + k * (2 * b + 3 * a * k)) / (3 * a)
        local q = -(d + k * (c + k * (b + a * k))) / (2 * a)
        local disc = q * q - p * p * p
        local root = math.sqrt(math.abs(disc))
        if disc > 0 then
            local u, v = q + root, q - root
            u = u < 0 and -(-u) ^ (1 / 3) or u ^ (1 / 3)
            v = v < 0 and -(-v) ^ (1 / 3) or v ^ (1 / 3)
            return k + u + v
        end
        local angle = math.atan2(root, q) / 3
        local scale = 2 * math.sqrt(p)
        return k - scale * math.sin(angle + math.pi / 6), k + scale * math.sin(angle - math.pi / 6), k + scale * math.cos(angle)
    elseif c then
        local k = -b / (2 * a)
        local disc = k * k - c / a
        if disc < 0 then return end
        local root = math.sqrt(disc)
        return k - root, k + root
    elseif b then
        return -b / a
    end
end

local function complexTrajectory(o, a, t, s, e)
    local ld = t - o
    a = -a
    e = e or Vector3.zero
    local r1, r2, r3, r4 = solve(
        a:Dot(a) * 0.25,
        a:Dot(e),
        a:Dot(ld) + e:Dot(e) - s * s,
        ld:Dot(e) * 2,
        ld:Dot(ld)
    )
    local x = (r1 and r1 > 0 and r1) or (r2 and r2 > 0 and r2) or (r3 and r3 > 0 and r3) or r4
    if not x or x <= 0 then
        return ld.Unit * s, 0
    end
    return (ld + e * x + 0.5 * a * x * x) / x, x
end

local SilentTarget
local PendingPosition, PendingVelocity
local PendingSilentAt = 0
local LastSilent = { ok = false, reason = "init" }

local function bulletSpeed()
    local weapons = Modules and Modules.WeaponControllerInterface
    local ok, speed = pcall(function()
        return weapons.getActiveWeaponController():getActiveWeapon()._weaponData.bulletspeed
    end)
    if ok and type(speed) == "number" and speed > 0 then
        return speed
    end
    return 1000
end

local function bulletAccel(fallback)
    local settings = Modules and Modules.PublicSettings
    local accel = settings and settings.bulletAcceleration
    if typeof(accel) == "Vector3" then
        return accel
    end
    if typeof(fallback) == "Vector3" then
        return fallback
    end
    return Vector3.new(0, -workspace.Gravity, 0)
end

local function silentResolve()
    if not Config.Silent then
        LastSilent = { ok = false, reason = "disabled" }
        return
    end
    local now = os.clock()

    if PendingPosition and now - PendingSilentAt < 0.05 then
        LastSilent = { ok = true, reason = "pending" }
        return PendingPosition, PendingVelocity
    end
    if Config.HitChance < ChanceOne then
        LastSilent = { ok = false, reason = "hitchance" }
        PendingPosition, PendingVelocity = nil, nil
        PendingSilentAt = now
        return
    end

    local target = closest(enemies(), Config.SilentFOV, "silent") or SilentTarget
    if not (target and target.Part) then

        target = closest(enemies(), math.max(Config.SilentFOV, 1), "silent")
    end
    if not (target and target.Part) then
        LastSilent = { ok = false, reason = "nofov" }
        return
    end
    SilentTarget = target
    PendingPosition = target.Part.Position
    PendingVelocity = velocityOf(target.Player)
    PendingSilentAt = now
    LastSilent = { ok = true, reason = "hit", player = tostring(target.Player) }
    return PendingPosition, PendingVelocity
end

local function isFiniteVec3(v)
    return typeof(v) == "Vector3"
        and v.X == v.X and v.Y == v.Y and v.Z == v.Z
        and math.abs(v.X) < 1e6 and math.abs(v.Y) < 1e6 and math.abs(v.Z) < 1e6
end

local function rewriteNewBullets(bulletData)
    if type(bulletData) ~= "table" or type(bulletData.bullets) ~= "table" then
        return false
    end
    local target, enemyVel = silentResolve()
    if not target or not isFiniteVec3(target) then
        return false
    end
    local firepos = bulletData.firepos
    if not isFiniteVec3(firepos) then
        LastSilent = { ok = false, reason = "nofirepos" }
        return false
    end
    local speed = bulletSpeed()
    if type(speed) ~= "number" or not (speed > 0) or speed ~= speed then
        return false
    end
    local ok, direction = pcall(function()
        return complexTrajectory(firepos, bulletAccel(), target, speed, enemyVel or Vector3.zero)
    end)
    if not ok or not isFiniteVec3(direction) or direction.Magnitude < 1e-4 then
        LastSilent = { ok = false, reason = "traj:" .. tostring(direction) }
        return false
    end

    direction = direction.Unit
    if not isFiniteVec3(direction) then
        return false
    end
    for _, bullet in bulletData.bullets do
        if type(bullet) == "table" then
            bullet[1] = direction
        end
    end
    LastSilent = { ok = true, reason = "newbullets", speed = speed }
    return true
end

local function rewriteBulletObject(bulletData)
    if type(bulletData) ~= "table" or not bulletData.onplayerhit then
        return false
    end
    if not isFiniteVec3(bulletData.position) or not isFiniteVec3(bulletData.velocity) then
        return false
    end
    local target, enemyVel = silentResolve()
    if not target or not isFiniteVec3(target) then
        return false
    end
    local speed = bulletData.velocity.Magnitude
    if not (speed > 0) then
        return false
    end
    local ok, velocity = pcall(function()
        return complexTrajectory(
            bulletData.position,
            bulletAccel(bulletData.acceleration),
            target,
            speed,
            enemyVel or Vector3.zero
        )
    end)
    if not ok or not isFiniteVec3(velocity) or velocity.Magnitude < 1e-4 then
        LastSilent = { ok = false, reason = "bullettraj:" .. tostring(velocity) }
        return false
    end

    bulletData.velocity = velocity.Unit * speed
    LastSilent = { ok = true, reason = "bulletObject" }
    return true
end

local hookedSend, hookedNew
local restoreSend, restoreNew

local function uninstallSilentHooks()
    local network = Modules and Modules.NetworkClient
    local bullets = Modules and Modules.BulletObject
    if network and hookedSend and network.send == hookedSend and restoreSend then
        network.send = restoreSend
    end
    if bullets and hookedNew and bullets.new == hookedNew and restoreNew then
        bullets.new = restoreNew
    end
    hookedSend, hookedNew, restoreSend, restoreNew = nil, nil, nil, nil
end

local function installSilentHooks()
    if not Modules then
        return false
    end
    local network = Modules.NetworkClient
    local bullets = Modules.BulletObject
    if not network or type(network.send) ~= "function" then
        return false
    end
    if hookedSend and network.send == hookedSend then
        return true
    end
    if hookedSend and network.send == hookedSend and restoreSend then
        network.send = restoreSend
    end
    if hookedNew and bullets and bullets.new == hookedNew and restoreNew then
        bullets.new = restoreNew
    end

    local nextSend = network.send
    local thisHook = function(self, name, ...)
        if name == "newbullets" then
            local a, b = ...
            if type(b) == "table" and b.bullets then
                pcall(rewriteNewBullets, b)
            elseif type(a) == "table" and a.bullets then
                pcall(rewriteNewBullets, a)
            end
        end
        return nextSend(self, name, ...)
    end
    hookedSend = thisHook
    restoreSend = nextSend
    network.send = thisHook

    if bullets and type(bullets.new) == "function" then
        local nextNew = bullets.new
        local thisNew = function(bulletData, ...)
            if type(bulletData) == "table" then
                pcall(rewriteBulletObject, bulletData)
            end
            return nextNew(bulletData, ...)
        end
        hookedNew = thisNew
        restoreNew = nextNew
        bullets.new = thisNew
    end
    return true
end

local function syncSilentHooks()
    if not Modules then
        return
    end
    if Config.Silent then
        installSilentHooks()
    else
        uninstallSilentHooks()
    end
end

if Modules then

    task.defer(syncSilentHooks)
    table.insert(Restores, uninstallSilentHooks)
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "Aim"
Gui.IgnoreGuiInset = true
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 5
Gui.Parent = (hui and not hui:IsA("LayerCollector")) and hui or CoreGui

local function ring(parent)
    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame
    return frame, stroke
end

local function newCircle(name)
    local holder = Instance.new("Frame")
    holder.Name = name
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.fromOffset(0, 0)
    holder.Visible = false
    holder.Parent = Gui
    local circle = { Holder = holder }
    circle.Outline, circle.OutlineStroke = ring(holder)
    circle.Line, circle.LineStroke = ring(holder)
    circle.Inline, circle.InlineStroke = ring(holder)
    return circle
end

local Circles = { Mouse = newCircle("MouseFOV"), Silent = newCircle("SilentFOV") }

local function drawCircle(circle, shown, radius, color, transparency, cursor, dt)
    if not shown then
        circle.Holder.Visible = false
        circle.DisplayRadius = radius
        return
    end
    local current = circle.DisplayRadius
    if typeof(current) ~= "number" then
        current = radius
    end
    local alpha = 1 - math.exp(-(math.max(dt or 0.016, 0)) * 14)
    current += (radius - current) * alpha
    if math.abs(current - radius) < 0.15 then
        current = radius
    end
    circle.DisplayRadius = current
    circle.Holder.Visible = true
    circle.Holder.Position = UDim2.fromOffset(math.floor(cursor.X + 0.5), math.floor(cursor.Y + 0.5))
    local size = math.floor(current + 0.5) * 2
    circle.Line.Size = UDim2.fromOffset(size, size)
    circle.Outline.Size = UDim2.fromOffset(size + 2, size + 2)
    circle.Inline.Size = UDim2.fromOffset(math.max(size - 2, 0), math.max(size - 2, 0))
    circle.LineStroke.Color, circle.LineStroke.Transparency = color, transparency
    circle.OutlineStroke.Color, circle.OutlineStroke.Transparency = Color3.new(0, 0, 0), transparency
    circle.InlineStroke.Color, circle.InlineStroke.Transparency = Color3.new(0, 0, 0), transparency
end

local function keyHeld()
    local key = Config.MouseKey
    if key == "always" then return true end
    local button = key == "left mouse" and Enum.UserInputType.MouseButton1 or Enum.UserInputType.MouseButton2
    return UserInputService:IsMouseButtonPressed(button)
end

local wasSilent = Config.Silent
local lastCacheAt = 0
table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
    applyHeldProfile()
    syncMode()
    if Config.Silent ~= wasSilent then
        wasSilent = Config.Silent
        syncSilentHooks()
    end

    local mouseOrigin = fovOrigin("mouse")
    local silentOrigin = fovOrigin("silent")
    local heldClass = normalizeWeaponClass(getgenv().TapologyWeaponClass)
    local showHeldFov = heldClass ~= nil and heldClass ~= "global" and Config.Profiles[heldClass] ~= nil
    drawCircle(
        Circles.Mouse,
        showHeldFov and Config.Mouse and Config.MouseShowFOV,
        Config.MouseFOV,
        Config.MouseFOVColor,
        Config.MouseFOVTransparency,
        mouseOrigin,
        dt
    )
    drawCircle(
        Circles.Silent,
        showHeldFov and Config.Silent and Config.SilentShowFOV,
        Config.SilentFOV,
        Config.SilentFOVColor,
        Config.SilentFOVTransparency,
        silentOrigin,
        dt
    )

    if not Config.Enabled then
        SilentTarget = nil
        return
    end

    if Config.Silent then
        ChanceOne = math.random(1, 100)
        local now = os.clock()
        if now - lastCacheAt >= 0.05 then
            lastCacheAt = now
            updateMovementCache()
        end
    end

    if not (Config.Silent or Config.Mouse) then
        SilentTarget = nil
        return
    end

    local list = enemies()
    SilentTarget = Config.Silent and closest(list, Config.SilentFOV, "silent") or nil

    if Config.Mouse and mousemoverel and keyHeld() then
        local target = closest(list, Config.MouseFOV, "mouse")
        if target then
            local screen = workspace.CurrentCamera:WorldToViewportPoint(target.Part.Position)
            local delta = Vector2.new(screen.X, screen.Y) - mouseOrigin

            local smooth = tonumber(Config.Smoothness) or 0
            local share = 1 - math.clamp(smooth, 0, 0.98) ^ (math.max(dt or 0, 0) * 60)
            local step = delta * share
            if step.Magnitude > 0.5 then
                mousemoverel(step.X, step.Y)
            end
        end
    end
end))

env.Aim = {
    Config = Config,
    Classes = WeaponClasses,
    Classify = resolveWeaponClass,
    SilentAvailable = Modules ~= nil and Modules.NetworkClient ~= nil,
    LastSilent = function()
        return LastSilent
    end,
    Rehook = installSilentHooks,
    SetEnabled = function(on)
        local enabled = on and true or false
        Config.Enabled = enabled
        if Config.Mode == "silent" then
            Config.SilentEnabled = enabled
        else
            Config.MouseEnabled = enabled
        end
        syncMode()
        syncSilentHooks()
    end,
    SetMode = function(mode)
        Config.Mode = mode == "silent" and "silent" or "mouse"
        syncMode()
        syncSilentHooks()
    end,

    SetColor = function(slot, color, transparency)
        Config[slot .. "Color"] = color
        if transparency then
            Config[slot .. "Transparency"] = transparency
        end
    end,
    Unload = function()
        for _, connection in Connections do
            connection:Disconnect()
        end
        table.clear(Connections)
        for _, restore in Restores do
            pcall(restore)
        end
        table.clear(Restores)
        Gui:Destroy()
        env.Aim = nil
    end,
}

end
do

local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Lighting = cloneref(game:GetService("Lighting"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local Config = {
    Ambience = false,
    Ambient = rgb(128, 128, 128),
    OutdoorAmbient = rgb(128, 128, 128),

    Clock = false,
    ClockTime = 14,

    Fog = false,
    FogDensity = 0.3,
    FogOffset = 0,
    FogColor = rgb(190, 200, 210),
    FogDecay = rgb(120, 130, 140),
    FogHaze = 1.5,
    FogGlare = 0,

    Lighting = false,
    Brightness = 2,
    ExposureCompensation = 0,

    ColorCorrection = false,
    Saturation = 0,
    Contrast = 0,
    CorrectionBrightness = 0,
    Exposure = 0,
    TintColor = rgb(255, 255, 255),

    DynamicExposure = false,
    DynamicExposureMin = -0.4,
    DynamicExposureMax = 0.8,
    DynamicExposureSpeed = 2,

    Sun = false,
    SunBrightness = 2,
    SunSize = 21,
    RemoveSun = false,
    RemoveMoon = false,
    RemoveStars = false,
    WorldTexture = false,
    WorldMaterial = "SmoothPlastic",

    Skybox = false,
    SkyboxId = "Afternoon",
    Skyboxes = {
        ["Afternoon"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://162001926", SkyboxDn = "rbxassetid://161998893", SkyboxFt = "rbxassetid://162001897", SkyboxBk = "rbxassetid://162001887", SkyboxLf = "rbxassetid://162001904", SkyboxRt = "rbxassetid://162001919" },
        ["Blue Space"] = { StarCount = 0, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://367149078", SkyboxDn = "rbxassetid://367147970", SkyboxFt = "rbxassetid://366731193", SkyboxBk = "rbxassetid://366731024", SkyboxLf = "rbxassetid://366731613", SkyboxRt = "rbxassetid://366731514" },
        ["Classic Roblox"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://11138465883", SkyboxDn = "rbxassetid://11138453351", SkyboxFt = "rbxassetid://11138458027", SkyboxBk = "rbxassetid://11138450201", SkyboxLf = "rbxassetid://11138460736", SkyboxRt = "rbxassetid://11138463127", SunTextureId = "rbxassetid://11138537872" },
        ["Cloudy"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://246480504", SkyboxDn = "rbxassetid://246480523", SkyboxFt = "rbxassetid://246480105", SkyboxBk = "rbxassetid://246480323", SkyboxLf = "rbxassetid://246480549", SkyboxRt = "rbxassetid://246480565" },
        ["Dusk"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 11, SkyboxUp = "rbxassetid://9778106496", SkyboxDn = "rbxassetid://9778110864", SkyboxFt = "rbxassetid://9778101192", SkyboxBk = "rbxassetid://9778108979", SkyboxLf = "rbxassetid://9778103329", SkyboxRt = "rbxassetid://9778104889" },
        ["Dawn"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://323478865", SkyboxDn = "rbxassetid://323481190", SkyboxFt = "rbxassetid://323480314", SkyboxBk = "rbxassetid://323479840", SkyboxLf = "rbxassetid://323480786", SkyboxRt = "rbxassetid://323480131" },
        ["Dark Skies"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://149397702", SkyboxDn = "rbxassetid://149397686", SkyboxFt = "rbxassetid://149397697", SkyboxBk = "rbxassetid://149397692", SkyboxLf = "rbxassetid://149397684", SkyboxRt = "rbxassetid://149397688" },
        ["Earth"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://15753304473", SkyboxDn = "rbxassetid://15753362674", SkyboxFt = "rbxassetid://15753305823", SkyboxBk = "rbxassetid://15753305495", SkyboxLf = "rbxassetid://15753310707", SkyboxRt = "rbxassetid://15753304774" },
        ["Ethereal"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://16823395515", SkyboxDn = "rbxassetid://16823388586", SkyboxFt = "rbxassetid://16823390254", SkyboxBk = "rbxassetid://16823386986", SkyboxLf = "rbxassetid://16823392344", SkyboxRt = "rbxassetid://16823394120" },
        ["Galaxy"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://2049518578", SkyboxDn = "rbxassetid://2049519279", SkyboxFt = "rbxassetid://2049519882", SkyboxBk = "rbxassetid://2049520382", SkyboxLf = "rbxassetid://2049522478", SkyboxRt = "rbxassetid://2049521207" },
        ["Heaven"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://7951703855", SkyboxDn = "rbxassetid://7951706908", SkyboxFt = "rbxassetid://7951694757", SkyboxBk = "rbxassetid://7951826533", SkyboxLf = "rbxassetid://7951697216", SkyboxRt = "rbxassetid://7951700251" },
        ["Horizontal Milky Way"] = { StarCount = 0, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://714276621", SkyboxDn = "rbxassetid://714276541", SkyboxFt = "rbxassetid://714276657", SkyboxBk = "rbxassetid://714276643", SkyboxLf = "rbxassetid://714276648", SkyboxRt = "rbxassetid://714276638" },
        ["Jungle"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://525546479", SkyboxDn = "rbxassetid://525544628", SkyboxFt = "rbxassetid://525548536", SkyboxBk = "rbxassetid://525546178", SkyboxLf = "rbxassetid://525550171", SkyboxRt = "rbxassetid://525545319" },
        ["Mountains"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://48015387", SkyboxDn = "rbxassetid://48015300", SkyboxFt = "rbxassetid://368388290", SkyboxBk = "rbxassetid://368385273", SkyboxLf = "rbxassetid://368390615", SkyboxRt = "rbxassetid://368385190" },
        ["Nebula"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://171448889", SkyboxDn = "rbxassetid://171448902", SkyboxFt = "rbxassetid://171448848", SkyboxBk = "rbxassetid://171448875", SkyboxLf = "rbxassetid://171448933", SkyboxRt = "rbxassetid://171448925" },
        ["Night"] = { StarCount = 0, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://12064131", SkyboxDn = "rbxassetid://12064152", SkyboxFt = "rbxassetid://12064121", SkyboxBk = "rbxassetid://12064107", SkyboxLf = "rbxassetid://12063984", SkyboxRt = "rbxassetid://12064115" },
        ["Night Light"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://171447068", SkyboxDn = "rbxassetid://171447094", SkyboxFt = "rbxassetid://171447041", SkyboxBk = "rbxassetid://171447054", SkyboxLf = "rbxassetid://171447128", SkyboxRt = "rbxassetid://171447111" },
        ["Ocean Sky"] = { StarCount = 3000, SunAngularSize = 1, MoonAngularSize = 0, SkyboxUp = "rbxassetid://11854708161", SkyboxDn = "rbxassetid://11854687121", SkyboxFt = "rbxassetid://11854693863", SkyboxBk = "rbxassetid://11854686548", SkyboxLf = "rbxassetid://11854696162", SkyboxRt = "rbxassetid://11854698541", SunTextureId = "rbxassetid://4774583925", MoonTextureId = "rbxassetid://4774580371" },
        ["Pink Clouds"] = { StarCount = 1334, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://271077958", SkyboxDn = "rbxassetid://271077243", SkyboxFt = "rbxassetid://271042556", SkyboxBk = "rbxassetid://271042516", SkyboxLf = "rbxassetid://271042310", SkyboxRt = "rbxassetid://271042467" },
        ["Pink Daylight"] = { SkyboxUp = "rbxassetid://271077958", SkyboxDn = "rbxassetid://271077243", SkyboxFt = "rbxassetid://271042556", SkyboxBk = "rbxassetid://271042516", SkyboxLf = "rbxassetid://271042310", SkyboxRt = "rbxassetid://271042467" },
        ["Red Dusk"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://136208328681929", SkyboxDn = "rbxassetid://123407860042117", SkyboxFt = "rbxassetid://132624761762466", SkyboxBk = "rbxassetid://85146619291315", SkyboxLf = "rbxassetid://102069641249982", SkyboxRt = "rbxassetid://136526747107728" },
        ["Redshift"] = { StarCount = 0, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://401664936", SkyboxDn = "rbxassetid://401664862", SkyboxFt = "rbxassetid://401664960", SkyboxBk = "rbxassetid://401664839", SkyboxLf = "rbxassetid://401664881", SkyboxRt = "rbxassetid://401664901" },
        ["Saturn"] = { StarCount = 3000, SunAngularSize = 10, MoonAngularSize = 0, SkyboxUp = "rbxassetid://1898736761", SkyboxDn = "rbxassetid://1898727189", SkyboxFt = "rbxassetid://1898722814", SkyboxBk = "rbxassetid://1898724755", SkyboxLf = "rbxassetid://1898729298", SkyboxRt = "rbxassetid://1898741025", MoonTextureId = "rbxassetid://0" },
        ["SFOTH"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://1014449", SkyboxDn = "rbxassetid://1012891", SkyboxFt = "rbxassetid://1012887", SkyboxBk = "rbxassetid://1012890", SkyboxLf = "rbxassetid://1012889", SkyboxRt = "rbxassetid://1012888" },
        ["Smoke"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://171410742", SkyboxDn = "rbxassetid://171410748", SkyboxFt = "rbxassetid://171410730", SkyboxBk = "rbxassetid://171410736", SkyboxLf = "rbxassetid://171410766", SkyboxRt = "rbxassetid://171410755" },
        ["Solid Black"] = { StarCount = 0, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://2013298", SkyboxDn = "rbxassetid://2013298", SkyboxFt = "rbxassetid://2013298", SkyboxBk = "rbxassetid://2013298", SkyboxLf = "rbxassetid://2013298", SkyboxRt = "rbxassetid://2013298" },
        ["Space"] = { StarCount = 0, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://155441905", SkyboxDn = "rbxassetid://155441905", SkyboxFt = "rbxassetid://155441905", SkyboxBk = "rbxassetid://155441905", SkyboxLf = "rbxassetid://155441905", SkyboxRt = "rbxassetid://155441905" },
        ["Storm"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://171410789", SkyboxDn = "rbxassetid://171410792", SkyboxFt = "rbxassetid://171410775", SkyboxBk = "rbxassetid://171410784", SkyboxLf = "rbxassetid://171410807", SkyboxRt = "rbxassetid://171410798" },
        ["Sunset"] = { StarCount = 5000, SunAngularSize = 18, MoonAngularSize = 11, SkyboxUp = "rbxassetid://264907379", SkyboxDn = "rbxassetid://264907909", SkyboxFt = "rbxassetid://264909420", SkyboxBk = "rbxassetid://264908339", SkyboxLf = "rbxassetid://264909758", SkyboxRt = "rbxassetid://264908886" },
        ["Underworld"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://171561009", SkyboxDn = "rbxassetid://171561019", SkyboxFt = "rbxassetid://171560968", SkyboxBk = "rbxassetid://171560994", SkyboxLf = "rbxassetid://171561065", SkyboxRt = "rbxassetid://171561026" },
        ["Vertical Milky Way"] = { StarCount = 3000, SunAngularSize = 1.440000057220459, MoonAngularSize = 0.5699999928474426, SkyboxUp = "rbxassetid://5559302033", SkyboxDn = "rbxassetid://5559290893", SkyboxFt = "rbxassetid://5559300879", SkyboxBk = "rbxassetid://5559289158", SkyboxLf = "rbxassetid://5559292825", SkyboxRt = "rbxassetid://5559302989" },
        ["White"] = { StarCount = 0, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://321136141", SkyboxDn = "rbxassetid://321136141", SkyboxFt = "rbxassetid://321136141", SkyboxBk = "rbxassetid://321136141", SkyboxLf = "rbxassetid://321136141", SkyboxRt = "rbxassetid://321136141" },
        ["GreenHaze"] = { SunAngularSize = 0, SkyboxUp = "rbxassetid://160193458", SkyboxDn = "rbxassetid://160193466", SkyboxFt = "rbxassetid://160193461", SkyboxBk = "rbxassetid://160193404", SkyboxLf = "rbxassetid://160193469", SkyboxRt = "rbxassetid://160193463" },
        ["Space2"] = { StarCount = 3000, SunAngularSize = 11, MoonAngularSize = 20, SkyboxUp = "rbxassetid://11844053742", SkyboxDn = "rbxassetid://11844069700", SkyboxFt = "rbxassetid://11844067209", SkyboxBk = "rbxassetid://11844076072", SkyboxLf = "rbxassetid://11844063543", SkyboxRt = "rbxassetid://11844058446", MoonTextureId = "rbxassetid://11844121592" },
        ["PinkMountains"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 0, SkyboxUp = "rbxassetid://160188588", SkyboxDn = "rbxassetid://160188614", SkyboxFt = "rbxassetid://160188609", SkyboxBk = "rbxassetid://160188495", SkyboxLf = "rbxassetid://160188589", SkyboxRt = "rbxassetid://160188597" },
        ["Valentines"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 0, SkyboxUp = "rbxassetid://11427771954", SkyboxDn = "rbxassetid://11427770685", SkyboxFt = "rbxassetid://11427769401", SkyboxBk = "rbxassetid://11427769401", SkyboxLf = "rbxassetid://11427769401", SkyboxRt = "rbxassetid://11427769401" },
        ["PinkArt"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 0, SkyboxUp = "rbxassetid://79190209626172", SkyboxDn = "rbxassetid://78865378050055", SkyboxFt = "rbxassetid://104560113223878", SkyboxBk = "rbxassetid://71607054149497", SkyboxLf = "rbxassetid://80395333901607", SkyboxRt = "rbxassetid://87570388049514" },
        ["PurplePlanet"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 0, SkyboxUp = "rbxassetid://16262366016", SkyboxDn = "rbxassetid://16262358026", SkyboxFt = "rbxassetid://16262360469", SkyboxBk = "rbxassetid://16262356578", SkyboxLf = "rbxassetid://16262362003", SkyboxRt = "rbxassetid://16262363873", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["Blizzard"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 0, SkyboxUp = "rbxassetid://16653228333", SkyboxDn = "rbxassetid://16653222701", SkyboxFt = "rbxassetid://16653224051", SkyboxBk = "rbxassetid://16653221738", SkyboxLf = "rbxassetid://16653225849", SkyboxRt = "rbxassetid://16653227200", SunTextureId = "rbxassetid://6196665106", MoonTextureId = "rbxassetid://6444320592" },
        ["Winter"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://155674931", SkyboxDn = "rbxassetid://155674246", SkyboxFt = "rbxassetid://155657609", SkyboxBk = "rbxassetid://155657655", SkyboxLf = "rbxassetid://155657671", SkyboxRt = "rbxassetid://155657619", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["FlamingSunset"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://415688354", SkyboxDn = "rbxassetid://415688193", SkyboxFt = "rbxassetid://415688242", SkyboxBk = "rbxassetid://415688378", SkyboxLf = "rbxassetid://415688310", SkyboxRt = "rbxassetid://415688274", SunTextureId = "rbxassetid://6196665106", MoonTextureId = "rbxassetid://6444320592" },
        ["Mountains 2"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 0, SkyboxUp = "rbxassetid://15359412677", SkyboxDn = "rbxassetid://15359411132", SkyboxFt = "rbxassetid://15359412131", SkyboxBk = "rbxassetid://15359410490", SkyboxLf = "rbxassetid://15359411633", SkyboxRt = "rbxassetid://15359417656", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["FPSBoost"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://11457548274", SkyboxDn = "rbxassetid://11457548274", SkyboxFt = "rbxassetid://11457548274", SkyboxBk = "rbxassetid://11457548274", SkyboxLf = "rbxassetid://11457548274", SkyboxRt = "rbxassetid://11457548274", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["AestheticMountains"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://15470207755", SkyboxDn = "rbxassetid://15470151245", SkyboxFt = "rbxassetid://15470200128", SkyboxBk = "rbxassetid://15470198023", SkyboxLf = "rbxassetid://15470202648", SkyboxRt = "rbxassetid://15470204862", SunTextureId = "rbxassetid://6196665106", MoonTextureId = "rbxassetid://6444320592" },
        ["BetterNight3"] = { StarCount = 500, SunAngularSize = 21, MoonAngularSize = 1.5, SkyboxUp = "rbxassetid://2670644331", SkyboxDn = "rbxassetid://2670643365", SkyboxFt = "rbxassetid://2670643214", SkyboxBk = "rbxassetid://2670643994", SkyboxLf = "rbxassetid://2670643070", SkyboxRt = "rbxassetid://2670644173", SunTextureId = "rbxassetid://6196665106", MoonTextureId = "rbxassetid://1075087760" },
        ["Galaxy2"] = { StarCount = 500, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://14164405298", SkyboxDn = "rbxassetid://14164386126", SkyboxFt = "rbxassetid://14164389230", SkyboxBk = "rbxassetid://14164368678", SkyboxLf = "rbxassetid://14164398493", SkyboxRt = "rbxassetid://14164402782", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["Aesthetic3"] = { StarCount = 500, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://151165227", SkyboxDn = "rbxassetid://151165197", SkyboxFt = "rbxassetid://151165224", SkyboxBk = "rbxassetid://151165214", SkyboxLf = "rbxassetid://151165191", SkyboxRt = "rbxassetid://151165206", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["PurpleSpace"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://15983964246", SkyboxDn = "rbxassetid://15983966825", SkyboxFt = "rbxassetid://5260817288", SkyboxBk = "rbxassetid://15983968922", SkyboxLf = "rbxassetid://15983967420", SkyboxRt = "rbxassetid://15983966246", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["Pink"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://271077958", SkyboxDn = "rbxassetid://271077243", SkyboxFt = "rbxassetid://271042556", SkyboxBk = "rbxassetid://271042516", SkyboxLf = "rbxassetid://271042310", SkyboxRt = "rbxassetid://271042467", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["PurpleNight"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://5084576400", SkyboxDn = "rbxassetid://5260653793", SkyboxFt = "rbxassetid://5260817288", SkyboxBk = "rbxassetid://5260808177", SkyboxLf = "rbxassetid://5260800833", SkyboxRt = "rbxassetid://5260800833", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["Flame"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 0, SkyboxUp = "rbxassetid://6286790025", SkyboxDn = "rbxassetid://6286782353", SkyboxFt = "rbxassetid://6286784186", SkyboxBk = "rbxassetid://6286780109", SkyboxLf = "rbxassetid://6286785801", SkyboxRt = "rbxassetid://6286788245", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["Galaxy3"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://14543371676", SkyboxDn = "rbxassetid://14543358958", SkyboxFt = "rbxassetid://14543257810", SkyboxBk = "rbxassetid://14543264135", SkyboxLf = "rbxassetid://14543275895", SkyboxRt = "rbxassetid://14543280890", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["Storm 2"] = { SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://1618913654", SkyboxDn = "rbxassetid://1618913943", SkyboxFt = "rbxassetid://1618913244", SkyboxBk = "rbxassetid://1618912481", SkyboxLf = "rbxassetid://1618912849", SkyboxRt = "rbxassetid://1618911568", SunTextureId = "rbxassetid://1084351190", MoonTextureId = "rbxassetid://1075087760" },
        ["Milkyway"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://137817405681365", SkyboxDn = "rbxassetid://108406529909981", SkyboxFt = "rbxassetid://104400530594543", SkyboxBk = "rbxassetid://129876530632297", SkyboxLf = "rbxassetid://73372229972523", SkyboxRt = "rbxassetid://87408857415924", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["PurpleClouds"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 0, SkyboxUp = "rbxassetid://570557727", SkyboxDn = "rbxassetid://570557775", SkyboxFt = "rbxassetid://570557559", SkyboxBk = "rbxassetid://570557514", SkyboxLf = "rbxassetid://570557620", SkyboxRt = "rbxassetid://570557672", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["BlueClouds"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://591059642", SkyboxDn = "rbxassetid://591059876", SkyboxFt = "rbxassetid://591058104", SkyboxBk = "rbxassetid://591058823", SkyboxLf = "rbxassetid://591057861", SkyboxRt = "rbxassetid://591057625", SunTextureId = "rbxassetid://6196665106", MoonTextureId = "rbxassetid://6444320592" },
        ["BetterNight"] = { StarCount = 3000, SkyboxUp = "rbxassetid://15470303050", SkyboxDn = "rbxassetid://15470291746", SkyboxFt = "rbxassetid://15470294431", SkyboxBk = "rbxassetid://15470289121", SkyboxLf = "rbxassetid://15470297162", SkyboxRt = "rbxassetid://15470299887" },
        ["Cloudy 2"] = { StarCount = 3000, SkyboxUp = "rbxassetid://4495867486", SkyboxDn = "rbxassetid://4495864887", SkyboxFt = "rbxassetid://4495865458", SkyboxBk = "rbxassetid://4495864450", SkyboxLf = "rbxassetid://4495866035", SkyboxRt = "rbxassetid://4495866584" },
        ["NetherWorld"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://14365019327", SkyboxDn = "rbxassetid://14365023350", SkyboxFt = "rbxassetid://14365018399", SkyboxBk = "rbxassetid://14365019002", SkyboxLf = "rbxassetid://14365018705", SkyboxRt = "rbxassetid://14365018143", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["NewYork"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://11333967970", SkyboxDn = "rbxassetid://11333969768", SkyboxFt = "rbxassetid://11333964303", SkyboxBk = "rbxassetid://11333973069", SkyboxLf = "rbxassetid://11333971332", SkyboxRt = "rbxassetid://11333982864", SunTextureId = "rbxassetid://6196665106", MoonTextureId = "rbxassetid://6444320592" },
        ["Purple2"] = { StarCount = 3000, SunAngularSize = 11, MoonAngularSize = 0, SkyboxUp = "rbxassetid://8107849791", SkyboxDn = "rbxassetid://6444884785", SkyboxFt = "rbxassetid://8107841671", SkyboxBk = "rbxassetid://8107841671", SkyboxLf = "rbxassetid://8107841671", SkyboxRt = "rbxassetid://8107841671", SunTextureId = "rbxassetid://6196665106", MoonTextureId = "rbxassetid://6444320592" },
        ["FunnyStorm"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 0, SkyboxUp = "rbxassetid://6280942402", SkyboxDn = "rbxassetid://6280935347", SkyboxFt = "rbxassetid://6280936575", SkyboxBk = "rbxassetid://6280934001", SkyboxLf = "rbxassetid://6280938749", SkyboxRt = "rbxassetid://6280940989", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["Galaxy Alt"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://159454288", SkyboxDn = "rbxassetid://159454296", SkyboxFt = "rbxassetid://159454293", SkyboxBk = "rbxassetid://159454299", SkyboxLf = "rbxassetid://159454293", SkyboxRt = "rbxassetid://159454293", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["BlueSpace"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 0, SkyboxUp = "rbxassetid://16876552681", SkyboxDn = "rbxassetid://16876543880", SkyboxFt = "rbxassetid://16876546384", SkyboxBk = "rbxassetid://16876541778", SkyboxLf = "rbxassetid://16876548320", SkyboxRt = "rbxassetid://16876550345", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["Purple3"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://433274285", SkyboxDn = "rbxassetid://433274194", SkyboxFt = "rbxassetid://433274131", SkyboxBk = "rbxassetid://433274085", SkyboxLf = "rbxassetid://433274370", SkyboxRt = "rbxassetid://433274429", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["Nebula2"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://16932810138", SkyboxDn = "rbxassetid://16932797813", SkyboxFt = "rbxassetid://16932800523", SkyboxBk = "rbxassetid://16932794531", SkyboxLf = "rbxassetid://16932803722", SkyboxRt = "rbxassetid://16932806825", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["Nebula Alt"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://5260824661", SkyboxDn = "rbxassetid://5260653793", SkyboxFt = "rbxassetid://5260817288", SkyboxBk = "rbxassetid://5260808177", SkyboxLf = "rbxassetid://5260800833", SkyboxRt = "rbxassetid://5260811073", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["LunarNight"] = { StarCount = 0, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://187712111", SkyboxDn = "rbxassetid://187712428", SkyboxFt = "rbxassetid://187712836", SkyboxBk = "rbxassetid://187713366", SkyboxLf = "rbxassetid://187713755", SkyboxRt = "rbxassetid://187714525", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["Purple"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://8539981085", SkyboxDn = "rbxassetid://8539981943", SkyboxFt = "rbxassetid://8539981721", SkyboxBk = "rbxassetid://8539982183", SkyboxLf = "rbxassetid://8539981424", SkyboxRt = "rbxassetid://8539980766", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["Hell"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 11, SkyboxUp = "rbxassetid://11730857150", SkyboxDn = "rbxassetid://11730842997", SkyboxFt = "rbxassetid://11730849615", SkyboxBk = "rbxassetid://11730840088", SkyboxLf = "rbxassetid://11730852920", SkyboxRt = "rbxassetid://11730855491", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["Nebula6"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://16694204069", SkyboxDn = "rbxassetid://16694190947", SkyboxFt = "rbxassetid://16694194795", SkyboxBk = "rbxassetid://16694187412", SkyboxLf = "rbxassetid://16694197080", SkyboxRt = "rbxassetid://16694200892", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["DarkishPink"] = { StarCount = 3000, SunAngularSize = 21, MoonAngularSize = 11, SkyboxUp = "rbxassetid://570555929", SkyboxDn = "rbxassetid://570555964", SkyboxFt = "rbxassetid://570555800", SkyboxBk = "rbxassetid://570555736", SkyboxLf = "rbxassetid://570555840", SkyboxRt = "rbxassetid://570555882", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["RedNight"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://401664936", SkyboxDn = "rbxassetid://401664862", SkyboxFt = "rbxassetid://401664960", SkyboxBk = "rbxassetid://401664839", SkyboxLf = "rbxassetid://401664881", SkyboxRt = "rbxassetid://401664901", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
        ["Space Alt"] = { StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 0, SkyboxUp = "rbxassetid://166510114", SkyboxDn = "rbxassetid://166510057", SkyboxFt = "rbxassetid://166510116", SkyboxBk = "rbxassetid://166509999", SkyboxLf = "rbxassetid://166510092", SkyboxRt = "rbxassetid://166510131", SunTextureId = "rbxassetid://8281961896", MoonTextureId = "rbxassetid://6444320592" },
    },

    Bloom = false,
    BloomIntensity = 0.4,
    BloomSize = 24,
    BloomThreshold = 1.5,

    DepthOfField = false,
    DoFFarIntensity = 0.4,
    DoFNearIntensity = 0.2,
    DoFFocusDistance = 40,
    DoFInFocusRadius = 20,
}

local env = getgenv and getgenv() or _G
if env.World then
    env.World.Unload()
end

local Connections = {}
local Original = {}
local Created = {}
local Grade
local Atmosphere
local BloomEffect
local DoFEffect
local SkyInstance
local DynamicValue = 0

local function ensureAtmosphere()
    Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not Atmosphere then
        Atmosphere = Instance.new("Atmosphere")
        Atmosphere.Density = 0
        Atmosphere.Haze = 0
        Atmosphere.Glare = 0
        Atmosphere.Parent = Lighting
        table.insert(Created, Atmosphere)
    end
    return Atmosphere
end

local function ensureGrade()
    if Grade and Grade.Parent then return Grade end
    Grade = Instance.new("ColorCorrectionEffect")
    Grade.Name = "TapologyWorld"
    Grade.Enabled = false
    Grade.Parent = Lighting
    table.insert(Created, Grade)
    return Grade
end

local function capture()
    Original.Ambient = Lighting.Ambient
    Original.OutdoorAmbient = Lighting.OutdoorAmbient
    Original.ClockTime = Lighting.ClockTime
    Original.Brightness = Lighting.Brightness
    Original.ExposureCompensation = Lighting.ExposureCompensation
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        Original.Fog = {
            Density = atmosphere.Density,
            Offset = atmosphere.Offset,
            Color = atmosphere.Color,
            Decay = atmosphere.Decay,
            Haze = atmosphere.Haze,
            Glare = atmosphere.Glare,
        }
    end
end

local function weatherActive()
    local weather = env.Weather
    local mode = weather and weather.Config and weather.Config.Mode
    return type(mode) == "string" and mode ~= "" and mode ~= "Off"
end

local function weatherOwnsEnvironment()
    if not weatherActive() then
        return false
    end
    local weather = env.Weather
    return weather.Config.ChangeEnvironment ~= false
end

local function restoreAmbience()
    if weatherOwnsEnvironment() then
        return
    end
    Lighting.Ambient = Original.Ambient
    Lighting.OutdoorAmbient = Original.OutdoorAmbient
end
local function restoreClock()
    if weatherOwnsEnvironment() then
        return
    end
    Lighting.ClockTime = Original.ClockTime
end
local function restoreLighting()
    if weatherOwnsEnvironment() then
        return
    end
    Lighting.Brightness = Original.Brightness
    if not Config.DynamicExposure then
        Lighting.ExposureCompensation = Original.ExposureCompensation
    end
    if not Config.Ambience then
        Lighting.Ambient = Original.Ambient
        Lighting.OutdoorAmbient = Original.OutdoorAmbient
    end
end
local function writeAtmosphereFromConfig()
    local atmosphere = ensureAtmosphere()
    atmosphere.Density = tonumber(Config.FogDensity) or 0.3
    atmosphere.Offset = tonumber(Config.FogOffset) or 0
    atmosphere.Haze = tonumber(Config.FogHaze) or 1.5
    atmosphere.Glare = tonumber(Config.FogGlare) or 0
    if typeof(Config.FogColor) == "Color3" then
        atmosphere.Color = Color3.new(Config.FogColor.R, Config.FogColor.G, Config.FogColor.B)
    end
    if typeof(Config.FogDecay) == "Color3" then
        atmosphere.Decay = Color3.new(Config.FogDecay.R, Config.FogDecay.G, Config.FogDecay.B)
    end
    return atmosphere
end

local function restoreFog()
    -- If weather still owns the environment, hand atmosphere back to weather.
    if weatherOwnsEnvironment() then
        local weather = env.Weather
        if weather and weather.Reapply then
            pcall(weather.Reapply)
        end
        return
    end
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    local fog = Original.Fog
    if atmosphere and fog then
        atmosphere.Density, atmosphere.Offset = fog.Density, fog.Offset
        atmosphere.Color, atmosphere.Decay = fog.Color, fog.Decay
        atmosphere.Haze, atmosphere.Glare = fog.Haze, fog.Glare
    end
end
local function restoreGrade()
    if Grade then
        Grade.Enabled = false
        Grade.Saturation, Grade.Contrast, Grade.Brightness = 0, 0, 0
        Grade.TintColor = Color3.new(1, 1, 1)
    end
end
local function restoreBloom()
    if BloomEffect then
        BloomEffect.Enabled = false
    end
end
local function restoreDoF()
    if DoFEffect then
        DoFEffect.Enabled = false
    end
end
local function restoreSkybox()
    if SkyInstance then
        SkyInstance:Destroy()
        SkyInstance = nil
    end
end

local function yieldToWeather()
    return weatherOwnsEnvironment()
end

local forceWorldColors
local worldColorToken = 0
local function scheduleWorldColors()
    worldColorToken += 1
    local token = worldColorToken
    task.delay(0.5, function()
        if token ~= worldColorToken then
            return
        end
        forceWorldColors()
    end)
end

local function applyAmbience()
    if yieldToWeather() then
        return
    end
    if not Config.Ambience then return restoreAmbience() end
    forceWorldColors()
    scheduleWorldColors()
end
local function applyClock()
    if yieldToWeather() then
        return
    end
    if not Config.Clock then return restoreClock() end
    Lighting.ClockTime = Config.ClockTime
end
local function applyLighting()
    if yieldToWeather() then
        return
    end
    if not Config.Lighting then return restoreLighting() end
    Lighting.Brightness = Config.Brightness
    if not Config.DynamicExposure then
        Lighting.ExposureCompensation = Config.ExposureCompensation
    end
    if not Config.Ambience then
        scheduleWorldColors()
    end
end
local function applyFog()
    -- Atmosphere always wins over weather/game when enabled.
    if not Config.Fog then
        return restoreFog()
    end
    writeAtmosphereFromConfig()
    if not yieldToWeather() then
        forceWorldColors()
        scheduleWorldColors()
    end
end
local function applyGrade()
    local grade = ensureGrade()
    grade.Enabled = Config.ColorCorrection == true
    if not Config.ColorCorrection then return restoreGrade() end
    grade.Saturation = Config.Saturation
    grade.Contrast = Config.Contrast
    grade.Brightness = Config.CorrectionBrightness
    if typeof(Config.TintColor) == "Color3" then
        grade.TintColor = Color3.new(Config.TintColor.R, Config.TintColor.G, Config.TintColor.B)
    end
end

local function ensureBloom()
    if BloomEffect and BloomEffect.Parent then return BloomEffect end
    BloomEffect = Instance.new("BloomEffect")
    BloomEffect.Name = "TapologyBloom"
    BloomEffect.Enabled = false
    BloomEffect.Parent = Lighting
    table.insert(Created, BloomEffect)
    return BloomEffect
end

local function applyBloom()
    local bloom = ensureBloom()
    bloom.Enabled = Config.Bloom == true
    if not Config.Bloom then return restoreBloom() end
    bloom.Intensity = Config.BloomIntensity
    bloom.Size = Config.BloomSize
    bloom.Threshold = Config.BloomThreshold
end

local function ensureDoF()
    if DoFEffect and DoFEffect.Parent then return DoFEffect end
    DoFEffect = Instance.new("DepthOfFieldEffect")
    DoFEffect.Name = "TapologyDoF"
    DoFEffect.Enabled = false
    DoFEffect.Parent = Lighting
    table.insert(Created, DoFEffect)
    return DoFEffect
end

local function applyDoF()
    local dof = ensureDoF()
    dof.Enabled = Config.DepthOfField
    if not Config.DepthOfField then return restoreDoF() end
    dof.FarIntensity = Config.DoFFarIntensity
    dof.NearIntensity = Config.DoFNearIntensity
    dof.FocusDistance = Config.DoFFocusDistance
    dof.InFocusRadius = Config.DoFInFocusRadius
end

local function applySkybox()
    if not Config.Skybox then
        return restoreSkybox()
    end
    local preset = Config.Skyboxes[Config.SkyboxId]
    if not preset then
        return
    end
    if not SkyInstance or not SkyInstance.Parent then
        SkyInstance = Instance.new("Sky")
        SkyInstance.Name = "TapologySky"
        SkyInstance.Parent = Lighting
        table.insert(Created, SkyInstance)
    end
    for key, value in preset do
        pcall(function()
            SkyInstance[key] = value
        end)
    end
end

local function dynamicTarget()
    local hour = Lighting.ClockTime
    local night = hour < 6 or hour > 19
    local dusk = (hour >= 6 and hour < 8) or (hour > 17 and hour <= 19)
    local lo = tonumber(Config.DynamicExposureMin) or -0.4
    local hi = tonumber(Config.DynamicExposureMax) or 0.8
    if lo > hi then
        lo, hi = hi, lo
    end
    local base = night and hi or (dusk and hi * 0.45 or lo)
    local outdoor = (Config.Ambience and Config.OutdoorAmbient or Lighting.OutdoorAmbient)
    local luma = outdoor.R * 0.3 + outdoor.G * 0.59 + outdoor.B * 0.11
    return math.clamp(base + (0.5 - luma) * 0.6, lo, hi)
end

local function applyAll()
    applyAmbience()
    applyClock()
    applyFog()
    applyLighting()
    applyGrade()
    applyBloom()
    applyDoF()
    applySkybox()
end

local function copyColor(color, fallback)
    if typeof(color) == "Color3" then
        return Color3.new(color.R, color.G, color.B)
    end
    return fallback
end

local function applyCelestial()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        return
    end
    if Original.SunAngularSize == nil then
        Original.SunAngularSize = sky.SunAngularSize
        Original.MoonAngularSize = sky.MoonAngularSize
        Original.StarCount = sky.StarCount
    end
    if Config.RemoveSun then
        sky.SunAngularSize = 0
    elseif Config.Sun then
        sky.SunAngularSize = math.clamp(tonumber(Config.SunSize) or 21, 0, 90)
        Lighting.Brightness = tonumber(Config.SunBrightness) or Lighting.Brightness
    else
        sky.SunAngularSize = Original.SunAngularSize
    end
    sky.MoonAngularSize = Config.RemoveMoon and 0 or Original.MoonAngularSize
    sky.StarCount = Config.RemoveStars and 0 or Original.StarCount
end

local function applyIndependentWorld()
    applyGrade()
    applyBloom()
    applyDoF()
    applySkybox()
    applyCelestial()
end

local function forceApplyWorld()
    if not yieldToWeather() then
        applyAmbience()
        applyClock()
        applyLighting()
    end
    applyFog()
    applyIndependentWorld()
end

forceWorldColors = function()
    if Config.Fog then
        writeAtmosphereFromConfig()
    end
    if yieldToWeather() then
        return
    end
    if Config.Ambience or Config.Lighting then
        if typeof(Config.Ambient) == "Color3" then
            Lighting.Ambient = Color3.new(Config.Ambient.R, Config.Ambient.G, Config.Ambient.B)
        end
        if typeof(Config.OutdoorAmbient) == "Color3" then
            Lighting.OutdoorAmbient = Color3.new(Config.OutdoorAmbient.R, Config.OutdoorAmbient.G, Config.OutdoorAmbient.B)
        end
    end
    if Config.ColorCorrection then
        local grade = ensureGrade()
        grade.Enabled = true
        if typeof(Config.TintColor) == "Color3" then
            grade.TintColor = Color3.new(Config.TintColor.R, Config.TintColor.G, Config.TintColor.B)
        end
    else
        restoreGrade()
    end
end

capture()
ensureGrade()

local function findModules()
    if not getgc or (getactors and #getactors() > 0) then
        return nil
    end
    for _, value in getgc(true) do
        if type(value) == "table" and rawget(value, "ScreenCull") and rawget(value, "NetworkClient") then
            local modules = {}
            for name, data in value do
                modules[name] = type(data) == "table" and data.module ~= nil and data.module or data
            end
            return modules
        end
    end
end

local function pinWeatherEnvironment()
    local weather = env.Weather
    if not weather then
        return false
    end

    if weather.Reapply then
        pcall(weather.Reapply)
        return weatherActive()
    end
    return weatherActive()
end

local function reapplyAfterSpawn()
    task.spawn(function()
        task.wait(0.05)
        local weatherOn = pinWeatherEnvironment()

        if weatherOn then
            yieldToWeather()
            applyFog()
            task.wait(0.35)
            pinWeatherEnvironment()
            yieldToWeather()
            applyFog()
            return
        end
        task.wait(0.12)
        forceApplyWorld()
        task.wait(0.35)
        forceApplyWorld()
        task.wait(1.25)
        forceApplyWorld()
    end)
end

do
    local okModules, modules = pcall(findModules)
    modules = okModules and modules or nil
    local ce = modules and modules.CharacterEvents
    if ce and ce.onSpawned and (ce.onSpawned.connect or ce.onSpawned.Connect) then
        local connect = ce.onSpawned.connect or ce.onSpawned.Connect
        table.insert(Connections, connect(ce.onSpawned, reapplyAfterSpawn))
    end
    local pse = modules and modules.PlayerStatusEvents
    if pse and pse.onPlayerSpawned and (pse.onPlayerSpawned.connect or pse.onPlayerSpawned.Connect) then
        local connect = pse.onPlayerSpawned.connect or pse.onPlayerSpawned.Connect
        local Players = game:GetService("Players")
        local localPlayer = Players.LocalPlayer
        table.insert(Connections, connect(pse.onPlayerSpawned, function(player)
            if player == localPlayer then
                reapplyAfterSpawn()
            end
        end))
    end
end

local PlayersSvc = game:GetService("Players")
local localPlayer = PlayersSvc.LocalPlayer
if localPlayer then
    table.insert(Connections, localPlayer.CharacterAdded:Connect(function()
        reapplyAfterSpawn()
    end))
    if localPlayer.Character then
        reapplyAfterSpawn()
    else
        task.defer(forceApplyWorld)
    end
else
    task.defer(forceApplyWorld)
end

local lastWorldForce = 0
local lastFogPin = 0
table.insert(Connections, RunService.Heartbeat:Connect(function()
    local now = os.clock()
    -- Keep world atmosphere pinned over weather/game every tick while enabled.
    if Config.Fog and now - lastFogPin >= 0.05 then
        lastFogPin = now
        writeAtmosphereFromConfig()
    end
    if weatherOwnsEnvironment() then
        if now - lastWorldForce >= 2 then
            lastWorldForce = now
            pinWeatherEnvironment()
            yieldToWeather()
            if Config.Fog then
                writeAtmosphereFromConfig()
            end
        end
        return
    end
    if now - lastWorldForce >= 2 then
        lastWorldForce = now
        forceApplyWorld()
        forceWorldColors()
    end
end))

local savedWorldMaterials = {}
local worldQueue = {}
local worldIndex = 1
local worldListedAt = 0
local function worldMaterialEnum()
    local name = Config.WorldMaterial or "SmoothPlastic"
    local ok, mat = pcall(function()
        return Enum.Material[name]
    end)
    return ok and mat or Enum.Material.SmoothPlastic
end
table.insert(Connections, RunService.Heartbeat:Connect(function()
    if Config.WorldTexture then
        local now = os.clock()
        if now - worldListedAt > 4 or worldIndex > #worldQueue then
            worldQueue = {}
            for _, rootName in { "Map", "Terrain", "Ignore" } do
                local root = workspace:FindFirstChild(rootName)
                if root then
                    for _, inst in root:GetDescendants() do
                        table.insert(worldQueue, inst)
                    end
                end
            end
            if #worldQueue == 0 then
                for _, inst in workspace:GetChildren() do
                    table.insert(worldQueue, inst)
                end
            end
            worldIndex = 1
            worldListedAt = now
        end
        local mat = worldMaterialEnum()
        local changed = 0
        while worldIndex <= #worldQueue and changed < 20 do
            local inst = worldQueue[worldIndex]
            worldIndex += 1
            if typeof(inst) == "Instance" and inst:IsA("BasePart") and inst.Parent then
                local model = inst:FindFirstAncestorOfClass("Model")
                if not (model and model:FindFirstChildOfClass("Humanoid")) then
                    if savedWorldMaterials[inst] == nil then
                        savedWorldMaterials[inst] = inst.Material
                    end
                    inst.Material = mat
                    changed += 1
                end
            end
        end
    elseif next(savedWorldMaterials) then
        local restored = 0
        for inst, mat in savedWorldMaterials do
            savedWorldMaterials[inst] = nil
            if typeof(inst) == "Instance" and inst.Parent and typeof(mat) == "EnumItem" then
                inst.Material = mat
            end
            restored += 1
            if restored >= 40 then
                break
            end
        end
    end
end))

local lastDynamicTick = 0
table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
    if weatherOwnsEnvironment() then
        return
    end
    if not Config.DynamicExposure then
        if DynamicValue ~= 0 then
            DynamicValue = 0
            if Config.Lighting then
                Lighting.ExposureCompensation = Config.ExposureCompensation
            else
                Lighting.ExposureCompensation = Original.ExposureCompensation
            end
        end
        return
    end
    local now = os.clock()
    if now - lastDynamicTick < 1 / 30 then
        return
    end
    local elapsed = now - lastDynamicTick
    lastDynamicTick = now
    local target = dynamicTarget() + (Config.ColorCorrection and Config.Exposure or 0)
    DynamicValue += (target - DynamicValue) * math.clamp(elapsed * Config.DynamicExposureSpeed, 0, 1)
    Lighting.ExposureCompensation = DynamicValue
end))

env.World = {
    Config = Config,
    Apply = applyAll,
    Reapply = forceApplyWorld,
    ForceApply = forceApplyWorld,
    SetEnabled = function(feature, on)
        Config[feature] = on and true or false
        if feature == "Ambience" then
            applyAmbience()
        elseif feature == "Clock" then
            applyClock()
        elseif feature == "Fog" then
            applyFog()
        elseif feature == "Lighting" then
            applyLighting()
        elseif feature == "ColorCorrection" then
            applyGrade()
        elseif feature == "Bloom" then
            applyBloom()
        elseif feature == "DepthOfField" then
            applyDoF()
        elseif feature == "Skybox" then
            applySkybox()
        elseif feature == "DynamicExposure" and not on then
            DynamicValue = 0
            applyLighting()
        end
    end,
    Set = function(key, value)
        Config[key] = value
        if key == "Ambient" or key == "OutdoorAmbient" then
            applyAmbience()
        elseif key == "ClockTime" then
            applyClock()
        elseif key == "Brightness" or key == "ExposureCompensation" then
            applyLighting()
        elseif key == "FogDensity" or key == "FogOffset" or key == "FogColor" or key == "FogDecay" or key == "FogHaze" or key == "FogGlare" then
            applyFog()
        elseif key == "Saturation" or key == "Contrast" or key == "CorrectionBrightness" or key == "TintColor" then
            applyGrade()
        elseif key == "BloomIntensity" or key == "BloomSize" or key == "BloomThreshold" then
            applyBloom()
        elseif key == "DoFFarIntensity" or key == "DoFNearIntensity" or key == "DoFFocusDistance" or key == "DoFInFocusRadius" then
            applyDoF()
        elseif key == "SkyboxId" then
            applySkybox()
        end
    end,
    SetColor = function(slot, color)
        Config[slot] = color
        if slot == "Ambient" or slot == "OutdoorAmbient" then
            if Config.Ambience or Config.Lighting then
                forceWorldColors()
            end
        elseif slot == "FogColor" or slot == "FogDecay" then
            if Config.Fog then
                forceWorldColors()
            end
        elseif slot == "TintColor" then
            if Config.ColorCorrection then
                forceWorldColors()
            end
        end
    end,
    Unload = function()
        worldColorToken += 1
        for _, connection in Connections do
            pcall(function()
                if connection.Disconnect then
                    connection:Disconnect()
                elseif connection.disconnect then
                    connection:disconnect()
                end
            end)
        end
        table.clear(Connections)
        restoreAmbience()
        restoreClock()
        restoreFog()
        restoreLighting()
        restoreGrade()
        restoreBloom()
        restoreDoF()
        restoreSkybox()
        Lighting.ExposureCompensation = Original.ExposureCompensation
        for _, instance in Created do
            instance:Destroy()
        end
        table.clear(Created)
        env.World = nil
    end,
}

end
do

-- Rage is provided by modules/rage.lua (loaded later).
end
do

local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local SoundService = cloneref(game:GetService("SoundService"))

local Config = {
    MovementBypass = false,
    WalkSpeed = false,
    SetSpeed = 50,
    JumpPower = false,
    HeightAddition = 10,
    NoFallDamage = false,
    BunnyHop = false,
    OnlyWhileJumping = false,
    SlideBoost = false,
    SlideBoostSpeed = 70,
    NoStamina = false,
    NoMoveCooldown = false,
    HeightBypass = false,
    HeightBypassTime = 1.5,
    MoveSmooth = 12,
    Crosshair = false,
    CrosshairMode = "onscreen",
    CrosshairThickness = 2,
    CrosshairGap = 4,
    CrosshairLength = 8,
    CrosshairBounce = 0,
    CrosshairBounceSpeed = 6,
    CrosshairSpin = 0,
    CrosshairSpinSpeed = 90,
    CrosshairFadeIn = 0,
    CrosshairFadeOut = 0,
    CrosshairOutline = false,
    CrosshairOutlineColor = Color3.fromRGB(0, 0, 0),
    CrosshairColor1 = Color3.fromRGB(255, 255, 255),
    CrosshairColor2 = Color3.fromRGB(255, 255, 255),
    CrosshairColor3 = Color3.fromRGB(255, 255, 255),
    CrosshairColor4 = Color3.fromRGB(255, 255, 255),

    HitMarkers = false,
    HitMarkerModes = { ["2d"] = true, ["3d"] = false },
    HitMarkerGap = 4,
    HitMarkerThickness = 2,
    HitMarkerLength = 10,
    HitMarkerDuration = 0.35,
    HitMarkerFadeIn = 0,
    HitMarkerFadeOut = 0,
    HitMarkerOutline = false,
    HitMarkerOutlineColor = Color3.fromRGB(0, 0, 0),
    HitMarkerColor1 = Color3.fromRGB(255, 255, 255),
    HitMarkerColor2 = Color3.fromRGB(255, 255, 255),
    HitMarkerColor3 = Color3.fromRGB(255, 255, 255),
    HitMarkerColor4 = Color3.fromRGB(255, 255, 255),
    HitMarkerAlpha1 = 1,
    HitMarkerAlpha2 = 1,
    HitMarkerAlpha3 = 1,
    HitMarkerAlpha4 = 1,
    RecoilControl = false,
    RecoilScale = 0.55,
    Removals = false,
    RemoveItems = {},
    RemoveHud = {},
    RemoveDecals = false,
    RemoveArms = false,
    RemoveAnimations = false,
    RemoveTeam = false,
    RemoveEnemy = false,
    RemoveExplosions = false,
    RemoveDroppedGuns = false,
    CustomSound = "",

    ThirdPerson = false,
    ShowCharacter = true,
    ShowCharacterWhileAiming = false,
    HideViewmodel = false,
    ApplyAntiAimToCharacter = false,
    ThirdPersonWeapon = true,
    ThirdPersonClip = true,
    ThirdPersonMinimum = 3,
    ThirdPersonMaximum = 8,
    CameraOffsetX = 0,
    CameraOffsetY = 0,
    CameraOffsetZ = 8,
    CameraOffsetAlwaysVisible = true,
    CameraSmooth = false,
    CameraSmoothness = 20,

    FOV = false,
    FOVAmount = 90,
    AspectRatio = false,
    Aspect = 1.6,

    Viewmodel = false,
    ViewmodelX = 0,
    ViewmodelY = 0,
    ViewmodelZ = 0,

    ArmsChams = false,
    ArmsChamsColor = Color3.fromRGB(108, 147, 255),
    ArmsChamsMaterial = "ForceField",
    ArmsChamsAlpha = 0,

    BodyChams = false,
    BodyChamsColor = Color3.fromRGB(255, 190, 150),
    BodyChamsMaterial = "ForceField",
    BodyChamsAlpha = 0,

    WeaponChams = false,
    WeaponChamsColor = Color3.fromRGB(108, 147, 255),
    WeaponChamsMaterial = "ForceField",
    WeaponChamsAlpha = 0,

    Auras = {},
    AuraColors = {
        highlight = Color3.fromRGB(108, 147, 255),
        glow = Color3.fromRGB(108, 147, 255),
        sparkles = Color3.fromRGB(255, 255, 255),
        energy = Color3.fromRGB(120, 200, 255),
        trail = Color3.fromRGB(255, 120, 200),
    },

    ShootSounds = false,
    MuteGameShootSounds = true,
    ShootSound = "Impact",
    ShootSoundVolume = 1.5,
    ShootSoundPitch = 1,
    ShootSoundIds = {
        Impact = "rbxassetid://9113500510",
        Gamesense = "rbxassetid://4817809188",
        Click = "rbxassetid://12222208",
        Hitmarker = "rbxassetid://705502934",
        Ping = "rbxasset://sounds/electronicpingshort.mp3",
        Switch = "rbxasset://sounds/switch.mp3",
        Soft = "rbxassetid://6895079853",
        Pop = "rbxassetid://4817809188",
        Clean = "rbxasset://sounds/electronicpingshort.mp3",
        Snap = "rbxassetid://12222208",
    },
}

local env = getgenv and getgenv() or _G
if env.Misc then
    env.Misc.Unload()
end

do
    if type(Config.RemoveHud) == "string" then
        local value = Config.RemoveHud
        Config.RemoveHud = {}
        if value == "all" or value == "chat" then
            Config.RemoveHud.chat = true
        end
        if value == "all" or value == "killfeed" then
            Config.RemoveHud.killfeed = true
        end
    elseif type(Config.RemoveHud) ~= "table" then
        Config.RemoveHud = {}
    end
    if type(Config.RemoveItems) ~= "table" then
        Config.RemoveItems = {}
    end
    if not next(Config.RemoveItems) then
        Config.RemoveItems.decals = nil
        if Config.RemoveArms then Config.RemoveItems.arms = true end
        if Config.RemoveAnimations then Config.RemoveItems.animations = true end
        if Config.RemoveTeam then Config.RemoveItems.team = true end
        if Config.RemoveEnemy then Config.RemoveItems.enemy = true end
        if Config.RemoveExplosions then Config.RemoveItems.explosions = true end
        if Config.RemoveDroppedGuns then Config.RemoveItems.dropped = true end
    end
end

local function removalOn(name)
    return Config.Removals == true and type(Config.RemoveItems) == "table" and Config.RemoveItems[name] == true
end

local function hudOn(name)
    return Config.Removals == true and type(Config.RemoveHud) == "table" and Config.RemoveHud[name] == true
end

local function syncRemovalFlags()
    Config.RemoveDecals = false
    Config.RemoveArms = removalOn("arms")
    Config.RemoveAnimations = removalOn("animations")
    Config.RemoveTeam = removalOn("team")
    Config.RemoveEnemy = removalOn("enemy")
    Config.RemoveExplosions = removalOn("explosions")
    Config.RemoveDroppedGuns = removalOn("dropped")
end
syncRemovalFlags()

local LocalPlayer = Players.LocalPlayer
local PhantomForces = game.PlaceId == 292439477 or game.PlaceId == 299659045
local Connections = {}
local Restores = {}
local BoundSteps = {}

local Modules
local function findModules()
    if not getgc or (getactors and #getactors() > 0) then return end
    for _, value in getgc(true) do
        if type(value) == "table" and rawget(value, "ScreenCull") and rawget(value, "NetworkClient") then
            local modules = {}
            for name, data in value do
                modules[name] = type(data) == "table" and data.module ~= nil and data.module or data
            end
            return modules
        end
    end
end
if PhantomForces then
    local ok, found = pcall(findModules)
    Modules = ok and found or nil
end

local function camera()
    return workspace.CurrentCamera
end

local function bindStep(name, priority, fn)
    pcall(RunService.UnbindFromRenderStep, RunService, name)
    RunService:BindToRenderStep(name, priority, fn)
    table.insert(BoundSteps, name)
end

local camRayParams = RaycastParams.new()
camRayParams.FilterType = Enum.RaycastFilterType.Exclude
camRayParams.IgnoreWater = true
local camRayIgnore = table.create(4)
local camRayIgnoreAt = 0
local function refreshCamRayIgnore(force, extra)
    local now = os.clock()
    if not force and now - camRayIgnoreAt < 0.75 and extra == nil then
        return
    end
    camRayIgnoreAt = now
    table.clear(camRayIgnore)
    local camInst = workspace.CurrentCamera
    if camInst then
        camRayIgnore[#camRayIgnore + 1] = camInst
    end
    local character = LocalPlayer.Character
    if character then
        camRayIgnore[#camRayIgnore + 1] = character
    end
    local playersFolder = workspace:FindFirstChild("Players")
    if playersFolder then
        camRayIgnore[#camRayIgnore + 1] = playersFolder
    end
    local ignoreFolder = workspace:FindFirstChild("Ignore")
    if ignoreFolder then
        camRayIgnore[#camRayIgnore + 1] = ignoreFolder
    end
    if typeof(extra) == "Instance" then
        camRayIgnore[#camRayIgnore + 1] = extra
    end
    camRayParams.FilterDescendantsInstances = camRayIgnore
end
refreshCamRayIgnore(true)
local function raycastCamera(origin, direction, extra)
    refreshCamRayIgnore(true, extra)
    return workspace:Raycast(origin, direction, camRayParams)
end

if Modules then
    local network = Modules.NetworkClient
    local charObject = Modules.CharacterObject
    local charInterface = Modules.CharacterInterface
    local weapons = Modules.WeaponControllerInterface
    local cameraObject = Modules.MainCameraObject
    local cameraInterface = Modules.CameraInterface
    local thirdPersonObject = Modules.ThirdPersonObject
    local replicationObject = Modules.ReplicationObject
    local playerDataIface = Modules.PlayerDataClientInterface

    local smoothOffset = Vector3.new(Config.CameraOffsetX, Config.CameraOffsetY, Config.CameraOffsetZ)
    local smoothCamPos = nil
    local lastCamClock = os.clock()
    local lastOffsetX, lastOffsetY, lastOffsetZ = Config.CameraOffsetX, Config.CameraOffsetY, Config.CameraOffsetZ
    local targetOffset = smoothOffset
    local lastRayDesired = nil
    local lastRayClock = 0
    local RAY_HZ = 1 / 36

    local fakeRepObject
    local currentObj
    local startedShow = false
    local lastShowPos
    local showDelta = 0
    local setCharacterRender

    local characterConfig
    local savedMoveCooldowns = {}
    local moveCooldownPatched = false
    local function findCharacterConfig()
        if characterConfig then
            return characterConfig
        end
        if not getgc then
            return nil
        end
        for _, value in getgc(true) do
            if type(value) == "table" and type(rawget(value, "casualMovementConfig")) == "table" then
                local normal = value.casualMovementConfig.normal
                if type(normal) == "table" and normal.slideCooldown ~= nil then
                    characterConfig = value
                    return characterConfig
                end
            end
        end
        return nil
    end
    local cooldownKeys = { "jumpCooldown", "maxJumpCooldown", "slideCooldown", "slidePreCooldown" }
    local function setMoveCooldowns(on)
        local cfg = findCharacterConfig()
        if not cfg then
            return
        end
        for _, bucketName in { "casualMovementConfig", "adrenalineMovementConfig" } do
            local bucket = cfg[bucketName]
            if type(bucket) == "table" then
                for _, stanceName in { "normal", "stamina" } do
                    local stance = bucket[stanceName]
                    if type(stance) == "table" then
                        local id = bucketName .. "/" .. stanceName
                        local saved = savedMoveCooldowns[id]
                        if not saved then
                            saved = {}
                            savedMoveCooldowns[id] = saved
                            for _, key in cooldownKeys do
                                if stance[key] ~= nil then
                                    saved[key] = stance[key]
                                end
                            end
                        end
                        for _, key in cooldownKeys do
                            if saved[key] ~= nil then
                                stance[key] = on and 0 or saved[key]
                            end
                        end
                    end
                end
            end
        end
        moveCooldownPatched = on and true or false
    end
    table.insert(Restores, function()
        if moveCooldownPatched then
            setMoveCooldowns(false)
        end
    end)

    if network and type(network.send) == "function" then
        local send = network.send
        network.send = function(self, name, ...)
            if name == "falldamage" and Config.NoFallDamage then
                return
            end
            if Config.ThirdPerson and Config.ShowCharacter and currentObj and fakeRepObject then
                if name == "equip" then
                    local slot = ...
                    pcall(function()
                        fakeRepObject:setActiveIndex(slot)
                        if slot ~= 3 then
                            currentObj:equip(slot)
                        else
                            currentObj:equipMelee()
                        end
                    end)
                elseif name == "aim" then
                    local aiming = ...
                    pcall(currentObj.setAim, currentObj, aiming)
                elseif name == "sprint" then
                    local sprinting = ...
                    pcall(currentObj.setSprint, currentObj, sprinting)
                elseif name == "stance" then
                    local stance = ...
                    pcall(currentObj.setStance, currentObj, stance)
                elseif name == "stab" then
                    pcall(currentObj.stab, currentObj)
                end
            end
            return send(self, name, ...)
        end
        table.insert(Restores, function()
            network.send = send
        end)
    end

    if charObject and type(charObject.setBaseWalkSpeed) == "function" then
        local setBaseWalkSpeed = charObject.setBaseWalkSpeed
        charObject.setBaseWalkSpeed = function(self, speed)
            if Config.WalkSpeed then
                local wanted = math.clamp(tonumber(Config.SetSpeed) or 50, 1, 200)
                if Config.SlideBoost and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    wanted = math.clamp(wanted + (tonumber(Config.SlideBoostSpeed) or 70), 1, 200)
                end
                return setBaseWalkSpeed(self, wanted)
            end
            return setBaseWalkSpeed(self, speed)
        end
        table.insert(Restores, function()
            charObject.setBaseWalkSpeed = setBaseWalkSpeed
        end)
    end
    if charObject and type(charObject.updateWalkSpeed) == "function" then
        local updateWalkSpeed = charObject.updateWalkSpeed
        charObject.updateWalkSpeed = function(self, ...)
            local result = updateWalkSpeed(self, ...)
            if Config.WalkSpeed then
                local speed = math.clamp(tonumber(Config.SetSpeed) or 50, 1, 200)
                if Config.SlideBoost and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    speed = math.clamp(speed + (tonumber(Config.SlideBoostSpeed) or 70), 1, 200)
                end
                if self._baseWalkSpeed ~= speed then
                    pcall(function()
                        self._baseWalkSpeed = speed
                        if type(self.setBaseWalkSpeed) == "function" then
                            self:setBaseWalkSpeed(speed)
                        end
                    end)
                end
            end
            return result
        end
        table.insert(Restores, function()
            charObject.updateWalkSpeed = updateWalkSpeed
        end)
    end

    if charObject and type(charObject.canJump) == "function" then
        local canJump = charObject.canJump
        charObject.canJump = function(self, ...)
            if Config.NoMoveCooldown then
                return true
            end
            return canJump(self, ...)
        end
        table.insert(Restores, function()
            charObject.canJump = canJump
        end)
    end

    if charObject and type(charObject.jump) == "function" then
        local jump = charObject.jump
        charObject.jump = function(self, height, vaulting)
            if not Config.JumpPower then
                return jump(self, height, vaulting)
            end
            local add = math.clamp(tonumber(Config.HeightAddition) or 0, 0, 30)
            local result = jump(self, (height or 4) + add, vaulting)
            if add > 0 then
                pcall(function()
                    local root = self.getRealRootPart and self:getRealRootPart() or self.getRootPart and self:getRootPart() or self._rootPart
                    if typeof(root) == "Instance" and root:IsA("BasePart") then
                        local vel = root.AssemblyLinearVelocity
                        local boost = 12 + add * 2.2
                        if vel.Y < boost then
                            root.AssemblyLinearVelocity = Vector3.new(vel.X, boost, vel.Z)
                        end
                    end
                    if self._velocity and typeof(self._velocity) == "Vector3" then
                        local vel = self._velocity
                        local boost = 12 + add * 2.2
                        if vel.Y < boost then
                            self._velocity = Vector3.new(vel.X, boost, vel.Z)
                        end
                    end
                end)
            end
            return result
        end
        table.insert(Restores, function()
            charObject.jump = jump
        end)
    end

    if cameraObject and type(cameraObject.getBaseFov) == "function" then
        local getBaseFov = cameraObject.getBaseFov
        cameraObject.getBaseFov = function(self, ...)
            local base = getBaseFov(self, ...)
            if Config.FOV then
                return math.clamp(tonumber(Config.FOVAmount) or 90, 40, 135)
            end
            return base
        end
        table.insert(Restores, function()
            cameraObject.getBaseFov = getBaseFov
        end)
    end

    -- Constant-exact third person: offset CurrentCamera.CFrame on __newindex only.
    -- Clip raycasts are throttled (~20Hz) so camera writes don't tank FPS.
    do
        local tpParam = RaycastParams.new()
        tpParam.FilterType = Enum.RaycastFilterType.Include
        tpParam.IgnoreWater = true
        local map = workspace:FindFirstChild("Map")
        if map then
            tpParam.FilterDescendantsInstances = { map }
        end
        local cachedDist = math.clamp(tonumber(Config.ThirdPersonMaximum) or 8, 1, 20)
        local cachedCan = false
        local lastRayAt = 0
        local lastAliveAt = 0
        local cachedAlive = false
        local hookMeta = hookmetamethod or hook_metamethod
        local checkCaller = checkcaller or function()
            return false
        end
        if type(hookMeta) == "function" then
            local currentCamera = workspace.CurrentCamera
            local newIndex
            newIndex = hookMeta(currentCamera, "__newindex", function(self, property, value)
                if not checkCaller() and self == workspace.CurrentCamera and property == "CFrame" and typeof(value) == "CFrame" then
                    if not Config.ThirdPerson then
                        Config._InThirdPerson = false
                        return newIndex(self, property, value)
                    end
                    local now = os.clock()
                    if now - lastAliveAt > 0.1 then
                        lastAliveAt = now
                        cachedAlive = false
                        pcall(function()
                            cachedAlive = charInterface and charInterface.isAlive and charInterface.isAlive()
                        end)
                        if not cachedAlive then
                            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                            cachedAlive = hum and hum.Health > 0
                        end
                    end
                    local canThirdPerson = false
                    if cachedAlive then
                        local maxDist = math.clamp(tonumber(Config.ThirdPersonMaximum) or 8, 1, 20)
                        local minDist = math.clamp(tonumber(Config.ThirdPersonMinimum) or 3, 1, 10)
                        if Config.ThirdPersonClip then
                            if now - lastRayAt >= 0.05 then
                                lastRayAt = now
                                if not tpParam.FilterDescendantsInstances or #tpParam.FilterDescendantsInstances == 0 then
                                    local mapFolder = workspace:FindFirstChild("Map")
                                    if mapFolder then
                                        tpParam.FilterDescendantsInstances = { mapFolder }
                                    end
                                end
                                local result = workspace:Raycast(value.Position, -value.LookVector * maxDist, tpParam)
                                if not result or not result.Instance.CanCollide or result.Instance.Transparency == 1 then
                                    cachedDist = maxDist
                                    cachedCan = true
                                else
                                    local magnitude = (result.Position - value.Position).Magnitude
                                    cachedCan = magnitude >= minDist
                                    cachedDist = cachedCan and magnitude or 0
                                end
                            end
                            canThirdPerson = cachedCan
                            if canThirdPerson and cachedDist > 0 then
                                value = value * CFrame.new(0, 0, cachedDist)
                            end
                        else
                            value = value * CFrame.new(0, 0, maxDist)
                            canThirdPerson = true
                        end
                    end
                    Config._InThirdPerson = canThirdPerson
                end
                return newIndex(self, property, value)
            end)
            table.insert(Restores, function()
                pcall(function()
                    hookMeta(workspace.CurrentCamera, "__newindex", newIndex)
                end)
            end)
        end
    end

    if thirdPersonObject and type(thirdPersonObject.setCharacterRender) == "function" then
        setCharacterRender = thirdPersonObject.setCharacterRender
        thirdPersonObject.setCharacterRender = function(self, render)
            if Config.ThirdPerson then
                local cam = camera()
                local pos = self._replicationObject and self._replicationObject._receivedPosition
                if not pos and self.getRootPart then
                    local root = self:getRootPart()
                    pos = root and root.Position
                end
                local onScreen = cam and pos and cam:WorldToViewportPoint(pos).Z > 0
                return setCharacterRender(self, render or (self._player ~= LocalPlayer and onScreen))
            end
            return setCharacterRender(self, render)
        end
        table.insert(Restores, function()
            thirdPersonObject.setCharacterRender = setCharacterRender
        end)
    end

    local function destroyShowCharacter()
        if fakeRepObject then
            pcall(function()
                fakeRepObject:despawn()
            end)
        end
        if currentObj then
            pcall(function()
                currentObj:Destroy()
            end)
        end
        currentObj = nil
        lastShowPos = nil
        startedShow = false
    end

    local function ensureFakeRep()
        if fakeRepObject or not replicationObject or type(replicationObject.new) ~= "function" then
            return fakeRepObject ~= nil
        end
        local ok, obj = pcall(replicationObject.new, setmetatable({}, {
            __index = function(_, index)
                if index == "GetPropertyChangedSignal" then
                    return function(_, property)
                        return LocalPlayer:GetPropertyChangedSignal(property)
                    end
                end
                return LocalPlayer[index]
            end,
            __newindex = function(_, index, value)
                LocalPlayer[index] = value
            end,
        }))
        if ok then
            fakeRepObject = obj
        end
        return fakeRepObject ~= nil
    end

    local function spawnShowCharacter()
        if not ensureFakeRep() then
            return
        end
        local classData
        pcall(function()
            local data = playerDataIface and playerDataIface.getPlayerData and playerDataIface.getPlayerData()
            classData = data and data.settings and data.settings.classdata
            classData = classData and classData[classData.curclass]
        end)
        if not classData then
            return
        end
        pcall(function()
            fakeRepObject._player = LocalPlayer
            fakeRepObject:spawn(nil, classData)
            currentObj = fakeRepObject._thirdPersonObject
            fakeRepObject:setActiveIndex(1)
            if currentObj then
                for i = 1, 3 do
                    if fakeRepObject.getWeaponObjects and fakeRepObject:getWeaponObjects()[i] then
                        pcall(currentObj.buildWeapon, currentObj, i)
                    end
                end
                currentObj.canRenderWeapon = true
            end
        end)
    end

    local lastBhopJump = 0
    table.insert(Connections, RunService.Heartbeat:Connect(function()
        if not Config.BunnyHop then
            return
        end
        if Config.OnlyWhileJumping and not UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            return
        end
        local object = charInterface and charInterface.getCharacterObject and charInterface.getCharacterObject()
        if not (object and object.jump) then
            return
        end
        local grounded = object._humanoid and object._humanoid.FloorMaterial ~= Enum.Material.Air
        if object.isGrounded then
            local okG, onGround = pcall(object.isGrounded, object)
            if okG then
                grounded = onGround and true or false
            end
        end
        if not grounded then
            return
        end
        local now = os.clock()
        if now - lastBhopJump < 0.05 then
            return
        end
        if object.canJump then
            local okC, can = pcall(object.canJump, object)
            if okC and not can then
                return
            end
        end
        local height = 4 + (Config.JumpPower and Config.HeightAddition or 0)
        local speed = tonumber(object._speed) or 0
        if speed > 12 then
            height *= 1.05
        end
        local ok, result = pcall(object.jump, object, height, true)
        if ok and result == "jump" then
            lastBhopJump = now

            if object._velocity and typeof(object._velocity) == "Vector3" then
                local horiz = Vector3.new(object._velocity.X, 0, object._velocity.Z)
                if horiz.Magnitude > 1 then
                    pcall(function()
                        object._speed = math.max(object._speed or 0, horiz.Magnitude)
                    end)
                end
            end
        end
    end))

    local lastGroundSnap = 0
    local function rootPartOf(object)
        if not object then
            return nil
        end
        local ok, part = pcall(function()
            if object.getRealRootPart then
                return object:getRealRootPart()
            end
            if object.getRootPart then
                return object:getRootPart()
            end
            return object._rootPart
        end)
        if ok and typeof(part) == "Instance" and part:IsA("BasePart") then
            return part
        end
        return nil
    end
    local function targetMoveSpeed()
        local speed = math.clamp(tonumber(Config.SetSpeed) or 50, 1, 200)
        if Config.SlideBoost and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            speed = math.clamp(speed + (tonumber(Config.SlideBoostSpeed) or 70), 1, 200)
        end
        return speed
    end
    local lastWalkSpeedApplied = nil
    local function applyPfWalkSpeed(object)
        if not object then
            return
        end
        local speed = targetMoveSpeed()
        if lastWalkSpeedApplied == speed and tonumber(object._baseWalkSpeed) == speed then
            return
        end
        lastWalkSpeedApplied = speed
        pcall(function()
            object._baseWalkSpeed = speed
            object._walkSpeedMult = 1
            if type(object.setBaseWalkSpeed) == "function" then
                object:setBaseWalkSpeed(speed)
            end
        end)
    end
    local hiddenHud = {}
    local hiddenHudNodes = {}
    local hiddenDecals = {}
    local decalQueue = {}
    local decalIndex = 1
    local decalListedAt = 0
    local hiddenEnemies = {}
    local removalTick = 0
    local function hideModelVisuals(model)
        if typeof(model) ~= "Instance" then
            return
        end
        for _, desc in model:GetDescendants() do
            if desc:IsA("BasePart") or desc:IsA("Decal") or desc:IsA("Texture") then
                desc.LocalTransparencyModifier = 1
            end
        end
    end
    local function applyHudRemovals()
        local hideChat = hudOn("chat")
        local hideKillfeed = hudOn("killfeed")
        local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not playerGui then
            return
        end
        if hideChat or hideKillfeed then
            local chatGui = playerGui:FindFirstChild("ChatScreenGui")
            if hideChat and chatGui and chatGui:IsA("ScreenGui") then
                if hiddenHud[chatGui] == nil then
                    hiddenHud[chatGui] = chatGui.Enabled
                end
                chatGui.Enabled = false
            end
            local hudGui = playerGui:FindFirstChild("HudScreenGui")
            if hideKillfeed and hudGui then
                local main = hudGui:FindFirstChild("Main") or hudGui:FindFirstChild("Main", true)
                local killfeed = main and (main:FindFirstChild("DisplayKillfeed") or main:FindFirstChild("DisplayKillfeed", true))
                if killfeed and killfeed:IsA("GuiObject") then
                    if hiddenHudNodes[killfeed] == nil then
                        hiddenHudNodes[killfeed] = killfeed.Visible
                    end
                    killfeed.Visible = false
                end
            end
            for _, child in playerGui:GetChildren() do
                if child:IsA("ScreenGui") then
                    local lower = string.lower(child.Name)
                    local match = (hideChat and string.find(lower, "chat", 1, true) and child.Name ~= "ChatScreenGui")
                        or (hideKillfeed and (string.find(lower, "kill", 1, true) or string.find(lower, "feed", 1, true)))
                    if match then
                        if hiddenHud[child] == nil then
                            hiddenHud[child] = child.Enabled
                        end
                        child.Enabled = false
                    end
                end
            end
            pcall(function()
                local core = game:GetService("CoreGui")
                local exp = core:FindFirstChild("ExperienceChat")
                if hideChat and exp and exp:IsA("ScreenGui") then
                    if hiddenHud[exp] == nil then
                        hiddenHud[exp] = exp.Enabled
                    end
                    exp.Enabled = false
                end
            end)
        else
            if next(hiddenHud) then
                for gui, enabled in hiddenHud do
                    hiddenHud[gui] = nil
                    if typeof(gui) == "Instance" and gui.Parent then
                        gui.Enabled = enabled
                    end
                end
            end
            if next(hiddenHudNodes) then
                for node, visible in hiddenHudNodes do
                    hiddenHudNodes[node] = nil
                    if typeof(node) == "Instance" and node.Parent then
                        node.Visible = visible
                    end
                end
            end
        end
    end
    local function applyWorldRemovals(object)
        if next(hiddenDecals) then
            local restored = 0
            for inst, transparency in hiddenDecals do
                hiddenDecals[inst] = nil
                if typeof(inst) == "Instance" and inst.Parent then
                    inst.Transparency = transparency
                end
                restored += 1
                if restored >= 40 then
                    break
                end
            end
        end
        local nowTick = os.clock()
        if Config.RemoveAnimations and object and object._humanoid and nowTick - (rawget(object, "_tapologyAnimAt") or 0) >= 0.25 then
            rawset(object, "_tapologyAnimAt", nowTick)
            pcall(function()
                for _, track in object._humanoid:GetPlayingAnimationTracks() do
                    local name = string.lower(track.Name)
                    if string.find(name, "reload", 1, true) or string.find(name, "equip", 1, true) or string.find(name, "inspect", 1, true) or string.find(name, "sprint", 1, true) then
                        track:Stop(0)
                    end
                end
            end)
        end
        if nowTick - removalTick > 0.35 and (Config.RemoveEnemy or Config.RemoveTeam or Config.RemoveExplosions or Config.RemoveDroppedGuns) then
            removalTick = nowTick
            local folder = workspace:FindFirstChild("Players")
            if folder and (Config.RemoveEnemy or Config.RemoveTeam) then
                for _, player in Players:GetPlayers() do
                    if player ~= LocalPlayer then
                        local same = LocalPlayer.TeamColor and player.TeamColor == LocalPlayer.TeamColor
                        local hide = (Config.RemoveEnemy and not same) or (Config.RemoveTeam and same)
                        local model = folder:FindFirstChild(player.Name)
                        if hide and model then
                            for _, desc in model:GetDescendants() do
                                if desc:IsA("BasePart") and hiddenEnemies[desc] == nil then
                                    hiddenEnemies[desc] = desc.LocalTransparencyModifier
                                    desc.LocalTransparencyModifier = 1
                                end
                            end
                        end
                    end
                end
            end
            if Config.RemoveExplosions then
                local ignoreFolder = workspace:FindFirstChild("Ignore")
                if ignoreFolder then
                    for _, desc in ignoreFolder:GetChildren() do
                        local lower = string.lower(desc.Name)
                        if string.find(lower, "explosion", 1, true) or string.find(lower, "blast", 1, true) then
                            for _, effect in desc:GetDescendants() do
                                if effect:IsA("ParticleEmitter") or effect:IsA("Fire") or effect:IsA("Smoke") then
                                    effect.Enabled = false
                                end
                            end
                        end
                    end
                end
            end
            if Config.RemoveDroppedGuns then
                local ignoreFolder = workspace:FindFirstChild("Ignore")
                local dropped = ignoreFolder and ignoreFolder:FindFirstChild("Dropped")
                if dropped then
                    for _, desc in dropped:GetDescendants() do
                        if desc:IsA("BasePart") then
                            desc.LocalTransparencyModifier = 1
                        end
                    end
                end
            end
        elseif not Config.RemoveEnemy and not Config.RemoveTeam and next(hiddenEnemies) then
            for inst, modifier in hiddenEnemies do
                hiddenEnemies[inst] = nil
                if typeof(inst) == "Instance" and inst.Parent then
                    inst.LocalTransparencyModifier = modifier
                end
            end
        end
    end
    table.insert(Connections, RunService.Heartbeat:Connect(function()
        local object = charInterface and charInterface.getCharacterObject and charInterface.getCharacterObject()
        do
            local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
            local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
            local classify = env.Aim and env.Aim.Classify
            local className = type(classify) == "function" and classify(weapon) or nil
            if className then
                getgenv().TapologyWeaponClass = className
            end
        end
        if Config.NoStamina and object then
            pcall(function()
                if object._maxStamina ~= nil and object._stamina ~= nil then
                    object._stamina = object._maxStamina
                elseif object._stamina ~= nil then
                    object._stamina = 1
                end
                if object._sprintCooldown ~= nil then
                    object._sprintCooldown = 0
                end
            end)
        end
        if Config.NoMoveCooldown then
            if not moveCooldownPatched then
                setMoveCooldowns(true)
            end
            if object then
                pcall(function()
                    object._moveCooldown = 0
                    object._jumpCooldown = 0
                    object._nextJump = 0
                    object._lastJumpTime = 0
                    object._lastLandTime = 0
                    object.dived = false
                    object.sprintDisabled = false
                end)
            end
        elseif moveCooldownPatched then
            setMoveCooldowns(false)
        end
        if Config.WalkSpeed then
            applyPfWalkSpeed(object)
        else
            lastWalkSpeedApplied = nil
        end
        local root = rootPartOf(object)
        if Config.HeightBypass and root then
            local now = os.clock()
            local waitFor = math.clamp(tonumber(Config.HeightBypassTime) or 1.5, 0.2, 8)
            if now - lastGroundSnap >= waitFor then
                lastGroundSnap = now
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = { root, workspace.CurrentCamera }
                local hit = workspace:Raycast(root.Position, Vector3.new(0, -500, 0), params)
                if hit and (root.Position.Y - hit.Position.Y) > 18 then
                    local vel = root.AssemblyLinearVelocity
                    root.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3.5, 0)) * (root.CFrame - root.CFrame.Position)
                    root.AssemblyLinearVelocity = Vector3.new(vel.X, math.min(vel.Y, 0), vel.Z)
                end
            end
        end
        applyHudRemovals()
        applyWorldRemovals(object)
    end))
    bindStep("TapologyRemoveArms", Enum.RenderPriority.Camera.Value + 75, function()
        if not Config.RemoveArms then
            return
        end
        local object = charInterface and charInterface.getCharacterObject and charInterface.getCharacterObject()
        if not object then
            return
        end
        local function hideArmModel(model)
            if typeof(model) ~= "Instance" then
                return
            end
            for _, desc in model:GetDescendants() do
                if desc:IsA("BasePart") or desc:IsA("Decal") or desc:IsA("Texture") then
                    local lower = string.lower(desc.Name)
                    if string.find(lower, "weapon", 1, true)
                        or string.find(lower, "gun", 1, true)
                        or string.find(lower, "barrel", 1, true)
                        or string.find(lower, "sight", 1, true)
                        or string.find(lower, "mag", 1, true)
                        or string.find(lower, "stock", 1, true)
                    then
                        continue
                    end
                    desc.LocalTransparencyModifier = 1
                end
            end
        end
        hideArmModel(object._leftArmModel)
        hideArmModel(object._rightArmModel)
    end)

    local smoothShowVel = Vector3.zero
    local wasHidingViewmodel = false

    local function hideInstance(model)
        if not model then
            return
        end
        for _, descendant in model:GetDescendants() do
            if descendant:IsA("BasePart") then
                descendant.LocalTransparencyModifier = 1
            elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
                descendant.LocalTransparencyModifier = 1
            end
        end
    end

    local function showInstance(model)
        if not model then
            return
        end
        for _, descendant in model:GetDescendants() do
            if descendant:IsA("BasePart") or descendant:IsA("Decal") or descendant:IsA("Texture") then
                descendant.LocalTransparencyModifier = 0
            end
        end
    end

    local function setFirstPersonHidden(hidden)
        local object = charInterface and charInterface.getCharacterObject and charInterface.getCharacterObject()
        local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
        local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()

        if hidden then
            if weapon then
                weapon._forceHidden = true
                if weapon.hideModel then
                    pcall(function()
                        weapon._isHidden = false
                        weapon:hideModel()
                    end)
                end
                hideInstance(weapon._weaponModel)
            end
            if object then
                hideInstance(object._leftArmModel)
                hideInstance(object._rightArmModel)
            end
        elseif wasHidingViewmodel then
            if weapon then
                weapon._forceHidden = nil
                if weapon.showModel then
                    pcall(weapon.showModel, weapon)
                end
                showInstance(weapon._weaponModel)
            end
            if object then
                showInstance(object._leftArmModel)
                showInstance(object._rightArmModel)
            end
        end
        wasHidingViewmodel = hidden
    end

    bindStep("TapologyMiscHideVM", Enum.RenderPriority.Camera.Value + 50, function()
        if not Config.ThirdPerson or Config.HideViewmodel ~= true then
            setFirstPersonHidden(false)
            return
        end
        local alive = charInterface and charInterface.isAlive and charInterface.isAlive()
        setFirstPersonHidden(alive == true)
    end)

    table.insert(Connections, RunService.Stepped:Connect(function(_, ndt)
        if not Config.ThirdPerson then
            if currentObj or startedShow or wasHidingViewmodel then
                setFirstPersonHidden(false)
                if currentObj or startedShow then
                    destroyShowCharacter()
                end
                smoothShowVel = Vector3.zero
            end
            return
        end
        local alive = charInterface and charInterface.isAlive and charInterface.isAlive()
        local wantShow = Config.ShowCharacter and alive
        local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
        local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
        local aiming = weapon and weapon._aiming

        if alive and Config.HideViewmodel == true then
            setFirstPersonHidden(true)
        elseif Config.HideViewmodel ~= true then
            setFirstPersonHidden(false)
        end

        if not wantShow then
            if currentObj or startedShow then
                destroyShowCharacter()
            end
            smoothShowVel = Vector3.zero
            return
        end

        showDelta += ndt
        local object = charInterface.getCharacterObject and charInterface.getCharacterObject()
        local rootPart = object and object.getRealRootPart and object:getRealRootPart()
            or object and object.getRootPart and object:getRootPart()
        if not rootPart then
            return
        end

        local position = rootPart.Position
        lastShowPos = lastShowPos or position

        local velocity = smoothShowVel
        local raw = (position - lastShowPos) / math.max(showDelta, 1 / 240)
        showDelta = 0
        lastShowPos = position
        if raw.Magnitude < 6 then
            raw = Vector3.zero
        else
            raw = Vector3.new(raw.X, 0, raw.Z)
            if raw.Magnitude > 40 then
                raw = raw.Unit * 40
            end
        end
        smoothShowVel = smoothShowVel:Lerp(raw, 1 - math.exp(-math.max(ndt, 0.001) * 6))
        velocity = smoothShowVel

        if not currentObj then
            startedShow = true
            spawnShowCharacter()
            startedShow = false
            if not currentObj then
                return
            end
        end

        local angles = Vector3.zero
        pcall(function()
            local active = cameraInterface and cameraInterface.getActiveCamera and cameraInterface.getActiveCamera()
            if active and active.getAngles then
                angles = active:getAngles()
            end
        end)
        local tickTime = tick()
        local clockTime = os.clock()
        pcall(function()
            fakeRepObject._posspring.t = position
            fakeRepObject._posspring.p = position
            fakeRepObject._lookangles.t = angles
            fakeRepObject._lookangles.p = angles
            if fakeRepObject._smoothReplication and fakeRepObject._smoothReplication.receive then
                fakeRepObject._smoothReplication:receive(clockTime, tickTime, {
                    t = tickTime,
                    position = position,
                    velocity = velocity,
                    angles = angles,
                    barrelAngles = Vector3.zero,
                    breakcount = 0,
                }, true)
            end
            fakeRepObject._updaterecieved = true
            fakeRepObject._receivedPosition = position
            if network and network.getTime then
                fakeRepObject._receivedFrameTime = network.getTime()
            end
            fakeRepObject._lastPacketTime = clockTime
            fakeRepObject._lastBarrelAngles = Vector3.zero
            fakeRepObject:step(3, true)
            if currentObj then
                currentObj.canRenderWeapon = Config.ThirdPersonWeapon ~= false
                if not Config.ShowCharacterWhileAiming and aiming and setCharacterRender then
                    setCharacterRender(currentObj, false)
                elseif setCharacterRender then
                    setCharacterRender(currentObj, true)
                end
                local shown = currentObj.getCharacterModel and currentObj:getCharacterModel() or currentObj._characterModel
                if typeof(shown) == "Instance" then
                    local quietAt = rawget(currentObj, "_tapologyQuietAt") or 0
                    local quietNow = os.clock()
                    if quietNow - quietAt >= 0.2 then
                        rawset(currentObj, "_tapologyQuietAt", quietNow)
                        for _, desc in shown:GetDescendants() do
                            if desc:IsA("Sound") then
                                desc.Volume = 0
                                desc.Playing = false
                                desc.RollOffMaxDistance = 0
                            elseif not Config.BodyChams and (desc:IsA("Decal") or desc:IsA("Texture") or desc:IsA("SurfaceAppearance")) then
                                if desc.Name ~= "TapologyField" and not desc:FindFirstAncestor("TapologyField") then
                                    if desc:IsA("SurfaceAppearance") then
                                        pcall(function()
                                            desc.Parent = nil
                                        end)
                                    else
                                        desc.Transparency = 1
                                    end
                                end
                            elseif not Config.BodyChams and desc:IsA("BasePart") then
                                if desc.Material == Enum.Material.ForceField or desc.Material == Enum.Material.Neon or desc.Material == Enum.Material.Glass then
                                    desc.Material = Enum.Material.SmoothPlastic
                                    desc.Reflectance = 0
                                end
                            end
                        end
                    end
                end
            end
        end)
    end))

    table.insert(Restores, function()
        setFirstPersonHidden(false)
        destroyShowCharacter()
    end)

    local savedMainOffset = {}
    local fovHooked = setmetatable({}, { __mode = "k" })
    bindStep("TapologyMiscCamera", Enum.RenderPriority.Last.Value, function()
        local cam = camera()
        if not cam then
            return
        end

        local activeCam = cameraInterface and cameraInterface.getActiveCamera and cameraInterface.getActiveCamera()
        if not Config.ThirdPerson and smoothCamPos then
            smoothOffset = Vector3.new(Config.CameraOffsetX, Config.CameraOffsetY, Config.CameraOffsetZ)
            targetOffset = smoothOffset
            lastOffsetX, lastOffsetY, lastOffsetZ = Config.CameraOffsetX, Config.CameraOffsetY, Config.CameraOffsetZ
            smoothCamPos = nil
            lastRayDesired = nil
            lastCamClock = os.clock()
        end

        if Config.FOV then
            local amount = math.clamp(tonumber(Config.FOVAmount) or 90, 40, 135)
            cam.FieldOfView = amount
            if type(activeCam) == "table" then
                activeCam._baseFov = amount
                if type(activeCam.getBaseFov) == "function" and not fovHooked[activeCam] then
                    fovHooked[activeCam] = true
                    local nextBase = activeCam.getBaseFov
                    activeCam.getBaseFov = function(self, ...)
                        if Config.FOV then
                            return math.clamp(tonumber(Config.FOVAmount) or 90, 40, 135)
                        end
                        return nextBase(self, ...)
                    end
                end
            end
        end

        if Config.AspectRatio then
            local size = cam.ViewportSize
            local native = size.X / math.max(size.Y, 1)
            local wanted = math.clamp(tonumber(Config.Aspect) or native, 0.4, 3)
            local factor = math.clamp(wanted / math.max(native, 1e-3), 0.25, 3)
            local cf = cam.CFrame
            cam.CFrame = CFrame.fromMatrix(cf.Position, cf.XVector * factor, cf.YVector, cf.ZVector)
        end

        local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
        local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
        if weapon then
            if weapon._mainOffset ~= nil then
                if savedMainOffset[weapon] == nil then
                    savedMainOffset[weapon] = weapon._mainOffset
                end
                local base = savedMainOffset[weapon]
                if Config.Viewmodel then
                    local scale = 2
                    weapon._mainOffset = base * CFrame.new(Config.ViewmodelX * scale, Config.ViewmodelY * scale, Config.ViewmodelZ * scale)
                else
                    weapon._mainOffset = base
                end
            end
            if Config.RecoilControl then
                local scale = 1 - math.clamp(tonumber(Config.RecoilScale) or 0.5, 0, 1)
                pcall(function()
                    local spring = weapon._recoilSpring or weapon._cameraSpring
                    if type(spring) == "table" then
                        if typeof(spring.p) == "Vector3" then
                            spring.p = spring.p * scale
                        end
                        if typeof(spring.v) == "Vector3" then
                            spring.v = spring.v * scale
                        end
                    end
                end)
            end
        end
    end)
    table.insert(Restores, function()
        for weapon, base in savedMainOffset do
            if weapon and weapon._mainOffset ~= nil then
                weapon._mainOffset = base
            end
        end
        table.clear(savedMainOffset)
    end)

    local partCache = {}
    local lastBodyModels = {}
    local lastWeaponModel, lastLeftArm, lastRightArm = nil, nil, nil
    local MATERIAL_MAP = {
        ForceField = Enum.Material.ForceField,
        Neon = Enum.Material.Neon,
        Glass = Enum.Material.Glass,
        SmoothPlastic = Enum.Material.SmoothPlastic,
        Plastic = Enum.Material.Plastic,
        Metal = Enum.Material.Metal,
        DiamondPlate = Enum.Material.DiamondPlate,
        Foil = Enum.Material.Foil,
        Ice = Enum.Material.Ice,
        Concrete = Enum.Material.Concrete,
        Grass = Enum.Material.Grass,
        Fabric = Enum.Material.Fabric,
        Wood = Enum.Material.Wood,
        Marble = Enum.Material.Marble,
        Granite = Enum.Material.Granite,
        Slate = Enum.Material.Slate,
        CorrodedMetal = Enum.Material.CorrodedMetal,
    }

    local ARM_FLESH_NAMES = {
        Arm = true,
        SkinTone = true,
        Hand = true,
        LeftArm = true,
        RightArm = true,
        LeftHand = true,
        RightHand = true,
    }
    local ARM_STRIP_NAMES = {
        Sleeves = true,
        Sleeve = true,
        Gloves = true,
        Glove = true,
        Watch = true,
        ["Team Color"] = true,
        Shirt = true,
        Pants = true,
        Clothing = true,
        Accessory = true,
        Band = true,
        Bracelet = true,
        Ring = true,
    }

    local function restoreCachedParts(filterFn)
        for inst, saved in pairs(partCache) do
            if typeof(inst) ~= "Instance" or not inst.Parent then
                partCache[inst] = nil
            elseif not filterFn or filterFn(inst) then
                pcall(function()
                    if saved.Color ~= nil and inst:IsA("BasePart") then
                        inst.Color = saved.Color
                        inst.Material = saved.Material
                        inst.Reflectance = saved.Reflectance
                    end
                    if saved.Size ~= nil and inst:IsA("BasePart") then
                        inst.Size = saved.Size
                    end
                    if saved.TextureID ~= nil and inst:IsA("MeshPart") then
                        inst.TextureID = saved.TextureID
                    end
                    if saved.TextureId ~= nil and inst:IsA("SpecialMesh") then
                        inst.TextureId = saved.TextureId
                    end
                    if saved.Transparency ~= nil and (inst:IsA("BasePart") or inst:IsA("Decal") or inst:IsA("Texture")) then
                        inst.Transparency = saved.Transparency
                    end
                    if saved.LocalTransparencyModifier ~= nil and (inst:IsA("BasePart") or inst:IsA("Decal") or inst:IsA("Texture")) then
                        inst.LocalTransparencyModifier = saved.LocalTransparencyModifier
                    end
                    if saved.Parent ~= nil and (
                        inst:IsA("Shirt")
                        or inst:IsA("Pants")
                        or inst:IsA("ShirtGraphic")
                        or inst:IsA("Clothing")
                        or inst:IsA("Accessory")
                        or inst:IsA("Accoutrement")
                        or inst:IsA("Hat")
                        or inst:IsA("CharacterMesh")
                        or inst:IsA("BodyColors")
                    ) then
                        inst.Parent = saved.Parent
                    end
                end)
                partCache[inst] = nil
            end
        end
    end

    local function restoreAllChams()
        restoreCachedParts(nil)
        table.clear(lastBodyModels)
        lastWeaponModel, lastLeftArm, lastRightArm = nil, nil, nil
    end

    local function cacheInstance(inst)
        if partCache[inst] then
            return partCache[inst]
        end
        local saved = {}
        if inst:IsA("BasePart") then
            saved.Color = inst.Color
            saved.Material = inst.Material
            saved.Reflectance = inst.Reflectance
            saved.Transparency = inst.Transparency
            saved.LocalTransparencyModifier = inst.LocalTransparencyModifier
            saved.Size = inst.Size
            if inst:IsA("MeshPart") then
                saved.TextureID = inst.TextureID
            end
        elseif inst:IsA("Decal") or inst:IsA("Texture") then
            saved.Transparency = inst.Transparency
            saved.LocalTransparencyModifier = inst.LocalTransparencyModifier
        elseif inst:IsA("SpecialMesh") then
            saved.TextureId = inst.TextureId
        end
        partCache[inst] = saved
        return saved
    end

    local function hideOverlay(inst)
        cacheInstance(inst)
        pcall(function()
            if inst:IsA("BasePart") or inst:IsA("Decal") or inst:IsA("Texture") then
                inst.LocalTransparencyModifier = 1
                inst.Transparency = 1
            elseif inst:IsA("SurfaceAppearance") then
                inst:Destroy()
            end
        end)
    end

    local function isArmFleshPart(part)
        if not part:IsA("BasePart") then
            return false
        end
        if ARM_FLESH_NAMES[part.Name] then
            return true
        end

        local c = part.Color
        local skinLike = c.R > 0.85 and c.G > 0.55 and c.G < 0.95 and c.B > 0.35 and c.B < 0.85
        return skinLike and part.Material ~= Enum.Material.Fabric and part.Material ~= Enum.Material.Metal
    end

    local function shouldStripArmPart(part)
        if ARM_STRIP_NAMES[part.Name] then
            return true
        end
        local lower = string.lower(part.Name)
        if string.find(lower, "sleeve", 1, true)
            or string.find(lower, "glove", 1, true)
            or string.find(lower, "watch", 1, true)
            or string.find(lower, "shirt", 1, true)
            or string.find(lower, "cloth", 1, true)
        then
            return true
        end
        if part:IsA("BasePart") and part.Material == Enum.Material.Fabric then
            return true
        end

        if part:IsA("BasePart") and not isArmFleshPart(part) then
            return true
        end
        return false
    end

    local BODY_CORE_NAMES = {
        Head = true,
        Torso = true,
        UpperTorso = true,
        LowerTorso = true,
        HumanoidRootPart = true,
        LeftArm = true,
        RightArm = true,
        LeftLeg = true,
        RightLeg = true,
        LeftHand = true,
        RightHand = true,
        LeftFoot = true,
        RightFoot = true,
        LeftUpperArm = true,
        LeftLowerArm = true,
        RightUpperArm = true,
        RightLowerArm = true,
        LeftUpperLeg = true,
        LeftLowerLeg = true,
        RightUpperLeg = true,
        RightLowerLeg = true,
        Arm = true,
        SkinTone = true,
        Hand = true,
    }

    local function shouldStripBodyGear(inst)
        if not inst then
            return false
        end
        if inst:IsA("Accessory") or inst:IsA("Accoutrement") or inst:IsA("Hat")
            or inst:IsA("Shirt") or inst:IsA("Pants") or inst:IsA("ShirtGraphic")
            or inst:IsA("Clothing") or inst:IsA("CharacterMesh") or inst:IsA("BodyColors")
        then
            return true
        end
        local parent = inst.Parent
        if parent and (parent:IsA("Accessory") or parent:IsA("Accoutrement") or parent:IsA("Hat")) then
            return true
        end
        if not inst:IsA("BasePart") then
            return false
        end
        if BODY_CORE_NAMES[inst.Name] then
            return false
        end
        local lower = string.lower(inst.Name)
        if string.find(lower, "hair", 1, true)
            or string.find(lower, "hat", 1, true)
            or string.find(lower, "backpack", 1, true)
            or string.find(lower, "holster", 1, true)
            or string.find(lower, "pouch", 1, true)
            or string.find(lower, "team color", 1, true)
        then
            return true
        end
        return false
    end

    local function detachGear(inst)
        if not partCache[inst] then
            partCache[inst] = { Parent = inst.Parent }
        elseif partCache[inst].Parent == nil then
            partCache[inst].Parent = inst.Parent
        end
        pcall(function()
            inst.Parent = nil
        end)
    end

    local FIELD_TEXTURE = "rbxassetid://1084969997"
    local function paintCham(part, alpha, materialName)
        local amount = math.clamp(tonumber(alpha) or 0, 0, 0.92)
        if materialName == "ForceField" then
            part.Transparency = math.max(amount, 0.12)
            local folder = part:FindFirstChild("TapologyField")
            if not folder then
                folder = Instance.new("Folder")
                folder.Name = "TapologyField"
                folder.Parent = part
                local faces = {
                    Enum.NormalId.Front,
                    Enum.NormalId.Back,
                    Enum.NormalId.Left,
                    Enum.NormalId.Right,
                    Enum.NormalId.Top,
                    Enum.NormalId.Bottom,
                }
                for _, face in faces do
                    local tex = Instance.new("Texture")
                    tex.Name = face.Name
                    tex.Face = face
                    tex.Texture = FIELD_TEXTURE
                    tex.StudsPerTileU = 2
                    tex.StudsPerTileV = 2
                    tex.Transparency = 0.2
                    tex.Parent = folder
                end
            end
            local shift = (os.clock() * 3) % 4
            for _, tex in folder:GetChildren() do
                if tex:IsA("Texture") then
                    tex.OffsetStudsU = shift
                    tex.OffsetStudsV = shift * 0.5
                end
            end
        else
            part.Transparency = amount
            local folder = part:FindFirstChild("TapologyField")
            if folder then
                folder:Destroy()
            end
        end
    end

    local function applyModelChams(model, color, materialName, opts)
        if typeof(model) ~= "Instance" then
            return
        end
        opts = opts or {}
        if typeof(color) ~= "Color3" then
            color = Color3.fromRGB(108, 147, 255)
        end
        local mat = MATERIAL_MAP[materialName] or Enum.Material.ForceField
        local reveal = opts.reveal == true
        local forceVisible = opts.forceVisible == true
        local skipRoot = opts.skipRoot ~= false
        local onlyVisible = opts.onlyVisible == true
        local stripGear = opts.stripGear == true
        local keepTextures = opts.keepTextures == true
        local stripOverlays = opts.stripOverlays == true or (stripGear and not keepTextures)
        local stripSurfaceOnly = opts.stripSurfaceOnly == true

        for _, desc in model:GetDescendants() do
            if stripGear and (
                desc:IsA("Accessory")
                or desc:IsA("Accoutrement")
                or desc:IsA("Hat")
                or desc:IsA("Shirt")
                or desc:IsA("Pants")
                or desc:IsA("ShirtGraphic")
                or desc:IsA("Clothing")
                or desc:IsA("CharacterMesh")
                or desc:IsA("BodyColors")
            ) then
                detachGear(desc)
            elseif desc:IsA("Shirt") or desc:IsA("Pants") or desc:IsA("ShirtGraphic") or desc:IsA("Clothing") then
                detachGear(desc)
            elseif stripSurfaceOnly and desc:IsA("SurfaceAppearance") then
                hideOverlay(desc)
            elseif stripOverlays and (desc:IsA("Decal") or desc:IsA("Texture") or desc:IsA("SurfaceAppearance")) and desc.Name ~= "TapologyField" and not desc:FindFirstAncestor("TapologyField") then
                hideOverlay(desc)
            elseif desc:IsA("BasePart") then
                if skipRoot and (desc.Name == "HumanoidRootPart" or desc.Name == "Root") then

                elseif stripGear and shouldStripBodyGear(desc) then
                    hideOverlay(desc)
                elseif onlyVisible and desc.Transparency >= 0.99 then

                else
                    local saved = cacheInstance(desc)
                    pcall(function()
                        desc.Color = color
                        desc.Material = mat
                        local ff = mat == Enum.Material.ForceField
                        desc.Reflectance = ff and 0.12 or 0
                        desc.CastShadow = false
                        if desc:IsA("MeshPart") and not keepTextures then
                            desc.TextureID = ""
                        end
                        if reveal or forceVisible or stripGear then
                            local wasHidden = saved and typeof(saved.Transparency) == "number" and saved.Transparency >= 0.99
                            if stripGear or reveal or forceVisible or not wasHidden then
                                paintCham(desc, opts.alpha, materialName)
                                desc.LocalTransparencyModifier = 0
                            end
                        end
                    end)
                    for _, child in desc:GetChildren() do
                        if child:IsA("SpecialMesh") then
                            cacheInstance(child)
                            if not keepTextures then
                                pcall(function()
                                    child.TextureId = ""
                    end)
                end
                        elseif stripSurfaceOnly and child:IsA("SurfaceAppearance") then
                            hideOverlay(child)
                        elseif stripOverlays and (child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance")) then
                            hideOverlay(child)
            end
        end
                end
            end
        end
        if model:IsA("BasePart") and not (skipRoot and (model.Name == "HumanoidRootPart" or model.Name == "Root")) then
            if not (onlyVisible and model.Transparency >= 0.99) and not (stripGear and shouldStripBodyGear(model)) then
                local saved = cacheInstance(model)
                pcall(function()
                    model.Color = color
                    model.Material = mat
                    model.Reflectance = 0
                    if model:IsA("MeshPart") and not keepTextures then
                        model.TextureID = ""
                    end
                    if reveal or forceVisible or stripGear then
                        local wasHidden = saved and typeof(saved.Transparency) == "number" and saved.Transparency >= 0.99
                        if stripGear or reveal or forceVisible or not wasHidden then
                            paintCham(model, opts.alpha, materialName)
                            model.LocalTransparencyModifier = 0
                        end
                    end
                end)
            end
        end
    end

    local function restoreBodyPartSizes(tpo)
        local sizes = tpo and rawget(tpo, "_partSizes")
        if type(sizes) ~= "table" then
            return
        end
        for part, size in pairs(sizes) do
            if typeof(part) == "Instance" and part:IsA("BasePart") and typeof(size) == "Vector3" then
                cacheInstance(part)
                pcall(function()
                    part.Size = size
                end)
            end
        end
    end

    local function collectBodyModels(object)
        local models = {}
        local seen = {}
        local function add(model)
            if typeof(model) == "Instance" and not seen[model] then
                seen[model] = true
                table.insert(models, model)
            end
        end

        local tpo = currentObj or (fakeRepObject and fakeRepObject._thirdPersonObject)
        if tpo then
            if type(tpo.getCharacterModel) == "function" then
                local ok, model = pcall(tpo.getCharacterModel, tpo)
                if ok then
                    add(model)
                end
            end
            add(rawget(tpo, "_characterModel"))
            local hash = rawget(tpo, "_characterModelHash")
            if type(hash) == "table" then
                for _, part in pairs(hash) do
                    if typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent then
                        add(part:FindFirstAncestorOfClass("Model") or part.Parent)
                        break
                    end
                end
            end
        end

        if #models > 0 then
        return models
        end

        if not (Config.ShowCharacter and Config.ThirdPerson) and object then
            add(object._characterModel)
        end
        return models
    end

    local function hideProxyBody(object)
        local proxies = {}
        local function addProxy(model)
            if typeof(model) == "Instance" then
                proxies[model] = true
            end
        end
        addProxy(object and object._characterModel)
        addProxy(LocalPlayer.Character)
        for proxy in pairs(proxies) do
            for _, desc in proxy:GetDescendants() do
                if desc:IsA("BasePart") or desc:IsA("Decal") or desc:IsA("Texture") then
                    hideOverlay(desc)
                end
            end
            if proxy:IsA("BasePart") then
                hideOverlay(proxy)
            end
        end
    end

    local function applyArmChams(model, color, materialName)
        if typeof(model) ~= "Instance" then
            return
        end
        if typeof(color) ~= "Color3" then
            color = Color3.fromRGB(108, 147, 255)
        end
        local mat = MATERIAL_MAP[materialName] or Enum.Material.ForceField

        for _, desc in model:GetDescendants() do
            if desc:IsA("Decal") or desc:IsA("Texture") or desc:IsA("SurfaceAppearance") then
                if not desc:FindFirstAncestor("TapologyField") then
                    hideOverlay(desc)
                end
            elseif desc:IsA("BasePart") then
                if shouldStripArmPart(desc) then
                    hideOverlay(desc)
                elseif isArmFleshPart(desc) then
                    cacheInstance(desc)
                    pcall(function()
                        paintCham(desc, Config.ArmsChamsAlpha, materialName)
                        desc.LocalTransparencyModifier = 0
                        desc.Color = color
                        desc.Material = mat
                        desc.Reflectance = 0
                    end)
                end
            end
        end

        if model:IsA("BasePart") and isArmFleshPart(model) then
            cacheInstance(model)
            pcall(function()
                paintCham(model, Config.ArmsChamsAlpha, materialName)
                model.LocalTransparencyModifier = 0
                model.Color = color
                model.Material = mat
                model.Reflectance = 0
            end)
        end
    end

    local function modelContains(model, part)
        return typeof(model) == "Instance" and typeof(part) == "Instance" and part:IsDescendantOf(model)
    end

    local lastChamPass = 0
    bindStep("TapologyMiscWeaponChams", Enum.RenderPriority.Camera.Value + 51, function()
        local now = os.clock()
        if now - lastChamPass < 0.05 then
            return
        end
        lastChamPass = now
        local armsOn = Config.ArmsChams and true or false
        local bodyOn = Config.BodyChams and true or false
        local weaponOn = Config.WeaponChams and true or false
        if not armsOn and not bodyOn and not weaponOn then
            if next(partCache) then
                restoreAllChams()
            end
            return
        end

        local object = charInterface and charInterface.getCharacterObject and charInterface.getCharacterObject()
        local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
        local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
        local weaponModel = weapon and weapon._weaponModel
        local leftArm = object and object._leftArmModel
        local rightArm = object and object._rightArmModel

        local bodyThirdPerson = Config.ThirdPerson and Config.ShowCharacter
        if bodyOn and bodyThirdPerson then
            local bodies = collectBodyModels(object)
            local active = {}
            for _, model in bodies do
                active[model] = true
            end
            for model in pairs(lastBodyModels) do
                if not active[model] then
                    restoreCachedParts(function(part)
                        return modelContains(model, part)
                    end)
                    lastBodyModels[model] = nil
                end
            end

            hideProxyBody(object)
            local tpo = currentObj or (fakeRepObject and fakeRepObject._thirdPersonObject)
            if tpo then
                restoreBodyPartSizes(tpo)
            end
            for _, model in bodies do
                lastBodyModels[model] = true

                for _, desc in model:GetDescendants() do
                    local lower = string.lower(desc.Name)
                    local isPlate = string.find(lower, "chest", 1, true)
                        or string.find(lower, "vest", 1, true)
                        or string.find(lower, "armor", 1, true)
                        or string.find(lower, "plate", 1, true)
                        or string.find(lower, "carrier", 1, true)
                    if isPlate and (desc:IsA("BasePart") or desc:IsA("Accessory") or desc:IsA("Folder") or desc:IsA("Model")) then
                        if desc:IsA("BasePart") then
                            hideOverlay(desc)
                        elseif desc:IsA("Accessory") then
                            detachGear(desc)
                        end
                    end
                end
                local cosmetics = model:FindFirstChild("Cosmetics")
                if cosmetics then
                    for _, child in cosmetics:GetChildren() do
                        local lower = string.lower(child.Name)
                        if string.find(lower, "chest", 1, true)
                            or string.find(lower, "vest", 1, true)
                            or string.find(lower, "armor", 1, true)
                            or string.find(lower, "plate", 1, true)
                            or string.find(lower, "carrier", 1, true)
                        then
                            if child:IsA("BasePart") then
                                hideOverlay(child)
                            else
                                for _, part in child:GetDescendants() do
                                    if part:IsA("BasePart") then
                                        hideOverlay(part)
                                    end
                                end
                            end
                        end
                    end
                end

                applyModelChams(model, Config.BodyChamsColor, Config.BodyChamsMaterial or "ForceField", {
                    reveal = true,
                    forceVisible = true,
                    skipRoot = true,
                    keepTextures = false,
                    stripSurfaceOnly = false,
                    stripOverlays = true,
                    stripGear = true,
                    alpha = Config.BodyChamsAlpha,
                })

                local bodyColor = Config.BodyChamsColor or Color3.fromRGB(255, 190, 150)
                local bodyMatName = Config.BodyChamsMaterial or "ForceField"
                local bodyMat = MATERIAL_MAP[bodyMatName] or Enum.Material.ForceField
                local isFF = bodyMat == Enum.Material.ForceField
                local function isWeaponDescendant(inst)
                    local p = inst
                    while p and p ~= model do
                        local n = string.lower(tostring(p.Name))
                        if string.find(n, "main", 1, true) or string.find(n, "weapon", 1, true)
                            or string.find(n, "gun", 1, true) or string.find(n, "knife", 1, true)
                        then
                            return true
                        end
                        p = p.Parent
                    end
                    return false
                end
                for _, desc in model:GetDescendants() do
                    if desc:IsA("Shirt") or desc:IsA("Pants") or desc:IsA("ShirtGraphic") or desc:IsA("Clothing")
                        or desc:IsA("CharacterMesh") or desc:IsA("BodyColors")
                    then
                        detachGear(desc)
                    elseif desc:IsA("BasePart") and desc.Name ~= "HumanoidRootPart" and desc.Name ~= "Root"
                        and not isWeaponDescendant(desc)
                    then
                        cacheInstance(desc)
                        pcall(function()
                            desc.Material = bodyMat
                            desc.Color = bodyColor
                            desc.Reflectance = isFF and 0.18 or 0
                            paintCham(desc, Config.BodyChamsAlpha, bodyMatName)
                            desc.LocalTransparencyModifier = 0
                            desc.CastShadow = false
                            if desc:IsA("MeshPart") then
                                desc.TextureID = ""
                            end
                            for _, child in desc:GetChildren() do
                                if child:IsA("SpecialMesh") then
                                    cacheInstance(child)
                                    child.TextureId = ""
                                elseif child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance")
                                    or child:IsA("Highlight") or child:IsA("ParticleEmitter") or child:IsA("Fire")
                                    or child:IsA("Smoke") or child:IsA("Sparkles")
                                then
                                    hideOverlay(child)
                                end
                            end
                        end)
                    elseif (desc:IsA("Decal") or desc:IsA("Texture") or desc:IsA("SurfaceAppearance")
                        or desc:IsA("Highlight")) and not isWeaponDescendant(desc) and not desc:FindFirstAncestor("TapologyField")
                    then
                        hideOverlay(desc)
                    end
                end
            end
        else
            if next(lastBodyModels) then
                for model in pairs(lastBodyModels) do
                    restoreCachedParts(function(part)
                        return modelContains(model, part)
                    end)
                end
                table.clear(lastBodyModels)
            end
            if object then
                hideProxyBody(object)
            end
            local fpBody = object and object._characterModel
            if typeof(fpBody) == "Instance" then
                for _, desc in fpBody:GetDescendants() do
                    if desc:IsA("BasePart") then
                        local folder = desc:FindFirstChild("TapologyField")
                        if folder then
                            folder:Destroy()
                        end
                        if desc.Material == Enum.Material.ForceField then
                            desc.Material = Enum.Material.SmoothPlastic
                            desc.Reflectance = 0
                            desc.LocalTransparencyModifier = 1
                        end
                    elseif desc:IsA("Texture") and desc:FindFirstAncestor("TapologyField") then
                        desc:Destroy()
                    end
                end
            end
        end

        if weaponOn then
            if weaponModel ~= lastWeaponModel then
                restoreCachedParts(function(part)
                    return lastWeaponModel and modelContains(lastWeaponModel, part)
                end)
                lastWeaponModel = weaponModel
            end
            if typeof(weaponModel) == "Instance" then

                if weapon then
                    weapon._forceHidden = nil
                    weapon._isHidden = false
                end
                applyModelChams(weaponModel, Config.WeaponChamsColor, Config.WeaponChamsMaterial or "ForceField", {
                    forceVisible = true,
                    onlyVisible = true,
                    skipRoot = false,
                    stripOverlays = false,
                    alpha = Config.WeaponChamsAlpha,
                })
            end
            local tpo = currentObj or (fakeRepObject and fakeRepObject._thirdPersonObject)
            if tpo and type(tpo.getWeaponModel) == "function" then
                local ok, tpWeapon = pcall(tpo.getWeaponModel, tpo)
                if ok and typeof(tpWeapon) == "Instance" and tpWeapon ~= weaponModel then
                    applyModelChams(tpWeapon, Config.WeaponChamsColor, Config.WeaponChamsMaterial or "ForceField", {
                        forceVisible = true,
                        onlyVisible = true,
                        skipRoot = false,
                        stripOverlays = false,
                        alpha = Config.WeaponChamsAlpha,
                    })
                end
            end
        elseif lastWeaponModel then
            restoreCachedParts(function(part)
                return modelContains(lastWeaponModel, part)
            end)
            lastWeaponModel = nil
        end

        if armsOn then
            if leftArm ~= lastLeftArm or rightArm ~= lastRightArm then
                restoreCachedParts(function(part)
                    return (lastLeftArm and modelContains(lastLeftArm, part))
                        or (lastRightArm and modelContains(lastRightArm, part))
                end)
                lastLeftArm, lastRightArm = leftArm, rightArm
            end
            applyArmChams(leftArm, Config.ArmsChamsColor, Config.ArmsChamsMaterial or "ForceField")
            applyArmChams(rightArm, Config.ArmsChamsColor, Config.ArmsChamsMaterial or "ForceField")
        elseif lastLeftArm or lastRightArm then
            restoreCachedParts(function(part)
                return (lastLeftArm and modelContains(lastLeftArm, part))
                    or (lastRightArm and modelContains(lastRightArm, part))
            end)
            lastLeftArm, lastRightArm = nil, nil
        end
    end)
    table.insert(Restores, restoreAllChams)

    local function syncAuraHost()
        local bodies = collectBodyModels(charInterface and charInterface.getCharacterObject and charInterface.getCharacterObject())
        local model = bodies[1]
        if typeof(model) ~= "Instance" then
            env.TapologyAuraHost = nil
            return
        end
        local root = model:FindFirstChild("Torso")
            or model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChildWhichIsA("BasePart", true)
        if typeof(root) ~= "Instance" then
            env.TapologyAuraHost = nil
            return
        end
        env.TapologyAuraHost = {
            Root = root,
            Character = model,
            Humanoid = model:FindFirstChildOfClass("Humanoid"),
        }
    end

    bindStep("TapologyMiscAuraHost", Enum.RenderPriority.Camera.Value + 52, syncAuraHost)
    table.insert(Restores, function()
        env.TapologyAuraHost = nil
    end)

    local shootSoundPool = {}
    local shootSoundFolder = Instance.new("Folder")
    shootSoundFolder.Name = "TapologyShootSounds"
    shootSoundFolder.Parent = SoundService
    table.insert(Restores, function()
        shootSoundFolder:Destroy()
        table.clear(shootSoundPool)
    end)

    local function getPooledSound(id)
        local bucket = shootSoundPool[id]
        if not bucket then
            bucket = {}
            shootSoundPool[id] = bucket
        end
        for i = 1, #bucket do
            local s = bucket[i]
            if s and s.Parent and not s.IsPlaying then
                return s
            end
        end
        local sound = Instance.new("Sound")
        sound.Name = "Shoot"
        sound.SoundId = id
        sound.Looped = false
        sound.PlayOnRemove = false
        sound.Parent = shootSoundFolder
        table.insert(bucket, sound)
        return sound
    end

    local lastShootSoundAt = 0
    local function playShootSound(force, skipDebounce)
        if not force and not Config.ShootSounds then
            return false
        end
        local now = os.clock()

        if not skipDebounce and now - lastShootSoundAt < 0.03 then
            return false
        end
        lastShootSoundAt = now
        local id = Config.ShootSoundIds and Config.ShootSoundIds[Config.ShootSound]
        local custom = Config.CustomSound
        if type(custom) == "string" and custom ~= "" then
            if getcustomasset and (string.find(string.lower(custom), ".mp3", 1, true) or string.find(string.lower(custom), ".wav", 1, true)) then
                local okAsset, asset = pcall(getcustomasset, custom)
                if okAsset and type(asset) == "string" and asset ~= "" then
                    id = asset
                end
            elseif string.find(custom, "rbxassetid://", 1, true) or string.find(custom, "rbxasset://", 1, true) then
                id = custom
            end
        end
        if type(id) ~= "string" or id == "" then
            id = "rbxassetid://4817809188"
        end
        local sound = getPooledSound(id)
        sound.Volume = math.clamp(tonumber(Config.ShootSoundVolume) or 1.5, 0, 5)
        sound.PlaybackSpeed = math.clamp(tonumber(Config.ShootSoundPitch) or 1, 0.1, 3)
        sound.TimePosition = 0
        local played = false
        if typeof(SoundService.PlayLocalSound) == "function" then
            played = pcall(function()
                SoundService:PlayLocalSound(sound)
            end)
        end
        pcall(function()
            sound:Play()
        end)
        return played
    end
    env._TapologyPlayShootSound = playShootSound

    local function soundToken(value)
        return string.lower(tostring(value or ""))
    end
    local function isGameShootSound(id, name)
        local token = soundToken(id) .. " " .. soundToken(name)
        for _, key in {
            "fire", "shoot", "shot", "gun", "rifle", "pistol", "shotgun", "sniper", "suppress", "muzzle",
            "blast", "bolt", "pump", "cycle", "shell", "carbine", "pdw", "lmg", "dmr",
        } do
            if string.find(token, key, 1, true) then
                return true
            end
        end
        return false
    end
    local function isGameHitSound(id, name)
        local token = soundToken(id) .. " " .. soundToken(name)
        for _, key in {
            "hit", "impact", "flesh", "body", "head", "blood", "ricochet", "whiz", "crack", "material",
        } do
            if string.find(token, key, 1, true) then
                return true
            end
        end
        return false
    end

    local audio = Modules and Modules.AudioSystem
    if audio then
        local function wrapAudio(fnName)
            local nextFn = audio[fnName]
            if type(nextFn) ~= "function" then
                return
            end
            audio[fnName] = function(...)
                local args = table.pack(...)
                local id, name
                for i = 1, args.n do
                    local value = args[i]
                    if type(value) == "string" then
                        if not id and (string.find(value, "rbxasset", 1, true) or string.find(value, "http", 1, true)) then
                            id = value
                        elseif not name then
                            name = value
                        end
                    elseif typeof(value) == "Instance" and value:IsA("Sound") then
                        id = id or value.SoundId
                        name = name or value.Name
                    end
                end
                local tracers = env.Tracers
                if Config.ShootSounds and Config.MuteGameShootSounds and isGameShootSound(id, name) then
                    playShootSound(false, true)
                    return
                end
                if tracers and tracers.Config and tracers.Config.HitSounds and tracers.Config.MuteGameHitSounds and isGameHitSound(id, name) then
                    if tracers.PlayHitSound then
                        tracers.PlayHitSound(true)
                    end
                    return
                end
                return nextFn(...)
            end
            table.insert(Restores, function()
                audio[fnName] = nextFn
            end)
        end
        wrapAudio("playSoundId")
        wrapAudio("playSound")
        wrapAudio("play")
    end

    local lastFireCount, lastFireWeapon, lastShotAt = nil, nil, 0
    local function noteShot(source)
        if not Config.ShootSounds then
            return
        end
        local now = os.clock()
        if now - lastShotAt < 0.012 then
            return
        end
        lastShotAt = now
        playShootSound(false, true)
    end
    table.insert(Connections, RunService.RenderStepped:Connect(function()
        if not Config.ShootSounds then
            lastFireCount, lastFireWeapon = nil, nil
            return
        end
        local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
        local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
        if not weapon then
            lastFireCount, lastFireWeapon = nil, nil
            return
        end
        local count = tonumber(weapon._fireCount) or tonumber(weapon._shotCount) or tonumber(weapon._bulletsFired)
        if typeof(count) ~= "number" then
            return
        end
        if weapon ~= lastFireWeapon then
            lastFireWeapon = weapon
            lastFireCount = count
            return
        end
        if lastFireCount == nil then
            lastFireCount = count
            return
        end
        if count > lastFireCount then
            local shots = math.min(count - lastFireCount, 12)
            lastFireCount = count
            for _ = 1, shots do
                noteShot("fireCount")
            end
        elseif count < lastFireCount then
            lastFireCount = count
        end
    end))

    if Modules and Modules.NetworkClient and type(Modules.NetworkClient.send) == "function" then
        local network = Modules.NetworkClient
        local nextSend = network.send
        local reverseTime = false
        local lastRepTime = nil
        local shootSend = function(self, name, ...)
            if Config.ShootSounds and (name == "newbullets" or name == "newshot" or name == "shoot" or name == "fire") then
                noteShot(name)
            end
            if name == "repupdate" and Config.MovementBypass then
                local fromExecutor = false
                if checkcaller then
                    local okCaller, isCaller = pcall(checkcaller)
                    fromExecutor = okCaller and isCaller and true or false
                end
                if not fromExecutor then
                    local args = { ... }
                    local newTime = args[4]
                    if typeof(newTime) == "number" then
                        if not reverseTime then
                            lastRepTime = newTime
                        end
                        if lastRepTime and (newTime - lastRepTime) > (1 / 60) then
                            reverseTime = false
                            lastRepTime = newTime
                        end
                        reverseTime = not reverseTime
                        args[4] = lastRepTime or newTime
                        return nextSend(self, name, table.unpack(args))
                    end
                end
            end
            return nextSend(self, name, ...)
        end
        network.send = shootSend
        table.insert(Restores, function()
            if network.send == shootSend then
                network.send = nextSend
            end
        end)
    end
    if Modules and Modules.BulletObject and type(Modules.BulletObject.new) == "function" then
        local nextNew = Modules.BulletObject.new
        local shootNew = function(data, ...)
            if Config.ShootSounds and type(data) == "table" then
                noteShot("bullet")
            end
            return nextNew(data, ...)
        end
        Modules.BulletObject.new = shootNew
        table.insert(Restores, function()
            if Modules.BulletObject.new == shootNew then
                Modules.BulletObject.new = nextNew
            end
        end)
    end
    if Modules and Modules.Effects and type(Modules.Effects.muzzleflash) == "function" then
        local nextFlash = Modules.Effects.muzzleflash
        Modules.Effects.muzzleflash = function(...)
            if Config.ShootSounds then
                noteShot("muzzle")
            end
            return nextFlash(...)
        end
        table.insert(Restores, function()
            Modules.Effects.muzzleflash = nextFlash
        end)
    end
else
    table.insert(Connections, RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            return
        end
        if Config.WalkSpeed then
            humanoid.WalkSpeed = Config.SetSpeed
        end
        if Config.JumpPower then
            humanoid.JumpPower = 50 + Config.HeightAddition * 2
            humanoid.JumpHeight = 7.2 + Config.HeightAddition
        end
        if Config.BunnyHop and humanoid.FloorMaterial ~= Enum.Material.Air then
            if not Config.OnlyWhileJumping or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                local root = character:FindFirstChild("HumanoidRootPart")
                local move = humanoid.MoveDirection
                if root and move.Magnitude > 0.1 then
                    local vel = root.AssemblyLinearVelocity
                    local keep = Vector3.new(vel.X, 0, vel.Z)
                    if keep.Magnitude < move.Magnitude * humanoid.WalkSpeed * 0.85 then
                        local boost = move.Unit * math.max(humanoid.WalkSpeed, keep.Magnitude)
                        root.AssemblyLinearVelocity = Vector3.new(boost.X, vel.Y, boost.Z)
                    end
                end
                humanoid.Jump = true
            end
        end
    end))
    local smoothWish = Vector3.zero
    local lastGroundSnap = 0
    local circleCenter = nil
    local circleAngle = 0
    local hiddenDecals = {}
    local decalQueue = {}
    local decalIndex = 1
    local decalListedAt = 0
    local hiddenHud = {}
    local hiddenEnemies = {}
    local removalTick = 0
    local function rootPartOf(object)
        if not object then
            return nil
        end
        local ok, part = pcall(function()
            if object.getRealRootPart then
                return object:getRealRootPart()
            end
            if object.getRootPart then
                return object:getRootPart()
            end
            return object._rootPart
        end)
        if ok and typeof(part) == "Instance" and part:IsA("BasePart") then
            return part
        end
        return nil
    end
    local function wishDirection(cam)
        local look = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
        local right = cam and cam.CFrame.RightVector or Vector3.new(1, 0, 0)
        local wish = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            wish += look
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            wish -= look
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            wish += right
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            wish -= right
        end
        wish = Vector3.new(wish.X, 0, wish.Z)
        if wish.Magnitude > 1e-3 then
            return wish.Unit
        end
        return Vector3.zero
    end
    table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
        dt = math.clamp(dt or 0.016, 0, 0.05)
        local object = charInterface and charInterface.getCharacterObject and charInterface.getCharacterObject()
        local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
        local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
        local classify = (getgenv().Aim and getgenv().Aim.Classify) or (env.Aim and env.Aim.Classify)
        local className = type(classify) == "function" and classify(weapon) or nil
        if className then
            getgenv().TapologyWeaponClass = className
        end
        if Config.NoStamina and object then
            pcall(function()
                if object._maxStamina ~= nil and object._stamina ~= nil then
                    object._stamina = object._maxStamina
                elseif object._stamina ~= nil then
                    object._stamina = 1
                end
                if object._sprintCooldown ~= nil then
                    object._sprintCooldown = 0
                end
            end)
        end
        if Config.NoMoveCooldown and object then
            pcall(function()
                object._moveCooldown = 0
                object._jumpCooldown = 0
                object._nextJump = 0
                object._lastJumpTime = 0
                object._lastLandTime = 0
                object.dived = false
                object.sprintDisabled = false
            end)
        end
        local root = rootPartOf(object)
        if Config.WalkSpeed then
            local speed = math.clamp(tonumber(Config.SetSpeed) or 50, 1, 200)
            if Config.SlideBoost and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                speed = math.clamp(speed + (tonumber(Config.SlideBoostSpeed) or 70), 1, 200)
            end
            pcall(function()
                if object and object._speed ~= nil then
                    object._speed = math.max(tonumber(object._speed) or 0, speed)
                end
                if object and object._baseWalkSpeed ~= nil then
                    object._baseWalkSpeed = speed
                end
                if object and type(object.setBaseWalkSpeed) == "function" then
                    object:setBaseWalkSpeed(speed)
                end
            end)
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = speed
            end
        end
        if next(hiddenDecals) then
            local restored = 0
            for inst, transparency in hiddenDecals do
                hiddenDecals[inst] = nil
                if typeof(inst) == "Instance" and inst.Parent then
                    inst.Transparency = transparency
                end
                restored += 1
                if restored >= 40 then
                    break
                end
            end
        end
        local nowTick = os.clock()
        if Config.RemoveArms and object and nowTick - (rawget(object, "_tapologyArmHideAt") or 0) >= 0.15 then
            rawset(object, "_tapologyArmHideAt", nowTick)
            pcall(function()
                local function hideArm(model)
                    if typeof(model) ~= "Instance" then
                        return
                    end
                    for _, desc in model:GetDescendants() do
                        if desc:IsA("BasePart") or desc:IsA("Decal") or desc:IsA("Texture") then
                            local lower = string.lower(desc.Name)
                            if string.find(lower, "weapon", 1, true)
                                or string.find(lower, "gun", 1, true)
                                or string.find(lower, "barrel", 1, true)
                                or string.find(lower, "sight", 1, true)
                                or string.find(lower, "mag", 1, true)
                                or string.find(lower, "stock", 1, true)
                            then
                                continue
                            end
                            desc.LocalTransparencyModifier = 1
                        end
                    end
                end
                hideArm(object._leftArmModel)
                hideArm(object._rightArmModel)
            end)
        end
        if Config.RemoveAnimations and object and object._humanoid and nowTick - (rawget(object, "_tapologyAnimAt") or 0) >= 0.2 then
            rawset(object, "_tapologyAnimAt", nowTick)
            pcall(function()
                for _, track in object._humanoid:GetPlayingAnimationTracks() do
                    local name = string.lower(track.Name)
                    if string.find(name, "reload", 1, true) or string.find(name, "equip", 1, true) or string.find(name, "inspect", 1, true) or string.find(name, "sprint", 1, true) then
                        track:Stop(0)
                    end
                end
            end)
        end
        if nowTick - removalTick > 0.3 and (Config.RemoveEnemy or Config.RemoveTeam or Config.RemoveExplosions or Config.RemoveDroppedGuns) then
            removalTick = nowTick
            local folder = workspace:FindFirstChild("Players")
            if folder and (Config.RemoveEnemy or Config.RemoveTeam) then
                for _, player in Players:GetPlayers() do
                    if player ~= LocalPlayer then
                        local same = LocalPlayer.TeamColor and player.TeamColor == LocalPlayer.TeamColor
                        local hide = (Config.RemoveEnemy and not same) or (Config.RemoveTeam and same)
                        local model = folder:FindFirstChild(player.Name)
                        if hide and model then
                            for _, desc in model:GetDescendants() do
                                if desc:IsA("BasePart") and hiddenEnemies[desc] == nil then
                                    hiddenEnemies[desc] = desc.LocalTransparencyModifier
                                    desc.LocalTransparencyModifier = 1
                                end
                            end
                        end
                    end
                end
            end
            if Config.RemoveExplosions then
                local ignoreFolder = workspace:FindFirstChild("Ignore")
                if ignoreFolder then
                    for _, desc in ignoreFolder:GetChildren() do
                        local lower = string.lower(desc.Name)
                        if string.find(lower, "explosion", 1, true) or string.find(lower, "blast", 1, true) then
                            for _, effect in desc:GetDescendants() do
                                if effect:IsA("ParticleEmitter") or effect:IsA("Fire") or effect:IsA("Smoke") then
                                    effect.Enabled = false
                                end
                            end
                        end
                    end
                end
            end
            if Config.RemoveDroppedGuns then
                local ignoreFolder = workspace:FindFirstChild("Ignore")
                local dropped = ignoreFolder and ignoreFolder:FindFirstChild("Dropped")
                if dropped then
                    for _, desc in dropped:GetDescendants() do
                        if desc:IsA("BasePart") then
                            desc.LocalTransparencyModifier = 1
                        end
                    end
                end
            end
        elseif not Config.RemoveEnemy and not Config.RemoveTeam and next(hiddenEnemies) then
            for inst, modifier in hiddenEnemies do
                hiddenEnemies[inst] = nil
                if typeof(inst) == "Instance" and inst.Parent then
                    inst.LocalTransparencyModifier = modifier
                end
            end
        end
        local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local hideChat = hudOn("chat")
        local hideKillfeed = hudOn("killfeed")
        if playerGui and (hideChat or hideKillfeed) then
            for _, child in playerGui:GetChildren() do
                local lower = string.lower(child.Name)
                local match = (hideChat and string.find(lower, "chat", 1, true))
                    or (hideKillfeed and (string.find(lower, "kill", 1, true) or string.find(lower, "feed", 1, true)))
                if match and child:IsA("ScreenGui") then
                    if hiddenHud[child] == nil then
                        hiddenHud[child] = child.Enabled
                    end
                    child.Enabled = false
                end
            end
        elseif next(hiddenHud) then
            for gui, enabled in hiddenHud do
                hiddenHud[gui] = nil
                if typeof(gui) == "Instance" and gui.Parent then
                    gui.Enabled = enabled
                end
            end
        end
        if Config.HeightBypass and root then
            local now = os.clock()
            local waitFor = math.clamp(tonumber(Config.HeightBypassTime) or 1.5, 0.2, 8)
            if now - lastGroundSnap >= waitFor then
                lastGroundSnap = now
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = { root, workspace.CurrentCamera }
                local hit = workspace:Raycast(root.Position, Vector3.new(0, -500, 0), params)
                if hit and (root.Position.Y - hit.Position.Y) > 18 then
                    root.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3.5, 0)) * (root.CFrame - root.CFrame.Position)
                end
            end
        end
    end))
end

do
    local function barLayout(gap, length, thick)
        return {
            { Name = "top", X = 40, Y = 40 - gap - length / 2, W = thick, H = length, Vertical = true, Flip = true },
            { Name = "right", X = 40 + gap + length / 2, Y = 40, W = length, H = thick, Vertical = false, Flip = false },
            { Name = "bottom", X = 40, Y = 40 + gap + length / 2, W = thick, H = length, Vertical = true, Flip = false },
            { Name = "left", X = 40 - gap - length / 2, Y = 40, W = length, H = thick, Vertical = false, Flip = true },
        }
    end

    local function applyBarEdgeFade(grad, fadeIn, fadeOut, flip)
        local inner = math.clamp(tonumber(fadeIn) or 0, 0, 1)
        local outer = math.clamp(tonumber(fadeOut) or 0, 0, 1)
        if flip then
            grad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, outer),
                NumberSequenceKeypoint.new(0.55, math.min(inner, outer) * 0.3),
                NumberSequenceKeypoint.new(1, inner),
            })
        else
            grad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, inner),
                NumberSequenceKeypoint.new(0.45, math.min(inner, outer) * 0.3),
                NumberSequenceKeypoint.new(1, outer),
            })
        end
    end

    -- Nesting under gethui()/RobloxGui does not paint; mount like Tapology UI on CoreGui.
    local overlayParent = game:GetService("CoreGui")
    do
        local ok = pcall(function()
            local probe = Instance.new("Folder")
            probe.Parent = overlayParent
            probe:Destroy()
        end)
        if not ok then
            local host = gethui and select(2, pcall(gethui))
            if typeof(host) == "Instance" then
                overlayParent = host
            else
                local pg = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
                if pg then
                    overlayParent = pg
                end
            end
        end
    end

    local crossGui = Instance.new("ScreenGui")
    crossGui.Name = "TapologyCrosshair"
    crossGui.IgnoreGuiInset = true
    crossGui.ResetOnSpawn = false
    crossGui.DisplayOrder = 190
    crossGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    crossGui.Parent = overlayParent
    local crossHolder = Instance.new("Frame")
    crossHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    crossHolder.BackgroundTransparency = 1
    crossHolder.Size = UDim2.fromOffset(80, 80)
    crossHolder.Visible = false
    crossHolder.Parent = crossGui
    local crossBars = {}
    for i = 1, 4 do
        local bar = Instance.new("Frame")
        bar.Name = "Bar" .. i
        bar.AnchorPoint = Vector2.new(0.5, 0.5)
        bar.BorderSizePixel = 0
        bar.Parent = crossHolder
        local grad = Instance.new("UIGradient")
        grad.Parent = bar
        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.LineJoinMode = Enum.LineJoinMode.Miter
        stroke.Thickness = 1
        stroke.Enabled = false
        stroke.Parent = bar
        crossBars[i] = bar
    end
    bindStep("TapologyCrosshair", Enum.RenderPriority.Camera.Value + 120, function()
        local cam = camera()
        crossHolder.Visible = Config.Crosshair and cam ~= nil
        if not crossHolder.Visible or not cam then
            return
        end
        if Config.CrosshairMode == "ingame" then
            local mouse = UserInputService:GetMouseLocation()
            crossHolder.Position = UDim2.fromOffset(mouse.X, mouse.Y)
        else
            crossHolder.Position = UDim2.fromScale(0.5, 0.5)
        end
        local bounce = math.sin(os.clock() * (tonumber(Config.CrosshairBounceSpeed) or 6)) * (tonumber(Config.CrosshairBounce) or 0)
        local gap = math.max(0, (tonumber(Config.CrosshairGap) or 4) + bounce)
        local length = math.clamp(tonumber(Config.CrosshairLength) or 8, 1, 40)
        local thick = math.clamp(tonumber(Config.CrosshairThickness) or 2, 1, 8)
        crossHolder.Rotation = os.clock() * (tonumber(Config.CrosshairSpinSpeed) or 0) * (tonumber(Config.CrosshairSpin) or 0)
        local colors = { Config.CrosshairColor1, Config.CrosshairColor2, Config.CrosshairColor3, Config.CrosshairColor4 }
        local fadeIn = Config.CrosshairFadeIn
        local fadeOut = Config.CrosshairFadeOut
        local outlineOn = Config.CrosshairOutline == true
        local outlineColor = Config.CrosshairOutlineColor or Color3.new(0, 0, 0)
        local layout = barLayout(gap, length, thick)
        for i = 1, 4 do
            local bar = crossBars[i]
            local spot = layout[i]
            bar.Position = UDim2.fromOffset(spot.X, spot.Y)
            bar.Size = UDim2.fromOffset(spot.W, spot.H)
            bar.BackgroundColor3 = colors[i] or Color3.new(1, 1, 1)
            local grad = bar:FindFirstChildOfClass("UIGradient")
            if grad then
                grad.Rotation = spot.Vertical and 90 or 0
                applyBarEdgeFade(grad, fadeIn, fadeOut, spot.Flip)
            end
            local stroke = bar:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Enabled = outlineOn
                stroke.Color = outlineColor
            end
        end
    end)

    local hitGui = Instance.new("ScreenGui")
    hitGui.Name = "TapologyHitMarkers"
    hitGui.IgnoreGuiInset = true
    hitGui.ResetOnSpawn = false
    hitGui.DisplayOrder = 200
    hitGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    hitGui.Parent = overlayParent
    local activeHitMarkers = {}

    local function hitModes()
        local raw = Config.HitMarkerModes
        local out = { ["2d"] = false, ["3d"] = false }
        if type(raw) == "table" then
            for key, value in raw do
                if type(key) == "string" and value == true then
                    out[string.lower(key)] = true
                elseif type(value) == "string" then
                    out[string.lower(value)] = true
                end
            end
        elseif type(raw) == "string" then
            out[string.lower(raw)] = true
        end
        if not out["2d"] and not out["3d"] then
            out["2d"] = true
        end
        return out
    end

    local function buildMarkerBars(parent)
        local holder = Instance.new("Frame")
        holder.Name = "Marker"
        holder.AnchorPoint = Vector2.new(0.5, 0.5)
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.fromOffset(80, 80)
        holder.Rotation = 45
        holder.Parent = parent
        local bars = {}
        for i = 1, 4 do
            local bar = Instance.new("Frame")
            bar.Name = "Bar" .. i
            bar.AnchorPoint = Vector2.new(0.5, 0.5)
            bar.BorderSizePixel = 0
            bar.Parent = holder
            Instance.new("UIGradient").Parent = bar
            local stroke = Instance.new("UIStroke")
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            stroke.LineJoinMode = Enum.LineJoinMode.Miter
            stroke.Thickness = 1
            stroke.Enabled = false
            stroke.Parent = bar
            bars[i] = bar
        end
        return holder, bars
    end

    local function paintMarker(holder, bars, lifeAlpha)
        lifeAlpha = math.clamp(tonumber(lifeAlpha) or 1, 0, 1)
        local gap = math.max(0, tonumber(Config.HitMarkerGap) or 4)
        local length = math.clamp(tonumber(Config.HitMarkerLength) or 10, 1, 40)
        local thick = math.clamp(tonumber(Config.HitMarkerThickness) or 2, 1, 8)
        local colors = {
            Config.HitMarkerColor1,
            Config.HitMarkerColor2,
            Config.HitMarkerColor3,
            Config.HitMarkerColor4,
        }
        local alphas = {
            Config.HitMarkerAlpha1,
            Config.HitMarkerAlpha2,
            Config.HitMarkerAlpha3,
            Config.HitMarkerAlpha4,
        }
        local fadeIn = Config.HitMarkerFadeIn
        local fadeOut = Config.HitMarkerFadeOut
        local outlineOn = Config.HitMarkerOutline == true
        local outlineColor = Config.HitMarkerOutlineColor or Color3.new(0, 0, 0)
        local layout = barLayout(gap, length, thick)
        holder.Size = UDim2.fromOffset(80, 80)
        holder.Rotation = 45
        for i = 1, 4 do
            local spot = layout[i]
            local bar = bars[i]
            local alpha = math.clamp(tonumber(alphas[i]) or 1, 0, 1) * lifeAlpha
            bar.Visible = true
            bar.Position = UDim2.fromOffset(spot.X, spot.Y)
            bar.Size = UDim2.fromOffset(spot.W, spot.H)
            bar.BackgroundColor3 = colors[i] or Color3.new(1, 1, 1)
            bar.BackgroundTransparency = 1 - alpha
            local grad = bar:FindFirstChildOfClass("UIGradient")
            if grad then
                grad.Rotation = spot.Vertical and 90 or 0
                applyBarEdgeFade(grad, fadeIn, fadeOut, spot.Flip)
            end
            local stroke = bar:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Enabled = outlineOn and alpha > 0.05
                stroke.Color = outlineColor
                stroke.Transparency = 1 - alpha
            end
        end
    end

    local function resolveHitPos(player, part)
        local pos
        if typeof(part) == "Instance" and part:IsA("BasePart") then
            pos = part.Position
        elseif typeof(part) == "Vector3" then
            pos = part
        end
        local char = typeof(player) == "Instance" and player:IsA("Player") and player.Character
        if not pos and typeof(part) == "string" and char then
            local named = char:FindFirstChild(part) or char:FindFirstChild(part, true)
            if named and named:IsA("BasePart") then
                pos = named.Position
            end
        end
        if not pos and typeof(player) == "Instance" and player:IsA("Player") then
            pcall(function()
                local modules = env._TapologyModules
                local rep = modules and modules.ReplicationInterface
                local entry = rep and (rep.getEntry and (rep.getEntry(rep, player) or rep.getEntry(player)))
                if type(entry) ~= "table" then
                    return
                end
                if typeof(part) == "string" then
                    local third = entry._thirdPersonObject
                    local model = third and (third._model or third.model)
                    if typeof(model) == "Instance" then
                        local named = model:FindFirstChild(part) or model:FindFirstChild(part, true)
                        if named and named:IsA("BasePart") then
                            pos = named.Position
                            return
                        end
                    end
                    local hash = entry._characterHash or entry._hash
                    local body = hash and hash[part]
                    if body and typeof(body) == "Instance" and body:IsA("BasePart") then
                        pos = body.Position
                        return
                    end
                end
                if typeof(entry._receivedPosition) == "Vector3" then
                    pos = entry._receivedPosition
                elseif typeof(entry.getPosition) == "function" then
                    local p = entry:getPosition()
                    if typeof(p) == "Vector3" then
                        pos = p
                    end
                end
            end)
        end
        if not pos and char then
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
            if root and root:IsA("BasePart") then
                pos = root.Position
            end
        end
        return pos
    end

    local function spawnOne(mode, worldPos)
        local duration = math.clamp(tonumber(Config.HitMarkerDuration) or 0.35, 0.05, 5)
        local born = os.clock()
        if mode == "3d" then
            if typeof(worldPos) ~= "Vector3" then
                return
            end
            local part = Instance.new("Part")
            part.Name = "TapologyHitMarkerAnchor"
            part.Anchored = true
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = false
            part.Transparency = 1
            part.Size = Vector3.new(0.2, 0.2, 0.2)
            part.CFrame = CFrame.new(worldPos)
            part.Parent = workspace.CurrentCamera or workspace
            local bill = Instance.new("BillboardGui")
            bill.Name = "TapologyHitMarker3D"
            bill.AlwaysOnTop = true
            bill.LightInfluence = 0
            bill.Size = UDim2.fromOffset(80, 80)
            bill.Adornee = part
            bill.Parent = part
            local holder, bars = buildMarkerBars(bill)
            holder.Position = UDim2.fromScale(0.5, 0.5)
            paintMarker(holder, bars, 1)
            table.insert(activeHitMarkers, {
                Mode = "3d",
                Born = born,
                Duration = duration,
                Part = part,
                Bill = bill,
                Holder = holder,
                Bars = bars,
                World = worldPos,
            })
        else
            local holder, bars = buildMarkerBars(hitGui)
            holder.Position = UDim2.fromScale(0.5, 0.5)
            paintMarker(holder, bars, 1)
            table.insert(activeHitMarkers, {
                Mode = "2d",
                Born = born,
                Duration = duration,
                Holder = holder,
                Bars = bars,
            })
        end
    end

    local function spawnHitMarker(worldPos)
        if not Config.HitMarkers then
            return
        end
        local modes = hitModes()
        if modes["2d"] then
            spawnOne("2d", worldPos)
        end
        if modes["3d"] then
            spawnOne("3d", worldPos)
        end
    end

    env._TapologyOnHitMarker = function(player, part)
        if not Config.HitMarkers then
            return
        end
        spawnHitMarker(resolveHitPos(player, part))
    end

    bindStep("TapologyHitMarkers", Enum.RenderPriority.Camera.Value + 121, function()
        local now = os.clock()
        local cam = workspace.CurrentCamera
        for i = #activeHitMarkers, 1, -1 do
            local marker = activeHitMarkers[i]
            local age = now - marker.Born
            local duration = marker.Duration or 0.35
            if age >= duration then
                if marker.Bill then
                    pcall(function()
                        marker.Bill:Destroy()
                    end)
                end
                if marker.Part then
                    pcall(function()
                        marker.Part:Destroy()
                    end)
                end
                if marker.Holder then
                    pcall(function()
                        marker.Holder:Destroy()
                    end)
                end
                table.remove(activeHitMarkers, i)
            else
                local life = 1 - (age / duration)
                paintMarker(marker.Holder, marker.Bars, life)
                if marker.Mode == "2d" and marker.Holder then
                    marker.Holder.Position = UDim2.fromScale(0.5, 0.5)
                elseif marker.Mode == "3d" and marker.Part and typeof(marker.World) == "Vector3" then
                    marker.Part.CFrame = CFrame.new(marker.World)
                    if cam then
                        local sp, visible = cam:WorldToViewportPoint(marker.World)
                        if marker.Bill then
                            marker.Bill.Enabled = visible ~= false and sp.Z > 0
                        end
                    end
                end
            end
        end
    end)

    table.insert(Restores, function()
        env._TapologyOnHitMarker = nil
        for _, marker in activeHitMarkers do
            if marker.Bill then
                pcall(function()
                    marker.Bill:Destroy()
                end)
            end
            if marker.Part then
                pcall(function()
                    marker.Part:Destroy()
                end)
            end
            if marker.Holder then
                pcall(function()
                    marker.Holder:Destroy()
                end)
            end
        end
        table.clear(activeHitMarkers)
        crossGui:Destroy()
        hitGui:Destroy()
    end)
end

Config.MovementBypass = Config.MovementBypass == true
Config.NoFallDamage = Config.NoFallDamage == true
Config.NoStamina = Config.NoStamina == true
Config.NoMoveCooldown = Config.NoMoveCooldown == true
Config.WalkSpeed = Config.WalkSpeed == true
Config.JumpPower = Config.JumpPower == true
Config.HeightBypass = Config.HeightBypass == true
Config.HideViewmodel = Config.HideViewmodel == true
Config.RemoveArms = Config.RemoveArms == true
print("[Tapology] Loaded bypasses")

env.Misc = {
    Config = Config,
    Available = Modules ~= nil,
    WeaponMaterials = {
        "ForceField",
        "Neon",
        "Glass",
        "SmoothPlastic",
        "Plastic",
        "Metal",
        "DiamondPlate",
        "Foil",
        "Ice",
        "Concrete",
        "Grass",
        "Fabric",
        "Wood",
        "Marble",
        "Granite",
        "Slate",
        "CorrodedMetal",
    },
    ShootSounds = (function()
        local names = {}
        for name in Config.ShootSoundIds do
            table.insert(names, name)
        end
        table.sort(names)
        return names
    end)(),
    PlayShootSound = function(force)
        local fn = env._TapologyPlayShootSound
        if type(fn) == "function" then
            return fn(force == nil and true or force)
        end
    end,
    Unload = function()
        for _, connection in Connections do
            connection:Disconnect()
        end
        table.clear(Connections)
        for _, name in BoundSteps do
            pcall(RunService.UnbindFromRenderStep, RunService, name)
        end
        table.clear(BoundSteps)
        for _, restore in Restores do
            pcall(restore)
        end
        table.clear(Restores)
        env.Misc = nil
    end,
}

end
do

local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService = cloneref(game:GetService("HttpService"))
local Debris = cloneref(game:GetService("Debris"))

local Palette = {
    Pink = Color3.fromRGB(255, 105, 190),
    Deep = Color3.fromRGB(200, 30, 150),
    Core = Color3.fromRGB(255, 225, 245),
    Violet = Color3.fromRGB(160, 90, 255),
    Cyan = Color3.fromRGB(90, 220, 255),
    Gold = Color3.fromRGB(255, 195, 90),
    Ember = Color3.fromRGB(255, 110, 60),
    White = Color3.fromRGB(255, 255, 255),
}

local WingModes = { "Feather", "Ribbon", "Seraph" }

local Config = {
    RingSize = 11,
    SigilSize = 7,
    OrbCount = 3,
    OrbRadius = 3,
    LightningCount = 3,
    RippleInterval = 1.6,
    AfterimageSpacing = 1.1,
    AfterimageOffset = 0.4,
    AfterimageDuration = 2,
    AfterimageOpacity = 0.55,
    AfterimageThroughWalls = true,
    AfterimageWallStrength = 0.6,
    FootstepStride = 2.2,
    FootstepHold = 0.7,
    FootstepFade = 1.3,
    WingMode = "Feather",
    Modifier = Enum.KeyCode.LeftAlt,
    WingModeKey = Enum.KeyCode.Q,
    AllKey = Enum.KeyCode.Zero,
    Keybinds = {
        ["Afterimages"] = Enum.KeyCode.A,
        ["Sky Beam"] = Enum.KeyCode.B,
        ["Ground Cracks"] = Enum.KeyCode.C,
        ["Limb Motes"] = Enum.KeyCode.D,
        ["Energy Rings"] = Enum.KeyCode.E,
        ["Flames"] = Enum.KeyCode.F,
        ["Ground Glow"] = Enum.KeyCode.G,
        ["Halo"] = Enum.KeyCode.H,
        ["Inner Runes"] = Enum.KeyCode.I,
        ["Sparks"] = Enum.KeyCode.J,
        ["Footsteps"] = Enum.KeyCode.K,
        ["Light Pillars"] = Enum.KeyCode.L,
        ["Mandala"] = Enum.KeyCode.M,
        ["Embers"] = Enum.KeyCode.N,
        ["Orbs"] = Enum.KeyCode.O,
        ["Petals"] = Enum.KeyCode.P,
        ["Rune Circle"] = Enum.KeyCode.R,
        ["Sigil"] = Enum.KeyCode.S,
        ["Lightning"] = Enum.KeyCode.T,
        ["Tendrils"] = Enum.KeyCode.U,
        ["Ground Vortex"] = Enum.KeyCode.V,
        ["Wings"] = Enum.KeyCode.W,
        ["Hex Grid"] = Enum.KeyCode.X,
        ["Ripple"] = Enum.KeyCode.Y,
        ["Haze"] = Enum.KeyCode.Z,
        ["Wisps"] = Enum.KeyCode.One,
        ["Pulse Sphere"] = Enum.KeyCode.Two,
        ["Aura Light"] = Enum.KeyCode.Three,
        ["Helix"] = Enum.KeyCode.Four,
        ["Atom Orbits"] = Enum.KeyCode.Five,
        ["Crystal Orbit"] = Enum.KeyCode.Six,
        ["Comet"] = Enum.KeyCode.Seven,
        ["Floating Runes"] = Enum.KeyCode.Eight,
        ["Star Field"] = Enum.KeyCode.Nine,
    },
    TextureFolder = "aura_textures",
}

local TextureIds

local env = getgenv and getgenv() or _G
if env.Aura then
    env.Aura.Unload()
end

local LocalPlayer = Players.LocalPlayer
local HighlightParent = gethui and gethui() or cloneref(game:GetService("CoreGui"))
local base64decode = (crypt and crypt.base64decode) or base64_decode or (base64 and base64.decode)
local SettingsPath = `{Config.TextureFolder}/settings.json`
local rng = Random.new()

local Textures = {}
local Connections = {}
local Effects = {}
local EffectsByName = {}
local Enabled = {}
local Colors = {}
local Current
local Unloaded = false

local function create(className, props)
    local instance = Instance.new(className)
    for key, value in props do
        if key ~= "Parent" then
            instance[key] = value
        end
    end
    instance.Parent = props.Parent
    return instance
end

local function numberSequence(points)
    local keypoints = {}
    for _, point in points do
        table.insert(keypoints, NumberSequenceKeypoint.new(point[1], point[2], point[3] or 0))
    end
    return NumberSequence.new(keypoints)
end

local function colorSequence(points)
    local keypoints = {}
    for _, point in points do
        table.insert(keypoints, ColorSequenceKeypoint.new(point[1], point[2]))
    end
    return ColorSequence.new(keypoints)
end

local function newPart(name, size, parent)
    return create("Part", {
        Name = name,
        Size = size,
        Anchored = true,
        CanCollide = false,
        CanQuery = false,
        CanTouch = false,
        CastShadow = false,
        Transparency = 1,
        Parent = parent,
    })
end

local function newSurfaceImage(part, face, texture, color, transparency, brightness)
    local gui = create("SurfaceGui", {
        Face = face,
        LightInfluence = 0,
        Brightness = brightness or 2,
        SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
        PixelsPerStud = 40,
        Parent = part,
    })
    return create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Image = texture,
        ImageColor3 = color or Palette.White,
        ImageTransparency = transparency or 0,
        Parent = gui,
    })
end

local function emitter(parent, props)
    props.LightEmission = props.LightEmission or 1
    props.LightInfluence = 0
    props.Parent = parent
    return create("ParticleEmitter", props)
end

local function cloneGhost(part)
    local wasArchivable = part.Archivable
    part.Archivable = true
    local ghost = part:Clone()
    part.Archivable = wasArchivable

    for _, child in ghost:GetChildren() do
        if child:IsA("SpecialMesh") then
            child.TextureId = ""
        elseif not child:IsA("DataModelMesh") then
            child:Destroy()
        end
    end
    if ghost:IsA("MeshPart") then
        ghost.TextureID = ""
    end

    ghost.Anchored = true
    ghost.CanCollide = false
    ghost.CanQuery = false
    ghost.CanTouch = false
    ghost.CastShadow = false
    return ghost
end

local function hash(text)
    local h = 0
    for i = 1, #text do
        h = (h * 31 + string.byte(text, i)) % 4294967291
    end
    return string.format("%08x", h)
end

local function loadTextures()
    for name, id in TextureIds do
        Textures[name] = id
    end
end

local function resolveAuraHost()
    local host = env.TapologyAuraHost
    if type(host) == "table" and typeof(host.Root) == "Instance" and host.Root:IsA("BasePart") and host.Root.Parent then
        return host
    end
    return nil
end

local function groundCFrame(build)
    local root = build.Root
    local ignore = { build.Character, build.Container, workspace.CurrentCamera }
    for _, name in ipairs({ "Ignore", "Players", "Effects", "Temporary", "Rain", "Weather" }) do
        local folder = workspace:FindFirstChild(name)
        if folder then
            table.insert(ignore, folder)
        end
    end
    build.RayParams.FilterDescendantsInstances = ignore
    local result = workspace:Raycast(root.Position + Vector3.new(0, 6, 0), Vector3.new(0, -80, 0), build.RayParams)

    for _ = 1, 6 do
        if not result then
            break
        end
        local model = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
        local characterish = model and (
            model:FindFirstChild("Cosmetics")
            or model:FindFirstChildOfClass("Humanoid")
            or (model:FindFirstChild("Torso") and model:FindFirstChild("Head"))
        )
        if not characterish then
            break
        end
        table.insert(ignore, model or result.Instance)
        build.RayParams.FilterDescendantsInstances = ignore
        result = workspace:Raycast(root.Position + Vector3.new(0, 6, 0), Vector3.new(0, -80, 0), build.RayParams)
    end

    local position, normal
    if result then
        position, normal = result.Position, result.Normal
    else
        local hip = (build.Humanoid and build.Humanoid.HipHeight) or 2
        position = root.Position - Vector3.new(0, hip + root.Size.Y / 2, 0)
        normal = Vector3.yAxis
    end

    local axis = Vector3.yAxis:Cross(normal)
    if axis.Magnitude < 1e-4 then
        return CFrame.new(position)
    end
    return CFrame.new(position) * CFrame.fromAxisAngle(axis.Unit, math.acos(math.clamp(normal.Y, -1, 1)))
end

local function slotColor(ctx, i)
    local slots = ctx.Slots
    return ctx.Colors[slots[(i - 1) % #slots + 1]]
end

local function blendSlots(ctx, x)
    local slots = ctx.Slots
    local f = x % #slots
    local i = math.floor(f)
    return ctx.Colors[slots[i + 1]]:Lerp(ctx.Colors[slots[(i + 1) % #slots + 1]], f - i)
end

local function groundLayer(ctx, opts)
    local size, offset = opts.Size, opts.Offset
    local part = newPart("Layer", Vector3.new(size, 0.05, size), ctx.Folder)
    local image = newSurfaceImage(part, Enum.NormalId.Top, opts.Texture, nil, 0, opts.Brightness)
    ctx.Bind(image, "ImageColor3", function(c) return c.Main end)

    ctx.Update = function(t)
        local scale = 1 + math.sin(t * 2.2 + offset * 50) * (opts.Pulse or 0)
        part.Size = Vector3.new(size * scale, 0.05, size * scale)
        part.CFrame = ctx.Build.Ground * CFrame.new(0, offset, 0)
        image.Rotation = (t * (opts.Spin or 0)) % 360
        if opts.Fade then
            image.ImageTransparency = opts.Fade(t)
        end
    end
end

local function orbitTrail(ctx, slot, opts)
    local parent = opts.Parent or ctx.Build.Root
    local a0 = ctx.Own(create("Attachment", { Name = "AuraOrbit", Parent = parent }))
    local a1 = ctx.Own(create("Attachment", { Name = "AuraOrbitTail", Parent = parent }))
    local coreSize = opts.CoreSize or 0.6

    ctx.Bind(emitter(a0, {
        Texture = Textures.glow,
        LockedToPart = true,
        Rate = 30,
        Lifetime = NumberRange.new(0.15, 0.25),
        Speed = NumberRange.new(0),
        Size = numberSequence({ { 0, coreSize }, { 1, coreSize * 0.6 } }),
        Transparency = numberSequence({ { 0, 0.15 }, { 1, 1 } }),
        Brightness = 6,
    }), "Color", function(c) return colorSequence({ { 0, Palette.White }, { 0.3, c[slot] }, { 1, c[slot] } }) end)

    local trail = ctx.Own(create("Trail", {
        Attachment0 = a0,
        Attachment1 = a1,
        Texture = Textures.trail,
        TextureMode = Enum.TextureMode.Stretch,
        Lifetime = opts.Lifetime or 0.35,
        MinLength = 0.05,
        FaceCamera = opts.FaceCamera ~= false,
        WidthScale = numberSequence({ { 0, 1 }, { 1, 0 } }),
        Transparency = numberSequence({ { 0, 0 }, { 1, 1 } }),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 4,
        Parent = parent,
    }))
    ctx.Bind(trail, "Color", function(c) return colorSequence({ { 0, Palette.White }, { 0.25, c[slot] }, { 1, c[slot] } }) end)

    return a0, a1, trail
end

local function effect(name, group, slots, build)
    local def = { Name = name, Group = group, Slots = {}, Defaults = {}, Build = build }
    Colors[name] = {}
    for _, slot in slots do
        table.insert(def.Slots, slot[1])
        def.Defaults[slot[1]] = slot[2]
        Colors[name][slot[1]] = slot[2]
    end
    table.insert(Effects, def)
    EffectsByName[name] = def
    Enabled[name] = false
end

effect("Hex Grid", "Ground", { { "Main", Palette.Violet } }, function(ctx)
    groundLayer(ctx, {
        Texture = Textures.hexgrid, Size = Config.RingSize * 1.7, Spin = 4, Offset = 0.01, Pulse = 0.02,
        Fade = function(t) return 0.25 + math.sin(t * 3) * 0.1 end,
    })
end)

effect("Ground Glow", "Ground", { { "Main", Palette.Pink } }, function(ctx)
    groundLayer(ctx, {
        Texture = Textures.glow, Size = Config.RingSize * 1.35, Offset = 0.02, Pulse = 0.06,
        Fade = function(t) return 0.45 + math.sin(t * 3) * 0.1 end,
    })
end)

effect("Ground Cracks", "Ground", { { "Main", Palette.Ember } }, function(ctx)
    groundLayer(ctx, {
        Texture = Textures.cracks, Size = Config.RingSize * 1.25, Spin = -2, Offset = 0.03, Brightness = 3,
        Fade = function(t) return 0.2 + (math.sin(t * 1.7) + 1) * 0.18 + rng:NextNumber(0, 0.06) end,
    })
end)

effect("Rune Circle", "Ground", { { "Main", Palette.Pink } }, function(ctx)
    groundLayer(ctx, { Texture = Textures.runes, Size = Config.RingSize, Spin = 12, Offset = 0.04, Pulse = 0.015 })
end)

effect("Sigil", "Ground", { { "Main", Palette.Pink } }, function(ctx)
    groundLayer(ctx, { Texture = Textures.sigil, Size = Config.SigilSize, Spin = -25, Offset = 0.06, Pulse = 0.04 })
end)

effect("Inner Runes", "Ground", { { "Main", Palette.Pink } }, function(ctx)
    groundLayer(ctx, {
        Texture = Textures.runes, Size = Config.SigilSize * 0.55, Spin = 40, Offset = 0.08, Pulse = 0.03,
        Fade = function(t) return 0.2 + math.sin(t * 3) * 0.1 end,
    })
end)

effect("Ground Vortex", "Ground", { { "A", Palette.Violet }, { "B", Palette.Cyan } }, function(ctx)
    local arms = {}
    for i = 1, 4 do
        local a0, a1, trail = orbitTrail(ctx, i % 2 == 1 and "A" or "B", {
            Parent = ctx.Build.Base, Lifetime = 0.5, CoreSize = 0.35, FaceCamera = false,
        })
        arms[i] = { A0 = a0, A1 = a1, Trail = trail, Offset = (i - 1) / 4, Last = 0 }
    end

    ctx.Update = function(t)
        for _, arm in arms do
            local h = (t * 0.5 + arm.Offset) % 1
            if h < arm.Last then
                arm.Trail:Clear()
            end
            arm.Last = h

            local radius = Config.RingSize * 0.55 * (1 - h) + 0.2
            local angle = h * math.pi * 3 + arm.Offset * math.pi * 2
            local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
            arm.A0.Position = direction * radius - Vector3.new(0, 0.05, 0)
            arm.A1.Position = direction * (radius + 0.3) - Vector3.new(0, 0.05, 0)
        end
    end
end)

effect("Ripple", "Ground", { { "Main", Palette.Pink } }, function(ctx)
    local nextAt = 0
    ctx.Update = function(t)
        if t < nextAt then return end
        nextAt = t + Config.RippleInterval

        local part = newPart("Ripple", Vector3.new(2, 0.05, 2), ctx.Folder)
        part.CFrame = ctx.Build.Ground * CFrame.new(0, 0.1, 0)
        local image = newSurfaceImage(part, Enum.NormalId.Top, Textures.shockwave, ctx.Colors.Main, 0.1)

        local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(part, info, { Size = Vector3.new(16, 0.05, 16) }):Play()
        TweenService:Create(image, info, { ImageTransparency = 1 }):Play()
        Debris:AddItem(part, 1)
    end
end)

effect("Energy Rings", "Ground", { { "A", Palette.Pink }, { "B", Palette.Violet }, { "C", Palette.Cyan } }, function(ctx)
    local rings, nextAt, index = {}, 0, 0
    local lifetime, rise = 1.4, 6

    ctx.Update = function(t)
        if t >= nextAt then
            nextAt = t + 0.45
            index += 1
            local color = slotColor(ctx, index)
            local part = newPart("Ring", Vector3.new(4.5, 0.05, 4.5), ctx.Folder)
            table.insert(rings, {
                Part = part,
                Born = t,
                Images = {
                    newSurfaceImage(part, Enum.NormalId.Top, Textures.shockwave, color, 1, 2.5),
                    newSurfaceImage(part, Enum.NormalId.Bottom, Textures.shockwave, color, 1, 2.5),
                },
            })
        end

        for i = #rings, 1, -1 do
            local ring = rings[i]
            local p = (t - ring.Born) / lifetime
            if p >= 1 then
                ring.Part:Destroy()
                table.remove(rings, i)
            else
                local size = 4.5 - p * 2.5
                ring.Part.Size = Vector3.new(size, 0.05, size)
                ring.Part.CFrame = ctx.Build.Ground * CFrame.new(0, 0.2 + p * rise, 0)
                local transparency = p < 0.15 and 1 - p / 0.15 * 0.8 or 0.2 + (p - 0.15) / 0.85 * 0.8
                for _, image in ring.Images do
                    image.ImageTransparency = transparency
                end
            end
        end
    end
end)

effect("Light Pillars", "Ground", { { "A", Palette.Pink }, { "B", Palette.Violet }, { "C", Palette.Cyan } }, function(ctx)
    local base = ctx.Build.Base
    local pillars = {}
    for i = 1, 6 do
        local a0 = ctx.Own(create("Attachment", { Parent = base }))
        local a1 = ctx.Own(create("Attachment", { Parent = base }))
        ctx.Bind(ctx.Own(create("Beam", {
            Attachment0 = a0,
            Attachment1 = a1,
            Texture = Textures.pillar,
            TextureMode = Enum.TextureMode.Stretch,
            Width0 = 0.9,
            Width1 = 0.5,
            Segments = 1,
            FaceCamera = true,
            Transparency = numberSequence({ { 0, 0.1 }, { 1, 0.4 } }),
            LightEmission = 1,
            LightInfluence = 0,
            Brightness = 4,
            Parent = base,
        })), "Color", function() return ColorSequence.new(slotColor(ctx, i)) end)
        table.insert(pillars, { A0 = a0, A1 = a1, Phase = (i - 1) / 6 * math.pi * 2 })
    end

    ctx.Update = function(t)
        local radius = Config.RingSize * 0.45
        for _, pillar in pillars do
            local angle = pillar.Phase + t * 0.6
            local position = Vector3.new(math.cos(angle) * radius, -0.1, math.sin(angle) * radius)
            pillar.A0.Position = position
            pillar.A1.Position = position + Vector3.new(0, 4 + math.sin(t * 2.5 + pillar.Phase * 3) * 1.5, 0)
        end
    end
end)

effect("Footsteps", "Ground", { { "Main", Palette.Pink } }, function(ctx)
    local build = ctx.Build
    local character = build.Character
    local feet = {
        character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg"),
        character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg"),
    }
    local steps, last, nextFoot = {}, nil, 1
    local lifetime = Config.FootstepHold + Config.FootstepFade

    local function placeStep(foot, t)
        local look = build.Root.CFrame.LookVector * Vector3.new(1, 0, 1)
        if not foot or look.Magnitude < 1e-3 then return end

        local result = workspace:Raycast(foot.Position + Vector3.new(0, 1, 0), Vector3.new(0, -4, 0), build.RayParams)
        if not result then return end

        local part = newPart("Step", Vector3.new(0.6, 0.05, 1.1), ctx.Folder)
        part.CFrame = CFrame.lookAt(result.Position, result.Position + look.Unit) * CFrame.new(0, 0.03, 0)
        local image = newSurfaceImage(part, Enum.NormalId.Top, Textures.footprint, ctx.Colors.Main, 0.05, 4)
        table.insert(steps, { Part = part, Image = image, Born = t })
    end

    ctx.Update = function(t)
        local position = build.Root.Position * Vector3.new(1, 0, 1)
        local grounded = build.Humanoid.FloorMaterial ~= Enum.Material.Air
        if not grounded then
            last = nil
        elseif not last or (position - last).Magnitude >= Config.FootstepStride then
            last = position
            placeStep(feet[nextFoot], t)
            nextFoot = 3 - nextFoot
        end

        for i = #steps, 1, -1 do
            local step = steps[i]
            local age = t - step.Born
            if age >= lifetime then
                step.Part:Destroy()
                table.remove(steps, i)
            elseif age > Config.FootstepHold then
                local p = (age - Config.FootstepHold) / Config.FootstepFade
                step.Image.ImageTransparency = 0.05 + 0.95 * p * p * (3 - 2 * p)
            end
        end
    end
end)

effect("Sky Beam", "Ground", { { "Main", Palette.White }, { "Top", Palette.Cyan } }, function(ctx)
    local beams, nextAt = {}, 1
    local lifetime = 0.9

    ctx.Update = function(t)
        if t >= nextAt then
            nextAt = t + 4
            local c = ctx.Colors
            local gradient = colorSequence({ { 0, c.Main }, { 1, c.Top } })
            local part = newPart("SkyBeam", Vector3.new(1, 1, 1), ctx.Folder)
            part.CFrame = ctx.Build.Ground
            local a0 = create("Attachment", { Parent = part })
            local a1 = create("Attachment", { Position = Vector3.new(0, 60, 0), Parent = part })
            local beam = create("Beam", {
                Attachment0 = a0,
                Attachment1 = a1,
                Texture = Textures.pillar,
                TextureMode = Enum.TextureMode.Stretch,
                Width0 = 0,
                Width1 = 0,
                Segments = 1,
                FaceCamera = true,
                Color = gradient,
                LightEmission = 1,
                LightInfluence = 0,
                Brightness = 8,
                Parent = part,
            })
            emitter(a0, {
                Texture = Textures.spark,
                Rate = 0,
                EmissionDirection = Enum.NormalId.Top,
                Lifetime = NumberRange.new(0.5, 0.9),
                Speed = NumberRange.new(8, 16),
                Drag = 3,
                SpreadAngle = Vector2.new(70, 70),
                Size = numberSequence({ { 0, 0.5 }, { 1, 0 } }),
                Color = gradient,
                Brightness = 6,
            }):Emit(30)
            table.insert(beams, { Part = part, Beam = beam, Born = t })
        end

        for i = #beams, 1, -1 do
            local entry = beams[i]
            local p = (t - entry.Born) / lifetime
            if p >= 1 then
                entry.Part:Destroy()
                table.remove(beams, i)
            else
                local width = math.sin(p * math.pi) * 3.5
                entry.Beam.Width0 = width
                entry.Beam.Width1 = width * 0.6
            end
        end
    end
end)

effect("Flames", "Body", { { "Main", Palette.Pink }, { "Core", Palette.Core }, { "Edge", Palette.Deep } }, function(ctx)
    ctx.Bind(ctx.Own(emitter(ctx.Build.Base, {
        Texture = Textures.flame,
        FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
        FlipbookMode = Enum.ParticleFlipbookMode.Loop,
        FlipbookFramerate = NumberRange.new(18, 26),
        FlipbookStartRandom = true,
        Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
        Shape = Enum.ParticleEmitterShape.Disc,
        EmissionDirection = Enum.NormalId.Top,
        Rate = 40,
        Lifetime = NumberRange.new(0.7, 1.2),
        Speed = NumberRange.new(2, 4),
        Acceleration = Vector3.new(0, 9, 0),
        Drag = 2,
        SpreadAngle = Vector2.new(15, 15),
        Rotation = NumberRange.new(-15, 15),
        RotSpeed = NumberRange.new(-30, 30),
        Size = numberSequence({ { 0, 0.8 }, { 0.3, 1.8, 0.3 }, { 1, 0.4 } }),
        Transparency = numberSequence({ { 0, 1 }, { 0.15, 0.15 }, { 0.7, 0.45 }, { 1, 1 } }),
        Brightness = 3,
        ZOffset = 0.5,
    })), "Color", function(c) return colorSequence({ { 0, c.Core }, { 0.4, c.Main }, { 1, c.Edge } }) end)
end)

effect("Sparks", "Body", { { "Main", Palette.Pink }, { "Core", Palette.Core } }, function(ctx)
    ctx.Bind(ctx.Own(emitter(ctx.Build.Base, {
        Texture = Textures.spark,
        Shape = Enum.ParticleEmitterShape.Disc,
        EmissionDirection = Enum.NormalId.Top,
        Rate = 18,
        Lifetime = NumberRange.new(1, 2),
        Speed = NumberRange.new(4, 9),
        Acceleration = Vector3.new(0, 3, 0),
        Drag = 1.5,
        SpreadAngle = Vector2.new(25, 25),
        RotSpeed = NumberRange.new(-200, 200),
        Size = numberSequence({ { 0, 0.35 }, { 0.5, 0.25 }, { 1, 0 } }),
        Transparency = numberSequence({ { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } }),
        Brightness = 5,
    })), "Color", function(c) return colorSequence({ { 0, c.Core }, { 1, c.Main } }) end)
end)

effect("Embers", "Body", { { "Main", Palette.Gold }, { "Fade", Palette.Ember } }, function(ctx)
    local area = newPart("Embers", Vector3.new(9, 0.2, 9), ctx.Folder)
    ctx.Bind(emitter(area, {
        Texture = Textures.glow,
        EmissionDirection = Enum.NormalId.Top,
        Rate = 25,
        Lifetime = NumberRange.new(2, 3.5),
        Speed = NumberRange.new(1, 3),
        Acceleration = Vector3.new(0, 2.5, 0),
        Drag = 0.6,
        SpreadAngle = Vector2.new(30, 30),
        Size = numberSequence({ { 0, 0.12 }, { 0.5, 0.18 }, { 1, 0 } }),
        Transparency = numberSequence({ { 0, 0.1 }, { 0.8, 0.3 }, { 1, 1 } }),
        Brightness = 6,
    }), "Color", function(c) return colorSequence({ { 0, c.Main }, { 1, c.Fade } }) end)

    ctx.Update = function()
        area.CFrame = ctx.Build.Ground * CFrame.new(0, 0.2, 0)
    end
end)

effect("Haze", "Body", { { "Main", Palette.Pink }, { "Edge", Palette.Deep } }, function(ctx)
    ctx.Bind(ctx.Own(emitter(ctx.Build.Base, {
        Texture = Textures.glow,
        Shape = Enum.ParticleEmitterShape.Disc,
        EmissionDirection = Enum.NormalId.Top,
        Rate = 6,
        Lifetime = NumberRange.new(1.5, 2.5),
        Speed = NumberRange.new(0.5, 1.5),
        Size = numberSequence({ { 0, 3 }, { 1, 6 } }),
        Transparency = numberSequence({ { 0, 1 }, { 0.3, 0.8 }, { 1, 1 } }),
        Brightness = 1.5,
    })), "Color", function(c) return colorSequence({ { 0, c.Main }, { 1, c.Edge } }) end)
end)

effect("Wisps", "Body", { { "Main", Palette.Pink }, { "Core", Palette.Core } }, function(ctx)
    ctx.Bind(ctx.Own(emitter(ctx.Build.Body, {
        Texture = Textures.wisp,
        EmissionDirection = Enum.NormalId.Top,
        Rate = 12,
        Lifetime = NumberRange.new(0.8, 1.4),
        Speed = NumberRange.new(1, 2),
        Acceleration = Vector3.new(0, 4, 0),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-60, 60),
        Size = numberSequence({ { 0, 0.6 }, { 0.4, 1.2 }, { 1, 0 } }),
        Transparency = numberSequence({ { 0, 1 }, { 0.2, 0.5 }, { 1, 1 } }),
        Brightness = 2,
    })), "Color", function(c) return colorSequence({ { 0, c.Core }, { 1, c.Main } }) end)
end)

effect("Limb Motes", "Body", { { "Main", Palette.Pink }, { "Core", Palette.Core } }, function(ctx)
    for _, part in ctx.Build.Character:GetChildren() do
        if part:IsA("BasePart") and part ~= ctx.Build.Root then
            ctx.Bind(ctx.Own(emitter(part, {
                Name = "AuraMotes",
                Texture = Textures.glow,
                Rate = 4,
                Lifetime = NumberRange.new(0.6, 1),
                Speed = NumberRange.new(0.5, 1.5),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, 2, 0),
                Size = numberSequence({ { 0, 0.25 }, { 1, 0 } }),
                Transparency = numberSequence({ { 0, 0.2 }, { 1, 1 } }),
                Brightness = 4,
            })), "Color", function(c) return colorSequence({ { 0, c.Core }, { 1, c.Main } }) end)
        end
    end
end)

effect("Lightning", "Body", { { "Main", Palette.Pink }, { "Core", Palette.Core } }, function(ctx)
    local body = ctx.Build.Body
    local bolts = {}
    for i = 1, Config.LightningCount do
        local a0 = ctx.Own(create("Attachment", { Parent = body }))
        local a1 = ctx.Own(create("Attachment", { Parent = body }))
        local beam = ctx.Own(create("Beam", {
            Attachment0 = a0,
            Attachment1 = a1,
            Texture = Textures.lightning,
            TextureMode = Enum.TextureMode.Wrap,
            TextureLength = 4,
            TextureSpeed = 3,
            Width0 = 0.7,
            Width1 = 0.4,
            Segments = 12,
            FaceCamera = true,
            Transparency = numberSequence({ { 0, 0 }, { 1, 0.3 } }),
            LightEmission = 1,
            LightInfluence = 0,
            Brightness = 6,
            Enabled = false,
            Parent = body,
        }))
        ctx.Bind(beam, "Color", function(c) return colorSequence({ { 0, c.Core }, { 1, c.Main } }) end)
        bolts[i] = { A0 = a0, A1 = a1, Beam = beam, Next = 0 }
    end

    ctx.Update = function(t)
        for _, bolt in bolts do
            if t >= bolt.Next then
                bolt.Next = t + rng:NextNumber(0.04, 0.14)
                local enabled = rng:NextNumber() < 0.55
                bolt.Beam.Enabled = enabled
                if enabled then
                    local angle = rng:NextNumber(0, math.pi * 2)
                    local reach = rng:NextNumber(3.2, 4.2)
                    bolt.A0.Position = rng:NextUnitVector() * rng:NextNumber(0.3, 1) + Vector3.new(0, 0.5, 0)
                    bolt.A1.Position = Vector3.new(math.cos(angle) * reach, rng:NextNumber(-2.5, 2), math.sin(angle) * reach)
                    bolt.Beam.CurveSize0 = rng:NextNumber(-3, 3)
                    bolt.Beam.CurveSize1 = rng:NextNumber(-3, 3)
                    bolt.Beam.Width0 = rng:NextNumber(0.4, 0.9)
                end
            end
        end
    end
end)

effect("Tendrils", "Body", { { "Root", Palette.Violet }, { "Tip", Palette.Pink } }, function(ctx)
    local base, body = ctx.Build.Base, ctx.Build.Body
    local tendrils = {}
    for i = 1, 5 do
        local phase = (i - 1) / 5 * math.pi * 2
        local radius = Config.RingSize * 0.42
        local a0 = ctx.Own(create("Attachment", {
            Position = Vector3.new(math.cos(phase) * radius, 0, math.sin(phase) * radius),
            Parent = base,
        }))
        local a1 = ctx.Own(create("Attachment", {
            Position = Vector3.new(math.cos(phase) * 0.4, 0.4, math.sin(phase) * 0.4),
            Parent = body,
        }))
        local beam = ctx.Own(create("Beam", {
            Attachment0 = a0,
            Attachment1 = a1,
            Texture = Textures.trail,
            TextureMode = Enum.TextureMode.Wrap,
            TextureLength = 3,
            TextureSpeed = -2,
            Width0 = 0.35,
            Width1 = 0.1,
            Segments = 20,
            FaceCamera = true,
            Transparency = numberSequence({ { 0, 0.2 }, { 1, 0.6 } }),
            LightEmission = 1,
            LightInfluence = 0,
            Brightness = 4,
            Parent = base,
        }))
        ctx.Bind(beam, "Color", function(c) return colorSequence({ { 0, c.Root }, { 1, c.Tip } }) end)
        tendrils[i] = { Beam = beam, Phase = phase }
    end

    ctx.Update = function(t)
        for _, tendril in tendrils do
            tendril.Beam.CurveSize0 = math.sin(t * 2 + tendril.Phase) * 3
            tendril.Beam.CurveSize1 = math.cos(t * 1.7 + tendril.Phase * 2) * 2
        end
    end
end)

effect("Pulse Sphere", "Body", { { "Main", Palette.Cyan } }, function(ctx)
    local spheres, nextAt = {}, 0.5
    local lifetime = 1.3

    ctx.Update = function(t)
        local root = ctx.Build.Root
        if t >= nextAt then
            nextAt = t + 2.4
            local part = newPart("PulseSphere", Vector3.new(2, 2, 2), ctx.Folder)
            part.Shape = Enum.PartType.Ball
            part.Material = Enum.Material.ForceField
            part.Color = ctx.Colors.Main
            table.insert(spheres, { Part = part, Born = t })
        end

        for i = #spheres, 1, -1 do
            local sphere = spheres[i]
            local p = (t - sphere.Born) / lifetime
            if p >= 1 then
                sphere.Part:Destroy()
                table.remove(spheres, i)
            else
                local size = 2 + 11 * (1 - (1 - p) ^ 3)
                sphere.Part.Size = Vector3.new(size, size, size)
                sphere.Part.CFrame = CFrame.new(root.Position)
                sphere.Part.Transparency = 0.1 + 0.9 * p
            end
        end
    end
end)

effect("Afterimages", "Body", { { "A", Palette.Pink }, { "B", Palette.Violet }, { "C", Palette.Cyan } }, function(ctx)
    local build = ctx.Build
    local sources = {}
    for _, part in build.Character:GetChildren() do
        if part:IsA("BasePart") and part ~= build.Root and part.Transparency < 1 then
            table.insert(sources, part)
        end
    end

    local duration = math.clamp(Config.AfterimageDuration, 0.05, 2)

    local viewport, viewportCamera
    if Config.AfterimageThroughWalls then
        local guiParent = HighlightParent:IsA("LayerCollector") and HighlightParent.Parent or HighlightParent
        local screen = ctx.Own(create("ScreenGui", {
            Name = "AuraAfterimages",
            IgnoreGuiInset = true,
            ResetOnSpawn = false,
            DisplayOrder = -1,
            Parent = guiParent,
        }))
        viewportCamera = create("Camera", { Parent = screen })
        viewport = create("ViewportFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Ambient = Color3.new(1, 1, 1),
            LightColor = Color3.new(0, 0, 0),
            CurrentCamera = viewportCamera,
            Parent = screen,
        })

        local bindName = `AuraAfterimages{HttpService:GenerateGUID(false)}`
        RunService:BindToRenderStep(bindName, Enum.RenderPriority.Camera.Value + 1, function()
            local camera = workspace.CurrentCamera
            viewportCamera.CFrame = camera.CFrame
            viewportCamera.FieldOfView = camera.FieldOfView
        end)
        ctx.Defer(function()
            RunService:UnbindFromRenderStep(bindName)
        end)
    end

    local pool = {}
    for i = 1, math.clamp(math.ceil(duration * 24) + 2, 4, 50) do
        local set = { Parts = {}, Overlay = {}, Born = -math.huge, Visible = false }
        for j, source in sources do
            local ghost = cloneGhost(source)
            ghost.Material = Enum.Material.Neon
            ghost.Transparency = 1
            ghost.Parent = ctx.Folder
            set.Parts[j] = ghost
            if viewport then
                local overlay = ghost:Clone()
                overlay.Material = Enum.Material.SmoothPlastic
                overlay.Parent = viewport
                set.Overlay[j] = overlay
            end
        end
        pool[i] = set
    end

    local function fade(p)
        return Config.AfterimageOpacity + (1 - Config.AfterimageOpacity) * (1 - (1 - p) ^ 2)
    end

    local nextIndex, lastPosition, lastTime = 1, nil, 0
    local moveParts, moveCFrames = {}, {}

    ctx.Update = function(t)
        local position = build.Root.Position
        lastPosition = lastPosition or position

        if (position - lastPosition).Magnitude >= Config.AfterimageSpacing and t - lastTime >= 0.03 then
            local travel = position - lastPosition
            lastPosition, lastTime = position, t
            local set = pool[nextIndex]
            nextIndex = nextIndex % #pool + 1
            set.Born, set.Visible = t, true

            local behind = -travel.Unit * Config.AfterimageOffset
            local color = blendSlots(ctx, t * 0.8)
            table.clear(moveParts)
            table.clear(moveCFrames)
            for j, ghost in set.Parts do
                local source = sources[j]
                local cframe = source.CFrame + behind
                if source.Parent then
                    table.insert(moveParts, ghost)
                    table.insert(moveCFrames, cframe)
                end
                ghost.Color = color
                local overlay = set.Overlay[j]
                if overlay then
                    overlay.CFrame = cframe
                    overlay.Color = color
                end
            end
            workspace:BulkMoveTo(moveParts, moveCFrames, Enum.BulkMoveMode.FireCFrameChanged)
        end

        for _, set in pool do
            if set.Visible then
                local p = (t - set.Born) / duration
                local transparency, overlayTransparency = 1, 1
                if p < 1 then
                    transparency = fade(p)
                    overlayTransparency = 1 - (1 - transparency) * Config.AfterimageWallStrength
                else
                    set.Visible = false
                end
                for j, ghost in set.Parts do
                    ghost.Transparency = transparency
                    local overlay = set.Overlay[j]
                    if overlay then
                        overlay.Transparency = overlayTransparency
                    end
                end
            end
        end
    end
end)

effect("Aura Light", "Body", { { "Main", Palette.Pink } }, function(ctx)
    local light = ctx.Own(create("PointLight", {
        Range = 14,
        Brightness = 2.5,
        Shadows = false,
        Parent = ctx.Build.Body,
    }))
    ctx.Bind(light, "Color", function(c) return c.Main end)
    ctx.Update = function(t)
        light.Brightness = 2.5 + math.sin(t * 1.2) * 0.5
    end
end)

effect("Orbs", "Orbit", { { "Main", Palette.Pink }, { "Core", Palette.Core } }, function(ctx)
    local orbs = {}
    for i = 1, Config.OrbCount do
        local a0, a1 = orbitTrail(ctx, "Main", { CoreSize = 0.9 })
        ctx.Bind(emitter(a0, {
            Texture = Textures.spark,
            Rate = 25,
            Lifetime = NumberRange.new(0.3, 0.5),
            Speed = NumberRange.new(0.2, 0.6),
            SpreadAngle = Vector2.new(180, 180),
            RotSpeed = NumberRange.new(-180, 180),
            Size = numberSequence({ { 0, 0.3 }, { 1, 0 } }),
            Transparency = numberSequence({ { 0, 0.1 }, { 1, 1 } }),
            Brightness = 4,
        }), "Color", function(c) return colorSequence({ { 0, c.Core }, { 1, c.Main } }) end)
        orbs[i] = { A0 = a0, A1 = a1, Phase = (i - 1) / Config.OrbCount * math.pi * 2, Speed = 2.5 + i * 0.2 }
    end

    ctx.Update = function(t)
        for _, orb in orbs do
            local angle = t * orb.Speed + orb.Phase
            local radius = Config.OrbRadius + math.sin(t * 0.8 + orb.Phase) * 0.5
            local position = Vector3.new(
                math.cos(angle) * radius,
                math.sin(t * 1.3 + orb.Phase) * 1.4 + 0.3,
                math.sin(angle) * radius
            )
            orb.A0.Position = position
            orb.A1.Position = position + Vector3.new(0, 0.3, 0)
        end
    end
end)

effect("Helix", "Orbit", { { "A", Palette.Cyan }, { "B", Palette.Violet } }, function(ctx)
    local strands = {}
    for i, slot in { "A", "B" } do
        local a0, a1, trail = orbitTrail(ctx, slot, { Lifetime = 0.6 })
        strands[i] = { A0 = a0, A1 = a1, Trail = trail, Offset = (i - 1) * 0.5, Last = 0 }
    end

    ctx.Update = function(t)
        for _, strand in strands do
            local h = (t * 0.45 + strand.Offset) % 1
            if h < strand.Last then
                strand.Trail:Clear()
            end
            strand.Last = h

            local angle = t * 5 + strand.Offset * math.pi * 2
            local radius = 1.9 - h * 0.6
            local position = Vector3.new(math.cos(angle) * radius, -2.8 + h * 6.3, math.sin(angle) * radius)
            strand.A0.Position = position
            strand.A1.Position = position + Vector3.new(0, 0.25, 0)
        end
    end
end)

effect("Atom Orbits", "Orbit", { { "A", Palette.Cyan }, { "B", Palette.White }, { "C", Palette.Violet } }, function(ctx)
    local electrons = {}
    for i, slot in { "A", "B", "C" } do
        local a0, a1 = orbitTrail(ctx, slot, { Lifetime = 0.22, CoreSize = 0.5 })
        electrons[i] = { A0 = a0, A1 = a1, Index = i }
    end

    ctx.Update = function(t)
        for _, electron in electrons do
            local plane = CFrame.Angles(0, t * 0.4 + electron.Index * 2.1, 0) * CFrame.Angles(math.rad(65), 0, 0)
            local angle = t * 6 + electron.Index * 2
            local offset = Vector3.new(math.cos(angle) * 2.4, 0, math.sin(angle) * 2.4)
            electron.A0.Position = plane * offset + Vector3.new(0, 0.6, 0)
            electron.A1.Position = plane * (offset * 1.06) + Vector3.new(0, 0.6, 0)
        end
    end
end)

effect("Crystal Orbit", "Orbit", { { "A", Palette.Cyan }, { "B", Palette.Violet } }, function(ctx)
    local crystals = {}
    for i = 1, 6 do
        local part = newPart("Crystal", Vector3.new(0.3, 0.75, 0.3), ctx.Folder)
        part.Material = Enum.Material.Neon
        part.Transparency = 0.1
        local slot = i % 2 == 1 and "A" or "B"
        ctx.Bind(part, "Color", function(c) return c[slot] end)
        crystals[i] = part
    end

    ctx.Update = function(t)
        local root = ctx.Build.Root.CFrame
        for i, part in crystals do
            local angle = t * 1.2 + (i - 1) / #crystals * math.pi * 2
            part.CFrame = root
                * CFrame.Angles(0, angle, 0)
                * CFrame.new(2.6, 0.6 + math.sin(t * 2 + i) * 0.35, 0)
                * CFrame.Angles(0, t * 3 + i, math.rad(20))
        end
    end
end)

effect("Comet", "Orbit", { { "Main", Palette.Gold }, { "Tail", Palette.Pink } }, function(ctx)
    local a0, a1 = orbitTrail(ctx, "Main", { Lifetime = 0.8, CoreSize = 1.4 })
    ctx.Bind(emitter(a0, {
        Texture = Textures.glow,
        Rate = 60,
        Lifetime = NumberRange.new(0.5, 0.8),
        Speed = NumberRange.new(0),
        Size = numberSequence({ { 0, 0.9 }, { 1, 0 } }),
        Transparency = numberSequence({ { 0, 0.2 }, { 1, 1 } }),
        Brightness = 5,
    }), "Color", function(c) return colorSequence({ { 0, c.Main }, { 1, c.Tail } }) end)

    ctx.Update = function(t)
        local angle = t * 1.6
        local position = Vector3.new(math.cos(angle) * 6, 2.5 + math.sin(t * 0.9) * 1.5, math.sin(angle) * 6)
        a0.Position = position
        a1.Position = position + Vector3.new(0, 0.5, 0)
    end
end)

effect("Floating Runes", "Orbit", { { "Main", Palette.Cyan } }, function(ctx)
    local function glyphOffset(index)
        return Vector2.new(index % 4 * 64, math.floor(index / 4) * 64)
    end

    local runes = {}
    for i = 1, 8 do
        local part = newPart("Rune", Vector3.new(0.2, 0.2, 0.2), ctx.Folder)
        local gui = create("BillboardGui", {
            Size = UDim2.fromScale(1.2, 1.2),
            LightInfluence = 0,
            Brightness = 2.5,
            Parent = part,
        })
        local image = create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = Textures.glyphs,
            ImageRectSize = Vector2.new(64, 64),
            ImageRectOffset = glyphOffset(rng:NextInteger(0, 15)),
            Parent = gui,
        })
        ctx.Bind(image, "ImageColor3", function(c) return c.Main end)
        runes[i] = { Part = part, Image = image, Phase = (i - 1) / 8 * math.pi * 2, NextSwap = rng:NextNumber(1, 4) }
    end

    ctx.Update = function(t)
        local center = ctx.Build.Root.Position
        for _, rune in runes do
            local angle = t * 0.5 + rune.Phase
            rune.Part.CFrame = CFrame.new(center + Vector3.new(
                math.cos(angle) * 3.4,
                1 + math.sin(t * 1.1 + rune.Phase * 2) * 0.8,
                math.sin(angle) * 3.4
            ))
            rune.Image.ImageTransparency = 0.15 + 0.25 * (math.sin(t * 3 + rune.Phase * 5) + 1) / 2
            if t >= rune.NextSwap then
                rune.NextSwap = t + rng:NextNumber(2, 5)
                rune.Image.ImageRectOffset = glyphOffset(rng:NextInteger(0, 15))
            end
        end
    end
end)

effect("Star Field", "Orbit", { { "A", Palette.Cyan }, { "B", Palette.White }, { "C", Palette.Violet } }, function(ctx)
    local sphere = newPart("StarField", Vector3.new(12, 12, 12), ctx.Folder)
    ctx.Bind(emitter(sphere, {
        Texture = Textures.spark,
        Shape = Enum.ParticleEmitterShape.Sphere,
        ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
        Rate = 18,
        Lifetime = NumberRange.new(2, 3.5),
        Speed = NumberRange.new(0.1, 0.4),
        SpreadAngle = Vector2.new(180, 180),
        RotSpeed = NumberRange.new(-40, 40),
        Size = numberSequence({ { 0, 0 }, { 0.2, 0.3 }, { 0.4, 0.1 }, { 0.6, 0.35 }, { 0.8, 0.1 }, { 1, 0 } }),
        Brightness = 5,
    }), "Color", function(c) return colorSequence({ { 0, c.A }, { 0.5, c.B }, { 1, c.C } }) end)

    ctx.Update = function()
        sphere.CFrame = ctx.Build.Root.CFrame
    end
end)

effect("Halo", "Head", { { "Main", Palette.Cyan }, { "Glint", Palette.White } }, function(ctx)
    local head = ctx.Build.Character:FindFirstChild("Head")
    local part = newPart("Halo", Vector3.new(2.6, 0.05, 2.6), ctx.Folder)
    local images = {
        newSurfaceImage(part, Enum.NormalId.Top, Textures.halo, nil, 0, 2.5),
        newSurfaceImage(part, Enum.NormalId.Bottom, Textures.halo, nil, 0, 2.5),
    }
    ctx.Bind(emitter(part, {
        Texture = Textures.spark,
        Rate = 10,
        Lifetime = NumberRange.new(0.4, 0.7),
        Speed = NumberRange.new(0.2, 0.5),
        RotSpeed = NumberRange.new(-90, 90),
        Size = numberSequence({ { 0, 0.25 }, { 1, 0 } }),
        Brightness = 5,
    }), "Color", function(c) return colorSequence({ { 0, c.Glint }, { 1, c.Main } }) end)

    ctx.Update = function(t)
        local root = ctx.Build.Root
        local anchor = head and head.Parent and head or root
        local _, yaw = root.CFrame:ToEulerAnglesYXZ()
        part.CFrame = CFrame.new(anchor.Position + Vector3.new(0, 1.15 + math.sin(t * 2) * 0.08, 0)) * CFrame.Angles(0, yaw, 0)
        local color = ctx.Colors.Main:Lerp(ctx.Colors.Glint, (math.sin(t * 3) + 1) / 4)
        for _, image in images do
            image.Rotation = (t * 30) % 360
            image.ImageColor3 = color
        end
    end
end)

effect("Mandala", "Head", { { "A", Palette.Violet }, { "B", Palette.Pink } }, function(ctx)
    local part = newPart("Mandala", Vector3.new(5, 5, 0.05), ctx.Folder)
    local back = newSurfaceImage(part, Enum.NormalId.Back, Textures.mandala, nil, 0.15)
    local front = newSurfaceImage(part, Enum.NormalId.Front, Textures.mandala, nil, 0.15)

    ctx.Update = function(t)
        local scale = 1 + math.sin(t * 2) * 0.03
        part.Size = Vector3.new(5 * scale, 5 * scale, 0.05)
        part.CFrame = ctx.Build.Root.CFrame * CFrame.new(0, 1.9, 1.1)
        local color = ctx.Colors.A:Lerp(ctx.Colors.B, (math.sin(t * 1.5) + 1) / 2)
        back.Rotation = (t * 15) % 360
        front.Rotation = -back.Rotation
        back.ImageColor3 = color
        front.ImageColor3 = color
    end
end)

local function wingBase(ctx, side, height)
    return ctx.Own(create("Attachment", {
        Name = "AuraWing",
        Position = Vector3.new(0.35 * side, height or 1.1, 0.55),
        Axis = Vector3.yAxis,
        Parent = ctx.Build.Root,
    }))
end

local function featherBeam(ctx, base, props)
    local root = ctx.Build.Root
    local tip = ctx.Own(create("Attachment", { Name = "AuraWingTip", Axis = Vector3.yAxis, Parent = root }))
    local beam = ctx.Own(create("Beam", {
        Attachment0 = base,
        Attachment1 = tip,
        Texture = props.Texture or Textures.wing,
        TextureMode = Enum.TextureMode.Stretch,
        Width0 = props.Width0,
        Width1 = props.Width1,
        CurveSize0 = props.Curve0 or 1.8,
        CurveSize1 = props.Curve1 or 2.2,
        Segments = 20,
        FaceCamera = true,
        Transparency = props.Transparency or numberSequence({ { 0, 0.5 }, { 0.3, 0.1 }, { 1, 0.2 } }),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = props.Brightness or 3,
        ZOffset = props.ZOffset or 0,
        Parent = root,
    }))
    ctx.Bind(beam, "Color", function(c) return colorSequence({ { 0, c.Base }, { 0.6, c.Mid }, { 1, c.Tip } }) end)
    return tip, beam
end

local function featherTip(feather, flap)
    local angle = feather.Angle + flap * feather.Swing
    local direction = Vector3.new(feather.Side * math.cos(angle), math.sin(angle), feather.Sweep + flap * 0.2)
    return feather.Base.Position + direction.Unit * feather.Length
end

local function bezier(p0, p1, p2, p3, u)
    local v = 1 - u
    return p0 * (v * v * v) + p1 * (3 * v * v * u) + p2 * (3 * v * u * u) + p3 * (u * u * u)
end

local WingBuilders = {}

function WingBuilders.Feather(ctx)
    local feathers = {}
    for _, side in { -1, 1 } do
        local base = wingBase(ctx, side)
        for j = 0, 4 do
            local tip = featherBeam(ctx, base, { Width0 = 0.5, Width1 = 2.4 - j * 0.25 })
            table.insert(feathers, {
                Base = base, Tip = tip, Side = side,
                Angle = math.rad(10 + j * 20), Length = 7 - j * 0.8, Swing = 0.18, Sweep = 0.36,
            })
        end
    end

    return function(t)
        local flap = math.sin(t * 2.6)
        for _, feather in feathers do
            feather.Tip.Position = featherTip(feather, flap)
        end
    end
end

function WingBuilders.Ribbon(ctx)
    local lines = {}
    for _, side in { -1, 1 } do
        local base = wingBase(ctx, side)
        for j = 0, 5 do
            local tip = featherBeam(ctx, base, {
                Texture = Textures.trail, Width0 = 0.08, Width1 = 0.14, Brightness = 4,
                Transparency = numberSequence({ { 0, 0.6 }, { 1, 0.2 } }),
            })
            local line = {
                Base = base, Tip = tip, Side = side, Threads = {},
                Angle = math.rad(5 + j * 17), Length = 7.5 - j * 0.7, Swing = 0.2, Sweep = 0.3,
            }
            for k = 1, 2 do
                local a0, a1, trail = orbitTrail(ctx, "Tip", { Lifetime = 0.3, CoreSize = 0.45 })
                line.Threads[k] = { A0 = a0, A1 = a1, Trail = trail, Phase = (k - 1) * 0.5 + j * 0.13, Last = 0 }
            end
            table.insert(lines, line)
        end
    end

    return function(t)
        local flap = math.sin(t * 2.2)
        for _, line in lines do
            local tip = featherTip(line, flap)
            line.Tip.Position = tip
            local p0 = line.Base.Position
            local p1 = p0 + Vector3.yAxis * 1.8
            local p2 = tip - Vector3.yAxis * 2.2
            for _, thread in line.Threads do
                local u = (t * 0.9 + thread.Phase) % 1
                if u < thread.Last then
                    thread.Trail:Clear()
                end
                thread.Last = u
                local position = bezier(p0, p1, p2, tip, u)
                thread.A0.Position = position
                thread.A1.Position = position + Vector3.new(0, 0.18, 0)
            end
        end
    end
end

function WingBuilders.Seraph(ctx)
    local root = ctx.Build.Root
    local feathers = {}

    local function wing(side, height, count, angle0, angleStep, length0, lengthStep, width, swing, delay)
        local base = wingBase(ctx, side, height)
        for j = 0, count - 1 do
            local featherWidth = width - j * 0.2
            local tip = featherBeam(ctx, base, {
                Width0 = 0.5, Width1 = featherWidth, Brightness = 1.6, Curve0 = 2, Curve1 = 2.6,
                Transparency = numberSequence({ { 0, 0.65 }, { 0.3, 0.25 }, { 1, 0.35 } }),
            })
            ctx.Bind(ctx.Own(create("Beam", {
                Attachment0 = base,
                Attachment1 = tip,
                Texture = Textures.trail,
                TextureMode = Enum.TextureMode.Stretch,
                Width0 = 0.8,
                Width1 = featherWidth * 1.4,
                CurveSize0 = 2,
                CurveSize1 = 2.6,
                Segments = 20,
                FaceCamera = true,
                Transparency = numberSequence({ { 0, 0.95 }, { 0.5, 0.88 }, { 1, 0.95 } }),
                LightEmission = 1,
                LightInfluence = 0,
                Brightness = 0.8,
                ZOffset = -0.5,
                Parent = root,
            })), "Color", function(c) return colorSequence({ { 0, c.Base }, { 1, c.Mid } }) end)
            ctx.Bind(emitter(tip, {
                Texture = Textures.spark,
                Rate = 6,
                Lifetime = NumberRange.new(0.6, 1),
                Speed = NumberRange.new(0.2, 0.6),
                Acceleration = Vector3.new(0, -1.5, 0),
                SpreadAngle = Vector2.new(180, 180),
                RotSpeed = NumberRange.new(-120, 120),
                Size = numberSequence({ { 0, 0.35 }, { 1, 0 } }),
                Brightness = 6,
            }), "Color", function(c) return colorSequence({ { 0, Palette.White }, { 1, c.Tip } }) end)
            table.insert(feathers, {
                Base = base, Tip = tip, Side = side,
                Angle = math.rad(angle0 + j * angleStep), Length = length0 - j * lengthStep,
                Swing = swing, Sweep = 0.5, Delay = delay + j * 0.3,
            })
        end
    end

    for _, side in { -1, 1 } do
        wing(side, 1.3, 6, -4, 12, 9.5, 0.65, 2.6, 0.2, 0)
        wing(side, 0.6, 4, -20, -10, 5, 0.4, 1.6, 0.14, 0.8)
    end

    local plumes = newPart("Plumes", Vector3.new(14, 4, 1.5), ctx.Folder)
    ctx.Bind(emitter(plumes, {
        Texture = Textures.plume,
        Rate = 7,
        Lifetime = NumberRange.new(2.5, 3.5),
        Speed = NumberRange.new(0.2, 0.6),
        Acceleration = Vector3.new(0, -0.8, 0),
        Drag = 0.5,
        SpreadAngle = Vector2.new(180, 180),
        Rotation = NumberRange.new(-40, 40),
        RotSpeed = NumberRange.new(-60, 60),
        Size = numberSequence({ { 0, 0 }, { 0.1, 0.6 }, { 0.9, 0.5 }, { 1, 0 } }),
        Transparency = numberSequence({ { 0, 1 }, { 0.1, 0.15 }, { 0.8, 0.3 }, { 1, 1 } }),
        Brightness = 3,
    }), "Color", function(c) return colorSequence({ { 0, c.Tip }, { 1, c.Mid } }) end)

    local radiance = newPart("Radiance", Vector3.new(16, 9, 0.05), ctx.Folder)
    local glows = {
        newSurfaceImage(radiance, Enum.NormalId.Back, Textures.glow, nil, 0.75, 1.2),
        newSurfaceImage(radiance, Enum.NormalId.Front, Textures.glow, nil, 0.75, 1.2),
    }
    for _, image in glows do
        ctx.Bind(image, "ImageColor3", function(c) return c.Mid end)
    end

    return function(t)
        for _, feather in feathers do
            feather.Tip.Position = featherTip(feather, math.sin(t * 1.8 - feather.Delay))
        end
        plumes.CFrame = root.CFrame * CFrame.new(0, 1.6, 1.2)
        radiance.CFrame = root.CFrame * CFrame.new(0, 1.8, 1)
        for _, image in glows do
            image.ImageTransparency = 0.75 + math.sin(t * 1.8) * 0.06
        end
    end
end

effect("Wings", "Head", { { "Base", Palette.Violet }, { "Mid", Palette.Pink }, { "Tip", Palette.Core } }, function(ctx)
    ctx.Update = (WingBuilders[Config.WingMode] or WingBuilders.Feather)(ctx)
end)

effect("Petals", "Head", { { "A", Palette.Pink }, { "B", Palette.Core }, { "C", Palette.Violet } }, function(ctx)
    local cloud = newPart("Petals", Vector3.new(8, 0.2, 8), ctx.Folder)
    ctx.Bind(emitter(cloud, {
        Texture = Textures.petal,
        EmissionDirection = Enum.NormalId.Bottom,
        Rate = 7,
        Lifetime = NumberRange.new(3, 4.5),
        Speed = NumberRange.new(0.5, 1.5),
        Acceleration = Vector3.new(0, -1.2, 0),
        Drag = 0.4,
        SpreadAngle = Vector2.new(35, 35),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-120, 120),
        Size = numberSequence({ { 0, 0 }, { 0.1, 0.35 }, { 0.9, 0.3 }, { 1, 0 } }),
        Squash = numberSequence({ { 0, 0 }, { 0.25, 0.6 }, { 0.5, -0.4 }, { 0.75, 0.6 }, { 1, 0 } }),
        Transparency = numberSequence({ { 0, 1 }, { 0.1, 0.1 }, { 0.85, 0.2 }, { 1, 1 } }),
        LightEmission = 0.5,
        Brightness = 2,
    }), "Color", function(c) return colorSequence({ { 0, c.A }, { 0.5, c.B }, { 1, c.C } }) end)

    ctx.Update = function()
        cloud.CFrame = CFrame.new(ctx.Build.Root.Position + Vector3.new(0, 5, 0))
    end
end)

local function startEffect(build, def)
    if build.Active[def.Name] then return end

    local ctx = {
        Build = build,
        Slots = def.Slots,
        Colors = Colors[def.Name],
        Owned = {},
        Bindings = {},
        Deferred = {},
        Folder = create("Folder", { Name = def.Name, Parent = build.Container }),
    }
    function ctx.Own(instance)
        table.insert(ctx.Owned, instance)
        return instance
    end
    function ctx.Defer(callback)
        table.insert(ctx.Deferred, callback)
    end

    function ctx.Bind(instance, property, compute)
        table.insert(ctx.Bindings, { instance, property, compute })
        instance[property] = compute(ctx.Colors)
        return instance
    end

    build.Active[def.Name] = ctx
    local ok, err = pcall(def.Build, ctx)
    if not ok then
        warn(`[Aura] {def.Name} failed to build: {err}`)
    end
end

local function stopEffect(build, name)
    local ctx = build.Active[name]
    if not ctx then return end
    build.Active[name] = nil

    for _, callback in ctx.Deferred do
        pcall(callback)
    end
    for _, instance in ctx.Owned do
        instance:Destroy()
    end
    ctx.Folder:Destroy()
end

local function cleanup()
    local build = Current
    if not build then return end
    Current = nil

    for name in build.Active do
        stopEffect(build, name)
    end
    build.Container:Destroy()
end

local function buildFromHost(host)
    if Unloaded or type(host) ~= "table" then
        return
    end
    local root = host.Root
    if typeof(root) ~= "Instance" or not root:IsA("BasePart") or not root.Parent then
        return
    end
    cleanup()

    local character = host.Character
    if typeof(character) ~= "Instance" then
        character = root:FindFirstAncestorOfClass("Model") or root
    end
    local container = create("Folder", { Name = "Aura", Parent = workspace.CurrentCamera })
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { character, container, LocalPlayer.Character }

    local build = {
        Character = character,
        Humanoid = host.Humanoid,
        Root = root,
        Container = container,
        RayParams = rayParams,
        Active = {},
        Time = 0,
        Base = newPart("Base", Vector3.new(4, 0.2, 4), container),
        Body = newPart("Body", Vector3.new(2.5, 5, 2.5), container),
        Hosted = true,
    }
    build.Ground = groundCFrame(build)
    Current = build

    for _, def in Effects do
        if Enabled[def.Name] then
            startEffect(build, def)
        end
    end
end

local function buildCharacter(character)
    local host = resolveAuraHost()
    if host then
        buildFromHost(host)
        return
    end
    local humanoid = character:WaitForChild("Humanoid", 10)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if Unloaded or not humanoid or not root or character ~= LocalPlayer.Character then return end
    cleanup()

    local container = create("Folder", { Name = "Aura", Parent = workspace.CurrentCamera })
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { character, container }

    local build = {
        Character = character,
        Humanoid = humanoid,
        Root = root,
        Container = container,
        RayParams = rayParams,
        Active = {},
        Time = 0,
        Base = newPart("Base", Vector3.new(4, 0.2, 4), container),
        Body = newPart("Body", Vector3.new(2.5, 5, 2.5), container),
    }
    build.Ground = groundCFrame(build)
    Current = build

    for _, def in Effects do
        if Enabled[def.Name] then
            startEffect(build, def)
        end
    end
end

local function loadSettings()
    if not (isfile and isfile(SettingsPath)) then return end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(SettingsPath))
    if not ok or type(data) ~= "table" then return end

    for name, enabled in data.Enabled or data do
        if Enabled[name] ~= nil and type(enabled) == "boolean" then
            Enabled[name] = enabled
        end
    end
    for name, slots in data.Colors or {} do
        if Colors[name] and type(slots) == "table" then
            for slot, hex in slots do
                if Colors[name][slot] then
                    local parsed, color = pcall(Color3.fromHex, hex)
                    if parsed then
                        Colors[name][slot] = color
                    end
                end
            end
        end
    end
    if table.find(WingModes, data.WingMode) then
        Config.WingMode = data.WingMode
    end
end

local function saveSettings()
    local colors = {}
    for name, slots in Colors do
        colors[name] = {}
        for slot, color in slots do
            colors[name][slot] = color:ToHex()
        end
    end
    pcall(writefile, SettingsPath, HttpService:JSONEncode({ Enabled = Enabled, Colors = colors, WingMode = Config.WingMode }))
end

local function setEffect(name, enabled)
    if Enabled[name] == nil then return end
    if enabled == nil then
        enabled = not Enabled[name]
    end
    Enabled[name] = enabled

    if Current then
        if enabled then
            startEffect(Current, EffectsByName[name])
        else
            stopEffect(Current, name)
        end
    end
end

local function setColor(name, slot, color)
    local colors = Colors[name]
    if not colors or colors[slot] == nil then return end
    colors[slot] = color

    local ctx = Current and Current.Active[name]
    if ctx then
        for _, binding in ctx.Bindings do
            binding[1][binding[2]] = binding[3](colors)
        end
    end
end

local function cycleWingMode()
    local index = table.find(WingModes, Config.WingMode) or 0
    Config.WingMode = WingModes[index % #WingModes + 1]
    if Current and Current.Active.Wings then
        stopEffect(Current, "Wings")
        startEffect(Current, EffectsByName.Wings)
    end
    saveSettings()
end

local function toggleAll()
    local anyOn = false
    for _, enabled in Enabled do
        anyOn = anyOn or enabled
    end
    for _, def in Effects do
        setEffect(def.Name, not anyOn)
    end
    saveSettings()
end

local function bindKeys()
    local keyToEffect = {}
    for name, key in Config.Keybinds do
        keyToEffect[key] = name
    end

    table.insert(Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not UserInputService:IsKeyDown(Config.Modifier) then return end

        local key = input.KeyCode
        if key == Config.WingModeKey then
            cycleWingMode()
        elseif key == Config.AllKey then
            toggleAll()
        elseif keyToEffect[key] then
            local name = keyToEffect[key]
            setEffect(name)
            saveSettings()
        end
    end))
end

local function update(dt)
    local host = resolveAuraHost()
    if host then
        if not Current or Current.Root ~= host.Root or not Current.Root.Parent then
            buildFromHost(host)
        else
            Current.Root = host.Root
            if typeof(host.Character) == "Instance" then
                Current.Character = host.Character
            end
        end
    elseif Current and Current.Hosted then
        cleanup()
    end

    local build = Current
    if not build or not build.Root or not build.Root.Parent then return end

    build.Time += dt
    local t = build.Time
    build.Ground = groundCFrame(build)
    build.Base.CFrame = build.Ground * CFrame.new(0, 0.15, 0)
    build.Body.CFrame = build.Root.CFrame

    for name, ctx in build.Active do
        if ctx.Update then
            local ok, err = pcall(ctx.Update, t, dt)
            if not ok then
                warn(`[Aura] {name} stopped: {err}`)
                stopEffect(build, name)
            end
        end
    end
end

local function main()
    loadTextures()
    loadSettings()
    bindKeys()

    env.Aura = {
        Config = Config,
        Palette = Palette,
        Effects = Enabled,
        Colors = Colors,
        List = function()
            local names = {}
            for _, def in Effects do
                table.insert(names, def.Name)
            end
            table.sort(names)
            return names
        end,
        Slots = function(name)
            local def = EffectsByName[name]
            if not def then
                return {}
            end
            local copy = {}
            for i, slot in def.Slots do
                copy[i] = slot
            end
            return copy
        end,
        Toggle = function(name, enabled)
            setEffect(name, enabled)
            saveSettings()
        end,
        SetColor = function(name, slot, color)
            setColor(name, slot, color)
            saveSettings()
        end,
        Rebuild = function()
            local host = resolveAuraHost()
            if host then
                buildFromHost(host)
            elseif LocalPlayer.Character then
                buildCharacter(LocalPlayer.Character)
            end
        end,
        Unload = function()
            Unloaded = true
            for _, connection in Connections do
                connection:Disconnect()
            end
            table.clear(Connections)
            cleanup()
            env.Aura = nil
        end,
    }

    local okBuild, buildErr = pcall(function()
        if resolveAuraHost() then
            buildFromHost(resolveAuraHost())
        elseif LocalPlayer.Character then
            buildCharacter(LocalPlayer.Character)
        end
    end)
    table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(character)
        task.spawn(buildCharacter, character)
    end))
    table.insert(Connections, LocalPlayer.CharacterRemoving:Connect(function()
        if not resolveAuraHost() then
            cleanup()
        end
    end))
    local lastAura = 0
    table.insert(Connections, RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - lastAura < 1 / 20 then
            return
        end
        local dt = now - lastAura
        lastAura = now
        local okUpdate, updateErr = pcall(update, math.clamp(dt, 0.01, 0.1))
        if not okUpdate then
            warn("[Aura] update failed:", updateErr)
        end
    end))
end

TextureIds = {
    glow = "rbxassetid://95181057201930",
    spark = "rbxassetid://139472915893534",
    wisp = "rbxassetid://73811842705253",
    shockwave = "rbxassetid://113470626707410",
    runes = "rbxassetid://123584451150295",
    sigil = "rbxassetid://99617834406007",
    trail = "rbxassetid://83380635508067",
    lightning = "rbxassetid://80755198260397",
    flame = "rbxassetid://103697401923653",
    halo = "rbxassetid://139497937595236",
    mandala = "rbxassetid://105380217179050",
    hexgrid = "rbxassetid://77003715948497",
    pillar = "rbxassetid://109552216383182",
    wing = "rbxassetid://122951898651645",
    petal = "rbxassetid://107198048327728",
    cracks = "rbxassetid://95044880519095",
    glyphs = "rbxassetid://136641308399184",
    footprint = "rbxassetid://105161323431879",
    plume = "rbxassetid://87992314886809",
}
getgenv()._TapologyTextureIds = TextureIds
getgenv()._TapologyOOVArrow = OOVArrowAsset

do
    local okAura, errAura = pcall(main)
    if not okAura then
        warn("[Aura] main failed:", errAura)
        getgenv()._TapologyAuraErr = tostring(errAura)
    end
end

end
loadRemote("weather")
loadRemote("hiteffect")
loadRemote("killeffect")
do
    -- Always refresh tracer/rage from local so hit hooks pick up fixes.
    local tracers = getgenv().Tracers
    if type(tracers) == "table" and type(tracers.Unload) == "function" then
        pcall(tracers.Unload)
    end
    getgenv().Tracers = nil
    local rage = getgenv().Rage
    if type(rage) == "table" and type(rage.Unload) == "function" then
        pcall(rage.Unload)
    end
    getgenv().Rage = nil
end
loadRemote("tracer")
loadRemote("rage")
print("[Tapology] Loaded Modules")
if type(getgenv().Weather) ~= "table" then
    warn("[Tapology] weather still missing after load")
end

do
    print("[Tapology] Loading assets...")
    local ContentProvider = game:GetService("ContentProvider")
    local ids = { OOVArrowAsset }
    local textures = getgenv()._TapologyTextureIds
    if type(textures) == "table" then
        for _, id in textures do
            if type(id) == "string" and id ~= "" then
                ids[#ids + 1] = id
            end
        end
    end
    local uiCfg = (getgenv().Tapology or getgenv().Library or {}).Config
    if type(uiCfg) == "table" and type(uiCfg.Logo) == "string" then
        ids[#ids + 1] = uiCfg.Logo
    end
    local holders = {}
    for _, id in ids do
        local decal = Instance.new("Decal")
        decal.Texture = id
        holders[#holders + 1] = decal
    end
    local okPreload, preloadErr = pcall(function()
        ContentProvider:PreloadAsync(holders)
    end)
    for _, decal in holders do
        decal:Destroy()
    end
    if okPreload then
        print("[Tapology] Loaded assets")
        getgenv()._TapologyAssetsLoaded = true
    else
        warn("[Tapology] asset preload failed:", preloadErr)
        getgenv()._TapologyAssetsLoaded = false
    end
    local remain = 5 - (os.clock() - BootStart)
    if remain > 0 then
        task.wait(remain)
    end
    print("[Tapology] Ready")
end

local ESP = getgenv().ESP
local Aim = getgenv().Aim
local World = getgenv().World
local Weather = getgenv().Weather
local Rage = getgenv().Rage
local Misc = getgenv().Misc
local Tracers = getgenv().Tracers
local HitEffects = getgenv().HitEffects
local KillEffects = getgenv().KillEffects

local menuGeneration = (tonumber(getgenv()._TapologyMenuGen) or 0) + 1
getgenv()._TapologyMenuGen = menuGeneration
getgenv()._TapologyMenuErr = nil
getgenv()._TapologyMenuBuilt = nil
local function buildTapologyMenu()
if getgenv()._TapologyMenuGen ~= menuGeneration then
    return
end
do
    local UI0 = getgenv().Tapology or getgenv().Library
    local list0 = UI0 and UI0.Gui and UI0.Gui:FindFirstChild("Window") and UI0.Gui.Window:FindFirstChild("Tabs") and UI0.Gui.Window.Tabs:FindFirstChild("List")
    local tabCount = 0
    if list0 then
        for _, child in list0:GetChildren() do
            if child:IsA("TextButton") then
                tabCount += 1
            end
        end
    end

    local pagesOk = true
    local tapPages = getgenv().TapologyPages
    if type(tapPages) == "table" then
        for _, name in { "legit", "rage", "players", "world", "misc", "server" } do
            local page = tapPages[name]
            if not (type(page) == "table" and typeof(page.Frame) == "Instance" and page.Frame.Parent ~= nil) then
                pagesOk = false
                break
            end
        end
    else
        pagesOk = false
    end
    if getgenv()._TapologyMenuBuilt == menuGeneration and tabCount >= 6 and pagesOk then
        return
    end

    if not pagesOk then
        getgenv()._TapologyMenuBuilt = nil
    end
end
local okMenu, errMenu = pcall(function()

local UI = getgenv().Tapology or getgenv().Library or Library
Library = UI
getgenv().Tapology = UI
getgenv().Library = UI
if not (UI and UI.Gui and UI.Gui.Parent) then
    error("UI gui missing after embed")
end

local ESP = getgenv().ESP
local Aim = getgenv().Aim
local World = getgenv().World
local Weather = getgenv().Weather
local Rage = getgenv().Rage
local Misc = getgenv().Misc
local Tracers = getgenv().Tracers
local HitEffects = getgenv().HitEffects
local KillEffects = getgenv().KillEffects

assert(UI and type(UI.Tab) == "function", "Library failed to load")
assert(ESP, "ESP failed to load")
assert(Aim, "Aim failed to embed")
assert(World, "World failed to embed")
assert(Misc, "Misc failed to embed")
assert(Tracers, "Tracers failed to embed")

local function aim()
    return getgenv().Aim
end
local function world()
    return getgenv().World
end
local function weather()
    return getgenv().Weather
end
local function rage()
    return getgenv().Rage
end
local function misc()
    return getgenv().Misc
end
local function tracers()
    return getgenv().Tracers
end
local function hitEffects()
    return getgenv().HitEffects
end
local function killEffects()
    return getgenv().KillEffects
end
local function esp()
    return getgenv().ESP
end

local function espSwatch(toggle, slot)
    return toggle:AlphaColorPicker(ESP.Config[slot .. "Color"], 1 - ESP.Config[slot .. "Transparency"], function(color, alpha)
        esp().SetColor(slot, color, 1 - alpha)
    end)
end

local pages = {}
getgenv().TapologyPages = pages
pages.__ui = UI
local function pageAlive(page)
    return type(page) == "table" and typeof(page.Frame) == "Instance" and page.Frame.Parent ~= nil
end
local function clearColumns(page)
    if type(page) ~= "table" or type(page.Columns) ~= "table" then
        return
    end
    for _, column in page.Columns do
        if typeof(column) == "Instance" then
            for _, child in column:GetChildren() do
                if not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end
        end
    end
end
local function ensureTab(name)
    local existing = pages[name] or (UI.Pages and UI.Pages[name])
    if pageAlive(existing) then
        pages[name] = existing
        clearColumns(existing)
        return existing
    end
    pages[name] = nil
    if UI.Pages then
        UI.Pages[name] = nil
    end
    local ok, page = pcall(function()
        return UI:Tab(name)
    end)
    if ok and pageAlive(page) then
        pages[name] = page
        clearColumns(page)
        return page
    end
    error(`[Tapology] tab '{name}' missing: {page}`)
end
local legit = ensureTab("legit")
local rageTab = ensureTab("rage")
local players = ensureTab("players")
local worldTab = ensureTab("world")
local miscTab = ensureTab("misc")
getgenv()._TapologyServerPage = ensureTab("server")

local function rageFlags()
    return getgenv().TapologyRageFlags or (getgenv().Rage and getgenv().Rage.Flags)
end
local function setRageFlag(name, value)
    local flags = rageFlags()
    if type(flags) == "table" then
        local flag = flags[name]
        if type(flag) ~= "table" then
            flags[name] = { Value = value }
        else
            flag.Value = value
        end
    end
    if getgenv().Rage and type(getgenv().Rage.SetFlag) == "function" then
        getgenv().Rage.SetFlag(name, value)
    end
end
local function getRageFlag(name, fallback)
    local flags = rageFlags()
    local flag = flags and flags[name]
    if type(flag) == "table" and flag.Value ~= nil then
        return flag.Value
    end
    return fallback
end

local function buildLegitUi()
local editingClass = aim().Config.Class or "assault rifle"
if type(aim().Classify) == "function" then
    editingClass = aim().Classify({ _name = editingClass }) or editingClass
elseif type(editingClass) == "string" then
    local aliases = {
        assault = "assault rifle",
        sniper = "sniper rifle",
    }
    editingClass = aliases[editingClass] or editingClass
end
if not (aim().Config.Profiles and aim().Config.Profiles[editingClass]) then
    editingClass = "assault rifle"
end
aim().Config.Class = editingClass
local function touch(key, value)
    local profiles = aim().Config.Profiles
    if editingClass == "global" then
        if type(profiles) == "table" then
            for _, profile in profiles do
                if type(profile) == "table" then
                    profile[key] = value
                end
            end
        end
        aim().Config[key] = value
        return
    end
    local profile = profiles and profiles[editingClass]
    if profile then
        profile[key] = value
    end
    if editingClass == (getgenv().TapologyWeaponClass or editingClass) then
        aim().Config[key] = value
    end
end

local aimbot = legit:Groupbox("aimbot", "left")
local silentBox = legit:Groupbox("silent", "right")

local mouseEnable = aimbot:Toggle("enable", Aim.Config.MouseEnabled, function(on)
    touch("MouseEnabled", on)
end)
mouseEnable:Keybind()
local mouseKids = mouseEnable:Children()
local mouseFov = mouseKids:Slider("fov", { Min = 10, Max = 600, Default = Aim.Config.MouseFOV, Suffix = "px" }, function(value)
    touch("MouseFOV", value)
end)
local mouseShow = mouseKids:Toggle("show fov", Aim.Config.MouseShowFOV, function(on)
    touch("MouseShowFOV", on)
end)
mouseShow:AlphaColorPicker(Aim.Config.MouseFOVColor, 1 - Aim.Config.MouseFOVTransparency, function(color, alpha)
    aim().SetColor("MouseFOV", color, 1 - alpha)
end)
local mouseOrigin = mouseShow:Children():Dropdown("origin", {
    Values = { "crosshair", "screen" },
    Default = Aim.Config.MouseFOVOrigin == "screen" and "screen" or "crosshair",
}, function(value)
    touch("MouseFOVOrigin", value)
end)
local mouseSmooth = mouseKids:Slider("smoothness", { Min = 0, Max = 0.95, Default = Aim.Config.Smoothness, Decimals = 2 }, function(value)
    touch("Smoothness", value)
end)
local mouseKey = mouseKids:Dropdown("mouse key", { Values = { "right mouse", "left mouse", "always" }, Default = Aim.Config.MouseKey }, function(value)
    touch("MouseKey", value)
end)
local targetPart = mouseKids:Dropdown("target part", { Values = { "head", "torso" }, Default = Aim.Config.TargetPart }, function(value)
    touch("TargetPart", value)
end)
local visibleCheck = mouseKids:Toggle("visible check", Aim.Config.VisibleCheck, function(on)
    touch("VisibleCheck", on)
end)
local maxDistance = mouseKids:Slider("max distance", { Min = 50, Max = 2000, Default = Aim.Config.MaxDistance, Suffix = "st" }, function(value)
    touch("MaxDistance", value)
end)

local silentEnable = silentBox:Toggle("enable", Aim.Config.SilentEnabled, function(on)
    touch("SilentEnabled", on and true or false)
    if aim().Rehook then
        pcall(aim().Rehook)
    end
end)
silentEnable:Keybind()
local silentKids = silentEnable:Children()
local silentFov = silentKids:Slider("fov", { Min = 10, Max = 600, Default = Aim.Config.SilentFOV, Suffix = "px" }, function(value)
    touch("SilentFOV", value)
end)
local silentShow = silentKids:Toggle("show fov", Aim.Config.SilentShowFOV, function(on)
    touch("SilentShowFOV", on)
end)
silentShow:AlphaColorPicker(Aim.Config.SilentFOVColor, 1 - Aim.Config.SilentFOVTransparency, function(color, alpha)
    aim().SetColor("SilentFOV", color, 1 - alpha)
end)
local silentOrigin = silentShow:Children():Dropdown("origin", {
    Values = { "crosshair", "screen" },
    Default = Aim.Config.SilentFOVOrigin == "screen" and "screen" or "crosshair",
}, function(value)
    touch("SilentFOVOrigin", value)
end)
local hitChance = silentKids:Slider("hit chance", { Min = 1, Max = 100, Default = Aim.Config.HitChance, Suffix = "%" }, function(value)
    touch("HitChance", value)
end)
silentKids:Dropdown("target part", { Values = { "head", "torso" }, Default = Aim.Config.TargetPart }, function(value)
    touch("TargetPart", value)
end)
silentKids:Slider("max distance", { Min = 50, Max = 2000, Default = Aim.Config.MaxDistance, Suffix = "st" }, function(value)
    touch("MaxDistance", value)
end)
if not Aim.SilentAvailable then
    Library:Notify("silent aim needs pf modules (rejoin with actors bypass)", 4)
end

local classColumns = legit.Frame and legit.Frame:FindFirstChild("Columns")
if classColumns then
    local oldBar = legit.Frame:FindFirstChild("ClassBar")
    if oldBar then
        oldBar:Destroy()
    end
    local inset = classColumns.Position.X.Offset
    local theme = UI.Config and UI.Config.Theme or {}
    local pad = (UI.Config and UI.Config.Spacing) or 6
    local titleHeight = ((UI.Config and UI.Config.TextSize) or 12) + 8
    local fieldHeight = ((UI.Config and UI.Config.TextSize) or 12) + 6
    local contentPad = pad + 2
    local barHeight = titleHeight + 1 + contentPad + fieldHeight + contentPad
    local gap = 10
    local bar = Instance.new("Frame")
    bar.Name = "ClassBar"
    bar.BackgroundColor3 = theme.Background or Color3.fromRGB(36, 36, 38)
    bar.BorderSizePixel = 0
    bar.ClipsDescendants = false
    bar.Position = UDim2.fromOffset(inset, inset)
    bar.Size = UDim2.new(1, -(inset * 2), 0, barHeight)
    bar.ZIndex = 5
    bar:SetAttribute("TapologyGroupbox", true)
    bar.Parent = legit.Frame
    local barStroke = Instance.new("UIStroke")
    barStroke.Thickness = 1
    barStroke.Color = theme.Shadow or Color3.fromRGB(8, 8, 10)
    barStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    barStroke.LineJoinMode = Enum.LineJoinMode.Miter
    barStroke.Parent = bar
    local rim = Instance.new("Frame")
    rim.Name = "Rim"
    rim.BackgroundTransparency = 1
    rim.Position = UDim2.fromOffset(1, 1)
    rim.Size = UDim2.new(1, -2, 1, -2)
    rim.ZIndex = 3
    rim.Parent = bar
    local rimStroke = Instance.new("UIStroke")
    rimStroke.Thickness = 1
    rimStroke.Color = theme.Highlight or Color3.fromRGB(54, 54, 60)
    rimStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    rimStroke.LineJoinMode = Enum.LineJoinMode.Miter
    rimStroke.Parent = rim
    local barShade = Instance.new("UIGradient")
    barShade.Rotation = 90
    barShade.Color = ColorSequence.new(Color3.new(1.08, 1.08, 1.08), Color3.new(0.88, 0.88, 0.88))
    barShade.Parent = bar
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(pad + 2, 0)
    title.Size = UDim2.new(1, -(pad + 2) * 2, 0, titleHeight)
    title.FontFace = UI.Font
    title.TextSize = (UI.Config and UI.Config.TextSize) or 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = theme.Text or Color3.fromRGB(230, 230, 232)
    title.Text = "weapon class"
    title.ZIndex = 6
    title.Parent = bar
    local sep = Instance.new("Frame")
    sep.Name = "Separator"
    sep.BorderSizePixel = 0
    sep.BackgroundColor3 = theme.Outline or Color3.fromRGB(56, 56, 60)
    sep.Position = UDim2.fromOffset(pad, titleHeight)
    sep.Size = UDim2.new(1, -pad * 2, 0, 1)
    sep.ZIndex = 6
    sep.Parent = bar
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Position = UDim2.fromOffset(pad, titleHeight + 1 + contentPad)
    content.Size = UDim2.new(1, -pad * 2, 0, fieldHeight)
    content.ZIndex = 6
    content.Parent = bar
    local barLayout = Instance.new("UIListLayout")
    barLayout.SortOrder = Enum.SortOrder.LayoutOrder
    barLayout.Padding = UDim.new(0, 0)
    barLayout.Parent = content
    classColumns.Position = UDim2.fromOffset(inset, inset + barHeight + gap)
    UI.Dropdown(content, "", {
        Values = Aim.Classes or {
            "assault rifle",
            "battle rifle",
            "carbine",
            "pdw",
            "lmg",
            "dmr",
            "sniper rifle",
            "shotgun",
            "pistol",
            "machine pistol",
            "revolver",
            "other",
        },
        Default = editingClass,
        Flag = "legit/weapon class",
    }, function(value)
        editingClass = value
        aim().Config.Class = value
        local profile = aim().Config.Profiles and aim().Config.Profiles[value]
        if not profile then
            return
        end
        mouseEnable:Set(profile.MouseEnabled)
        mouseFov:Set(profile.MouseFOV)
        mouseShow:Set(profile.MouseShowFOV)
        mouseOrigin:Set(profile.MouseFOVOrigin)
        mouseSmooth:Set(profile.Smoothness)
        mouseKey:Set(profile.MouseKey)
        targetPart:Set(profile.TargetPart)
        visibleCheck:Set(profile.VisibleCheck)
        maxDistance:Set(profile.MaxDistance)
        silentEnable:Set(profile.SilentEnabled)
        silentFov:Set(profile.SilentFOV)
        silentShow:Set(profile.SilentShowFOV)
        silentOrigin:Set(profile.SilentFOVOrigin)
        hitChance:Set(profile.HitChance)
    end)
end
end
buildLegitUi()

local rageUiBuilt = false
local function buildRageUi()
    local rage = getgenv().Rage
    local cfg = rage and rage.Config
    if not cfg then
        return false
    end
    if rageUiBuilt then
        return true
    end
    rageUiBuilt = true
    local main = rageTab:Groupbox("ragebot", "left")
    local extra = rageTab:Groupbox("extra", "right")

    local enabled = main:Toggle("enabled", cfg.Enabled == true, function(on)
        local live = getgenv().Rage
        local liveCfg = live and live.Config
        if liveCfg then
            liveCfg.Enabled = on and true or false
        end
        if live and live.SetEnabled then
            live.SetEnabled(on)
        end
    end)
    enabled:Keybind()
    main:Dropdown("priority", {
        Values = { "Closest to Crosshair", "Closest to Local", "Lowest Health" },
        Default = cfg.Priority or "Closest to Crosshair",
    }, function(value)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.Priority = value
        end
    end)
    main:Dropdown("mode", {
        Values = { "default", "edge" },
        Default = cfg.Mode == "edge" and "edge" or "default",
    }, function(value)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.Mode = value
        end
    end)
    main:Toggle("use fov", cfg.UseFOV == true, function(on)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.UseFOV = on and true or false
        end
    end)
    main:Slider("fov radius", { Min = 50, Max = 2000, Default = tonumber(cfg.FOVRadius) or 350, Suffix = "px" }, function(value)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.FOVRadius = value
        end
    end)
    main:Slider("max distance", { Min = 50, Max = 3000, Default = tonumber(cfg.MaxDistance) or 1500, Suffix = "st" }, function(value)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.MaxDistance = value
        end
    end)
    main:Toggle("fire position scan", cfg.FirePositionScanning ~= false, function(on)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.FirePositionScanning = on and true or false
        end
    end)
    main:Slider("fire position offset", { Min = 1, Max = 20, Default = tonumber(cfg.FirePositionOffset) or 10, Suffix = "st" }, function(value)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.FirePositionOffset = value
        end
    end)
    main:Toggle("hit position scan", cfg.HitPositionScanning ~= false, function(on)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.HitPositionScanning = on and true or false
        end
    end)
    main:Slider("hit position offset", { Min = 1, Max = 20, Default = tonumber(cfg.HitPositionOffset) or 10, Suffix = "st" }, function(value)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.HitPositionOffset = value
        end
    end)
    main:Toggle("prediction", cfg.Prediction ~= false, function(on)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.Prediction = on and true or false
        end
    end)
    main:Toggle("shoot effects", cfg.ShootEffects ~= false, function(on)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.ShootEffects = on and true or false
        end
    end)

    local resolver = extra:Toggle("resolver", cfg.Resolver == true, function(on)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.Resolver = on and true or false
        end
    end)
    resolver:Children():Slider("strength", { Min = 1, Max = 12, Default = tonumber(cfg.ResolverStrength) or 4, Decimals = 1 }, function(value)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.ResolverStrength = value
        end
    end)
    local aa = extra:Toggle("anti aim", cfg.AntiAim == true, function(on)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.AntiAim = on and true or false
        end
    end)
    local aaKids = aa:Children()
    aaKids:Slider("pitch", { Min = -2, Max = 2, Default = tonumber(cfg.PitchAmount) or 0, Decimals = 2 }, function(value)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.PitchAmount = value
        end
    end)
    aaKids:Slider("yaw", { Min = -180, Max = 180, Default = tonumber(cfg.YawAmount) or 180 }, function(value)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.YawAmount = value
        end
    end)
    local fake = extra:Toggle("fake lag", cfg.FakeLag == true, function(on)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.FakeLag = on and true or false
        end
    end)
    local fakeKids = fake:Children()
    fakeKids:Slider("amount", { Min = 0.1, Max = 3, Default = tonumber(cfg.FakeLagAmount) or 1.2, Decimals = 2, Suffix = "st" }, function(value)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.FakeLagAmount = value
        end
    end)
    fakeKids:Slider("hold", { Min = 0.05, Max = 1, Default = tonumber(cfg.FakeLagHold) or 0.35, Decimals = 2, Suffix = "s" }, function(value)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.FakeLagHold = value
        end
    end)
    fakeKids:Slider("smooth", { Min = 0, Max = 1, Default = tonumber(cfg.FakeLagSmooth) or 0.45, Decimals = 2 }, function(value)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.FakeLagSmooth = value
        end
    end)
    extra:Toggle("indicators", cfg.Indicators ~= false, function(on)
        local liveCfg = getgenv().Rage and getgenv().Rage.Config
        if liveCfg then
            liveCfg.Indicators = on and true or false
        end
    end)
    if not rage.Available then
        Library:Notify("ragebot waiting for pf modules", 4)
    end
    return true
end
if not buildRageUi() then
    Library:Notify("ragebot module missing — retrying", 3)
    task.spawn(function()
        for _ = 1, 40 do
            task.wait(0.25)
            if getgenv()._TapologyMenuGen ~= menuGeneration then
                return
            end
            if buildRageUi() then
                Library:Notify("ragebot ready", 2)
                return
            end
        end
    end)
end

local function buildEspUi()
local espBox = players:Groupbox("extra sensory shi", "left")
for _, row in {
    { "name", "ShowNames", "Name" },
    { "weapon", "ShowWeapon", "Weapon" },
    { "distance", "ShowDistance", "Distance" },
} do
    local text, setting, slot = row[1], row[2], row[3]
    local toggle = espBox:Toggle(text, ESP.Config[setting], function(on)
        esp().Config[setting] = on
    end)
    espSwatch(toggle, slot)
    toggle:Settings(text):Toggle("outline", ESP.Config[slot .. "Outline"] ~= false, function(on)
        esp().Config[slot .. "Outline"] = on
    end)
end
local boxToggle = espBox:Toggle("box", ESP.Config.ShowBoxes, function(on)
    esp().Config.ShowBoxes = on
end)
local boxCfg = boxToggle:Settings("box")
boxCfg:Toggle("outline", ESP.Config.BoxOutline ~= false, function(on)
    esp().Config.BoxOutline = on
end)
boxCfg:AlphaColorPicker("color", ESP.Config.BoxColor, 1 - ESP.Config.BoxTransparency, function(color, alpha)
    esp().SetColor("Box", color, 1 - alpha)
end)
boxCfg:AlphaColorPicker("outline", ESP.Config.OutlineColor, 1 - ESP.Config.OutlineTransparency, function(color, alpha)
    esp().SetColor("Outline", color, 1 - alpha)
end)
local healthToggle = espBox:Toggle("healthbar", ESP.Config.ShowHealth, function(on)
    esp().Config.ShowHealth = on
end)
local healthCfg = healthToggle:Settings("healthbar")
healthCfg:Toggle("outline", ESP.Config.HealthOutline ~= false, function(on)
    esp().Config.HealthOutline = on
end)
healthCfg:AlphaColorPicker("color", ESP.Config.HealthColor, 1 - ESP.Config.HealthTransparency, function(color, alpha)
    esp().SetColor("Health", color, 1 - alpha)
end)
healthCfg:AlphaColorPicker("low", ESP.Config.HealthLowColor, 1, function(color, alpha)
    esp().Config.HealthLowColor = color
    esp().Config.HealthLowTransparency = 1 - alpha
end)
local snapToggle = espBox:Toggle("snaplines", ESP.Config.Snaplines, function(on)
    esp().Config.Snaplines = on
end)
local snapCfg = snapToggle:Settings("snaplines")
snapCfg:Toggle("outline", ESP.Config.SnaplineOutline ~= false, function(on)
    esp().Config.SnaplineOutline = on
end)
snapCfg:AlphaColorPicker("color", ESP.Config.SnaplineColor, 1 - (ESP.Config.SnaplineTransparency or 0), function(color, alpha)
    esp().Config.SnaplineColor = color
    esp().Config.SnaplineTransparency = 1 - alpha
end)
local oovToggle = espBox:Toggle("oov arrows", ESP.Config.OOV, function(on)
    esp().Config.OOV = on
end)
local oovCfg = oovToggle:Settings("oov arrows")
oovCfg:Slider("radius", { Min = 40, Max = 400, Default = ESP.Config.OOVRadius or 180, Suffix = "px" }, function(value)
    esp().Config.OOVRadius = value
end)
oovCfg:Slider("size", { Min = 8, Max = 32, Default = ESP.Config.OOVSize or 16 }, function(value)
    esp().Config.OOVSize = value
end)
oovCfg:AlphaColorPicker("color", ESP.Config.OOVColor, 1 - (ESP.Config.OOVTransparency or 0), function(color, alpha)
    esp().Config.OOVColor = color
    esp().Config.OOVTransparency = 1 - alpha
end)

local extra = players:Groupbox("extra", "right")
local highlight = extra:Toggle("chams", ESP.Config.Highlight, function(on)
    esp().Config.Highlight = on
end)
local chamCfg = highlight:Settings("chams")
chamCfg:Dropdown("mode", {
    Values = { "highlight", "adornment" },
    Default = ESP.Config.ChamsMode == "adornment" and "adornment" or "highlight",
}, function(value)
    esp().Config.ChamsMode = value == "adornment" and "adornment" or "highlight"
end)
chamCfg:Dropdown("adornment", {
    Values = { "solid", "shaded", "glow", "glow 2x", "xray", "xray shaded", "plasma" },
    Default = ESP.Config.AdornmentType or "solid",
}, function(value)
    esp().Config.AdornmentType = value
end)
chamCfg:Slider("glow", { Min = 0.25, Max = 4, Default = ESP.Config.AdornmentGlow or 1, Decimals = 2 }, function(value)
    esp().Config.AdornmentGlow = value
end)
chamCfg:Toggle("per part", ESP.Config.HighlightPerPart, function(on)
    esp().Config.HighlightPerPart = on
end)
chamCfg:Toggle("visible", ESP.Config.HighlightVisible, function(on)
    esp().Config.HighlightVisible = on
end)
chamCfg:AlphaColorPicker("visible fill", ESP.Config.HighlightVisibleFillColor, 1 - ESP.Config.HighlightVisibleFillTransparency, function(color, alpha)
    esp().SetColor("HighlightVisibleFill", color, 1 - alpha)
end)
chamCfg:AlphaColorPicker("visible line", ESP.Config.HighlightVisibleOutlineColor, 1 - ESP.Config.HighlightVisibleOutlineTransparency, function(color, alpha)
    esp().SetColor("HighlightVisibleOutline", color, 1 - alpha)
end)
chamCfg:Toggle("occluded", ESP.Config.HighlightOccluded, function(on)
    esp().Config.HighlightOccluded = on
end)
chamCfg:AlphaColorPicker("occluded fill", ESP.Config.HighlightOccludedFillColor, 1 - ESP.Config.HighlightOccludedFillTransparency, function(color, alpha)
    esp().SetColor("HighlightOccludedFill", color, 1 - alpha)
end)
chamCfg:AlphaColorPicker("occluded line", ESP.Config.HighlightOccludedOutlineColor, 1 - ESP.Config.HighlightOccludedOutlineTransparency, function(color, alpha)
    esp().SetColor("HighlightOccludedOutline", color, 1 - alpha)
end)
end
buildEspUi()

local function buildWorldUi()
local mainWorld = worldTab:Groupbox("world", "left")
local weatherBox = worldTab:Groupbox("weather", "right")
local colorBox = worldTab:Groupbox("color correction", "left")

local ambience = mainWorld:Toggle("ambience", World.Config.Ambience, function(on)
    world().SetEnabled("Ambience", on)
end):Settings("ambience")
ambience:ColorPicker("ambient", World.Config.Ambient, function(color)
    world().SetColor("Ambient", color)
end)
ambience:ColorPicker("outdoor", World.Config.OutdoorAmbient, function(color)
    world().SetColor("OutdoorAmbient", color)
end)

local clock = mainWorld:Toggle("clock time", World.Config.Clock, function(on)
    world().SetEnabled("Clock", on)
end):Settings("clock time")
clock:Slider("time", { Min = 0, Max = 24, Default = World.Config.ClockTime, Decimals = 1 }, function(value)
    world().Set("ClockTime", value)
end)
local sun = mainWorld:Toggle("sun", World.Config.Sun, function(on)
    world().Config.Sun = on
    world().ForceApply()
end)
local sunCfg = sun:Settings("sun")
sunCfg:Slider("brightness", { Min = 0, Max = 10, Default = World.Config.SunBrightness or 2, Decimals = 1 }, function(value)
    world().Config.SunBrightness = value
    world().ForceApply()
end)
sunCfg:Slider("size", { Min = 0, Max = 90, Default = World.Config.SunSize or 21 }, function(value)
    world().Config.SunSize = value
    world().ForceApply()
end)
local worldRemove = worldTab:Groupbox("removals", "right")
worldRemove:Toggle("sun", World.Config.RemoveSun, function(on)
    world().Config.RemoveSun = on
    world().ForceApply()
end)
worldRemove:Toggle("moon", World.Config.RemoveMoon, function(on)
    world().Config.RemoveMoon = on
    world().ForceApply()
end)
worldRemove:Toggle("stars", World.Config.RemoveStars, function(on)
    world().Config.RemoveStars = on
    world().ForceApply()
end)
local texture = worldRemove:Toggle("texture", World.Config.WorldTexture, function(on)
    world().Config.WorldTexture = on
end)
texture:Children():Dropdown("material", {
    Values = { "SmoothPlastic", "Neon", "ForceField", "Glass", "Grass", "Slate", "Concrete", "Ice", "Metal", "DiamondPlate", "Foil" },
    Default = World.Config.WorldMaterial or "SmoothPlastic",
}, function(value)
    world().Config.WorldMaterial = value
end)

local atmosphere = mainWorld:Toggle("atmosphere", World.Config.Fog, function(on)
    world().SetEnabled("Fog", on)
end):Settings("atmosphere")
atmosphere:Slider("density", { Min = 0, Max = 1, Default = World.Config.FogDensity, Decimals = 2 }, function(value)
    world().Set("FogDensity", value)
end)
atmosphere:Slider("offset", { Min = 0, Max = 20, Default = World.Config.FogOffset or 0, Decimals = 1 }, function(value)
    world().Set("FogOffset", value)
end)
atmosphere:Slider("haze", { Min = 0, Max = 10, Default = World.Config.FogHaze, Decimals = 1 }, function(value)
    world().Set("FogHaze", value)
end)
atmosphere:Slider("glare", { Min = 0, Max = 10, Default = World.Config.FogGlare, Decimals = 1 }, function(value)
    world().Set("FogGlare", value)
end)
atmosphere:ColorPicker("color", World.Config.FogColor, function(color)
    world().SetColor("FogColor", color)
end)
atmosphere:ColorPicker("decay", World.Config.FogDecay, function(color)
    world().SetColor("FogDecay", color)
end)

local lighting = mainWorld:Toggle("lighting", World.Config.Lighting, function(on)
    world().SetEnabled("Lighting", on)
end):Settings("lighting")
lighting:Slider("brightness", { Min = 0, Max = 10, Default = World.Config.Brightness, Decimals = 1 }, function(value)
    world().Set("Brightness", value)
end)
lighting:Slider("exposure", { Min = -3, Max = 3, Default = World.Config.ExposureCompensation, Decimals = 2 }, function(value)
    world().Set("ExposureCompensation", value)
end)
lighting:ColorPicker("ambient", World.Config.Ambient, function(color)
    world().SetColor("Ambient", color)
end)
lighting:ColorPicker("outdoor", World.Config.OutdoorAmbient, function(color)
    world().SetColor("OutdoorAmbient", color)
end)

local skyboxNames = {}
for name in World.Config.Skyboxes do
    table.insert(skyboxNames, name)
end
table.sort(skyboxNames)
local skybox = mainWorld:Toggle("skybox", World.Config.Skybox, function(on)
    world().SetEnabled("Skybox", on)
end)
skybox:Children():Dropdown("preset", { Values = skyboxNames, Default = World.Config.SkyboxId }, function(value)
    world().Set("SkyboxId", value)
end)

local bloom = mainWorld:Toggle("bloom", World.Config.Bloom, function(on)
    world().SetEnabled("Bloom", on)
end)
local bloomKids = bloom:Children()
bloomKids:Slider("intensity", { Min = 0, Max = 2, Default = World.Config.BloomIntensity, Decimals = 2 }, function(value)
    world().Set("BloomIntensity", value)
end)
bloomKids:Slider("size", { Min = 1, Max = 56, Default = World.Config.BloomSize }, function(value)
    world().Set("BloomSize", value)
end)
bloomKids:Slider("threshold", { Min = 0, Max = 3, Default = World.Config.BloomThreshold, Decimals = 2 }, function(value)
    world().Set("BloomThreshold", value)
end)

local dof = mainWorld:Toggle("depth of field", World.Config.DepthOfField, function(on)
    world().SetEnabled("DepthOfField", on)
end)
local dofKids = dof:Children()
dofKids:Slider("far intensity", { Min = 0, Max = 1, Default = World.Config.DoFFarIntensity, Decimals = 2 }, function(value)
    world().Set("DoFFarIntensity", value)
end)
dofKids:Slider("near intensity", { Min = 0, Max = 1, Default = World.Config.DoFNearIntensity, Decimals = 2 }, function(value)
    world().Set("DoFNearIntensity", value)
end)
dofKids:Slider("focus distance", { Min = 1, Max = 200, Default = World.Config.DoFFocusDistance, Suffix = "st" }, function(value)
    world().Set("DoFFocusDistance", value)
end)
dofKids:Slider("in focus radius", { Min = 0, Max = 100, Default = World.Config.DoFInFocusRadius, Suffix = "st" }, function(value)
    world().Set("DoFInFocusRadius", value)
end)

if Weather then
local weatherLast = Weather.Config.LastMode
if not weatherLast or weatherLast == "Off" or not table.find(Weather.Modes, weatherLast) then
    weatherLast = Weather.Config.Mode ~= "Off" and Weather.Config.Mode or (Weather.Modes[1] or "Snow")
    Weather.Config.LastMode = weatherLast
end
local weatherOn = weatherBox:Toggle("enable", Weather.Config.Mode ~= "Off", function(on)
    local W = weather()
    if on then
        local nextMode = W.Config.LastMode
        if not nextMode or nextMode == "Off" or not table.find(W.Modes, nextMode) then
            nextMode = W.Modes[1] or "Snow"
        end
        W.SetMode(nextMode)
    else
        W.SetMode("Off")
    end
end)
local weatherKids = weatherOn:Children()
weatherKids:Toggle("affect ambience", Weather.Config.ChangeEnvironment, function(on)
    weather().SetChangeEnvironment(on)
end)
local modeValues = table.clone(Weather.Modes)
local modeDropdown = weatherKids:Dropdown("mode", {
    Values = modeValues,
    Default = Weather.Config.Mode ~= "Off" and Weather.Config.Mode or weatherLast,
}, function(value)
    local W = weather()
    W.Config.LastMode = value

    if W.Config.Mode ~= "Off" then
        W.SetMode(value)
    end
end)
local function weatherParams(modeName)
    return (Weather.Config.ModeParams and Weather.Config.ModeParams[modeName]) or {}
end
local function weatherSlider(section, modeName, key, text, opts)
    local params = weatherParams(modeName)
    local default = params[key]
    if default == nil then
        return
    end
    section:Slider(text, {
        Min = opts.Min,
        Max = opts.Max,
        Default = default,
        Decimals = opts.Decimals,
        Suffix = opts.Suffix,
    }, function(value)
        weather().SetParam(modeName, key, value)
    end)
end
for _, modeName in modeValues do
    local section = modeDropdown:Children(modeName)
    weatherSlider(section, modeName, "Radius", "radius", { Min = 20, Max = 200, Suffix = "st" })
    weatherSlider(section, modeName, "Density", "amount", { Min = 0.1, Max = 3, Decimals = 2 })
    weatherSlider(section, modeName, "Wind", "wind", { Min = 0, Max = 4, Decimals = 2 })
    weatherSlider(section, modeName, "Size", "size", { Min = 0.25, Max = 3, Decimals = 2 })
    weatherSlider(section, modeName, "Height", "height", { Min = 6, Max = 60, Suffix = "st" })
    weatherSlider(section, modeName, "StarDistance", "star distance", { Min = 80, Max = 900, Suffix = "st" })
    weatherSlider(section, modeName, "CometRate", "comet rate", { Min = 0.1, Max = 4, Decimals = 1 })
    local colors = Weather.Config.Colors[modeName]
    if colors then
        local slots = {}
        for slot in colors do
            table.insert(slots, slot)
        end
        table.sort(slots)
        for _, slot in slots do
            section:ColorPicker(slot:lower(), colors[slot], function(color)
                weather().SetColor(modeName, slot, color)
            end)
        end
    end
end
end

local correction = colorBox:Toggle("enabled", World.Config.ColorCorrection, function(on)
    world().SetEnabled("ColorCorrection", on)
end)
local correctionKids = correction:Children()
correctionKids:Slider("saturation", { Min = -1, Max = 1, Default = World.Config.Saturation, Decimals = 2 }, function(value)
    world().Set("Saturation", value)
end)
correctionKids:Slider("contrast", { Min = -1, Max = 1, Default = World.Config.Contrast, Decimals = 2 }, function(value)
    world().Set("Contrast", value)
end)
correctionKids:Slider("brightness", { Min = -1, Max = 1, Default = World.Config.CorrectionBrightness, Decimals = 2 }, function(value)
    world().Set("CorrectionBrightness", value)
end)
correctionKids:Slider("exposure", { Min = -2, Max = 2, Default = World.Config.Exposure, Decimals = 2 }, function(value)
    world().Set("Exposure", value)
end)
correctionKids:ColorPicker("tint", World.Config.TintColor, function(color)
    world().SetColor("TintColor", color)
end)
local dynamic = correctionKids:Toggle("dynamic exposure", World.Config.DynamicExposure, function(on)
    world().SetEnabled("DynamicExposure", on)
end)
local dynamicKids = dynamic:Children()
dynamicKids:Slider("min", { Min = -2, Max = 1, Default = World.Config.DynamicExposureMin, Decimals = 2 }, function(value)
    local w = world()
    w.Set("DynamicExposureMin", value)
    if (tonumber(w.Config.DynamicExposureMax) or 0.8) < value then
        w.Set("DynamicExposureMax", value)
    end
end)
dynamicKids:Slider("max", { Min = 0, Max = 2, Default = World.Config.DynamicExposureMax, Decimals = 2 }, function(value)
    local w = world()
    w.Set("DynamicExposureMax", value)
    if (tonumber(w.Config.DynamicExposureMin) or -0.4) > value then
        w.Set("DynamicExposureMin", value)
    end
end)
dynamicKids:Slider("speed", { Min = 0.2, Max = 8, Default = World.Config.DynamicExposureSpeed, Decimals = 1 }, function(value)
    world().Set("DynamicExposureSpeed", value)
end)
end
buildWorldUi()

local function buildMiscUi()
local movementBox = miscTab:Groupbox("movement", "left")
local cameraBox = miscTab:Groupbox("camera", "right")
local tracersBox = miscTab:Groupbox("tracers", "left")
local tracerTab = tracersBox:Subtab("tracers")
local hitsTab = tracersBox:Subtab("hits")
local hitLogTab = tracersBox:Subtab("hit logs")
local aurasBox = miscTab:Groupbox("auras", "left")

local effectsBox = miscTab:Groupbox("effects", "right")
local hitsBox = effectsBox:Subtab("hit effects")
local killsBox = effectsBox:Subtab("kill effects")

local viewmodelModBox = miscTab:Groupbox("viewmodel modify", "right")
local vmModifyTab = viewmodelModBox:Subtab("modify")
local vmShootTab = viewmodelModBox:Subtab("shoot")
local vmRemovalsTab = viewmodelModBox:Subtab("removals")

movementBox:Toggle("movement bypass", Misc.Config.MovementBypass == true, function(on)
    misc().Config.MovementBypass = on and true or false
end)
local walk = movementBox:Toggle("walk speed", Misc.Config.WalkSpeed, function(on)
    misc().Config.WalkSpeed = on and true or false
end)
walk:Keybind()
walk:Children():Slider("speed", { Min = 10, Max = 200, Default = math.clamp(tonumber(Misc.Config.SetSpeed) or 50, 10, 200), Suffix = "st/s" }, function(value)
    misc().Config.SetSpeed = math.clamp(tonumber(value) or 50, 1, 200)
end)
local jump = movementBox:Toggle("jump power", Misc.Config.JumpPower, function(on)
    misc().Config.JumpPower = on and true or false
end)
jump:Keybind()
jump:Children():Slider("height addition", { Min = 1, Max = 15, Default = Misc.Config.HeightAddition, Suffix = "st" }, function(value)
    misc().Config.HeightAddition = value
end)
movementBox:Toggle("no fall damage", Misc.Config.NoFallDamage, function(on)
    misc().Config.NoFallDamage = on
end)
local bhop = movementBox:Toggle("bunny hop", Misc.Config.BunnyHop, function(on)
    misc().Config.BunnyHop = on
end)
bhop:Keybind()
bhop:Children():Toggle("only while jumping", Misc.Config.OnlyWhileJumping, function(on)
    misc().Config.OnlyWhileJumping = on
end)
local slide = movementBox:Toggle("slide boost", Misc.Config.SlideBoost, function(on)
    misc().Config.SlideBoost = on
end)
slide:Children():Slider("speed", { Min = 10, Max = 150, Default = Misc.Config.SlideBoostSpeed or 70, Suffix = "st/s" }, function(value)
    misc().Config.SlideBoostSpeed = value
end)
movementBox:Toggle("no stamina", Misc.Config.NoStamina, function(on)
    misc().Config.NoStamina = on
end)
movementBox:Toggle("no movement cooldown", Misc.Config.NoMoveCooldown, function(on)
    misc().Config.NoMoveCooldown = on and true or false
end)
movementBox:Toggle("height snap", Misc.Config.HeightBypass, function(on)
    misc().Config.HeightBypass = on
end)
movementBox:Slider("height snap time", { Min = 0.2, Max = 8, Default = Misc.Config.HeightBypassTime or 1.5, Decimals = 1, Suffix = "s" }, function(value)
    misc().Config.HeightBypassTime = value
end)
movementBox:Slider("move smooth", { Min = 1, Max = 40, Default = Misc.Config.MoveSmooth or 12 }, function(value)
    misc().Config.MoveSmooth = value
end)

local third = cameraBox:Toggle("third person", Misc.Config.ThirdPerson, function(on)
    misc().Config.ThirdPerson = on
    if on then
        misc().Config.HideViewmodel = true
        misc().Config.ShowCharacter = true
    end
end)
third:Keybind()
local thirdKids = third:Children()
thirdKids:Toggle("render weapon", Misc.Config.ThirdPersonWeapon ~= false, function(on)
    misc().Config.ThirdPersonWeapon = on and true or false
end)
thirdKids:Toggle("show character", Misc.Config.ShowCharacter ~= false, function(on)
    misc().Config.ShowCharacter = on
end)
thirdKids:Toggle("show while aiming", Misc.Config.ShowCharacterWhileAiming, function(on)
    misc().Config.ShowCharacterWhileAiming = on
end)
thirdKids:Toggle("hide viewmodel", Misc.Config.HideViewmodel == true, function(on)
    misc().Config.HideViewmodel = on and true or false
end)
misc().Config.ApplyAntiAimToCharacter = false
local clip = thirdKids:Toggle("clip camera", Misc.Config.ThirdPersonClip ~= false, function(on)
    misc().Config.ThirdPersonClip = on and true or false
end)
local clipKids = clip:Children()
clipKids:Slider("minimum", { Min = 1, Max = 10, Default = tonumber(Misc.Config.ThirdPersonMinimum) or 3, Decimals = 1, Suffix = "m" }, function(value)
    misc().Config.ThirdPersonMinimum = value
end)
clipKids:Slider("maximum", { Min = 1, Max = 20, Default = tonumber(Misc.Config.ThirdPersonMaximum) or 8, Decimals = 1, Suffix = "m" }, function(value)
    misc().Config.ThirdPersonMaximum = value
    misc().Config.CameraOffsetZ = value
end)
local fovCam = cameraBox:Toggle("fov", Misc.Config.FOV, function(on)
    misc().Config.FOV = on
end)
fovCam:Keybind()
fovCam:Children():Slider("amount", { Min = 40, Max = 135, Default = Misc.Config.FOVAmount }, function(value)
    misc().Config.FOVAmount = value
end)
local aspect = cameraBox:Toggle("aspect ratio", Misc.Config.AspectRatio, function(on)
    misc().Config.AspectRatio = on
end)
aspect:Keybind()
aspect:Children():Slider("ratio", { Min = 0.4, Max = 3, Default = Misc.Config.Aspect, Decimals = 2 }, function(value)
    misc().Config.Aspect = value
end)
local viewmodel = cameraBox:Toggle("viewmodel", Misc.Config.Viewmodel, function(on)
    misc().Config.Viewmodel = on
end)
viewmodel:Keybind()
local vmKids = viewmodel:Children()
vmKids:Slider("offset x", { Min = -8, Max = 8, Default = Misc.Config.ViewmodelX, Decimals = 2, Suffix = "st" }, function(value)
    misc().Config.ViewmodelX = value
end)
vmKids:Slider("offset y", { Min = -8, Max = 8, Default = Misc.Config.ViewmodelY, Decimals = 2, Suffix = "st" }, function(value)
    misc().Config.ViewmodelY = value
end)
vmKids:Slider("offset z", { Min = -8, Max = 8, Default = Misc.Config.ViewmodelZ, Decimals = 2, Suffix = "st" }, function(value)
    misc().Config.ViewmodelZ = value
end)
local recoil = cameraBox:Toggle("recoil control", Misc.Config.RecoilControl, function(on)
    misc().Config.RecoilControl = on
end)
recoil:Children():Slider("strength", { Min = 0, Max = 1, Default = Misc.Config.RecoilScale or 0.55, Decimals = 2 }, function(value)
    misc().Config.RecoilScale = value
end)
local cross = cameraBox:Toggle("crosshair", Misc.Config.Crosshair, function(on)
    misc().Config.Crosshair = on
end)
cross:ColorPicker(Misc.Config.CrosshairColor1, function(color)
    misc().Config.CrosshairColor1 = color
end)
cross:ColorPicker(Misc.Config.CrosshairColor2, function(color)
    misc().Config.CrosshairColor2 = color
end)
cross:ColorPicker(Misc.Config.CrosshairColor3, function(color)
    misc().Config.CrosshairColor3 = color
end)
cross:ColorPicker(Misc.Config.CrosshairColor4, function(color)
    misc().Config.CrosshairColor4 = color
end)
local crossKids = cross:Children()
crossKids:Dropdown("place", {
    Values = { "onscreen", "ingame" },
    Default = Misc.Config.CrosshairMode == "ingame" and "ingame" or "onscreen",
}, function(value)
    misc().Config.CrosshairMode = value
end)
crossKids:Slider("thickness", { Min = 1, Max = 8, Default = Misc.Config.CrosshairThickness or 2 }, function(value)
    misc().Config.CrosshairThickness = value
end)
crossKids:Slider("gap", { Min = 0, Max = 30, Default = Misc.Config.CrosshairGap or 4 }, function(value)
    misc().Config.CrosshairGap = value
end)
crossKids:Slider("length", { Min = 1, Max = 40, Default = Misc.Config.CrosshairLength or 8 }, function(value)
    misc().Config.CrosshairLength = value
end)
crossKids:Slider("fade in", { Min = 0, Max = 1, Default = tonumber(Misc.Config.CrosshairFadeIn) or 0, Decimals = 2 }, function(value)
    misc().Config.CrosshairFadeIn = value
end)
crossKids:Slider("fade out", { Min = 0, Max = 1, Default = tonumber(Misc.Config.CrosshairFadeOut) or 0, Decimals = 2 }, function(value)
    misc().Config.CrosshairFadeOut = value
end)
local crossOutline = crossKids:Toggle("outline", Misc.Config.CrosshairOutline == true, function(on)
    misc().Config.CrosshairOutline = on and true or false
end)
crossOutline:ColorPicker(Misc.Config.CrosshairOutlineColor or Color3.new(0, 0, 0), function(color)
    misc().Config.CrosshairOutlineColor = color
end)
crossKids:Slider("bounce", { Min = 0, Max = 20, Default = Misc.Config.CrosshairBounce or 0 }, function(value)
    misc().Config.CrosshairBounce = value
end)
crossKids:Slider("bounce speed", { Min = 0, Max = 20, Default = Misc.Config.CrosshairBounceSpeed or 6, Decimals = 1 }, function(value)
    misc().Config.CrosshairBounceSpeed = value
end)
crossKids:Slider("spin", { Min = 0, Max = 4, Default = Misc.Config.CrosshairSpin or 0, Decimals = 2 }, function(value)
    misc().Config.CrosshairSpin = value
end)
crossKids:Slider("spin speed", { Min = 0, Max = 360, Default = Misc.Config.CrosshairSpinSpeed or 90 }, function(value)
    misc().Config.CrosshairSpinSpeed = value
end)

local function syncMiscRemovals()
    local cfg = misc().Config
    local on = cfg.Removals == true
    local items = type(cfg.RemoveItems) == "table" and cfg.RemoveItems or {}
    if items.decals ~= nil then
        items.decals = nil
    end
    cfg.RemoveDecals = false
    cfg.RemoveArms = on and items.arms == true
    cfg.RemoveAnimations = on and items.animations == true
    cfg.RemoveTeam = on and items.team == true
    cfg.RemoveEnemy = on and items.enemy == true
    cfg.RemoveExplosions = on and items.explosions == true
    cfg.RemoveDroppedGuns = on and items.dropped == true
end
local removalsEnable = vmRemovalsTab:Toggle("enable", Misc.Config.Removals, function(on)
    misc().Config.Removals = on and true or false
    syncMiscRemovals()
end)
local removalKids = removalsEnable:Children()
removalKids:Dropdown("items", {
    Multi = true,
    Values = { "arms", "animations", "team", "enemy", "explosions", "dropped" },
    Default = Misc.Config.RemoveItems or {},
}, function(value)
    if type(value) == "table" then
        value.decals = nil
    end
    misc().Config.RemoveItems = value
    syncMiscRemovals()
end)
removalKids:Dropdown("hud", {
    Multi = true,
    Values = { "chat", "killfeed" },
    Default = type(Misc.Config.RemoveHud) == "table" and Misc.Config.RemoveHud or {},
}, function(value)
    misc().Config.RemoveHud = value
end)

local function styleColors(section, colorTable, setColor)
    if not colorTable then
        return
    end
    local slots = {}
    for slot in colorTable do
        table.insert(slots, slot)
    end
    table.sort(slots)
    for _, slot in slots do
        local value = colorTable[slot]
        if typeof(value) == "Color3" then
            section:ColorPicker(slot:lower(), value, function(color)
                setColor(slot, color)
            end)
        elseif typeof(value) == "table" and typeof(value[1]) == "Color3" then
            section:ColorPicker(slot:lower(), value[1], function(color)
                value[1] = color
                setColor(slot, value)
            end)
        end
    end
end

if Tracers then
local tracerOn = tracerTab:Toggle("enable", Tracers.Config.Enabled, function(on)
    tracers().SetEnabled(on)
end)
local tracerKids = tracerOn:Children()
local tracerStyles = Tracers.Styles or {}
local tracerStyle = tracerKids:Dropdown("style", {
    Values = tracerStyles,
    Default = Tracers.Config.Style,
}, function(value)
    tracers().SetStyle(value)
end)

for _, styleName in tracerStyles do
    local section = tracerStyle:Children(styleName)
    styleColors(section, Tracers.Config.Colors[styleName], function(slot, color)
        tracers().SetColor(styleName, slot, color)
    end)
end
tracerKids:Slider("width", { Min = 0.25, Max = 3, Default = Tracers.Config.Width, Decimals = 2 }, function(value)
    tracers().Config.Width = value
end)
tracerKids:Slider("lifetime", { Min = 0.1, Max = 5, Default = Tracers.Config.Lifetime or 1, Decimals = 2, Suffix = "x" }, function(value)
    tracers().Config.Lifetime = value
end)
tracerKids:Slider("max distance", { Min = 100, Max = 3000, Default = Tracers.Config.MaxDistance, Suffix = "st" }, function(value)
    tracers().Config.MaxDistance = value
end)

local hitSounds = hitsTab:Toggle("sound", Tracers.Config.HitSounds, function(on)
    tracers().Config.HitSounds = on
end)
local hitSoundKids = hitSounds:Children()
hitSoundKids:Toggle("mute game sounds", Tracers.Config.MuteGameHitSounds ~= false, function(on)
    tracers().Config.MuteGameHitSounds = on
end)
local hitSoundNames = Tracers.HitSounds or {}
if #hitSoundNames == 0 and Tracers.Config.HitSoundIds then
    for name in Tracers.Config.HitSoundIds do
        table.insert(hitSoundNames, name)
    end
    table.sort(hitSoundNames)
end
hitSoundKids:Dropdown("sound", {
    Values = hitSoundNames,
    Default = Tracers.Config.HitSound or hitSoundNames[1],
}, function(value)
    tracers().Config.HitSound = value
end)
hitSoundKids:Slider("volume", { Min = 0, Max = 5, Default = Tracers.Config.HitSoundVolume or 1, Decimals = 2 }, function(value)
    tracers().Config.HitSoundVolume = value
end)
hitSoundKids:Slider("pitch", { Min = 0.1, Max = 3, Default = Tracers.Config.HitSoundPitch or 1, Decimals = 2 }, function(value)
    tracers().Config.HitSoundPitch = value
end)
hitSoundKids:Button("preview", function()
    local t = tracers()
    if t and t.PlayHitSound then
        local was = t.Config.HitSounds
        t.Config.HitSounds = true
        t.PlayHitSound()
        t.Config.HitSounds = was
    end
end)

local hitMarkers = hitsTab:Toggle("hitmarkers", Misc.Config.HitMarkers == true, function(on)
    misc().Config.HitMarkers = on and true or false
end)
hitMarkers:AlphaColorPicker(Misc.Config.HitMarkerColor1, tonumber(Misc.Config.HitMarkerAlpha1) or 1, function(color, alpha)
    misc().Config.HitMarkerColor1 = color
    misc().Config.HitMarkerAlpha1 = alpha
end)
hitMarkers:AlphaColorPicker(Misc.Config.HitMarkerColor2, tonumber(Misc.Config.HitMarkerAlpha2) or 1, function(color, alpha)
    misc().Config.HitMarkerColor2 = color
    misc().Config.HitMarkerAlpha2 = alpha
end)
hitMarkers:AlphaColorPicker(Misc.Config.HitMarkerColor3, tonumber(Misc.Config.HitMarkerAlpha3) or 1, function(color, alpha)
    misc().Config.HitMarkerColor3 = color
    misc().Config.HitMarkerAlpha3 = alpha
end)
hitMarkers:AlphaColorPicker(Misc.Config.HitMarkerColor4, tonumber(Misc.Config.HitMarkerAlpha4) or 1, function(color, alpha)
    misc().Config.HitMarkerColor4 = color
    misc().Config.HitMarkerAlpha4 = alpha
end)
local hitMarkerKids = hitMarkers:Children()
hitMarkerKids:Dropdown("mode", {
    Multi = true,
    Values = { "2d", "3d" },
    Default = (function()
        local raw = Misc.Config.HitMarkerModes
        if type(raw) == "table" and (raw["2d"] or raw["3d"] or raw[1]) then
            return raw
        end
        if Misc.Config.HitMarkerMode == "3d" then
            return { ["3d"] = true }
        end
        return { ["2d"] = true }
    end)(),
}, function(value)
    misc().Config.HitMarkerModes = value
end)
hitMarkerKids:Slider("thickness", { Min = 1, Max = 8, Default = tonumber(Misc.Config.HitMarkerThickness) or 2 }, function(value)
    misc().Config.HitMarkerThickness = value
end)
hitMarkerKids:Slider("gap", { Min = 0, Max = 30, Default = tonumber(Misc.Config.HitMarkerGap) or 4 }, function(value)
    misc().Config.HitMarkerGap = value
end)
hitMarkerKids:Slider("length", { Min = 1, Max = 40, Default = tonumber(Misc.Config.HitMarkerLength) or 10 }, function(value)
    misc().Config.HitMarkerLength = value
end)
hitMarkerKids:Slider("fade in", { Min = 0, Max = 1, Default = tonumber(Misc.Config.HitMarkerFadeIn) or 0, Decimals = 2 }, function(value)
    misc().Config.HitMarkerFadeIn = value
end)
hitMarkerKids:Slider("fade out", { Min = 0, Max = 1, Default = tonumber(Misc.Config.HitMarkerFadeOut) or 0, Decimals = 2 }, function(value)
    misc().Config.HitMarkerFadeOut = value
end)
local hmOutline = hitMarkerKids:Toggle("outline", Misc.Config.HitMarkerOutline == true, function(on)
    misc().Config.HitMarkerOutline = on and true or false
end)
hmOutline:ColorPicker(Misc.Config.HitMarkerOutlineColor or Color3.new(0, 0, 0), function(color)
    misc().Config.HitMarkerOutlineColor = color
end)
hitMarkerKids:Slider("duration", { Min = 0.05, Max = 1.5, Default = tonumber(Misc.Config.HitMarkerDuration) or 0.35, Decimals = 2, Suffix = "s" }, function(value)
    misc().Config.HitMarkerDuration = value
end)

local hitLogs = hitLogTab:Toggle("enable", Tracers.Config.HitLogs, function(on)
    tracers().Config.HitLogs = on
end)
hitLogs:Children():Slider("duration", { Min = 1, Max = 8, Default = Tracers.Config.HitLogDuration or 3.5, Decimals = 1, Suffix = "s" }, function(value)
    tracers().Config.HitLogDuration = value
end)
end

do
    local function auraModule()
        return getgenv().Aura
    end

    local Aura = auraModule()
    local auraValues = (Aura and Aura.List and Aura.List()) or {}
    table.sort(auraValues)

    local defaultSet = {}
    if type(Misc.Config.Auras) == "table" then
        for key, on in pairs(Misc.Config.Auras) do
            if on then
                if typeof(key) == "number" then
                    defaultSet[on] = true
                else
                    defaultSet[key] = true
                end
            end
        end
    end

    local function applyAuraSelection(set)
        misc().Config.Auras = set
        local aura = auraModule()
        if not (aura and aura.Toggle) then
            return
        end
        local names = aura.List and aura.List() or auraValues
        for _, name in names do
            if aura.Effects and aura.Effects[name] ~= nil then
                aura.Toggle(name, set and set[name] == true)
            end
        end
    end

    local function auraSlotColor(name, slot)
        local aura = auraModule()
        local color = aura and aura.Colors and aura.Colors[name] and aura.Colors[name][slot]
        return typeof(color) == "Color3" and color or Color3.fromRGB(108, 147, 255)
    end

    local auraDrop = aurasBox:Dropdown("auras", {
        Values = auraValues,
        Multi = true,
        Default = defaultSet,
    }, applyAuraSelection)

    for _, name in auraValues do
        local section = auraDrop:Children(name)
        local aura = auraModule()
        local slots = (aura and aura.Slots and aura.Slots(name)) or { "Main" }
        local label = string.lower(tostring(name))
        local mainSlot = slots[1] or "Main"
        local picker = section:ColorPicker(label, auraSlotColor(name, mainSlot), function(color)
            local live = auraModule()
            if live and live.SetColor then
                live.SetColor(name, mainSlot, color)
            end
            if type(misc().Config.AuraColors) ~= "table" then
                misc().Config.AuraColors = {}
            end
            misc().Config.AuraColors[name] = color
        end)

        if picker and picker.Settings and #slots > 1 then
            local cfg = picker:Settings(label)
            for _, slot in slots do
                local slotName = tostring(slot)
                cfg:ColorPicker(string.lower(slotName), auraSlotColor(name, slotName), function(color)
                    local live = auraModule()
                    if live and live.SetColor then
                        live.SetColor(name, slotName, color)
                    end
                    if slotName == mainSlot then
                        picker:Set(color)
                        if type(misc().Config.AuraColors) ~= "table" then
                            misc().Config.AuraColors = {}
                        end
                        misc().Config.AuraColors[name] = color
                    end
                end)
            end
        end
    end

    applyAuraSelection(defaultSet)
end

if HitEffects then
local hitOn = hitsBox:Toggle("enable", HitEffects.Config.Enabled, function(on)
    local fx = hitEffects()
    fx.SetEnabled(on)
    if on then
        fx.Config.OnDamage = true
    end
end)
local hitKids = hitOn:Children()
hitKids:Toggle("on damage", HitEffects.Config.OnDamage ~= false, function(on)
    hitEffects().Config.OnDamage = on
end)
local hitStyles = HitEffects.Effects or HitEffects.Config.DemoEffects
local hitStyle = hitKids:Dropdown("style", {
    Values = hitStyles,
    Default = HitEffects.Config.Style,
}, function(value)
    hitEffects().SetStyle(value)
end)
hitKids:Slider("scale", { Min = 0.25, Max = 3, Default = HitEffects.Config.Scale, Decimals = 2 }, function(value)
    hitEffects().Config.Scale = value
end)
for _, styleName in hitStyles do
    local section = hitStyle:Children(styleName)
    styleColors(section, HitEffects.Config.Colors[styleName], function(slot, color)
        hitEffects().SetColor(styleName, slot, color)
    end)
end
end

if KillEffects then
local killOn = killsBox:Toggle("enable", KillEffects.Config.Enabled, function(on)
    local fx = killEffects()
    fx.SetEnabled(on)
    if on then
        fx.Config.OnKill = true
    end
end)
local killKids = killOn:Children()
killKids:Toggle("on kill", KillEffects.Config.OnKill ~= false, function(on)
    killEffects().Config.OnKill = on
end)
local killStyles = KillEffects.Effects or KillEffects.Config.DemoEffects
local killStyle = killKids:Dropdown("style", {
    Values = killStyles,
    Default = KillEffects.Config.Effect,
}, function(value)
    killEffects().SetEffect(value)
end)
killKids:Slider("speed", { Min = 0.25, Max = 3, Default = KillEffects.Config.Speed, Decimals = 2, Suffix = "x" }, function(value)
    killEffects().SetSpeed(value)
end)
killKids:Slider("scale", { Min = 0.35, Max = 3, Default = KillEffects.Config.Scale, Decimals = 2 }, function(value)
    killEffects().SetScale(value)
end)
for _, styleName in killStyles do
    local section = killStyle:Children(styleName)
    styleColors(section, KillEffects.Config.Colors[styleName], function(slot, color)
        killEffects().SetColor(styleName, slot, color)
    end)
end
end

local weaponMats = Misc.WeaponMaterials or {
    "ForceField", "Neon", "Glass", "SmoothPlastic", "Plastic", "Metal", "DiamondPlate", "Foil", "Ice",
}
local armsChams = vmModifyTab:Toggle("arms", Misc.Config.ArmsChams, function(on)
    misc().Config.ArmsChams = on
end)
local armsKids = armsChams:Children()
armsKids:Dropdown("material", {
    Values = weaponMats,
    Default = Misc.Config.ArmsChamsMaterial or "ForceField",
}, function(value)
    misc().Config.ArmsChamsMaterial = value
end)
armsKids:AlphaColorPicker("color", Misc.Config.ArmsChamsColor or Color3.fromRGB(108, 147, 255), 1 - (Misc.Config.ArmsChamsAlpha or 0), function(color, alpha)
    misc().Config.ArmsChamsColor = color
    misc().Config.ArmsChamsAlpha = 1 - alpha
end)

local bodyChams = vmModifyTab:Toggle("body", Misc.Config.BodyChams, function(on)
    misc().Config.BodyChams = on
end)
local bodyKids = bodyChams:Children()
bodyKids:Dropdown("material", {
    Values = weaponMats,
    Default = Misc.Config.BodyChamsMaterial or "ForceField",
}, function(value)
    misc().Config.BodyChamsMaterial = value
end)
bodyKids:AlphaColorPicker("color", Misc.Config.BodyChamsColor or Color3.fromRGB(255, 190, 150), 1 - (Misc.Config.BodyChamsAlpha or 0), function(color, alpha)
    misc().Config.BodyChamsColor = color
    misc().Config.BodyChamsAlpha = 1 - alpha
end)

local weaponChams = vmModifyTab:Toggle("weapon", Misc.Config.WeaponChams, function(on)
    misc().Config.WeaponChams = on
end)
local weaponKids = weaponChams:Children()
weaponKids:Dropdown("material", {
    Values = weaponMats,
    Default = Misc.Config.WeaponChamsMaterial or "ForceField",
}, function(value)
    misc().Config.WeaponChamsMaterial = value
end)
weaponKids:AlphaColorPicker("color", Misc.Config.WeaponChamsColor or Color3.fromRGB(108, 147, 255), 1 - (Misc.Config.WeaponChamsAlpha or 0), function(color, alpha)
    misc().Config.WeaponChamsColor = color
    misc().Config.WeaponChamsAlpha = 1 - alpha
end)

local shootOn = vmShootTab:Toggle("enable", Misc.Config.ShootSounds, function(on)
    misc().Config.ShootSounds = on
end)
local shootKids = shootOn:Children()
shootKids:Toggle("mute game sounds", Misc.Config.MuteGameShootSounds ~= false, function(on)
    misc().Config.MuteGameShootSounds = on
end)
local shootNames = Misc.ShootSounds or {}
if #shootNames == 0 and Misc.Config.ShootSoundIds then
    for name in Misc.Config.ShootSoundIds do
        table.insert(shootNames, name)
    end
    table.sort(shootNames)
end
shootKids:Dropdown("sound", {
    Values = shootNames,
    Default = Misc.Config.ShootSound or "Impact",
}, function(value)
    misc().Config.ShootSound = value
end)
shootKids:Textbox("custom file", { Default = Misc.Config.CustomSound or "", Placeholder = "sound.wav / .mp3 / rbxassetid://" }, function(value)
    misc().Config.CustomSound = value
end)
shootKids:Slider("volume", { Min = 0, Max = 5, Default = Misc.Config.ShootSoundVolume or 1.2, Decimals = 2 }, function(value)
    misc().Config.ShootSoundVolume = value
end)
shootKids:Slider("pitch", { Min = 0.1, Max = 3, Default = Misc.Config.ShootSoundPitch or 1, Decimals = 2 }, function(value)
    misc().Config.ShootSoundPitch = value
end)
shootKids:Button("preview", function()
    local m = misc()
    if m and m.PlayShootSound then
        m.PlayShootSound(true)
    end
end)
end
buildMiscUi()

end)

local okServer, errServer = pcall(function()
local UI = getgenv().Tapology or getgenv().Library
local serverTab = getgenv()._TapologyServerPage
if not (UI and serverTab) then
    return
end
if serverTab.Columns then
    for _, side in { "left", "right" } do
        local column = serverTab.Columns[side]
        if column then
            for _, child in column:GetChildren() do
                if not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end
        end
    end
end

local prevServer = getgenv()._TapologyServer
if type(prevServer) == "table" and type(prevServer.Stop) == "function" then
    pcall(prevServer.Stop)
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local statuses = getgenv().TapologyPlayerStatus
if type(statuses) ~= "table" then
    statuses = {}
    getgenv().TapologyPlayerStatus = statuses
end

local conns = {}
local alive = true
local popup
local popupBlocker
local selectedPlayer
local selectedJob
local popupPlayer
local openPopup
local serverSort = "most"
local rebuildServers
local serverCache = {}
local playerEntries = {}
local serverEntries = {}

local function track(conn)
    if conn then
        conns[#conns + 1] = conn
    end
    return conn
end

local function stop()
    alive = false
    for index = 1, #conns do
        pcall(function()
            conns[index]:Disconnect()
        end)
    end
    table.clear(conns)
    if popup then
        pcall(function()
            popup:Destroy()
        end)
        popup = nil
    end
    if popupBlocker then
        pcall(function()
            popupBlocker:Destroy()
        end)
        popupBlocker = nil
    end
end

local gate = {
    Stop = stop,
    Rejoin = false,
    Joining = false,
    LastHop = 0,
}
getgenv()._TapologyServer = gate

local function tag(className, props)
    local inst = Instance.new(className)
    local parent = props.Parent
    for key, value in props do
        if key ~= "Parent" then
            inst[key] = value
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function textLabel(parent, text, align)
    local label = tag("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = UI.Font,
        TextSize = UI.Config.TextSize,
        Text = text or "",
        TextXAlignment = align or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.fromOffset(6, 0),
        TextColor3 = UI.Config.Theme.Text,
        Parent = parent,
    })
    local stroke = tag("UIStroke", {
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        Color = UI.Config.Theme.TextOutline,
        Parent = label,
    })
    return label, stroke
end

local function makeList(parent, visible, layoutOrder)
    local rowH = UI.Config.TextSize + 4
    local box = tag("Frame", {
        Name = "List",
        BackgroundColor3 = UI.Config.Theme.Inline,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, rowH * visible),
        LayoutOrder = layoutOrder or 1,
        Parent = parent,
    })
    local boxStroke = tag("UIStroke", {
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Color = UI.Config.Theme.Shadow,
        Parent = box,
    })
    local scroller = tag("ScrollingFrame", {
        Name = "Rows",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = UI.Config.Theme.Accent,
        Parent = box,
    })
    tag("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = scroller,
    })
    return box, scroller, boxStroke
end

local function statusColor(status)
    if status == "ignore" then
        return Color3.fromRGB(255, 74, 74)
    end
    if status == "friendly" then
        return Color3.fromRGB(86, 224, 128)
    end
    if status == "prioritize" then
        return Color3.fromRGB(255, 186, 64)
    end
    return UI.Config.Theme.Text
end

local function playerText(player)
    local status = statuses[tostring(player.UserId)]
    if status then
        return player.Name .. "  " .. status
    end
    return player.Name
end

local function paintChrome()
    local theme = UI.Config.Theme
    if popup and popup.Parent then
        popup.BackgroundColor3 = theme.Background
        local accent = popup:FindFirstChild("Accent")
        if accent then
            accent.BackgroundColor3 = theme.Accent
        end
        local stroke = popup:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = theme.Outline
        end
    end
end

local playersBox = serverTab:Groupbox("players", "left")
local _, playerScroll, playerStroke = makeList(playersBox.Frame, 8)
local serversBox = serverTab:Groupbox("servers", "right")
serversBox:Dropdown("players", {
    Values = { "most players", "least players" },
    Default = "most players",
}, function(value)
    serverSort = value == "least players" and "least" or "most"
    if rebuildServers and #serverCache > 0 then
        local copy = {}
        for index = 1, #serverCache do
            copy[index] = serverCache[index]
        end
        rebuildServers(copy)
    end
end)
local _, serverScroll, serverStroke = makeList(serversBox.Frame, 5, 30)
local joinBox = serverTab:Groupbox("join", "right")

local function paintPlayers()
    local theme = UI.Config.Theme
    playerStroke.Color = theme.Shadow
    for index = 1, #playerEntries do
        local entry = playerEntries[index]
        if entry.Label.Parent then
            local status = statuses[tostring(entry.Player.UserId)]
            entry.Label.Text = playerText(entry.Player)
            entry.Label.TextColor3 = statusColor(status)
            entry.Stroke.Color = theme.TextOutline
            entry.Button.BackgroundColor3 = theme.Inline
            entry.Button.BackgroundTransparency = entry.Player == selectedPlayer and 0 or 1
        end
    end
    paintChrome()
end

local function rebuildPlayers()
    local y = playerScroll.CanvasPosition.Y
    for _, child in playerScroll:GetChildren() do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    table.clear(playerEntries)
    if selectedPlayer and not selectedPlayer.Parent then
        selectedPlayer = nil
        if popup then
            popup.Visible = false
        end
    end
    local list = Players:GetPlayers()
    table.sort(list, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)
    local order = 0
    for index = 1, #list do
        local player = list[index]
        if player ~= LocalPlayer then
            order += 1
            local button = tag("TextButton", {
                Name = player.Name,
                Text = "",
                AutoButtonColor = false,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, UI.Config.TextSize + 4),
                LayoutOrder = order,
                Parent = playerScroll,
            })
            local label, stroke = textLabel(button, player.Name)
            local entry = { Player = player, Button = button, Label = label, Stroke = stroke }
            playerEntries[#playerEntries + 1] = entry
            button.MouseButton1Click:Connect(function()
                selectedPlayer = player
                paintPlayers()
            end)
            button.MouseButton2Click:Connect(function()
                selectedPlayer = player
                paintPlayers()
                openPopup(player)
            end)
        end
    end
    if order == 0 then
        local holder = tag("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, UI.Config.TextSize + 4),
            Parent = playerScroll,
        })
        local label, stroke = textLabel(holder, "none")
        label.TextColor3 = UI.Config.Theme.SubText
        stroke.Color = UI.Config.Theme.TextOutline
    end
    playerScroll.CanvasPosition = Vector2.new(0, y)
    paintPlayers()
end

local function setStatus(player, status)
    if not player then
        return
    end
    local key = tostring(player.UserId)
    if status == "ignore" or status == "friendly" or status == "prioritize" then
        statuses[key] = status
    else
        statuses[key] = nil
    end
    if player.Parent then
        selectedPlayer = player
    end
    paintPlayers()
end

popup = tag("Frame", {
    Name = "PlayerStatus",
    Visible = false,
    ZIndex = 80,
    BorderSizePixel = 0,
    AutomaticSize = Enum.AutomaticSize.Y,
    Size = UDim2.fromOffset(124, 0),
    BackgroundColor3 = UI.Config.Theme.Background,
    Parent = UI.Gui,
})
tag("UIStroke", {
    Thickness = 1,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    LineJoinMode = Enum.LineJoinMode.Miter,
    Color = UI.Config.Theme.Outline,
    Parent = popup,
})
if type(UI.PolishOverlay) == "function" then
    UI.PolishOverlay(popup, { Shadow = true, ShadowPad = 24, ShadowTransparency = 0.42, Gloss = false })
end
tag("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
    Parent = popup,
})
tag("Frame", {
    Name = "Accent",
    BackgroundColor3 = UI.Config.Theme.Accent,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 1),
    LayoutOrder = 0,
    ZIndex = 81,
    Parent = popup,
})

local popupButtons = {}
local popupNames = { "ignore", "friendly", "prioritize", "clean" }
for index = 1, #popupNames do
    local name = popupNames[index]
    local button = tag("TextButton", {
        Name = name,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        BorderSizePixel = 0,
        BackgroundColor3 = UI.Config.Theme.Inline,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, UI.Config.TextSize + 6),
        LayoutOrder = index,
        ZIndex = 82,
        Parent = popup,
    })
    local label, stroke = textLabel(button, name, Enum.TextXAlignment.Center)
    label.Position = UDim2.fromOffset(0, 0)
    label.Size = UDim2.fromScale(1, 1)
    label.ZIndex = 83
    label.TextColor3 = name == "clean" and UI.Config.Theme.Text or statusColor(name)
    stroke.ZIndex = 83
    popupButtons[index] = { Name = name, Button = button, Label = label }
    button.MouseButton1Down:Connect(function()
        if not popup.Visible or not popupPlayer then
            return
        end
        if name == "clean" then
            setStatus(popupPlayer, nil)
        else
            setStatus(popupPlayer, name)
        end
        popup.Visible = false
        if popupBlocker then
            popupBlocker.Visible = false
        end
    end)
end

popupBlocker = tag("TextButton", {
    Name = "PlayerStatusBlock",
    Text = "",
    AutoButtonColor = false,
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 70,
    Visible = false,
    Parent = UI.Gui,
})
local function hidePopup()
    if popup then
        popup.Visible = false
    end
    if popupBlocker then
        popupBlocker.Visible = false
    end
end
popupBlocker.MouseButton1Click:Connect(hidePopup)
popupBlocker.MouseButton2Click:Connect(hidePopup)

openPopup = function(player)
    popupPlayer = player
    local status = statuses[tostring(player.UserId)]
    for index = 1, #popupButtons do
        local item = popupButtons[index]
        local active = item.Name == status
        item.Label.TextColor3 = item.Name == "clean" and UI.Config.Theme.Text or statusColor(item.Name)
        item.Button.BackgroundColor3 = UI.Config.Theme.Inline
        item.Button.BackgroundTransparency = active and 0 or 1
    end
    local mouse = UserInputService:GetMouseLocation()
    local camera = workspace.CurrentCamera
    local vs = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local maxX = math.max(vs.X - 124, 0)
    local maxY = math.max(vs.Y - 110, 0)
    popup.Position = UDim2.fromOffset(math.clamp(mouse.X, 0, maxX), math.clamp(mouse.Y, 0, maxY))
    popupBlocker.Visible = true
    popup.Visible = true
    paintChrome()
end

local function encodeStatuses()
    local parts = {}
    for id, status in statuses do
        if status == "ignore" or status == "friendly" or status == "prioritize" then
            parts[#parts + 1] = tostring(id) .. "=" .. status
        end
    end
    table.sort(parts)
    return table.concat(parts, ";")
end

UI.Flags["server/statuses"] = {
    Get = encodeStatuses,
    Set = function(value)
        local nextMap = {}
        if type(value) == "string" then
            for id, status in value:gmatch("(%d+)=([%a]+)") do
                if status == "ignore" or status == "friendly" or status == "prioritize" then
                    nextMap[id] = status
                end
            end
        end
        local stale = {}
        for key in statuses do
            stale[#stale + 1] = key
        end
        for index = 1, #stale do
            statuses[stale[index]] = nil
        end
        for id, status in nextMap do
            statuses[id] = status
        end
        if alive then
            rebuildPlayers()
        end
    end,
}

local function paintServers()
    local theme = UI.Config.Theme
    serverStroke.Color = theme.Shadow
    if serverScroll then
        serverScroll.ScrollBarImageColor3 = theme.Accent
    end
    for index = 1, #serverEntries do
        local entry = serverEntries[index]
        if entry.Label.Parent then
            entry.Stroke.Color = theme.TextOutline
            local selected = entry.Id == selectedJob
            entry.Label.TextColor3 = selected and theme.Accent or theme.Text
            entry.Button.BackgroundColor3 = theme.Inline
            entry.Button.BackgroundTransparency = selected and 0 or 1
        end
    end
end

rebuildServers = function(list, message)
    local y = serverScroll.CanvasPosition.Y
    for _, child in serverScroll:GetChildren() do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    table.clear(serverEntries)
    serverCache = {}
    if type(list) == "table" then
        for index = 1, #list do
            serverCache[index] = list[index]
        end
        table.sort(serverCache, function(a, b)
            if a.playing ~= b.playing then
                if serverSort == "least" then
                    return a.playing < b.playing
                end
                return a.playing > b.playing
            end
            if a.ping ~= b.ping then
                return a.ping < b.ping
            end
            return a.id < b.id
        end)
    end
    local still = false
    for index = 1, #serverCache do
        if serverCache[index].id == selectedJob then
            still = true
            break
        end
    end
    if not still then
        selectedJob = nil
    end
    if #serverCache == 0 then
        local holder = tag("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, UI.Config.TextSize + 4),
            Parent = serverScroll,
        })
        local label, stroke = textLabel(holder, message or "no servers")
        label.TextColor3 = UI.Config.Theme.SubText
        stroke.Color = UI.Config.Theme.TextOutline
    end
    for index = 1, #serverCache do
        local server = serverCache[index]
        local button = tag("TextButton", {
            Name = string.sub(server.id, -4),
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, UI.Config.TextSize + 4),
            LayoutOrder = index,
            Parent = serverScroll,
        })
        local caption = string.format("%d/%d  %dms  %s", server.playing, server.max, math.floor(server.ping), string.sub(server.id, -4))
        local label, stroke = textLabel(button, caption)
        serverEntries[#serverEntries + 1] = { Id = server.id, Button = button, Label = label, Stroke = stroke }
        button.MouseButton1Click:Connect(function()
            selectedJob = server.id
            paintServers()
        end)
    end
    serverScroll.CanvasPosition = Vector2.new(0, y)
    paintServers()
end

local function httpGet(url)
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(body) == "string" and #body > 2 then
        return body
    end
    local genv = getgenv()
    local req = genv.request or genv.http_request
    if type(genv.syn) == "table" and type(genv.syn.request) == "function" then
        req = genv.syn.request
    elseif type(genv.http) == "table" and type(genv.http.request) == "function" then
        req = genv.http.request
    end
    if type(req) ~= "function" then
        return
    end
    local okReq, res = pcall(req, { Url = url, Method = "GET" })
    if okReq and type(res) == "table" and type(res.Body) == "string" then
        return res.Body
    end
end

local function fetchServers()
    local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"
    local body = httpGet(url)
    if type(body) ~= "string" then
        return nil
    end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if not ok or type(decoded) ~= "table" or type(decoded.data) ~= "table" then
        return nil
    end
    local list = {}
    for index = 1, #decoded.data do
        local row = decoded.data[index]
        if type(row) == "table" and type(row.id) == "string" and row.id ~= game.JobId then
            local playing = tonumber(row.playing) or 0
            local maxPlayers = tonumber(row.maxPlayers) or 0
            if maxPlayers <= 0 or playing < maxPlayers then
                list[#list + 1] = {
                    id = row.id,
                    playing = playing,
                    max = maxPlayers > 0 and maxPlayers or playing,
                    ping = tonumber(row.ping) or 0,
                }
            end
        end
    end
    return list
end

local function serverLink(jobId)
    return string.format("https://www.roblox.com/games/%d?gameInstanceId=%s", game.PlaceId, jobId)
end

local guidPattern = "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"
local function parseLink(text)
    if type(text) ~= "string" then
        return
    end
    local id = text:match("gameInstanceId=(" .. guidPattern .. ")")
        or text:match("gameInstanceId%%3D(" .. guidPattern .. ")")
        or text:match("[Jj]obId=(" .. guidPattern .. ")")
        or text:match("^%s*(" .. guidPattern .. ")%s*$")
        or text:match("(" .. guidPattern .. ")")
    if not id then
        return
    end
    local place = tonumber(text:match("placeId=(%d+)")) or tonumber(text:match("games/(%d+)")) or game.PlaceId
    return id, place
end

local function readClipboard()
    if type(getclipboard) == "function" then
        local ok, text = pcall(getclipboard)
        if ok and type(text) == "string" then
            return text
        end
    end
    local genv = getgenv()
    if type(genv.clipboard) == "table" and type(genv.clipboard.get) == "function" then
        local ok, text = pcall(genv.clipboard.get)
        if ok and type(text) == "string" then
            return text
        end
    end
end

local function writeClipboard(text)
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, text)
        if ok then
            return true
        end
    end
    if type(toclipboard) == "function" then
        local ok = pcall(toclipboard, text)
        if ok then
            return true
        end
    end
    return false
end

local function joinJob(jobId, placeId)
    if not alive or gate.Joining then
        return
    end
    if type(jobId) ~= "string" or jobId == "" then
        UI:Notify("select a server", 3)
        return
    end
    placeId = tonumber(placeId) or game.PlaceId
    if jobId == game.JobId and placeId == game.PlaceId then
        UI:Notify("already in that server", 3)
        return
    end
    gate.Joining = true
    UI:Notify("joining server", 3)
    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
    end)
    if not ok then
        gate.Joining = false
        UI:Notify("join failed", 3)
    end
end

local function selectedServer()
    for index = 1, #serverCache do
        if serverCache[index].id == selectedJob then
            return serverCache[index]
        end
    end
end

serversBox:Button("copy link", function()
    local server = selectedServer()
    if not server then
        UI:Notify("select a server", 3)
        return
    end
    if writeClipboard(serverLink(server.id)) then
        UI:Notify("copied server link", 3)
    else
        UI:Notify("clipboard unavailable", 3)
    end
end):Add("join", function()
    local server = selectedServer()
    if not server then
        UI:Notify("select a server", 3)
        return
    end
    joinJob(server.id, game.PlaceId)
end)

joinBox:Button("clip join", function()
    local id, place = parseLink(readClipboard() or "")
    if not id then
        UI:Notify("clipboard has no server", 3)
        return
    end
    joinJob(id, place)
end)

joinBox:Toggle("rejoin on votekick", false, function(on)
    gate.Rejoin = on and true or false
end)

track(TeleportService.TeleportInitFailed:Connect(function()
    gate.Joining = false
    if alive then
        UI:Notify("join failed", 3)
    end
end))

local function isSelf(name, id)
    local lp = Players.LocalPlayer
    if not lp then
        return false
    end
    if typeof(name) == "Instance" and name:IsA("Player") then
        id = id or name.UserId
        name = name.Name
    end
    if tonumber(id) == lp.UserId then
        return true
    end
    if type(name) ~= "string" then
        return false
    end
    local lowered = name:lower()
    return lowered == lp.Name:lower() or lowered == tostring(lp.DisplayName):lower()
end

local function hopNew()
    task.spawn(function()
        local list = fetchServers()
        if not alive then
            return
        end
        if type(list) == "table" and #list > 0 then
            local pick = list[math.random(1, math.min(#list, 12))]
            joinJob(pick.id, game.PlaceId)
            return
        end
        if gate.Joining then
            return
        end
        gate.Joining = true
        UI:Notify("rejoining", 3)
        local ok = pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
        if not ok then
            gate.Joining = false
            UI:Notify("join failed", 3)
        end
    end)
end

local function onVote(name, id)
    if not alive or not gate.Rejoin or gate.Joining then
        return
    end
    if not isSelf(name, id) then
        return
    end
    if os.clock() - (gate.LastHop or 0) < 8 then
        return
    end
    gate.LastHop = os.clock()
    UI:Notify("votekick started, rejoining", 3)
    hopNew()
end

local remote = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvent")
if remote and remote:IsA("RemoteEvent") then
    track(remote.OnClientEvent:Connect(function(...)
        local args = { ... }
        for index = 1, math.min(#args, 4) do
            if args[index] == "startvotekick" then
                onVote(args[index + 1], args[index + 3])
                return
            end
        end
    end))
end

local voteHooked = false
local function hookVoteGui()
    if voteHooked then
        return true
    end
    local pg = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local display = pg and pg:FindFirstChild("ChatScreenGui")
    display = display and display:FindFirstChild("Main")
    display = display and display:FindFirstChild("DisplayVoteKick")
    if not display then
        return false
    end
    voteHooked = true
    local title = display:FindFirstChild("TextTitle")
    local idLabel = display:FindFirstChild("TextID")
    local function check()
        if not alive or not display.Parent or not display.Visible then
            return
        end
        local name = title and title.Text:match("^Votekick%s+(.-)%s+out")
        local id = idLabel and idLabel.Text:match("(%d+)")
        onVote(name, id)
    end
    track(display:GetPropertyChangedSignal("Visible"):Connect(check))
    if title then
        track(title:GetPropertyChangedSignal("Text"):Connect(check))
    end
    check()
    return true
end

task.spawn(function()
    for _ = 1, 30 do
        if not alive then
            return
        end
        if hookVoteGui() then
            return
        end
        task.wait(1)
    end
end)

rebuildPlayers()
rebuildServers(nil, "loading")

task.spawn(function()
    local list = fetchServers()
    if not alive then
        return
    end
    if list == nil then
        rebuildServers(nil, "unavailable")
    else
        rebuildServers(list)
    end
    while alive do
        task.wait(15)
        if not alive then
            return
        end
        list = fetchServers()
        if not alive then
            return
        end
        if list == nil then
            rebuildServers(serverCache, "unavailable")
        else
            rebuildServers(list)
        end
    end
end)

track(Players.PlayerAdded:Connect(function()
    if alive then
        rebuildPlayers()
    end
end))
track(Players.PlayerRemoving:Connect(function()
    if alive then
        task.defer(function()
            if alive then
                rebuildPlayers()
            end
        end)
    end
end))

table.insert(UI.Refreshers, function()
    if alive then
        paintPlayers()
        paintServers()
    end
end)
end)
if not okMenu then
    getgenv()._TapologyMenuErr = tostring(errMenu)
    warn("[Tapology] menu build failed:", errMenu)
elseif not okServer then
    getgenv()._TapologyMenuErr = tostring(errServer)
    warn("[Tapology] menu build failed:", errServer)
else
    getgenv()._TapologyMenuErr = nil
    local list1 = Library and Library.Gui and Library.Gui:FindFirstChild("Window")
        and Library.Gui.Window:FindFirstChild("Tabs")
        and Library.Gui.Window.Tabs:FindFirstChild("List")
    local count1 = 0
    if list1 then
        for _, child in list1:GetChildren() do
            if child:IsA("TextButton") then
                count1 += 1
            end
        end
    end
    if count1 >= 6 then
        getgenv()._TapologyMenuBuilt = menuGeneration
        local purge = getgenv()._TapologyPurgeGuis
        if type(purge) == "function" then
            purge(Library and Library.Gui)
        end
    else
        getgenv()._TapologyMenuBuilt = nil
        getgenv()._TapologyMenuErr = "incomplete tab strip (" .. tostring(count1) .. ")"
    end
end
end
task.defer(buildTapologyMenu)
task.delay(0.35, buildTapologyMenu)
task.delay(1.25, buildTapologyMenu)
getgenv()._TapologyScriptTail = os.clock()
getgenv()._TapologyMenuGenAtTail = menuGeneration
