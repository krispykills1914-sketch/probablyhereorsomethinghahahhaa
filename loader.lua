local ModuleUrls = {
    library = "https://raw.githubusercontent.com/krispykills1914-sketch/probablyhereorsomethinghahahhaa/main/library.lua",
    weather = "https://raw.githubusercontent.com/krispykills1914-sketch/probablyhereorsomethinghahahhaa/main/weather.lua",
    hiteffect = "https://raw.githubusercontent.com/krispykills1914-sketch/probablyhereorsomethinghahahhaa/main/hiteffect.lua",
    killeffect = "https://raw.githubusercontent.com/krispykills1914-sketch/probablyhereorsomethinghahahhaa/main/killeffect.lua",
    tracer = "https://raw.githubusercontent.com/krispykills1914-sketch/probablyhereorsomethinghahahhaa/main/tracer.lua",
}

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
    getgenv()._TapologyLibraryPatch = table.concat(hits, ",")
    return src
end

local ModuleRoot = "c:/Users/1223/Downloads/roblox resources/Tapology Resources/Visuals/modules"

local function moduleAlreadyLoaded(name)
    if name == "library" then
        local ui = getgenv().Tapology or getgenv().Library
        return type(ui) == "table" and type(ui.Unload) == "function" and ui.Gui ~= nil
    elseif name == "weather" then
        return type(getgenv().Weather) == "table" and type(getgenv().Weather.SetMode) == "function"
    elseif name == "hiteffect" then
        return type(getgenv().HitEffects) == "table"
    elseif name == "killeffect" then
        return type(getgenv().KillEffects) == "table"
    elseif name == "tracer" then
        return type(getgenv().Tracers) == "table"
    end
    return false
end

local function loadRemote(name)
    if getgenv()._TapologyUseLocalModules and moduleAlreadyLoaded(name) then
        getgenv()._TapologyModuleSource = getgenv()._TapologyModuleSource or {}
        getgenv()._TapologyModuleSource[name] = "local"
        return
    end
    local src
    local localPath = `{ModuleRoot}/{name}.lua`
    if type(readfile) == "function" then
        local okLocal, data = pcall(readfile, localPath)
        if okLocal and type(data) == "string" and #data > 20 then
            src = data
            getgenv()._TapologyModuleSource = getgenv()._TapologyModuleSource or {}
            getgenv()._TapologyModuleSource[name] = "local"
        end
    end
    if not src then
        local url = ModuleUrls[name]
        if type(url) ~= "string" or url:find("YOUR_HOST", 1, true) then
            warn("[Tapology]", name, "url is not set")
            return
        end
        local ok, data = pcall(function()
            return game:HttpGet(url)
        end)
        if not ok or type(data) ~= "string" or #data < 20 then
            warn("[Tapology]", name, "download failed:", data)
            return
        end
        src = data
        getgenv()._TapologyModuleSource = getgenv()._TapologyModuleSource or {}
        getgenv()._TapologyModuleSource[name] = "remote"
        if name == "library" then
            src = patchLibrary(src)
        end
    end
    local fn, err = loadstring(src, "@" .. name)
    if not fn then
        warn("[Tapology]", name, "did not compile:", err)
        return
    end
    local ran, result = pcall(fn)
    if not ran then
        warn("[Tapology]", name, "failed:", result)
    end
end

do
    local prevServer = getgenv()._TapologyServer
    if type(prevServer) == "table" and type(prevServer.Stop) == "function" then
        pcall(prevServer.Stop)
    end
    for _, key in { "Tapology", "Library" } do
        local stub = getgenv()[key]
        if type(stub) ~= "table" or type(stub.Unload) ~= "function" then
            getgenv()[key] = nil
        end
    end
end
loadRemote("library")
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

