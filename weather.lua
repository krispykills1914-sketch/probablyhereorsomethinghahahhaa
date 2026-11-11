do

local warn = function() end

local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService = cloneref(game:GetService("HttpService"))
local Lighting = cloneref(game:GetService("Lighting"))

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local Config = {
    Radius = 90,
    Height = 26,
    Heights = {
        Snow = 26,
        Stars = 22,
        Rain = 30,
        Ash = 26,
        Spring = 22,
        Autumn = 24,
        Fireflies = 14,
        Sandstorm = 20,
        Pestilence = 24,
        Bubbles = 18,
    },
    StarDistance = 500,
    Density = 1,
    Wind = Vector3.new(2, 0, 1),
    ChangeEnvironment = true,
    Mode = "Off",
    LastMode = "Snow",
    FadeTime = 2,
    Modifier = Enum.KeyCode.LeftControl,
    CycleKey = Enum.KeyCode.Equals,
    Keys = {
        [Enum.KeyCode.One] = "Snow",
        [Enum.KeyCode.Two] = "Stars",
        [Enum.KeyCode.Three] = "Rain",
        [Enum.KeyCode.Four] = "Ash",
        [Enum.KeyCode.Five] = "Spring",
        [Enum.KeyCode.Six] = "Autumn",
        [Enum.KeyCode.Seven] = "Fireflies",
        [Enum.KeyCode.Eight] = "Sandstorm",
        [Enum.KeyCode.Nine] = "Pestilence",
        [Enum.KeyCode.Minus] = "Bubbles",
        [Enum.KeyCode.Zero] = "Off",
    },

    Colors = {
        Snow = { Flakes = rgb(240, 246, 255), Dust = rgb(235, 242, 255), Mist = rgb(225, 235, 250) },
        Stars = {
            Star1 = rgb(255, 255, 255), Star2 = rgb(170, 210, 255), Star3 = rgb(220, 180, 255),
            Dust = rgb(200, 225, 255), DustFade = rgb(230, 190, 255),
            Comet = rgb(255, 255, 255), CometTail = rgb(170, 200, 255),
            AuroraGreen = rgb(80, 255, 170), AuroraCyan = rgb(90, 220, 255),
            AuroraViolet = rgb(170, 110, 255), AuroraPink = rgb(255, 120, 200),
        },
        Rain = {
            Drops = rgb(205, 220, 240), Veil = rgb(180, 195, 215), Splash = rgb(215, 230, 245),
            Droplets = rgb(220, 232, 245), Mist = rgb(150, 160, 175),
            Lightning = rgb(215, 225, 255), LightningGlow = rgb(200, 215, 255),
        },
        Ash = {
            Ash = rgb(115, 108, 105), EmberHot = rgb(255, 210, 120), EmberMid = rgb(255, 120, 50),
            EmberCool = rgb(200, 40, 20), Mist = rgb(120, 85, 70),
        },
        Spring = {
            Petal1 = rgb(255, 190, 215), Petal2 = rgb(255, 160, 200), Petal3 = rgb(255, 225, 235),
            Pollen = rgb(255, 235, 150),
            Butterfly1 = rgb(255, 170, 210), Butterfly2 = rgb(255, 225, 120), Butterfly3 = rgb(150, 210, 255),
        },
        Autumn = {
            Maple = rgb(235, 120, 40), Red = rgb(200, 55, 35), Oak = rgb(180, 110, 45),
            Birch = rgb(235, 185, 55), Motes = rgb(255, 210, 150),
        },
        Fireflies = {
            Firefly1 = rgb(200, 255, 110), Firefly2 = rgb(255, 235, 100), Firefly3 = rgb(170, 255, 150),
            Stars = rgb(220, 230, 255), Mist = rgb(60, 90, 95),
        },
        Sandstorm = { Sand = rgb(225, 185, 130), Dust = rgb(205, 165, 115), Drift = rgb(215, 175, 120) },
        Pestilence = {
            Flies = rgb(28, 30, 22), Spores = rgb(170, 255, 90), SporeFade = rgb(90, 140, 40),
            Blight = rgb(120, 130, 95), Miasma = rgb(120, 150, 70), Toxic = rgb(150, 210, 60),
        },
        Bubbles = {
            Bubble = rgb(255, 255, 255), Sparkle = rgb(255, 240, 255), Glow = rgb(210, 225, 255),
        },
    },
    TextureFolder = "weather_textures",
    RememberMode = false,
    Hotkeys = false,

    ModeParams = {},
}

local TextureIds

local env = getgenv and getgenv() or _G
if env.Weather then
    env.Weather.Unload()
end

if type(env.WeatherOptions) == "table" then
    for key, value in env.WeatherOptions do
        Config[key] = value
    end
end

local LocalPlayer = Players.LocalPlayer
local base64decode = (crypt and crypt.base64decode) or base64_decode or (base64 and base64.decode)
local SettingsPath = `{Config.TextureFolder}/settings.json`
local rng = Random.new()

local Textures = {}
local Connections = {}
local Modes = {}
local ModeOrder = {}
local Active
local Container, Sky, Column, Volume, Ground, NearSky, NearGround, Dome, Lens

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

local characterInterface
local characterLookupDone = false
local function resolveCharacterInterface()
    if characterInterface or characterLookupDone then
        return characterInterface
    end
    characterLookupDone = true
    if not getgc then
        return nil
    end
    for _, value in getgc(true) do
        if type(value) == "table" and rawget(value, "ScreenCull") and rawget(value, "NetworkClient") then
            local entry = rawget(value, "CharacterInterface")
            local mod = type(entry) == "table" and entry.module ~= nil and entry.module or entry
            if type(mod) == "table" and mod.getCharacterObject then
                characterInterface = mod
                return characterInterface
            end
        end
    end
    for _, value in getgc(true) do
        if type(value) == "table" and rawget(value, "getCharacterObject") and rawget(value, "isAlive") then
            characterInterface = value
            return characterInterface
        end
    end
    return nil
end

local function focusPosition()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.CFrame.Position
    end
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        return root.Position
    end
    local ci = resolveCharacterInterface()
    if ci then
        local ok, object = pcall(ci.getCharacterObject)
        if ok and object and object.getRootPart then
            local okRoot, part = pcall(function()
                return object:getRootPart()
            end)
            if okRoot and part and typeof(part.Position) == "Vector3" then
                return part.Position
            end
        end
    end
    return Vector3.zero
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function isCharacterishHit(inst)
    if not inst then
        return false
    end
    local model = inst:FindFirstAncestorOfClass("Model")
    if not model then
        return false
    end
    if model:FindFirstChildOfClass("Humanoid")
        or model:FindFirstChild("Cosmetics")
        or (model:FindFirstChild("Torso") and model:FindFirstChild("Head"))
        or model:FindFirstChild("HumanoidRootPart")
    then
        return true
    end
    return false
end

local function groundBelow(position, fallback)
    local ignore = { LocalPlayer.Character, Container, workspace.CurrentCamera }
    for _, name in ipairs({ "Ignore", "Players", "Effects", "Temporary", "Rain", "Weather", "Aura" }) do
        local folder = workspace:FindFirstChild(name)
        if folder then
            table.insert(ignore, folder)
        end
    end
    local origin = position + Vector3.new(0, 80, 0)
    local direction = Vector3.new(0, -500, 0)
    for _ = 1, 10 do
        rayParams.FilterDescendantsInstances = ignore
        local hit = workspace:Raycast(origin, direction, rayParams)
        if not hit then
            break
        end
        local inst = hit.Instance
        if isCharacterishHit(inst) then
            local model = inst:FindFirstAncestorOfClass("Model")
            table.insert(ignore, model or inst)
        else
        return hit.Position
    end
    end
    local fallbackY = typeof(fallback) == "number" and fallback or position.Y - 3
    return Vector3.new(position.X, fallbackY, position.Z)
end

local ModeParamDefaults = {
    Snow = { Radius = 90, Density = 1, Wind = 1, Size = 1, Height = 26 },
    Stars = { Radius = 70, Density = 0.7, Wind = 0.35, Size = 1, Height = 22, StarDistance = 280, CometRate = 0.55 },
    Rain = { Radius = 90, Density = 1, Wind = 1, Size = 1, Height = 30 },
    Ash = { Radius = 90, Density = 1, Wind = 1.2, Size = 1, Height = 26 },
    Spring = { Radius = 90, Density = 1, Wind = 0.8, Size = 1, Height = 22 },
    Autumn = { Radius = 90, Density = 1, Wind = 1.1, Size = 1, Height = 24 },
    Fireflies = { Radius = 70, Density = 1, Wind = 0.25, Size = 1, Height = 14 },
    Sandstorm = { Radius = 110, Density = 1.2, Wind = 2.2, Size = 1, Height = 20 },
    Pestilence = { Radius = 90, Density = 1, Wind = 0.7, Size = 1, Height = 24 },
    Bubbles = { Radius = 80, Density = 1, Wind = 0.5, Size = 1, Height = 18 },
}
for name, defaults in ModeParamDefaults do
    local copy = {}
    for key, value in defaults do
        copy[key] = value
    end
    Config.ModeParams[name] = copy
end

local function modeParams(name)
    return Config.ModeParams[name] or ModeParamDefaults[name]
end

local function paramOf(name, key, fallback)
    local params = modeParams(name)
    local value = params and params[key]
    if value == nil then
        return fallback
    end
    return value
end

local function activeRadius(name)
    return paramOf(name or (Active and Active.Name), "Radius", Config.Radius)
end

