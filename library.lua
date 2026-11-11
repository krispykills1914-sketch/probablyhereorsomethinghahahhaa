local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local TextService = cloneref(game:GetService("TextService"))
local RunService = cloneref(game:GetService("RunService"))
local GuiService = cloneref(game:GetService("GuiService"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local GuiParent = game:GetService("CoreGui")

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local Config = {
    Folder = "tapology",
    FontFolder = "tapology/fonts",
    GameFolder = "phantom forces",
    MenuKey = Enum.KeyCode.RightControl,
    Logo = "rbxassetid://101443361081291",
    SplashTime = 3,
    AutoloadTimeout = 10,
    FontName = "ProggyClean",
    FontUrl = "https://raw.githubusercontent.com/bluescan/proggyfonts/master/ProggyOriginal/ProggyClean.ttf",
    TextSize = 12,
    Bold = true,
    BoldStrength = 0.4,
    Spacing = 6,
    TabTween = 0.25,
    ToggleTween = 0.22,
    HoverLighten = 0.06,
    Indent = 12,

    Border = {
        { "Shadow", 1 },
        { "Outline", 4 },
        { "Shadow", 1 },
    },
    Theme = {
        TextOutline = rgb(0, 0, 0),
        Shadow = rgb(8, 8, 10),
        Highlight = rgb(54, 54, 60),
        Background = rgb(36, 36, 38),
        Inline = rgb(24, 24, 26),
        Outline = rgb(56, 56, 60),
        Accent = rgb(108, 147, 255),
        Text = rgb(230, 230, 232),
        SubText = rgb(130, 130, 136),
    },
}

local env = getgenv and getgenv() or _G

do
    local prev = getgenv()._TapologyServer
    if type(prev) == "table" and type(prev.Stop) == "function" then
        pcall(prev.Stop)
    end
end

getgenv()._TapologyMenuGen = (tonumber(getgenv()._TapologyMenuGen) or 0) + 1
if type(env.Tapology) == "table" and type(env.Tapology.Unload) == "function" then
    pcall(env.Tapology.Unload)
else
    env.Tapology = nil
end
if type(env.Library) == "table" and type(env.Library.Unload) == "function" then
    pcall(env.Library.Unload)
else
    env.Library = nil
end

if type(env.UI) == "table" and type(env.UI.Unload) == "function" then
    pcall(env.UI.Unload)
end

do
    local parents = { GuiParent }
    local lp = Players.LocalPlayer
    if lp then
        local pg = lp:FindFirstChildOfClass("PlayerGui")
        if pg then
            parents[#parents + 1] = pg
        end
    end
    if typeof(gethui) == "function" then
        local okHui, host = pcall(gethui)
        if okHui and typeof(host) == "Instance" then
            parents[#parents + 1] = host
        end
    end
    for _, parent in parents do
        if typeof(parent) == "Instance" then
            for _, child in parent:GetChildren() do
                if child.Name == "Tapology" and child:IsA("ScreenGui") then
                    pcall(child.Destroy, child)
                end
            end
        end
    end
end

local LocalPlayer = Players.LocalPlayer
local Connections = {}
local Themed = {}

local UI = { Config = Config, Refreshers = {}, Hotkeys = {} }

local function create(className, props)
    props = props or {}
    local instance = Instance.new(className)
    local parent = props.Parent
    for key, value in props do
        if key ~= "Parent" then
            instance[key] = value
        end
    end
    if parent ~= nil then
        local ok = pcall(function()
            instance.Parent = parent
        end)
        if not ok or instance.Parent == nil then
            pcall(function()
                instance.Parent = GuiParent
            end)
        end
    end
    return instance
end

local function theme(instance, property, slot)
    instance[property] = Config.Theme[slot]
    table.insert(Themed, { instance, property, slot })
    return instance
end

local function heartbeatUntil(step, done)
    local elapsed, connection = 0, nil
    connection = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if not step(elapsed) then
            connection:Disconnect()
            if done then
                done()
            end
        end
    end)
    table.insert(Connections, connection)
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

local function loadFont()
    for _, folder in { Config.Folder, Config.FontFolder } do
        if not isfolder(folder) then
            makefolder(folder)
        end
    end
    local fontPath = `{Config.FontFolder}/{Config.FontName}.ttf`
    local familyPath = `{Config.FontFolder}/{Config.FontName}.json`
    if not isfile(fontPath) then
        writefile(fontPath, game:HttpGet(Config.FontUrl))
    end
    writefile(familyPath, cloneref(game:GetService("HttpService")):JSONEncode({
        name = Config.FontName,
        faces = {
            { name = "Regular", weight = 400, style = "normal", assetId = getcustomasset(fontPath) },
        },
    }))
    return Font.new(getcustomasset(familyPath), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end

local ok, font = pcall(loadFont)
if not ok then
    warn(`[UI] couldn't load {Config.FontName}, falling back to Code: {font}`)
    font = Font.fromEnum(Enum.Font.Code)
end
UI.Font = font

local Mirrored = { "Text", "TextColor3", "TextTransparency", "TextXAlignment", "TextYAlignment", "TextSize", "FontFace", "TextWrapped" }

function UI.Label(parent, text, props, options)
    options = options or {}
    local slot, outline = options.Slot, options.Outline
    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = UI.Font,
        TextSize = Config.TextSize,
        Text = (type(text) == "string" and text) or "",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 0, Config.TextSize + 4),
        Parent = parent,
    })
    theme(label, "TextColor3", slot or "Text")
    for key, value in props or {} do
        label[key] = value
    end

    local layers, strokes = {}, {}
    local offsets = (options.Bold and Config.Bold) and { 1 } or {}
    if outline then
        local stroke = create("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = label })
        theme(stroke, "Color", "TextOutline")
        table.insert(strokes, stroke)
        for _, x in offsets do
            table.insert(layers, { X = x, Stroke = true })
        end
        table.insert(layers, { X = 0 })
    end
    for _, x in offsets do
        table.insert(layers, { X = x, Soft = true })
    end
    local copies = {}
    for i, layer in layers do
        local copy = create("TextLabel", {
            Name = "Layer",
            BackgroundTransparency = 1,
            Text = "",
            Position = UDim2.fromOffset(layer.X, 0),
            Size = UDim2.fromScale(1, 1),
            ZIndex = label.ZIndex + i,
            Parent = label,
        })
        if layer.Stroke then
            local stroke = create("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = copy })
            theme(stroke, "Color", "TextOutline")
            table.insert(strokes, stroke)
        end
        table.insert(copies, { Label = copy, Soft = layer.Soft })
    end
    local function fadeStrokes()
        for _, stroke in strokes do
            stroke.Transparency = label.TextTransparency
        end
    end
    fadeStrokes()
    connect(label:GetPropertyChangedSignal("TextTransparency"), fadeStrokes)
    for _, property in Mirrored do
        local function sync()
            for _, copy in copies do
                local value = label[property]
                if copy.Soft and property == "TextTransparency" then
                    value = 1 - (1 - value) * Config.BoldStrength
                end
                copy.Label[property] = value
            end
        end
        sync()
        connect(label:GetPropertyChangedSignal(property), sync)
    end
    return label
end

local dragJobs = {}
local dragBound = false
local dragCount = 0
UI.Dragging = false
local function setDragging(on)
    if on then
        dragCount += 1
    else
        dragCount = math.max(dragCount - 1, 0)
    end
    UI.Dragging = dragCount > 0
end
local function bindDrag()
    if dragBound then
        return
    end
    dragBound = true
    connect(RunService.Heartbeat, function()
        if dragCount <= 0 then
            return
        end
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
    if handle:IsA("GuiObject") then
        handle.Active = true
    end
    local job = dragJobs[frame]
    if not job then
        job = { dragging = false, armed = false }
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
    local function arm(input)
        if job.dragging or job.armed then
            return
        end
        job.armed = true
        job.dragging = false
        job.startMouse = input.Position
        job.startPosition = frame.Position
        job.pending = nil
    end
    local function release()
        if job.dragging then
            apply()
            job.dragging = false
            setDragging(false)
        end
        job.armed = false
        job.pending = nil
    end
    connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            arm(input)
        end
    end)
    if not job.globalBound then
        job.globalBound = true
        connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                release()
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if not (job.armed or job.dragging) then
                return
            end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            local delta = input.Position - job.startMouse
            if not job.dragging then
                if math.abs(delta.X) < 3 and math.abs(delta.Y) < 3 then
                    return
                end
                job.dragging = true
                setDragging(true)
            end
            job.pending = input.Position
        end)
    end
end

function UI.WindowDraggable(frame)
    if frame:IsA("GuiObject") then
        frame.Active = true
    end
    local job = dragJobs[frame]
    if not job then
        job = { dragging = false, armed = false }
        dragJobs[frame] = job
        bindDrag()
    end
    if job.windowBound then
        return
    end
    job.windowBound = true
    local function inside(pos)
        local p, s = frame.AbsolutePosition, frame.AbsoluteSize
        return pos.X >= p.X and pos.Y >= p.Y and pos.X <= p.X + s.X and pos.Y <= p.Y + s.Y
    end
    local function overGroupbox(pos)
        if not UI.Gui then
            return false
        end
        local objects = UI.Gui:GetGuiObjectsAtPosition(pos.X, pos.Y)
        for _, object in objects do
            local node = object
            while node and node ~= frame do
                if node:GetAttribute("TapologyGroupbox") then
                    return true
                end
                node = node.Parent
            end
        end
        return false
    end
    local function topIsOurs(pos)
        if not UI.Gui then
            return false
        end
        local objects = UI.Gui:GetGuiObjectsAtPosition(pos.X, pos.Y)
        for _, object in objects do
            if object:IsA("TextBox") then
                return false
            end
            if object:IsDescendantOf(frame) or object == frame then
                return true
            end
        end
        return false
    end
    connect(UserInputService.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        if UI.Gui and UI.Gui.Enabled == false then
            return
        end
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        if not inside(pos) or not topIsOurs(pos) or overGroupbox(pos) then
            return
        end
        if job.dragging or job.armed then
            return
        end
        job.armed = true
        job.dragging = false
        job.startMouse = input.Position
        job.startPosition = frame.Position
        job.pending = nil
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        if job.dragging then
            local pending = job.pending
            if pending and job.startMouse and job.startPosition then
                local delta = pending - job.startMouse
                local pos = job.startPosition
                frame.Position = UDim2.new(pos.X.Scale, pos.X.Offset + delta.X, pos.Y.Scale, pos.Y.Offset + delta.Y)
            end
            job.dragging = false
            setDragging(false)
        end
        job.armed = false
        job.pending = nil
    end)
    connect(UserInputService.InputChanged, function(input)
        if not (job.armed or job.dragging) then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local delta = input.Position - job.startMouse
        if not job.dragging then
            if math.abs(delta.X) < 3 and math.abs(delta.Y) < 3 then
                return
            end
            job.dragging = true
            setDragging(true)
        end
        job.pending = input.Position
    end)
end

local function outlined(instance, slot)
    theme(create("UIStroke", {
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = instance,
    }), "Color", slot or "Outline")
    return instance
end

local function shade(instance, top, bottom)
    create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(top, top, top), Color3.new(bottom, bottom, bottom)), Parent = instance })
    return instance
end

local function inset(instance)
    outlined(instance, "Shadow")
    outlined(create("Frame", {
        Name = "Rim",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 3,
        Parent = instance,
    }), "Highlight")
    for _, edge in { { Size = UDim2.new(1, 0, 0, 10), Rotation = 90 }, { Size = UDim2.new(0, 8, 1, 0), Rotation = 0 } } do
        local shadow = create("Frame", {
            Name = "InnerShadow",
            Size = edge.Size,
            BorderSizePixel = 0,
            ZIndex = 0,
            Parent = instance,
        })
        theme(shadow, "BackgroundColor3", "Shadow")
        create("UIGradient", {
            Rotation = edge.Rotation,
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) }),
            Parent = shadow,
        })
    end
    return shade(instance, 0.6, 1)
end

local Container = {}
Container.__index = Container

local function container(frame)
    return setmetatable({ Frame = frame }, Container)
end

function Container:Toggle(text, default, callback, options)
    return UI.Toggle(self.Frame, text, default, callback, options)
end
function Container:Slider(text, options, callback)
    return UI.Slider(self.Frame, text, options, callback)
end
function Container:ColorPicker(text, default, callback, options)
    return UI.ColorPicker(self.Frame, text, default, callback, options)
end
function Container:AlphaColorPicker(text, default, alpha, callback, options)
    return UI.AlphaColorPicker(self.Frame, text, default, alpha, callback, options)
end
function Container:Dropdown(text, options, callback)
    return UI.Dropdown(self.Frame, text, options, callback)
end
function Container:List(text, options, callback)
    return UI.List(self.Frame, text, options, callback)
end
function Container:Textbox(text, options, callback)
    return UI.Textbox(self.Frame, text, options, callback)
end
function Container:Button(text, callback)
    return UI.Button(self.Frame, text, callback)
end
function Container:Keybind(text, default, onPress)
    return UI.KeybindRow(self.Frame, text, default, onPress)
