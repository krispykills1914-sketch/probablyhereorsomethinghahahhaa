do

local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local Config = {
    Enabled = false,
    Effect = "Dust",
    OnKill = true,
    Speed = 1,
    Scale = 1,
    Demo = false,
    DemoDistance = 10,
    DemoEffects = { "Dust", "Blossom", "Sparks", "Blackhole", "Debris", "Butterflies", "Shatter", "Glitch", "Ember", "Ascension", "Constellation" },
    DemoGap = 0.6,
    Colors = {
        Dust = { Dust = rgb(185, 228, 255), Fade = rgb(120, 175, 250) },
        Blossom = {
            Petals = { rgb(255, 190, 215), rgb(255, 160, 200), rgb(255, 225, 235), rgb(250, 140, 185) },
            Pollen = rgb(255, 240, 200),
            Flash = rgb(255, 200, 225),
        },

        Debris = { Dust = rgb(200, 195, 190), Fallback = rgb(165, 150, 135) },
        Shatter = { Glass = rgb(200, 235, 255), Sparkle = rgb(230, 245, 255), Flash = rgb(200, 230, 255) },
        Ember = {
            EmberHot = rgb(255, 200, 110), EmberCool = rgb(255, 80, 25),
            Ash = rgb(85, 78, 74), AshFade = rgb(55, 52, 50), Smoke = rgb(70, 65, 62), Glow = rgb(255, 140, 60),
        },
        Sparks = {
            Hot = rgb(255, 250, 225), Mid = rgb(255, 195, 80), Cool = rgb(255, 90, 30),
            Arc = rgb(255, 225, 160), Smoke = rgb(90, 85, 80), Flash = rgb(255, 200, 120),
        },
        Blackhole = {
            Body = rgb(220, 205, 255), Pulled = rgb(120, 60, 220),
            Disk = rgb(170, 90, 255), DiskInner = rgb(255, 170, 90), Ring = rgb(230, 210, 255), Core = rgb(0, 0, 0),
        },
        Glitch = { Main = rgb(120, 205, 225), Red = rgb(230, 40, 95), Cyan = rgb(40, 210, 240), Scan = rgb(120, 255, 240) },
        Butterflies = {
            Wings = { rgb(95, 170, 255), rgb(170, 120, 255), rgb(90, 230, 210) },
            Glitter = rgb(220, 235, 255),
        },
        Ascension = {
            Body = rgb(255, 238, 190), Fade = rgb(255, 215, 130), Pillar = rgb(255, 235, 180),
            Halo = rgb(255, 220, 140), Feathers = rgb(255, 250, 235),
        },
        Constellation = {
            Nebula = { rgb(90, 70, 220), rgb(190, 80, 210), rgb(50, 150, 230) },
            Dust = rgb(110, 125, 255), DustFade = rgb(200, 120, 255),
            Stars = rgb(230, 240, 255), Lines = rgb(150, 195, 255), Comet = rgb(205, 230, 255),
        },
    },
    Timing = {
        Dust = { Hold = 0.9, Sweep = 1.4 },
        Ember = { Hold = 0.6, Sweep = 1.3 },
        Blossom = { Gather = 0.35, Petals = 110, Linger = 2.5, Fade = 1.2 },
        Debris = { Appear = 0.25, Hold = 0.5, Sweep = 0.7, Drift = 2.2, Fade = 1.3 },
        Shatter = { Appear = 0.2, Hold = 0.35, Linger = 1.8, Fade = 1 },
        Sparks = { Crackle = 0.8 },
        Blackhole = { Form = 0.5, Pull = 1.9, Fall = 0.6, Collapse = 0.4 },
        Glitch = { Appear = 0.3, Glitch = 0.9, Scan = 1 },
        Butterflies = { Hold = 0.7, Sweep = 0.9 },
        Ascension = { Rise = 0.5, Hold = 0.6, Sweep = 1.2 },

        Constellation = { Link = 0.16, Hold = 0.8, Drift = 1.4, Dive = 40, Wave = 14, Scatter = 1.5 },
    },
    TextureFolder = "killeffect_textures",
}

local TextureIds

local env = getgenv and getgenv() or _G
if env.KillEffects then
    env.KillEffects.Unload()
end

local LocalPlayer = Players.LocalPlayer
local base64decode = (crypt and crypt.base64decode) or base64_decode or (base64 and base64.decode)
local rng = Random.new()

local Textures = {}
local Effects = {}
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

local function solidPart(name, props)
    props.Name = name
    props.Anchored = true
    props.CanCollide = false
    props.CanQuery = false
    props.CanTouch = false
    props.CastShadow = false
    return create("Part", props)
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

local function shuffle(list)
    for i = #list, 2, -1 do
        local j = rng:NextInteger(1, i)
        list[i], list[j] = list[j], list[i]
    end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function groundBelow(position)
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character, Container }
    local hit = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -60, 0), rayParams)
    return hit and hit.Position.Y or position.Y - 3
end

local function randomRotation()
    return CFrame.Angles(rng:NextNumber(0, math.pi * 2), rng:NextNumber(0, math.pi * 2), rng:NextNumber(0, math.pi * 2))
end

local function burst(position, count, props)
    local part = newPart("Burst", Vector3.one * (props.Spread or 0.5), Container)
    part.CFrame = CFrame.new(position)
    props.Spread = nil
    props.Texture = props.Texture or Textures.dot
    props.Enabled = false
    props.LightInfluence = props.LightInfluence or 0
    props.Parent = part
    create("ParticleEmitter", props):Emit(count)
    task.delay(props.Lifetime.Max + 0.2, part.Destroy, part)
end

local function flash(position, color, brightness, range, duration)
    local part = newPart("Flash", Vector3.one, Container)
    part.CFrame = CFrame.new(position)
    local light = create("PointLight", { Color = color, Brightness = brightness, Range = range, Shadows = false, Parent = part })
    TweenService:Create(light, TweenInfo.new(duration, Enum.EasingStyle.Quad), { Brightness = 0 }):Play()
    task.delay(duration, part.Destroy, part)
end

local function flatImage(part, texture, color, transparency, brightness)
    local images = {}
    for _, face in { Enum.NormalId.Top, Enum.NormalId.Bottom } do
        local gui = create("SurfaceGui", {
            Face = face,
            LightInfluence = 0,
            Brightness = brightness or 2,
            SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
            PixelsPerStud = 40,
            Parent = part,
        })
        table.insert(images, create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = texture,
            ImageColor3 = color,
            ImageTransparency = transparency or 0,
            Parent = gui,
        }))
    end
    return images
end

local function setImages(images, props)
    for _, image in images do
        for key, value in props do
            image[key] = value
        end
    end
end

local function shockwave(cframe, color, from, to, duration, brightness)
    local part = newPart("Shockwave", Vector3.new(from, 0.02, from), Container)
    part.CFrame = cframe
    local images = flatImage(part, Textures.ring, color, 0.1, brightness)
    TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad), { Size = Vector3.new(to, 0.02, to) }):Play()
    for _, image in images do
        TweenService:Create(image, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { ImageTransparency = 1 }):Play()
    end
    task.delay(duration, part.Destroy, part)
end

local function findRoot(source)
    if not source then
        return nil
    end
    return source:FindFirstChild("HumanoidRootPart")
        or source:FindFirstChild("Torso")
        or source:FindFirstChild("UpperTorso")
        or source.PrimaryPart
        or source:FindFirstChildWhichIsA("BasePart", true)
end

local BODY_NAMES = {
    Head = true,
    Torso = true,
    ["Left Arm"] = true,
    ["Right Arm"] = true,
    ["Left Leg"] = true,
    ["Right Leg"] = true,
    UpperTorso = true,
    LowerTorso = true,
    LeftUpperArm = true,
    LeftLowerArm = true,
    LeftHand = true,
    RightUpperArm = true,
    RightLowerArm = true,
    RightHand = true,
    LeftUpperLeg = true,
    LeftLowerLeg = true,
    LeftFoot = true,
    RightUpperLeg = true,
    RightLowerLeg = true,
    RightFoot = true,
}

local function isBodyPartName(name)
    if BODY_NAMES[name] then
        return true
    end
    return name:find("Arm")
        or name:find("Leg")
        or name:find("Hand")
        or name:find("Foot")
        or name:find("Torso")
        or name == "Head"
end

local function bodyParts(source)
    local root = findRoot(source)
    local preferred = {}
    local parts = {}
    for _, descendant in source:GetDescendants() do
        if not descendant:IsA("BasePart") or descendant == root then
            continue
        end

        local named = isBodyPartName(descendant.Name)
        local visible = descendant.Transparency < 1
        if descendant.Size.Magnitude <= 0.05 and not named then
            continue
        end
        if named then
            table.insert(preferred, descendant)
        elseif visible then
            local parent = descendant.Parent
            local isBody = parent == source or (parent and (parent:IsA("Accessory") or parent:IsA("Model")))
            if isBody then
                table.insert(parts, descendant)
            end
        end
    end
    if #preferred > 0 then
        return preferred, root
    end
    if #parts > 0 then
        return parts, root
    end
    for _, descendant in source:GetDescendants() do
        if descendant:IsA("BasePart") and descendant ~= root and descendant.Size.Magnitude > 0.05 then
            table.insert(parts, descendant)
        end
    end
    return parts, root
end

local function bodyPieces(source, target)
    local parts, root = bodyParts(source)
    root = root or findRoot(source)
    if not root then
        return {}
    end
    local scale = math.clamp(Config.Scale or 1, 0.35, 3)
    local pieces = {}
    for _, part in parts do
        local size = part.Size * scale
        table.insert(pieces, {
            CFrame = target * root.CFrame:ToObjectSpace(part.CFrame),
            Size = size,
            Color = part.Color,
            Textured = part:FindFirstChildOfClass("SurfaceAppearance") ~= nil or part:IsA("MeshPart") and part.TextureID ~= "",
            Volume = size.X * size.Y * size.Z,
        })
    end
    return pieces
end

local queryParams = RaycastParams.new()
queryParams.FilterType = Enum.RaycastFilterType.Include