local function rateScale(name)
    local density = paramOf(name or (Active and Active.Name), "Density", Config.Density)
    local area = (activeRadius(name) / 90) ^ 2
    return math.clamp(density, 0.15, 1.25) * math.clamp(area, 0.25, 1.35) * 0.45
end

local function modeHeight(name)
    return paramOf(name, "Height", Config.Heights[name] or Config.Height)
end

local function modeStarDistance(name)
    return paramOf(name or "Stars", "StarDistance", Config.StarDistance)
end

local function modeWindScale(name)
    return paramOf(name or (Active and Active.Name), "Wind", 1)
end

local function windDirection(name)
    local flat = Config.Wind * modeWindScale(name) * Vector3.new(1, 0, 1)
    return flat.Magnitude > 1e-3 and flat.Unit or Vector3.xAxis
end

local function modeSizeScale(name)
    return paramOf(name or (Active and Active.Name), "Size", 1)
end

local function scaleSequence(sequence, mul)
    if mul == 1 or typeof(sequence) ~= "NumberSequence" then
        return sequence
    end
    local keypoints = {}
    for _, keypoint in sequence.Keypoints do
        table.insert(keypoints, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * mul, keypoint.Envelope * mul))
    end
    return NumberSequence.new(keypoints)
end

local EnvironmentProps = {
    Lighting = { "ClockTime", "Brightness", "Ambient", "OutdoorAmbient", "ExposureCompensation" },
    Atmosphere = { "Density", "Offset", "Color", "Decay", "Glare", "Haze" },
    Clouds = { "Cover", "Density", "Color" },
    Grade = { "TintColor", "Saturation", "Contrast", "Brightness" },
    Bloom = { "Intensity", "Size", "Threshold" },
    SunRays = { "Intensity", "Spread" },
}

local Environment = { Targets = {}, Original = {}, Created = {} }

local function captureEnvironment()
    local targets = Environment.Targets
    targets.Lighting = Lighting

    targets.Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not targets.Atmosphere then
        targets.Atmosphere = create("Atmosphere", { Density = 0, Haze = 0, Glare = 0, Parent = Lighting })
        table.insert(Environment.Created, targets.Atmosphere)
    end

    targets.Clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
    if not targets.Clouds then
        targets.Clouds = create("Clouds", { Cover = 0, Density = 0, Parent = workspace.Terrain })
        table.insert(Environment.Created, targets.Clouds)
    end

    targets.Grade = create("ColorCorrectionEffect", { Name = "WeatherGrade", Parent = Lighting })
    targets.Bloom = create("BloomEffect", { Name = "WeatherBloom", Intensity = 0, Size = 24, Threshold = 2, Parent = Lighting })
    targets.SunRays = create("SunRaysEffect", { Name = "WeatherSunRays", Intensity = 0, Spread = 1, Parent = Lighting })
    for _, key in { "Grade", "Bloom", "SunRays" } do
        table.insert(Environment.Created, targets[key])
    end

    for group, props in EnvironmentProps do
        Environment.Original[group] = {}
        for _, prop in props do
            Environment.Original[group][prop] = targets[group][prop]
        end
    end
end

local function applyEnvironment(preset, instant)
    for group, props in EnvironmentProps do
        local values = {}
        for _, prop in props do
            local value = preset and preset[group] and preset[group][prop]
            if value == nil or not Config.ChangeEnvironment and group ~= "Grade" then
                value = Environment.Original[group][prop]
            end
            values[prop] = value
        end

        local target = Environment.Targets[group]
        if instant then
            for prop, value in values do
                target[prop] = value
            end
        else
            TweenService:Create(target, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Sine), values):Play()
        end
    end
end

local function restoreEnvironment()
    applyEnvironment(nil, true)
    for _, instance in Environment.Created do
        instance:Destroy()
    end
end

local function mode(name, environment, build)
    Modes[name] = { Name = name, Environment = environment, Build = build }
    table.insert(ModeOrder, name)
end

local twinkle = numberSequence({ { 0, 0 }, { 0.15, 1 }, { 0.3, 0.4 }, { 0.5, 1 }, { 0.7, 0.3 }, { 0.85, 0.9 }, { 1, 0 } })
local blink = numberSequence({
    { 0, 0 }, { 0.08, 1 }, { 0.16, 0.1 }, { 0.32, 0.1 }, { 0.4, 1 }, { 0.48, 0.1 },
    { 0.64, 0.1 }, { 0.72, 1 }, { 0.8, 0.1 }, { 1, 0 },
})
local flutter = numberSequence({ { 0, 0 }, { 0.2, 0.6 }, { 0.4, -0.5 }, { 0.6, 0.6 }, { 0.8, -0.5 }, { 1, 0 } })

local function scaled(sequence, size)
    local keypoints = {}
    for _, keypoint in sequence.Keypoints do
        table.insert(keypoints, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * size))
    end
    return NumberSequence.new(keypoints)
end

local function popSize(size)
    return numberSequence({ { 0, 0 }, { 0.06, size }, { 0.9, size * 1.05 }, { 0.96, size * 1.3 }, { 1, size * 1.45 } })
end
local popTransparency = numberSequence({ { 0, 1 }, { 0.06, 0 }, { 0.9, 0 }, { 0.96, 0.45 }, { 1, 1 } })

local function nearField(m, opts)
    opts = opts or {}
    local texture = opts.Texture or Textures.soft
    local color = opts.Color or Color3.new(1, 1, 1)
    local hazeColor = opts.HazeColor or color
    local rate = opts.Rate or 55
    local size = opts.Size or 0.28
    local transparency = opts.Transparency or 0.35
    local wind = opts.Wind or 0.8

    m.Emit(NearGround, {
        Texture = texture,
        EmissionDirection = Enum.NormalId.Top,
        Rate = rate,
        Lifetime = NumberRange.new(1.1, 1.8),
        Speed = NumberRange.new(1.2, 3.2),
        SpreadAngle = Vector2.new(55, 55),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-40, 40),
        Size = NumberSequence.new(size),
        Transparency = numberSequence({ { 0, 1 }, { 0.12, transparency }, { 0.85, transparency + 0.15 }, { 1, 1 } }),
        Color = ColorSequence.new(color),
        LightEmission = opts.LightEmission or 0.15,
        LightInfluence = opts.LightInfluence or 0.55,
        Brightness = opts.Brightness or 1.2,
    }, wind)

    m.Emit(Lens, {
        Texture = texture,
        EmissionDirection = Enum.NormalId.Front,
        Rate = math.max(12, math.floor(rate * 0.45)),
        Lifetime = NumberRange.new(0.7, 1.3),
        Speed = NumberRange.new(1.5, 4),
        SpreadAngle = Vector2.new(70, 70),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-50, 50),
        Size = NumberSequence.new(size * 1.15),
        Transparency = numberSequence({ { 0, 1 }, { 0.15, transparency + 0.05 }, { 0.85, transparency + 0.2 }, { 1, 1 } }),
        Color = ColorSequence.new(color),
        LightEmission = opts.LightEmission or 0.2,
        LightInfluence = opts.LightInfluence or 0.45,
        Brightness = opts.Brightness or 1.3,
    }, wind)

    if opts.Haze ~= false then
        m.Emit(NearGround, {
            Texture = Textures.haze,
            EmissionDirection = Enum.NormalId.Top,
            Rate = opts.HazeRate or 10,
            Lifetime = NumberRange.new(2.5, 4),
            Speed = NumberRange.new(0.3, 0.9),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-8, 8),
            Size = numberSequence({ { 0, 6 }, { 1, 12 } }),
            Transparency = numberSequence({ { 0, 1 }, { 0.2, 0.78 }, { 0.8, 0.82 }, { 1, 1 } }),
            Color = ColorSequence.new(hazeColor),
            LightEmission = 0,
            LightInfluence = 0.7,
        }, wind * 0.5)
    end
end

local function groundMist(m, color, transparency, rate)
    m.Emit(Ground, {
        Texture = Textures.haze,
        EmissionDirection = Enum.NormalId.Top,
        Rate = rate or 8,
        Lifetime = NumberRange.new(7, 10),
        Speed = NumberRange.new(0.2, 0.6),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-6, 6),
        Size = numberSequence({ { 0, 10 }, { 1, 18 } }),
        Transparency = numberSequence({ { 0, 1 }, { 0.3, transparency }, { 0.7, transparency }, { 1, 1 } }),
        Color = ColorSequence.new(color),
        LightEmission = 0,
        LightInfluence = 0.8,
    }, 0.4)
end

local function starDome(m, rate, brightness, colors)
    local distance = modeStarDistance(m.Name)
    local scale = math.clamp(distance / 220, 0.45, 1.1)

    Dome.Size = Vector3.one * distance * 2
    for _, color in colors do
        local emitter = m.Emit(Dome, {
            Texture = Textures.star,
            LockedToPart = true,
            Shape = Enum.ParticleEmitterShape.Sphere,
            ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
            Rate = math.min(rate, 28),
            Lifetime = NumberRange.new(5, 9),
            Speed = NumberRange.new(0),
            Rotation = NumberRange.new(0, 90),
            Size = scaled(twinkle, rng:NextNumber(2.2, 3.0) * scale),
            Color = ColorSequence.new(color),
            LightEmission = 1,
            LightInfluence = 0,
            Brightness = math.min(brightness, 2.2),
        })
        emitter:Emit(math.min(math.floor(emitter.Rate * 1.5), 24))
    end
end

local function falling(fall, drag)
    return Vector3.new(0, -fall, 0), drag
end