end
function Container:Label(text)
    return UI.Label(self.Frame, text, { LayoutOrder = #self.Frame:GetChildren() * 10 }, { Slot = "SubText", Outline = true })
end

UI.Flags = {}
UI.LastRegistered = os.clock()
local function register(parent, text, options, get, set)
    UI.LastRegistered = os.clock()
    if options and options.Save == false then return end
    local base = options and options.Flag or `{parent:GetAttribute("Path") or "ui"}/{text}`
    local flag, n = base, 1
    while UI.Flags[flag] do
        n += 1
        flag = `{base} #{n}`
    end
    UI.Flags[flag] = { Get = get, Set = set }
    return flag
end

local function encodeUDim2(value)
    return { value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset }
end
local function decodeUDim2(data)
    return UDim2.new(data[1], data[2], data[3], data[4])
end

local function registerPosition(flag, frame)
    UI.Flags[flag] = {
        Get = function()
            return encodeUDim2(frame.Position)
        end,
        Set = function(data)
            frame.Position = decodeUDim2(data)
        end,
    }
end

local function addBorder(frame)
    local offset = 0
    for i, ring in Config.Border do
        local holder = create("Frame", {
            Name = "Border" .. i,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(-offset, -offset),
            Size = UDim2.new(1, offset * 2, 1, offset * 2),
            Parent = frame,
        })
        theme(create("UIStroke", {
            Thickness = ring[2],
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            LineJoinMode = Enum.LineJoinMode.Miter,
            Parent = holder,
        }), "Color", ring[1])
        offset += ring[2]
    end
end

local layoutOrders = setmetatable({}, { __mode = "k" })
local function nextOrder(parent)
    local ok, count = pcall(function()
        return #parent:GetChildren()
    end)
    if ok and type(count) == "number" then
        layoutOrders[parent] = count
        return count * 10
    end
    local n = (layoutOrders[parent] or 0) + 1
    layoutOrders[parent] = n
    return n * 10
end

local function row(parent, name, height)
    local rowName = (type(name) == "string" and name ~= "") and name or "Row"
    return create("TextButton", {
        Name = rowName,
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height or Config.TextSize + 4),
        LayoutOrder = nextOrder(parent),
        Parent = parent,
    })
end

local ToggleBox = Config.TextSize - 1
local RowGap = 4

local function visualBottom(gui)
    local bottom = gui:GetAttribute("Bottom")
    return gui.AbsolutePosition.Y + (bottom or gui.AbsoluteSize.Y)
end

local function childSection(anchor)
    local frame = create("Frame", {
        Name = anchor.Name .. " children",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = anchor.LayoutOrder + 1,
        Visible = false,
        Parent = anchor.Parent,
    })
    local guide = create("Frame", {
        Name = "Guide",
        Position = UDim2.fromOffset(1 + math.floor(ToggleBox / 2), 0),
        Size = UDim2.new(0, 1, 1, 0),
        BorderSizePixel = 0,
        Parent = frame,
    })
    theme(guide, "BackgroundColor3", "Outline")
    local list = create("Frame", {
        Name = "List",
        Position = UDim2.fromOffset(Config.Indent, 0),
        Size = UDim2.new(1, -Config.Indent, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = frame,
    })
    create("UIListLayout", { Padding = UDim.new(0, RowGap), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
    list:SetAttribute("Path", anchor.Parent:GetAttribute("Path"))

    local function fit()
        local last
        for _, child in list:GetChildren() do
            if child:IsA("GuiObject") and child.Visible and (not last or child.LayoutOrder >= last.LayoutOrder) then
                last = child
            end
        end
        local length = last and math.max(visualBottom(last) - frame.AbsolutePosition.Y, 0) or 0
        guide.Size = UDim2.fromOffset(1, length)

        frame:SetAttribute("Bottom", length)
    end
    connect(list:GetPropertyChangedSignal("AbsoluteSize"), fit)
    connect(list.ChildAdded, function()
        task.defer(fit)
    end)

    local section = container(list)
    section.Section = frame
    return section
end

local function textWidth(text)
    local params = Instance.new("GetTextBoundsParams")
    params.Text, params.Font, params.Size, params.Width = text, UI.Font, Config.TextSize, 1000
    local ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
    return ok and bounds.X or #text * 7
end

local CharWidth
local function charWidth()
    CharWidth = CharWidth or textWidth("m")
    return CharWidth
end

local function fitText(text, width)
    local fits = math.floor(width / charWidth())
    if width <= 0 or #text <= fits then
        return text
    end
    return text:sub(1, math.max(fits - 3, 0)) .. "..."
end

local function lighten(color, amount)
    return color:Lerp(Color3.new(1, 1, 1), amount or Config.HoverLighten)
end

local function fillGradient(instance)
    create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.45, 0.45, 0.5)),
        Parent = instance,
    })
end

local function inside(gui, point)
    local position, size = gui.AbsolutePosition, gui.AbsoluteSize
    return point.X >= position.X and point.X <= position.X + size.X and point.Y >= position.Y and point.Y <= position.Y + size.Y
end

local function isClick(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function dragArea(surface, onMove)
    local held = false
    connect(surface.InputBegan, function(input)
        if isClick(input) then
            held = true
            onMove(input.Position)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if isClick(input) then
            held = false
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if held and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            onMove(input.Position)
        end
    end)
end

local Popup = { Open = nil }
local function popupFrame(name, opener)
    local frame = create("Frame", { Name = name, BorderSizePixel = 0, Visible = false, ZIndex = 20, Parent = UI.Gui })
    theme(frame, "BackgroundColor3", "Background")
    outlined(frame, "Shadow")
    shade(frame, 1.08, 0.88)
    connect(UserInputService.InputBegan, function(input)
        if frame.Visible and isClick(input) and not inside(frame, input.Position) and not inside(opener, input.Position) then
            frame.Visible = false
        end
    end)
    return frame
end

local function openPopup(frame, opener, x, y)
    if Popup.Open and Popup.Open ~= frame then
        Popup.Open.Visible = false
    end

    local inset = GuiService:GetGuiInset()
    frame.Position = UDim2.fromOffset(opener.AbsolutePosition.X + inset.X + x, opener.AbsolutePosition.Y + inset.Y + y)
    frame.Visible = true
    Popup.Open = frame
end

function UI.Groupbox(column, title, path)
    local titleHeight = Config.TextSize + 8
    local box = create("Frame", {
        Name = title,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(column),
        Parent = column,
    })
    theme(box, "BackgroundColor3", "Background")
    box:SetAttribute("TapologyGroupbox", true)
    outlined(box, "Shadow")
    outlined(create("Frame", {
        Name = "Rim",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 3,
        Parent = box,
    }), "Highlight")
    shade(box, 1.08, 0.88)
    local titleLabel = UI.Label(box, title, {
        Position = UDim2.fromOffset(Config.Spacing + 2, 0),
        Size = UDim2.new(1, -(Config.Spacing + 2) * 2, 0, titleHeight),
    }, { Outline = true, Bold = true })
    theme(create("Frame", {
        Name = "Separator",
        Position = UDim2.fromOffset(Config.Spacing, titleHeight),
        Size = UDim2.new(1, -Config.Spacing * 2, 0, 1),
        BorderSizePixel = 0,
        Parent = box,
    }), "BackgroundColor3", "Outline")

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(0, titleHeight + 1),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = box,
    })
    create("UIPadding", {
        PaddingLeft = UDim.new(0, Config.Spacing),
        PaddingRight = UDim.new(0, Config.Spacing),
        PaddingTop = UDim.new(0, Config.Spacing),
        PaddingBottom = UDim.new(0, Config.Spacing),
        Parent = content,
    })
    create("UIListLayout", { Padding = UDim.new(0, RowGap), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
    path = path or title
    content:SetAttribute("Path", path)

    local group = container(content)
    group.Box, group.Title, group.Subtabs = box, title, {}

    local header
    local function paintSubtabs()
        for _, tab in group.Subtabs do
            local selected = tab == group.Selected
            tab.Label.TextColor3 = Config.Theme[selected and "Accent" or (tab.Hovered and "Text" or "SubText")]
            tab.Frame.Visible = selected
        end
    end
    function group:Subtab(name)
        if not header then
            titleLabel.Visible = false
            header = create("Frame", {
                Name = "Subtabs",
                Position = UDim2.fromOffset(Config.Spacing + 2, 0),
                Size = UDim2.new(1, -(Config.Spacing + 2) * 2, 0, titleHeight),
                BackgroundTransparency = 1,
                Parent = box,
            })
            create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = header })
            table.insert(UI.Refreshers, paintSubtabs)
        end
        local button = create("TextButton", {
            Name = name,
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            LayoutOrder = #group.Subtabs + 1,
            Parent = header,
        })
        local frame = create("Frame", {
            Name = name,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = #group.Subtabs + 1,
            Visible = false,
            Parent = content,
        })
        frame:SetAttribute("Path", `{path}/{name}`)
        create("UIListLayout", { Padding = UDim.new(0, RowGap), SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })
        local tab = {
            Name = name,
            Button = button,
            Frame = frame,
            Label = UI.Label(button, name, { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X }, { Slot = "SubText", Outline = true, Bold = true }),
        }
        table.insert(group.Subtabs, tab)
        group.Selected = group.Selected or tab
        connect(button.MouseButton1Click, function()
            group.Selected = tab
            paintSubtabs()
        end)
        connect(button.MouseEnter, function()
            tab.Hovered = true
            paintSubtabs()
        end)
        connect(button.MouseLeave, function()
            tab.Hovered = false
            paintSubtabs()
        end)
        paintSubtabs()
        local sub = container(frame)
        sub.Tab = tab
        return sub
    end
    return group
end

function UI.Toggle(parent, text, default, callback, options)
    local size = ToggleBox
    local rowHeight = Config.TextSize + 4
    local boxTop = math.floor((rowHeight - size) / 2)
    local line = row(parent, text, rowHeight)
    line:SetAttribute("Bottom", boxTop + size + 1)
    local box = create("Frame", {
        Name = "Box",
        Position = UDim2.fromOffset(1, boxTop),
        Size = UDim2.fromOffset(size, size),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = line,
    })
    shade(box, 0.6, 1)
    outlined(box, "Shadow")
    local fill = create("Frame", {
        Name = "Fill",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.fromScale(1, 0),
        BorderSizePixel = 0,
        Parent = box,
    })
    fillGradient(fill)
    local label = UI.Label(line, text, {
        Position = UDim2.fromOffset(size + 8, 0),
        Size = UDim2.new(1, -(size + 8), 1, 0),
    }, { Slot = "SubText", Outline = true })

    local toggle = { Value = false, Row = line, Sections = {} }
    local hovered = false
    local function paint(instant)
        local info = TweenInfo.new(instant and 0 or Config.ToggleTween, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenService:Create(fill, info, { Size = UDim2.fromScale(1, toggle.Value and 1 or 0) }):Play()
        TweenService:Create(label, info, { TextColor3 = Config.Theme[toggle.Value and "Text" or "SubText"] }):Play()
        box.BackgroundColor3 = hovered and lighten(Config.Theme.Inline) or Config.Theme.Inline
        fill.BackgroundColor3 = hovered and lighten(Config.Theme.Accent) or Config.Theme.Accent
        for _, section in toggle.Sections do
            section.Section.Visible = toggle.Value
        end
    end
    table.insert(UI.Refreshers, function()
        paint(true)
    end)

    function toggle:Set(value, instant)
        value = value and true or false
        local changed = value ~= toggle.Value
        toggle.Value = value
        paint(instant)
        if changed and callback then
            task.spawn(callback, value)
        end
    end

    function toggle:ColorPicker(color, onChange, swatchOptions)
        return UI.Swatch(line, color, onChange, swatchOptions)
    end
    function toggle:AlphaColorPicker(color, alpha, onChange, swatchOptions)
        return UI.AlphaSwatch(line, color, alpha, onChange, swatchOptions)
    end

    function toggle:Keybind(key, onPress)
        toggle.Bind = UI.Keybind(line, key, function()
            toggle:Set(not toggle.Value)
            if onPress then
                onPress(toggle.Value)
            end
        end)

        local path = parent:GetAttribute("Path") or ""
        table.insert(UI.Hotkeys, {
            Name = text == "enabled" and (path:match("([^/]+)$") or text) or text,
            Bind = toggle.Bind,
            Toggle = toggle,
        })
        return toggle.Bind
    end

    function toggle:Settings(title)
        return UI.ConfigWindow(line, title or text)
    end

    function toggle:Children()
        local section = childSection(line)
        table.insert(toggle.Sections, section)
        section.Section.Visible = toggle.Value
        return section
    end

    connect(line.MouseButton1Click, function()
        toggle:Set(not toggle.Value)
    end)
    connect(line.MouseEnter, function()
        hovered = true
        paint(true)
    end)
    connect(line.MouseLeave, function()
        hovered = false
        paint(true)
    end)
    toggle:Set(default, true)
    toggle.Flag = register(parent, text, options, function()
        return toggle.Value
    end, function(value)
        toggle:Set(value)
    end)
    return toggle
end

local function accessories(line)
    local strip = line:FindFirstChild("Accessories")
    if not strip then
        strip = create("Frame", {
            Name = "Accessories",
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, -1, 0, Config.TextSize + 4),
            BackgroundTransparency = 1,
            Parent = line,
        })
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = strip,
        })
    end
    return strip