local function surfacePoints(source, target, perArea, maxTotal)
    local parts, root = bodyParts(source)
    root = root or findRoot(source)
    if not root then
        return {}
    end
    local toTarget = target * root.CFrame:Inverse()

    local totalArea = 0
    for _, part in parts do
        local s = part.Size
        totalArea += 2 * (s.X * s.Y + s.Y * s.Z + s.X * s.Z)
    end
    local density = math.min(perArea, maxTotal / math.max(totalArea, 1))

    local points = {}
    for _, part in parts do
        local size = part.Size
        local area = 2 * (size.X * size.Y + size.Y * size.Z + size.X * size.Z)
        local wanted = math.max(4, math.floor(area * density))
        local reach = size.Magnitude
        queryParams.FilterDescendantsInstances = { part }

        local found, tries = 0, 0
        while found < wanted and tries < wanted * 3 do
            tries += 1
            local direction = rng:NextUnitVector()
            local aim = part.CFrame * Vector3.new(rng:NextNumber(-0.35, 0.35) * size.X, rng:NextNumber(-0.35, 0.35) * size.Y, rng:NextNumber(-0.35, 0.35) * size.Z)
            local hit = workspace:Raycast(aim + direction * reach, -direction * reach * 1.2, queryParams)
            if hit then
                local point = hit.Position
                if rng:NextNumber() < 0.3 then
                    point = point:Lerp(aim, rng:NextNumber(0.15, 0.6))
                end
                table.insert(points, toTarget * point)
                found += 1
            end
        end

        if found == 0 then
            for _ = 1, wanted do
                table.insert(points, toTarget * (part.CFrame * Vector3.new(rng:NextNumber(-0.5, 0.5) * size.X, rng:NextNumber(-0.5, 0.5) * size.Y, rng:NextNumber(-0.5, 0.5) * size.Z)))
            end
        end
    end
    return points
end

local function bounds(pieces)
    local highest, lowest, center, volume = -math.huge, math.huge, Vector3.zero, 0
    for _, piece in pieces do
        local position = piece.CFrame.Position
        highest = math.max(highest, position.Y + piece.Size.Y / 2)
        lowest = math.min(lowest, position.Y - piece.Size.Y / 2)
        center += position * piece.Volume
        volume += piece.Volume
    end
    return highest, lowest, center / math.max(volume, 1e-3), volume
end

