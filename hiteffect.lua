do

local warn = function() end

local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local TweenService = cloneref(game:GetService("TweenService"))

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local Config = {
    Enabled = false,
    Style = "Aether",
    Scale = 1,
    OnDamage = true,
    Demo = false,
    DemoEffects = { "Aether", "Blossom", "Inferno", "Plasma", "Frost", "Lightning", "Rift", "Starfall", "Cosmos", "Void" },
    DemoInterval = 1.2,
    DemoDistance = 12,

    Colors = {
        Aether = { Silk = rgb(255, 212, 135), Threads = rgb(120, 220, 255), Runes = rgb(150, 230, 255), Motes = rgb(255, 235, 180) },
        Blossom = { Glow = rgb(255, 160, 200), Petals = { rgb(255, 190, 215), rgb(255, 160, 200), rgb(255, 228, 238) } },
        Inferno = { Outer = rgb(255, 60, 15), Inner = rgb(255, 165, 50), Embers = rgb(255, 140, 40) },
        Plasma = { Core = rgb(170, 240, 255), Sparks = rgb(130, 230, 255) },
        Frost = { Ice = rgb(170, 228, 255), Flakes = rgb(230, 248, 255), Glints = rgb(205, 242, 255) },
        Lightning = { Bolt = rgb(225, 234, 255), Sparks = rgb(190, 208, 255) },
        Rift = { Cyan = rgb(40, 230, 255), Pixels = { rgb(255, 40, 95), rgb(40, 230, 255), rgb(235, 245, 255) } },
        Starfall = { Glow = rgb(255, 160, 60), Stars = rgb(255, 226, 150) },
        Cosmos = { Nebula = rgb(140, 70, 230), Stars = rgb(235, 235, 255), Rings = rgb(165, 145, 255) },
        Void = { Wisps = rgb(95, 45, 140), Embers = rgb(215, 145, 255) },
    },
    TextureFolder = "hiteffect_textures",
}

local TextureIds

local env = getgenv and getgenv() or _G
if env.HitEffects then
    env.HitEffects.Unload()
end

local LocalPlayer = Players.LocalPlayer
local base64decode = (crypt and crypt.base64decode) or base64_decode or (base64 and base64.decode)

local Textures = {}
local Effects = {}
local Container
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

local function colorList(value)
    return typeof(value) == "table" and value or { value }
end

local function burst(position, count, color, props)
    local part = newPart("Burst", Vector3.one * (props.Spread or 0.4), Container)
    part.CFrame = CFrame.new(position)
    props.Spread = nil
    props.Enabled = false
    props.LightInfluence = props.LightInfluence or 0
    local colors = colorList(color)
    for _, c in colors do
        local emitterProps = table.clone(props)
        emitterProps.Color = emitterProps.Color or ColorSequence.new(c)
        emitterProps.Parent = part
        create("ParticleEmitter", emitterProps):Emit(math.ceil(count / #colors))
    end
    task.delay(props.Lifetime.Max + 0.2, part.Destroy, part)
end

local function flash(position, color, brightness, range, duration)
    local part = newPart("Flash", Vector3.one, Container)
    part.CFrame = CFrame.new(position)
    local light = create("PointLight", { Color = color, Brightness = brightness, Range = range, Shadows = false, Parent = part })
    TweenService:Create(light, TweenInfo.new(duration, Enum.EasingStyle.Quad), { Brightness = 0 }):Play()
    task.delay(duration, part.Destroy, part)
end

local function bloom(position, texture, color, from, to, duration, rotSpeed)
    burst(position, 1, color, {
        Texture = Textures[texture],
        Lifetime = NumberRange.new(duration),
        Speed = NumberRange.new(0),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(rotSpeed or 0),
        Size = numberSequence({ { 0, from }, { 0.3, to * 0.85 }, { 1, to } }),
        Transparency = numberSequence({ { 0, 0.1 }, { 0.5, 0.35 }, { 1, 1 } }),
        LightEmission = 1,
        Brightness = 1.5,
    })
end

local petalFlutter = numberSequence({ { 0, 0 }, { 0.2, 0.6 }, { 0.4, -0.5 }, { 0.6, 0.6 }, { 0.8, -0.5 }, { 1, 0 } })

function Effects.Aether(position, colors, scale)
    flash(position, colors.Silk, 1, 9, 0.5)
    bloom(position, "rune", colors.Runes, 0.5 * scale, 3.4 * scale, 0.9, 60)
    burst(position, 12, colors.Threads, {
        Texture = Textures.sparkle,
        Lifetime = NumberRange.new(0.6, 1.1),
        Speed = NumberRange.new(2, 5),
        SpreadAngle = Vector2.new(180, 180),
        Drag = 3,
        Rotation = NumberRange.new(0, 90),
        Size = numberSequence({ { 0, 0.3 * scale }, { 1, 0 } }),
        LightEmission = 1,
        Brightness = 1.6,
    })
    burst(position, 10, colors.Motes, {
        Texture = Textures.dot,
        Lifetime = NumberRange.new(1, 1.6),
        Speed = NumberRange.new(0.5, 2),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, 2, 0),
        Size = numberSequence({ { 0, 0.11 * scale }, { 1, 0 } }),
        LightEmission = 1,
        Brightness = 1.6,
    })
end

function Effects.Blossom(position, colors, scale)
    flash(position, colors.Glow, 0.8, 8, 0.4)
    burst(position, 18, colors.Petals, {
        Texture = Textures.petal,
        Lifetime = NumberRange.new(1.6, 2.6),
        Speed = NumberRange.new(3, 7),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, -4, 0),
        Drag = 2.5,
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-200, 200),
        Squash = petalFlutter,
        Size = numberSequence({ { 0, 0.3 * scale }, { 0.85, 0.26 * scale }, { 1, 0 } }),
        Transparency = numberSequence({ { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } }),
        LightInfluence = 0.15,
        Brightness = 1.4,
    })