end

local OpenConfigWindow
local function configWindow(line, title)

    local rowHeight = Config.TextSize + 4
    local dots = create("TextButton", {
        Name = "Settings",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(11, rowHeight),
        LayoutOrder = 1000,
        Parent = accessories(line),
    })
    local middle = math.floor((rowHeight - ToggleBox) / 2) + math.floor(ToggleBox / 2)
    local dotPixels = {}
    for i = 0, 2 do
        local dot = create("Frame", {
            Position = UDim2.fromOffset(1 + i * 4, middle),
            Size = UDim2.fromOffset(2, 2),
            BorderSizePixel = 0,
            Parent = dots,
        })
        outlined(dot, "TextOutline")
        table.insert(dotPixels, dot)
    end
    local dotsLabel = setmetatable({}, {
        __newindex = function(_, _, color)
            for _, dot in dotPixels do
                dot.BackgroundColor3 = color
            end
        end,
    })

    local frame = create("Frame", { Name = "ConfigWindow", BorderSizePixel = 0, Visible = false, ZIndex = 15, Parent = UI.Gui })
    theme(frame, "BackgroundColor3", "Background")
    shade(frame, 1, 0.86)
    addBorder(frame)
    theme(create("Frame", { Name = "Accent", Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, ZIndex = 4, Parent = frame }), "BackgroundColor3", "Accent")
    local content = create("Frame", {
        Name = "Content",
        Size = UDim2.fromOffset(200, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = frame,
    })
    local titleHeight = Config.TextSize + 8
    UI.Label(content, title, {
        Position = UDim2.fromOffset(Config.Spacing + 2, 1),
        Size = UDim2.new(1, -(Config.Spacing + 2) * 2, 0, titleHeight),
    }, { Outline = true, Bold = true })
    theme(create("Frame", {
        Name = "Separator",
        Position = UDim2.fromOffset(Config.Spacing, titleHeight + 1),
        Size = UDim2.new(1, -Config.Spacing * 2, 0, 1),
        BorderSizePixel = 0,
        Parent = content,
    }), "BackgroundColor3", "Outline")
    local body = create("Frame", {
        Name = "Body",
        Position = UDim2.fromOffset(Config.Spacing, titleHeight + 2 + Config.Spacing),
        Size = UDim2.new(1, -Config.Spacing * 2, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = content,
    })
    create("UIPadding", { PaddingBottom = UDim.new(0, Config.Spacing), Parent = content })
    create("UIListLayout", { Padding = UDim.new(0, RowGap), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
    body:SetAttribute("Path", `{line.Parent:GetAttribute("Path") or "ui"}/{title}`)
    local function fit()
        frame.Size = UDim2.fromOffset(content.AbsoluteSize.X, content.AbsoluteSize.Y)
    end
    connect(content:GetPropertyChangedSignal("AbsoluteSize"), fit)

    local hovered = false
    local function paint()
        dotsLabel.TextColor3 = Config.Theme[frame.Visible and "Accent" or (hovered and "Text" or "SubText")]
    end
    table.insert(UI.Refreshers, paint)
    local function close()
        frame.Visible = false
        if Popup.Open then
            Popup.Open.Visible = false
        end
    end
    connect(frame:GetPropertyChangedSignal("Visible"), paint)
    connect(dots.MouseButton1Click, function()
        if frame.Visible then
            return close()
        end
        if OpenConfigWindow and OpenConfigWindow ~= frame then
            OpenConfigWindow.Visible = false
        end

        local inset = GuiService:GetGuiInset()
        frame.Position = UDim2.fromOffset(dots.AbsolutePosition.X + dots.AbsoluteSize.X + 12 + inset.X, line.AbsolutePosition.Y - 2 + inset.Y)
        fit()
        frame.Visible = true
        OpenConfigWindow = frame
    end)
    connect(dots.MouseEnter, function()
        hovered = true
        paint()
    end)
    connect(dots.MouseLeave, function()
        hovered = false
        paint()
    end)
    connect(UserInputService.InputBegan, function(input)
        if not frame.Visible or not isClick(input) then return end
        local point = input.Position
        local inChild = Popup.Open and Popup.Open.Visible and inside(Popup.Open, point)
        if not inside(frame, point) and not inside(dots, point) and not inChild then
            close()
        end
    end)
    paint()
    local section = container(body)
    section.Window = frame
    return section
end
UI.ConfigWindow = configWindow

local function makeSwatch(parent, default, alpha, callback, options)
    local hasAlpha = type(alpha) == "number"
    local strip = accessories(parent)
    local swatch = create("TextButton", {
        Name = "Swatch",
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromOffset(20, Config.TextSize - 2),
        BorderSizePixel = 0,
        LayoutOrder = #strip:GetChildren(),
        Parent = strip,
    })
    fillGradient(swatch)
    outlined(swatch, "Shadow")

    local zIndex = 20
    local popup = popupFrame("ColorPicker", swatch)
    popup.Size = UDim2.fromOffset(hasAlpha and 204 or 178, 172)
    theme(create("Frame", { Name = "Accent", Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, ZIndex = zIndex + 3, Parent = popup }), "BackgroundColor3", "Accent")

    local square = create("TextButton", {
        Name = "Square",
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.fromOffset(6, 7),
        Size = UDim2.fromOffset(140, 140),
        BorderSizePixel = 0,
        ZIndex = zIndex + 1,
        Parent = popup,
    })
    outlined(square, "Shadow")
    local whites = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = zIndex + 1, Parent = square })
    create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = whites })
    local blacks = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = zIndex + 2, Parent = square })
    create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = blacks })
    local squareCursor = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(4, 4),
        BackgroundTransparency = 1,
        ZIndex = zIndex + 3,
        Parent = square,
    })
    create("UIStroke", { Thickness = 1, Color = Color3.new(1, 1, 1), LineJoinMode = Enum.LineJoinMode.Miter, Parent = squareCursor })

    local hueBar = create("TextButton", {
        Name = "Hue",
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.fromOffset(152, 7),
        Size = UDim2.fromOffset(20, 140),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = zIndex + 1,
        Parent = popup,
    })
    outlined(hueBar, "Shadow")
    local hues = {}
    for i = 0, 6 do
        table.insert(hues, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 % 1, 1, 1)))
    end
    create("UIGradient", { Rotation = 90, Color = ColorSequence.new(hues), Parent = hueBar })
    local hueCursor = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = zIndex + 2,
        Parent = hueBar,
    })
    outlined(hueCursor, "Shadow")

    local alphaBar, alphaFill, alphaCursor
    if hasAlpha then
        alphaBar = create("TextButton", {
            Name = "Alpha",
            Text = "",
            AutoButtonColor = false,
            Position = UDim2.fromOffset(178, 7),
            Size = UDim2.fromOffset(20, 140),
            BackgroundColor3 = Color3.fromRGB(20, 20, 22),
            BorderSizePixel = 0,
            ZIndex = zIndex + 1,
            Parent = popup,
        })
        outlined(alphaBar, "Shadow")
        alphaFill = create("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = zIndex + 1, Parent = alphaBar })
        create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 1), Parent = alphaFill })
        alphaCursor = create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = zIndex + 2,
            Parent = alphaBar,
        })
        outlined(alphaCursor, "Shadow")
    end

    local readout = UI.Label(popup, "", {
        Position = UDim2.fromOffset(7, 150),
        Size = UDim2.new(1, -14, 0, Config.TextSize + 4),
        ZIndex = zIndex + 1,
    }, { Slot = "SubText", Outline = true })

    local picker = { Value = default or Config.Theme.Accent, Alpha = hasAlpha and math.clamp(alpha, 0, 1) or 1, Swatch = swatch, Popup = popup }
    local h, s, v = picker.Value:ToHSV()
    local function paint()
        local color = Color3.fromHSV(h, s, v)
        picker.Value = color
        swatch.BackgroundColor3 = color
        square.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        squareCursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.fromScale(0, h)
        local text = string.format("#%s  %d, %d, %d", color:ToHex(), color.R * 255 + 0.5, color.G * 255 + 0.5, color.B * 255 + 0.5)
        if hasAlpha then
            alphaFill.BackgroundColor3 = color
            alphaCursor.Position = UDim2.fromScale(0, 1 - picker.Alpha)
            text ..= string.format("  %d%%", picker.Alpha * 100 + 0.5)
        end
        readout.Text = text
    end
    local function changed()
        paint()
        if callback then
            if hasAlpha then
                task.spawn(callback, picker.Value, picker.Alpha)
            else
                task.spawn(callback, picker.Value)
            end
        end
    end
    function picker:Set(color, alpha)
        h, s, v = color:ToHSV()
        if hasAlpha and type(alpha) == "number" then
            picker.Alpha = math.clamp(alpha, 0, 1)
        end
        changed()
    end
    function picker:ColorPicker(color, onChange, swatchOptions)
        return UI.Swatch(parent, color, onChange, swatchOptions)
    end
    function picker:AlphaColorPicker(color, startAlpha, onChange, swatchOptions)
        return UI.AlphaSwatch(parent, color, startAlpha, onChange, swatchOptions)
    end

    function picker:Settings(title)
        local line = parent:IsA("GuiObject") and parent or swatch.Parent
        if line and line.Name == "Accessories" then
            line = line.Parent
        end
        local section = UI.ConfigWindow(line, title or "settings")
        local strip = line and line:FindFirstChild("Accessories")
        local settingsBtn = strip and strip:FindFirstChild("Settings")
        if settingsBtn then
            settingsBtn.LayoutOrder = -10
        end
        return section
    end
    picker.Line = parent

    dragArea(square, function(point)
        s = math.clamp((point.X - square.AbsolutePosition.X) / square.AbsoluteSize.X, 0, 1)
        v = 1 - math.clamp((point.Y - square.AbsolutePosition.Y) / square.AbsoluteSize.Y, 0, 1)
        changed()
    end)
    dragArea(hueBar, function(point)
        h = math.clamp((point.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 0.999)
        changed()
    end)
    if hasAlpha then
        dragArea(alphaBar, function(point)
            picker.Alpha = 1 - math.clamp((point.Y - alphaBar.AbsolutePosition.Y) / alphaBar.AbsoluteSize.Y, 0, 1)
            changed()
        end)
    end
    connect(swatch.MouseButton1Click, function()
        if popup.Visible then
            popup.Visible = false
        else
            openPopup(popup, swatch, swatch.AbsoluteSize.X - popup.Size.X.Offset, swatch.AbsoluteSize.Y + 4)
        end
    end)

    local menu = popupFrame("ColorMenu", swatch)
    menu.Size = UDim2.fromOffset(90, 0)
    menu.AutomaticSize = Enum.AutomaticSize.Y
    local menuList = create("Frame", {
        Name = "List",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = menu,
    })
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        Parent = menuList,
    })
    create("UIListLayout", { Padding = UDim.new(0, RowGap), SortOrder = Enum.SortOrder.LayoutOrder, Parent = menuList })
    UI.Button(menuList, "copy", function()
        UI.ColorClipboard = picker.Value
        UI.AlphaClipboard = hasAlpha and picker.Alpha or nil
        local hex = `#{picker.Value:ToHex()}`
        if setclipboard then
            pcall(setclipboard, hex)
        end
        menu.Visible = false
        UI:Notify(`copied color {hex}`, 2)
    end)
    UI.Button(menuList, "paste", function()
        menu.Visible = false
        if not UI.ColorClipboard then
            return UI:Notify("no color copied yet", 2)
        end
        picker:Set(UI.ColorClipboard, UI.AlphaClipboard)
        UI:Notify(`pasted color #{UI.ColorClipboard:ToHex()}`, 2)
    end)
    connect(swatch.MouseButton2Click, function()
        if menu.Visible then
            menu.Visible = false
        else
            openPopup(menu, swatch, swatch.AbsoluteSize.X - menu.Size.X.Offset, swatch.AbsoluteSize.Y + 4)
        end
    end)
    paint()

    picker.Flag = register(parent.Parent, `{parent.Name}/color`, options, function()
        local hex = picker.Value:ToHex()
        return hasAlpha and hex .. string.format("%02x", math.floor(picker.Alpha * 255 + 0.5)) or hex
    end, function(hex)
        hex = tostring(hex):gsub("^#", "")
        local alpha = #hex == 8 and tonumber(hex:sub(7, 8), 16)
        picker:Set(Color3.fromHex(hex:sub(1, 6)), alpha and alpha / 255)
    end)
    return picker
end

function UI.Swatch(parent, default, callback, options)
    return makeSwatch(parent, default, nil, callback, options)
end
function UI.AlphaSwatch(parent, default, alpha, callback, options)
    return makeSwatch(parent, default, type(alpha) == "number" and alpha or 1, callback, options)
end

