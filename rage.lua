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

local function marked(player)
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
            selected = Config.Targets[player] == true,
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

local function applyAAAngles(angles)
    if typeof(angles) ~= "Vector3" or not isFiniteVec3(angles) then
        return angles
    end
    if not Config.AntiAim then
        return angles
    end
    local x = math.rad(number(Config.PitchAmount, 0, -89, 89))
    local y = wrapYaw(math.rad(number(Config.YawAmount, 180, -180, 180)))
    x = math.clamp(x, -halfPi, halfPi)
    return Vector3.new(x, y, 0)
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

                if Config.AntiAim or Config.FakeLag then
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

                do
                    local tracers = env.Tracers
                    if tracers and type(tracers.FirePath) == "function" then
                        local playerPos = realOrigin
                        if not isFiniteVec3(playerPos) then
                            playerPos = lastOrigin
                        end
                        if not isFiniteVec3(playerPos) then
                            local char = LocalPlayer.Character
                            local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
                            if root and root:IsA("BasePart") then
                                playerPos = root.Position
                            end
                        end
                        if not isFiniteVec3(playerPos) then
                            playerPos = origin
                        end
                        local style = tracers.Config and tracers.Config.Style
                        pcall(tracers.FirePath, { playerPos, newOrigin, newTarget }, style, entry._player, true)
                    elseif tracers and type(tracers.Fire) == "function" then
                        local style = tracers.Config and tracers.Config.Style
                        pcall(tracers.Fire, origin, newOrigin, style, nil, true)
                        pcall(tracers.Fire, newOrigin, newTarget, style, entry._player, true)
                    end
                end

                local shotPlayer, shotWeapon, shotHead = entry._player, weapon.uniqueId, characterHash(entry).Head

        pcall(function()
                    local onMarker = env._TapologyOnHitMarker
                    if type(onMarker) == "function" then
                        onMarker(shotPlayer, newTarget)
                end
            end)
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

table.insert(Connections, RunService.RenderStepped:Connect(function()
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
