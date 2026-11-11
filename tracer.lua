do

local warn = function() end

local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local SoundService = cloneref(game:GetService("SoundService"))

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local Config = {
    Enabled = false,
    Style = "Aether",
    Demo = false,
    DemoStyles = { "Aether", "Blossom", "Inferno", "Plasma", "Frost", "Lightning", "Rift", "Starfall", "Cosmos", "Void" },
    DemoInterval = 1.1,
    DemoDistance = 16,
    DemoSpan = 36,
    OnShoot = false,
    MaxDistance = 2000,

    TaperPeak = 0.3,
    Pieces = 8,
    Width = 1,
    Lifetime = 1,
    HitSounds = false,
    HitSound = "Impact",
    HitSoundVolume = 1,
    HitSoundPitch = 1,
    HitLogs = false,
    HitLogDuration = 3.5,
    HitSoundIds = {
        Impact = "rbxassetid://9113500510",
        Gamesense = "rbxassetid://4817809188",
        Neverlose = "rbxassetid://6607339542",
        Bell = "rbxassetid://6532297512",
        Cod = "rbxassetid://5685988853",
        Click = "rbxassetid://12222208",
        Metal = "rbxassetid://8917041751",
        Soft = "rbxassetid://9113809773",
        Classic = "rbxassetid://131961136",
        Perc = "rbxassetid://9114221361",
        Pop = "rbxassetid://9114220987",
        Snap = "rbxassetid://9120092149",
        Ding = "rbxassetid://8255306220",
        Hitmarker = "rbxassetid://705502934",
        Ping = "rbxasset://sounds/electronicpingshort.mp3",
    },

    Styles = {
        Aether = { Speed = 95, Linger = 0.7, Fade = 0.8, Width = 1 },
        Blossom = { Speed = 110, Linger = 0.8, Fade = 0.8, Width = 1 },
        Inferno = { Speed = 160, Linger = 0.5, Fade = 0.6, Width = 1 },
        Plasma = { Speed = 220, Linger = 0.3, Fade = 0.4, Width = 1 },
        Frost = { Speed = 130, Linger = 0.6, Fade = 0.8, Width = 1 },
        Lightning = { Speed = math.huge, Linger = 0.35, Fade = 0.3, Width = 1 },
        Rift = { Speed = 260, Linger = 0.4, Fade = 0.3, Width = 1 },
        Starfall = { Speed = 75, Linger = 0.4, Fade = 0.8, Width = 1 },
        Cosmos = { Speed = 90, Linger = 0.6, Fade = 0.9, Width = 1 },
        Void = { Speed = 150, Linger = 0.5, Fade = 0.9, Width = 1 },
    },

    Colors = {
        Aether = { Silk = rgb(255, 212, 135), Threads = rgb(120, 220, 255), Motes = rgb(255, 235, 180) },
        Blossom = {
            Garland = rgb(255, 160, 200), Pollen = rgb(255, 238, 200),
            Petals = { rgb(255, 190, 215), rgb(255, 160, 200), rgb(255, 228, 238) },
        },
        Inferno = { Outer = rgb(255, 60, 15), Inner = rgb(255, 165, 50), Embers = rgb(255, 140, 40), Smoke = rgb(60, 45, 40) },
        Plasma = { Core = rgb(170, 240, 255), Strands = rgb(170, 100, 255), Sparks = rgb(130, 230, 255) },
        Frost = { Ice = rgb(170, 228, 255), Flakes = rgb(230, 248, 255), Glints = rgb(205, 242, 255), Mist = rgb(170, 215, 240) },
        Lightning = { Bolt = rgb(225, 234, 255), Sparks = rgb(190, 208, 255) },
        Rift = {
            Carrier = rgb(235, 245, 255), Red = rgb(255, 40, 95), Cyan = rgb(40, 230, 255),
            Pixels = { rgb(255, 40, 95), rgb(40, 230, 255), rgb(235, 245, 255) },
        },
        Starfall = { Trail = rgb(255, 205, 110), Glow = rgb(255, 160, 60), Stars = rgb(255, 226, 150) },
        Cosmos = { Nebula = rgb(140, 70, 230), Stars = rgb(235, 235, 255), Dust = rgb(255, 120, 200), Rings = rgb(165, 145, 255) },
        Void = { Smoke = rgb(80, 32, 125), Wisps = rgb(95, 45, 140), Embers = rgb(215, 145, 255) },
    },
    TextureFolder = "tracer_textures",
}

local TextureIds, TextureAspect

local env = getgenv and getgenv() or _G
if env.Tracers then
    env.Tracers.Unload()
end

local LocalPlayer = Players.LocalPlayer
local base64decode = (crypt and crypt.base64decode) or base64_decode or (base64 and base64.decode)
local rng = Random.new()

local Textures = {}
local Styles = {}
local Connections = {}
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

local function scaleSequence(sequence, factor)
    local keypoints = {}
    for _, point in sequence.Keypoints do
        table.insert(keypoints, NumberSequenceKeypoint.new(point.Time, point.Value * factor, point.Envelope * factor))
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

local function heartbeat(callback)
    local connection
    local elapsed = 0
    connection = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if Unloaded or callback(dt, elapsed) == false then
            connection:Disconnect()
        end
    end)
    table.insert(Connections, connection)
end

local function colorList(value)
    return typeof(value) == "table" and value or { value }
end