local function colorRow(parent, text)
    local line = row(parent, text)
    line:SetAttribute("Bottom", math.floor((Config.TextSize + 4 + Config.TextSize - 2) / 2) + 1)
    UI.Label(line, text, { Size = UDim2.new(1, -28, 1, 0), Position = UDim2.fromOffset(1, 0) }, { Outline = true })
    return line
end
function UI.ColorPicker(parent, text, default, callback, options)
    return UI.Swatch(colorRow(parent, text), default, callback, options)
end
function UI.AlphaColorPicker(parent, text, default, alpha, callback, options)
    return UI.AlphaSwatch(colorRow(parent, text), default, alpha, callback, options)
end

function UI.Slider(parent, text, options, callback)
    options = options or {}
    local min, max = options.Min or 0, options.Max or 100
    local decimals, suffix = options.Decimals or 0, options.Suffix or ""
    local labelHeight, barHeight = Config.TextSize + 4, 10
    local line = row(parent, text, labelHeight + barHeight + math.ceil(Config.TextSize / 2) + 2)
    line:SetAttribute("Bottom", labelHeight + barHeight + 1)
    UI.Label(line, text, { Position = UDim2.fromOffset(1, 0), Size = UDim2.new(1, -2, 0, labelHeight) }, { Outline = true })

    local bar = create("TextButton", {
        Name = "Bar",
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.fromOffset(1, labelHeight),
        Size = UDim2.new(1, -2, 0, barHeight),
        BorderSizePixel = 0,
        Parent = line,
    })
    shade(bar, 0.6, 1)
    outlined(bar, "Shadow")
    local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = bar })
    fillGradient(fill)
    local value = UI.Label(bar, "", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(0, Config.TextSize),
        AutomaticSize = Enum.AutomaticSize.X,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 3,
    }, { Outline = true })

    local slider = { Value = min }
    local hovered = false
    local function place()
        if UI.Dragging then
            return
        end
        local fraction = (slider.Value - min) / math.max(max - min, 1e-9)
        local width = bar.AbsoluteSize.X
        if width <= 0 then
            return
        end
        local half = math.ceil((value.TextBounds.X + 2) / 2)
        local low = math.min(half, width)
        local high = math.max(width - half, low)
        local x = math.clamp(math.floor(fraction * width + 0.5), low, high)
        value.Position = UDim2.new(0, x, 1, 0)
    end
    local function paint()
        value.Text = string.format(`%.{decimals}f`, slider.Value) .. suffix
        fill.Size = UDim2.fromScale((slider.Value - min) / math.max(max - min, 1e-9), 1)
        bar.BackgroundColor3 = hovered and lighten(Config.Theme.Inline) or Config.Theme.Inline
        fill.BackgroundColor3 = hovered and lighten(Config.Theme.Accent) or Config.Theme.Accent
        place()
    end
    table.insert(UI.Refreshers, paint)
    connect(bar:GetPropertyChangedSignal("AbsoluteSize"), place)
    connect(value:GetPropertyChangedSignal("TextBounds"), place)

    function slider:Set(newValue)
        local step = 10 ^ -decimals
        local lo, hi = math.min(min, max), math.max(min, max)
        newValue = math.clamp(math.floor(newValue / step + 0.5) * step, lo, hi)
        local changed = newValue ~= slider.Value
        slider.Value = newValue
        paint()
        if changed and callback then
            task.spawn(callback, newValue)
        end
    end
    local function ctrlHeld()
        return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
    end
    dragArea(bar, function(point)
        if ctrlHeld() then return end
        slider:Set(min + (max - min) * math.clamp((point.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1))
    end)

    local entry
    local function openEntry()
        if not entry then
            local frame = popupFrame("SliderInput", bar)
            local list = create("Frame", { Name = "List", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = frame })
            create("UIPadding", {
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                Parent = list,
            })
            create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
            entry = { Frame = frame, Box = UI.Textbox(list, nil, { Placeholder = `{min} - {max}{suffix}`, Save = false }) }
            connect(entry.Box.Box.FocusLost, function(enterPressed)
                if enterPressed then
                    local number = tonumber((entry.Box.Value:gsub("[^%d%.%-]", "")))
                    if number then
                        slider:Set(number)
                    end
                end
                frame.Visible = false
                entry.Box:Set("")
            end)
        end
        entry.Frame.Size = UDim2.fromOffset(bar.AbsoluteSize.X + 2, Config.TextSize + 6 + 8)
        openPopup(entry.Frame, bar, -1, bar.AbsoluteSize.Y + 4)
        task.defer(function()
            entry.Box.Box:CaptureFocus()
        end)
    end
    connect(bar.InputBegan, function(input)
        if isClick(input) and ctrlHeld() then
            openEntry()
        end
    end)
    connect(bar.MouseEnter, function()
        hovered = true
        paint()
    end)
    connect(bar.MouseLeave, function()
        hovered = false
        paint()
    end)
    slider:Set(options.Default or min)
    slider.Flag = register(parent, text, options, function()
        return slider.Value
    end, function(value)
        slider:Set(value)
    end)
    return slider
end

function UI.Dropdown(parent, text, options, callback)
    options = options or {}
    local values, multi = options.Values or {}, options.Multi
    local hasLabel = type(text) == "string" and text ~= ""
    local labelHeight = hasLabel and Config.TextSize + 4 or 0
    local fieldHeight, optionHeight = Config.TextSize + 6, Config.TextSize + 6
    local line = row(parent, hasLabel and text or "Dropdown", labelHeight + fieldHeight)
    line:SetAttribute("Bottom", labelHeight + fieldHeight + 1)
    if hasLabel then
        UI.Label(line, text, { Position = UDim2.fromOffset(1, 0), Size = UDim2.new(1, -2, 0, labelHeight) }, { Outline = true })
    end

    local field = create("TextButton", {
        Name = "Field",
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.fromOffset(1, labelHeight),
        Size = UDim2.new(1, -2, 0, fieldHeight),
        BorderSizePixel = 0,
        Parent = line,
    })
    theme(field, "BackgroundColor3", "Inline")
    outlined(field, "Shadow")
    local shown = UI.Label(field, "", {
        Position = UDim2.fromOffset(6, 0),
        Size = UDim2.new(1, -22, 1, 0),
    }, { Outline = true })

    local chevron = create("Frame", {
        Name = "Chevron",
        Position = UDim2.new(1, -12, 0, math.floor((fieldHeight - 3) / 2)),
        Size = UDim2.fromOffset(5, 3),
        BackgroundTransparency = 1,
        Parent = field,
    })
    local chevronPixels = {}
    for _, p in { { 0, 0 }, { 4, 0 }, { 1, 1 }, { 3, 1 }, { 2, 2 } } do
        table.insert(chevronPixels, create("Frame", {
            Position = UDim2.fromOffset(p[1], p[2]),
            Size = UDim2.fromOffset(1, 1),
            BorderSizePixel = 0,
            Parent = chevron,
        }))
    end
    local wasOpen = false
    local maxVisible = 10

    local list = popupFrame("Dropdown", field)
    local scroller = create("ScrollingFrame", {
        Name = "List",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 2,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 21,
        Parent = list,
    })
    theme(scroller, "ScrollBarImageColor3", "Accent")
    local listLayout = create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroller })
    create("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2), Parent = scroller })

    local dropdown = { Value = multi and {} or nil, Sections = {} }
    local hovered = false
    local optionRows = {}
    local function isSelected(option)
        if multi then
            return dropdown.Value[option] == true
        end
        return dropdown.Value == option
    end
    local function fitList()
        local count = math.max(#values, 1)
        local visible = math.min(count, maxVisible)
        local height = visible * optionHeight + 4
        list.Size = UDim2.fromOffset(math.max(field.AbsoluteSize.X, 80), height)
        scroller.CanvasSize = UDim2.fromOffset(0, count * optionHeight + 4)
        scroller.ScrollBarThickness = count > maxVisible and 2 or 0
    end
    local function paint()
        if multi then
            local picked = {}
            for _, option in values do
                if dropdown.Value[option] then
                    table.insert(picked, option)
                end
            end
            shown.Text = #picked > 0 and table.concat(picked, ", ") or "none"
        else
            shown.Text = dropdown.Value ~= nil and tostring(dropdown.Value) or "none"
        end

        if not UI.Dragging then
            shown.Text = fitText(shown.Text, field.AbsoluteSize.X - 6 - 16)
        end
        if list.Visible ~= wasOpen then
            wasOpen = list.Visible
            TweenService:Create(chevron, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Rotation = wasOpen and 180 or 0 }):Play()
        end
        for _, pixel in chevronPixels do
            pixel.BackgroundColor3 = Config.Theme[(list.Visible or hovered) and "Text" or "SubText"]
        end
        field.BackgroundColor3 = (hovered or list.Visible) and lighten(Config.Theme.Inline) or Config.Theme.Inline
        for option, entry in optionRows do
            entry.Label.TextColor3 = Config.Theme[isSelected(option) and "Accent" or (entry.Hovered and "Text" or "SubText")]
            entry.Button.BackgroundTransparency = entry.Hovered and 0 or 1
            entry.Button.BackgroundColor3 = lighten(Config.Theme.Background)
        end
        for _, section in dropdown.Sections do
            section.Section.Visible = isSelected(section.Option)
        end
    end
    table.insert(UI.Refreshers, paint)
    connect(list:GetPropertyChangedSignal("Visible"), paint)
    connect(field:GetPropertyChangedSignal("AbsoluteSize"), function()
        if UI.Dragging then
            return
        end
        paint()
        if list.Visible then
            fitList()
        end
    end)

    function dropdown:SetValues(newValues)
        values = newValues
        for _, entry in optionRows do
            entry.Button:Destroy()
        end
        table.clear(optionRows)
        for i, option in values do
            local button = create("TextButton", {
                Name = tostring(option),
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, optionHeight),
                LayoutOrder = i,
                ZIndex = 22,
                Parent = scroller,
            })
            local entry = {
                Button = button,
                Label = UI.Label(button, tostring(option), {
                    Position = UDim2.fromOffset(6, 0),
                    Size = UDim2.new(1, -12, 1, 0),
                    ZIndex = 23,
                }, { Slot = "SubText", Outline = true }),
            }
            optionRows[option] = entry
            connect(button.MouseEnter, function()
                entry.Hovered = true
                paint()
            end)
            connect(button.MouseLeave, function()
                entry.Hovered = false
                paint()
            end)
            connect(button.MouseButton1Click, function()
                if multi then
                    local set = table.clone(dropdown.Value)
                    set[option] = not set[option] or nil
                    dropdown:Set(set)
                else
                    dropdown:Set(option)
                    list.Visible = false
                end
            end)
        end
        fitList()
        paint()
    end
    dropdown:SetValues(values)

    function dropdown:Set(value)
        if multi then
            local set = {}
            for key, on in typeof(value) == "table" and value or {} do
                if typeof(key) == "number" then
                    set[on] = true
                elseif on then
                    set[key] = true
                end
            end
            value = set
        end
        dropdown.Value = value
        paint()
        if callback then
            task.spawn(callback, value)
        end
    end

    function dropdown:Children(option)
        local section = childSection(line)
        section.Option = option
        section.Section.LayoutOrder = line.LayoutOrder + 1 + #dropdown.Sections
        table.insert(dropdown.Sections, section)
        paint()
        return section
    end

    connect(field.MouseButton1Click, function()
        if list.Visible then
            list.Visible = false
        else
            fitList()
            openPopup(list, field, 0, field.AbsoluteSize.Y + 2)
        end
    end)
    connect(field.MouseEnter, function()
        hovered = true
        paint()
    end)
    connect(field.MouseLeave, function()
        hovered = false
        paint()
    end)
    dropdown:Set(options.Default)
    dropdown.Flag = register(parent, text, options, function()
        return dropdown.Value
    end, function(value)
        dropdown:Set(value)
    end)
    return dropdown
end

local KeyNames = {
    LeftShift = "lshift", RightShift = "rshift", LeftControl = "lctrl", RightControl = "rctrl",
    LeftAlt = "lalt", RightAlt = "ralt", Return = "enter", Backspace = "bksp", CapsLock = "caps",
    MouseButton1 = "mb1", MouseButton2 = "mb2", MouseButton3 = "mb3",
}
local function keyName(key)
    return key and (KeyNames[key.Name] or key.Name:lower()) or "..."
end