mode("Snow", {
    Lighting = { ClockTime = 13.5, Brightness = 1.6, Ambient = rgb(120, 125, 135), OutdoorAmbient = rgb(150, 160, 175), ExposureCompensation = 0.15 },
    Atmosphere = { Density = 0.42, Offset = 0.15, Color = rgb(205, 215, 230), Decay = rgb(160, 175, 200), Glare = 0, Haze = 2.4 },
    Clouds = { Cover = 0.85, Density = 0.55, Color = rgb(225, 230, 240) },
    Grade = { TintColor = rgb(230, 238, 255), Saturation = -0.2, Contrast = 0.05, Brightness = 0.02 },
    Bloom = { Intensity = 0.4, Size = 30, Threshold = 1.6 },
}, function(m)
    local gravity, drag = falling(0.7, 0.2)
    for i = 1, 3 do
        m.Emit(Sky, {
            Texture = Textures[`flake{i}`],
            EmissionDirection = Enum.NormalId.Bottom,
            Rate = 70,
            Lifetime = m.Fall(2.6, 3.5),
            Speed = NumberRange.new(2.6, 3.5),
            Acceleration = gravity,
            Drag = drag,
            SpreadAngle = Vector2.new(15, 15),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-40, 40),
            Size = NumberSequence.new(0.35 + i * 0.08),
            Transparency = numberSequence({ { 0, 1 }, { 0.05, 0.1 }, { 0.9, 0.2 }, { 1, 1 } }),
            Color = ColorSequence.new(m.C("Flakes")),
            LightEmission = 0.4,
            LightInfluence = 0.15,
            Brightness = 1.6,
        }, 1)
    end
    m.Emit(Sky, {
        Texture = Textures.soft,
        EmissionDirection = Enum.NormalId.Bottom,
        Rate = 450,
        Lifetime = m.Fall(3, 4),
        Speed = NumberRange.new(3, 4),
        Acceleration = Vector3.new(0, -0.8, 0),
        Drag = 0.2,
        SpreadAngle = Vector2.new(10, 10),
        Size = NumberSequence.new(0.14),
        Transparency = numberSequence({ { 0, 1 }, { 0.05, 0.25 }, { 0.9, 0.35 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Dust")),
        LightEmission = 0.3,
        LightInfluence = 0.15,
        Brightness = 1.4,
    }, 1.2)

    m.Emit(Lens, {
        Texture = Textures.soft,
        EmissionDirection = Enum.NormalId.Bottom,
        Rate = 35,
        Lifetime = NumberRange.new(5, 7),
        Speed = NumberRange.new(1.5, 2.5),
        SpreadAngle = Vector2.new(20, 20),
        Size = NumberSequence.new(0.4),
        Transparency = numberSequence({ { 0, 1 }, { 0.15, 0.45 }, { 0.85, 0.5 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Flakes")),
        LightEmission = 0.3,
        LightInfluence = 0.2,
        Brightness = 1.2,
    }, 1)
    nearField(m, {
        Texture = Textures.flake1,
        Color = m.C("Flakes"),
        HazeColor = m.C("Mist"),
        Rate = 70,
        Size = 0.32,
        Transparency = 0.28,
        Wind = 1,
    })
    groundMist(m, m.C("Mist"), 0.85, 6)
end)

mode("Stars", {
    Lighting = { ClockTime = 0.3, Brightness = 1, Ambient = rgb(70, 72, 110), OutdoorAmbient = rgb(90, 95, 140), ExposureCompensation = 0.35 },
    Atmosphere = { Density = 0.1, Offset = 0, Color = rgb(80, 90, 140), Decay = rgb(40, 40, 80), Glare = 0, Haze = 0.3 },
    Clouds = { Cover = 0.15, Density = 0.1, Color = rgb(90, 95, 130) },
    Grade = { TintColor = rgb(225, 225, 255), Saturation = 0.15, Contrast = 0.06, Brightness = 0.03 },
    Bloom = { Intensity = 0.35, Size = 18, Threshold = 1.15 },
}, function(m)
    starDome(m, 24, 2.2, { m.C("Star1"), m.C("Star2"), m.C("Star3") })
    m.Emit(Volume, {
        Texture = Textures.star,
        EmissionDirection = Enum.NormalId.Bottom,
        Rate = 28,
        Lifetime = NumberRange.new(6, 10),
        Speed = NumberRange.new(0.4, 1.4),
        SpreadAngle = Vector2.new(30, 30),
        RotSpeed = NumberRange.new(-30, 30),
        Size = scaled(twinkle, 0.55),
        Color = colorSequence({ { 0, m.C("Dust") }, { 1, m.C("DustFade") } }),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 2,
    }, 0.4)

    local auroraAnchor = newPart("Aurora", Vector3.one, m.Folder)
    local radius = modeStarDistance(m.Name) * 0.55
    local span = math.rad(50)
    local green, cyan, violet = m.C("AuroraGreen"), m.C("AuroraCyan"), m.C("AuroraViolet")
    local palettes = {
        { green, cyan, green },
        { cyan, violet, cyan },
    }
    local curtains = {}
    for i, colors in palettes do
        local start = (i - 1) / #palettes * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
        local height = rng:NextNumber(55, 95)
        local function ringPoint(angle, y)
            return Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
        end
        local function tangent(angle)
            return Vector3.new(-math.sin(angle), 0, math.cos(angle))
        end
        local a0 = create("Attachment", { Position = ringPoint(start, height), Axis = tangent(start), Parent = auroraAnchor })
        local a1 = create("Attachment", { Position = ringPoint(start + span, height + rng:NextNumber(-12, 12)), Axis = tangent(start + span), Parent = auroraAnchor })
        local width = rng:NextNumber(48, 72)
        local beam = create("Beam", {
            Attachment0 = a0,
            Attachment1 = a1,
            Texture = Textures.aurora,
            TextureMode = Enum.TextureMode.Wrap,
            TextureLength = 140,
            TextureSpeed = rng:NextNumber(0.12, 0.28) * (rng:NextNumber() < 0.5 and -1 or 1),
            Width0 = width,
            Width1 = width * rng:NextNumber(0.75, 1.05),
            Segments = 8,
            FaceCamera = true,
            Color = colorSequence({ { 0, colors[1] }, { 0.5, colors[2] }, { 1, colors[3] } }),
            Transparency = numberSequence({ { 0, 1 }, { 0.2, 0.35 }, { 0.8, 0.35 }, { 1, 1 } }),
            LightEmission = 1,
            LightInfluence = 0,
            Brightness = 1.4,
            Parent = auroraAnchor,
        })

        local handle = radius * 4 / 3 * math.tan(span / 4)
        curtains[i] = { Beam = beam, Handle = handle, Phase = i * 1.3 }
    end

    local comets, nextAt, lastAurora = {}, 0, 0
    m.Update = function(t, dt)
        auroraAnchor.CFrame = CFrame.new(focusPosition())
        if t - lastAurora >= 0.12 then
            lastAurora = t
            for _, curtain in curtains do
                curtain.Beam.CurveSize0 = curtain.Handle * (1 + 0.25 * math.sin(t * 0.17 + curtain.Phase))
                curtain.Beam.CurveSize1 = curtain.Handle * (1 + 0.25 * math.cos(t * 0.13 + curtain.Phase))
            end
        end

        if t >= nextAt and #comets < 2 then
            local cometRate = math.max(paramOf(m.Name, "CometRate", 1), 0.1)
            nextAt = t + rng:NextNumber(2.2, 4.8) / cometRate
            local center = focusPosition()
            local area = activeRadius(m.Name)
            local angle = rng:NextNumber(0, math.pi * 2)
            local direction = Vector3.new(math.cos(angle), rng:NextNumber(-0.35, -0.15), math.sin(angle)).Unit
            local start = center + Vector3.new(rng:NextNumber(-area, area), m.Height + rng:NextNumber(30, 60), rng:NextNumber(-area, area))
                - direction * 40

            local part = newPart("ShootingStar", Vector3.new(0.2, 0.2, 0.2), m.Folder)
            part.CFrame = CFrame.new(start)
            local a0 = create("Attachment", { Position = Vector3.new(0, 0.35, 0), Parent = part })
            local a1 = create("Attachment", { Position = Vector3.new(0, -0.35, 0), Parent = part })
            create("Trail", {
                Attachment0 = a0,
                Attachment1 = a1,
                Texture = Textures.streak,
                TextureMode = Enum.TextureMode.Stretch,
                Lifetime = 0.3,
                FaceCamera = true,
                WidthScale = numberSequence({ { 0, 1 }, { 1, 0 } }),
                Transparency = numberSequence({ { 0, 0 }, { 1, 1 } }),
                Color = colorSequence({ { 0, m.C("Comet") }, { 1, m.C("CometTail") } }),
                LightEmission = 1,
                LightInfluence = 0,
                Brightness = 2.2,
                MaxLength = 60,
                Parent = part,
            })
            table.insert(comets, { Part = part, Velocity = direction * rng:NextNumber(70, 110), Born = t })
        end

        for i = #comets, 1, -1 do
            local comet = comets[i]
            if t - comet.Born > 1.2 then
                comet.Part:Destroy()
                table.remove(comets, i)
            else
                comet.Part.CFrame += comet.Velocity * dt
            end
        end
    end

    nearField(m, {
        Texture = Textures.star,
        Color = m.C("Dust"),
        HazeColor = m.C("DustFade"),
        Rate = 40,
        Size = 0.2,
        Transparency = 0.25,
        Wind = 0.25,
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 4,
        HazeRate = 4,
    })
end)

local function boltPath(from, to, segments, jitter)
    local points = { from }
    for i = 1, segments - 1 do
        local alpha = i / segments
        local offset = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.3, 0.3), rng:NextNumber(-1, 1))
        table.insert(points, from:Lerp(to, alpha) + offset * jitter * (0.4 + math.sin(alpha * math.pi)))
    end
    table.insert(points, to)
    return points
end

local function boltSegments(folder, points, width, color, parts)
    for i = 1, #points - 1 do
        local a, b = points[i], points[i + 1]
        table.insert(parts, create("Part", {
            Name = "Bolt",
            Anchored = true,
            CanCollide = false,
            CanQuery = false,
            CanTouch = false,
            CastShadow = false,
            Material = Enum.Material.Neon,
            Color = color,
            Size = Vector3.new(width, width, (b - a).Magnitude + width * 0.5),
            CFrame = CFrame.lookAt((a + b) / 2, b),
            Parent = folder,
        }))
    end
end

local function strike(m)
    local center = focusPosition()
    local angle = rng:NextNumber(0, math.pi * 2)
    local distance = rng:NextNumber(30, activeRadius(m.Name) * 0.9)
    local impact = groundBelow(center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * distance, center.Y - 3)
    local top = impact + Vector3.new(rng:NextNumber(-25, 25), 160, rng:NextNumber(-25, 25))

    local folder = create("Folder", { Name = "Strike", Parent = m.Folder })
    local parts = {}
    local color = m.C("Lightning")
    local main = boltPath(top, impact, 22, 10)
    boltSegments(folder, main, 0.55, color, parts)
    for _ = 1, rng:NextInteger(3, 6) do
        local index = rng:NextInteger(3, 14)
        local origin = main[index]
        local direction = ((main[index + 1] - origin).Unit + Vector3.new(rng:NextNumber(-1, 1), -0.4, rng:NextNumber(-1, 1))).Unit
        boltSegments(folder, boltPath(origin, origin + direction * rng:NextNumber(15, 40), 8, 4), 0.25, color, parts)
    end

    local light = create("PointLight", { Color = m.C("LightningGlow"), Range = 60, Brightness = 0, Shadows = true, Parent = parts[#main - 1] })
    local grade = Environment.Targets.Grade
    local baseBrightness = m.Environment.Grade.Brightness

    task.spawn(function()
        for _, step in { { 0, 0.05 }, { 1, 0.06 }, { 0, 0.12 } } do
            for _, part in parts do
                part.Transparency = step[1]
            end
            light.Brightness = step[1] == 0 and 10 or 0
            grade.Brightness = baseBrightness + (step[1] == 0 and 0.45 or 0.1)
            task.wait(step[2])
        end
        local start = os.clock()
        while os.clock() - start < 0.35 do
            local p = (os.clock() - start) / 0.35
            for _, part in parts do
                part.Transparency = p
            end
            light.Brightness = 10 * (1 - p)
            grade.Brightness = baseBrightness + 0.45 * (1 - p) ^ 2
            task.wait()
        end
        grade.Brightness = baseBrightness
        folder:Destroy()
    end)
end

mode("Rain", {
    Lighting = { ClockTime = 17.2, Brightness = 0.9, Ambient = rgb(70, 75, 85), OutdoorAmbient = rgb(85, 92, 105), ExposureCompensation = -0.1 },
    Atmosphere = { Density = 0.5, Offset = 0.2, Color = rgb(125, 135, 150), Decay = rgb(70, 80, 95), Glare = 0, Haze = 3 },
    Clouds = { Cover = 0.97, Density = 0.95, Color = rgb(70, 75, 85) },
    Grade = { TintColor = rgb(205, 215, 235), Saturation = -0.3, Contrast = 0.08, Brightness = -0.02 },
    Bloom = { Intensity = 0.5, Size = 30, Threshold = 1.3 },
}, function(m)
    local speed = 38

    local function rain(parent, rate, height, size, transparency)
        m.Emit(parent, {
            Texture = Textures.raindrop,
            Orientation = Enum.ParticleOrientation.VelocityParallel,
            EmissionDirection = Enum.NormalId.Bottom,
            Rate = rate,
            Lifetime = NumberRange.new(height / speed, height / speed * 1.05),
            Speed = NumberRange.new(speed * 0.95, speed),
            SpreadAngle = Vector2.zero,
            Size = NumberSequence.new(size),
            Transparency = NumberSequence.new(transparency),
            Color = ColorSequence.new(m.C("Drops")),
            LightEmission = 0.4,
            LightInfluence = 0.3,
            Brightness = 1.8,
        })
    end

    rain(Sky, 700, m.Height, 1.6, 0.4)
    rain(Sky, 350, m.Height, 2.2, 0.5)
    rain(NearSky, 650, m.Height, 1.5, 0.35)
    rain(Lens, 180, Lens.Size.Y, 0.8, 0.6)

    m.Emit(Sky, {
        Texture = Textures.rainsheet,
        Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
        EmissionDirection = Enum.NormalId.Bottom,
        Rate = 5,
        Lifetime = NumberRange.new(m.Height / 16, m.Height / 14),
        Speed = NumberRange.new(14, 16),
        Size = NumberSequence.new(m.Height * 0.9),
        Transparency = numberSequence({ { 0, 1 }, { 0.2, 0.82 }, { 0.8, 0.82 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Veil")),
        LightEmission = 0.1,
        LightInfluence = 0.6,
    })

    m.Emit(NearGround, {
        Texture = Textures.splash,
        FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2,
        FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
        Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
        EmissionDirection = Enum.NormalId.Top,
        Rate = 140,
        Lifetime = NumberRange.new(0.35, 0.45),
        Speed = NumberRange.new(0.01),
        Size = NumberSequence.new(0.7),
        Transparency = numberSequence({ { 0, 0.45 }, { 1, 0.85 } }),
        Color = ColorSequence.new(m.C("Splash")),
        LightEmission = 0.3,
        LightInfluence = 0.4,
        Brightness = 1.5,
    })
    m.Emit(NearGround, {
        Texture = Textures.soft,
        EmissionDirection = Enum.NormalId.Top,
        Rate = 220,
        Lifetime = NumberRange.new(0.2, 0.32),
        Speed = NumberRange.new(3, 6),
        SpreadAngle = Vector2.new(35, 35),
        Acceleration = Vector3.new(0, -45, 0),
        Size = numberSequence({ { 0, 0.07 }, { 1, 0.04 } }),
        Transparency = numberSequence({ { 0, 0.3 }, { 1, 0.8 } }),
        Color = ColorSequence.new(m.C("Droplets")),
        LightEmission = 0.4,
        LightInfluence = 0.4,
        Brightness = 1.6,
    })
    nearField(m, {
        Texture = Textures.raindrop,
        Color = m.C("Drops"),
        HazeColor = m.C("Mist"),
        Rate = 90,
        Size = 0.22,
        Transparency = 0.4,
        Wind = 0.2,
        LightEmission = 0.35,
    })
    groundMist(m, m.C("Mist"), 0.82, 10)

    local nextStrike = rng:NextNumber(3, 6)
    m.Update = function(t)
        if t >= nextStrike then
            nextStrike = t + rng:NextNumber(5, 12)
            strike(m)
            if rng:NextNumber() < 0.35 then
                task.delay(rng:NextNumber(0.3, 0.8), strike, m)
            end
        end
    end
end)

mode("Ash", {
    Lighting = { ClockTime = 18.1, Brightness = 1.2, Ambient = rgb(95, 65, 55), OutdoorAmbient = rgb(120, 80, 60), ExposureCompensation = 0 },
    Atmosphere = { Density = 0.55, Offset = 0.25, Color = rgb(170, 100, 65), Decay = rgb(100, 40, 25), Glare = 1.5, Haze = 2.8 },
    Clouds = { Cover = 0.85, Density = 0.8, Color = rgb(95, 60, 50) },
    Grade = { TintColor = rgb(255, 215, 190), Saturation = -0.15, Contrast = 0.12, Brightness = -0.02 },
    Bloom = { Intensity = 0.8, Size = 35, Threshold = 1.1 },
    SunRays = { Intensity = 0.12, Spread = 0.6 },
}, function(m)
    local gravity, drag = falling(0.75, 0.3)
    for i = 1, 3 do
        m.Emit(Sky, {
            Texture = Textures[`ash{i}`],
            EmissionDirection = Enum.NormalId.Bottom,
            Rate = 80,
            Lifetime = m.Fall(1.9, 2.5),
            Speed = NumberRange.new(2, 2.5),
            Acceleration = gravity,
            Drag = drag,
            SpreadAngle = Vector2.new(25, 25),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-90, 90),
            Squash = flutter,
            Size = NumberSequence.new(0.25 + i * 0.07),
            Transparency = numberSequence({ { 0, 1 }, { 0.05, 0.1 }, { 0.9, 0.2 }, { 1, 1 } }),
            Color = ColorSequence.new(m.C("Ash")),
            LightEmission = 0,
            LightInfluence = 1,
        }, 1.5)
    end
    m.Emit(Ground, {
        Texture = Textures.ember,
        EmissionDirection = Enum.NormalId.Top,
        Rate = 90,
        Lifetime = NumberRange.new(3, 6),
        Speed = NumberRange.new(2, 5),
        SpreadAngle = Vector2.new(25, 25),
        Acceleration = Vector3.new(0, 1.5, 0),
        Size = numberSequence({ { 0, 0.18 }, { 0.6, 0.12 }, { 1, 0 } }),
        Transparency = numberSequence({ { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } }),
        Color = colorSequence({ { 0, m.C("EmberHot") }, { 0.5, m.C("EmberMid") }, { 1, m.C("EmberCool") } }),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 5,
    }, 1)
    m.Emit(Lens, {
        Texture = Textures.ash1,
        EmissionDirection = Enum.NormalId.Bottom,
        Rate = 12,
        Lifetime = NumberRange.new(5, 7),
        Speed = NumberRange.new(1, 2),
        SpreadAngle = Vector2.new(30, 30),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-90, 90),
        Size = NumberSequence.new(0.5),
        Transparency = numberSequence({ { 0, 1 }, { 0.15, 0.3 }, { 0.85, 0.35 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Ash"):Lerp(Color3.new(0, 0, 0), 0.2)),
        LightEmission = 0,
        LightInfluence = 1,
    }, 1.5)
    nearField(m, {
        Texture = Textures.ash1,
        Color = m.C("Ash"),
        HazeColor = m.C("Mist"),
        Rate = 65,
        Size = 0.26,
        Transparency = 0.3,
        Wind = 1.4,
        LightEmission = 0.05,
    })
    groundMist(m, m.C("Mist"), 0.8, 8)
end)

mode("Spring", {
    Lighting = { ClockTime = 9.2, Brightness = 2.4, Ambient = rgb(130, 120, 125), OutdoorAmbient = rgb(165, 155, 160), ExposureCompensation = 0.2 },
    Atmosphere = { Density = 0.3, Offset = 0.1, Color = rgb(255, 230, 235), Decay = rgb(205, 185, 220), Glare = 0.6, Haze = 1.6 },
    Clouds = { Cover = 0.5, Density = 0.3, Color = rgb(255, 250, 250) },
    Grade = { TintColor = rgb(255, 245, 242), Saturation = 0.18, Contrast = 0.04, Brightness = 0.02 },
    Bloom = { Intensity = 0.6, Size = 40, Threshold = 1.2 },
    SunRays = { Intensity = 0.15, Spread = 0.5 },
}, function(m)
    local gravity, drag = falling(0.9, 0.3)
    for i = 1, 3 do
        m.Emit(Sky, {
            Texture = Textures[`petal{i}`],
            EmissionDirection = Enum.NormalId.Bottom,
            Rate = 50,
            Lifetime = m.Fall(2.3, 3),
            Speed = NumberRange.new(2.3, 3),
            Acceleration = gravity,
            Drag = drag,
            SpreadAngle = Vector2.new(30, 30),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-120, 120),
            Squash = flutter,
            Size = NumberSequence.new(0.35 + i * 0.05),
            Transparency = numberSequence({ { 0, 1 }, { 0.05, 0 }, { 0.92, 0.1 }, { 1, 1 } }),
            Color = ColorSequence.new(m.C(`Petal{i}`)),
            LightEmission = 0.2,
            LightInfluence = 0.3,
            Brightness = 1.4,
        }, 2.5)
    end
    m.Emit(Volume, {
        Texture = Textures.soft,
        Rate = 70,
        Lifetime = NumberRange.new(5, 8),
        Speed = NumberRange.new(0.2, 0.6),
        SpreadAngle = Vector2.new(180, 180),
        Size = scaled(twinkle, 0.18),
        Color = ColorSequence.new(m.C("Pollen")),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 2.5,
    }, 0.6)
    for i = 1, 3 do
        m.Emit(Volume, {
            Texture = Textures.butterfly,
            FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2,
            FlipbookMode = Enum.ParticleFlipbookMode.Loop,
            FlipbookFramerate = NumberRange.new(10, 16),
            FlipbookStartRandom = true,
            Rate = 2,
            Lifetime = NumberRange.new(8, 12),
            Speed = NumberRange.new(1.5, 3),
            SpreadAngle = Vector2.new(180, 180),
            Rotation = NumberRange.new(-25, 25),
            Size = numberSequence({ { 0, 0 }, { 0.05, 0.7 }, { 0.95, 0.7 }, { 1, 0 } }),
            Color = ColorSequence.new(m.C(`Butterfly{i}`)),
            LightEmission = 0.3,
            LightInfluence = 0.3,
            Brightness = 1.5,
        }, 0.3)
    end
    m.Emit(Lens, {
        Texture = Textures.petal1,
        EmissionDirection = Enum.NormalId.Bottom,
        Rate = 6,
        Lifetime = NumberRange.new(5, 7),
        Speed = NumberRange.new(1.5, 2.5),
        SpreadAngle = Vector2.new(30, 30),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-120, 120),
        Squash = flutter,
        Size = NumberSequence.new(0.5),
        Transparency = numberSequence({ { 0, 1 }, { 0.15, 0.2 }, { 0.85, 0.25 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Petal1")),
        LightEmission = 0.2,
        LightInfluence = 0.3,
        Brightness = 1.4,
    }, 2.5)
    nearField(m, {
        Texture = Textures.petal1,
        Color = m.C("Petal1"),
        HazeColor = m.C("Pollen"),
        Rate = 55,
        Size = 0.3,
        Transparency = 0.25,
        Wind = 0.9,
    })
end)

mode("Autumn", {
    Lighting = { ClockTime = 16.4, Brightness = 2, Ambient = rgb(125, 105, 90), OutdoorAmbient = rgb(160, 130, 105), ExposureCompensation = 0.1 },
    Atmosphere = { Density = 0.32, Offset = 0.1, Color = rgb(230, 190, 150), Decay = rgb(170, 120, 90), Glare = 0.8, Haze = 1.8 },
    Clouds = { Cover = 0.55, Density = 0.35, Color = rgb(255, 235, 215) },
    Grade = { TintColor = rgb(255, 238, 220), Saturation = 0.12, Contrast = 0.06, Brightness = 0.01 },
    Bloom = { Intensity = 0.5, Size = 35, Threshold = 1.3 },
    SunRays = { Intensity = 0.13, Spread = 0.6 },
}, function(m)
    local gravity, drag = falling(1, 0.35)
    local leaves = {
        { Texture = Textures.maple, Color = m.C("Maple"), Size = 0.65 },
        { Texture = Textures.maple, Color = m.C("Red"), Size = 0.55 },
        { Texture = Textures.oak, Color = m.C("Oak"), Size = 0.55 },
        { Texture = Textures.birch, Color = m.C("Birch"), Size = 0.45 },
    }
    for _, leaf in leaves do
        m.Emit(Sky, {
            Texture = leaf.Texture,
            EmissionDirection = Enum.NormalId.Bottom,
            Rate = 32,
            Lifetime = m.Fall(2.2, 2.9),
            Speed = NumberRange.new(2.2, 2.9),
            Acceleration = gravity,
            Drag = drag,
            SpreadAngle = Vector2.new(30, 30),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-150, 150),
            Squash = flutter,
            Size = NumberSequence.new(leaf.Size),
            Transparency = numberSequence({ { 0, 1 }, { 0.04, 0 }, { 0.94, 0 }, { 1, 1 } }),
            Color = ColorSequence.new(leaf.Color),
            LightEmission = 0,
            LightInfluence = 0.7,
            Brightness = 1.3,
        }, 3)
    end
    m.Emit(Lens, {
        Texture = Textures.maple,
        EmissionDirection = Enum.NormalId.Bottom,
        Rate = 4,
        Lifetime = NumberRange.new(5, 7),
        Speed = NumberRange.new(1.5, 2.5),
        SpreadAngle = Vector2.new(30, 30),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-150, 150),
        Squash = flutter,
        Size = NumberSequence.new(0.8),
        Transparency = numberSequence({ { 0, 1 }, { 0.15, 0.1 }, { 0.85, 0.15 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Maple")),
        LightEmission = 0,
        LightInfluence = 0.7,
    }, 3)
    m.Emit(Volume, {
        Texture = Textures.soft,
        Rate = 50,
        Lifetime = NumberRange.new(5, 8),
        Speed = NumberRange.new(0.2, 0.5),
        SpreadAngle = Vector2.new(180, 180),
        Size = scaled(twinkle, 0.12),
        Color = ColorSequence.new(m.C("Motes")),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 2,
    }, 0.6)
    nearField(m, {
        Texture = Textures.maple,
        Color = m.C("Maple"),
        HazeColor = m.C("Motes"),
        Rate = 50,
        Size = 0.34,
        Transparency = 0.22,
        Wind = 1.2,
    })
end)

mode("Fireflies", {
    Lighting = { ClockTime = 21.3, Brightness = 0.9, Ambient = rgb(55, 65, 80), OutdoorAmbient = rgb(75, 90, 105), ExposureCompensation = 0.4 },
    Atmosphere = { Density = 0.35, Offset = 0.05, Color = rgb(60, 80, 90), Decay = rgb(25, 35, 45), Glare = 0, Haze = 1.5 },
    Clouds = { Cover = 0.3, Density = 0.2, Color = rgb(70, 80, 95) },
    Grade = { TintColor = rgb(220, 240, 235), Saturation = 0.05, Contrast = 0.08, Brightness = 0 },
    Bloom = { Intensity = 1.1, Size = 30, Threshold = 0.9 },
}, function(m)
    starDome(m, 40, 3, { m.C("Stars") })

    local meadow = newPart("Meadow", Vector3.new(activeRadius(m.Name) * 1.4, m.Height, activeRadius(m.Name) * 1.4), m.Folder)
    meadow.CFrame = Ground.CFrame * CFrame.new(0, m.Height / 2, 0)
    for i = 1, 3 do
        m.Emit(meadow, {
            Texture = Textures.soft,
            Rate = 45,
            Lifetime = NumberRange.new(6, 10),
            Speed = NumberRange.new(0.3, 0.8),
            SpreadAngle = Vector2.new(180, 180),
            Size = scaled(blink, 0.3),
            Color = ColorSequence.new(m.C(`Firefly{i}`)),
            LightEmission = 1,
            LightInfluence = 0,
            Brightness = 6,
        }, 0.15)
    end
    m.Emit(Lens, {
        Texture = Textures.soft,
        Rate = 5,
        Lifetime = NumberRange.new(5, 8),
        Speed = NumberRange.new(0.2, 0.6),
        SpreadAngle = Vector2.new(180, 180),
        Size = scaled(blink, 0.6),
        Color = ColorSequence.new(m.C("Firefly1")),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 4,
    }, 0.15)
    nearField(m, {
        Texture = Textures.soft,
        Color = m.C("Firefly1"),
        HazeColor = m.C("Mist"),
        Rate = 35,
        Size = 0.22,
        Transparency = 0.2,
        Wind = 0.2,
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 4,
        HazeRate = 6,
    })
    groundMist(m, m.C("Mist"), 0.86, 8)

    m.Update = function()
        meadow.CFrame = Ground.CFrame * CFrame.new(0, m.Height / 2, 0)
    end
end)

mode("Sandstorm", {
    Lighting = { ClockTime = 14.8, Brightness = 2.2, Ambient = rgb(150, 120, 90), OutdoorAmbient = rgb(190, 150, 110), ExposureCompensation = 0.05 },
    Atmosphere = { Density = 0.62, Offset = 0.2, Color = rgb(215, 170, 120), Decay = rgb(180, 120, 70), Glare = 1.2, Haze = 3.2 },
    Clouds = { Cover = 0.75, Density = 0.6, Color = rgb(220, 180, 130) },
    Grade = { TintColor = rgb(255, 225, 190), Saturation = -0.1, Contrast = 0.08, Brightness = 0.02 },
    Bloom = { Intensity = 0.4, Size = 30, Threshold = 1.4 },
    SunRays = { Intensity = 0.08, Spread = 0.8 },
}, function(m)

    local size = math.clamp(activeRadius(m.Name), 40, 140) * 2
    local storm = newPart("Storm", Vector3.new(size, m.Height, size), m.Folder)
    local drift = newPart("Drift", Vector3.new(size * 0.55, 1.5, size * 0.55), m.Folder)
    local gusts = newPart("Gusts", Vector3.new(28, 14, 28), m.Folder)
    local body = newPart("Body", Vector3.new(22, 12, 22), m.Folder)

    local function sand(parent, rate, lifetime, speed, spread, grainSize, transparency, color)
        return m.Emit(parent, {
            Texture = Textures.grain,
            Orientation = Enum.ParticleOrientation.VelocityParallel,
            EmissionDirection = Enum.NormalId.Front,
            Rate = rate,
            Lifetime = lifetime,
            Speed = speed,
            SpreadAngle = Vector2.new(spread, spread),
            Size = NumberSequence.new(grainSize),
            Transparency = numberSequence({ { 0, 1 }, { 0.12, transparency }, { 0.88, transparency + 0.08 }, { 1, 1 } }),
            Color = ColorSequence.new(color),
            LightEmission = 0.1,
            LightInfluence = 0.8,
        })
    end
    local stormSand = sand(storm, 420, NumberRange.new(1.2, 1.8), NumberRange.new(26, 40), 8, 0.55, 0.42, m.C("Sand"))
    sand(gusts, 220, NumberRange.new(0.8, 1.2), NumberRange.new(24, 36), 7, 0.45, 0.38, m.C("Sand"))
    sand(drift, 180, NumberRange.new(1, 1.6), NumberRange.new(18, 28), 4, 0.4, 0.32, m.C("Drift"))
    sand(body, 260, NumberRange.new(0.7, 1.2), NumberRange.new(14, 26), 18, 0.35, 0.3, m.C("Sand"))
    m.Emit(storm, {
        Texture = Textures.haze,
        EmissionDirection = Enum.NormalId.Front,
        Rate = 22,
        Lifetime = NumberRange.new(2.5, 4),
        Speed = NumberRange.new(12, 20),
        SpreadAngle = Vector2.new(12, 12),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-20, 20),
        Size = numberSequence({ { 0, 10 }, { 1, 18 } }),
        Transparency = numberSequence({ { 0, 1 }, { 0.2, 0.72 }, { 0.8, 0.72 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Dust")),
        LightEmission = 0,
        LightInfluence = 0.8,
    })
    nearField(m, {
        Texture = Textures.grain,
        Color = m.C("Sand"),
        HazeColor = m.C("Dust"),
        Rate = 140,
        Size = 0.38,
        Transparency = 0.28,
        Wind = 2,
        HazeRate = 16,
    })

    m.Update = function(t)
        local direction = windDirection(m.Name)
        if direction.Magnitude < 1e-3 then
            direction = Vector3.xAxis
        end
        local base = Ground.Position
        local mid = base + Vector3.new(0, m.Height / 2, 0)
        local cam = workspace.CurrentCamera
        local camera = (cam and cam.CFrame.Position) or mid
        storm.CFrame = CFrame.lookAt(mid, mid + direction) * CFrame.new(0, 0, size * 0.18)
        drift.CFrame = CFrame.lookAt(base + Vector3.new(0, 0.8, 0), base + Vector3.new(0, 0.8, 0) + direction)
        gusts.CFrame = CFrame.lookAt(camera, camera + direction) * CFrame.new(0, 0, 8)
        body.CFrame = CFrame.lookAt(base + Vector3.new(0, 5, 0), base + Vector3.new(0, 5, 0) + direction)
        if stormSand and stormSand.Parent then
            stormSand.TimeScale = 1 + 0.25 * math.sin(t * 0.8) + 0.1 * math.sin(t * 2.3)
        end
    end
end)

mode("Pestilence", {
    Lighting = { ClockTime = 17.8, Brightness = 1, Ambient = rgb(85, 95, 60), OutdoorAmbient = rgb(105, 115, 70), ExposureCompensation = -0.05 },
    Atmosphere = { Density = 0.55, Offset = 0.2, Color = rgb(140, 160, 90), Decay = rgb(80, 90, 40), Glare = 0.3, Haze = 2.6 },
    Clouds = { Cover = 0.9, Density = 0.75, Color = rgb(110, 120, 80) },
    Grade = { TintColor = rgb(220, 240, 190), Saturation = -0.35, Contrast = 0.15, Brightness = -0.03 },
    Bloom = { Intensity = 0.6, Size = 30, Threshold = 1.15 },
}, function(m)
    local gravity, drag = falling(0.6, 0.3)
    for i = 1, 3 do
        m.Emit(Sky, {
            Texture = Textures[`ash{i}`],
            EmissionDirection = Enum.NormalId.Bottom,
            Rate = 45,
            Lifetime = m.Fall(1.6, 2.1),
            Speed = NumberRange.new(1.6, 2.1),
            Acceleration = gravity,
            Drag = drag,
            SpreadAngle = Vector2.new(30, 30),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-70, 70),
            Squash = flutter,
            Size = NumberSequence.new(0.2 + i * 0.06),
            Transparency = numberSequence({ { 0, 1 }, { 0.05, 0.15 }, { 0.9, 0.25 }, { 1, 1 } }),
            Color = ColorSequence.new(m.C("Blight")),
            LightEmission = 0,
            LightInfluence = 1,
        }, 1.2)
    end

    m.Emit(Volume, {
        Texture = Textures.soft,
        EmissionDirection = Enum.NormalId.Top,
        Rate = 90,
        Lifetime = NumberRange.new(5, 9),
        Speed = NumberRange.new(0.3, 0.9),
        SpreadAngle = Vector2.new(60, 60),
        Acceleration = Vector3.new(0, 0.15, 0),
        Size = scaled(twinkle, 0.22),
        Color = colorSequence({ { 0, m.C("Spores") }, { 1, m.C("SporeFade") } }),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 3,
    }, 0.5)

    m.Emit(NearGround, {
        Texture = Textures.bubble,
        EmissionDirection = Enum.NormalId.Top,
        Rate = 25,
        Lifetime = NumberRange.new(1.2, 2),
        Speed = NumberRange.new(0.4, 1.2),
        SpreadAngle = Vector2.new(20, 20),
        Size = popSize(0.35),
        Transparency = popTransparency,
        Color = ColorSequence.new(m.C("Toxic")),
        LightEmission = 0.5,
        LightInfluence = 0.3,
        Brightness = 1.6,
    })

    groundMist(m, m.C("Miasma"), 0.72, 14)
    m.Emit(Volume, {
        Texture = Textures.haze,
        Rate = 6,
        Lifetime = NumberRange.new(8, 12),
        Speed = NumberRange.new(0.3, 0.8),
        SpreadAngle = Vector2.new(180, 20),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-5, 5),
        Size = numberSequence({ { 0, 14 }, { 1, 24 } }),
        Transparency = numberSequence({ { 0, 1 }, { 0.3, 0.8 }, { 0.7, 0.8 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Toxic")),
        LightEmission = 0.15,
        LightInfluence = 0.6,
    }, 0.4)
    nearField(m, {
        Texture = Textures.fly,
        Color = m.C("Flies"),
        HazeColor = m.C("Miasma"),
        Rate = 70,
        Size = 0.16,
        Transparency = 0.2,
        Wind = 0.8,
        HazeRate = 12,
    })

    local swarms = {}
    local function newHome()
        local angle = rng:NextNumber(0, math.pi * 2)
        local distance = rng:NextNumber(6, 45)
        return Vector3.new(math.cos(angle) * distance, rng:NextNumber(1, 5), math.sin(angle) * distance)
    end
    for i = 1, 7 do
        local home = newHome()
        local anchor = newPart("Swarm", Vector3.new(1.5, 1.5, 1.5), m.Folder)
        anchor.CFrame = CFrame.new(Ground.Position + home)
        m.Emit(anchor, {
            Texture = Textures.fly,
            Rate = 55,
            Lifetime = NumberRange.new(1, 1.8),
            Speed = NumberRange.new(3, 6),
            SpreadAngle = Vector2.new(180, 180),
            Drag = 4,
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-400, 400),
            Size = numberSequence({ { 0, 0 }, { 0.1, 0.16 }, { 0.9, 0.16 }, { 1, 0 } }),
            Color = ColorSequence.new(m.C("Flies")),
            LightEmission = 0,
            LightInfluence = 1,
        })
        swarms[i] = { Anchor = anchor, Home = home, Seed = rng:NextNumber(0, 100), Moved = 0 }
    end

    m.Update = function(t, dt)
        local center = Ground.Position
        for _, swarm in swarms do
            swarm.Moved += dt
            if swarm.Moved > rng:NextNumber(8, 16) then
                swarm.Moved = 0
                swarm.Home = newHome()
            end
            local s = swarm.Seed
            local wander = Vector3.new(
                math.sin(t * 1.7 + s) * 2 + math.sin(t * 6.3 + s * 2) * 0.6,
                math.sin(t * 2.1 + s * 3) * 0.8,
                math.cos(t * 1.3 + s) * 2 + math.cos(t * 5.7 + s * 4) * 0.6
            )
            local target = center + swarm.Home + wander
            local current = swarm.Anchor.Position
            swarm.Anchor.CFrame = CFrame.new(current:Lerp(target, math.min(1, dt * 2)))
        end
    end
end)

mode("Bubbles", {
    Lighting = { ClockTime = 10.5, Brightness = 2.6, Ambient = rgb(150, 140, 170), OutdoorAmbient = rgb(180, 175, 200), ExposureCompensation = 0.25 },
    Atmosphere = { Density = 0.28, Offset = 0.1, Color = rgb(210, 225, 255), Decay = rgb(220, 190, 240), Glare = 0.5, Haze = 1.2 },
    Clouds = { Cover = 0.4, Density = 0.25, Color = rgb(255, 255, 255) },
    Grade = { TintColor = rgb(245, 245, 255), Saturation = 0.2, Contrast = 0.03, Brightness = 0.03 },
    Bloom = { Intensity = 0.7, Size = 45, Threshold = 1 },
    SunRays = { Intensity = 0.1, Spread = 0.6 },
}, function(m)

    local field = newPart("BubbleField", Vector3.new(activeRadius(m.Name) * 1.6, m.Height, activeRadius(m.Name) * 1.6), m.Folder)
    field.CFrame = Ground.CFrame * CFrame.new(0, m.Height / 2, 0)
    for _, kind in { { Size = 0.45, Rate = 45 }, { Size = 0.9, Rate = 26 }, { Size = 1.6, Rate = 10 } } do
        m.Emit(Ground, {
            Texture = Textures.bubble,
            EmissionDirection = Enum.NormalId.Top,
            Rate = kind.Rate,
            Lifetime = NumberRange.new(8, 14),
            Speed = NumberRange.new(0.8, 2),
            SpreadAngle = Vector2.new(35, 35),
            Acceleration = Vector3.new(0, 0.18, 0),
            Drag = 0.35,
            Size = popSize(kind.Size),
            Transparency = popTransparency,
            Color = ColorSequence.new(m.C("Bubble")),
            LightEmission = 0.35,
            LightInfluence = 0.25,
            Brightness = 1.5,
        }, 0.9)
    end

    local prewarm = m.Emit(field, {
        Texture = Textures.bubble,
        Rate = 30,
        Lifetime = NumberRange.new(5, 9),
        Speed = NumberRange.new(0.4, 1),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, 0.18, 0),
        Drag = 0.35,
        Size = popSize(0.8),
        Transparency = popTransparency,
        Color = ColorSequence.new(m.C("Bubble")),
        LightEmission = 0.35,
        LightInfluence = 0.25,
        Brightness = 1.5,
    }, 0.9)
    prewarm:Emit(120)
    m.Emit(Lens, {
        Texture = Textures.bubble,
        Rate = 3,
        Lifetime = NumberRange.new(5, 8),
        Speed = NumberRange.new(0.3, 0.8),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, 0.2, 0),
        Drag = 0.35,
        Size = popSize(2.4),
        Transparency = numberSequence({ { 0, 1 }, { 0.08, 0.2 }, { 0.9, 0.2 }, { 0.96, 0.55 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Bubble")),
        LightEmission = 0.35,
        LightInfluence = 0.25,
        Brightness = 1.5,
    }, 0.9)
    m.Emit(field, {
        Texture = Textures.star,
        Rate = 50,
        Lifetime = NumberRange.new(3, 6),
        Speed = NumberRange.new(0.2, 0.5),
        SpreadAngle = Vector2.new(180, 180),
        Size = scaled(twinkle, 0.35),
        Color = ColorSequence.new(m.C("Sparkle")),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 4,
    }, 0.4)
    m.Emit(field, {
        Texture = Textures.soft,
        Rate = 30,
        Lifetime = NumberRange.new(5, 8),
        Speed = NumberRange.new(0.2, 0.5),
        SpreadAngle = Vector2.new(180, 180),
        Size = scaled(twinkle, 0.3),
        Color = ColorSequence.new(m.C("Glow")),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 2,
    }, 0.5)
    nearField(m, {
        Texture = Textures.bubble,
        Color = m.C("Bubble"),
        HazeColor = m.C("Glow"),
        Rate = 45,
        Size = 0.4,
        Transparency = 0.2,
        Wind = 0.6,
        HazeRate = 8,
    })

    m.Update = function()
        field.CFrame = Ground.CFrame * CFrame.new(0, m.Height / 2, 0)
    end
end)

local function destroyModeFolder(folder)
    if folder and folder.Parent then
        folder:Destroy()
    end
end

local function purgeModeFolders(keep)
    if not Container then
        return
    end
    for _, child in Container:GetChildren() do
        if child:IsA("Folder") and Modes[child.Name] and child ~= keep then
            destroyModeFolder(child)
        end
    end
end

local function stopMode(immediate)
    local m = Active
    if not m then return end
    Active = nil

    if m.Stop then
        pcall(m.Stop)
    end

    if immediate then
        for _, entry in m.Emitters do
            pcall(function()
                entry.Emitter:Destroy()
            end)
        end
        destroyModeFolder(m.Folder)
        return
    end

    local originals = {}
    for i, entry in m.Emitters do
        if entry.Emitter and entry.Emitter.Parent then
            entry.Emitter.Enabled = false
            originals[i] = entry.Emitter.Transparency
        end
    end
    local start = os.clock()
    local fade
    fade = RunService.Heartbeat:Connect(function()
        local k = math.min((os.clock() - start) / Config.FadeTime, 1)
        for i, entry in m.Emitters do
            local original = originals[i]
            local emitter = entry.Emitter
            if original and emitter and emitter.Parent then
                local keypoints = {}
                for _, keypoint in original.Keypoints do
                    table.insert(keypoints, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value + (1 - keypoint.Value) * k))
                end
                emitter.Transparency = NumberSequence.new(keypoints)
            end
        end
        if k >= 1 then
            fade:Disconnect()
            for _, entry in m.Emitters do
                if entry.Emitter and entry.Emitter.Parent then
                    entry.Emitter:Destroy()
                end
            end
            destroyModeFolder(m.Folder)
        end
    end)
    table.insert(Connections, fade)
end

local function startMode(name)
    local def = Modes[name]
    if not def then return end

    purgeModeFolders()

    local m = {
        Name = name,
        Environment = def.Environment,
        Height = modeHeight(name),
        Emitters = {},
        Time = 0,
        Folder = create("Folder", { Name = name, Parent = Container }),
    }
    Column.Size = Vector3.new(Column.Size.X, m.Height, Column.Size.Z)

    function m.Fall(minSpeed, maxSpeed)
        return NumberRange.new(m.Height / maxSpeed, m.Height / minSpeed * 1.1)
    end

    function m.C(slot)
        local colors = Config.Colors[name]
        return colors and colors[slot] or Color3.new(1, 1, 1)
    end

    function m.Emit(parent, props, windScale)
        local rate = (tonumber(props.Rate) or 0) * rateScale(name)
        props.Rate = math.clamp(rate, 0, 90)
        if props.Brightness and props.Brightness > 2.5 then
            props.Brightness = 2.5
        end
        if props.Size then
            props.Size = scaleSequence(props.Size, modeSizeScale(name))
        end
        props.Parent = parent
        local emitter = create("ParticleEmitter", props)
        local entry = { Emitter = emitter, Base = props.Acceleration or Vector3.zero, Wind = windScale or 0 }
        table.insert(m.Emitters, entry)

        if parent == Sky and not props.LockedToPart then
            local lifetime = props.Lifetime and props.Lifetime.Max or 1
            local burst = math.min(math.floor(props.Rate * lifetime * 0.2), 40)
            if burst > 0 then
                local prewarm = emitter:Clone()
                prewarm.Enabled = false
                prewarm.Parent = Column
                prewarm:Emit(burst)
                table.insert(m.Emitters, { Emitter = prewarm, Base = entry.Base, Wind = entry.Wind })
                task.delay(lifetime, prewarm.Destroy, prewarm)
            end
        end
        return emitter
    end

    Active = m
    local ok, err = pcall(def.Build, m)
    if not ok then
        warn(`[Weather] {name} failed to build: {err}`)
    end
    for _, entry in m.Emitters do
        if entry.Emitter and entry.Emitter.Parent then
            entry.Emitter.Enabled = true
        end
    end
    if m.Update then
        local okUpdate, updateErr = pcall(m.Update, 0, 0)
        if not okUpdate then
            warn(`[Weather] {name} first update failed: {updateErr}`)
            m.Update = nil
        end
    end
    applyEnvironment(def.Environment)
end

local function saveSettings()
    if not Config.RememberMode then return end
    pcall(writefile, SettingsPath, HttpService:JSONEncode({ Mode = Config.Mode }))
end

local function loadSettings()
    if not Config.RememberMode or not (isfile and isfile(SettingsPath)) then return end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(SettingsPath))
    if ok and type(data) == "table" and (Modes[data.Mode] or data.Mode == "Off") then
        Config.Mode = data.Mode
    end
end

local function setMode(name, force)
    if Active and Active.Name == name and not force then return end
    if name ~= "Off" and not Modes[name] then return end
    if name == "Off" then
        if Config.Mode ~= "Off" and Modes[Config.Mode] then
            Config.LastMode = Config.Mode
        end
    else
        Config.LastMode = name
    end
    stopMode(force == true)
    Config.Mode = name
    if name == "Off" then
        Active = nil
        applyEnvironment(nil)
        purgeModeFolders()
        if Container then
            Container.Parent = nil
        end
    else
        if Container and not Container.Parent then
            Container.Parent = workspace.CurrentCamera
        end
        startMode(name)
    end
    saveSettings()
end

local function cycleMode()
    local index = table.find(ModeOrder, Config.Mode) or 0
    setMode(ModeOrder[index % #ModeOrder + 1])
end

local lastGround = nil
local lastGroundAt = 0
local lastGustAt = 0
local cachedGust = Vector3.zero
local lastWeatherTick = 0

local function update(dt)
    local m = Active
    if not m or Config.Mode == "Off" then
        return
    end

    local center = focusPosition()
    local now = os.clock()
    local ground
    if lastGround and now - lastGroundAt < 0.2 then
        ground = Vector3.new(center.X, lastGround.Y, center.Z)
    else
        ground = groundBelow(center, center.Y - 3)
        lastGround = ground
        lastGroundAt = now
    end
    local camera = workspace.CurrentCamera.CFrame.Position
    local height = m.Height or Config.Height
    local radius = activeRadius(m.Name)
    local area = radius * 2
    if Sky.Size.X ~= area then
        Sky.Size = Vector3.new(area, 1, area)
        Column.Size = Vector3.new(area, height, area)
        Volume.Size = Vector3.new(area, Volume.Size.Y, area)
        Ground.Size = Vector3.new(area, 0.2, area)
    elseif Column.Size.Y ~= height then
        Column.Size = Vector3.new(area, height, area)
    end
    if m.Name == "Stars" then
        local distance = modeStarDistance("Stars")
        local domeSize = distance * 2
        if Dome.Size.X ~= domeSize then
            Dome.Size = Vector3.one * domeSize
        end
    end

    Sky.CFrame = CFrame.new(center.X, center.Y + height, center.Z)
    Column.CFrame = CFrame.new(center.X, center.Y + height / 2, center.Z)
    Volume.CFrame = CFrame.new(center.X, ground.Y + Volume.Size.Y / 2, center.Z)
    Ground.CFrame = CFrame.new(center.X, ground.Y + 0.05, center.Z)
    NearSky.Size = Vector3.new(36, 1, 36)
    NearGround.Size = Vector3.new(36, 0.2, 36)
    NearSky.CFrame = CFrame.new(center.X, center.Y + math.min(height, 18), center.Z)
    NearGround.CFrame = CFrame.new(center.X, ground.Y + 0.05, center.Z)
    Dome.CFrame = CFrame.new(center)
    Lens.Size = Vector3.new(24, 18, 24)
    Lens.CFrame = CFrame.new(camera + Vector3.new(0, 2, 0))

    m.Time += dt
    local t = m.Time

    if now - lastGustAt >= 0.1 then
        lastGustAt = now
        cachedGust = Config.Wind * modeWindScale(m.Name) * (1 + 0.6 * math.sin(t * 0.35))
            + Vector3.new(math.sin(t * 0.7), 0, math.cos(t * 0.5)) * 0.8 * modeWindScale(m.Name)
        for _, entry in m.Emitters do
            if entry.Wind ~= 0 and entry.Emitter and entry.Emitter.Parent then
                entry.Emitter.Acceleration = entry.Base + cachedGust * entry.Wind
            end
        end
    end

    if m.Update then
        local ok, err = pcall(m.Update, t, dt)
        if not ok then
            warn(`[Weather] {m.Name} update failed: {err}`)
            m.Update = nil
        end
    end
end

local function main()
    loadTextures()
    loadSettings()
    captureEnvironment()

    local size = Config.Radius * 2
    Container = create("Folder", { Name = "TapologyWeather", Parent = workspace.CurrentCamera })
    Sky = newPart("Sky", Vector3.new(size, 1, size), Container)
    Column = newPart("Column", Vector3.new(size, Config.Height, size), Container)
    Volume = newPart("Volume", Vector3.new(size, 24, size), Container)
    Ground = newPart("Ground", Vector3.new(size, 0.2, size), Container)
    NearSky = newPart("NearSky", Vector3.new(50, 1, 50), Container)
    NearGround = newPart("NearGround", Vector3.new(50, 0.2, 50), Container)
    Dome = newPart("Dome", Vector3.one * Config.StarDistance * 2, Container)
    Lens = newPart("Lens", Vector3.new(30, 26, 30), Container)

    update(0)
    if Config.Mode ~= "Off" then
        startMode(Config.Mode)
    end

    table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
        local now = os.clock()
        if now - lastWeatherTick < 1 / 20 then
            return
        end
        local step = now - lastWeatherTick
        lastWeatherTick = now
        update(math.clamp(step, 0.05, 0.1))
    end))
    table.insert(Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not Config.Hotkeys or not UserInputService:IsKeyDown(Config.Modifier) then return end
        if input.KeyCode == Config.CycleKey then
            cycleMode()
            return
        end
        local name = Config.Keys[input.KeyCode]
        if name then
            setMode(name)
        end
    end))

    local rebuildToken = 0
    env.Weather = {
        Config = Config,
        Modes = ModeOrder,
        SetMode = setMode,

        SetColor = function(modeName, slot, color)
            Config.Colors[modeName] = Config.Colors[modeName] or {}
            Config.Colors[modeName][slot] = color
            if Active and Active.Name == modeName then
                rebuildToken += 1
                local token = rebuildToken
                task.delay(0.35, function()
                    if token == rebuildToken and Active and Active.Name == modeName then
                        setMode(modeName, true)
                    end
                end)
            end
        end,

        SetChangeEnvironment = function(on)
            Config.ChangeEnvironment = on and true or false
            applyEnvironment(Active and Active.Environment)
        end,

        SetParam = function(modeName, key, value)
            Config.ModeParams[modeName] = Config.ModeParams[modeName] or {}
            Config.ModeParams[modeName][key] = value
            if key == "Height" then
                Config.Heights[modeName] = value
            end
            if Active and Active.Name == modeName then
                if key == "Height" then
                    Active.Height = value
                end
                rebuildToken += 1
                local token = rebuildToken
                task.delay(0.35, function()
                    if token == rebuildToken and Active and Active.Name == modeName then
                        setMode(modeName, true)
                    end
                end)
            end
        end,
        Strike = function()
            if Active and Active.Name == "Rain" then
                strike(Active)
            end
        end,

        Reapply = function()
            if not Active or Active.Name == "Off" then
                return
            end
            applyEnvironment(Active.Environment, true)
        end,

        Rebuild = function()
            if not Active or Active.Name == "Off" then
                return
            end
            setMode(Active.Name, true)
        end,
        Unload = function()
            for _, connection in Connections do
                connection:Disconnect()
            end
            table.clear(Connections)
            Active = nil
            Container:Destroy()
            restoreEnvironment()
            env.Weather = nil
        end,
    }
end

TextureIds = {
    flake1 = "rbxassetid://79645306266230",
    flake2 = "rbxassetid://133424539659250",
    flake3 = "rbxassetid://72156116653308",
    soft = "rbxassetid://126113124163785",
    raindrop = "rbxassetid://139846859897029",
    splash = "rbxassetid://91125787375786",
    star = "rbxassetid://97979520465485",
    streak = "rbxassetid://81651000185831",
    ash1 = "rbxassetid://115864219323770",
    ash2 = "rbxassetid://71854731655512",
    ash3 = "rbxassetid://87064905267865",
    ember = "rbxassetid://80546770381782",
    petal1 = "rbxassetid://112586437979626",
    petal2 = "rbxassetid://71341499685050",
    petal3 = "rbxassetid://88001043515254",
    butterfly = "rbxassetid://138578077100518",
    haze = "rbxassetid://130890784990156",
    aurora = "rbxassetid://86499590710700",
    maple = "rbxassetid://74682057917220",
    oak = "rbxassetid://90776733413444",
    birch = "rbxassetid://93326338292493",
    rainsheet = "rbxassetid://83419859311993",
    grain = "rbxassetid://98885703554732",
    fly = "rbxassetid://129163843793947",
    bubble = "rbxassetid://112220434891323",
}

do
    local okWeather, errWeather = pcall(main)
    if not okWeather then
        warn("[Weather] main failed:", errWeather)
    end
end

end