local function taper(u)
    local peak = Config.TaperPeak
    if u < peak then
        return math.max(0.06, 1 - (1 - u / peak) ^ 2)
    end
    return math.max(0.06, 1 - ((u - peak) / (1 - peak)) ^ 1.4 * 0.94)
end

local function enemyOf(instance)
    local model = instance and instance:FindFirstAncestorOfClass("Model")
    while model do
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if humanoid then
            return model ~= LocalPlayer.Character and humanoid.Health > 0 and model or nil
        end
        model = model:FindFirstAncestorOfClass("Model")
    end
end

local petalFlutter = numberSequence({ { 0, 0 }, { 0.2, 0.6 }, { 0.4, -0.5 }, { 0.6, 0.6 }, { 0.8, -0.5 }, { 1, 0 } })

Styles.Aether = {
    Layers = {
        { Texture = "aether", Color = "Silk", Width = 0.75, Scroll = 1.2, LightEmission = 0.8, Brightness = 1.4 },
        { Texture = "glowbeam", Color = "Threads", Width = 0.05, Curve = 0.7, Spin = 5, Phase = 0, LightEmission = 1, Brightness = 2 },
        { Texture = "glowbeam", Color = "Threads", Width = 0.05, Curve = 0.7, Spin = 5, Phase = math.pi, LightEmission = 1, Brightness = 2 },
    },
    Shed = {
        {
            Texture = "dot", Color = "Motes", PerStud = 0.35, Rate = 0.3,
            Props = {
                Lifetime = NumberRange.new(1.2, 2),
                Speed = NumberRange.new(0.2, 0.6),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, 1.4, 0),
                Size = numberSequence({ { 0, 0.09 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.6,
            },
        },
        {
            Texture = "sparkle", Color = "Threads", PerStud = 0.15, Rate = 0.1,
            Props = {
                Lifetime = NumberRange.new(0.5, 0.9),
                Speed = NumberRange.new(0),
                Rotation = NumberRange.new(0, 90),
                Size = numberSequence({ { 0, 0 }, { 0.4, 0.28 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.6,
            },
        },
    },
}

Styles.Blossom = {
    Layers = {
        { Texture = "blossom", Color = "Garland", Width = 0.8, Scroll = 0.7, LightEmission = 0.1, Brightness = 1.3 },
    },
    Shed = {
        {
            Texture = "petal", Color = "Petals", PerStud = 0.4, Rate = 0.25,
            Props = {
                Lifetime = NumberRange.new(2.2, 3.4),
                Speed = NumberRange.new(0.4, 1.6),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, -3, 0),
                Drag = 1.3,
                Rotation = NumberRange.new(0, 360),
                RotSpeed = NumberRange.new(-160, 160),
                Squash = petalFlutter,
                Size = numberSequence({ { 0, 0 }, { 0.06, 0.3 }, { 0.85, 0.26 }, { 1, 0 } }),
                Transparency = numberSequence({ { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } }),
                LightEmission = 0.1,
                LightInfluence = 0.15,
                Brightness = 1.4,
            },
        },
        {
            Texture = "dot", Color = "Pollen", PerStud = 0.25, Rate = 0.1,
            Props = {
                Lifetime = NumberRange.new(1, 1.8),
                Speed = NumberRange.new(0.2, 0.8),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, 0.4, 0),
                Size = numberSequence({ { 0, 0.08 }, { 1, 0 } }),
                LightEmission = 0.8,
                Brightness = 1.5,
            },
        },
    },
}

Styles.Inferno = {
    Layers = {
        { Texture = "flame", Color = "Outer", Width = 0.8, Scroll = 3, LightEmission = 0.8, Brightness = 1.2 },
        { Texture = "flame", Color = "Inner", Width = 0.32, Scroll = 4.5, Transparency = 0.2, LightEmission = 0.8, Brightness = 1.2 },
    },
    Shed = {
        {
            Texture = "flamelet", Gradient = { "Inner", "Outer" }, PerStud = 0.45, Rate = 0.6,
            Props = {
                Lifetime = NumberRange.new(0.35, 0.7),
                Speed = NumberRange.new(0.5, 1.5),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, 7, 0),
                Rotation = NumberRange.new(-15, 15),
                Size = numberSequence({ { 0, 0.42 }, { 1, 0.05 } }),
                Transparency = numberSequence({ { 0, 0.1 }, { 1, 1 } }),
                LightEmission = 1,
                Brightness = 1.6,
            },
        },
        {
            Texture = "dot", Color = "Embers", PerStud = 0.3, Rate = 0.35,
            Props = {
                Lifetime = NumberRange.new(0.8, 1.4),
                Speed = NumberRange.new(1, 3),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, 4, 0),
                Drag = 1,
                Size = numberSequence({ { 0, 0.08 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.8,
            },
        },
        {
            Texture = "puff", Color = "Smoke", PerStud = 0.1, Rate = 0.15,
            Props = {
                Lifetime = NumberRange.new(1, 1.6),
                Speed = NumberRange.new(0.3, 0.8),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, 2, 0),
                Rotation = NumberRange.new(0, 360),
                RotSpeed = NumberRange.new(-30, 30),
                Size = numberSequence({ { 0, 0.5 }, { 1, 1.6 } }),
                Transparency = numberSequence({ { 0, 1 }, { 0.2, 0.65 }, { 1, 1 } }),
                LightEmission = 0,
                LightInfluence = 0.5,
            },
        },
    },
}

Styles.Plasma = {
    Layers = {
        { Texture = "plasma", Color = "Core", Width = 0.32, Scroll = 5, Transparency = 0.1, LightEmission = 1, Brightness = 1.3 },
        { Texture = "glowbeam", Color = "Strands", Width = 0.09, Curve = 0.8, Spin = 11, Phase = 0, LightEmission = 0.8, Brightness = 2.2 },
        { Texture = "glowbeam", Color = "Strands", Width = 0.09, Curve = 0.8, Spin = 11, Phase = math.pi, LightEmission = 0.8, Brightness = 2.2 },
    },
    Shed = {
        {
            Texture = "spark", Color = "Sparks", PerStud = 0.4, Rate = 0,
            Props = {
                Orientation = Enum.ParticleOrientation.VelocityParallel,
                Lifetime = NumberRange.new(0.2, 0.45),
                Speed = NumberRange.new(6, 12),
                SpreadAngle = Vector2.new(180, 180),
                Drag = 4,
                Size = numberSequence({ { 0, 0.24 }, { 1, 0.04 } }),
                LightEmission = 1,
                Brightness = 2,
            },
        },
        {
            Texture = "dot", Color = "Strands", PerStud = 0.3, Rate = 0.3,
            Props = {
                Lifetime = NumberRange.new(0.5, 1),
                Speed = NumberRange.new(0.3, 1),
                SpreadAngle = Vector2.new(180, 180),
                Size = numberSequence({ { 0, 0.14 }, { 1, 0 } }),
                Transparency = numberSequence({ { 0, 0.1 }, { 1, 1 } }),
                LightEmission = 1,
                Brightness = 1.6,
            },
        },
    },
}

Styles.Frost = {
    Layers = {
        { Texture = "frost", Color = "Ice", Width = 0.7, Scroll = 0.5, LightEmission = 0.7, Brightness = 1.5 },
    },
    Shed = {
        {
            Texture = "flake", Color = "Flakes", PerStud = 0.25, Rate = 0.25,
            Props = {
                Lifetime = NumberRange.new(1.6, 2.6),
                Speed = NumberRange.new(0.2, 0.8),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, -1.2, 0),
                Drag = 0.5,
                Rotation = NumberRange.new(0, 360),
                RotSpeed = NumberRange.new(-60, 60),
                Size = numberSequence({ { 0, 0 }, { 0.1, 0.22 }, { 1, 0.15 } }),
                Transparency = numberSequence({ { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } }),
                LightEmission = 0.6,
                Brightness = 1.5,
            },
        },
        {
            Texture = "sparkle", Color = "Glints", PerStud = 0.2, Rate = 0.15,
            Props = {
                Lifetime = NumberRange.new(0.3, 0.6),
                Speed = NumberRange.new(0),
                Rotation = NumberRange.new(0, 90),
                Size = numberSequence({ { 0, 0 }, { 0.5, 0.32 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.8,
            },
        },
        {
            Texture = "puff", Color = "Mist", PerStud = 0.08, Rate = 0.12,
            Props = {
                Lifetime = NumberRange.new(1.2, 2),
                Speed = NumberRange.new(0.1, 0.4),
                SpreadAngle = Vector2.new(180, 180),
                Rotation = NumberRange.new(0, 360),
                RotSpeed = NumberRange.new(-20, 20),
                Size = numberSequence({ { 0, 0.6 }, { 1, 1.8 } }),
                Transparency = numberSequence({ { 0, 1 }, { 0.25, 0.75 }, { 1, 1 } }),
                LightEmission = 0.2,
            },
        },
    },
}

Styles.Lightning = {
    Chain = { Spacing = 2.4, Jitter = 0.55, Interval = 0.05, Forks = 3 },
    Layers = {
        { Texture = "lightning", Color = "Bolt", Width = 0.4, Chain = true, LightEmission = 1, Brightness = 2.2 },
    },
    Shed = {
        {
            Texture = "spark", Color = "Sparks", PerStud = 0.25, Rate = 0.5,
            Props = {
                Orientation = Enum.ParticleOrientation.VelocityParallel,
                Lifetime = NumberRange.new(0.15, 0.35),
                Speed = NumberRange.new(5, 11),
                SpreadAngle = Vector2.new(180, 180),
                Drag = 5,
                Size = numberSequence({ { 0, 0.2 }, { 1, 0.04 } }),
                LightEmission = 1,
                Brightness = 2,
            },
        },
    },
}

Styles.Rift = {
    Layers = {
        { Texture = "glitch", Color = "Red", Width = 0.42, Shift = 0.16, Transparency = 0.25, LightEmission = 1, Brightness = 1.6 },
        { Texture = "glitch", Color = "Cyan", Width = 0.42, Shift = 0.16, Transparency = 0.25, LightEmission = 1, Brightness = 1.6 },
        { Texture = "glitch", Color = "Carrier", Width = 0.42, Scroll = 2, LightEmission = 1, Brightness = 1.4 },
    },
    Shed = {
        {
            Texture = "pixel", Color = "Pixels", PerStud = 0.45, Rate = 0.35,
            Props = {
                Lifetime = NumberRange.new(0.25, 0.6),
                Speed = NumberRange.new(0.2, 1.5),
                SpreadAngle = Vector2.new(180, 180),
                Size = numberSequence({ { 0, 0.16 }, { 1, 0.16 } }),
                Transparency = numberSequence({ { 0, 0 }, { 0.7, 0 }, { 1, 1 } }),
                LightEmission = 1,
                Brightness = 1.6,
            },
        },
    },
}

Styles.Starfall = {
    Layers = {
        { Texture = "startrail", Color = "Trail", Width = 0.5, Scroll = 1.5, LightEmission = 1, Brightness = 1.6 },
    },
    Shed = {
        {
            Texture = "sparkle", Color = "Stars", PerStud = 0.35, Rate = 0.3,
            Props = {
                Lifetime = NumberRange.new(1, 1.8),
                Speed = NumberRange.new(0.3, 1.2),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, -4, 0),
                Drag = 1,
                Rotation = NumberRange.new(0, 90),
                RotSpeed = NumberRange.new(-90, 90),
                Size = numberSequence({ { 0, 0.34 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.8,
            },
        },
        {
            Texture = "dot", Color = "Glow", PerStud = 0.4, Rate = 0.25,
            Props = {
                Lifetime = NumberRange.new(0.6, 1.2),
                Speed = NumberRange.new(0.2, 0.8),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, -1.5, 0),
                Size = numberSequence({ { 0, 0.1 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.5,
            },
        },
    },
    Trail = {
        Texture = "sparkle", Color = "Stars", Rate = 55,
        Props = {
            Lifetime = NumberRange.new(0.4, 0.9),
            Speed = NumberRange.new(1, 3),
            SpreadAngle = Vector2.new(180, 180),
            Acceleration = Vector3.new(0, -5, 0),
            Drag = 2,
            Rotation = NumberRange.new(0, 90),
            Size = numberSequence({ { 0, 0.32 }, { 1, 0 } }),
            LightEmission = 1,
            Brightness = 2,
        },
    },
}

Styles.Cosmos = {
    Layers = {
        { Texture = "cosmos", Color = "Nebula", Width = 0.85, Scroll = 0.6, LightEmission = 0.6, Brightness = 1.6 },
        { Texture = "startrail", Color = "Stars", Width = 0.3, Scroll = 1.5, Transparency = 0.2, LightEmission = 1, Brightness = 1.4 },
    },
    Shed = {
        {
            Texture = "sparkle", Color = "Stars", PerStud = 0.3, Rate = 0.3,
            Props = {
                Lifetime = NumberRange.new(0.8, 1.5),
                Speed = NumberRange.new(0.1, 0.4),
                SpreadAngle = Vector2.new(180, 180),
                Rotation = NumberRange.new(0, 90),
                Size = numberSequence({ { 0, 0 }, { 0.3, 0.3 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.8,
            },
        },
        {
            Texture = "ring", Color = "Rings", PerStud = 0.05, Rate = 0,
            Props = {
                Lifetime = NumberRange.new(0.8, 1.2),
                Speed = NumberRange.new(0),
                Size = numberSequence({ { 0, 0 }, { 1, 1.6 } }),
                Transparency = numberSequence({ { 0, 0.3 }, { 1, 1 } }),
                LightEmission = 1,
                Brightness = 1.4,
            },
        },
        {
            Texture = "dot", Color = "Dust", PerStud = 0.3, Rate = 0.25,
            Props = {
                Lifetime = NumberRange.new(1, 1.6),
                Speed = NumberRange.new(0.2, 0.6),
                SpreadAngle = Vector2.new(180, 180),
                Size = numberSequence({ { 0, 0.1 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.6,
            },
        },
    },
}

Styles.Void = {
    Layers = {
        { Texture = "void", Color = "Smoke", Width = 1.1, Scroll = -0.6, Transparency = 0.1, LightEmission = 0.15, LightInfluence = 0, Brightness = 1.3 },
    },
    Shed = {
        {
            Texture = "puff", Color = "Wisps", PerStud = 0.25, Rate = 0.35,
            Props = {
                Lifetime = NumberRange.new(1.2, 2),
                Speed = NumberRange.new(0.3, 1),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, 0.8, 0),
                Rotation = NumberRange.new(0, 360),
                RotSpeed = NumberRange.new(-40, 40),
                Size = numberSequence({ { 0, 0.35 }, { 1, 1.4 } }),
                Transparency = numberSequence({ { 0, 1 }, { 0.2, 0.5 }, { 1, 1 } }),
                LightEmission = 0.1,
                Brightness = 1.3,
            },
        },
        {
            Texture = "dot", Color = "Embers", PerStud = 0.3, Rate = 0.25,
            Props = {
                Lifetime = NumberRange.new(0.8, 1.5),
                Speed = NumberRange.new(0.5, 1.5),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, 1, 0),
                Size = numberSequence({ { 0, 0.1 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.8,
            },
        },
    },
}

local function fire(from, to, styleName, hit, force)
    styleName = styleName or Config.Style
    local style, settings, colors = Styles[styleName], Config.Styles[styleName], Config.Colors[styleName]
    if Unloaded or (not force and not Config.Enabled) or not style or not settings or not colors then return end
    local length = (to - from).Magnitude
    if length < 0.1 then return end

    local scale = (settings.Width or 1) * (Config.Width or 1)
    local lifeScale = math.clamp(tonumber(Config.Lifetime) or 1, 0.1, 5)
    local frame = CFrame.lookAt(from, to)
    local travel = settings.Speed == math.huge and 0 or length / settings.Speed
    local fadeStart = travel + (settings.Linger or 0.4) * lifeScale
    local finished = fadeStart + (settings.Fade or 0.5) * lifeScale
    local pieces = Config.Pieces

    local model = create("Model", { Name = styleName, Parent = Container })
    local anchor = newPart("Tracer", Vector3.one, model)
    anchor.CFrame = frame
    local tip = create("Attachment", { Parent = anchor })

    local function newBeam(layer, a0, a1, width0, width1)
        return create("Beam", {
            Attachment0 = a0,
            Attachment1 = a1,
            Texture = Textures[layer.Texture],
            TextureMode = Enum.TextureMode.Wrap,
            TextureLength = 1,
            TextureSpeed = layer.Scroll or 0,
            Width0 = width0,
            Width1 = width1,
            Segments = layer.Curve and 16 or 1,
            FaceCamera = true,
            Color = ColorSequence.new(colorList(colors[layer.Color])[1]),
            LightEmission = layer.LightEmission or 1,
            LightInfluence = layer.LightInfluence or 0,
            Brightness = layer.Brightness or 1,
            Parent = anchor,
        })
    end

    local ribbons, strands, bolt = {}, {}, nil
    for _, layer in style.Layers do
        local width = layer.Width * scale
        if layer.Chain then
            local count = math.max(2, math.ceil(length / style.Chain.Spacing))
            bolt = { Nodes = {}, Beams = {}, Forks = {}, Layer = layer }
            for i = 0, count do
                bolt.Nodes[i] = create("Attachment", { Position = Vector3.new(0, 0, -length * i / count), Parent = anchor })
            end
            for i = 1, count do
                table.insert(bolt.Beams, newBeam(layer, bolt.Nodes[i - 1], bolt.Nodes[i], width * taper((i - 1) / count), width * taper(i / count)))
            end
            for _ = 1, style.Chain.Forks do
                local a0 = create("Attachment", { Parent = anchor })
                local a1 = create("Attachment", { Parent = anchor })
                table.insert(bolt.Forks, { A0 = a0, A1 = a1, Beam = newBeam(layer, a0, a1, width * 0.4, width * 0.05) })
            end
        elseif layer.Curve then
            local a0 = create("Attachment", { Parent = anchor })
            local a1 = create("Attachment", { Parent = anchor })
            table.insert(strands, { A0 = a0, A1 = a1, Layer = layer, Beam = newBeam(layer, a0, a1, width * 0.3, width * 0.3) })
        else
            local ribbon = { Layer = layer, Width = width, Nodes = {}, Beams = {}, Shift = Vector3.zero }
            for k = 0, pieces do
                ribbon.Nodes[k] = create("Attachment", { Parent = anchor })
            end
            for k = 1, pieces do
                ribbon.Beams[k] = newBeam(layer, ribbon.Nodes[k - 1], ribbon.Nodes[k], width * taper((k - 1) / pieces), width * taper(k / pieces))
            end
            table.insert(ribbons, ribbon)
        end
    end

    local function jitterBolt()
        local nodes, count = bolt.Nodes, #bolt.Nodes
        for i = 1, count - 1 do
            local amount = style.Chain.Jitter * scale * math.sin(math.pi * i / count) ^ 0.5
            nodes[i].Position = Vector3.new(rng:NextNumber(-amount, amount), rng:NextNumber(-amount, amount), -length * i / count)
        end
        for _, fork in bolt.Forks do
            local on = rng:NextNumber() < 0.7
            fork.Beam.Enabled = on
            if on then
                local base = nodes[rng:NextInteger(1, count - 1)].Position
                local side = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), 0).Unit
                fork.A0.Position = base
                fork.A1.Position = base + side * rng:NextNumber(0.8, 2) * scale + Vector3.new(0, 0, -rng:NextNumber(0.5, 1.5))
            end
        end
    end

    local segments = {}
    local segmentCount = math.clamp(math.ceil(length / 4), 1, 14)
    local segmentLength = length / segmentCount
    for i = 1, segmentCount do
        local u = (i - 0.5) / segmentCount
        local profile = taper(u)
        local part = newPart("Shed", Vector3.new(0.3 * scale * profile, 0.3 * scale * profile, segmentLength), model)
        part.CFrame = frame * CFrame.new(0, 0, -segmentLength * (i - 0.5))
        local emitters = {}
        for _, shed in style.Shed or {} do
            local list = shed.Gradient and { false } or colorList(colors[shed.Color])
            for _, color in list do
                local props = table.clone(shed.Props)
                props.Texture = Textures[shed.Texture]
                props.Color = shed.Gradient and ColorSequence.new(colors[shed.Gradient[1]], colors[shed.Gradient[2]]) or ColorSequence.new(color)
                props.Size = scaleSequence(props.Size, scale * (0.35 + 0.65 * profile))
                props.Shape = Enum.ParticleEmitterShape.Box
                props.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
                props.Rate = shed.Rate * segmentLength * profile / #list
                props.Enabled = false
                props.LightInfluence = props.LightInfluence or 0
                props.Parent = part
                table.insert(emitters, { Emitter = create("ParticleEmitter", props), Count = shed.PerStud * segmentLength * profile / #list })
            end
        end
        segments[i] = { Pass = travel * u, Emitters = emitters }
    end

    local trail
    if style.Trail and travel > 0 then
        local props = table.clone(style.Trail.Props)
        props.Texture = Textures[style.Trail.Texture]
        props.Color = ColorSequence.new(colorList(colors[style.Trail.Color])[1])
        props.Size = scaleSequence(props.Size, scale)
        props.Rate = style.Trail.Rate
        props.LightInfluence = props.LightInfluence or 0
        props.Parent = tip
        trail = create("ParticleEmitter", props)
    end

    local impacted, lastJitter, lastShift = false, -math.huge, -math.huge
    heartbeat(function(_, elapsed)
        local d = travel > 0 and math.min(elapsed / travel, 1) * length or length
        local f = math.clamp((elapsed - fadeStart) / settings.Fade, 0, 1)
        local tailZ = -d * 0.8 * f * f
        local span = math.max(d + tailZ, 0.01)
        tip.Position = Vector3.new(0, 0, -d)
        local transparencyOf = function(base)
            return NumberSequence.new(base + (1 - base) * f)
        end
        local thin = 1 - 0.5 * f

        if elapsed - lastShift >= 0.06 then
            lastShift = elapsed
            for _, ribbon in ribbons do
                local amount = (ribbon.Layer.Shift or 0) * scale
                ribbon.Shift = amount > 0 and Vector3.new(rng:NextNumber(-amount, amount), rng:NextNumber(-amount, amount), 0) or Vector3.zero
            end
        end
        for _, ribbon in ribbons do
            local layer = ribbon.Layer
            local pieceLength = span / pieces
            local tile = ribbon.Width * TextureAspect[layer.Texture]
            local repeats = math.max(1, math.floor(pieceLength / tile + 0.5))
            for k = 0, pieces do
                local u = k / pieces
                ribbon.Nodes[k].Position = Vector3.new(0, 0, tailZ - span * u) + ribbon.Shift * taper(u)
            end
            local transparency = transparencyOf(layer.Transparency or 0)
            for k, beam in ribbon.Beams do
                beam.TextureLength = math.max(pieceLength / repeats, 0.05)
                beam.Transparency = transparency
                beam.Width0 = ribbon.Width * taper((k - 1) / pieces) * thin
                beam.Width1 = ribbon.Width * taper(k / pieces) * thin
            end
        end
        for _, strand in strands do
            local layer = strand.Layer
            local angle = elapsed * layer.Spin + layer.Phase
            strand.A0.CFrame = CFrame.new(0, 0, tailZ) * CFrame.Angles(0, 0, angle)
            strand.A1.CFrame = CFrame.new(0, 0, -d) * CFrame.Angles(0, 0, angle)
            local curve = math.min(layer.Curve * scale, span / 3)
            strand.Beam.CurveSize0, strand.Beam.CurveSize1 = curve, curve
            strand.Beam.Transparency = transparencyOf(layer.Transparency or 0)
        end
        if bolt then
            if f < 1 and elapsed - lastJitter >= style.Chain.Interval then
                lastJitter = elapsed
                jitterBolt()
            end
            local transparency = transparencyOf(bolt.Layer.Transparency or 0)
            for _, beam in bolt.Beams do
                beam.Transparency = transparency
            end
            for _, fork in bolt.Forks do
                fork.Beam.Transparency = transparency
            end
        end

        for _, segment in segments do
            if not segment.Passed and elapsed >= segment.Pass then
                segment.Passed = true
                for _, e in segment.Emitters do
                    local count = math.floor(e.Count + rng:NextNumber())
                    if count > 0 then
                        e.Emitter:Emit(count)
                    end
                    e.Emitter.Enabled = e.Emitter.Rate > 0
                end
            end
            if not segment.Stopped and elapsed >= fadeStart + settings.Fade * 0.4 then
                segment.Stopped = true
                for _, e in segment.Emitters do
                    e.Emitter.Enabled = false
                end
            end
        end

        if not impacted and elapsed >= travel then
            impacted = true
            if trail then
                trail.Enabled = false
            end

            if hit == true then
                local hitFx = env.HitEffects
                if hitFx and hitFx.Config and hitFx.Config.Enabled and hitFx.Config.OnDamage ~= false and hitFx.Play then
                    local style = styleName or hitFx.Config.Style
                    task.defer(function()
                        pcall(hitFx.Play, style, to)
                    end)
                end
            end
        end

        if elapsed >= finished then
            for _, beam in anchor:GetChildren() do
                if beam:IsA("Beam") then
                    beam.Enabled = false
                end
            end
            task.delay(3.6, model.Destroy, model)
            return false
        end
    end)
    return finished
end

local function segmentTravel(from, to, styleName)
    styleName = styleName or Config.Style
    local settings = Config.Styles[styleName]
    if not settings then
        return 0
    end
    local length = (to - from).Magnitude
    if length < 0.1 then
        return 0
    end
    if settings.Speed == math.huge or not settings.Speed or settings.Speed <= 0 then
        return 0
    end
    return length / settings.Speed
end

local function firePath(points, styleName, hit, force)
    if Unloaded or (not force and not Config.Enabled) or type(points) ~= "table" or #points < 2 then
        return
    end
    styleName = styleName or Config.Style
    local cleaned = {}
    for i = 1, #points do
        local p = points[i]
        if typeof(p) == "Vector3" and p.X == p.X and p.Y == p.Y and p.Z == p.Z then
            local prev = cleaned[#cleaned]
            if not prev or (p - prev).Magnitude >= 0.1 then
                cleaned[#cleaned + 1] = p
            end
        end
    end
    if #cleaned < 2 then
        return
    end

    local function step(index)
        if Unloaded or (not force and not Config.Enabled) or index >= #cleaned then
            return
        end
        local from, to = cleaned[index], cleaned[index + 1]
        local isLast = index + 1 >= #cleaned
        fire(from, to, styleName, isLast and hit or nil, force)
        if index + 1 < #cleaned then
            local delay = segmentTravel(from, to, styleName)
            if delay <= 0 then
                step(index + 1)
            else
                task.delay(delay, function()
                    step(index + 1)
                end)
            end
        end
    end
    step(1)
end

local function pathTravel(points, styleName)
    if type(points) ~= "table" or #points < 2 then
        return 0
    end
    local total = 0
    for i = 1, #points - 1 do
        total += segmentTravel(points[i], points[i + 1], styleName)
    end
    return total
end

local function main()
    loadTextures()
    Container = create("Folder", { Name = "Tracers", Parent = workspace.CurrentCamera })

    task.spawn(function()
        local index, flip = 0, false
        while not Unloaded do
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if Config.Demo and root then
                index = index % #Config.DemoStyles + 1
                flip = not flip
                local half = Config.DemoSpan / 2
                local height = rng:NextNumber(0.5, 3)
                local a = root.CFrame * Vector3.new(-half, height, -Config.DemoDistance)
                local b = root.CFrame * Vector3.new(half, height + rng:NextNumber(-1.5, 1.5), -Config.DemoDistance - rng:NextNumber(-4, 4))
                if flip then
                    a, b = b, a
                end
                local ok, err = pcall(fire, a, b, Config.DemoStyles[index])
                if not ok then
                    warn(`[Tracers] {err}`)
                end
            end
            task.wait(Config.DemoInterval)
        end
    end)

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    table.insert(Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not Config.Enabled or not Config.OnShoot or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local character = LocalPlayer.Character
        local tool = character and character:FindFirstChildOfClass("Tool")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not tool or not root then return end
        local handle = tool:FindFirstChild("Handle")
        local from = handle and handle:IsA("BasePart") and handle.Position or root.Position
        local mouse = UserInputService:GetMouseLocation()
        local ray = workspace.CurrentCamera:ViewportPointToRay(mouse.X, mouse.Y)
        rayParams.FilterDescendantsInstances = { character, Container }
        local hit = workspace:Raycast(ray.Origin, ray.Direction * Config.MaxDistance, rayParams)
        fire(from, hit and hit.Position or ray.Origin + ray.Direction * Config.MaxDistance, Config.Style, hit and hit.Instance)
    end))

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
    local okModules, modules = pcall(findModules)
    modules = okModules and modules or nil

    local lastHitSoundAt = 0
    local function playHitSound(force)
        if not force and not Config.HitSounds then
            return false
        end
        local now = os.clock()
        if now - lastHitSoundAt < 0.035 then
            return false
        end
        lastHitSoundAt = now
        local id = Config.HitSoundIds and Config.HitSoundIds[Config.HitSound]
        if type(id) ~= "string" or id == "" then
            return false
        end
        local sound = Instance.new("Sound")
        sound.Name = "TapologyHitSound"
        sound.SoundId = id
        sound.Volume = math.clamp(tonumber(Config.HitSoundVolume) or 1, 0, 5)
        sound.PlaybackSpeed = math.clamp(tonumber(Config.HitSoundPitch) or 1, 0.1, 3)
        sound.Looped = false
        sound.PlayOnRemove = false
        sound.Parent = SoundService
        local played = false
        if typeof(SoundService.PlayLocalSound) == "function" then
            played = pcall(function()
                SoundService:PlayLocalSound(sound)
            end)
        end
        if not played then
            played = pcall(function()
                sound:Play()
            end)
        else

            pcall(function()
                sound:Play()
            end)
        end
        task.delay(4, function()
            if sound then
                sound:Destroy()
            end
        end)
        return played
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

    local function resolveEntry(player)
        local rep = modules and modules.ReplicationInterface
        if not (player and rep and rep.getEntry) then
            return nil
        end
        local ok, entry = pcall(rep.getEntry, rep, player)
        if ok then
            return entry
        end
        ok, entry = pcall(rep.getEntry, player)
        return ok and entry or nil
    end

    local armedHits = {}
    local function notifyHit(player, part)
        if Config.HitSounds then
            playHitSound(true)
        end
        if Config.HitLogs then
            local rage = env.Rage
            if rage and rage.LogHit then
                rage.LogHit(player.Name, part)
            else
                local ui = env.Tapology or env.Library
                if ui and ui.Notify then
                    ui:Notify(string.format("hit ( %s )%s", player.Name, part and (" · " .. tostring(part)) or ""), Config.HitLogDuration or 3.5)
                end
            end
        end
    end

    local function armManualHit(player, part)
        if not player or player == LocalPlayer then
            return
        end
        if os.clock() < (env._TapologySkipHitLogUntil or 0) then
            return
        end
        if armedHits[player] and os.clock() - armedHits[player] < 0.04 then
            return
        end
        armedHits[player] = os.clock()
        local entry = resolveEntry(player)
        local hpBefore = entryHealth(entry)
        if typeof(hpBefore) ~= "number" then
            hpBefore = 100
        end
        task.spawn(function()

            for _ = 1, 14 do
                task.wait(0.07)
                if Unloaded then
                    return
                end
                if os.clock() < (env._TapologySkipHitLogUntil or 0) then
                    return
                end
                entry = resolveEntry(player) or entry
                local hpAfter = entryHealth(entry)
                local damaged = typeof(hpAfter) == "number" and hpAfter < hpBefore - 0.15
                local dead = entry and (entry._alive == false or (typeof(hpAfter) == "number" and hpAfter <= 0))
                if damaged or dead then
                    notifyHit(player, part)
                    return
                end
                if typeof(hpAfter) == "number" then
                    hpBefore = math.min(hpBefore, hpAfter)
                end
            end
        end)
    end

    if modules and modules.BulletObject and type(modules.BulletObject.new) == "function" then
        local nextNew = modules.BulletObject.new
        modules.BulletObject.new = function(data, ...)
            if type(data) == "table" and data.onplayerhit then
                local prevHit = data.onplayerhit
                data.onplayerhit = function(...)

                    local args = table.pack(...)
                    for i = 1, args.n do
                        local value = args[i]
                        if typeof(value) == "Instance" and value:IsA("Player") then
                            armManualHit(value, nil)
                            break
                        elseif type(value) == "table" and typeof(value._player) == "Instance" then
                            armManualHit(value._player, nil)
                            break
                        end
                    end
                    return prevHit(...)
                end
                if Config.Enabled and data.position and data.velocity then
                    local from = data.position
                    local weapons = modules.WeaponControllerInterface
                    local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
                    local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
                    local barrel = weapon and weapon._barrelPart
                    if barrel then
                        from = barrel.Position + barrel.CFrame.LookVector * (barrel.Size.Z * 0.5)
                    end
                    local direction = data.velocity.Unit
                    rayParams.FilterDescendantsInstances = { workspace.CurrentCamera, Container, workspace:FindFirstChild("Ignore"), workspace:FindFirstChild("Players") }
                    local hit = workspace:Raycast(from, direction * Config.MaxDistance, rayParams)
                    local to = hit and hit.Position or (from + direction * Config.MaxDistance)
                    task.defer(fire, from, to, Config.Style, nil)
                end
            end
            return nextNew(data, ...)
        end
        table.insert(Restores, function()
            modules.BulletObject.new = nextNew
        end)
    end

    if modules and modules.NetworkClient and type(modules.NetworkClient.send) == "function" then
        local network = modules.NetworkClient
        local nextSend = network.send
        network.send = function(self, name, ...)
            if name == "bullethit" then
                local _, player, _, part = ...
                if typeof(player) == "Instance" and player:IsA("Player") then
                    armManualHit(player, part)
                end
            end
            return nextSend(self, name, ...)
        end
        table.insert(Restores, function()
            network.send = nextSend
        end)
    end

    env.Tracers = {
        Config = Config,
        Styles = (function()
            local names = {}
            for name in Config.Styles do
                table.insert(names, name)
            end
            table.sort(names)
            return names
        end)(),
        HitSounds = (function()
            local names = {}
            for name in Config.HitSoundIds do
                table.insert(names, name)
            end
            table.sort(names)
            return names
        end)(),
        StyleDefs = Styles,
        Fire = fire,
        FirePath = firePath,
        PathTravel = pathTravel,
        PlayHitSound = playHitSound,
        SetEnabled = function(on)
            Config.Enabled = on and true or false
        end,
        SetStyle = function(styleName)
            if Config.Styles[styleName] then
                Config.Style = styleName
            end
        end,

        SetColor = function(styleName, slot, color)
            Config.Colors[styleName] = Config.Colors[styleName] or {}
            Config.Colors[styleName][slot] = color
        end,
        Unload = function()
            Unloaded = true
            for _, connection in Connections do
                connection:Disconnect()
            end
            for _, restore in Restores do
                pcall(restore)
            end
            Container:Destroy()
            env.Tracers = nil
        end,
    }
end

TextureIds = {
    blossom = "rbxassetid://129556989689384",
    plasma = "rbxassetid://94136981752496",
    lightning = "rbxassetid://111593746793021",
    startrail = "rbxassetid://85942207251913",
    void = "rbxassetid://110093922567787",
    aether = "rbxassetid://90054071953795",
    flame = "rbxassetid://97446809758616",
    frost = "rbxassetid://80128546239435",
    glitch = "rbxassetid://100727003138673",
    cosmos = "rbxassetid://133771181538188",
    glowbeam = "rbxassetid://78577585159137",
    petal = "rbxassetid://91106269226329",
    dot = "rbxassetid://79451523688005",
    spark = "rbxassetid://83337948032750",
    puff = "rbxassetid://98688240512895",
    pixel = "rbxassetid://98416523570354",
    ring = "rbxassetid://130480777986951",
    sparkle = "rbxassetid://86312741349859",
    flamelet = "rbxassetid://122232318996052",
    flake = "rbxassetid://75489274996945",
}
TextureAspect = {
    blossom = 4,
    plasma = 4,
    lightning = 4,
    startrail = 4,
    void = 2,
    aether = 4,
    flame = 2.66667,
    frost = 2.66667,
    glitch = 4,
    cosmos = 2.66667,
    glowbeam = 2,
    petal = 1,
    dot = 1,
    spark = 1,
    puff = 1,
    pixel = 1,
    ring = 1,
    sparkle = 1,
    flamelet = 1,
    flake = 1,
}

do
    local okTracers, errTracers = pcall(main)
    if not okTracers then
        warn("[Tracers] main failed:", errTracers)
    end
end

end