function UI.Keybind(line, default, onPress)
    local height = Config.TextSize
    local box = create("TextButton", {
        Name = "Keybind",
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromOffset(textWidth(keyName(default)) + 10, height),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = -1,
        Parent = accessories(line),
    })
    shade(box, 0.6, 1)
    outlined(box, "Shadow")
    local label = UI.Label(box, keyName(default), {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    }, { Slot = "SubText", Outline = true })

    local bind = { Value = default, Listening = false }
    local hovered = false
    local function paint()
        box.BackgroundColor3 = (hovered or bind.Listening) and lighten(Config.Theme.Inline) or Config.Theme.Inline
        label.TextColor3 = Config.Theme[bind.Listening and "Accent" or (bind.Value and "Text" or "SubText")]
    end
    table.insert(UI.Refreshers, paint)
    local function resize()
        local text = bind.Listening and "..." or keyName(bind.Value)
        label.Text = text
        task.spawn(function()
            TweenService:Create(box, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(textWidth(text) + 10, height),
            }):Play()
        end)
    end

    function bind:Set(key)
        bind.Value = key
        resize()
        paint()
    end

    connect(box.MouseButton1Click, function()
        if bind.Listening then return end
        bind.Listening = true
        resize()
        paint()

        heartbeatUntil(function(elapsed)
            label.TextTransparency = 0.55 - 0.45 * math.cos(elapsed * 7)
            return bind.Listening
        end, function()
            label.TextTransparency = 0
        end)
        local listener
        listener = UserInputService.InputBegan:Connect(function(input)
            local key
            if input.UserInputType == Enum.UserInputType.Keyboard then
                key = (input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode ~= Enum.KeyCode.Backspace) and input.KeyCode or false
            elseif input.UserInputType.Name:match("^MouseButton%d$") then
                key = input.UserInputType
            end
            if key == nil then return end
            listener:Disconnect()
            bind.Listening = false
            bind:Set(key or nil)
        end)
        table.insert(Connections, listener)
    end)
    connect(box.MouseEnter, function()
        hovered = true
        paint()
    end)
    connect(box.MouseLeave, function()
        hovered = false
        paint()
    end)
    connect(UserInputService.InputBegan, function(input, processed)
        local key = bind.Value
        if processed or bind.Listening or not key then return end
        if input.KeyCode == key or input.UserInputType == key then
            task.spawn(onPress)
        end
    end)
    paint()

    bind.Flag = register(line.Parent, `{line.Name}/key`, nil, function()
        return bind.Value and `{bind.Value.EnumType}.{bind.Value.Name}` or false
    end, function(data)
        local enumType, name = tostring(data):match("^(%w+)%.(%w+)$")
        local ok, key = pcall(function()
            return Enum[enumType][name]
        end)
        bind:Set(enumType and ok and key or nil)
    end)
    return bind
end

function UI.KeybindRow(parent, text, default, onPress)
    local line = row(parent, text)
    UI.Label(line, text, { Position = UDim2.fromOffset(1, 0), Size = UDim2.new(1, -2, 1, 0) }, { Outline = true })
    return UI.Keybind(line, default, onPress)
end

function UI.List(parent, text, options, callback)
    options = options or {}
    local values, multi = options.Values or {}, options.Multi
    local labelHeight, optionHeight = text and Config.TextSize + 2 or 0, Config.TextSize + 4
    local line = row(parent, text or "List", labelHeight)
    if text then
        UI.Label(line, text, { Position = UDim2.fromOffset(1, -1), Size = UDim2.new(1, -2, 0, labelHeight) }, { Outline = true })
    end
    local box = create("Frame", {
        Name = "Box",
        Position = UDim2.fromOffset(1, labelHeight),
        Size = UDim2.new(1, -2, 0, 0),
        BorderSizePixel = 0,
        Parent = line,
    })
    theme(box, "BackgroundColor3", "Inline")
    shade(box, 0.6, 1)
    outlined(box, "Shadow")
    create("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2), Parent = box })
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })

    local list = { Value = multi and {} or nil }
    local entries = {}
    local slide = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local function isSelected(option)
        if multi then
            return list.Value[option] == true
        end
        return list.Value == option
    end
    local function paint()
        for option, entry in entries do
            entry.Label.TextColor3 = Config.Theme[isSelected(option) and "Accent" or (entry.Hovered and "Text" or "SubText")]
        end
    end
    table.insert(UI.Refreshers, paint)

    function list:SetValues(newValues)
        values = newValues
        for _, entry in entries do
            entry.Button:Destroy()
        end
        table.clear(entries)
        for i, option in values do
            local button = create("TextButton", {
                Name = tostring(option),
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, optionHeight),
                LayoutOrder = i,
                Parent = box,
            })
            local entry = {
                Button = button,
                Label = UI.Label(button, tostring(option), {
                    Position = UDim2.fromOffset(6, 0),
                    Size = UDim2.new(1, -12, 1, 0),
                }, { Slot = "SubText", Outline = true }),
            }
            entries[option] = entry
            connect(button.MouseEnter, function()
                entry.Hovered = true
                TweenService:Create(entry.Label, slide, { Position = UDim2.fromOffset(10, 0) }):Play()
                paint()
            end)
            connect(button.MouseLeave, function()
                entry.Hovered = false
                TweenService:Create(entry.Label, slide, { Position = UDim2.fromOffset(6, 0) }):Play()
                paint()
            end)
            connect(button.MouseButton1Click, function()
                if multi then
                    local set = table.clone(list.Value)
                    set[option] = not set[option] or nil
                    list:Set(set)
                else
                    list:Set(option)
                end
            end)
        end
        list:Resize()
        paint()
    end

    function list:Resize()
        local boxHeight = math.max(#values, 1) * optionHeight + 4
        local page = options.Fill and line:FindFirstAncestorOfClass("ScrollingFrame")
        if page and page.AbsoluteSize.Y > 0 then
            local bottom = page.AbsolutePosition.Y + page.AbsoluteSize.Y - Config.Spacing * 2 - 2
            boxHeight = math.max(boxHeight, math.floor(bottom - box.AbsolutePosition.Y))
        end
        box.Size = UDim2.new(1, -2, 0, boxHeight)
        line.Size = UDim2.new(1, 0, 0, labelHeight + boxHeight)
        line:SetAttribute("Bottom", labelHeight + boxHeight + 1)
    end
    if options.Fill then
        local function refit()
            task.defer(list.Resize, list)
        end
        connect(line.AncestryChanged, refit)
        task.defer(function()
            local page = line:FindFirstAncestorOfClass("ScrollingFrame")
            if page then
                connect(page:GetPropertyChangedSignal("AbsoluteSize"), refit)
                connect(page:GetPropertyChangedSignal("CanvasPosition"), refit)
            end
            list:Resize()
        end)
    end
    list:SetValues(values)

    function list:Set(value)
        if multi then
            local set = {}
            for key, on in typeof(value) == "table" and value or {} do
                if typeof(key) == "number" then
                    set[on] = true
                elseif on then
                    set[key] = true
                end
            end
            value = set
        end
        list.Value = value
        paint()
        if callback then
            task.spawn(callback, value)
        end
    end
    list:Set(options.Default)
    list.Flag = register(parent, text or "list", options, function()
        return list.Value
    end, function(value)
        list:Set(value)
    end)
    return list
end

function UI.Textbox(parent, text, options, callback)
    options = options or {}
    local labelHeight, fieldHeight = text and Config.TextSize + 4 or 0, Config.TextSize + 6
    local line = row(parent, text or "Textbox", labelHeight + fieldHeight)
    line:SetAttribute("Bottom", labelHeight + fieldHeight + 1)
    if text then
        UI.Label(line, text, { Position = UDim2.fromOffset(1, 0), Size = UDim2.new(1, -2, 0, labelHeight) }, { Outline = true })
    end
    local field = create("TextBox", {
        Name = "Field",
        Position = UDim2.fromOffset(1, labelHeight),
        Size = UDim2.new(1, -2, 0, fieldHeight),
        BorderSizePixel = 0,
        FontFace = UI.Font,
        TextSize = Config.TextSize,
        Text = "",

        TextTransparency = 1,
        PlaceholderText = "",
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = line,
    })
    create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = field })
    theme(field, "BackgroundColor3", "Inline")
    outlined(field, "Shadow")

    local display = create("Frame", { Name = "Display", BackgroundTransparency = 1, ClipsDescendants = true, Size = UDim2.fromScale(1, 1), Parent = field })

    local placeholder = UI.Label(display, options.Placeholder or "", { Size = UDim2.fromScale(1, 1), ZIndex = 1 }, { Slot = "SubText", Outline = true })
    local strip = create("Frame", { Name = "Strip", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = display })
    local caret = create("Frame", {
        Name = "Caret",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(1, Config.TextSize),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 2,
        Parent = strip,
    })
    theme(caret, "BackgroundColor3", "Accent")

    local charWidth = textWidth("m")
    local roll = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local glyphs, shown = {}, ""
    local function glyph(char)
        local label = create("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = UI.Font,
            TextSize = Config.TextSize,
            Text = char,
            TextTransparency = 1,
            Size = UDim2.new(0, charWidth, 1, 0),
            Parent = strip,
        })
        theme(label, "TextColor3", "Text")
        local stroke = create("UIStroke", { Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = label })
        theme(stroke, "Color", "TextOutline")
        return { Label = label, Stroke = stroke }
    end
    local function fade(g, transparency)
        TweenService:Create(g.Label, roll, { TextTransparency = transparency }):Play()
        TweenService:Create(g.Stroke, roll, { Transparency = transparency }):Play()
    end
    local function follow()
        local cursor = field.CursorPosition > 0 and field.CursorPosition - 1 or #shown
        local x = cursor * charWidth
        TweenService:Create(caret, TweenInfo.new(0.08, Enum.EasingStyle.Quad), { Position = UDim2.new(0, x, 0.5, 0) }):Play()
        local scroll = math.min(0, display.AbsoluteSize.X - x - 2)
        TweenService:Create(strip, roll, { Position = UDim2.fromOffset(scroll, 0) }):Play()
    end

    local function sync(newText)
        local old = shown
        local prefix = 0
        while prefix < #old and prefix < #newText and old:sub(prefix + 1, prefix + 1) == newText:sub(prefix + 1, prefix + 1) do
            prefix += 1
        end
        local suffix = 0
        while suffix < #old - prefix and suffix < #newText - prefix and old:sub(#old - suffix, #old - suffix) == newText:sub(#newText - suffix, #newText - suffix) do
            suffix += 1
        end
        for i = #old - suffix, prefix + 1, -1 do
            local g = table.remove(glyphs, i)
            TweenService:Create(g.Label, roll, { Position = g.Label.Position + UDim2.fromOffset(0, 6) }):Play()
            fade(g, 1)
            task.delay(roll.Time, g.Label.Destroy, g.Label)
        end
        for i = prefix + 1, #newText - suffix do
            local g = glyph(newText:sub(i, i))
            g.Label.Position = UDim2.fromOffset((i - 1) * charWidth, -6)
            table.insert(glyphs, i, g)
            fade(g, 0)
        end
        for i, g in glyphs do
            TweenService:Create(g.Label, roll, { Position = UDim2.fromOffset((i - 1) * charWidth, 0) }):Play()
        end
        shown = newText
        TweenService:Create(placeholder, roll, { TextTransparency = #newText == 0 and 0 or 1 }):Play()
        follow()
    end

    local textbox = { Value = "", Box = field }
    local hovered = false
    local function paint()
        field.BackgroundColor3 = (hovered or field:IsFocused()) and lighten(Config.Theme.Inline) or Config.Theme.Inline
        field.TextColor3 = field.BackgroundColor3
    end
    table.insert(UI.Refreshers, paint)
    function textbox:Set(value)
        field.Text = value
    end
    connect(field:GetPropertyChangedSignal("Text"), function()
        textbox.Value = field.Text
        sync(field.Text)
        if callback then
            task.spawn(callback, field.Text)
        end
    end)
    connect(field:GetPropertyChangedSignal("CursorPosition"), follow)
    connect(field.Focused, function()
        paint()
        caret.Visible = true
        heartbeatUntil(function(elapsed)
            caret.BackgroundTransparency = elapsed % 1 < 0.55 and 0 or 1
            return field:IsFocused()
        end, function()
            caret.Visible = false
        end)
    end)
    connect(field.FocusLost, paint)
    connect(field.MouseEnter, function()
        hovered = true
        paint()
    end)
    connect(field.MouseLeave, function()
        hovered = false
        paint()
    end)
    paint()
    if options.Default then
        field.Text = options.Default
    end
    textbox.Flag = register(parent, text or "textbox", options, function()
        return textbox.Value
    end, function(value)
        textbox:Set(value)
    end)
    return textbox
end

function UI.Button(parent, text, callback)
    local height = Config.TextSize + 6
    local line = row(parent, text, height)
    line:SetAttribute("Bottom", height + 1)
    local group = { Buttons = {} }
    local function layout()

        local count, gap = #group.Buttons, 4
        local shrink = (2 + gap * (count - 1)) / count
        for i, entry in group.Buttons do
            entry.Button.Position = UDim2.new((i - 1) / count, 1 + (i - 1) * (gap - shrink), 0, 0)
            entry.Button.Size = UDim2.new(1 / count, -shrink, 1, 0)
        end
    end
    function group:Add(name, onClick)
        local button = create("TextButton", {
            Name = name,
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Parent = line,
        })
        shade(button, 1.1, 0.85)
        outlined(button, "Shadow")
        local label = UI.Label(button, name, {
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
        }, { Outline = true })
        local entry = { Button = button, Label = label }
        local hovered = false
        local function paint()
            button.BackgroundColor3 = hovered and lighten(Config.Theme.Background) or Config.Theme.Background
        end
        table.insert(UI.Refreshers, paint)
        connect(button.MouseEnter, function()
            hovered = true
            paint()
        end)
        connect(button.MouseLeave, function()
            hovered = false
            paint()
        end)
        connect(button.MouseButton1Click, function()
            label.TextColor3 = Config.Theme.Accent
            TweenService:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextColor3 = Config.Theme.Text }):Play()
            if onClick then
                task.spawn(onClick)
            end
        end)
        paint()
        table.insert(group.Buttons, entry)
        layout()
        return group
    end
    group:Add(text, callback)
    return group