end

function Effects.Inferno(position, colors, scale)
    flash(position, colors.Outer, 1.5, 10, 0.35)
    burst(position, 14, colors.Inner, {
        Texture = Textures.flamelet,
        Color = ColorSequence.new(colors.Inner, colors.Outer),
        Lifetime = NumberRange.new(0.4, 0.8),
        Speed = NumberRange.new(2, 6),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, 8, 0),
        Drag = 2,
        Rotation = NumberRange.new(-20, 20),
        Size = numberSequence({ { 0, 0.6 * scale }, { 1, 0.05 } }),
        Transparency = numberSequence({ { 0, 0 }, { 1, 1 } }),
        LightEmission = 1,
        Brightness = 1.6,
    })
    burst(position, 16, colors.Embers, {
        Texture = Textures.dot,
        Lifetime = NumberRange.new(0.8, 1.5),
        Speed = NumberRange.new(3, 8),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, 3, 0),
        Drag = 2,
        Size = numberSequence({ { 0, 0.1 * scale }, { 1, 0 } }),
        LightEmission = 1,
        Brightness = 1.8,
    })
end

function Effects.Plasma(position, colors, scale)
    flash(position, colors.Core, 1.5, 10, 0.3)
    burst(position, 22, colors.Sparks, {
        Texture = Textures.spark,
        Orientation = Enum.ParticleOrientation.VelocityParallel,
        Lifetime = NumberRange.new(0.25, 0.5),
        Speed = NumberRange.new(10, 20),
        SpreadAngle = Vector2.new(180, 180),
        Drag = 4,
        Size = numberSequence({ { 0, 0.3 * scale }, { 1, 0.05 } }),
        LightEmission = 1,
        Brightness = 2,
    })
end

function Effects.Frost(position, colors, scale)
    flash(position, colors.Ice, 1, 9, 0.4)
    burst(position, 18, colors.Glints, {
        Texture = Textures.spark,
        Orientation = Enum.ParticleOrientation.VelocityParallel,
        Lifetime = NumberRange.new(0.3, 0.6),
        Speed = NumberRange.new(6, 14),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, -12, 0),
        Drag = 2,
        Size = numberSequence({ { 0, 0.3 * scale }, { 1, 0.05 } }),
        LightEmission = 1,
        Brightness = 1.8,
    })
    burst(position, 12, colors.Flakes, {
        Texture = Textures.flake,
        Lifetime = NumberRange.new(1, 1.8),
        Speed = NumberRange.new(1, 4),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, -2, 0),
        Drag = 2,
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-90, 90),
        Size = numberSequence({ { 0, 0.3 * scale }, { 1, 0.1 } }),
        Transparency = numberSequence({ { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } }),
        LightEmission = 0.6,
        Brightness = 1.5,
    })