local function pointsCenter(points)
    local sum = Vector3.zero
    for _, point in points do
        sum += point
    end
    return sum / math.max(#points, 1)
end

local function randomPoint(piece)
    local size = piece.Size
    return piece.CFrame * Vector3.new(rng:NextNumber(-0.5, 0.5) * size.X, rng:NextNumber(-0.5, 0.5) * size.Y, rng:NextNumber(-0.5, 0.5) * size.Z)
end

local function weightedPiece(pieces, totalVolume)
    local pick = rng:NextNumber(0, totalVolume)
    for _, piece in pieces do
        pick -= piece.Volume
        if pick <= 0 then
            return piece
        end
    end
    return pieces[#pieces]
end

local function sweepDelay(piece, highest, lowest, sweep, upward)
    local height = math.max(highest - lowest, 1)
    local position, half = piece.CFrame.Position.Y, piece.Size.Y / 2
    local fraction = upward and (position - half - lowest) / height or (highest - position - half) / height
    return math.clamp(fraction, 0, 1) * sweep
end

local function split(points, shares)
    local copy = table.clone(points)
    shuffle(copy)
    local result, index = {}, 1
    for i, share in shares do
        local count = i == #shares and #copy - index + 1 or math.floor(#copy * share)
        result[i] = table.move(copy, index, index + count - 1, 1, {})
        index += count
    end
    return result
end

local function pointCloud(model, points, o)
    local count = o.Groups or 8
    local groups = {}
    for i = 1, count do
        groups[i] = { Index = i, Points = {}, Emitters = {} }
    end

    local group = o.Group
    if not group then
        local high, low = -math.huge, math.huge
        for _, point in points do
            high, low = math.max(high, point.Y), math.min(low, point.Y)
        end
        local span = math.max(high - low, 0.01)
        group = function(point)
            local f = (high - point.Y) / span
            if o.Upward then
                f = 1 - f
            end
            return math.clamp(math.floor(f * count) + 1, 1, count)
        end
    end
    for _, point in points do
        table.insert(groups[group(point)].Points, point)
    end

    local anchor = newPart("Cloud", Vector3.one, model)
    anchor.CFrame = CFrame.new(points[1] or Vector3.zero)
    local perGroup = o.PerGroup or 4
    local longest = 0
    for _, g in groups do
        shuffle(g.Points)
        longest = math.max(longest, #g.Points)
        for _ = 1, perGroup do
            local props = table.clone(o.Props)
            if o.GroupProps then
                for key, value in o.GroupProps(g.Index) do
                    props[key] = value
                end
            end
            props.Enabled = false
            props.TimeScale = 0
            props.LightInfluence = props.LightInfluence or 0
            local attachment = create("Attachment", { Parent = anchor })
            props.Parent = attachment
            table.insert(g.Emitters, { Attachment = attachment, Emitter = create("ParticleEmitter", props) })
        end
    end

    local cloud = { Groups = groups, FormTime = math.ceil(longest / perGroup) / 60 }

    function cloud.Emit()
        task.spawn(function()
            local frame = 0
            while frame * perGroup < longest and not Unloaded and model.Parent do
                local ready = {}
                for _, g in groups do
                    for k, slot in g.Emitters do
                        local point = g.Points[frame * perGroup + k]
                        if point then
                            slot.Attachment.WorldPosition = point
                            if o.Place then
                                o.Place(slot, point)
                            end
                            table.insert(ready, slot.Emitter)
                        end
                    end
                end
                RunService.RenderStepped:Wait()
                for _, emitter in ready do
                    emitter:Emit(1)
                end
                frame += 1
            end
        end)
        return cloud.FormTime
    end

    function cloud.Release(index, ramp)
        local g = groups[index]
        heartbeat(function(_, elapsed)
            local p = math.min(elapsed / math.max(ramp, 1e-3), 1)
            for _, slot in g.Emitters do
                slot.Emitter.TimeScale = p * p
            end
            return p < 1
        end)
    end

    function cloud.Sweep(duration, ramp, randomOrder)
        local order = {}
        for i = 1, count do
            order[i] = i
        end
        if randomOrder then
            shuffle(order)
        end
        for position, index in order do
            task.delay((position - 1) / math.max(count - 1, 1) * duration, cloud.Release, index, ramp)
        end
    end

    return cloud
end

local function simulate(bodies, params)
    local groundY = params.GroundY
    heartbeat(function(dt, elapsed)
        local alive = false
        for _, body in bodies do
            if body.Done then continue end
            alive = true
            if elapsed < (body.Release or 0) then continue end

            if not body.Resting then
                local velocity = body.Velocity + Vector3.new(0, -params.Gravity * dt, 0)
                velocity *= math.exp(-params.Drag * dt)
                if params.Flutter then
                    local s = body.Seed
                    velocity += Vector3.new(math.sin(elapsed * 3.1 + s), 0, math.cos(elapsed * 2.7 + s)) * params.Flutter * dt
                end
                body.Velocity = velocity
                body.Spin *= math.exp(-(params.SpinDrag or 0) * dt)
                body.Rotation *= CFrame.Angles(body.Spin.X * dt, body.Spin.Y * dt, body.Spin.Z * dt)
                local position = body.Position + velocity * dt

                if groundY and position.Y <= groundY + body.Rest then
                    position = Vector3.new(position.X, groundY + body.Rest, position.Z)
                    if params.Bounce and velocity.Y < -5 and (body.Bounces or 0) < 2 then
                        body.Bounces = (body.Bounces or 0) + 1
                        body.Velocity = Vector3.new(velocity.X * 0.55, -velocity.Y * params.Bounce, velocity.Z * 0.55)
                        body.Spin *= 0.5
                    else
                        local _, yaw = body.Rotation:ToEulerAnglesYXZ()
                        body.Rotation = CFrame.Angles(0, yaw, 0) * (body.Flat or CFrame.identity)
                            * CFrame.Angles(rng:NextNumber(-0.08, 0.08), 0, rng:NextNumber(-0.08, 0.08))
                        body.Resting = true
                        body.FadeAt = body.FadeAt or elapsed + params.Linger
                    end
                end
                body.Position = position
                body.Part.CFrame = CFrame.new(position) * body.Rotation
            end

            if body.FadeAt and elapsed >= body.FadeAt then
                local p = math.min((elapsed - body.FadeAt) / params.Fade, 1)
                body.SetFade(p)
                if p >= 1 then
                    body.Done = true
                    body.Part:Destroy()
                end
            end
        end
        return alive
    end)
end

function Effects.Dust(ctx)
    local colors, timing = Config.Colors.Dust, Config.Timing.Dust
    local target = ctx.Target
    local breeze = -target.LookVector * 0.7 + target.RightVector * 0.4 + target.UpVector * 0.5
    local cloud = pointCloud(ctx.Model, surfacePoints(ctx.Source, target, 30, 1300), {
        Groups = 10,
        PerGroup = 6,
        Props = {
            Texture = Textures.dot,
            Lifetime = NumberRange.new(2.2, 3.4),
            Speed = NumberRange.new(0.4, 2.2),
            SpreadAngle = Vector2.new(180, 180),
            Acceleration = breeze,
            Drag = 0.55,
            Size = numberSequence({ { 0, 0.1 }, { 0.4, 0.2 }, { 1, 0.46 } }),
            Transparency = numberSequence({ { 0, 0.05 }, { 0.45, 0.3 }, { 1, 1 } }),
            Color = colorSequence({ { 0, colors.Dust }, { 1, colors.Fade } }),
            LightEmission = 0.25,
            LightInfluence = 0.25,
            Brightness = 1.2,
        },
    })
    local form = cloud.Emit()
    task.delay(form + timing.Hold, cloud.Sweep, timing.Sweep, 0.45)
    return form + timing.Hold + timing.Sweep + 4
end

function Effects.Ember(ctx)
    local colors, timing = Config.Colors.Ember, Config.Timing.Ember
    local target = ctx.Target
    local points = surfacePoints(ctx.Source, target, 26, 1100)
    local parts = split(points, { 0.55, 0.45 })
    local function cloudOf(subset, props)
        return pointCloud(ctx.Model, subset, { Groups = 9, PerGroup = 4, Upward = true, Props = props })
    end
    local embers = cloudOf(parts[1], {
        Texture = Textures.ember,
        Lifetime = NumberRange.new(1.6, 2.8),
        Speed = NumberRange.new(0.4, 1.6),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = target.UpVector * 3.4,
        Drag = 0.8,
        Size = numberSequence({ { 0, 0.12 }, { 0.6, 0.08 }, { 1, 0 } }),
        Transparency = numberSequence({ { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } }),
        Color = colorSequence({ { 0, colors.EmberHot }, { 1, colors.EmberCool } }),
        LightEmission = 1,
        Brightness = 3,
    })
    local ash = cloudOf(parts[2], {
        Texture = Textures.dot,
        Lifetime = NumberRange.new(1.8, 3),
        Speed = NumberRange.new(0.3, 1.2),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = target.UpVector * -2.4 + target.RightVector * 0.5,
        Drag = 0.9,
        Size = numberSequence({ { 0, 0.11 }, { 1, 0.2 } }),
        Transparency = numberSequence({ { 0, 0.1 }, { 0.6, 0.4 }, { 1, 1 } }),
        Color = colorSequence({ { 0, colors.Ash }, { 1, colors.AshFade } }),
        LightEmission = 0,
        LightInfluence = 1,
    })
    local form = math.max(embers.Emit(), ash.Emit())
    local _, lowest, center = bounds(ctx.Pieces)
    task.delay(form + timing.Hold, function()
        if Unloaded then return end
        flash(Vector3.new(center.X, lowest + 1, center.Z), colors.Glow, 2.2, 16, timing.Sweep + 1)
        embers.Sweep(timing.Sweep, 0.3)
        ash.Sweep(timing.Sweep, 0.3)
        for i = 0, 4 do
            task.delay(i / 4 * timing.Sweep, function()
                burst(Vector3.new(center.X, lowest + (center.Y - lowest) * 2 * i / 4, center.Z), 6, {
                    Texture = Textures.puff,
                    Spread = 1.5,
                    Lifetime = NumberRange.new(1.8, 2.6),
                    Speed = NumberRange.new(0.3, 0.8),
                    SpreadAngle = Vector2.new(40, 40),
                    Acceleration = Vector3.new(0, 1.2, 0),
                    Rotation = NumberRange.new(0, 360),
                    RotSpeed = NumberRange.new(-30, 30),
                    Size = numberSequence({ { 0, 0.6 }, { 1, 2.4 } }),
                    Transparency = numberSequence({ { 0, 1 }, { 0.2, 0.75 }, { 1, 1 } }),
                    Color = ColorSequence.new(colors.Smoke),
                    LightInfluence = 1,
                })
            end)
        end
    end)
    return form + timing.Hold + timing.Sweep + 3.5
end

function Effects.Sparks(ctx)
    local colors, timing = Config.Colors.Sparks, Config.Timing.Sparks
    local target = ctx.Target
    local points = surfacePoints(ctx.Source, target, 22, 900)
    local center = pointsCenter(points)
    local groundY = groundBelow(center)

    local glints = pointCloud(ctx.Model, points, {
        Groups = 1,
        PerGroup = 30,
        Props = {
            Texture = Textures.glint,
            Lifetime = NumberRange.new(0.12, 0.2),
            Speed = NumberRange.new(0),
            Rotation = NumberRange.new(0, 90),
            Size = NumberSequence.new(0.22),
            Transparency = numberSequence({ { 0, 0.1 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Hot),
            LightEmission = 1,
            Brightness = 2.5,
        },
    })
    local sparks = pointCloud(ctx.Model, points, {
        Groups = 1,
        PerGroup = 30,
        Props = {
            Texture = Textures.spark,
            Orientation = Enum.ParticleOrientation.VelocityParallel,
            Lifetime = NumberRange.new(0.5, 1.1),
            Speed = NumberRange.new(8, 22),
            SpreadAngle = Vector2.new(180, 180),
            Acceleration = Vector3.new(0, -30, 0),
            Drag = 0.9,
            Size = numberSequence({ { 0, 0.4 }, { 1, 0.12 } }),
            Transparency = numberSequence({ { 0, 1 }, { 0.02, 0 }, { 0.7, 0.2 }, { 1, 1 } }),
            Color = colorSequence({ { 0, colors.Hot }, { 0.35, colors.Mid }, { 1, colors.Cool } }),
            LightEmission = 1,
            Brightness = 4,
        },
    })
    local form = math.max(glints.Emit(), sparks.Emit())

    local arcAnchor = newPart("Arcs", Vector3.one, ctx.Model)
    arcAnchor.CFrame = CFrame.new(center)
    local arcs = {}
    for i = 1, 5 do
        local a0 = create("Attachment", { Parent = arcAnchor })
        local a1 = create("Attachment", { Parent = arcAnchor })
        arcs[i] = {
            A0 = a0,
            A1 = a1,
            Beam = create("Beam", {
                Attachment0 = a0,
                Attachment1 = a1,
                Texture = Textures.arc,
                TextureMode = Enum.TextureMode.Stretch,
                Width0 = 0.35,
                Width1 = 0.35,
                Segments = 10,
                FaceCamera = true,
                Color = ColorSequence.new(colors.Arc),
                LightEmission = 1,
                LightInfluence = 0,
                Brightness = 4,
                Enabled = false,
                Parent = arcAnchor,
            }),
        }
    end
    local crackleEnd = form + timing.Crackle
    local nextJump = 0
    heartbeat(function(_, elapsed)
        if elapsed >= crackleEnd then
            for _, a in arcs do
                a.Beam.Enabled = false
            end
            return false
        end
        if elapsed >= form and elapsed >= nextJump then
            nextJump = elapsed + 0.05
            for _, a in arcs do
                local on = rng:NextNumber() < 0.65
                a.Beam.Enabled = on
                if on then
                    a.A0.WorldPosition = points[rng:NextInteger(1, #points)]
                    a.A1.WorldPosition = points[rng:NextInteger(1, #points)]
                    a.Beam.CurveSize0 = rng:NextNumber(-1.5, 1.5)
                    a.Beam.CurveSize1 = rng:NextNumber(-1.5, 1.5)
                end
            end
        end
    end)

    task.delay(crackleEnd, function()
        if Unloaded then return end
        glints.Release(1, 0.01)
        sparks.Release(1, 0.01)
        flash(center, colors.Flash, 5, 22, 0.7)
        burst(Vector3.new(center.X, groundY + 0.3, center.Z), 16, {
            Texture = Textures.puff,
            Spread = 2.5,
            Lifetime = NumberRange.new(1.5, 2.5),
            Speed = NumberRange.new(0.5, 1.5),
            SpreadAngle = Vector2.new(60, 60),
            Acceleration = Vector3.new(0, 1, 0),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-30, 30),
            Size = numberSequence({ { 0, 1 }, { 1, 3.5 } }),
            Transparency = numberSequence({ { 0, 1 }, { 0.15, 0.7 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Smoke),
            LightInfluence = 1,
        })
    end)
    return crackleEnd + 2.8
end

function Effects.Blackhole(ctx)
    local colors, timing = Config.Colors.Blackhole, Config.Timing.Blackhole
    local target = ctx.Target
    local points = surfacePoints(ctx.Source, target, 26, 1000)
    local center = pointsCenter(points)

    local fall = timing.Fall
    local reach = 0
    for _, point in points do
        reach = math.max(reach, (point - center).Magnitude)
    end
    local shells = 10
    local cloud = pointCloud(ctx.Model, points, {
        Groups = shells,
        PerGroup = 4,
        Group = function(point)
            local f = (point - center).Magnitude / math.max(reach, 0.01)
            return math.clamp(math.floor(f * shells) + 1, 1, shells)
        end,
        Place = function(slot, point)
            slot.Attachment.WorldCFrame = CFrame.lookAt(point, center)
            slot.Emitter.Speed = NumberRange.new((center - point).Magnitude / fall)
        end,
        Props = {
            Texture = Textures.dot,
            EmissionDirection = Enum.NormalId.Front,
            Lifetime = NumberRange.new(fall),
            SpreadAngle = Vector2.zero,
            Drag = 0,
            Size = numberSequence({ { 0, 0.11 }, { 0.7, 0.07 }, { 1, 0 } }),
            Transparency = numberSequence({ { 0, 0 }, { 0.85, 0.1 }, { 1, 1 } }),
            Color = colorSequence({ { 0, colors.Body }, { 0.6, colors.Pulled }, { 1, colors.Disk } }),
            LightEmission = 0.6,
            Brightness = 1.6,
        },
    })
    local form = cloud.Emit()

    local core = solidPart("Core", {
        Shape = Enum.PartType.Ball,
        Size = Vector3.one * 0.05,
        Color = colors.Core,
        Material = Enum.Material.SmoothPlastic,
        CFrame = CFrame.new(center),
        Parent = ctx.Model,
    })
    local tilt = CFrame.new(center) * CFrame.Angles(math.rad(14), 0, math.rad(-8))
    local disk = newPart("Disk", Vector3.new(0.1, 0.02, 0.1), ctx.Model)
    disk.CFrame = tilt
    local outer = flatImage(disk, Textures.swirl, colors.Disk, 0, 2.5)
    local innerDisk = newPart("InnerDisk", Vector3.new(0.1, 0.02, 0.1), ctx.Model)
    innerDisk.CFrame = tilt
    local inner = flatImage(innerDisk, Textures.swirl, colors.DiskInner, 0.2, 3)
    local lens = create("BillboardGui", { Size = UDim2.fromScale(0, 0), LightInfluence = 0, Brightness = 3, Adornee = core, Parent = core })
    local lensImage = create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Image = Textures.ring,
        ImageColor3 = colors.Ring,
        ImageTransparency = 0.2,
        Parent = lens,
    })

    local opened = form + timing.Form
    local pullEnd = opened + timing.Pull
    local finished = pullEnd + timing.Collapse
    local grow = TweenInfo.new(timing.Form, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.delay(form, function()
        if Unloaded then return end
        TweenService:Create(core, grow, { Size = Vector3.one * 1.3 }):Play()
        TweenService:Create(disk, grow, { Size = Vector3.new(7, 0.02, 7) }):Play()
        TweenService:Create(innerDisk, grow, { Size = Vector3.new(3.6, 0.02, 3.6) }):Play()
        TweenService:Create(lens, grow, { Size = UDim2.fromScale(2.6, 2.6) }):Play()
    end)
    task.delay(opened, cloud.Sweep, math.max(timing.Pull - fall * 1.55, 0.1), fall * 0.8, false)

    heartbeat(function(_, elapsed)
        if elapsed > finished then
            return false
        end
        setImages(outer, { Rotation = (elapsed * 220) % 360 })
        setImages(inner, { Rotation = (-elapsed * 380) % 360 })
        lensImage.Rotation = (elapsed * 60) % 360
        if elapsed > pullEnd then
            local p = (elapsed - pullEnd) / timing.Collapse
            local s = (1 - p) ^ 2
            core.Size = Vector3.one * 1.3 * s + Vector3.one * 0.01
            disk.Size = Vector3.new(7 * s + 0.01, 0.02, 7 * s + 0.01)
            innerDisk.Size = Vector3.new(3.6 * s + 0.01, 0.02, 3.6 * s + 0.01)
            lens.Size = UDim2.fromScale(2.6 * (1 + p * 0.6), 2.6 * (1 + p * 0.6))
            lensImage.ImageTransparency = 0.2 + 0.8 * p
        end
    end)

    task.delay(finished, function()
        if Unloaded then return end
        core.Transparency = 1
        flash(center, colors.Ring, 6, 20, 0.6)
        shockwave(tilt, colors.Disk, 1, 18, 0.7, 3)
        burst(center, 60, {
            Texture = Textures.glint,
            Lifetime = NumberRange.new(0.5, 1),
            Speed = NumberRange.new(10, 22),
            SpreadAngle = Vector2.new(180, 180),
            Drag = 3,
            Rotation = NumberRange.new(0, 90),
            Size = numberSequence({ { 0, 0.3 }, { 1, 0 } }),
            Color = colorSequence({ { 0, colors.Ring }, { 1, colors.Disk } }),
            LightEmission = 1,
            Brightness = 3,
        })
    end)
    return finished + 1.2
end

function Effects.Blossom(ctx)
    local colors, timing = Config.Colors.Blossom, Config.Timing.Blossom
    local pieces = ctx.Pieces
    local _, _, center, volume = bounds(pieces)
    local groundY = groundBelow(center)

    burst(center, 70, {
        Spread = 2,
        Lifetime = NumberRange.new(1.2, 2),
        Speed = NumberRange.new(4, 9),
        SpreadAngle = Vector2.new(180, 180),
        Drag = 2.5,
        Acceleration = Vector3.new(0, -1.5, 0),
        Size = numberSequence({ { 0, 0.1 }, { 1, 0 } }),
        Transparency = numberSequence({ { 0, 0 }, { 0.8, 0.3 }, { 1, 1 } }),
        Color = ColorSequence.new(colors.Pollen),
        LightEmission = 0.8,
        Brightness = 2,
    })
    flash(center, colors.Flash, 2.5, 14, 0.8)

    local bodies = {}
    for _ = 1, timing.Petals do
        local origin = randomPoint(weightedPiece(pieces, volume))
        local scale = rng:NextNumber(0.9, 1.5)
        local part = newPart("Petal", Vector3.new(0.5 * scale, 0.02, 0.42 * scale), ctx.Model)
        local rotation = randomRotation()
        part.CFrame = CFrame.new(origin) * rotation
        local images = flatImage(part, Textures.petal, colors.Petals[rng:NextInteger(1, #colors.Petals)], 1, 1)
        for _, image in images do
            image.Parent.LightInfluence = 1
            TweenService:Create(image, TweenInfo.new(timing.Gather), { ImageTransparency = 0 }):Play()
        end

        local outward = (origin - center) * Vector3.new(1, 0.35, 1)
        outward = outward.Magnitude > 0.05 and outward.Unit or rng:NextUnitVector()
        table.insert(bodies, {
            Part = part,
            Position = origin,
            Rotation = rotation,
            Velocity = outward * rng:NextNumber(12, 22) + Vector3.new(0, rng:NextNumber(8, 15), 0),
            Spin = Vector3.new(rng:NextNumber(-6, 6), rng:NextNumber(-4, 4), rng:NextNumber(-6, 6)),
            Seed = rng:NextNumber(0, 100),
            Release = timing.Gather,
            Rest = 0.02,
            SetFade = function(p)
                setImages(images, { ImageTransparency = p })
            end,
        })
    end

    simulate(bodies, {

        GroundY = groundY, Gravity = 6.5, Drag = 2.8, Flutter = 11, SpinDrag = 0.3,
        Linger = timing.Linger, Fade = timing.Fade,
    })
    return timing.Gather + 6 + timing.Linger + timing.Fade
end

function Effects.Debris(ctx)
    local colors, timing = Config.Colors.Debris, Config.Timing.Debris
    local pieces = ctx.Pieces
    local highest, lowest, center = bounds(pieces)
    local away = -ctx.Target.LookVector

    local bodies = {}
    for _, piece in pieces do
        local release = timing.Appear + timing.Hold + sweepDelay(piece, highest, lowest, timing.Sweep, false)
        local count = math.clamp(math.floor(piece.Volume * 10), 2, 18)
        local _, _, brightness = piece.Color:ToHSV()
        local shade = (piece.Textured or brightness < 0.08) and colors.Fallback or piece.Color
        for _ = 1, count do
            local size = Vector3.new(rng:NextNumber(0.2, 0.55), rng:NextNumber(0.2, 0.55), rng:NextNumber(0.2, 0.55))
            size = Vector3.new(math.min(size.X, piece.Size.X), math.min(size.Y, piece.Size.Y), math.min(size.Z, piece.Size.Z))
            local origin = randomPoint(piece)
            local rotation = piece.CFrame.Rotation
            local part = solidPart("Chunk", {
                Size = size,
                Color = shade:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.25)),
                Material = Enum.Material.Slate,
                Transparency = 1,
                CFrame = CFrame.new(origin) * rotation,
                Parent = ctx.Model,
            })
            TweenService:Create(part, TweenInfo.new(timing.Appear), { Transparency = 0 }):Play()

            local outward = origin - center
            outward = outward.Magnitude > 0.05 and outward.Unit or rng:NextUnitVector()
            local baseSize = size
            table.insert(bodies, {
                Part = part,
                Position = origin,
                Rotation = rotation,
                Velocity = outward * rng:NextNumber(0.8, 2.2) + away * rng:NextNumber(0.5, 1.4) + Vector3.new(0, rng:NextNumber(0.6, 1.8), 0),
                Spin = Vector3.new(rng:NextNumber(-1.6, 1.6), rng:NextNumber(-1.6, 1.6), rng:NextNumber(-1.6, 1.6)),
                Seed = rng:NextNumber(0, 100),
                Release = release,
                Rest = 0,
                FadeAt = release + timing.Drift + rng:NextNumber(-0.4, 0.6),
                SetFade = function(p)
                    part.Transparency = p
                    part.Size = baseSize * (1 - 0.6 * p)
                end,
            })
        end

        task.delay(release, function()
            if Unloaded then return end
            burst(piece.CFrame.Position, math.clamp(math.floor(piece.Volume * 10), 3, 20), {
                Texture = Textures.puff,
                Spread = math.max(piece.Size.X, piece.Size.Y, piece.Size.Z),
                Lifetime = NumberRange.new(1.4, 2.4),
                Speed = NumberRange.new(0.3, 1),
                SpreadAngle = Vector2.new(180, 180),
                Drag = 0.8,
                Acceleration = away * 0.6 + Vector3.new(0, 0.5, 0),
                Rotation = NumberRange.new(0, 360),
                RotSpeed = NumberRange.new(-40, 40),
                Size = numberSequence({ { 0, 0.3 }, { 1, 1.4 } }),
                Transparency = numberSequence({ { 0, 0.5 }, { 1, 1 } }),
                Color = ColorSequence.new(colors.Dust),
                LightInfluence = 1,
            })
        end)
    end

    simulate(bodies, { Gravity = -0.25, Drag = 0.15, SpinDrag = 0.05, Linger = 0, Fade = timing.Fade })
    return timing.Appear + timing.Hold + timing.Sweep + timing.Drift + timing.Fade + 1
end

function Effects.Shatter(ctx)
    local colors, timing = Config.Colors.Shatter, Config.Timing.Shatter
    local pieces = ctx.Pieces
    local _, _, center = bounds(pieces)
    local groundY = groundBelow(center)
    local release = timing.Appear + timing.Hold

    local bodies = {}
    for _, piece in pieces do
        local count = math.clamp(math.floor(piece.Volume * 14), 3, 22)
        for _ = 1, count do
            local size = Vector3.new(rng:NextNumber(0.25, 0.7), rng:NextNumber(0.35, 0.9), 0.06)
            local origin = randomPoint(piece)
            local rotation = piece.CFrame.Rotation * CFrame.Angles(0, 0, rng:NextNumber(0, math.pi * 2))

            local part = solidPart("Shard", {
                Size = size,
                Color = colors.Glass,
                Material = Enum.Material.Ice,
                Reflectance = 0.15,
                Transparency = 1,
                CFrame = CFrame.new(origin) * rotation,
                Parent = ctx.Model,
            })
            TweenService:Create(part, TweenInfo.new(timing.Appear), { Transparency = 0.1 }):Play()

            local outward = origin - center
            outward = outward.Magnitude > 0.05 and outward.Unit or rng:NextUnitVector()
            table.insert(bodies, {
                Part = part,
                Position = origin,
                Rotation = rotation,
                Velocity = outward * rng:NextNumber(8, 18) + Vector3.new(0, rng:NextNumber(4, 9), 0),
                Spin = Vector3.new(rng:NextNumber(-10, 10), rng:NextNumber(-10, 10), rng:NextNumber(-10, 10)),
                Seed = rng:NextNumber(0, 100),
                Release = release,
                Rest = size.Z / 2,
                Flat = CFrame.Angles(math.pi / 2, 0, 0),
                SetFade = function(p)
                    part.Transparency = 0.1 + 0.9 * p
                end,
            })
        end
    end

    task.delay(release, function()
        if Unloaded then return end
        flash(center, colors.Flash, 4, 18, 0.5)
        shockwave(CFrame.new(center.X, groundY + 0.05, center.Z), colors.Sparkle, 1, 10, 0.45, 2)
        burst(center, 70, {
            Texture = Textures.glint,
            Spread = 2.5,
            Lifetime = NumberRange.new(0.5, 1),
            Speed = NumberRange.new(6, 14),
            SpreadAngle = Vector2.new(180, 180),
            Drag = 3,
            Rotation = NumberRange.new(0, 90),
            Size = numberSequence({ { 0, 0.35 }, { 1, 0 } }),
            Color = ColorSequence.new(colors.Sparkle),
            LightEmission = 1,
            Brightness = 3,
        })
    end)

    simulate(bodies, {
        GroundY = groundY, Gravity = 45, Drag = 0.3, Bounce = 0.35, SpinDrag = 0.8,
        Linger = timing.Linger, Fade = timing.Fade,
    })
    return release + 3 + timing.Linger + timing.Fade
end

function Effects.Glitch(ctx)
    local colors, timing = Config.Colors.Glitch, Config.Timing.Glitch
    local target = ctx.Target
    local right = target.RightVector
    local points = surfacePoints(ctx.Source, target, 10, 320)
    local highest, lowest = -math.huge, math.huge
    for _, point in points do
        highest, lowest = math.max(highest, point.Y), math.min(lowest, point.Y)
    end
    local center = pointsCenter(points)

    local voxels = {}
    for i, point in points do
        local roll = rng:NextNumber()
        local channel = roll < 0.14 and "Red" or roll < 0.28 and "Cyan" or "Main"
        local part = solidPart("Voxel", {
            Size = Vector3.one * rng:NextNumber(0.16, 0.26),
            Color = colors[channel],
            Material = Enum.Material.Neon,
            Transparency = 1,
            CFrame = CFrame.new(point) * target.Rotation,
            Parent = ctx.Model,
        })
        voxels[i] = {
            Part = part,
            Home = point,
            Shown = rng:NextNumber(0, timing.Appear),
            Split = channel ~= "Main" and (channel == "Red" and -1 or 1) or 0,
            Alpha = channel == "Main" and 0.15 or 0.35,
        }
    end

    local scanPart = newPart("Scan", Vector3.new(4, 0.04, 4), ctx.Model)
    local scanImages = flatImage(scanPart, Textures.pixel, colors.Scan, 0.25, 2.5)
    local peel = create("ParticleEmitter", {
        Texture = Textures.pixel,
        Rate = 0,
        Lifetime = NumberRange.new(0.5, 1.1),
        Speed = NumberRange.new(1.5, 5),
        SpreadAngle = Vector2.new(180, 25),
        Acceleration = right * 5,
        Drag = 1.5,
        Size = numberSequence({ { 0, 0.16 }, { 1, 0 } }),
        Color = colorSequence({ { 0, colors.Cyan }, { 1, colors.Red } }),
        LightEmission = 0.8,
        LightInfluence = 0,
        Brightness = 2,
        Parent = scanPart,
    })

    local glitchStart, scanStart = timing.Appear, timing.Appear + timing.Glitch
    local finished = scanStart + timing.Scan
    local slices, nextTick = {}, 0
    local moveParts, moveCFrames = {}, {}
    heartbeat(function(_, elapsed)
        if elapsed >= nextTick then
            nextTick = elapsed + 0.06
            table.clear(slices)
            if elapsed >= glitchStart and elapsed < scanStart then
                for _ = 1, rng:NextInteger(1, 3) do
                    local y = rng:NextNumber(lowest, highest)
                    table.insert(slices, { Low = y, High = y + rng:NextNumber(0.2, 0.8), Shift = rng:NextNumber(-0.9, 0.9) })
                end
            end
        end

        local scanY = elapsed >= scanStart and highest - (elapsed - scanStart) / timing.Scan * (highest - lowest + 0.4) or math.huge
        local deleted = 0
        table.clear(moveParts)
        table.clear(moveCFrames)
        for _, voxel in voxels do
            if voxel.Dead then continue end
            local home = voxel.Home
            if home.Y > scanY then
                voxel.Dead = true
                voxel.Part.Transparency = 1
                deleted += 1
                continue
            end
            local shift = 0
            for _, slice in slices do
                if home.Y >= slice.Low and home.Y <= slice.High then
                    shift = slice.Shift
                end
            end
            if elapsed >= glitchStart then
                shift += voxel.Split * (0.08 + rng:NextNumber(0, 0.12))
            end
            local visible = elapsed >= voxel.Shown and not (elapsed >= glitchStart and rng:NextNumber() < 0.05)
            voxel.Part.Transparency = visible and voxel.Alpha or 1
            table.insert(moveParts, voxel.Part)
            table.insert(moveCFrames, CFrame.new(home + right * shift) * target.Rotation)
        end
        workspace:BulkMoveTo(moveParts, moveCFrames, Enum.BulkMoveMode.FireCFrameChanged)

        if scanY ~= math.huge then
            scanPart.CFrame = CFrame.new(center.X, scanY, center.Z) * target.Rotation
            setImages(scanImages, { ImageTransparency = 0.25 + 0.5 * math.max(0, (elapsed - finished + 0.3) / 0.3) })
            if deleted > 0 then
                peel:Emit(deleted * 3)
            end
        else
            setImages(scanImages, { ImageTransparency = 1 })
        end
        return elapsed < finished + 1.2
    end)
    return finished + 1.4
end

function Effects.Butterflies(ctx)
    local colors, timing = Config.Colors.Butterflies, Config.Timing.Butterflies
    local target = ctx.Target
    local points = surfacePoints(ctx.Source, target, 6, 180)
    local flocks = split(points, { 0.34, 0.33, 0.33 })
    local clouds = {}
    for i, subset in flocks do
        clouds[i] = pointCloud(ctx.Model, subset, {
            Groups = 6,
            PerGroup = 3,
            Props = {
                Texture = Textures.butterfly,
                FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2,
                FlipbookMode = Enum.ParticleFlipbookMode.Loop,
                FlipbookFramerate = NumberRange.new(12, 18),
                FlipbookStartRandom = true,
                Lifetime = NumberRange.new(3, 4.5),
                Speed = NumberRange.new(1.5, 4),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = target.UpVector * 1.6 - target.LookVector * 0.8,
                Drag = 0.6,
                Rotation = NumberRange.new(-25, 25),
                Size = numberSequence({ { 0, 0.34 }, { 0.85, 0.34 }, { 1, 0 } }),
                Transparency = numberSequence({ { 0, 0 }, { 0.8, 0 }, { 1, 1 } }),
                Color = ColorSequence.new(colors.Wings[i]),
                LightEmission = 0.35,
                LightInfluence = 0.4,
                Brightness = 1.4,
            },
        })
    end
    local glitter = pointCloud(ctx.Model, surfacePoints(ctx.Source, target, 14, 500), {
        Groups = 6,
        PerGroup = 4,
        Props = {
            Texture = Textures.glint,
            Lifetime = NumberRange.new(1.2, 2.2),
            Speed = NumberRange.new(0.3, 1.2),
            SpreadAngle = Vector2.new(180, 180),
            Acceleration = target.UpVector * 0.8,
            Drag = 0.8,
            Rotation = NumberRange.new(0, 90),
            Size = numberSequence({ { 0, 0.12 }, { 0.5, 0.18 }, { 1, 0 } }),
            Transparency = numberSequence({ { 0, 0.3 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Glitter),
            LightEmission = 0.8,
            Brightness = 2,
        },
    })

    local form = glitter.Emit()
    for _, cloud in clouds do
        form = math.max(form, cloud.Emit())
    end
    task.delay(form + timing.Hold, function()
        if Unloaded then return end
        for _, cloud in clouds do
            cloud.Sweep(timing.Sweep, 0.35)
        end
        glitter.Sweep(timing.Sweep, 0.35)
    end)
    return form + timing.Hold + timing.Sweep + 5
end

function Effects.Ascension(ctx)
    local colors, timing = Config.Colors.Ascension, Config.Timing.Ascension
    local target = ctx.Target
    local points = surfacePoints(ctx.Source, target, 26, 1000)
    local center = pointsCenter(points)
    local groundY = groundBelow(center)
    local highest = -math.huge
    for _, point in points do
        highest = math.max(highest, point.Y)
    end

    local cloud = pointCloud(ctx.Model, points, {
        Groups = 8,
        PerGroup = 5,
        Props = {
            Texture = Textures.dot,
            Lifetime = NumberRange.new(2.4, 3.4),
            Speed = NumberRange.new(0.2, 0.8),
            SpreadAngle = Vector2.new(180, 180),
            Acceleration = target.UpVector * 5,
            Drag = 0.6,
            Size = numberSequence({ { 0, 0.1 }, { 1, 0.24 } }),
            Transparency = numberSequence({ { 0, 0 }, { 0.6, 0.3 }, { 1, 1 } }),
            Color = colorSequence({ { 0, colors.Body }, { 1, colors.Fade } }),
            LightEmission = 0.6,
            Brightness = 1.6,
        },
    })
    local form = cloud.Emit()

    local pillarAnchor = newPart("Pillar", Vector3.one, ctx.Model)
    pillarAnchor.CFrame = CFrame.new(center.X, groundY, center.Z)
    local a0 = create("Attachment", { Parent = pillarAnchor })
    local a1 = create("Attachment", { Position = Vector3.new(0, 70, 0), Parent = pillarAnchor })
    local pillar = create("Beam", {
        Attachment0 = a0,
        Attachment1 = a1,
        Texture = Textures.ray,
        TextureMode = Enum.TextureMode.Stretch,
        Width0 = 0,
        Width1 = 0,
        Segments = 1,
        FaceCamera = true,
        Color = ColorSequence.new(colors.Pillar),
        Transparency = numberSequence({ { 0, 0.25 }, { 0.7, 0.45 }, { 1, 1 } }),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 2.5,
        Parent = pillarAnchor,
    })
    local halo = newPart("Halo", Vector3.new(0.1, 0.02, 0.1), ctx.Model)
    local haloImages = flatImage(halo, Textures.ring, colors.Halo, 1, 3)

    local start = form
    local release = start + timing.Rise + timing.Hold
    local finished = release + timing.Sweep + 3.5
    heartbeat(function(_, elapsed)
        if elapsed > finished then
            return false
        end
        local rise = math.clamp((elapsed - start) / timing.Rise, 0, 1)
        local fade = math.clamp((elapsed - release - timing.Sweep) / 2, 0, 1)
        local width = 4.5 * (1 - (1 - rise) ^ 3) * (1 - fade)
        pillar.Width0, pillar.Width1 = width, width * 1.4

        local lift = math.max(0, elapsed - release) * 2
        halo.Size = Vector3.new(2.2 * rise + 0.01, 0.02, 2.2 * rise + 0.01)
        halo.CFrame = CFrame.new(center.X, highest + 0.6 + lift, center.Z) * CFrame.Angles(0, elapsed * 1.5, 0)
        setImages(haloImages, { ImageTransparency = 1 - rise * (1 - fade) * 0.9 })
    end)

    task.delay(start, function()
        if Unloaded then return end
        flash(center, colors.Pillar, 3, 18, timing.Rise + timing.Hold + timing.Sweep + 1)
        shockwave(CFrame.new(center.X, groundY + 0.05, center.Z), colors.Halo, 1, 9, 1, 2)
    end)
    task.delay(release, function()
        if Unloaded then return end
        cloud.Sweep(timing.Sweep, 0.5)
        burst(center, 26, {
            Texture = Textures.feather,
            Spread = 2,
            Lifetime = NumberRange.new(3, 4.5),
            Speed = NumberRange.new(1, 3),
            SpreadAngle = Vector2.new(180, 180),
            Acceleration = Vector3.new(0, -0.9, 0),
            Drag = 1.4,
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-60, 60),
            Squash = numberSequence({ { 0, 0 }, { 0.25, 0.5 }, { 0.5, -0.4 }, { 0.75, 0.5 }, { 1, 0 } }),
            Size = numberSequence({ { 0, 0 }, { 0.08, 0.55 }, { 0.9, 0.5 }, { 1, 0 } }),
            Transparency = numberSequence({ { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Feathers),
            LightEmission = 0.3,
            LightInfluence = 0.5,
            Brightness = 1.5,
        })
    end)
    return finished
end

function Effects.Constellation(ctx)
    local colors, timing = Config.Colors.Constellation, Config.Timing.Constellation
    local source, target = ctx.Source, ctx.Target
    local points = surfacePoints(source, target, 26, 1000)
    local center = pointsCenter(points)
    local frame = CFrame.new(center) * target.Rotation
    local sourceRoot = findRoot(source)
    local toTarget = sourceRoot and (target * sourceRoot.CFrame:Inverse()) or target

    local stars, edges = {}, {}
    local function starAt(position)
        for i, star in stars do
            if (star.World - position).Magnitude < 0.75 then
                star.Count += 1
                star.World = star.World:Lerp(position, 1 / star.Count)
                return i
            end
        end
        table.insert(stars, { World = position, Count = 1 })
        return #stars
    end
    for _, part in bodyParts(source) do
        if part.Parent == source then
            local cframe, size = toTarget * part.CFrame, part.Size
            if part.Name == "Head" then
                starAt(cframe.Position)
            else
                local axis = size.X >= size.Y and size.X >= size.Z and Vector3.xAxis or size.Y >= size.Z and Vector3.yAxis or Vector3.zAxis
                local reach = axis * (axis:Dot(size) * 0.4)
                local a, b = starAt(cframe * reach), starAt(cframe * -reach)
                if a ~= b then
                    table.insert(edges, { a, b })
                end
            end
        end
    end
    if #stars == 0 then
        return 0
    end

    local parent = {}
    local function find(i)
        while parent[i] and parent[i] ~= i do
            i = parent[i]
        end
        return i
    end
    for i in stars do
        parent[i] = i
    end
    for _, edge in edges do
        parent[find(edge[1])] = find(edge[2])
    end
    local pairsByDistance = {}
    for i = 1, #stars do
        for j = i + 1, #stars do
            table.insert(pairsByDistance, { i, j, (stars[i].World - stars[j].World).Magnitude })
        end
    end
    table.sort(pairsByDistance, function(p, q)
        return p[3] < q[3]
    end)
    for _, pair in pairsByDistance do
        if find(pair[1]) ~= find(pair[2]) then
            parent[find(pair[1])] = find(pair[2])
            table.insert(edges, { pair[1], pair[2] })
        end
    end

    local links = {}
    for i in stars do
        links[i] = {}
    end
    for index, edge in edges do
        table.insert(links[edge[1]], index)
        table.insert(links[edge[2]], index)
    end
    local first = 1
    for i, star in stars do
        if star.World.Y > stars[first].World.Y then
            first = i
        end
    end
    stars[first].Appear = 0
    local queue, drawEnd = { first }, 0
    while #queue > 0 do
        local current = table.remove(queue, 1)
        for _, index in links[current] do
            local edge = edges[index]
            local other = edge[1] == current and edge[2] or edge[1]
            if not edge.Start then
                local length = (stars[other].World - stars[current].World).Magnitude
                edge.Start = stars[current].Appear
                edge.From, edge.To = current, other
                edge.End = edge.Start + timing.Link * math.clamp(length / 1.2, 0.6, 1.8)
                if not stars[other].Appear then
                    stars[other].Appear = edge.End
                    table.insert(queue, other)
                end
                drawEnd = math.max(drawEnd, edge.End)
            end
        end
    end

    local dustPoints, speckPoints = table.unpack(split(points, { 0.94, 0.06 }))
    local dust = pointCloud(ctx.Model, dustPoints, {
        Groups = 8,
        PerGroup = 4,
        Props = {
            Texture = Textures.dot,
            Lifetime = NumberRange.new(2, 3),
            Speed = NumberRange.new(0.3, 1.4),
            SpreadAngle = Vector2.new(180, 180),
            Acceleration = Vector3.new(0, 0.3, 0),
            Drag = 0.7,
            Size = numberSequence({ { 0, 0.09 }, { 1, 0.2 } }),
            Transparency = numberSequence({ { 0, 0.05 }, { 0.6, 0.35 }, { 1, 1 } }),
            Color = colorSequence({ { 0, colors.Dust }, { 1, colors.DustFade } }),
            LightEmission = 0.2,
            Brightness = 1.2,
        },
    })
    local specks = pointCloud(ctx.Model, speckPoints, {
        Groups = 1,
        PerGroup = 4,
        Props = {
            Texture = Textures.star,
            Lifetime = NumberRange.new(1.6, 2.6),
            Speed = NumberRange.new(0.2, 1),
            SpreadAngle = Vector2.new(180, 180),
            Drag = 0.7,
            Rotation = NumberRange.new(0, 90),
            Size = numberSequence({ { 0, 0.2 }, { 1, 0.08 } }),
            Transparency = numberSequence({ { 0, 0.1 }, { 0.7, 0.35 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Stars),
            LightEmission = 0.6,
            Brightness = 1.6,
        },
    })
    local form = math.max(dust.Emit(), specks.Emit())
    local release = form + drawEnd + timing.Hold
    local cometStart = release + 0.15

    local impact = Vector3.zero
    for _, star in stars do
        impact += star.World
    end
    impact /= #stars
    local fallDirection = -(target.UpVector + target.RightVector * 0.9).Unit
    local entry = impact - fallDirection * 18
    local keys = { { Position = entry, Time = 0 }, { Position = impact, Time = 18 / timing.Dive } }
    local impactTime = cometStart + keys[2].Time
    local lastHit = impactTime
    for _, star in stars do
        local away = star.World - impact
        local distance = away.Magnitude
        star.Hit = impactTime + distance / timing.Wave
        lastHit = math.max(lastHit, star.Hit)
        local push = (distance > 0.01 and away.Unit or rng:NextUnitVector()) + fallDirection * 0.25 + rng:NextUnitVector() * 0.35
        star.Drift = frame:VectorToObjectSpace(push.Unit) * rng:NextNumber(4, 7)
        star.Spin = rng:NextNumber(-140, 140)
    end
    local finished = lastHit + timing.Scatter + 0.2

    local highest, lowest = -math.huge, math.huge
    for _, point in points do
        highest, lowest = math.max(highest, point.Y), math.min(lowest, point.Y)
    end
    for i = 1, 3 do
        local height = lowest + (highest - lowest) * (i - 0.5) / 3
        burst(Vector3.new(center.X, height, center.Z), 3, {
            Texture = Textures.nebula,
            Spread = 1.6,
            Lifetime = NumberRange.new(cometStart + 0.6 - form),
            Speed = NumberRange.new(0.05, 0.2),
            SpreadAngle = Vector2.new(180, 180),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-8, 8),
            Size = numberSequence({ { 0, 1 }, { 0.15, 2.6 }, { 1, 3.6 } }),
            Transparency = numberSequence({ { 0, 1 }, { 0.15, 0.8 }, { 0.75, 0.84 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Nebula[(i - 1) % #colors.Nebula + 1]),
            LightEmission = 0,
            Brightness = 1,
        })
    end

    local anchor = newPart("Sky", Vector3.one, ctx.Model)
    anchor.CFrame = frame
    local glow = create("PointLight", { Color = colors.Lines, Brightness = 0, Range = 10, Shadows = false, Parent = anchor })
    for i, star in stars do
        star.Local = frame:PointToObjectSpace(star.World)
        star.Current = star.Local
        star.Attachment = create("Attachment", { Position = star.Local, Parent = anchor })
        star.Gui = create("BillboardGui", {
            Size = UDim2.fromScale(0, 0),
            LightInfluence = 0,
            Brightness = 1.8,
            Adornee = star.Attachment,
            Parent = star.Attachment,
        })
        star.Image = create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = Textures.star,
            ImageColor3 = colors.Stars,
            Rotation = rng:NextNumber(-12, 12),
            Parent = star.Gui,
        })
        star.Base = i == first and 2.2 or rng:NextNumber(1.3, 1.7)
        star.Phase = rng:NextNumber(0, math.pi * 2)
        star.Rotation = star.Image.Rotation
        task.delay(form + star.Appear, function()
            if Unloaded then return end
            burst(star.World, 3, {
                Texture = Textures.glint,
                Lifetime = NumberRange.new(0.3, 0.5),
                Speed = NumberRange.new(1, 2.5),
                SpreadAngle = Vector2.new(180, 180),
                Drag = 4,
                Rotation = NumberRange.new(0, 90),
                Size = numberSequence({ { 0, 0.2 }, { 1, 0 } }),
                Color = ColorSequence.new(colors.Stars),
                LightEmission = 0.6,
                Brightness = 1.5,
            })
        end)

        task.delay(star.Hit, function()
            if Unloaded then return end
            burst(star.World, 5, {
                Texture = Textures.star,
                Spread = 0.3,
                Lifetime = NumberRange.new(0.7, 1.3),
                Speed = NumberRange.new(1.5, 4.5),
                SpreadAngle = Vector2.new(180, 180),
                Drag = 2.2,
                Rotation = NumberRange.new(0, 90),
                RotSpeed = NumberRange.new(-90, 90),
                Size = numberSequence({ { 0, 0.42 }, { 1, 0 } }),
                Transparency = numberSequence({ { 0, 0 }, { 0.6, 0.25 }, { 1, 1 } }),
                Color = ColorSequence.new(colors.Stars),
                LightEmission = 0.5,
                Brightness = 1.6,
            })
        end)
    end
    for _, edge in edges do
        edge.Tip = create("Attachment", { Position = stars[edge.From].Local, Parent = anchor })
        edge.Beam = create("Beam", {
            Attachment0 = stars[edge.From].Attachment,
            Attachment1 = edge.Tip,
            Texture = Textures.line,
            TextureMode = Enum.TextureMode.Stretch,
            Width0 = 0.06,
            Width1 = 0.06,
            Segments = 1,
            FaceCamera = true,
            Color = ColorSequence.new(colors.Lines),
            Transparency = NumberSequence.new(0.25),
            LightEmission = 0.6,
            LightInfluence = 0,
            Brightness = 1.5,
            Enabled = false,
            Parent = anchor,
        })
    end

    heartbeat(function(_, elapsed)
        if elapsed > finished then
            return false
        end
        local t = elapsed - form
        local intact = 0
        for _, star in stars do
            local a = math.clamp((t - star.Appear) / 0.3, 0, 1) - 1
            local pop = 1 + 2.7 * a ^ 3 + 1.7 * a ^ 2
            local size = star.Base * (t >= star.Appear and pop or 0) * (1 + 0.08 * math.sin(elapsed * 5 + star.Phase))
            local s = elapsed - star.Hit
            if s >= 0 then

                local fade = math.clamp(s / timing.Scatter, 0, 1)
                star.Current = star.Local + star.Drift * ((1 - math.exp(-1.6 * s)) / 1.6) + Vector3.new(0, 0.25 * s, 0)
                size *= (1 + 0.6 * math.exp(-s * 12)) * (1 - 0.55 * fade)
                star.Image.ImageTransparency = 0.1 + 0.9 * fade ^ 1.3
                star.Image.Rotation = star.Rotation + s * star.Spin
            else
                intact += 1
                star.Image.ImageTransparency = 0.1
            end
            star.Gui.Size = UDim2.fromScale(size, size)
            star.Attachment.Position = star.Current
        end
        glow.Brightness = 0.6 * math.clamp(t / math.max(drawEnd, 0.1), 0, 1) * intact / #stars

        for _, edge in edges do
            local from, to = stars[edge.From], stars[edge.To]
            local d = math.clamp((t - edge.Start) / math.max(edge.End - edge.Start, 1e-3), 0, 1)
            local snapped = math.clamp((elapsed - math.min(from.Hit, to.Hit)) / 0.25, 0, 1)
            edge.Beam.Enabled = t > edge.Start and snapped < 1
            edge.Tip.Position = from.Current:Lerp(to.Current, 1 - (1 - d) ^ 2)
            edge.Beam.Transparency = NumberSequence.new(0.25 + 0.75 * snapped)
        end
    end)

    task.delay(release, function()
        if Unloaded then return end
        dust.Sweep(timing.Drift, 0.6, true)
        specks.Sweep(timing.Drift, 0.6, true)
    end)

    task.delay(cometStart, function()
        if Unloaded then return end
        local comet = newPart("Comet", Vector3.one * 0.2, ctx.Model)
        comet.CFrame = CFrame.new(entry)
        local t0 = create("Attachment", { Position = Vector3.new(0, 0.12, 0), Parent = comet })
        local t1 = create("Attachment", { Position = Vector3.new(0, -0.12, 0), Parent = comet })
        create("Trail", {
            Attachment0 = t0,
            Attachment1 = t1,
            Lifetime = 0.3,
            FaceCamera = true,
            WidthScale = numberSequence({ { 0, 1 }, { 1, 0 } }),
            Transparency = numberSequence({ { 0, 0.1 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Comet),
            LightEmission = 0.7,
            LightInfluence = 0,
            Brightness = 2,
            Parent = comet,
        })
        local head = create("BillboardGui", { Size = UDim2.fromScale(1.3, 1.3), LightInfluence = 0, Brightness = 2.2, Adornee = comet, Parent = comet })
        local headImage = create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = Textures.star,
            ImageColor3 = colors.Comet,
            Parent = head,
        })
        local segment = 1
        heartbeat(function(_, elapsed)
            while keys[segment + 1] and elapsed >= keys[segment + 1].Time do
                segment += 1
            end
            local a, b = keys[segment], keys[segment + 1]
            if not b then
                head.Enabled = false
                task.delay(0.35, comet.Destroy, comet)
                return false
            end
            local f = (elapsed - a.Time) / math.max(b.Time - a.Time, 1e-3)
            comet.CFrame = CFrame.new(a.Position:Lerp(b.Position, f))
        end)
    end)

    task.delay(impactTime, function()
        if Unloaded then return end
        flash(impact, colors.Comet, 1.2, 12, 0.5)
        burst(impact, 16, {
            Texture = Textures.star,
            Spread = 0.4,
            Lifetime = NumberRange.new(0.6, 1.1),
            Speed = NumberRange.new(5, 11),
            SpreadAngle = Vector2.new(180, 180),
            Drag = 3,
            Rotation = NumberRange.new(0, 90),
            RotSpeed = NumberRange.new(-120, 120),
            Size = numberSequence({ { 0, 0.5 }, { 1, 0 } }),
            Transparency = numberSequence({ { 0, 0 }, { 0.6, 0.3 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Comet),
            LightEmission = 0.5,
            Brightness = 1.6,
        })
    end)
    return finished
end

local function scaleTiming(effectName)
    local base = Config.Timing[effectName]
    if not base then
        return nil, nil
    end
    local speed = math.clamp(Config.Speed or 1, 0.25, 3)
    if math.abs(speed - 1) < 1e-3 then
        return nil, nil
    end
    local scaled = {}
    for key, value in base do
        if type(value) == "number" then

            if key == "Dive" or key == "Wave" or key == "Petals" then
                scaled[key] = value * speed
            else
                scaled[key] = value / speed
            end
        else
            scaled[key] = value
        end
    end
    return base, scaled
end

local function play(effectName, target, source)
    if Unloaded or not Config.Enabled then
        return 0
    end
    effectName = effectName or Config.Effect
    local effect = Effects[effectName]
    source = source or LocalPlayer.Character
    if typeof(source) ~= "Instance" then
        return 0
    end
    local root = findRoot(source)
    if not effect or not root then
        return 0
    end

    if not source:FindFirstChild("HumanoidRootPart") and root.Name ~= "HumanoidRootPart" then
        pcall(function()
            root.Name = "HumanoidRootPart"
        end)
    end

    if typeof(target) == "Vector3" then
        target = CFrame.new(target)
    end
    target = target or root.CFrame * CFrame.new(0, 0, -Config.DemoDistance) * CFrame.Angles(0, math.pi, 0)
    local pieces = bodyPieces(source, target)
    if #pieces == 0 then
        return 0
    end

    local saved, scaled = scaleTiming(effectName)
    if saved and scaled then
        Config.Timing[effectName] = scaled
    end

    local model = create("Model", { Name = effectName, Parent = Container })
    local ok, duration = pcall(effect, { Model = model, Source = source, Target = target, Pieces = pieces })
    if saved then
        Config.Timing[effectName] = saved
    end
    if not ok then
        warn(`[KillEffects] {duration}`)
        model:Destroy()
        return 0
    end
    duration = tonumber(duration) or 2

    duration = duration / math.clamp(Config.Speed or 1, 0.25, 3)
    task.delay(duration, model.Destroy, model)
    return duration
end

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

local function buildModelFromHash(tpo)
    if not tpo then
        return nil
    end
    local hash = tpo._characterModelHash
    if type(hash) ~= "table" then
        return nil
    end
    local rootPart = nil
    pcall(function()
        rootPart = tpo.getRootPart and tpo:getRootPart() or tpo._rootPart
    end)
    local rootCf = rootPart and rootPart.CFrame or CFrame.new()
    local model = Instance.new("Model")
    model.Name = "PFKillBody"
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.Transparency = 1
    hrp.Anchored = true
    hrp.CanCollide = false
    hrp.CFrame = rootCf
    hrp.Parent = model
    local count = 0
    for name, part in hash do
        if typeof(part) == "Instance" and part:IsA("BasePart") then
            local piece = Instance.new("Part")
            piece.Name = tostring(name)
            local size = part.Size
            if size.Magnitude < 0.2 then
                size = Vector3.new(1, 1, 1)
            end
            piece.Size = size
            piece.CFrame = part.CFrame
            piece.Color = part.Color
            piece.Material = Enum.Material.SmoothPlastic
            piece.Anchored = true
            piece.CanCollide = false
            piece.CanQuery = false
            piece.CanTouch = false
            piece.Transparency = 0
            piece.Parent = model
            count += 1
        end
    end
    if count == 0 then
        model:Destroy()
        return nil
    end
    return model, hrp
end

local function characterFromEntry(entry)
    if not entry then
        return nil
    end
    local tpo = entry._thirdPersonObject
    if not tpo then
        return nil
    end
    local model = nil
    pcall(function()
        model = tpo.getCharacterModel and tpo:getCharacterModel() or tpo._character
    end)
    if typeof(model) ~= "Instance" then
        local hash = tpo._characterModelHash
        if type(hash) == "table" then
            for _, part in hash do
                if typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent then
                    model = part:FindFirstAncestorOfClass("Model") or part.Parent
                    break
                end
            end
        end
    end
    local root = nil
    pcall(function()
        root = tpo.getRootPart and tpo:getRootPart() or tpo._rootPart
    end)
    root = root or (typeof(model) == "Instance" and findRoot(model)) or nil
    return model, root, tpo
end

local function main()
    loadTextures()
    Container = create("Folder", { Name = "KillEffects", Parent = workspace.CurrentCamera })

    local Restores = {}
    local damagedAt = {}
    local bodyCache = {}
    local playedAt = {}
    local Modules = findModules()

    local function clearCache(player)
        local cached = bodyCache[player]
        if cached and cached.model then
            pcall(function()
                cached.model:Destroy()
            end)
        end
        bodyCache[player] = nil
    end

    local function snapshotPlayer(player, entry)
        local model, root, tpo = characterFromEntry(entry)
        local clone = nil
        local rootCf = root and root.CFrame or nil

        if tpo then
            local hashModel, hashRoot = buildModelFromHash(tpo)
            if hashModel then
                clone = hashModel
                rootCf = hashRoot and hashRoot.CFrame or rootCf
            end
        end

        if not clone and typeof(model) == "Instance" then
            local ok, copied = pcall(function()
                return model:Clone()
            end)
            if ok and typeof(copied) == "Instance" then
                clone = copied
            end
        end
        if not clone then
            return
        end

        clone.Name = "KillSnap"
        clone.Parent = nil
        for _, d in clone:GetDescendants() do
            if d:IsA("BasePart") then
                d.Anchored = true
                d.CanCollide = false
                d.CanQuery = false
                d.CanTouch = false
                if d.Transparency >= 1 and d.Name ~= "HumanoidRootPart" then
                    d.Transparency = 0
                end
            end
        end
        if not rootCf then
            local cloneRoot = findRoot(clone)
            rootCf = cloneRoot and cloneRoot.CFrame or CFrame.new()
        end
        clearCache(player)
        bodyCache[player] = {
            model = clone,
            cf = rootCf,
            at = os.clock(),
        }
    end

    local function playForPlayer(player, fallbackCf)
        if Unloaded or not Config.Enabled or not Config.OnKill then
            return
        end
        local now = os.clock()
        if playedAt[player] and now - playedAt[player] < 0.75 then
            return
        end
        local stamped = damagedAt[player]
        if stamped and now - stamped > 5 then
            return
        end
        if not stamped and not fallbackCf then
            return
        end
        playedAt[player] = now
        damagedAt[player] = nil

        local cached = bodyCache[player]
        local clone = cached and cached.model
        local target = (cached and cached.cf) or fallbackCf
        bodyCache[player] = nil

        if typeof(clone) ~= "Instance" then

            clone = Instance.new("Model")
            clone.Name = "KillStandIn"
            local root = Instance.new("Part")
            root.Name = "HumanoidRootPart"
            root.Size = Vector3.new(2, 2, 1)
            root.Transparency = 1
            root.Anchored = true
            root.CanCollide = false
            if typeof(target) == "CFrame" then
                root.CFrame = target
            elseif typeof(target) == "Vector3" then
                root.CFrame = CFrame.new(target)
            else
                root.CFrame = CFrame.new()
            end
            root.Parent = clone
            for _, info in {
                { "Head", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 1.5, 0) },
                { "Torso", Vector3.new(2, 2, 1), CFrame.new() },
                { "Left Arm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 0, 0) },
                { "Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 0, 0) },
                { "Left Leg", Vector3.new(1, 2, 1), CFrame.new(-0.5, -2, 0) },
                { "Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, -2, 0) },
            } do
                local part = Instance.new("Part")
                part.Name = info[1]
                part.Size = info[2]
                part.Anchored = true
                part.CanCollide = false
                part.Color = Color3.fromRGB(200, 200, 210)
                part.CFrame = root.CFrame * info[3]
                part.Parent = clone
            end
        end

        clone.Parent = Container
        local cloneRoot = findRoot(clone)
        if cloneRoot and cloneRoot.Name ~= "HumanoidRootPart" then
            pcall(function()
                cloneRoot.Name = "HumanoidRootPart"
            end)
        end

        for _, d in clone:GetDescendants() do
            if d:IsA("BasePart") then
                d.CanCollide = false
                d.Anchored = true
                if d.Transparency >= 1 then
                    d.Transparency = 0
                end
            end
        end
        if typeof(target) ~= "CFrame" then
            if typeof(target) == "Vector3" then
                target = CFrame.new(target)
            else
                target = cloneRoot and cloneRoot.CFrame or CFrame.new()
            end
        end
        task.defer(function()
            local ok, dur = pcall(play, Config.Effect, target, clone)
            task.delay(((ok and tonumber(dur)) or 3) + 0.75, function()
                if clone and clone.Parent then
                    clone:Destroy()
                end
            end)
        end)
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

    local function markDamaged(player, entry)
        if not player then
            return
        end
        damagedAt[player] = os.clock()
        entry = entry or (Modules and Modules.ReplicationInterface and Modules.ReplicationInterface.getEntry and Modules.ReplicationInterface.getEntry(player))
        if entry then
            pcall(snapshotPlayer, player, entry)
        end
    end

    local function notifyKill(player, fallbackCf)
        if not player or player == LocalPlayer then
            return
        end
        damagedAt[player] = damagedAt[player] or os.clock()
        local cached = bodyCache[player]
        local cf = fallbackCf or (cached and cached.cf) or nil
        if typeof(cf) == "Vector3" then
            cf = CFrame.new(cf)
        end
        playForPlayer(player, cf)
    end

    if Modules and Modules.NetworkClient and type(Modules.NetworkClient.send) == "function" then
        local network = Modules.NetworkClient
        local send = network.send
        network.send = function(self, name, ...)
            if Config.Enabled and Config.OnKill and name == "bullethit" then
                local _, player = ...
                if player then
                    local entry = Modules.ReplicationInterface and Modules.ReplicationInterface.getEntry and Modules.ReplicationInterface.getEntry(player)
                    local hpBefore = entryHealth(entry)

                    if entry then
                        pcall(snapshotPlayer, player, entry)
                    end
                    task.delay(0.18, function()
                        if Unloaded or not (Config.Enabled and Config.OnKill) then
                            return
                        end
                        entry = Modules.ReplicationInterface and Modules.ReplicationInterface.getEntry and Modules.ReplicationInterface.getEntry(player) or entry
                        local hpAfter = entryHealth(entry)
                        local damaged = typeof(hpBefore) == "number" and typeof(hpAfter) == "number" and hpAfter < hpBefore - 0.25
                        local dead = entry and (entry._alive == false or (typeof(hpAfter) == "number" and hpAfter <= 0))
                        if damaged or dead then
                            markDamaged(player, entry)
                            if dead then
                                notifyKill(player)
                            end
                        end
                    end)
                end
            end
            return send(self, name, ...)
        end
        table.insert(Restores, function()
            network.send = send
        end)
    end

    local pse = Modules and Modules.PlayerStatusEvents
    if pse and pse.onPlayerDied and (pse.onPlayerDied.connect or pse.onPlayerDied.Connect) then
        local connect = pse.onPlayerDied.connect or pse.onPlayerDied.Connect
        table.insert(Connections, connect(pse.onPlayerDied, function(data)
            if Unloaded or not Config.Enabled or not Config.OnKill or type(data) ~= "table" then
                return
            end
            local victim = data.victim or data.player or data.Player
            local attacker = data.attacker or data.killer or data.Killer
            local attackerOk = attacker == LocalPlayer
                or (typeof(attacker) == "Instance" and attacker:IsA("Player") and attacker.UserId == LocalPlayer.UserId)
                or (type(attacker) == "string" and (attacker == LocalPlayer.Name or attacker == tostring(LocalPlayer.UserId)))
                or damagedAt[victim] ~= nil
            if not attackerOk or not victim or victim == LocalPlayer then
                return
            end
            damagedAt[victim] = damagedAt[victim] or os.clock()
            local cached = bodyCache[victim]
            notifyKill(victim, cached and cached.cf or nil)
        end))
    end

    if Modules and Modules.ReplicationInterface then
        table.insert(Connections, RunService.Heartbeat:Connect(function()
            if Unloaded or not Config.Enabled or not Config.OnKill then
                return
            end
            pcall(Modules.ReplicationInterface.operateOnAllEntries, function(player, entry)
                local stamped = damagedAt[player]
                if not stamped then
                    return
                end
                if os.clock() - stamped < 0.05 then
                    return
                end

                if entry._alive ~= false then
                    local hpOk, hp = true, 100
                    if entry.getHealth then
                        hpOk, hp = pcall(entry.getHealth, entry)
                    end
                    if hpOk and typeof(hp) == "number" and hp > 0 then
                        if not bodyCache[player] or os.clock() - (bodyCache[player].at or 0) > 0.2 then
                            snapshotPlayer(player, entry)
                        end
                        return
                    end
                end
                playForPlayer(player, bodyCache[player] and bodyCache[player].cf or entry._receivedPosition and CFrame.new(entry._receivedPosition) or nil)
            end)
        end))
    end

    table.insert(Restores, function()
        for player in bodyCache do
            clearCache(player)
        end
        table.clear(bodyCache)
        table.clear(damagedAt)
        table.clear(playedAt)
    end)

    task.spawn(function()
        local index = 0
        while not Unloaded do
            local wait = 1
            if Config.Demo then
                index = index % #Config.DemoEffects + 1
                local ok, result = pcall(play, Config.DemoEffects[index])
                if ok then
                    wait = math.max((tonumber(result) or 2) * 0.75, 2) + Config.DemoGap
                else
                    warn(`[KillEffects] {result}`)
                end
            end
            task.wait(wait)
        end
    end)

    local effectNames = {}
    for name in Effects do
        table.insert(effectNames, name)
    end
    table.sort(effectNames)

    env.KillEffects = {
        Config = Config,
        Effects = effectNames,
        EffectDefs = Effects,
        Play = play,

        NotifyDamage = markDamaged,
        NotifyKill = notifyKill,
        SetEnabled = function(on)
            Config.Enabled = on and true or false
        end,
        SetEffect = function(name)
            if Effects[name] then
                Config.Effect = name
            end
        end,
        SetSpeed = function(value)
            Config.Speed = math.clamp(tonumber(value) or 1, 0.25, 3)
        end,
        SetScale = function(value)
            Config.Scale = math.clamp(tonumber(value) or 1, 0.35, 3)
        end,

        SetColor = function(effectName, slot, color)
            Config.Colors[effectName] = Config.Colors[effectName] or {}
            Config.Colors[effectName][slot] = color
        end,
        Unload = function()
            Unloaded = true
            for _, connection in Connections do
                connection:Disconnect()
            end
            table.clear(Connections)
            for _, restore in Restores do
                pcall(restore)
            end
            table.clear(Restores)
            if Container then
                Container:Destroy()
            end
            env.KillEffects = nil
        end,
    }
end

TextureIds = {
    dot = "rbxassetid://79451523688005",
    petal = "rbxassetid://91106269226329",
    puff = "rbxassetid://105339311737422",
    glint = "rbxassetid://80819042809873",
    ember = "rbxassetid://131265282730044",
    spark = "rbxassetid://83337948032750",
    arc = "rbxassetid://137171593273887",
    swirl = "rbxassetid://112339946092674",
    ring = "rbxassetid://130480777986951",
    pixel = "rbxassetid://98416523570354",
    butterfly = "rbxassetid://140497468226737",
    ray = "rbxassetid://78335664913090",
    feather = "rbxassetid://131624527200833",
    star = "rbxassetid://105260989921589",
    nebula = "rbxassetid://137135863795287",
    line = "rbxassetid://111587888494612",
}

do
    local okKill, errKill = pcall(main)
    if not okKill then
        warn("[KillEffects] main failed:", errKill)
    end
end

end