end

function UI.Window(size)
    size = size or UDim2.fromOffset(450, 500)
    local margin, gap, tabHeight = 6, 6, Config.TextSize + 14
    local frame = create("Frame", {
        Name = "Window",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BorderSizePixel = 0,
        Active = true,
        Parent = UI.Gui,
    })
    theme(frame, "BackgroundColor3", "Background")
    shade(frame, 1, 0.86)
    addBorder(frame)
    registerPosition("__window", frame)
    local accent = 1
    local accentBar = create("Frame", { Name = "Accent", Size = UDim2.new(1, 0, 0, accent), BorderSizePixel = 0, ZIndex = 4, Parent = frame })
    theme(accentBar, "BackgroundColor3", "Accent")
    local grab = create("TextButton", {
        Name = "Grab",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, margin + accent + 4),
        ZIndex = 5,
        Parent = frame,
    })

    local pages = create("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(margin, margin + accent),
        Size = UDim2.new(1, -margin * 2, 1, -(margin * 2 + gap + tabHeight + accent)),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = frame,
    })
    theme(pages, "BackgroundColor3", "Inline")
    inset(pages)

    local tabBar = create("Frame", {
        Name = "Tabs",
        Position = UDim2.new(0, 6, 1, -(tabHeight + 6)),
        Size = UDim2.new(1, -12, 0, tabHeight),
        BorderSizePixel = 0,
        Parent = frame,
    })
    theme(tabBar, "BackgroundColor3", "Inline")
    inset(tabBar)

    local selection = create("Frame", { Name = "Selection", BorderSizePixel = 0, ZIndex = 1, Parent = tabBar })
    theme(selection, "BackgroundColor3", "Background")
    shade(selection, 1.1, 0.85)
    theme(create("Frame", { Name = "Indicator", Position = UDim2.fromOffset(0, 1), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = selection }), "BackgroundColor3", "Accent")

    local tabList = create("Frame", { Name = "List", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = tabBar })

    local window = { Frame = frame, Pages = pages, TabBar = tabBar, Selection = selection, Tabs = {}, Selected = nil }
    local slide

    local function refresh()
        for _, tab in window.Tabs do
            local selected = tab == window.Selected
            tab.Label.TextColor3 = (selected or tab.Hovered) and Config.Theme[selected and "Accent" or "Text"] or Config.Theme.SubText
            tab.Page.Visible = selected
        end
    end
    window.Refresh = refresh
    table.insert(UI.Refreshers, refresh)

    local function selectionGoal()
        local tab = window.Selected
        return UDim2.fromOffset(tab and tab.X or 0, 0), UDim2.new(0, tab and tab.Width or 0, 1, 0)
    end

    local function layoutTabs()
        local total, count = tabList.AbsoluteSize.X, #window.Tabs
        if count == 0 or total <= 0 then return end
        local textWidth = 0
        for _, tab in window.Tabs do
            textWidth += tab.Label.TextBounds.X
        end
        local gap = math.floor((total - textWidth) / count)
        local textX = math.floor((total - textWidth - gap * (count - 1)) / 2)
        local starts = {}
        for i, tab in window.Tabs do
            starts[i] = textX
            textX += tab.Label.TextBounds.X + gap
        end
        for i, tab in window.Tabs do
            local left = i == 1 and 0 or starts[i] - math.floor(gap / 2)
            local right = i == count and total or starts[i + 1] - math.floor(gap / 2)
            tab.X, tab.Width = left, right - left
            tab.Button.Position = UDim2.fromOffset(left, 0)
            tab.Button.Size = UDim2.new(0, tab.Width, 1, 0)
            tab.Label.Position = UDim2.fromOffset(starts[i] - left, 0)
            tab.Label.Size = UDim2.new(0, tab.Label.TextBounds.X, 1, 0)
        end
        if not (slide and slide.PlaybackState == Enum.PlaybackState.Playing) then
            selection.Position, selection.Size = selectionGoal()
        end
    end
    connect(tabList:GetPropertyChangedSignal("AbsoluteSize"), layoutTabs)

    function window:Select(tab, instant)
        window.Selected = tab
        refresh()
        local position, size = selectionGoal()
        if slide then
            slide:Cancel()
        end
        if instant then
            selection.Position, selection.Size = position, size
        else
            slide = TweenService:Create(selection, TweenInfo.new(Config.TabTween, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = position,
                Size = size,
            })
            slide:Play()
        end
    end

    function window:Tab(name, options)
        local button = create("TextButton", {
            Name = name,
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = tabList,
        })
        local scroller = create("ScrollingFrame", {
            Name = name,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 2,
            Visible = false,
            ZIndex = 1,
            Parent = pages,
        })
        theme(scroller, "ScrollBarImageColor3", "Accent")

        create("UIPadding", { PaddingBottom = UDim.new(0, Config.Spacing), Parent = scroller })
        local holder = create("Frame", {
            Name = "Columns",
            Position = UDim2.fromOffset(Config.Spacing, Config.Spacing),
            Size = UDim2.new(1, -Config.Spacing * 2, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = scroller,
        })
        local columns = {}
        for i, side in { "left", "right" } do
            local column = create("Frame", {
                Name = side,
                Position = UDim2.new((i - 1) * 0.5, (i - 1) * Config.Spacing / 2, 0, 0),
                Size = UDim2.new(0.5, -Config.Spacing / 2, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = holder,
            })
            create("UIListLayout", { Padding = UDim.new(0, Config.Spacing), SortOrder = Enum.SortOrder.LayoutOrder, Parent = column })
            columns[side] = column
        end

        local page = { Name = name, Frame = scroller, Columns = columns }
        function page:Groupbox(title, side)
            return UI.Groupbox(columns[side or "left"] or columns.left, title, `{name}/{title}`)
        end

        local tab = {
            Name = name,
            Button = button,
            Label = UI.Label(button, name, { Size = UDim2.fromScale(1, 1) }, { Slot = "SubText", Outline = true, Bold = true }),
            Page = scroller,
            Pinned = options and options.Pinned,
        }

        local index = #window.Tabs + 1
        if not tab.Pinned then
            for i, other in window.Tabs do
                if other.Pinned then
                    index = i
                    break
                end
            end
        end
        table.insert(window.Tabs, index, tab)
        if not tab.Pinned and window.Selected and window.Selected.Pinned then
            window.Selected = tab
        end
        connect(tab.Label:GetPropertyChangedSignal("TextBounds"), layoutTabs)
        layoutTabs()
        connect(button.MouseButton1Click, function()
            if window.Selected ~= tab then
                window:Select(tab)
            end
        end)
        connect(button.MouseEnter, function()
            tab.Hovered = true
            refresh()
        end)
        connect(button.MouseLeave, function()
            tab.Hovered = false
            refresh()
        end)
        window:Select(window.Selected or tab, true)
        return page
    end

    UI.WindowDraggable(frame)
    UI.Draggable(frame, grab)
    UI.Draggable(frame, tabBar)
    return window
end

function UI.SetColor(slot, color)
    Config.Theme[slot] = color
    for _, entry in Themed do
        if entry[3] == slot and entry[1].Parent then
            entry[1][entry[2]] = color
        end
    end
    for _, refresh in UI.Refreshers do
        refresh()
    end
end

function UI.Unload()
    for _, connection in Connections do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(Connections)
    local keepGone = UI.Gui
    if keepGone then
        pcall(function()
            keepGone:Destroy()
        end)
    end
    local parents = { GuiParent }
    local lp = LocalPlayer
    if lp then
        local pg = lp:FindFirstChildOfClass("PlayerGui")
        if pg then
            parents[#parents + 1] = pg
        end
    end
    if typeof(gethui) == "function" then
        local okHui, host = pcall(gethui)
        if okHui and typeof(host) == "Instance" then
            parents[#parents + 1] = host
        end
    end
    for _, parent in parents do
        if typeof(parent) == "Instance" then
            for _, child in parent:GetChildren() do
                if child.Name == "Tapology" and child:IsA("ScreenGui") then
                    pcall(child.Destroy, child)
                end
            end
        end
    end
    UI.Gui = nil
    if env.Tapology == UI then
        env.Tapology = nil
    end
    if env.Library == UI then
        env.Library = nil
    end
end

local hui = gethui and gethui()
do
    local parent = GuiParent
    if hui and typeof(hui) == "Instance" and not hui:IsA("LayerCollector") then
        parent = hui
    elseif gethui then

        local okHui, host = pcall(gethui)
        if okHui and typeof(host) == "Instance" and not host:IsA("LayerCollector") then
            parent = host
        end
    end
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    UI.Gui = create("ScreenGui", {
        Name = "Tapology",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        Parent = parent,
    })
    if not UI.Gui.Parent and playerGui then
        pcall(function()
            UI.Gui.Parent = playerGui
        end)
    end
    if not UI.Gui.Parent then
        pcall(function()
            UI.Gui.Parent = GuiParent
        end)
    end
end

do
    local border = 0
    for _, ring in Config.Border do
        border += ring[2]
    end
    local height = Config.TextSize + 16
    local function frameSize(width)
        return UDim2.fromOffset(width + border * 2, height + border * 2)
    end
    local function textSize(parts)
        local count = 0
        for _, part in parts do
            count += #part[1]
        end
        return count * charWidth() + 1 + 28
    end
    local started = os.clock()
    print("[Tapology] Loading UI...")
    local canvas = create("CanvasGroup", {
        Name = "Splash",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = frameSize(0),
        BackgroundTransparency = 1,
        ZIndex = 100,
        Parent = UI.Gui,
    })
    local panel = create("Frame", {
        Position = UDim2.fromOffset(border, border),
        Size = UDim2.new(1, -border * 2, 1, -border * 2),
        BorderSizePixel = 0,
        Parent = canvas,
    })
    theme(panel, "BackgroundColor3", "Background")
    shade(panel, 1, 0.86)
    addBorder(panel)

    local clip = create("Frame", { Name = "Clip", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, Parent = panel })
    theme(create("Frame", { Name = "Accent", Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = clip }), "BackgroundColor3", "Accent")

    local function phrase(parts, transparency)
        local holder = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = clip })
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = holder,
        })
        local labels = {}
        for i, part in parts do
            local label = UI.Label(holder, part[1], {
                Size = UDim2.fromOffset(0, Config.TextSize + 4),
                AutomaticSize = Enum.AutomaticSize.X,
                LayoutOrder = i,
            }, { Slot = part[2], Outline = true, Bold = true })
            label.TextTransparency = transparency
            table.insert(labels, label)
        end
        return labels
    end
    local question = { { "are you ready to", "Text" }, { " tap?", "Accent" } }
    local brand = { { "tapology", "Text" }, { ".pro", "Accent" } }
    local questionLabels, brandLabels = phrase(question, 0), phrase(brand, 1)

    local function play(target, info, goal)
        local tween = TweenService:Create(target, info, goal)
        tween:Play()
        return tween
    end
    local function quart(time, direction)
        return TweenInfo.new(time, Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
    end
    local function fade(labels, transparency, time)
        local last
        for _, label in labels do
            last = play(label, quart(time), { TextTransparency = transparency })
        end
        return last
    end

    play(canvas, quart(0.45), { Size = frameSize(textSize(question)) }).Completed:Wait()
    task.wait(math.max(Config.SplashTime * 0.5 - (os.clock() - started), 0.4))

    fade(questionLabels, 1, 0.2)
    play(canvas, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), { Size = frameSize(textSize(brand)) })
    task.wait(0.15)
    fade(brandLabels, 0, 0.3).Completed:Wait()
    task.wait(math.max(Config.SplashTime - (os.clock() - started), 0.4))

    play(canvas, quart(0.35), { GroupTransparency = 1 }).Completed:Wait()
    canvas:Destroy()
    print("[Tapology] Loaded UI")
end

local window = UI.Window(UDim2.fromOffset(505, 660))
UI.Main = window
UI.Pages = {}
UI.Groups = {}
UI.Pages.settings = window:Tab("settings", { Pinned = true })
UI.Groups.configs = UI.Pages.settings:Groupbox("configs", "left")
UI.Groups.config = UI.Pages.settings:Groupbox("config", "right")

function UI:Tab(name)
    local page = window:Tab(name)
    UI.Pages[name] = page
    return page
end