end

function Effects.Lightning(position, colors, scale)
    flash(position, colors.Bolt, 2.5, 12, 0.3)
    burst(position, 24, colors.Sparks, {
        Texture = Textures.spark,
        Orientation = Enum.ParticleOrientation.VelocityParallel,
        Lifetime = NumberRange.new(0.25, 0.6),
        Speed = NumberRange.new(10, 22),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, -20, 0),
        Drag = 3,
        Size = numberSequence({ { 0, 0.26 * scale }, { 1, 0.05 } }),
        LightEmission = 1,
        Brightness = 2,
    })
end

function Effects.Rift(position, colors, scale)
    flash(position, colors.Cyan, 1, 8, 0.25)
    burst(position, 24, colors.Pixels, {
        Texture = Textures.pixel,
        Lifetime = NumberRange.new(0.3, 0.7),
        Speed = NumberRange.new(2, 7),
        SpreadAngle = Vector2.new(180, 180),
        Drag = 4,
        Size = numberSequence({ { 0, 0.22 * scale }, { 1, 0.22 * scale } }),
        Transparency = numberSequence({ { 0, 0 }, { 0.7, 0 }, { 1, 1 } }),
        LightEmission = 1,
        Brightness = 1.6,
    })
end

function Effects.Starfall(position, colors, scale)
    flash(position, colors.Glow, 1.2, 10, 0.5)
    burst(position, 18, colors.Stars, {
        Texture = Textures.sparkle,
        Lifetime = NumberRange.new(0.8, 1.5),
        Speed = NumberRange.new(3, 8),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, -6, 0),
        Drag = 2,
        Rotation = NumberRange.new(0, 90),
        RotSpeed = NumberRange.new(-120, 120),
        Size = numberSequence({ { 0, 0.42 * scale }, { 1, 0 } }),
        LightEmission = 1,
        Brightness = 1.8,
    })
end

function Effects.Cosmos(position, colors, scale)
    flash(position, colors.Nebula, 1.2, 10, 0.5)
    bloom(position, "ring", colors.Rings, 0.2 * scale, 4 * scale, 0.7)
    burst(position, 18, colors.Stars, {
        Texture = Textures.sparkle,
        Lifetime = NumberRange.new(0.7, 1.3),
        Speed = NumberRange.new(2, 6),
        SpreadAngle = Vector2.new(180, 180),
        Drag = 2,
        Rotation = NumberRange.new(0, 90),
        Size = numberSequence({ { 0, 0.32 * scale }, { 1, 0 } }),
        LightEmission = 1,
        Brightness = 1.8,
    })
end

function Effects.Void(position, colors, scale)
    flash(position, colors.Embers, 1, 8, 0.4)
    burst(position, 8, colors.Wisps, {
        Texture = Textures.puff,
        Lifetime = NumberRange.new(1, 1.8),
        Speed = NumberRange.new(1, 3),
        SpreadAngle = Vector2.new(180, 180),
        Drag = 2,
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-60, 60),
        Size = numberSequence({ { 0, 0.5 * scale }, { 1, 2 * scale } }),
        Transparency = numberSequence({ { 0, 0.4 }, { 1, 1 } }),
        LightEmission = 0.1,
    })
    burst(position, 14, colors.Embers, {
        Texture = Textures.dot,
        Lifetime = NumberRange.new(0.6, 1.2),
        Speed = NumberRange.new(3, 7),
        SpreadAngle = Vector2.new(180, 180),
        Drag = 3,
        Size = numberSequence({ { 0, 0.13 * scale }, { 1, 0 } }),
        LightEmission = 1,
        Brightness = 1.8,
    })
end

local function play(name, position, scale)
    name = name or Config.Style
    local effect, colors = Effects[name], Config.Colors[name]
    if Unloaded or not Config.Enabled or not effect or not colors then return false end
    effect(position, colors, (scale or 1) * Config.Scale)
    return true
end