local function phantomTargets(list)
    local root = workspace:FindFirstChild("Players")
    if not root then return end
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
                    table.insert(list, {
                        Key = name,
                        Player = player,
                        Name = displayName(player, name),
                        Root = info.Root,
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
        for _, inst in adorns do
            inst:Destroy()
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

local function applyAdornments(target, visible)
    local key = target.Key
    local list = Adornments[key]
    if not list then
        list = {}
        Adornments[key] = list
    end
    local mode = visible and "HighlightVisible" or "HighlightOccluded"
    local color = Config[mode .. "FillColor"]
    local always, transparency = adornLook(Config.AdornmentType, Config.AdornmentGlow)
    local kind = Config.AdornmentType
    local wanted = 0
    for _, part in target.Parts or {} do
        if part and part.Parent and part:IsA("BasePart") and wanted < 14 then
            wanted += 1
            local box = list[wanted]
            if not box then
                box = Instance.new("BoxHandleAdornment")
                box.Name = key
                box.Parent = HighlightParent
                list[wanted] = box
                if kind == "glow 2x" then
                    local outer = Instance.new("BoxHandleAdornment")
                    outer.Name = key .. " glow"
                    outer.Parent = HighlightParent
                    list[wanted + 100] = outer
                end
            end
            box.Adornee = part
            box.Size = part.Size
            box.AlwaysOnTop = always
            box.ZIndex = 2
            box.Color3 = color
            box.Transparency = transparency
            box.Visible = true
            local outer = list[wanted + 100]
            if outer then
                outer.Adornee = part
                outer.Size = part.Size * 1.08
                outer.AlwaysOnTop = true
                outer.ZIndex = 1
                outer.Color3 = color
                outer.Transparency = math.clamp(transparency + 0.25, 0, 0.92)
                outer.Visible = kind == "glow 2x"
            end
        end
    end
    for index, inst in list do
        local slot = index > 100 and index - 100 or index
        if slot > wanted and inst then
            inst.Visible = false
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
            if adorns then
                for _, inst in adorns do
                    inst.Visible = false
                end
            end
        end
        return
    end
    local adorns = Adornments[key]
    if adorns then
        Adornments[key] = nil
        for _, inst in adorns do
            inst:Destroy()
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
        piece.AnchorPoint = Vector2.new(0.5, 0.5)
        piece.Position = UDim2.new(0.5, x, 0.5, 0)
        piece.Size = UDim2.fromOffset(3, 11)
        piece.Rotation = rot
        piece.BorderSizePixel = 0
        piece.Parent = holder
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = piece
        return piece
    end
    arrow = { Holder = holder, A = bar(36, -3), B = bar(-36, 3) }
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

local function placeArrow(key, camera, world, onScreen)
    local arrow = arrowFor(key)
    if not Config.OOV or onScreen then
        arrow.Holder.Visible = false
        return
    end
    local screen = camera:WorldToViewportPoint(world)
    local center = camera.ViewportSize * 0.5
    local dir = Vector2.new(screen.X - center.X, screen.Y - center.Y)
    if screen.Z <= 0 then
        dir = -dir
    end
    if dir.Magnitude < 1 then
        dir = Vector2.new(0, -1)
    else
        dir = dir.Unit
    end
    local radius = math.clamp(tonumber(Config.OOVRadius) or 180, 40, 500)
    local pos = center + dir * radius
    local size = math.clamp(tonumber(Config.OOVSize) or 16, 8, 32)
    arrow.Holder.Visible = true
    arrow.Holder.Position = UDim2.fromOffset(pos.X, pos.Y)
    arrow.Holder.Size = UDim2.fromOffset(size, size)
    arrow.Holder.Rotation = math.deg(math.atan2(dir.Y, dir.X))
    arrow.A.BackgroundColor3 = Config.OOVColor
    arrow.B.BackgroundColor3 = Config.OOVColor
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
        target.Distance = (target.Root.Position - cameraPosition).Magnitude
    end
    table.sort(targets, function(a, b)
        return a.Distance < b.Distance
    end)

    table.clear(seen)
    for rank, target in ipairs(targets) do
        local distance = target.Distance
        updateHighlight(target, distance <= Config.MaxDistance and rank or math.huge, cameraPosition)
        local rootCFrame, low, high
        if distance <= Config.MaxDistance then
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
            placeArrow(target.Key, camera, target.Root.Position, true)
        else
            local line = Snaplines[target.Key]
            if line then
                line.Frame.Visible = false
            end
            if target.Root then
                placeArrow(target.Key, camera, target.Root.Position, false)
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
    Class = "assault",
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

local WeaponClasses = { "assault", "pdw", "lmg", "sniper", "shotgun", "pistol" }
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
for _, name in WeaponClasses do
    Config.Profiles[name] = profileFrom(Config)
end

local function applyHeldProfile()
    local held = (getgenv and getgenv().TapologyWeaponClass) or Config.Class or "assault"
    if Config.Profiles[held] == nil then
        held = "assault"
    end
    local profile = Config.Profiles[held]
    if not profile then
        return
    end
    Config.MouseEnabled = profile.MouseEnabled
    Config.SilentEnabled = profile.SilentEnabled
    Config.MouseFOV = profile.MouseFOV
    Config.MouseShowFOV = profile.MouseShowFOV
    Config.MouseFOVOrigin = profile.MouseFOVOrigin
    Config.SilentFOV = profile.SilentFOV
    Config.SilentShowFOV = profile.SilentShowFOV
    Config.SilentFOVOrigin = profile.SilentFOVOrigin
    Config.Smoothness = profile.Smoothness
    Config.MouseKey = profile.MouseKey
    Config.HitChance = profile.HitChance
    Config.TargetPart = profile.TargetPart
    Config.VisibleCheck = profile.VisibleCheck
    Config.MaxDistance = profile.MaxDistance
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

local function drawCircle(circle, shown, radius, color, transparency, cursor)
    circle.Holder.Visible = shown
    if not shown then return end
    circle.Holder.Position = UDim2.fromOffset(math.floor(cursor.X + 0.5), math.floor(cursor.Y + 0.5))
    local size = math.floor(radius + 0.5) * 2
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
    drawCircle(Circles.Mouse, Config.Mouse and Config.MouseShowFOV, Config.MouseFOV, Config.MouseFOVColor, Config.MouseFOVTransparency, mouseOrigin)
    drawCircle(Circles.Silent, Config.Silent and Config.SilentShowFOV, Config.SilentFOV, Config.SilentFOVColor, Config.SilentFOVTransparency, silentOrigin)

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

            local share = 1 - math.clamp(Config.Smoothness, 0, 0.98) ^ (dt * 60)
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
    SkyboxId = "Pink Daylight",
    Skyboxes = {
        ["Pink Daylight"] = {
            SkyboxBk = "rbxassetid://271042516",
            SkyboxDn = "rbxassetid://271077243",
            SkyboxFt = "rbxassetid://271042556",
            SkyboxLf = "rbxassetid://271042310",
            SkyboxRt = "rbxassetid://271042467",
            SkyboxUp = "rbxassetid://271077958",
        },
        ["Purple Nebula"] = {
            SkyboxBk = "rbxassetid://159454299",
            SkyboxDn = "rbxassetid://159454296",
            SkyboxFt = "rbxassetid://159454293",
            SkyboxLf = "rbxassetid://159454286",
            SkyboxRt = "rbxassetid://159454300",
            SkyboxUp = "rbxassetid://159454288",
        },
        ["Night Sky"] = {
            SkyboxBk = "rbxassetid://12064107",
            SkyboxDn = "rbxassetid://12064152",
            SkyboxFt = "rbxassetid://12064121",
            SkyboxLf = "rbxassetid://12063984",
            SkyboxRt = "rbxassetid://12064115",
            SkyboxUp = "rbxassetid://12064131",
        },
        ["Cloudy"] = {
            SkyboxBk = "rbxassetid://151165214",
            SkyboxDn = "rbxassetid://151165197",
            SkyboxFt = "rbxassetid://151165224",
            SkyboxLf = "rbxassetid://151165191",
            SkyboxRt = "rbxassetid://151165206",
            SkyboxUp = "rbxassetid://151165227",
        },
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
local function restoreFog()
    if weatherOwnsEnvironment() then
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
    if not weatherOwnsEnvironment() then
        return false
    end

    if Grade and Grade.Parent then
        Grade.Enabled = false
    end
    if BloomEffect and BloomEffect.Parent then
        BloomEffect.Enabled = false
    end
    return true
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
    if yieldToWeather() then
        return
    end
    if not Config.Fog then return restoreFog() end
    local atmosphere = ensureAtmosphere()
    atmosphere.Density = Config.FogDensity
    atmosphere.Offset = Config.FogOffset
    atmosphere.Haze = Config.FogHaze
    atmosphere.Glare = Config.FogGlare
    scheduleWorldColors()
end
local function applyGrade()
    if yieldToWeather() then
        return
    end
    local grade = ensureGrade()
    grade.Enabled = Config.ColorCorrection
    if not Config.ColorCorrection then return restoreGrade() end
    grade.Saturation = Config.Saturation
    grade.Contrast = Config.Contrast
    grade.Brightness = Config.CorrectionBrightness
    scheduleWorldColors()
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
    if yieldToWeather() then
        return
    end
    local bloom = ensureBloom()
    bloom.Enabled = Config.Bloom
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
        SkyInstance[key] = value
    end
end

local function dynamicTarget()
    local hour = Lighting.ClockTime
    local night = hour < 6 or hour > 19
    local dusk = (hour >= 6 and hour < 8) or (hour > 17 and hour <= 19)
    local base = night and Config.DynamicExposureMax or (dusk and Config.DynamicExposureMax * 0.45 or Config.DynamicExposureMin)
    local outdoor = (Config.Ambience and Config.OutdoorAmbient or Lighting.OutdoorAmbient)
    local luma = outdoor.R * 0.3 + outdoor.G * 0.59 + outdoor.B * 0.11
    return math.clamp(base + (0.5 - luma) * 0.6, Config.DynamicExposureMin, Config.DynamicExposureMax)
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

local function forceApplyWorld()
    if yieldToWeather() then
        return
    end
    if Config.Clock then
        applyClock()
    end
    if Config.Lighting then
        Lighting.Brightness = Config.Brightness
        if not Config.DynamicExposure then
            Lighting.ExposureCompensation = Config.ExposureCompensation
        end
    end
    if Config.Fog then
        local atmosphere = ensureAtmosphere()
        atmosphere.Density = Config.FogDensity
        atmosphere.Offset = Config.FogOffset
        atmosphere.Haze = Config.FogHaze
        atmosphere.Glare = Config.FogGlare
    end
    if Config.ColorCorrection then
        local grade = ensureGrade()
        grade.Enabled = true
        grade.Saturation = Config.Saturation
        grade.Contrast = Config.Contrast
        grade.Brightness = Config.CorrectionBrightness
    end
    if Config.Bloom then
        applyBloom()
    end
    if Config.DepthOfField then
        applyDoF()
    end
    if Config.Skybox then
        applySkybox()
    end
    applyCelestial()
    scheduleWorldColors()
end

forceWorldColors = function()
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
    if Config.Fog then
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or ensureAtmosphere()
        if typeof(Config.FogColor) == "Color3" then
            atmosphere.Color = Color3.new(Config.FogColor.R, Config.FogColor.G, Config.FogColor.B)
        end
        if typeof(Config.FogDecay) == "Color3" then
            atmosphere.Decay = Color3.new(Config.FogDecay.R, Config.FogDecay.G, Config.FogDecay.B)
        end
    end
    if Config.ColorCorrection then
        local grade = ensureGrade()
        grade.Enabled = true
        if typeof(Config.TintColor) == "Color3" then
            grade.TintColor = Color3.new(Config.TintColor.R, Config.TintColor.G, Config.TintColor.B)
        end
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
            task.wait(0.35)
            pinWeatherEnvironment()
            yieldToWeather()
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
table.insert(Connections, RunService.Heartbeat:Connect(function()
    local now = os.clock()
    if weatherOwnsEnvironment() then
        if now - lastWorldForce >= 2 then
            lastWorldForce = now
            pinWeatherEnvironment()
            yieldToWeather()
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
            applyAmbience()
            if Config.Lighting then
                applyLighting()
            end
        elseif slot == "FogColor" or slot == "FogDecay" then
            applyFog()
        elseif slot == "TintColor" then
            applyGrade()
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

local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local GuiService = cloneref(game:GetService("GuiService"))

local Config = {

    Enabled = false,
    Priority = "Closest to Crosshair",
    FirePositionScanning = true,
    FirePositionOffset = 10,
    HitPositionScanning = true,
    ConstrainHitPositions = true,
    Prediction = true,
    PredictionWindow = 0.12,
    PredictionIterations = 8,
    PredictionMaxTime = 5,
    MaxPredictionSpeed = 150,
    PredictionResetDistance = 20,
    HitboxPointScale = 0.35,
    HitPositionScanMode = "V1",
    HitPositionOffset = 10,
    ShootEffects = true,
    UseFOV = false,
    FOVRadius = 350,
    MaxDistance = 1500,
    MaxTargets = 12,
    MaxBulletChecks = 40,
    MaxFrameChecks = 128,
    ScanBudgetMs = 5,
    ScanMissCooldown = 0.01,
    ModuleTimeout = 15,

    Mode = "default",
    WhitelistFriendlyStatus = true,
    Targets = {},
    Friendlies = {},

    Resolver = false,
    ResolverCooldown = 1.0,
    ResolverStrength = 4,
    ResolverHeight = 0.35,
    ResolverHold = 0.45,
    ResolverFlash = 0.35,

    AntiAim = false,
    PitchAmount = 0,
    YawAmount = 180,
    PitchType = "static",
    YawType = "static",
    PitchWays = 7,
    YawWays = 7,
    AASpeed = 6,
    FakePosition = false,
    FakePositionDistance = 4,
    FakePositionHeight = 0,
    RageVisual = false,
    ShowScanRange = false,
    ScanRangeVisual = 80,

    FakeLag = false,
    FakeLagAmount = 1.2,
    FakeLagHold = 0.35,
    FakeLagSmooth = 0.45,

    Indicators = true,
    IndicatorRagebot = true,
    IndicatorResolver = true,
    IndicatorRageActive = Color3.fromRGB(255, 255, 255),
    IndicatorRageIdle = Color3.fromRGB(255, 255, 255),
    IndicatorResolverReady = Color3.fromRGB(255, 255, 255),
    IndicatorResolverCooldown = Color3.fromRGB(180, 180, 190),
}

local env = getgenv and getgenv() or _G
if env.RageBot and env.RageBot.Unload then
    pcall(env.RageBot.Unload)
end
if env.Rage and env.Rage.Unload then
    pcall(env.Rage.Unload)
end

local LocalPlayer = Players.LocalPlayer
local PhantomForces = game.PlaceId == 292439477 or game.PlaceId == 299659045
local Connections = {}
local Restores = {}
local Unloaded = false
local Controller
local Runtime = { Status = "Starting", LastError = nil, Checks = 0, ScanMisses = 0, Shots = 0 }

local Modules
if PhantomForces and type(getfflag) == "function" and type(setfflag) == "function" then
    pcall(function()
        if tostring(getfflag("DebugRunParallelLuaOnMainThread")):lower() ~= "true" then
            setfflag("DebugRunParallelLuaOnMainThread", "True")
        end
    end)
end

local moduleNames = {
    "ScreenCull", "NetworkClient", "ReplicationInterface", "BulletCheck",
    "CharacterInterface", "GameClock", "PublicSettings", "WeaponControllerInterface",
    "Effects", "AudioSystem", "HudCrosshairsInterface", "RoundSystemClientFactory", "CameraInterface",
}

local function usableModules(modules)
    return type(modules) == "table"
        and type(modules.NetworkClient) == "table" and type(modules.NetworkClient.send) == "function"
        and type(modules.ReplicationInterface) == "table"
        and type(modules.ReplicationInterface.operateOnAllEntries) == "function"
        and type(modules.WeaponControllerInterface) == "table"
        and type(modules.WeaponControllerInterface.getActiveWeaponController) == "function"
        and type(modules.BulletCheck) == "function"
        and type(modules.PublicSettings) == "table"
end

local function findModules()
    if env._TapologyModules and usableModules(env._TapologyModules) then
        return env._TapologyModules
    end
    if shared and type(shared.require) == "function" then
        local found = {}
        for _, name in ipairs(moduleNames) do
            local ok, value = pcall(shared.require, name)
            if ok then
                found[name] = value
            end
        end
        if usableModules(found) then
            return found
        end
    end
    if type(getgc) ~= "function" then
        return
    end
    for _, value in ipairs(getgc(true)) do
        if type(value) == "table" and rawget(value, "ScreenCull") and rawget(value, "NetworkClient") then
            local found = {}
            for name, data in pairs(value) do
                found[name] = type(data) == "table" and rawget(data, "module") ~= nil and rawget(data, "module") or data
            end
            if usableModules(found) then
                return found
            end
        end
    end
end

local function number(value, fallback, low, high)
    value = tonumber(value)
    if not value or value ~= value then
        value = fallback
    end
    return math.clamp(value, low, high)
end

local function playerMark(player)
    local map = env.TapologyPlayerStatus
    if type(map) ~= "table" or not player then
        return
    end
    return map[tostring(player.UserId)]
end

local function marked(player)
    local status = playerMark(player)
    if status == "ignore" or status == "friendly" then
        return false
    end
    if Config.WhitelistFriendlyStatus and Config.Friendlies[player] then
        return false
    end
    return true
end

local function isFiniteVec3(v)
    return typeof(v) == "Vector3"
        and v.X == v.X and v.Y == v.Y and v.Z == v.Z
        and math.abs(v.X) < 1e6 and math.abs(v.Y) < 1e6 and math.abs(v.Z) < 1e6
end

local function characterHash(entry)
    return entry and entry._thirdPersonObject and entry._thirdPersonObject._characterModelHash
end

local function entryAimPos(entry)
    local hash = characterHash(entry)
    if hash and hash.Head and isFiniteVec3(hash.Head.Position) then
        return hash.Head.Position
    end
    return entry._receivedPosition
end

local function entryHealth(entry)
    if entry.getHealth then
        local ok, hp = pcall(entry.getHealth, entry)
        if ok and type(hp) == "number" then
            return hp
        end
    end
    if type(entry._health) == "number" then
        return entry._health
    end
    return 100
end

local function priorityScore(entry, origin, camera, mouse)
    local position = entryAimPos(entry)
    if not isFiniteVec3(position) then
        return math.huge
    end
    local distance = (position - origin).Magnitude
    if distance > number(Config.MaxDistance, 1500, 1, 10000) then
        return math.huge
    end
    local screenScore
    if camera then
        local screen, onScreen = camera:WorldToViewportPoint(position)
        if onScreen and screen.Z > 0 then
            local dx, dy = screen.X - mouse.X, screen.Y - mouse.Y
            screenScore = dx * dx + dy * dy
        end
    end
    if Config.UseFOV then
        local radius = number(Config.FOVRadius, 350, 1, 5000)
        if not screenScore or screenScore > radius * radius then
            return math.huge
        end
    end
    if Config.Priority == "Closest to Local" then
        return distance
    end
    if Config.Priority == "Lowest Health" then
        return entryHealth(entry) + distance * 0.001
    end
    return screenScore or (1e9 + distance)
end

local frameCheckBudget, frameCheckDeadline = 0, 0
local ScanStates = setmetatable({}, { __mode = "k" })

local function getClosestPlayers(origin)
    local ordered = {}
    if not (Modules and Modules.ReplicationInterface) then
        return ordered
    end
    local camera = workspace.CurrentCamera
    local mouse = UserInputService:GetMouseLocation()
    local okInset, inset = pcall(GuiService.GetGuiInset, GuiService)
    if okInset then
        mouse = mouse - inset
    end
    local scored = {}
    local ok, reason = pcall(Modules.ReplicationInterface.operateOnAllEntries, function(player, entry)
        local hash = characterHash(entry)
        if not player or not player.Parent or not entry._isEnemy or not hash or not hash.Head or not marked(player) then
            return
        end
        if entryHealth(entry) <= 0 then
            return
        end
        local score = priorityScore(entry, origin, camera, mouse)
        if score ~= score or score == math.huge then
            return
        end
        scored[#scored + 1] = {
            entry = entry,
            score = score,
            selected = Config.Targets[player] == true or playerMark(player) == "prioritize",
            id = player.UserId or 0,
        }
    end)
    if not ok then
        Runtime.LastError = tostring(reason)
        return ordered
    end
    table.sort(scored, function(a, b)
        if a.selected ~= b.selected then
            return a.selected
        end
        if a.score == b.score then
            return a.id < b.id
        end
        return a.score < b.score
    end)
    for index = 1, math.min(#scored, number(Config.MaxTargets, 12, 1, 12)) do
        ordered[index] = scored[index].entry
    end
    return ordered
end

local function trajectory(origin, acceleration, target, speed)
    if not isFiniteVec3(origin) or not isFiniteVec3(acceleration) or not isFiniteVec3(target)
        or type(speed) ~= "number" or speed ~= speed or speed <= 0 or speed == math.huge
    then
        return
    end
    local delta = target - origin
    local distanceSquared = delta:Dot(delta)
    if distanceSquared < 1e-8 then
        return
    end
    local a = acceleration:Dot(acceleration) * 0.25
    if a < 1e-12 then
        return delta.Unit * speed, math.sqrt(distanceSquared) / speed
    end
    local b = -(delta:Dot(acceleration) + speed * speed)
    local discriminant = b * b - 4 * a * distanceSquared
    if discriminant < 0 then
        return
    end
    local root = math.sqrt(discriminant)
    local q = -0.5 * (b + (b >= 0 and root or -root))
    local first = q / a
    local second = q ~= 0 and distanceSquared / q or math.huge
    local timeSquared = math.min(first > 0 and first or math.huge, second > 0 and second or math.huge)
    if timeSquared == math.huge then
        return
    end
    local flightTime = math.sqrt(timeSquared)
    if flightTime <= 0 then
        return
    end
    local velocity = (delta - acceleration * (0.5 * timeSquared)) / flightTime
    if isFiniteVec3(velocity) then
        return velocity, flightTime
    end
end

local MotionStates = setmetatable({}, { __mode = "k" })

local function sampleMotion()
    local interface = Modules and Modules.ReplicationInterface
    if not interface then
        return
    end
    local now = os.clock()
    interface.operateOnAllEntries(function(_, entry)
        local hash = characterHash(entry)
        local head = hash and hash.Head
        if not head or not head.Parent or not entry._isEnemy or entryHealth(entry) <= 0 then
            MotionStates[entry] = nil
            return
        end
        local root = hash.Torso or hash.UpperTorso or head
        if not root.Parent then
            root = head
        end
        local position = root.Position
        if not isFiniteVec3(position) then
            return
        end
        local state = MotionStates[entry]
        local jumpLimit = number(Config.PredictionResetDistance, 20, 2, 100)
        if not state or state.Head ~= head or (position - state.Position).Magnitude > jumpLimit then
            state = {
                Head = head,
                Position = position,
                Samples = {},
                Velocity = Vector3.zero,
                ResetAt = state and now or nil,
            }
            MotionStates[entry] = state
        end
        local samples = state.Samples
        local last = samples[#samples]
        if last and now - last.Time < 0.005 then
            return
        end
        samples[#samples + 1] = { Time = now, Position = position }
        state.Position = position
        local window = number(Config.PredictionWindow, 0.12, 0.03, 0.3)
        while #samples > 2 and now - samples[1].Time > window do
            table.remove(samples, 1)
        end
        local count = #samples
        if count < 2 or now - samples[1].Time < 0.015 then
            return
        end
        local sumTime, sumTimeSquared = 0, 0
        local sumPosition, sumWeighted = Vector3.zero, Vector3.zero
        for _, sample in ipairs(samples) do
            local time = sample.Time - now
            local displacement = sample.Position - position
            sumTime = sumTime + time
            sumTimeSquared = sumTimeSquared + time * time
            sumPosition = sumPosition + displacement
            sumWeighted = sumWeighted + displacement * time
        end
        local denominator = count * sumTimeSquared - sumTime * sumTime
        if denominator <= 1e-10 then
            return
        end
        local velocity = (sumWeighted * count - sumPosition * sumTime) / denominator
        local maximum = number(Config.MaxPredictionSpeed, 150, 1, 500)
        if isFiniteVec3(velocity) and velocity.Magnitude <= maximum then
            state.Velocity = velocity.Magnitude < 0.5 and Vector3.zero or velocity
            state.UpdatedAt = now
        else
            state.Samples = { { Time = now, Position = position } }
            state.Velocity = Vector3.zero
            state.UpdatedAt = now
        end
    end)
end

local function targetVelocity(entry)
    if Config.Prediction == false then
        return Vector3.zero
    end
    local state = entry and MotionStates[entry]
    if state and state.ResetAt and not state.UpdatedAt and os.clock() - state.ResetAt < 0.15 then
        return Vector3.zero
    end
    if state and state.UpdatedAt and os.clock() - state.UpdatedAt < 0.15 then
        return state.Velocity
    end
    local velocity = entry and entry._velspring and entry._velspring.t
    if isFiniteVec3(velocity) and velocity.Magnitude <= number(Config.MaxPredictionSpeed, 150, 1, 500) then
        return velocity
    end
    return Vector3.zero
end

local scanVerticesV1 = {
    Vector3.new(0, 0, -1),
    Vector3.new(0, -1, 0),
    Vector3.new(-1, 0, 0),
    Vector3.new(0, 1, 0),
    Vector3.new(1, 0, 0),
    Vector3.new(0, 0, 1),
}

local scanVerticesV2 = {
    Vector3.new(1, 0, 0),
    Vector3.new(-1, 0, 0),
    Vector3.new(0, 1, 0),
    Vector3.new(0, -1, 0),
    Vector3.new(0, 0, 1),
    Vector3.new(0, 0, -1),
    Vector3.new(0.707, 0.707, 0),
    Vector3.new(0.707, -0.707, 0),
    Vector3.new(-0.707, 0.707, 0),
    Vector3.new(-0.707, -0.707, 0),
    Vector3.new(0.707, 0, 0.707),
    Vector3.new(0.707, 0, -0.707),
    Vector3.new(-0.707, 0, 0.707),
    Vector3.new(-0.707, 0, -0.707),
}

local function getPositionOffsets(origin, target, offset, mode)
    mode = mode == "V2" and "V2" or "V1"
    local maxOffset = mode == "V2" and 28 or 16
    offset = number(offset, 0, 0, maxOffset)
    if offset < 0.001 or (target - origin).Magnitude < 0.001 then
        return { origin }
    end
    local look = CFrame.new(origin, target)
    local offsets = {}

    local function push(point)
        if isFiniteVec3(point) then
            offsets[#offsets + 1] = point
        end
    end

    if mode == "V1" then
        local cframe = look
        for _, vertex in scanVerticesV1 do
            push(cframe * (vertex * offset))
        end
    else
        for _, scale in { 0.55, 1 } do
            local radius = offset * scale
            for _, vertex in scanVerticesV2 do
                push(look * (vertex * radius))
            end
        end
    end

    if #offsets == 0 then
        return { origin }
    end
    return offsets
end

local function interceptTrajectory(origin, acceleration, target, speed, movement)
    if not isFiniteVec3(movement) then
        movement = Vector3.zero
    end
    local velocity, time = trajectory(origin, acceleration, target, speed)
    if not velocity then
        return
    end
    local lifetime = Modules and Modules.PublicSettings and Modules.PublicSettings.bulletLifeTime
    local limit = type(lifetime) == "number" and lifetime > 0 and lifetime or number(Config.PredictionMaxTime, 5, 0.1, 20)
    if time > limit then
        return
    end
    if movement.Magnitude < 0.001 then
        return velocity, time, target
    end
    local iterations = math.floor(number(Config.PredictionIterations, 8, 3, 16))
    for _ = 1, iterations do
        local predicted = target + movement * time
        velocity, time = trajectory(origin, acceleration, predicted, speed)
        if not velocity or time > limit then
            return
        end
        local destination = target + movement * time
        local impact = origin + velocity * time + acceleration * (0.5 * time * time)
        if (impact - destination).Magnitude <= 0.01
            and math.abs(velocity.Magnitude - speed) <= math.max(0.001, speed * 0.00001)
        then
            return velocity, time, destination
        end
    end
end

local function headScanPoints(entry, fallback, origin)
    local hash = entry and characterHash(entry)
    local head = hash and hash.Head
    if not Config.ConstrainHitPositions or not head or not head.Parent then
        return getPositionOffsets(fallback, origin, Config.HitPositionOffset, Config.HitPositionScanMode)
    end
    local scale = number(Config.HitboxPointScale, 0.35, 0.05, 0.45)
    local offset = number(Config.HitPositionOffset, 10, 0, 28)
    local extent = head.Size * scale
    extent = Vector3.new(math.min(extent.X, offset), math.min(extent.Y, offset), math.min(extent.Z, offset))
    local vertices = {
        Vector3.new(1, 0, 0),
        Vector3.new(-1, 0, 0),
        Vector3.new(0, 1, 0),
        Vector3.new(0, -1, 0),
        Vector3.new(0, 0, 1),
        Vector3.new(0, 0, -1),
    }
    if Config.HitPositionScanMode == "V2" then
        for x = -1, 1, 2 do
            for y = -1, 1, 2 do
                for z = -1, 1, 2 do
                    vertices[#vertices + 1] = Vector3.new(x, y, z)
                end
            end
        end
    end
    local points = {}
    for _, vertex in ipairs(vertices) do
        points[#points + 1] = head.CFrame:PointToWorldSpace(
            Vector3.new(vertex.X * extent.X, vertex.Y * extent.Y, vertex.Z * extent.Z)
        )
    end
    return points
end

local function tryBulletPath(bulletCheck, origin, target, acceleration, speed, penetration, movement)
    local velocity, flightTime, predicted = interceptTrajectory(origin, acceleration, target, speed, movement)
    if not velocity then
        return false, false, nil, nil
    end
    local ok, result = pcall(bulletCheck, origin, predicted, velocity, acceleration, penetration, 1 / 50)
    return true, ok and result and true or false, velocity, flightTime, predicted
end

local function edgePeekPoints(origin, target, reach)
    local points = {}
    if not (isFiniteVec3(origin) and isFiniteVec3(target)) then
        return points
    end
    reach = number(reach, 10, 0.25, 12)
    local delta = target - origin
    local dist = delta.Magnitude
    if dist < 1.5 then
        return points
    end
    local dir = delta.Unit
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = {}
    if LocalPlayer.Character then
        ignore[#ignore + 1] = LocalPlayer.Character
    end
    local interface = Modules and Modules.ReplicationInterface
    if interface then
        pcall(interface.operateOnAllEntries, function(_, entry)
            local hash = characterHash(entry)
            local head = hash and hash.Head
            if head and head.Parent then
                ignore[#ignore + 1] = head.Parent
            end
        end)
    end
    params.FilterDescendantsInstances = ignore
    local hit = workspace:Raycast(origin, dir * (dist - 0.75), params)
    if not hit then
        return points
    end
    local normal = hit.Normal
    if normal.Magnitude < 1e-4 then
        return points
    end
    normal = normal.Unit
    local right = dir:Cross(Vector3.yAxis)
    if right.Magnitude < 1e-3 then
        right = dir:Cross(Vector3.xAxis)
    end
    right = right.Unit
    local up = right:Cross(dir)
    if up.Magnitude < 1e-3 then
        up = Vector3.yAxis
    else
        up = up.Unit
    end
    local axes = {
        right, -right, up, -up,
        (right + up).Unit, (right - up).Unit,
        (-right + up).Unit, (-right - up).Unit,
    }
    local function cap(point)
        local offset = point - origin
        if offset.Magnitude > reach then
            return origin + offset.Unit * reach
        end
        return point
    end
    local function push(point)
        if not isFiniteVec3(point) or #points >= 10 then
            return
        end
        point = cap(point)
        for _, existing in ipairs(points) do
            if (existing - point).Magnitude < 0.2 then
                return
            end
        end
        points[#points + 1] = point
    end
    for _, axis in ipairs(axes) do
        if #points >= 10 then
            break
        end
        local best
        local lo, hi = 0.2, reach
        for _ = 1, 4 do
            local mid = (lo + hi) * 0.5
            local candidate = cap(origin + axis * mid + normal * 0.35)
            local toTarget = target - candidate
            local blocked = toTarget.Magnitude > 0.5 and workspace:Raycast(candidate, toTarget, params)
            local clear = not blocked or (blocked.Position - target).Magnitude < 3
            if clear then
                best = candidate
                hi = mid
            else
                lo = mid
            end
        end
        if best then
            push(best)
        end
    end
    return points
end

local function headEdgePoints(entry, origin, target)
    local hash = entry and characterHash(entry)
    local head = hash and hash.Head
    local points = {}
    if not (head and head.Parent and isFiniteVec3(target)) then
        return points
    end
    local reach = number(Config.HitPositionOffset, 10, 0, 12)
    local scale = number(Config.HitboxPointScale, 0.35, 0.05, 0.45)
    local extent = head.Size * scale
    local toUs = origin - target
    if toUs.Magnitude < 1e-3 then
        return points
    end
    toUs = toUs.Unit
    local right = toUs:Cross(Vector3.yAxis)
    if right.Magnitude < 1e-3 then
        right = Vector3.xAxis
    else
        right = right.Unit
    end

    local bias = {
        toUs,
        (toUs + right).Unit,
        (toUs - right).Unit,
        (toUs + Vector3.yAxis).Unit,
        (toUs * 0.6 + right).Unit,
    }
    for _, dir in ipairs(bias) do
        local localDir = head.CFrame:VectorToObjectSpace(dir)
        local corner = Vector3.new(
            math.clamp(localDir.X, -1, 1) * math.min(extent.X, reach),
            math.clamp(localDir.Y, -1, 1) * math.min(extent.Y, reach),
            math.clamp(localDir.Z, -1, 1) * math.min(extent.Z, reach)
        )
        local point = head.CFrame:PointToWorldSpace(corner)
        if isFiniteVec3(point) then
            points[#points + 1] = point
        end
    end
    return points
end

local function scanPositions(origin, target, acceleration, speed, penetration, entry)
    if not isFiniteVec3(origin) or not isFiniteVec3(target) or not isFiniteVec3(acceleration)
        or type(speed) ~= "number" or speed ~= speed or speed <= 0
    then
        return
    end
    local bulletCheck = Modules and Modules.BulletCheck
    if type(bulletCheck) ~= "function" then
        return
    end
    local movement = targetVelocity(entry)
    local checks = 0
    local limit = number(Config.MaxBulletChecks, 10, 1, 128)
    local function canProbe()
        return checks < limit and frameCheckBudget > 0 and os.clock() < frameCheckDeadline
    end
    local function probe(newOrigin, newTarget)
        checks = checks + 1
        frameCheckBudget = frameCheckBudget - 1
        Runtime.Checks = Runtime.Checks + 1
        local _, hit, velocity, flightTime, predicted =
            tryBulletPath(bulletCheck, newOrigin, newTarget, acceleration, speed, penetration, movement)
        if hit then
            return newOrigin, predicted, velocity, flightTime
        end
    end
    if not canProbe() then
        return
    end
    local o, t, v, flightTime = probe(origin, target)
    if o then
        return o, t, v, flightTime
    end
    local origins, targets = { origin }, { target }
    local function append(list, points)
        for _, point in ipairs(points) do
            local unique = true
            for _, existing in ipairs(list) do
                if (point - existing).Magnitude < 0.001 then
                    unique = false
                    break
                end
            end
            if unique then
                list[#list + 1] = point
            end
        end
    end
    local edgeMode = Config.Mode == "edge"
    if edgeMode and Config.FirePositionScanning then
        local slot = entry and ScanStates[entry]
        local reach = number(Config.FirePositionOffset, 10, 0, 12)
        local peeked
        if slot and slot.edgePoints and slot.edgeReach == reach and os.clock() - (slot.edgeAt or 0) < 0.12 then
            peeked = slot.edgePoints
        else
            peeked = edgePeekPoints(origin, target, reach)
            if entry then
                slot = slot or { cursor = 1 }
                slot.edgePoints = peeked
                slot.edgeAt = os.clock()
                slot.edgeReach = reach
                ScanStates[entry] = slot
            end
        end
        append(origins, peeked)
    end
    if Config.FirePositionScanning and not edgeMode then
        append(origins, getPositionOffsets(origin, target, Config.FirePositionOffset, "V1"))
    elseif Config.FirePositionScanning and edgeMode then

        append(origins, getPositionOffsets(origin, target, math.min(Config.FirePositionOffset, 6), "V1"))
    end
    if edgeMode and Config.HitPositionScanning then
        append(targets, headEdgePoints(entry, origin, target))
    end
    if Config.HitPositionScanning and not edgeMode then
        append(targets, headScanPoints(entry, target, origin))
    end
    local paths = {}
    for index = 2, #origins do
        paths[#paths + 1] = { origins[index], target }
    end
    for index = 2, #targets do
        paths[#paths + 1] = { origin, targets[index] }
    end
    for first = 2, #origins do
        for second = 2, #targets do
            paths[#paths + 1] = { origins[first], targets[second] }
        end
    end
    if #paths == 0 then
        return
    end
    local saved = entry and ScanStates[entry] or nil
    local key = tostring(Config.Mode)
        .. ":"
        .. tostring(Config.FirePositionScanning)
        .. ":"
        .. tostring(Config.FirePositionOffset)
        .. ":"
        .. tostring(Config.HitPositionScanning)
        .. ":"
        .. tostring(Config.HitPositionOffset)
        .. ":"
        .. tostring(Config.HitPositionScanMode)
    if not saved or saved.key ~= key then
        local carried = saved
        saved = { cursor = 1, key = key }
        if carried then
            saved.edgePoints = carried.edgePoints
            saved.edgeAt = carried.edgeAt
            saved.edgeReach = carried.edgeReach
        end
        if entry then
            ScanStates[entry] = saved
        end
    end
    local cursor = saved.cursor
    for visited = 0, #paths - 1 do
        if not canProbe() then
            break
        end
        local index = 1 + (cursor - 1 + visited) % #paths
        saved.cursor = 1 + index % #paths
        local path = paths[index]
        o, t, v, flightTime = probe(path[1], path[2])
        if o then
            return o, t, v, flightTime
        end
    end
end

local function targetDistance(entry, origin)
    local aim = entry and entryAimPos(entry)
    if not (isFiniteVec3(aim) and isFiniteVec3(origin)) then
        return nil
    end
    return math.floor((aim - origin).Magnitude + 0.5)
end

local function fireDelayForWeapon(data, weapon)
    local rpm = tonumber(data and data.firerate) or 600
    if type(data and data.firerate) == "table" then
        local index = weapon and weapon._firemodeIndex or 1
        rpm = tonumber(data.firerate[index]) or tonumber(data.firerate[1]) or rpm
    end
    if weapon and weapon._aiming and data and data.aimedfirerate then
        rpm = tonumber(data.aimedfirerate) or rpm
    end
    rpm = math.clamp(rpm, 60, 3000)
    return 60 / rpm
end

local PendingHits = {}
local ticket = 0
local nextShot = 0
local lastOrigin
local realOrigin
local originUpdatedAt = -math.huge

local function fallbackOrigin()
    if os.clock() - originUpdatedAt <= 0.25 and isFiniteVec3(lastOrigin) then
        return lastOrigin
    end
    if os.clock() - originUpdatedAt <= 0.25 and isFiniteVec3(realOrigin) then
        return realOrigin
    end
    local charInterface = Modules and Modules.CharacterInterface
    local object = charInterface and charInterface.getCharacterObject and charInterface.getCharacterObject()
    local root = object and object.getRootPart and object:getRootPart()
    if root and isFiniteVec3(root.Position) then
        return root.Position
    end
    local cam = workspace.CurrentCamera
    return cam and cam.CFrame.Position or nil
end

local function gameTime()
    local clock = Modules and Modules.GameClock
    if clock and type(clock.getTime) == "function" then
        local ok, t = pcall(clock.getTime)
        if ok and type(t) == "number" then
            return t
        end
    end
    local network = Modules and Modules.NetworkClient
    if network and type(network.getTime) == "function" then
        local ok, t = pcall(network.getTime)
        if ok and type(t) == "number" then
            return t
        end
    end
    return nil
end

local function nextBulletTicket(weapon)
    ticket += 1
    if weapon and debug and debug.getupvalue and debug.setupvalue and type(weapon.fireRound) == "function" then
        local ok, current = pcall(debug.getupvalue, weapon.fireRound, 11)
        if ok and type(current) == "number" then
            ticket = math.max(ticket, current + 1)
            pcall(debug.setupvalue, weapon.fireRound, 11, ticket)
        end
    end
    return ticket
end

local halfPi = math.pi * 0.5
local function wrapYaw(y)
    local pi = math.pi
    local tau = pi * 2
    y = y % tau
    if y < 0 then
        y += tau
    end
    return y - pi
end

local function aaWave(kind, amount, ways)
    local speed = number(Config.AASpeed, 6, 0.5, 20)
    local t = os.clock() * speed
    if kind == "sine" then
        return amount * math.sin(t)
    elseif kind == "jitter" then
        return (math.floor(t * 2) % 2 == 0 and 1 or -1) * amount
    elseif kind == "ways" then
        local count = math.clamp(math.floor(tonumber(ways) or 7), 2, 10)
        local step = math.floor(t) % count
        if count <= 1 then
            return 0
        end
        return -amount + (2 * amount) * (step / (count - 1))
    elseif kind == "180" then
        return (math.floor(t) % 2 == 0 and 1 or -1) * amount
    end
    return amount
end

local function applyAAAngles(angles)
    if typeof(angles) ~= "Vector3" or not isFiniteVec3(angles) then
        return angles
    end
    if not Config.AntiAim then
        return angles
    end
    local pitchKind = Config.PitchType or "static"
    local yawKind = Config.YawType or "static"
    local pitch = pitchKind == "static" and math.rad(number(Config.PitchAmount, 0, -89, 89))
        or aaWave(pitchKind, math.rad(number(Config.PitchAmount, 0, -89, 89)), Config.PitchWays)
    local yaw = yawKind == "static" and math.rad(number(Config.YawAmount, 180, -180, 180))
        or aaWave(yawKind, math.rad(number(Config.YawAmount, 180, -180, 180)), Config.YawWays)
    local x = math.clamp(angles.X + pitch, -halfPi, halfPi)
    local y = wrapYaw(angles.Y + yaw)
    return Vector3.new(x, y, 0)
end

local function applyFakePosition(position)
    if not Config.FakePosition or not isFiniteVec3(position) then
        return position
    end
    local cam = workspace.CurrentCamera
    local look = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude < 0.05 then
        flat = Vector3.new(0, 0, -1)
    else
        flat = flat.Unit
    end
    local dist = number(Config.FakePositionDistance, 4, 0, 14)
    local height = number(Config.FakePositionHeight, 0, -6, 6)
    local shifted = position + flat * dist + Vector3.new(0, height, 0)
    return isFiniteVec3(shifted) and shifted or position
end

local FAKE_LAG_HARD_CAP = 2.8
local fakeLag = {
    lastRefreshTime = 0,
    lastSentPosition = nil,
    heldUntil = 0,
}

local function applyFakeLag(position)
    if not isFiniteVec3(position) then
        return position
    end
    local now = os.clock()
    local amount = number(Config.FakeLagAmount, 1.2, 0, FAKE_LAG_HARD_CAP)
    local hold = number(Config.FakeLagHold, 0.35, 0.05, 3)
    local smooth = number(Config.FakeLagSmooth, 0.45, 0, 1)

    if not fakeLag.lastSentPosition then
        fakeLag.lastSentPosition = position
        fakeLag.lastRefreshTime = now
        fakeLag.heldUntil = now + hold
        return position
    end

    if now < fakeLag.heldUntil then
        local held = fakeLag.lastSentPosition
        local delta = held - position
        if delta.Magnitude > amount then
            held = position + delta.Unit * amount
        end
        fakeLag.lastSentPosition = held
        return held
    end

    local yaw = math.random() * math.pi * 2
    local candidate = position + Vector3.new(math.cos(yaw) * amount, 0, math.sin(yaw) * amount)
    if smooth < 1 then
        candidate = fakeLag.lastSentPosition:Lerp(candidate, smooth)
    end
    local fromReal = candidate - position
    if fromReal.Magnitude > amount then
        candidate = position + fromReal.Unit * amount
    end
    local fromLast = candidate - fakeLag.lastSentPosition
    local jumpCap = math.min(amount, FAKE_LAG_HARD_CAP)
    if fromLast.Magnitude > jumpCap and fromLast.Magnitude > 1e-4 then
        candidate = fakeLag.lastSentPosition + fromLast.Unit * jumpCap
    end
    fakeLag.lastSentPosition = candidate
    fakeLag.lastRefreshTime = now
    fakeLag.heldUntil = now + hold
    return candidate
end

local resolverState = {
    phase = "cooldown",
    cycleStart = 0,
    flashUntil = 0,
    holdUntil = 0,
    entry = nil,
    offset = Vector3.zero,
    worldPoint = nil,
    name = nil,
    bases = setmetatable({}, { __mode = "k" }),
}

local function captureBases(entry)
    local hash = characterHash(entry)
    if not hash then
        return
    end
    local bases = resolverState.bases[entry]
    if not bases then
        bases = {}
        resolverState.bases[entry] = bases
    end
    for name, part in pairs(hash) do
        if typeof(part) == "Instance" and part:IsA("BasePart") then
            bases[name] = part.CFrame
        end
    end
end

local function clearRelocate(entry)
    if not entry then
        return
    end
    local bases = resolverState.bases[entry]
    local hash = characterHash(entry)
    if bases and hash then
        for name, cf in pairs(bases) do
            local part = hash[name]
            if typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent and typeof(cf) == "CFrame" then
                pcall(function()
                    part.CFrame = cf
                end)
            end
        end
    end
    resolverState.bases[entry] = nil
end

local function applyRelocate(entry, worldPoint)
    if not (entry and isFiniteVec3(worldPoint)) then
        return false
    end
    local hash = characterHash(entry)
    local head = hash and hash.Head
    if not (head and head.Parent and isFiniteVec3(head.Position)) then
        return false
    end
    local delta = worldPoint - head.Position
    if delta.Magnitude < 1e-4 then
        return true
    end
    for _, part in pairs(hash) do
        if typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent then
            pcall(function()
                part.CFrame = part.CFrame + delta
            end)
        end
    end
    return true
end

local function findOrbitResolvePoint(origin, entry, accel, speed, penetration)
    local aim = entryAimPos(entry) or entry._receivedPosition
    if not isFiniteVec3(aim) then
        return nil
    end
    local vel = targetVelocity(entry)
    local predicted = aim + vel * 0.12
    local height = number(Config.ResolverHeight, 0.35, -2, 3)
    predicted = predicted + Vector3.new(0, height, 0)
    local strength = number(Config.ResolverStrength, 4, 0.5, 10)
    local bulletCheck = Modules and Modules.BulletCheck
    local movement = vel
    local candidates = {}

    for _, point in ipairs(edgePeekPoints(origin, predicted, math.min(strength, 10))) do
        candidates[#candidates + 1] = point
    end
    candidates[#candidates + 1] = predicted
    for i = 0, 7 do
        local a = (i / 8) * math.pi * 2
        candidates[#candidates + 1] = predicted
            + Vector3.new(math.cos(a) * strength, 0, math.sin(a) * strength)
    end
    for i = 0, 7 do
        local a = (i / 8) * math.pi * 2 + 0.4
        candidates[#candidates + 1] = predicted
            + Vector3.new(math.cos(a) * strength * 0.55, height * 0.5, math.sin(a) * strength * 0.55)
    end
    if type(bulletCheck) == "function" and isFiniteVec3(origin) and accel and speed and penetration then
        for _, point in ipairs(candidates) do
            local _, hit = tryBulletPath(bulletCheck, origin, point, accel, speed, penetration, movement)
            if hit then
                return point
            end
        end
    end
    return candidates[2] or predicted
end

local function resolverCooldownLeft()
    if resolverState.phase == "resolved" then
        return 0
    end
    local cool = number(Config.ResolverCooldown, 1, 0.1, 5)
    local elapsed = os.clock() - (resolverState.cycleStart or 0)
    return math.max(0, cool - elapsed)
end

local function resolverTick(origin, accel, speed, penetration)
    if not Config.Resolver then
        if resolverState.entry then
            clearRelocate(resolverState.entry)
            resolverState.entry = nil
        end
        resolverState.phase = "cooldown"
        return
    end
    local now = os.clock()
    local flash = number(Config.ResolverFlash, 0.35, 0.1, 1.5)
    local hold = number(Config.ResolverHold, 0.45, 0.1, 3)

    if resolverState.cycleStart <= 0 then
        resolverState.cycleStart = now
        resolverState.phase = "cooldown"
    end

    if resolverState.entry then
        if now <= resolverState.holdUntil then
            local received = resolverState.entry._receivedPosition
            if isFiniteVec3(received) and isFiniteVec3(resolverState.offset) then
                resolverState.worldPoint = received + resolverState.offset
            end
            if isFiniteVec3(resolverState.worldPoint) then
                applyRelocate(resolverState.entry, resolverState.worldPoint)
            end
        else
            clearRelocate(resolverState.entry)
            resolverState.entry = nil
            resolverState.worldPoint = nil
        end
    end

    if resolverState.phase == "resolved" then
        if now >= resolverState.flashUntil then
            resolverState.phase = "cooldown"
            resolverState.cycleStart = now
        end
        return
    end

    if resolverCooldownLeft() > 0.001 then
        return
    end

    local closest = isFiniteVec3(origin) and getClosestPlayers(origin) or {}
    local entry = closest and closest[1]
    local point = entry and findOrbitResolvePoint(origin, entry, accel, speed, penetration)
    if entry and isFiniteVec3(point) then
        captureBases(entry)
        local received = entry._receivedPosition
        resolverState.offset = isFiniteVec3(received) and (point - received) or Vector3.zero
        resolverState.worldPoint = point
        applyRelocate(entry, point)
        resolverState.entry = entry
        resolverState.name = entry._player and entry._player.Name or "target"
    else
        resolverState.entry = nil
        resolverState.worldPoint = nil
        resolverState.name = nil
    end
    resolverState.phase = "resolved"
    resolverState.flashUntil = now + flash
    resolverState.holdUntil = now + hold
end

local function startModules()
    local network = Modules.NetworkClient
    local settings = Modules.PublicSettings
    local weapons = Modules.WeaponControllerInterface
    local effects = Modules.Effects
    local audio = Modules.AudioSystem
    local crosshairs = Modules.HudCrosshairsInterface
    local roundSystem = Modules.RoundSystemClientFactory
        and Modules.RoundSystemClientFactory.getClientRoundSystem
        and Modules.RoundSystemClientFactory.getClientRoundSystem()
    local cameraInterface = Modules.CameraInterface

    if network and type(network.send) == "function" then
        local send = network.send
        local wrapper = function(self, name, ...)
            if name == "repupdate" then
                local position, angles = ...
                if isFiniteVec3(position) then
                    originUpdatedAt = os.clock()
                    realOrigin = position
                    lastOrigin = position
                end

                if Config.AntiAim or Config.FakeLag or Config.FakePosition then
                    if Config.FakePosition and isFiniteVec3(position) then
                        position = applyFakePosition(position)
                    end
                    if Config.FakeLag and isFiniteVec3(position) then
                        position = applyFakeLag(position)
                    else
                        fakeLag.lastSentPosition = nil
                        fakeLag.heldUntil = 0
                    end
                    if Config.AntiAim then
                        angles = applyAAAngles(typeof(angles) == "Vector3" and angles or Vector3.zero)
                    end
                    return send(self, name, position, angles, select(3, ...))
                end
            end
            return send(self, name, ...)
        end
        network.send = wrapper
        table.insert(Restores, function()
            if network.send == wrapper then
                network.send = send
            end
        end)

        table.insert(Connections, RunService.Heartbeat:Connect(function()
            if Unloaded or not Config.Enabled or Config.Prediction == false then
                return
            end
            local ok, reason = pcall(sampleMotion)
            if not ok then
                Runtime.LastError = tostring(reason)
            end
        end))

        table.insert(Connections, RunService.Heartbeat:Connect(function()
            if Unloaded then
                return
            end
            local origin = fallbackOrigin()
            local accel = settings and settings.bulletAcceleration
            local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
            local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
            local data = weapon and weapon._weaponData
            local speed = data and data.bulletspeed
            local penetration = data and data.penetrationdepth
            local ok, reason = pcall(resolverTick, origin, accel, speed, penetration)
            if not ok then
                Runtime.LastError = tostring(reason)
            end
        end))

        local function update()
            if Unloaded or not Config.Enabled then
                return
            end
            if roundSystem and roundSystem.roundLock then
                return
            end
            local now = os.clock()
            if now < nextShot then
                return
            end

            Config.WhitelistFriendlyStatus = true

            local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
            local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
            local data = weapon and weapon._weaponData
            local origin
            local barrel = weapon and weapon._barrelPart
            if barrel and barrel.Parent and isFiniteVec3(barrel.Position) then
                origin = barrel.Position
            end
            origin = origin or fallbackOrigin()
            if not (weapon and data and origin and settings and settings.bulletAcceleration) then
                return
            end
            if not weapon.uniqueId or not data.bulletspeed or not data.penetrationdepth then
                return
            end
            if (weapon._magCount or 0) < 1 and (weapon._spareCount or 0) < 1 then
                return
            end

            local camPos = origin
            pcall(function()
                local active = cameraInterface and cameraInterface.getActiveCamera and cameraInterface.getActiveCamera()
                if active and active.getBaseCFrame then
                    local p = active:getBaseCFrame().Position
                    if isFiniteVec3(p) then
                        camPos = p
                    end
                end
            end)

            local accel = settings.bulletAcceleration
            local speed = data.bulletspeed
            local penetration = data.penetrationdepth
            local closest = getClosestPlayers(origin)
            local fired = false
            frameCheckBudget = number(Config.MaxFrameChecks, 128, 1, 256)
            frameCheckDeadline = os.clock() + number(Config.ScanBudgetMs, 5, 1, 8) / 1000

            for _, entry in closest do
                if not (entry and entry._player and entry._player.Parent) then
                    continue
                end
                local aim = entryAimPos(entry)
                if isFiniteVec3(aim) then
                    getgenv().TapologyAimPoint = aim
                end
                if not isFiniteVec3(aim) or (aim - origin).Magnitude > number(Config.MaxDistance, 1500, 1, 10000) then
                    continue
                end

                local newOrigin, newTarget, velocity, flightTime = scanPositions(origin, aim, accel, speed, penetration, entry)
                if not (newOrigin and newTarget and velocity and velocity.Magnitude > 1e-3) then
                    continue
                end

                if (weapon._magCount or 0) < 1 then
                    local spare = weapon._spareCount or 0
                    if spare < 1 then
                        return
                    end
                    local magSize = math.max(1, math.floor(tonumber(data.magsize) or spare))
                    local load = math.min(magSize, spare)
                    weapon._magCount = load
                    weapon._spareCount = spare - load
                    pcall(send, network, "reload")
                end
                local direction = velocity
                local bullets = {}
                local bulletData = {
                    camerapos = camPos,
                    firepos = newOrigin,
                    bullets = bullets,
                }
                local pelletCount = math.clamp(math.floor(tonumber(data.pelletcount) or 1), 1, 128)
                local netTime = gameTime()
                if type(netTime) ~= "number" or type(flightTime) ~= "number" then
                    Runtime.LastError = "Synchronized shot time unavailable"
                    break
                end
                for _ = 1, pelletCount do
                    table.insert(bullets, { direction, nextBulletTicket(weapon) })
                end

                local sent = pcall(send, network, "newbullets", weapon.uniqueId, bulletData, netTime)
                if not sent then
                    break
                end
                fired = true
                Runtime.Shots = Runtime.Shots + 1
                Runtime.ClearName = entry._player.Name
                Runtime.ClearUntil = os.clock() + 0.35
                Runtime.ClearDist = math.floor((aim - origin).Magnitude + 0.5)

                local shotPlayer, shotWeapon, shotHead = entry._player, weapon.uniqueId, characterHash(entry).Head
                local pending
                pending = task.delay(flightTime, function()
                    PendingHits[pending] = nil
                    if Unloaded or not shotPlayer.Parent then
                        return
                    end
                    local hash = characterHash(entry)
                    if not hash or hash.Head ~= shotHead or entryHealth(entry) <= 0 then
                        return
                    end
                    local hitTime = gameTime() or netTime + flightTime
                    for _, bullet in ipairs(bullets) do
                        local reported, reason =
                            pcall(send, network, "bullethit", shotWeapon, shotPlayer, newTarget, "Head", bullet[2], hitTime)
                        if not reported then
                            Runtime.LastError = tostring(reason)
                        end
                    end
                end)
                PendingHits[pending] = true

                if Config.ShootEffects and weapon._barrelPart then
                    local barrelPart = weapon._barrelPart
                    if effects and effects.muzzleflash then
                        pcall(effects.muzzleflash, barrelPart, data.hideflash, 0.9)
                    end
                    if audio and audio.playSoundId and data.firesoundid then
                        pcall(audio.playSoundId, data.firesoundid, 2, data.firevolume, data.firepitch, barrelPart, nil, 0, 0.05)
                    end
                    if crosshairs and crosshairs.fireImpulse and data.crossexpansion and not weapon._aiming then
                        pcall(crosshairs.fireImpulse, data.crossexpansion)
                    end
                end

                nextShot = now + fireDelayForWeapon(data, weapon)
                weapon._magCount = math.max((weapon._magCount or 1) - 1, 0)
                if (weapon._magCount or 0) < 1 and (weapon._spareCount or 0) >= 1 then
                    local spare = weapon._spareCount or 0
                    local magSize = math.max(1, math.floor(tonumber(data.magsize) or spare))
                    local load = math.min(magSize, spare)
                    weapon._magCount = load
                    weapon._spareCount = spare - load
                    pcall(send, network, "reload")
                end
                break
            end

            if not fired then
                Runtime.ScanMisses = Runtime.ScanMisses + 1
                nextShot = now + number(Config.ScanMissCooldown, 0.12, 0.01, 1)
            end
        end
        table.insert(Connections, RunService.Heartbeat:Connect(function()
            local ok, reason = pcall(update)
            if not ok then
                Runtime.LastError = tostring(reason)
                Runtime.Status = "Update error"
                nextShot = os.clock() + 0.25
            end
        end))
    end
end

local indicatorGui
local indicatorRageRow
local indicatorResolverRow
local INDICATOR_TEXT_SIZE = 12

local function accentColor()
    local ui = env.Tapology or env.Library
    local theme = ui and ui.Config and ui.Config.Theme
    if theme and typeof(theme.Accent) == "Color3" then
        return theme.Accent
    end
    return Color3.fromRGB(108, 147, 255)
end

local function indicatorFont()
    local ui = env.Tapology or env.Library
    if ui and ui.Font then
        return ui.Font
    end
    local esp = env.ESP
    if esp and esp.Font then
        return esp.Font
    end
    return Font.fromEnum(Enum.Font.Code)
end

local function ensureIndicators()
    if indicatorGui and indicatorGui.Parent then
        return
    end
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 2)
    if not playerGui then
        return
    end
    indicatorGui = Instance.new("ScreenGui")
    indicatorGui.Name = "TapologyRageIndicators"
    indicatorGui.IgnoreGuiInset = true
    indicatorGui.ResetOnSpawn = false
    indicatorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    indicatorGui.Parent = playerGui

    local font = indicatorFont()
    local function makeRow(name)
        local row = Instance.new("Frame")
        row.Name = name
        row.BackgroundTransparency = 1
        row.AnchorPoint = Vector2.new(0.5, 0)
        row.AutomaticSize = Enum.AutomaticSize.X
        row.Size = UDim2.fromOffset(0, INDICATOR_TEXT_SIZE)
        row.Visible = false
        row.Parent = indicatorGui
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 0)
        layout.Parent = row
        local function makeText(labelName, order)
            local label = Instance.new("TextLabel")
            label.Name = labelName
            label.BackgroundTransparency = 1
            label.AutomaticSize = Enum.AutomaticSize.X
            label.Size = UDim2.fromOffset(0, INDICATOR_TEXT_SIZE)
            label.FontFace = font
            label.TextSize = INDICATOR_TEXT_SIZE
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextYAlignment = Enum.TextYAlignment.Center
            label.LayoutOrder = order
            label.ZIndex = 5
            label.Parent = row
            local stroke = Instance.new("UIStroke")
            stroke.Name = "Outline"
            stroke.Thickness = 1
            stroke.Color = Color3.new(0, 0, 0)
            stroke.LineJoinMode = Enum.LineJoinMode.Miter
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
            stroke.Parent = label
            return label
        end
        return { Row = row, Prefix = makeText("Prefix", 1), Info = makeText("Info", 2) }
    end
    indicatorRageRow = makeRow("Ragebot")
    indicatorResolverRow = makeRow("Resolver")
end

local function destroyIndicators()
    if indicatorGui then
        pcall(function()
            indicatorGui:Destroy()
        end)
    end
    indicatorGui, indicatorRageRow, indicatorResolverRow = nil, nil, nil
end

local function paintRow(row, y, prefix, info, infoColor)
    if not row then
        return
    end
    local font = indicatorFont()
    row.Row.Visible = true
    row.Row.Size = UDim2.fromOffset(0, INDICATOR_TEXT_SIZE)
    row.Row.Position = UDim2.new(0.5, 0, 0.5, y)
    for _, label in { row.Prefix, row.Info } do
        label.FontFace = font
        label.TextSize = INDICATOR_TEXT_SIZE
        label.Size = UDim2.fromOffset(0, INDICATOR_TEXT_SIZE)
        local stroke = label:FindFirstChild("Outline")
        if stroke and stroke:IsA("UIStroke") then
            stroke.Thickness = 1
            stroke.Color = Color3.new(0, 0, 0)
            stroke.Transparency = 0
            stroke.LineJoinMode = Enum.LineJoinMode.Miter
        end
    end
    row.Prefix.Text = prefix
    row.Prefix.TextColor3 = accentColor()
    row.Info.Text = info
    row.Info.TextColor3 = infoColor or Color3.new(1, 1, 1)
end

local function animatedDots()
    local phase = math.floor(os.clock() * 3) % 4
    if phase <= 0 then
        return ""
    end
    return string.rep(".", phase)
end

local scanPart, scanAdorn
table.insert(Connections, RunService.RenderStepped:Connect(function()
    if Config.ShowScanRange then
        local origin = fallbackOrigin()
        if isFiniteVec3(origin) then
            if not scanPart then
                scanPart = Instance.new("Part")
                scanPart.Name = "TapologyScan"
                scanPart.Anchored = true
                scanPart.CanCollide = false
                scanPart.CanQuery = false
                scanPart.CanTouch = false
                scanPart.Transparency = 1
                scanPart.Size = Vector3.new(0.2, 0.2, 0.2)
                scanPart.Parent = workspace
                scanAdorn = Instance.new("SphereHandleAdornment")
                scanAdorn.Adornee = scanPart
                scanAdorn.AlwaysOnTop = true
                scanAdorn.ZIndex = 1
                scanAdorn.Transparency = 0.86
                scanAdorn.Color3 = Color3.fromRGB(108, 147, 255)
                scanAdorn.Parent = scanPart
            end
            scanPart.CFrame = CFrame.new(origin)
            scanAdorn.Radius = number(Config.ScanRangeVisual, 80, 5, 400)
            scanAdorn.Visible = true
        end
    elseif scanAdorn then
        scanAdorn.Visible = false
    end
    if not Config.Indicators then
        if indicatorGui then
            destroyIndicators()
        end
        return
    end
    ensureIndicators()
    if not indicatorRageRow or not indicatorResolverRow then
        return
    end
    local line = INDICATOR_TEXT_SIZE + 4
    local y = 20
    local dots = animatedDots()
    if Config.IndicatorRagebot then
        local info, color = " off" .. dots, Config.IndicatorRageIdle
        if Config.Enabled then
            local origin = fallbackOrigin()
            local closest = isFiniteVec3(origin) and getClosestPlayers(origin) or {}
            local entry = closest[1]
            if entry and entry._player then
                local dist = targetDistance(entry, origin)
                local mode = Config.Mode == "edge" and "edge" or "default"
                local fresh = Runtime.ClearName == entry._player.Name and os.clock() < (Runtime.ClearUntil or 0)
                if fresh then
                    info = string.format(" %s clear %sm%s", entry._player.Name, tostring(Runtime.ClearDist or dist or 0), dots)
                elseif dist then
                    info = string.format(" %s %s %sm%s", entry._player.Name, mode, tostring(dist), dots)
                else
                    info = string.format(" %s %s%s", entry._player.Name, mode, dots)
                end
                color = Config.IndicatorRageActive
            else
                info = " scanning" .. dots
            end
        end
        paintRow(indicatorRageRow, y, "ragebot :", info, color)
        y += line
    else
        indicatorRageRow.Row.Visible = false
    end
    if Config.IndicatorResolver then
        local info, color
        if not Config.Resolver then
            info = " off"
            color = Config.IndicatorResolverCooldown
        elseif resolverState.phase == "resolved" then
            info = " resolved!"
            color = Config.IndicatorResolverReady
        else
            info = string.format(" %.1f", resolverCooldownLeft())
            color = Config.IndicatorResolverCooldown
        end
        paintRow(indicatorResolverRow, y, "resolver :", info, color)
    else
        indicatorResolverRow.Row.Visible = false
    end
end))

Controller = {
    Config = Config,
    Available = false,
    Runtime = Runtime,
    SetEnabled = function(on)
        Config.Enabled = on and true or false
    end,
    GetAntiAimAngles = function(angles)
        return applyAAAngles(angles)
    end,
    GetResolverState = function()
        if not Config.Resolver then
            return "off"
        end
        if resolverState.phase == "resolved" then
            return "resolved"
        end
        if resolverCooldownLeft() > 0.01 then
            return "cooldown"
        end
        return "ready"
    end,
    GetResolverCooldown = resolverCooldownLeft,
    SetTarget = function(player, on)
        Config.Targets[player] = on and true or nil
    end,
    SetFriendly = function(player, on)
        Config.Friendlies[player] = on and true or nil
    end,
    Unload = function()
        if Unloaded then
            return
        end
        Unloaded = true
        Controller.Available = false
        Runtime.Status = "Unloaded"
        Config.Enabled = false
        if resolverState.entry then
            clearRelocate(resolverState.entry)
        end
        for pending in pairs(PendingHits) do
            pcall(task.cancel, pending)
        end
        table.clear(PendingHits)
        for _, connection in Connections do
            pcall(function()
                connection:Disconnect()
            end)
        end
        table.clear(Connections)
        for _, restore in Restores do
            pcall(restore)
        end
        table.clear(Restores)
        destroyIndicators()
        if env.Rage == Controller then
            env.Rage = nil
        end
        if env.RageBot == Controller then
            env.RageBot = nil
        end
    end,
}

env.RageBot, env.Rage = Controller, Controller

if not PhantomForces then
    Runtime.Status = "Unsupported place"
    Config.Enabled = false
else
    task.spawn(function()
        Runtime.Status = "Finding modules"
        local deadline = os.clock() + number(Config.ModuleTimeout, 15, 1, 120)
        repeat
            if Unloaded then
                return
            end
            local ok, found = pcall(findModules)
            if ok and found then
                Modules = found
                env._TapologyModules = env._TapologyModules or found
                local connectionCount, restoreCount = #Connections, #Restores
                local started, reason = pcall(startModules)
                if Unloaded then
                    for index = #Connections, connectionCount + 1, -1 do
                        pcall(function()
                            Connections[index]:Disconnect()
                        end)
                        Connections[index] = nil
                    end
                    for index = #Restores, restoreCount + 1, -1 do
                        pcall(Restores[index])
                        Restores[index] = nil
                    end
                    return
                end
                if started then
                    Controller.Available = true
                    Runtime.Status = "Ready"
                    Runtime.LastError = nil
                    return
                end
                Runtime.LastError = tostring(reason)
                for index = #Connections, connectionCount + 1, -1 do
                    pcall(function()
                        Connections[index]:Disconnect()
                    end)
                    Connections[index] = nil
                end
                for index = #Restores, restoreCount + 1, -1 do
                    pcall(Restores[index])
                    Restores[index] = nil
                end
            elseif not ok then
                Runtime.LastError = tostring(found)
            end
            task.wait(1)
        until Unloaded or os.clock() >= deadline
        if not Unloaded then
            Runtime.Status = "Modules unavailable"
        end
    end)
end
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
    WalkSpeed = false,
    SetSpeed = 50,
    JumpPower = false,
    HeightAddition = 10,
    NoFallDamage = false,
    BunnyHop = false,
    OnlyWhileJumping = true,
    SlideBoost = false,
    SlideBoostSpeed = 70,
    NoStamina = false,
    NoMoveCooldown = false,
    HeightBypass = false,
    HeightBypassTime = 1.5,
    CircleJump = false,
    ZigzagJump = false,
    Pathfind = false,
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
    CrosshairColor1 = Color3.fromRGB(255, 255, 255),
    CrosshairColor2 = Color3.fromRGB(255, 255, 255),
    CrosshairColor3 = Color3.fromRGB(255, 255, 255),
    CrosshairColor4 = Color3.fromRGB(255, 255, 255),
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
    ShowCharacter = false,
    ShowCharacterWhileAiming = false,
    HideViewmodel = true,
    ApplyAntiAimToCharacter = true,
    CameraOffsetX = 0,
    CameraOffsetY = 1.5,
    CameraOffsetZ = 8,
    CameraOffsetAlwaysVisible = true,
    CameraSmooth = true,
    CameraSmoothness = 14,

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
        if Config.RemoveDecals then Config.RemoveItems.decals = true end
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
    Config.RemoveDecals = removalOn("decals")
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

local function raycastCamera(origin, direction)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = { workspace.CurrentCamera }
    if LocalPlayer.Character then
        table.insert(ignore, LocalPlayer.Character)
    end
    local playersFolder = workspace:FindFirstChild("Players")
    local ignoreFolder = workspace:FindFirstChild("Ignore")
    if playersFolder then
        table.insert(ignore, playersFolder)
    end
    if ignoreFolder then
        table.insert(ignore, ignoreFolder)
    end
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true
    return workspace:Raycast(origin, direction, params)
end

if Modules then
    local network = Modules.NetworkClient
    local charObject = Modules.CharacterObject
    local charInterface = Modules.CharacterInterface
    local weapons = Modules.WeaponControllerInterface
    local cameraObject = Modules.MainCameraObject
    local cameraInterface = Modules.CameraInterface
    local screenCull = Modules.ScreenCull
    local thirdPersonObject = Modules.ThirdPersonObject
    local replicationObject = Modules.ReplicationObject
    local playerDataIface = Modules.PlayerDataClientInterface

    local smoothOffset = Vector3.new(Config.CameraOffsetX, Config.CameraOffsetY, Config.CameraOffsetZ)
    local lastCamClock = os.clock()

    local fakeRepObject
    local currentObj
    local startedShow = false
    local lastShowPos
    local showDelta = 0
    local setCharacterRender

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
            return setBaseWalkSpeed(self, Config.WalkSpeed and Config.SetSpeed or speed)
        end
        table.insert(Restores, function()
            charObject.setBaseWalkSpeed = setBaseWalkSpeed
        end)
    end

    if charObject and type(charObject.jump) == "function" then
        local jump = charObject.jump
        charObject.jump = function(self, height, vaulting)
            local add = Config.JumpPower and Config.HeightAddition or 0
            return jump(self, (height or 4) + add, vaulting)
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

    if screenCull and type(screenCull.step) == "function" then
        local step = screenCull.step
        screenCull.step = function(...)
            step(...)
            if not Config.ThirdPerson then
                smoothOffset = Vector3.new(Config.CameraOffsetX, Config.CameraOffsetY, Config.CameraOffsetZ)
                lastCamClock = os.clock()
                return
            end
            local cam = camera()
            if not cam then
                return
            end
            local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
            local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
            local aiming = weapon and weapon._aiming
            if aiming and not Config.ShowCharacterWhileAiming and not Config.CameraOffsetAlwaysVisible then
                return
            end

            local target = Vector3.new(Config.CameraOffsetX, Config.CameraOffsetY, Config.CameraOffsetZ)
            local now = os.clock()
            local dt = math.clamp(now - lastCamClock, 0, 0.1)
            lastCamClock = now
            if Config.CameraSmooth then
                local smooth = math.clamp(tonumber(Config.CameraSmoothness) or 14, 1, 40)
                local rate = (42 - smooth) * 0.45
                local alpha = 1 - math.exp(-rate * dt)
                smoothOffset = smoothOffset:Lerp(target, alpha)
            else
                smoothOffset = target
            end
            if smoothOffset.Magnitude < 1e-4 then
                return
            end

            local didHit = false
            if Config.CameraOffsetAlwaysVisible then
                local oldPosition = cam.CFrame.Position
                local newPosition = cam.CFrame * smoothOffset
                local dir = newPosition - oldPosition
                local hit = raycastCamera(oldPosition, dir)
                if hit then
                    local frac = (hit.Position - oldPosition).Magnitude / math.max(smoothOffset.Magnitude, 1e-4)
                    cam.CFrame *= CFrame.new(smoothOffset * math.clamp(frac, 0, 1) * 0.99)
                    didHit = true
                end
            end
            if not didHit then
                cam.CFrame *= CFrame.new(smoothOffset)
            end
        end
        table.insert(Restores, function()
            screenCull.step = step
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
        local alive = charInterface and charInterface.isAlive and charInterface.isAlive()
        local hideView = Config.ThirdPerson and alive and Config.HideViewmodel ~= false
        if hideView then
            setFirstPersonHidden(true)
        else
            setFirstPersonHidden(false)
        end
    end)

    table.insert(Connections, RunService.Stepped:Connect(function(_, ndt)
        local alive = charInterface and charInterface.isAlive and charInterface.isAlive()
        local wantShow = Config.ThirdPerson and Config.ShowCharacter and alive
        local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
        local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
        local aiming = weapon and weapon._aiming

        if Config.ThirdPerson and alive and Config.HideViewmodel ~= false then
            setFirstPersonHidden(true)
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
        Config.ApplyAntiAimToCharacter = true
        do
            local rage = env.Rage
            if rage and rage.GetAntiAimAngles then
                local ok, aa = pcall(rage.GetAntiAimAngles, angles)
                if ok and typeof(aa) == "Vector3" then
                    angles = aa
                end
            end
            local rc = rage and rage.Config
            local aimPoint = getgenv().TapologyAimPoint
            if rc and rc.RageVisual and typeof(aimPoint) == "Vector3" then
                local flat = aimPoint - position
                if Vector3.new(flat.X, 0, flat.Z).Magnitude > 1 then
                    local yaw = math.atan2(-flat.X, -flat.Z)
                    local pitch = math.asin(math.clamp(flat.Unit.Y, -1, 1))
                    angles = Vector3.new(pitch, yaw, 0)
                end
            end
        end

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
                currentObj.canRenderWeapon = true
                do
                    local rage = env.Rage
                    local rc = rage and rage.Config
                    if rc and rc.AntiAim and rc.ForceStance and currentObj.setStance then
                        local stance = rc.Stance == "Stand" and "Stand" or rc.Stance == "Crouch" and "Crouch" or "Prone"
                        pcall(currentObj.setStance, currentObj, stance)
                    end
                end
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

        if bodyOn then
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

            if Config.ShowCharacter and Config.ThirdPerson then
                hideProxyBody(object)
            elseif #bodies > 0 then
                hideProxyBody(object)
            end
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
        elseif next(lastBodyModels) then
            for model in pairs(lastBodyModels) do
                restoreCachedParts(function(part)
                    return modelContains(model, part)
                end)
            end
            table.clear(lastBodyModels)
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

    local lastFireCount, lastFireWeapon = nil, nil
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
        local count = tonumber(weapon._fireCount)
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
            local shots = math.min(count - lastFireCount, 8)
            lastFireCount = count
            for _ = 1, shots do
                playShootSound(false, true)
            end
        elseif count < lastFireCount then
            lastFireCount = count
        end
    end))

    if Modules and Modules.NetworkClient and type(Modules.NetworkClient.send) == "function" then
        local network = Modules.NetworkClient
        local nextSend = network.send
        local shootSend = function(self, name, ...)
            if name == "newbullets" and Config.ShootSounds then
                playShootSound()
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
                playShootSound()
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
    local function weaponClassName(weapon)
        local data = weapon and (weapon._weaponData or weapon.weaponData or weapon._data)
        local label = ""
        if type(data) == "table" then
            label = tostring(data.displayname or data.displayName or data.name or data.Name or data.type or "")
        end
        if label == "" and weapon and type(weapon._name) == "string" then
            label = weapon._name
        end
        local upper = string.upper(label)
        local groups = {
            { "pistol", { "M9", "G17", "M1911", "DEAGLE", "DESERT", "MP412", "REX", "93R", "TEC", "FIVE", "MAKAROV", "M45", "ZIP", "SERBU", "SFG", "PISTOL" } },
            { "shotgun", { "KS-23", "KS23", "REMINGTON 870", "DBV", "SAIGA", "STEVENS", "SPAS", "AA-12", "USAS", "SHOTGUN" } },
            { "sniper", { "INTERVENTION", "REMINGTON 700", "AWS", "AWM", "TRG", "MOSIN", "SVD", "WA2000", "BFG", "HECATE", "SCOUT", "DRAGUNOV", "OBREZ", "SNIPER" } },
            { "lmg", { "M60", "HBAR", "MG36", "COLT LMG", "L86", "HAMR", "RPK", "HK21", "MG3", "LMG" } },
            { "pdw", { "MP5", "MP7", "MP10", "UMP", "P90", "VECTOR", "KRISS", "MAC10", "MP40", "PPSH", "TOMMY", "SR-3", "PDW", "SMG" } },
        }
        for _, group in groups do
            for _, token in group[2] do
                if string.find(upper, token, 1, true) then
                    return group[1]
                end
            end
        end
        if upper ~= "" then
            return "assault"
        end
        return nil
    end
    table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
        dt = math.clamp(dt or 0.016, 0, 0.05)
        local object = charInterface and charInterface.getCharacterObject and charInterface.getCharacterObject()
        local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
        local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
        local className = weaponClassName(weapon)
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
                if object._moveCooldown ~= nil then
                    object._moveCooldown = 0
                end
                if object._jumpCooldown ~= nil then
                    object._jumpCooldown = 0
                end
                if object._nextJump ~= nil then
                    object._nextJump = 0
                end
            end)
        end
        local root = rootPartOf(object)
        local cam = camera()
        local moving = Config.WalkSpeed or Config.SlideBoost or Config.CircleJump or Config.ZigzagJump or Config.Pathfind
        if moving and root then
            pcall(function()
                if object._speed ~= nil then
                    object._speed = math.max(tonumber(object._speed) or 0, Config.WalkSpeed and Config.SetSpeed or 16)
                end
            end)
            local wish = wishDirection(cam)
            local speed = Config.WalkSpeed and (tonumber(Config.SetSpeed) or 50) or 16
            if Config.SlideBoost and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                speed += tonumber(Config.SlideBoostSpeed) or 70
            end
            if Config.CircleJump and UserInputService:IsKeyDown(Enum.KeyCode.Z) then
                circleCenter = circleCenter or root.Position
                circleAngle += dt * 4
                local offset = Vector3.new(math.cos(circleAngle), 0, math.sin(circleAngle)) * 6
                wish = (circleCenter + offset - root.Position)
                wish = Vector3.new(wish.X, 0, wish.Z)
                if wish.Magnitude > 1e-3 then
                    wish = wish.Unit
                end
                speed = math.max(speed, 40)
            else
                circleCenter = nil
            end
            if Config.ZigzagJump and UserInputService:IsKeyDown(Enum.KeyCode.F) then
                local side = math.sin(os.clock() * 8)
                local right = cam and cam.CFrame.RightVector or Vector3.new(1, 0, 0)
                local look = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
                local flat = Vector3.new(look.X, 0, look.Z)
                local forward = flat.Magnitude > 1e-3 and flat.Unit or Vector3.new(0, 0, -1)
                if wish.Magnitude < 1e-3 then
                    wish = forward
                end
                local mixed = wish + right * side
                if mixed.Magnitude > 1e-3 then
                    wish = mixed.Unit
                end
                speed = math.max(speed, 36)
            end
            if Config.Pathfind then
                local point = getgenv().TapologyAimPoint
                if typeof(point) == "Vector3" then
                    local toward = Vector3.new(point.X - root.Position.X, 0, point.Z - root.Position.Z)
                    if toward.Magnitude > 4 then
                        wish = toward.Unit
                        speed = math.max(speed, Config.WalkSpeed and Config.SetSpeed or 28)
                    end
                end
            end
            local rate = math.clamp(tonumber(Config.MoveSmooth) or 12, 1, 40)
            smoothWish = smoothWish:Lerp(wish * speed, 1 - math.exp(-dt * rate))
            if smoothWish.Magnitude > 0.05 then
                root.CFrame = root.CFrame + smoothWish * dt
            end
        else
            smoothWish = smoothWish:Lerp(Vector3.zero, 1 - math.exp(-dt * 8))
        end
        if Config.RemoveDecals then
            local now = os.clock()
            if now - decalListedAt > 3 or decalIndex > #decalQueue then
                decalQueue = {}
                local roots = {}
                for _, rootName in { "Map", "Ignore" } do
                    local folder = workspace:FindFirstChild(rootName)
                    if folder then
                        table.insert(roots, folder)
                    end
                end
                if #roots == 0 then
                    roots = { workspace }
                end
                for _, rootFolder in roots do
                    for _, inst in rootFolder:GetDescendants() do
                        if inst:IsA("Decal") or inst:IsA("Texture") then
                            table.insert(decalQueue, inst)
                        end
                    end
                end
                decalIndex = 1
                decalListedAt = now
            end
            local scanned = 0
            while decalIndex <= #decalQueue and scanned < 25 do
                local inst = decalQueue[decalIndex]
                decalIndex += 1
                if typeof(inst) == "Instance" and inst.Parent and hiddenDecals[inst] == nil and not inst:FindFirstAncestor("TapologyField") then
                    hiddenDecals[inst] = inst.Transparency
                    inst.Transparency = 1
                    scanned += 1
                end
            end
        elseif next(hiddenDecals) then
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
        if Config.HeightBypass and Config.JumpPower and root then
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

    local crossGui = Instance.new("ScreenGui")
    crossGui.Name = "TapologyCrosshair"
    crossGui.IgnoreGuiInset = true
    crossGui.ResetOnSpawn = false
    crossGui.DisplayOrder = 20
    crossGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    local crossHolder = Instance.new("Frame")
    crossHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    crossHolder.BackgroundTransparency = 1
    crossHolder.Size = UDim2.fromOffset(80, 80)
    crossHolder.Visible = false
    crossHolder.Parent = crossGui
    local crossBars = {}
    for i = 1, 4 do
        local bar = Instance.new("Frame")
        bar.AnchorPoint = Vector2.new(0.5, 0.5)
        bar.BorderSizePixel = 0
        bar.Parent = crossHolder
        crossBars[i] = bar
    end
    bindStep("TapologyCrosshair", Enum.RenderPriority.Camera.Value + 120, function()
        local cam = camera()
        crossHolder.Visible = Config.Crosshair and cam ~= nil
        if not crossHolder.Visible or not cam then
            return
        end
        local center = cam.ViewportSize * 0.5
        if Config.CrosshairMode == "ingame" then
            local mouse = UserInputService:GetMouseLocation()
            crossHolder.Position = UDim2.fromOffset(mouse.X, mouse.Y)
        else
            crossHolder.Position = UDim2.fromOffset(center.X, center.Y)
        end
        local bounce = math.sin(os.clock() * (tonumber(Config.CrosshairBounceSpeed) or 6)) * (tonumber(Config.CrosshairBounce) or 0)
        local gap = math.max(0, (tonumber(Config.CrosshairGap) or 4) + bounce)
        local length = math.clamp(tonumber(Config.CrosshairLength) or 8, 1, 40)
        local thick = math.clamp(tonumber(Config.CrosshairThickness) or 2, 1, 8)
        crossHolder.Rotation = os.clock() * (tonumber(Config.CrosshairSpinSpeed) or 0) * (tonumber(Config.CrosshairSpin) or 0)
        local colors = { Config.CrosshairColor1, Config.CrosshairColor2, Config.CrosshairColor3, Config.CrosshairColor4 }
        local layout = {
            { 40, 40 - gap - length / 2, thick, length },
            { 40 + gap + length / 2, 40, length, thick },
            { 40, 40 + gap + length / 2, thick, length },
            { 40 - gap - length / 2, 40, length, thick },
        }
        for i = 1, 4 do
            local bar = crossBars[i]
            local spot = layout[i]
            bar.Position = UDim2.fromOffset(spot[1], spot[2])
            bar.Size = UDim2.fromOffset(spot[3], spot[4])
            bar.BackgroundColor3 = colors[i] or Color3.new(1, 1, 1)
        end
    end)
    table.insert(Restores, function()
        crossGui:Destroy()
    end)
end

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

do
    local okAura, errAura = pcall(main)
    if not okAura then
        warn("[Aura] main failed:", errAura)
        getgenv()._TapologyAuraErr = tostring(errAura)
    end
end

end
loadRemote("hiteffect")
loadRemote("killeffect")
loadRemote("tracer")
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
    if getgenv()._TapologyMenuBuilt == menuGeneration and tabCount >= 7 and pagesOk then
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
assert(Rage, "Rage failed to embed")
assert(Misc, "Misc failed to embed")

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

local function buildLegitUi()
local editingClass = aim().Config.Class or "assault"
local function touch(key, value)
    local profiles = aim().Config.Profiles
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
    touch("SilentEnabled", on)
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
if not Aim.SilentAvailable then
    Library:Notify("silent aim needs a rejoin with the debug flag (esp turns it on)", 4)
end

local classColumns = legit.Frame and legit.Frame:FindFirstChild("Columns")
if classColumns then
    local oldBar = legit.Frame:FindFirstChild("ClassBar")
    if oldBar then
        oldBar:Destroy()
    end
    local inset = classColumns.Position.X.Offset
    local barHeight = 40
    local gap = 10
    local bar = Instance.new("Frame")
    bar.Name = "ClassBar"
    bar.BackgroundTransparency = 1
    bar.ClipsDescendants = false
    bar.Position = UDim2.fromOffset(inset, inset)
    bar.Size = UDim2.new(1, -(inset * 2), 0, barHeight)
    bar.ZIndex = 5
    bar.Parent = legit.Frame
    local barLayout = Instance.new("UIListLayout")
    barLayout.SortOrder = Enum.SortOrder.LayoutOrder
    barLayout.Parent = bar
    classColumns.Position = UDim2.fromOffset(inset, inset + barHeight + gap)
    UI.Dropdown(bar, "weapon class", {
        Values = Aim.Classes or { "assault", "pdw", "lmg", "sniper", "shotgun", "pistol" },
        Default = editingClass,
    }, function(value)
        editingClass = value
        aim().Config.Class = value
        local profile = aim().Config.Profiles and aim().Config.Profiles[value]
        if not profile then
            return
        end
        mouseEnable:Set(profile.MouseEnabled)
        silentEnable:Set(profile.SilentEnabled)
        mouseFov:Set(profile.MouseFOV)
        silentFov:Set(profile.SilentFOV)
        mouseShow:Set(profile.MouseShowFOV)
        silentShow:Set(profile.SilentShowFOV)
        mouseOrigin:Set(profile.MouseFOVOrigin)
        silentOrigin:Set(profile.SilentFOVOrigin)
        mouseSmooth:Set(profile.Smoothness)
        mouseKey:Set(profile.MouseKey)
        targetPart:Set(profile.TargetPart)
        visibleCheck:Set(profile.VisibleCheck)
        maxDistance:Set(profile.MaxDistance)
        hitChance:Set(profile.HitChance)
    end)
end
end
buildLegitUi()

local function buildRageUi()
local rageBot = rageTab:Groupbox("ragebot", "left")
local antiAim = rageTab:Groupbox("anti aim", "left")
local visualizing = rageTab:Groupbox("visualizing", "left")
local fakeLag = rageTab:Groupbox("fake lag", "right")

rage().Config.WhitelistFriendlyStatus = true
rage().Config.ShootEffects = true
if rage().Config.Mode ~= "edge" then
    rage().Config.Mode = "default"
end

local rageEnable = rageBot:Toggle("enable", Rage.Config.Enabled, function(on)
    rage().SetEnabled(on)
end)
rageEnable:Keybind()
local rageKids = rageEnable:Children()
rageKids:Dropdown("mode", {
    Values = { "default", "edge" },
    Default = Rage.Config.Mode == "edge" and "edge" or "default",
}, function(value)
    rage().Config.Mode = value == "edge" and "edge" or "default"
end)
rageKids:Slider("fire position", {
    Min = 0,
    Max = 12,
    Default = math.clamp(tonumber(Rage.Config.FirePositionOffset) or 10, 0, 12),
    Decimals = 1,
    Suffix = "st",
    }, function(value)
    rage().Config.FirePositionOffset = value
    rage().Config.FirePositionScanning = value > 0
end)
rageKids:Slider("hit offset", {
    Min = 0,
    Max = 12,
    Default = math.clamp(tonumber(Rage.Config.HitPositionOffset) or 10, 0, 12),
    Decimals = 1,
    Suffix = "st",
}, function(value)
    rage().Config.HitPositionOffset = value
    rage().Config.HitPositionScanning = value > 0
end)
rageKids:Dropdown("priority", {
    Values = { "Closest to Crosshair", "Closest to Local", "Lowest Health" },
    Default = Rage.Config.Priority or "Closest to Crosshair",
}, function(value)
    rage().Config.Priority = value
end)
rageKids:Slider("targets", {
    Min = 1,
    Max = 12,
    Default = math.clamp(math.floor(tonumber(Rage.Config.MaxTargets) or 12), 1, 12),
    Decimals = 0,
}, function(value)
    rage().Config.MaxTargets = value
end)
rageKids:Toggle("prediction", Rage.Config.Prediction ~= false, function(on)
    rage().Config.Prediction = on
end)
local resolverToggle = rageKids:Toggle("resolver", Rage.Config.Resolver, function(on)
    rage().Config.Resolver = on
end)
local resolverKids = resolverToggle:Children()
resolverKids:Slider("strength", {
    Min = 0.5,
    Max = 10,
    Default = Rage.Config.ResolverStrength or 4,
    Decimals = 1,
    Suffix = "st",
}, function(value)
    rage().Config.ResolverStrength = value
end)
resolverKids:Slider("cooldown", {
    Min = 0.1,
    Max = 5,
    Default = Rage.Config.ResolverCooldown or 1,
    Decimals = 1,
    Suffix = "s",
}, function(value)
    rage().Config.ResolverCooldown = value
end)
local perf = rageEnable:Settings("performance")
perf:Slider("bullet checks", {
    Min = 4,
    Max = 80,
    Default = Rage.Config.MaxBulletChecks or 40,
    Decimals = 0,
}, function(value)
    rage().Config.MaxBulletChecks = value
end)
perf:Slider("frame checks", {
    Min = 8,
    Max = 256,
    Default = Rage.Config.MaxFrameChecks or 128,
    Decimals = 0,
}, function(value)
    rage().Config.MaxFrameChecks = value
end)
perf:Slider("scan budget", {
    Min = 1,
    Max = 8,
    Default = Rage.Config.ScanBudgetMs or 5,
    Decimals = 1,
    Suffix = "ms",
}, function(value)
    rage().Config.ScanBudgetMs = value
end)
perf:Dropdown("scan type", {
    Values = { "V1", "V2" },
    Default = Rage.Config.HitPositionScanMode == "V2" and "V2" or "V1",
}, function(value)
    rage().Config.HitPositionScanMode = value == "V2" and "V2" or "V1"
end)
perf:Toggle("show scan range", Rage.Config.ShowScanRange, function(on)
    rage().Config.ShowScanRange = on
end)
perf:Slider("scan range", {
    Min = 5,
    Max = 400,
    Default = Rage.Config.ScanRangeVisual or 80,
    Suffix = "st",
}, function(value)
    rage().Config.ScanRangeVisual = value
end)
if not Rage.Available then
    Library:Notify("rage needs a rejoin with the debug flag (visuals turns it on)", 4)
end

local aaEnable = antiAim:Toggle("enable", Rage.Config.AntiAim, function(on)
    rage().Config.AntiAim = on
end)
aaEnable:Keybind()
local aaKids = aaEnable:Children()
local aaTypes = { "static", "sine", "jitter", "ways", "180" }
aaKids:Dropdown("pitch type", {
    Values = aaTypes,
    Default = Rage.Config.PitchType or "static",
}, function(value)
    rage().Config.PitchType = value
end)
aaKids:Slider("pitch", {
    Min = -89,
    Max = 89,
    Default = Rage.Config.PitchAmount or 0,
    Decimals = 1,
    Suffix = "deg",
}, function(value)
    rage().Config.PitchAmount = value
end)
aaKids:Slider("pitch ways", {
    Min = 2,
    Max = 10,
    Default = Rage.Config.PitchWays or 7,
    Decimals = 0,
}, function(value)
    rage().Config.PitchWays = value
end)
aaKids:Dropdown("yaw type", {
    Values = aaTypes,
    Default = Rage.Config.YawType or "static",
}, function(value)
    rage().Config.YawType = value
end)
aaKids:Slider("yaw", {
    Min = -180,
    Max = 180,
    Default = Rage.Config.YawAmount or 180,
    Decimals = 1,
    Suffix = "deg",
}, function(value)
    rage().Config.YawAmount = value
end)
aaKids:Slider("yaw ways", {
    Min = 2,
    Max = 10,
    Default = Rage.Config.YawWays or 7,
    Decimals = 0,
}, function(value)
    rage().Config.YawWays = value
end)
aaKids:Slider("speed", {
    Min = 1,
    Max = 20,
    Default = Rage.Config.AASpeed or 6,
    Decimals = 1,
}, function(value)
    rage().Config.AASpeed = value
end)
local fakePos = antiAim:Toggle("fake position", Rage.Config.FakePosition, function(on)
    rage().Config.FakePosition = on
end)
local fakePosKids = fakePos:Children()
fakePosKids:Slider("distance", {
    Min = 0,
    Max = 14,
    Default = Rage.Config.FakePositionDistance or 4,
    Decimals = 1,
    Suffix = "st",
}, function(value)
    rage().Config.FakePositionDistance = value
end)
fakePosKids:Slider("height", {
    Min = -6,
    Max = 6,
    Default = Rage.Config.FakePositionHeight or 0,
    Decimals = 1,
    Suffix = "st",
}, function(value)
    rage().Config.FakePositionHeight = value
end)
local indicators = visualizing:Toggle("rage indicators", Rage.Config.Indicators ~= false, function(on)
    rage().Config.Indicators = on
end)
local indicatorKids = indicators:Children()
local rageInd = indicatorKids:Toggle("ragebot", Rage.Config.IndicatorRagebot ~= false, function(on)
    rage().Config.IndicatorRagebot = on
end)
rageInd:ColorPicker(Rage.Config.IndicatorRageActive or Color3.fromRGB(255, 255, 255), function(color)
    rage().Config.IndicatorRageActive = color
end)
rageInd:ColorPicker(Rage.Config.IndicatorRageIdle or Color3.fromRGB(255, 255, 255), function(color)
    rage().Config.IndicatorRageIdle = color
end)
local resInd = indicatorKids:Toggle("resolver", Rage.Config.IndicatorResolver ~= false, function(on)
    rage().Config.IndicatorResolver = on
end)
resInd:ColorPicker(Rage.Config.IndicatorResolverReady or Color3.fromRGB(255, 255, 255), function(color)
    rage().Config.IndicatorResolverReady = color
end)
resInd:ColorPicker(Rage.Config.IndicatorResolverCooldown or Color3.fromRGB(180, 180, 190), function(color)
    rage().Config.IndicatorResolverCooldown = color
end)

local fakeLagEnable = fakeLag:Toggle("enable", Rage.Config.FakeLag, function(on)
    rage().Config.FakeLag = on
end)
fakeLagEnable:Keybind()
local fakeLagKids = fakeLagEnable:Children()
fakeLagKids:Slider("amount", {
    Min = 0,
    Max = 2.8,
    Default = math.clamp(tonumber(Rage.Config.FakeLagAmount) or 1.2, 0, 2.8),
    Decimals = 1,
    Suffix = "st",
}, function(value)
    rage().Config.FakeLagAmount = value
end)
fakeLagKids:Slider("hold", {
    Min = 0.05,
    Max = 3,
    Default = Rage.Config.FakeLagHold or 0.35,
    Decimals = 2,
    Suffix = "s",
}, function(value)
    rage().Config.FakeLagHold = value
end)
fakeLagKids:Slider("smooth", {
    Min = 0,
    Max = 1,
    Default = Rage.Config.FakeLagSmooth or 0.45,
    Decimals = 2,
}, function(value)
    rage().Config.FakeLagSmooth = value
end)
visualizing:Toggle("rage visual", Rage.Config.RageVisual, function(on)
    rage().Config.RageVisual = on
end)
end
buildRageUi()

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
boxCfg:ColorPicker("color", ESP.Config.BoxColor, function(color)
    esp().SetColor("Box", color, 1 - ESP.Config.BoxTransparency)
end)
boxCfg:ColorPicker("outline", ESP.Config.OutlineColor, function(color)
    esp().SetColor("Outline", color, 1 - ESP.Config.OutlineTransparency)
end)
local healthToggle = espBox:Toggle("healthbar", ESP.Config.ShowHealth, function(on)
    esp().Config.ShowHealth = on
end)
local healthCfg = healthToggle:Settings("healthbar")
healthCfg:Toggle("outline", ESP.Config.HealthOutline ~= false, function(on)
    esp().Config.HealthOutline = on
end)
healthCfg:ColorPicker("color", ESP.Config.HealthColor, function(color)
    esp().SetColor("Health", color, 1 - ESP.Config.HealthTransparency)
end)
healthCfg:ColorPicker("low", ESP.Config.HealthLowColor, function(color)
    esp().Config.HealthLowColor = color
end)
local snapToggle = espBox:Toggle("snaplines", ESP.Config.Snaplines, function(on)
    esp().Config.Snaplines = on
end)
local snapCfg = snapToggle:Settings("snaplines")
snapCfg:Toggle("outline", ESP.Config.SnaplineOutline ~= false, function(on)
    esp().Config.SnaplineOutline = on
end)
snapCfg:ColorPicker("color", ESP.Config.SnaplineColor, function(color)
    esp().Config.SnaplineColor = color
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
oovCfg:ColorPicker("color", ESP.Config.OOVColor, function(color)
    esp().Config.OOVColor = color
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
chamCfg:ColorPicker("visible fill", ESP.Config.HighlightVisibleFillColor, function(color)
    esp().SetColor("HighlightVisibleFill", color, 1 - ESP.Config.HighlightVisibleFillTransparency)
end)
chamCfg:ColorPicker("visible line", ESP.Config.HighlightVisibleOutlineColor, function(color)
    esp().SetColor("HighlightVisibleOutline", color, 1 - ESP.Config.HighlightVisibleOutlineTransparency)
end)
chamCfg:Toggle("occluded", ESP.Config.HighlightOccluded, function(on)
    esp().Config.HighlightOccluded = on
end)
chamCfg:ColorPicker("occluded fill", ESP.Config.HighlightOccludedFillColor, function(color)
    esp().SetColor("HighlightOccludedFill", color, 1 - ESP.Config.HighlightOccludedFillTransparency)
end)
chamCfg:ColorPicker("occluded line", ESP.Config.HighlightOccludedOutlineColor, function(color)
    esp().SetColor("HighlightOccludedOutline", color, 1 - ESP.Config.HighlightOccludedOutlineTransparency)
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
    world().Set("DynamicExposureMin", value)
end)
dynamicKids:Slider("max", { Min = 0, Max = 2, Default = World.Config.DynamicExposureMax, Decimals = 2 }, function(value)
    world().Set("DynamicExposureMax", value)
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
local hitSoundTab = tracersBox:Subtab("hit sounds")
local hitLogTab = tracersBox:Subtab("hit logs")
local aurasBox = miscTab:Groupbox("auras", "left")

local effectsBox = miscTab:Groupbox("effects", "right")
local hitsBox = effectsBox:Subtab("hit effects")
local killsBox = effectsBox:Subtab("kill effects")

local viewmodelModBox = miscTab:Groupbox("viewmodel modify", "right")
local vmModifyTab = viewmodelModBox:Subtab("modify")
local vmShootTab = viewmodelModBox:Subtab("shoot")
local vmRemovalsTab = viewmodelModBox:Subtab("removals")

local walk = movementBox:Toggle("walk speed", Misc.Config.WalkSpeed, function(on)
    misc().Config.WalkSpeed = on
end)
walk:Keybind()
walk:Children():Slider("speed", { Min = 10, Max = 250, Default = Misc.Config.SetSpeed, Suffix = "st/s" }, function(value)
    misc().Config.SetSpeed = value
end)
local jump = movementBox:Toggle("jump power", Misc.Config.JumpPower, function(on)
    misc().Config.JumpPower = on
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
    misc().Config.NoMoveCooldown = on
end)
local height = movementBox:Toggle("height bypass", Misc.Config.HeightBypass, function(on)
    misc().Config.HeightBypass = on
end)
height:Children():Slider("timer", { Min = 0.2, Max = 8, Default = Misc.Config.HeightBypassTime or 1.5, Decimals = 1, Suffix = "s" }, function(value)
    misc().Config.HeightBypassTime = value
end)
movementBox:Toggle("z circle", Misc.Config.CircleJump, function(on)
    misc().Config.CircleJump = on
end)
movementBox:Toggle("f zigzag", Misc.Config.ZigzagJump, function(on)
    misc().Config.ZigzagJump = on
end)
movementBox:Toggle("pathfind", Misc.Config.Pathfind, function(on)
    misc().Config.Pathfind = on
end)
movementBox:Slider("move smooth", { Min = 1, Max = 40, Default = Misc.Config.MoveSmooth or 12 }, function(value)
    misc().Config.MoveSmooth = value
end)

local third = cameraBox:Toggle("third person", Misc.Config.ThirdPerson, function(on)
    misc().Config.ThirdPerson = on
    if on then
        misc().Config.HideViewmodel = true
    end
end)
third:Keybind()
local thirdKids = third:Children()
thirdKids:Toggle("show character", Misc.Config.ShowCharacter, function(on)
    misc().Config.ShowCharacter = on
end)
thirdKids:Toggle("show while aiming", Misc.Config.ShowCharacterWhileAiming, function(on)
    misc().Config.ShowCharacterWhileAiming = on
end)
thirdKids:Toggle("hide viewmodel", Misc.Config.HideViewmodel ~= false, function(on)
    misc().Config.HideViewmodel = on
end)
misc().Config.ApplyAntiAimToCharacter = true
local smoothCam = thirdKids:Toggle("smooth follow", Misc.Config.CameraSmooth, function(on)
    misc().Config.CameraSmooth = on
end)
smoothCam:Children():Slider("smoothness", { Min = 1, Max = 40, Default = Misc.Config.CameraSmoothness, Suffix = "/s" }, function(value)
    misc().Config.CameraSmoothness = value
end)
thirdKids:Slider("offset x", { Min = -20, Max = 20, Default = Misc.Config.CameraOffsetX, Decimals = 1, Suffix = "st" }, function(value)
    misc().Config.CameraOffsetX = value
end)
thirdKids:Slider("offset y", { Min = -20, Max = 20, Default = Misc.Config.CameraOffsetY, Decimals = 1, Suffix = "st" }, function(value)
    misc().Config.CameraOffsetY = value
end)
thirdKids:Slider("offset z", { Min = -20, Max = 20, Default = Misc.Config.CameraOffsetZ, Decimals = 1, Suffix = "st" }, function(value)
    misc().Config.CameraOffsetZ = value
end)
thirdKids:Toggle("always visible", Misc.Config.CameraOffsetAlwaysVisible, function(on)
    misc().Config.CameraOffsetAlwaysVisible = on
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

local removalsEnable = vmRemovalsTab:Toggle("enable", Misc.Config.Removals, function(on)
    misc().Config.Removals = on
    local cfg = misc().Config
    cfg.RemoveDecals = on and cfg.RemoveItems and cfg.RemoveItems.decals or false
    cfg.RemoveArms = on and cfg.RemoveItems and cfg.RemoveItems.arms or false
    cfg.RemoveAnimations = on and cfg.RemoveItems and cfg.RemoveItems.animations or false
    cfg.RemoveTeam = on and cfg.RemoveItems and cfg.RemoveItems.team or false
    cfg.RemoveEnemy = on and cfg.RemoveItems and cfg.RemoveItems.enemy or false
    cfg.RemoveExplosions = on and cfg.RemoveItems and cfg.RemoveItems.explosions or false
    cfg.RemoveDroppedGuns = on and cfg.RemoveItems and cfg.RemoveItems.dropped or false
end)
local removalKids = removalsEnable:Children()
removalKids:Dropdown("items", {
    Multi = true,
    Values = { "decals", "arms", "animations", "team", "enemy", "explosions", "dropped" },
    Default = Misc.Config.RemoveItems or {},
}, function(value)
    misc().Config.RemoveItems = value
    local cfg = misc().Config
    local on = cfg.Removals == true
    cfg.RemoveDecals = on and value.decals or false
    cfg.RemoveArms = on and value.arms or false
    cfg.RemoveAnimations = on and value.animations or false
    cfg.RemoveTeam = on and value.team or false
    cfg.RemoveEnemy = on and value.enemy or false
    cfg.RemoveExplosions = on and value.explosions or false
    cfg.RemoveDroppedGuns = on and value.dropped or false
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

local hitSounds = hitSoundTab:Toggle("enable", Tracers.Config.HitSounds, function(on)
    tracers().Config.HitSounds = on
end)
local hitSoundKids = hitSounds:Children()
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
armsKids:ColorPicker("color", Misc.Config.ArmsChamsColor or Color3.fromRGB(108, 147, 255), function(color)
    misc().Config.ArmsChamsColor = color
end)
armsKids:Slider("alpha", { Min = 0, Max = 0.92, Default = Misc.Config.ArmsChamsAlpha or 0, Decimals = 2 }, function(value)
    misc().Config.ArmsChamsAlpha = value
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
bodyKids:ColorPicker("color", Misc.Config.BodyChamsColor or Color3.fromRGB(255, 190, 150), function(color)
    misc().Config.BodyChamsColor = color
end)
bodyKids:Slider("alpha", { Min = 0, Max = 0.92, Default = Misc.Config.BodyChamsAlpha or 0, Decimals = 2 }, function(value)
    misc().Config.BodyChamsAlpha = value
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
weaponKids:ColorPicker("color", Misc.Config.WeaponChamsColor or Color3.fromRGB(108, 147, 255), function(color)
    misc().Config.WeaponChamsColor = color
end)
weaponKids:Slider("alpha", { Min = 0, Max = 0.92, Default = Misc.Config.WeaponChamsAlpha or 0, Decimals = 2 }, function(value)
    misc().Config.WeaponChamsAlpha = value
end)

local shootOn = vmShootTab:Toggle("enable", Misc.Config.ShootSounds, function(on)
    misc().Config.ShootSounds = on
end)
local shootKids = shootOn:Children()
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
    popup.Position = UDim2.fromOffset(math.clamp(mouse.X, 0, math.max(vs.X - 124, 0)), math.clamp(mouse.Y, 0, math.max(vs.Y - 110, 0)))
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
    if count1 >= 7 then
        getgenv()._TapologyMenuBuilt = menuGeneration
    else
        getgenv()._TapologyMenuBuilt = nil
        getgenv()._TapologyMenuErr = "incomplete tab strip (" .. tostring(count1) .. ")"
    end
end
end
task.defer(buildTapologyMenu)
task.delay(0.2, buildTapologyMenu)
task.delay(0.75, buildTapologyMenu)
task.delay(1.5, buildTapologyMenu)
task.delay(3, buildTapologyMenu)
getgenv()._TapologyScriptTail = os.clock()
getgenv()._TapologyMenuGenAtTail = menuGeneration