local function overlay(name, position, anchor)
    local frame = create("Frame", {
        Name = name,
        AnchorPoint = anchor,
        Position = position,
        BorderSizePixel = 0,
        Parent = UI.Gui,
    })
    theme(frame, "BackgroundColor3", "Background")
    shade(frame, 1, 0.86)
    addBorder(frame)
    theme(create("Frame", { Name = "Accent", Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, ZIndex = 4, Parent = frame }), "BackgroundColor3", "Accent")

    local clip = create("Frame", { Name = "Clip", BackgroundTransparency = 1, ClipsDescendants = true, Size = UDim2.fromScale(1, 1), Parent = frame })
    local content = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.new(),
        Parent = clip,
    })
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 9),
        PaddingRight = UDim.new(0, 9),
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 4),
        Parent = content,
    })

    local resize = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local function fit(instant)
        local goal = UDim2.fromOffset(content.AbsoluteSize.X, content.AbsoluteSize.Y)
        if instant == true then
            frame.Size = goal
        else
            TweenService:Create(frame, resize, { Size = goal }):Play()
        end
    end
    connect(content:GetPropertyChangedSignal("AbsoluteSize"), fit)
    task.defer(fit, true)
    UI.Draggable(frame)
    registerPosition(`__{name:lower()}`, frame)
    return frame, content
end

local function autoLabel(parent, text, slot, order, bold, nudge)
    local label = UI.Label(parent, text, {
        Size = UDim2.fromOffset(0, Config.TextSize + 4),
        AutomaticSize = Enum.AutomaticSize.X,
        LayoutOrder = order,
    }, { Slot = slot, Outline = true, Bold = bold })
    if nudge then
        create("UIPadding", { PaddingTop = UDim.new(0, nudge * 2), Parent = label })
    end
    return label
end

local watermark, watermarkContent = overlay("Watermark", UDim2.new(1, -8, 0, 8), Vector2.new(1, 0))
create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = watermarkContent,
})
autoLabel(watermarkContent, "tapology", "Text", 1, true, 1)
autoLabel(watermarkContent, ".pro", "Accent", 2, true, 1)
UI.Watermark = watermark

local WatermarkInfo = { "fps", "time", "game", "ram", "cpu usage" }
local watermarkItems = {}
local gameName = "game"
task.spawn(function()
    local ok, info = pcall(function()
        return cloneref(game:GetService("MarketplaceService")):GetProductInfo(game.PlaceId)
    end)
    if ok and info and info.Name then
        gameName = #info.Name > 28 and info.Name:sub(1, 26) .. ".." or info.Name
    end
end)

local frames, fps = 0, 0
connect(RunService.RenderStepped, function()
    frames += 1
end)

local function cpuUsage()
    local ok, ms = pcall(function()
        return cloneref(game:GetService("Stats")).PerformanceStats.CPU:GetValue()
    end)
    if not ok then
        return "cpu n/a"
    end
    return string.format("cpu %.1fms", ms)
end
local function infoText(name)
    if name == "fps" then
        return `{fps} fps`
    elseif name == "time" then
        return os.date("%H:%M:%S")
    elseif name == "game" then
        return gameName
    elseif name == "ram" then
        local ok, mb = pcall(function()
            return cloneref(game:GetService("Stats")):GetTotalMemoryUsageMb()
        end)
        if not ok then
            return "ram n/a"
        end
        return string.format("ram %.0fmb", mb)
    elseif name == "cpu usage" then
        return cpuUsage()
    end
    return name
end

function UI.SetWatermarkInfo(selected)
    for _, item in watermarkItems do
        item.Divider:Destroy()
        item.Label:Destroy()
    end
    table.clear(watermarkItems)
    for i, name in WatermarkInfo do
        if selected[name] then
            local divider = create("Frame", {
                Name = "Divider",
                Size = UDim2.fromOffset(21, Config.TextSize + 4),
                BackgroundTransparency = 1,
                LayoutOrder = 10 + i * 2,
                Parent = watermarkContent,
            })
            theme(create("Frame", {
                Position = UDim2.fromOffset(10, 2),
                Size = UDim2.new(0, 1, 1, -4),
                BorderSizePixel = 0,
                Parent = divider,
            }), "BackgroundColor3", "Highlight")
            table.insert(watermarkItems, { Name = name, Divider = divider, Label = autoLabel(watermarkContent, infoText(name), "SubText", 11 + i * 2, false, 1) })
        end
    end
end

task.spawn(function()
    local last = os.clock()
    while UI.Gui.Parent do
        task.wait(1)
        local now = os.clock()
        fps = math.floor(frames / (now - last) + 0.5)
        frames, last = 0, now
        for _, item in watermarkItems do
            item.Label.Text = infoText(item.Name)
        end
    end
end)

local hotkeys, hotkeysContent = overlay("Hotkeys", UDim2.new(0, 10, 0.5, 0), Vector2.new(0, 0.5))
create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = hotkeysContent })
autoLabel(hotkeysContent, "hotkeys", "Text", 0, true)
UI.HotkeysOverlay = hotkeys
local hotkeyRows = {}

local function refreshHotkeys()
    local shown = 0
    local width = #"hotkeys" * charWidth() + 1
    for _, entry in UI.Hotkeys do
        if entry.Bind.Value ~= nil then
            width = math.max(width, (#entry.Name + #keyName(entry.Bind.Value)) * charWidth() + 16)
        end
    end
    for i, entry in UI.Hotkeys do
        local bound = entry.Bind.Value ~= nil
        local rowFrame = hotkeyRows[i]
        if not rowFrame then
            rowFrame = create("Frame", {
                Name = entry.Name,
                Size = UDim2.fromOffset(width, Config.TextSize + 4),
                BackgroundTransparency = 1,
                LayoutOrder = i,
                Parent = hotkeysContent,
            })
            rowFrame:SetAttribute("Index", i)
            UI.Label(rowFrame, entry.Name, { Size = UDim2.fromScale(1, 1), Name = "Title" }, { Slot = "SubText", Outline = true })
            UI.Label(rowFrame, "", { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Right, Name = "Key" }, { Slot = "SubText", Outline = true })
            hotkeyRows[i] = rowFrame
        end
        rowFrame.Visible = bound
        rowFrame.Size = UDim2.fromOffset(width, Config.TextSize + 4)
        if bound then
            shown += 1
            local on = entry.Toggle.Value
            rowFrame.Title.TextColor3 = Config.Theme[on and "Text" or "SubText"]
            rowFrame.Key.Text = keyName(entry.Bind.Value)
            rowFrame.Key.TextColor3 = Config.Theme[on and "Accent" or "SubText"]
        end
    end
end
table.insert(UI.Refreshers, refreshHotkeys)
task.spawn(function()
    while UI.Gui.Parent do
        refreshHotkeys()
        task.wait(0.2)
    end
end)

local HttpService = cloneref(game:GetService("HttpService"))
local GameFolder = `{Config.Folder}/games/{Config.GameFolder}`
local ConfigFolder = `{GameFolder}/configs`

local function escape(text)
    return (tostring(text):gsub("[%%,=#%[%]\n\r]", function(char)
        return string.format("%%%02X", string.byte(char))
    end))
end
local function unescape(text)
    return (text:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end))
end

local function encodeValue(value)
    local kind = typeof(value)
    if kind == "boolean" then
        return `bool:{value}`
    elseif kind == "number" then
        return `num:{string.format("%.10g", value)}`
    elseif kind == "string" then
        return `str:{escape(value)}`
    elseif kind == "table" then
        if #value > 0 then
            local parts = {}
            for i, item in value do
                parts[i] = string.format("%.10g", item)
            end
            return `arr:{table.concat(parts, ",")}`
        end
        local keys = {}
        for key, on in value do
            if on then
                table.insert(keys, escape(key))
            end
        end
        table.sort(keys)
        return `set:{table.concat(keys, ",")}`
    end
end

local function decodeValue(text)
    local kind, body = text:match("^(%a+):(.*)$")
    if kind == "bool" then
        return body == "true"
    elseif kind == "num" then
        return tonumber(body)
    elseif kind == "str" then
        return unescape(body)
    elseif kind == "arr" then
        local list = {}
        for part in body:gmatch("[^,]+") do
            table.insert(list, tonumber(part))
        end
        return list
    elseif kind == "set" then
        local set = {}
        for part in body:gmatch("[^,]+") do
            set[unescape(part)] = true
        end
        return set
    end
end

local Base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function base64Encode(data)
    local out = {}
    for i = 1, #data, 3 do
        local a, b, c = string.byte(data, i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local chars = {}
        for k = 3, 0, -1 do
            local index = math.floor(n / 64 ^ k) % 64 + 1
            table.insert(chars, Base64:sub(index, index))
        end
        if not b then
            chars[3], chars[4] = "=", "="
        elseif not c then
            chars[4] = "="
        end
        table.insert(out, table.concat(chars))
    end
    return table.concat(out)
end
local function base64Decode(data)
    data = data:gsub("[^%w%+/=]", "")
    local out = {}
    for i = 1, #data, 4 do
        local n, pad = 0, 0
        for k = 0, 3 do
            local char = data:sub(i + k, i + k)
            local index = Base64:find(char, 1, true)
            if char == "=" or not index then
                pad += 1
                index = 1
            end
            n = n * 64 + index - 1
        end
        local bytes = string.char(math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
        table.insert(out, bytes:sub(1, 3 - pad))
    end
    return table.concat(out)
end

local function checksum(text)
    local h = 2166136261
    for i = 1, #text do
        h = bit32.bxor(h, string.byte(text, i))
        h = (h * 16777619) % 4294967296
    end
    return string.format("%08x", h)
end

local function pack(tag, entries)
    local keys = {}
    for key in entries do
        table.insert(keys, key)
    end
    table.sort(keys)
    local lines = {}
    for _, key in keys do
        table.insert(lines, `{escape(key)}={entries[key]}`)
    end
    local body = table.concat(lines, "\n")
    return `{tag}.{checksum(body)}.{base64Encode(body)}`
end

local function unpack(tag, text)
    local fileTag, sum, data = text:match("^%s*(%w+)%.(%x+)%.([%w%+/=]*)%s*$")
    if fileTag ~= tag then
        return nil
    end
    local body = base64Decode(data)
    if checksum(body) ~= sum then
        return nil
    end
    local entries = {}
    for line in (body .. "\n"):gmatch("(.-)\n") do
        local key, value = line:match("^(.-)=(.*)$")
        if key and key ~= "" then
            entries[unescape(key)] = value
        end
    end
    return entries
end

local function ensureFolder(path)
    local built = ""
    for part in path:gmatch("[^/]+") do
        built = built == "" and part or `{built}/{part}`
        if not isfolder(built) then
            makefolder(built)
        end
    end
end

local function configPath(name)
    return `{ConfigFolder}/{name}.tap`
end

local function listNames(folder, extension)
    local names = {}
    if isfolder(folder) then
        for _, file in listfiles(folder) do
            local name = file:match(`([^/\\]+)%.{extension}$`)
            if name then
                table.insert(names, name)
            end
        end
    end
    table.sort(names)
    return names
end

function UI.ListConfigs()
    return listNames(ConfigFolder, "tap")
end

function UI.SaveConfig(name)
    ensureFolder(ConfigFolder)
    local entries = {}
    for flag, entry in UI.Flags do
        local ok, value = pcall(entry.Get)
        local encoded = ok and encodeValue(value)
        if encoded then
            entries[flag] = encoded
        end
    end
    writefile(configPath(name), pack("tap2", entries))
end

function UI.LoadConfig(name)
    if not isfile(configPath(name)) then
        return false
    end
    local ok, entries = pcall(unpack, "tap2", readfile(configPath(name)))
    if not ok or not entries then
        return false
    end
    for flag, raw in entries do
        local entry = UI.Flags[flag]
        local value = decodeValue(raw)
        if entry and value ~= nil then
            pcall(entry.Set, value)
        end
    end
    return true
end

local AutoloadConfigFile = `{GameFolder}/autoload.txt`
local AutoloadThemeFile = `{Config.Folder}/themes/autoload.txt`
local function readAutoload(path)
    local name = isfile(path) and readfile(path):match("^%s*(.-)%s*$") or ""
    return name ~= "" and name or nil
end
local function writeAutoload(path, name)
    ensureFolder(path:match("^(.*)/[^/]+$"))
    if name then
        writefile(path, name)
    elseif isfile(path) then
        delfile(path)
    end
end

function UI.DeleteConfig(name)
    if isfile(configPath(name)) then
        delfile(configPath(name))
    end
end

local BorderWidth = 0
for _, ring in Config.Border do
    BorderWidth += ring[2]
end
local Notices = {}
local NoticeMargin, NoticeGap = 14, 6
local noticeHolder = create("Frame", { Name = "Notifications", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 40, Parent = UI.Gui })
local slideInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function restack()
    local offset = 0
    for _, notice in Notices do
        notice.Y = -(NoticeMargin - BorderWidth) - offset
        if not notice.Leaving then
            TweenService:Create(notice.Canvas, slideInfo, { Position = UDim2.new(1, -(NoticeMargin - BorderWidth), 1, notice.Y) }):Play()
        end
        offset += notice.Height + NoticeGap
    end
end

function UI:Notify(text, duration)
    duration = duration or 4
    text = tostring(text)
    local width = math.max(#text * charWidth() + 20, 150)
    local height = Config.TextSize + 12
    local canvas = create("CanvasGroup", {
        Name = "Notification",
        AnchorPoint = Vector2.new(1, 1),
        Size = UDim2.fromOffset(width + BorderWidth * 2, height + BorderWidth * 2),
        Position = UDim2.new(1, -(NoticeMargin - BorderWidth) + 40, 1, -(NoticeMargin - BorderWidth)),
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        Parent = noticeHolder,
    })
    local panel = create("Frame", {
        Position = UDim2.fromOffset(BorderWidth, BorderWidth),
        Size = UDim2.fromOffset(width, height),
        BorderSizePixel = 0,
        Parent = canvas,
    })
    theme(panel, "BackgroundColor3", "Background")
    shade(panel, 1, 0.86)
    addBorder(panel)

    local timer = create("Frame", { Name = "Accent", Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = panel })
    theme(timer, "BackgroundColor3", "Accent")
    UI.Label(panel, text, { Position = UDim2.fromOffset(9, 1), Size = UDim2.new(1, -18, 1, -1) }, { Outline = true })

    local notice = { Canvas = canvas, Height = height + BorderWidth * 2 }
    table.insert(Notices, 1, notice)
    restack()
    canvas.Position = UDim2.new(1, -(NoticeMargin - BorderWidth) + 40, 1, notice.Y)
    TweenService:Create(canvas, slideInfo, { Position = UDim2.new(1, -(NoticeMargin - BorderWidth), 1, notice.Y), GroupTransparency = 0 }):Play()
    TweenService:Create(timer, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 1) }):Play()

    task.delay(duration, function()
        notice.Leaving = true
        TweenService:Create(canvas, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(1, -(NoticeMargin - BorderWidth) + 40, 1, notice.Y),
            GroupTransparency = 1,
        }):Play()
        task.wait(0.3)
        table.remove(Notices, table.find(Notices, notice))
        canvas:Destroy()
        restack()
    end)
end

local configList = UI.Groups.configs:List(nil, { Values = UI.ListConfigs(), Save = false, Fill = true })
local configGroup = UI.Groups.config
local manage = configGroup:Subtab("config")
local themeTab = configGroup:Subtab("theme")

local function report(text)
    UI:Notify(text)
end
local function cleanName(text)
    return (text:gsub("[^%w%s%-_]", ""):match("^%s*(.-)%s*$"))
end

local nameBox = manage:Textbox("config name", { Placeholder = "name", Save = false })
local function refreshConfigs()
    configList:SetValues(UI.ListConfigs())
    configList:Set(configList.Value)
end
local function chosenName()
    local name = cleanName(nameBox.Value)
    if name == "" then
        name = configList.Value or ""
    end
    return name
end

local configListSet = configList.Set
function configList:Set(value)
    configListSet(self, value)
    if value then
        nameBox:Set(value)
    end
end

manage:Button("create", function()
    local name = chosenName()
    if name == "" then return report("enter a config name") end
    if isfile(configPath(name)) then return report(`config '{name}' already exists`) end
    UI.SaveConfig(name)
    refreshConfigs()
    configList:Set(name)
    report(`created config '{name}'`)
end)
manage:Button("save", function()
    local name = chosenName()
    if name == "" then return report("enter a config name") end
    UI.SaveConfig(name)
    refreshConfigs()
    configList:Set(name)
    report(`saved config '{name}'`)
end):Add("load", function()
    local name = chosenName()
    report(UI.LoadConfig(name) and `loaded config '{name}'` or `couldn't load config '{name}'`)
end)
manage:Button("delete", function()
    local name = chosenName()
    if not isfile(configPath(name)) then return report(`no config named '{name}'`) end
    UI.DeleteConfig(name)
    configList:Set(nil)
    nameBox:Set("")
    refreshConfigs()
    report(`deleted config '{name}'`)
end):Add("refresh", function()
    refreshConfigs()
    report(`{#UI.ListConfigs()} configs for {Config.GameFolder}`)
end)
manage:Button("set autoload", function()
    local name = chosenName()
    if not isfile(configPath(name)) then return report(`no config named '{name}'`) end
    writeAutoload(AutoloadConfigFile, name)
    report(`config '{name}' will autoload`)
end):Add("rem autoload", function()
    local name = readAutoload(AutoloadConfigFile)
    writeAutoload(AutoloadConfigFile, nil)
    report(name and `config '{name}' won't autoload` or "no config is set to autoload")
end)

UI.MenuKey = manage:Keybind("menu key", Config.MenuKey, function()
    UI:ToggleMenu()
end)

local menuCursorConn
local function setMenuCursorFree(on)
    if menuCursorConn then
        menuCursorConn:Disconnect()
        menuCursorConn = nil
    end
    if on then
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        pcall(function()
            GuiService.SelectedObject = nil
        end)
        menuCursorConn = RunService.RenderStepped:Connect(function()
            if not window.Frame.Visible then
                return
            end
            UserInputService.MouseIconEnabled = true
            if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
        end)
        table.insert(Connections, menuCursorConn)
    end
end

function UI:ToggleMenu(visible)
    if visible == nil then
        visible = not window.Frame.Visible
    end
    window.Frame.Visible = visible
    if not visible then
        if Popup.Open then
            Popup.Open.Visible = false
        end
        if OpenConfigWindow then
            OpenConfigWindow.Visible = false
        end
        setMenuCursorFree(false)
    else
        setMenuCursorFree(true)
    end
end

UI.IsMenuOpen = function()
    return window.Frame.Visible
end

if window.Frame.Visible then
    setMenuCursorFree(true)
end

local watermarkToggle = themeTab:Toggle("watermark", true, function(on)
    watermark.Visible = on
end)
watermarkToggle:Children():Dropdown("watermark info", {
    Values = WatermarkInfo,
    Multi = true,
    Default = { "fps", "time", "game" },
}, UI.SetWatermarkInfo)

local extraInfo, extraInfoContent = overlay("ExtraInfo", UDim2.new(0, 8, 0, 8), Vector2.new(0, 0))
extraInfo.Visible = false
create("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 1),
    Parent = extraInfoContent,
})
local extraFpsLabel = autoLabel(extraInfoContent, "Average FPS: 0", "Text", 1, true, 0)
local extraPingLabel = autoLabel(extraInfoContent, "Ping (L7/L4): 0/0ms", "Text", 2, true, 0)
local extraDcLabel = autoLabel(extraInfoContent, "Datacenter: …", "Text", 3, true, 0)
UI.ExtraInfo = extraInfo