local function main()
    loadTextures()
    Container = create("Folder", { Name = "HitEffects", Parent = workspace.CurrentCamera })

    task.spawn(function()
        local index = 0
        while not Unloaded do
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if Config.Demo and root then
                index = index % #Config.DemoEffects + 1
                local ok, err = pcall(play, Config.DemoEffects[index], root.CFrame * Vector3.new(0, 1, -Config.DemoDistance))
                if not ok then
                    warn(`[HitEffects] {err}`)
                end
            end
            task.wait(Config.DemoInterval)
        end
    end)

    local Restores = {}
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
    local function entryHealth(entry)
        if not entry then
            return nil
        end
        if entry.getHealth then
            local ok, hp = pcall(entry.getHealth, entry)
            if ok and type(hp) == "number" then
                return hp
            end
        end
        if type(entry._health) == "number" then
            return entry._health
        end
        return nil
    end
    local function playIfDamaged(player, position, hpBefore)
        if not (Config.Enabled and Config.OnDamage) then
            return
        end
        if typeof(position) ~= "Vector3" then
            return
        end
        local modules = env._TapologyModules
        local rep = modules and modules.ReplicationInterface
        local entry = player and rep and rep.getEntry and rep.getEntry(player)
        local before = typeof(hpBefore) == "number" and hpBefore or entryHealth(entry) or 100
        task.delay(0.18, function()
            if Unloaded or not (Config.Enabled and Config.OnDamage) then
                return
            end
            entry = player and rep and rep.getEntry and rep.getEntry(player) or entry
            local after = entryHealth(entry)
            local damaged = typeof(after) == "number" and after < before - 0.25
            local dead = entry and (entry._alive == false or (typeof(after) == "number" and after <= 0))
            if damaged or dead then
                play(Config.Style, position, Config.Scale)
            end
        end)
    end
    local okModules, modules = pcall(findModules)
    modules = okModules and modules or nil
    if modules then
        env._TapologyModules = modules
    end
    if modules and modules.NetworkClient and type(modules.NetworkClient.send) == "function" then
        local network = modules.NetworkClient
        local send = network.send
        network.send = function(self, name, ...)
            if Config.Enabled and Config.OnDamage and name == "bullethit" then
                local _, player, position = ...
                if player and typeof(position) == "Vector3" then
                    local rep = modules.ReplicationInterface
                    local entry = rep and rep.getEntry and rep.getEntry(player)
                    playIfDamaged(player, position, entryHealth(entry))
                end
            end
            return send(self, name, ...)
        end
        table.insert(Restores, function()
            network.send = send
        end)
    end

    local effectNames = {}
    for name in Effects do
        table.insert(effectNames, name)
    end
    table.sort(effectNames)

    env.HitEffects = {
        Config = Config,
        Effects = effectNames,
        EffectDefs = Effects,
        Play = play,

        NotifyDamage = function(position, player, hpBefore)
            if typeof(position) == "Vector3" then
                if player then
                    playIfDamaged(player, position, hpBefore)
                elseif Config.Enabled and Config.OnDamage then
                    play(Config.Style, position, Config.Scale)
                end
            end
        end,
        SetEnabled = function(on)
            Config.Enabled = on and true or false
        end,
        SetStyle = function(name)
            if Effects[name] then
                Config.Style = name
            end
        end,

        SetColor = function(name, slot, color)
            Config.Colors[name] = Config.Colors[name] or {}
            Config.Colors[name][slot] = color
        end,
        Unload = function()
            Unloaded = true
            for _, restore in Restores do
                pcall(restore)
            end
            Container:Destroy()
            env.HitEffects = nil
        end,
    }
end

TextureIds = {
    petal = "rbxassetid://91106269226329",
    dot = "rbxassetid://79451523688005",
    spark = "rbxassetid://83337948032750",
    puff = "rbxassetid://78353513378754",
    pixel = "rbxassetid://98416523570354",
    ring = "rbxassetid://130480777986951",
    sparkle = "rbxassetid://86312741349859",
    flamelet = "rbxassetid://71817844601963",
    flake = "rbxassetid://75489274996945",
    rune = "rbxassetid://131541064840891",
}

do
    local okHit, errHit = pcall(main)
    if not okHit then
        warn("[HitEffects] main failed:", errHit)
    end
end

end