local StatsService = cloneref(game:GetService("Stats"))
local extraDc = "…"
task.spawn(function()
    pcall(function()
        local raw = game:HttpGet("https://ipinfo.io/json")
        local city = string.match(raw, '"city"%s*:%s*"([^"]+)"')
        local region = string.match(raw, '"region"%s*:%s*"([^"]+)"')
        local country = string.match(raw, '"country"%s*:%s*"([^"]+)"')
        local org = string.match(raw, '"org"%s*:%s*"([^"]+)"')
        if city and country then
            extraDc = string.upper(string.sub(city, 1, 3)) .. country
        elseif region then
            extraDc = region
        elseif country then
            extraDc = country
        elseif org then
            extraDc = org
        end
    end)
    if extraDc == "…" then
        extraDc = "LOCAL"
    end
end)

local function readDataPingMs()
    local ok, value = pcall(function()
        local item = StatsService.Network.ServerStatsItem:FindFirstChild("Data Ping")
        if not item then
            return nil
        end
        local v = item:GetValue()
        if type(v) == "number" then
            return v
        end
        if type(v) == "string" then
            return tonumber((v:gsub("[^%d%.]", "")))
        end
    end)
    return ok and value or nil
end

local function readL7PingMs()
    local ok, value = pcall(function()
        return Players.LocalPlayer:GetNetworkPing() * 1000
    end)
    return ok and value or nil
end

task.spawn(function()
    while UI.Gui and UI.Gui.Parent do
        task.wait(0.5)
        if extraInfo.Visible then
            local l7 = readL7PingMs()
            local l4 = readDataPingMs()
            extraFpsLabel.Text = string.format("Average FPS: %d", fps)
            extraPingLabel.Text = string.format(
                "Ping (L7/L4): %d/%dms",
                math.floor((l7 or 0) + 0.5),
                math.floor((l4 or 0) + 0.5)
            )
            extraDcLabel.Text = "Datacenter: " .. tostring(extraDc)
        end
    end
end)

themeTab:Toggle("extra info", false, function(on)
    extraInfo.Visible = on and true or false
end)
themeTab:Toggle("hotkeys", true, function(on)
    hotkeys.Visible = on
end)

local ThemeFolder = `{Config.Folder}/themes`
local ThemeSlots = { "Accent", "Background", "Inline", "Outline", "Shadow", "Highlight", "Text", "SubText", "TextOutline" }
local themePickers = {}
local function slotLabel(slot)
    return slot:gsub("(%l)(%u)", "%1 %2"):lower()
end
for _, slot in ThemeSlots do
    themePickers[slot] = themeTab:ColorPicker(slotLabel(slot), Config.Theme[slot], function(color)
        UI.SetColor(slot, color)
    end, { Save = false })
end

local function themePath(name)
    return `{ThemeFolder}/{name}.taptheme`
end
function UI.ListThemes()
    return listNames(ThemeFolder, "taptheme")
end
function UI.SaveTheme(name)
    ensureFolder(ThemeFolder)
    local colors = {}
    for _, slot in ThemeSlots do
        colors[slotLabel(slot)] = `#{Config.Theme[slot]:ToHex()}`
    end
    writefile(themePath(name), pack("tpt2", colors))
end
function UI.LoadTheme(name)
    if not isfile(themePath(name)) then
        return false
    end
    local ok, colors = pcall(unpack, "tpt2", readfile(themePath(name)))
    if not ok or not colors then
        return false
    end
    for _, slot in ThemeSlots do
        local hex = colors[slotLabel(slot)]
        local okColor, color = pcall(Color3.fromHex, hex and hex:gsub("^#", "") or "")
        if hex and okColor then
            themePickers[slot]:Set(color)
        end
    end
    return true
end
function UI.DeleteTheme(name)
    if isfile(themePath(name)) then
        delfile(themePath(name))
    end
end

local themeName
local themeList = themeTab:Dropdown("themes", { Values = UI.ListThemes(), Save = false })
themeName = themeTab:Textbox("theme name", { Placeholder = "name", Save = false })
local themeListSet = themeList.Set
function themeList:Set(value)
    themeListSet(self, value)
    if value then
        themeName:Set(value)
    end
end
local function chosenTheme()
    local name = cleanName(themeName.Value)
    if name == "" then
        name = themeList.Value or ""
    end
    return name
end
local function refreshThemes()
    themeList:SetValues(UI.ListThemes())
    themeList:Set(themeList.Value)
end

themeTab:Button("create", function()
    local name = chosenTheme()
    if name == "" then return report("enter a theme name") end
    if isfile(themePath(name)) then return report(`theme '{name}' already exists`) end
    UI.SaveTheme(name)
    refreshThemes()
    themeList:Set(name)
    report(`created theme '{name}'`)
end)
themeTab:Button("save", function()
    local name = chosenTheme()
    if name == "" then return report("enter a theme name") end
    UI.SaveTheme(name)
    refreshThemes()
    themeList:Set(name)
    report(`saved theme '{name}'`)
end):Add("load", function()
    local name = chosenTheme()
    report(UI.LoadTheme(name) and `loaded theme '{name}'` or `couldn't load theme '{name}'`)
end)
themeTab:Button("delete", function()
    local name = chosenTheme()
    if not isfile(themePath(name)) then return report(`no theme named '{name}'`) end
    UI.DeleteTheme(name)
    themeList:Set(nil)
    themeName:Set("")
    refreshThemes()
    report(`deleted theme '{name}'`)
end):Add("refresh", function()
    refreshThemes()
    report(`{#UI.ListThemes()} themes`)
end)
themeTab:Button("set autoload", function()
    local name = chosenTheme()
    if not isfile(themePath(name)) then return report(`no theme named '{name}'`) end
    writeAutoload(AutoloadThemeFile, name)
    report(`theme '{name}' will autoload`)
end):Add("rem autoload", function()
    local name = readAutoload(AutoloadThemeFile)
    writeAutoload(AutoloadThemeFile, nil)
    report(name and `theme '{name}' won't autoload` or "no theme is set to autoload")
end)

env.Tapology = UI
env.Library = UI
getgenv().Tapology = UI
getgenv().Library = UI
UI:Notify(`tapology.pro - {keyName(Config.MenuKey)} toggles the menu`, 5)

task.spawn(function()
    local started = os.clock()
    repeat
        task.wait(0.25)
        local built = #window.Tabs > 1 and os.clock() - UI.LastRegistered >= 1
    until not UI.Gui.Parent or built or os.clock() - started >= Config.AutoloadTimeout
    if not UI.Gui.Parent then return end
    local themeName = readAutoload(AutoloadThemeFile)
    if themeName and UI.LoadTheme(themeName) then
        themeList:Set(themeName)
        report(`autoloaded theme '{themeName}'`)
    end
    local configName = readAutoload(AutoloadConfigFile)
    if configName and UI.LoadConfig(configName) then
        configList:Set(configName)
        report(`autoloaded config '{configName}'`)
    end
end)
return UI
