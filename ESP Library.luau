local ExecuteUrl, FetchService = function(Url) return loadstring(game:HttpGet(Url, true))() end, function(Name) local Success, Service = pcall(game.GetService, game, Name) return Success and Service end
local Drawing = loadstring(game:HttpGet("https://raw.githubusercontent.com/TheRealXORA/Drawing/refs/heads/main/Drawing.luau", true))()

local Services = setmetatable({}, {
    __index = function(Self, Name)
        local Service = FetchService(Name) or FetchService(Name .. "Service")
        rawset(Self, Name, cloneref and cloneref(Service) or Service)
        return rawget(Self, Name)
    end
})

local HiddenUI = gethui and gethui() or Services.CoreGui.RobloxGui
local Client, Players, Entities, Connections, RunIn, ESP, ESPDirectory, Objects, ActiveBoxBounds = {}, {}, {}, {}, { Heartbeat = {}, PreRenderSync = {}, PreRender = {} }, {}, HiddenUI:FindFirstChild("ESP Directory") or Instance.new("Folder", HiddenUI), { Highlights = 0, Tracers = 0, Boxes = 0, Bars = 0, Names = 0, Distances = 0, States = 0, Tools = 0 }, {}
ESPDirectory.Name = "ESP Directory"
local ESPUIDirectory, GradientKeys, StrokeKeys, AutoRotationKeys = ESPDirectory:FindFirstChild("ESP Gui Directory") or Instance.new("ScreenGui", ESPDirectory), { "Enabled", "Color", "Rotation", "Transparency", "Offset" }, { "Enabled", "Color", "Transparency", "Thickness", "LineJoinMode" }, { "Enabled", "Amount", "Speed", "Start", "End" }
ESPUIDirectory.Name, ESPUIDirectory.ResetOnSpawn, ESPUIDirectory.IgnoreGuiInset, ESPUIDirectory.DisplayOrder = "ESP Gui Directory", false, true, 2147483646

local DefaultGradient = {
    ColorSequenceKeypoint.new(0,   Color3.new(1, 1, 1)),
    ColorSequenceKeypoint.new(0.5, Color3.new(0, 0, 0)),
    ColorSequenceKeypoint.new(1,   Color3.new(1, 1, 1)),
}

local StateNames = {
    [Enum.HumanoidStateType.Running] = "Running",
    [Enum.HumanoidStateType.RunningNoPhysics] = "Running",
    [Enum.HumanoidStateType.Jumping] = "Jumping",
    [Enum.HumanoidStateType.Freefall] = "Falling",
    [Enum.HumanoidStateType.Swimming] = "Swimming",
    [Enum.HumanoidStateType.Climbing] = "Climbing",
    [Enum.HumanoidStateType.Seated] = "Seated",
    [Enum.HumanoidStateType.Dead] = "Dead",
    [Enum.HumanoidStateType.Landed] = "Idle",
    [Enum.HumanoidStateType.GettingUp]  = "Getting Up",
    [Enum.HumanoidStateType.PlatformStanding]  = "Standing",
    [Enum.HumanoidStateType.StrafingNoPhysics] = "Strafing",
}

local SideAnchor = {
    Top = Vector2.new(0.5, 1),
    Bottom = Vector2.new(0.5, 0),
    Left = Vector2.new(1, 0.5),
    Right = Vector2.new(0, 0.5),
}



--// SETUP FUNCTIONS



local function SetupPlayers()
    for _, Player in Services.Players:GetPlayers() do
        table.insert(Players, Player)
    end
    Connections.PlayerAdded = Services.Players.PlayerAdded:Connect(function(Player)
        table.insert(Players, Player)
    end)
    Connections.PlayerRemoving = Services.Players.PlayerRemoving:Connect(function(Player)
        local Index = table.find(Players, Player)
        if Index then table.remove(Players, Index) end
    end)
end; SetupPlayers()

local function SetupEntities()
    local UpdatePending = false
    local function UpdateEntities(DelayTime)
        if UpdatePending then return end
        UpdatePending = true
        task.delay(DelayTime or 0.01, function()
            for _, Entity in workspace:GetDescendants() do
                if Entity.ClassName ~= "Model" or table.find(Entities, Entity) then continue end
                local Humanoid = Entity:FindFirstChildOfClass("Humanoid")
                local RootPart = Humanoid and (Humanoid.RootPart or Entity:FindFirstChild("HumanoidRootPart"))
                if not (RootPart and Humanoid.Health > 0) then continue end
                local function Remove()
                    local Index = table.find(Entities, Entity)
                    if Index then table.remove(Entities, Index) end
                end
                print(Entity.Name)
                Humanoid.Died:Once(Remove)
                Entity.Destroying:Once(Remove)
                table.insert(Entities, Entity)
            end
            UpdatePending = false
        end)
    end
    UpdateEntities(1)
    Connections.DescendantAdded = workspace.DescendantAdded:Connect(function(Descendant)
        if Descendant.ClassName == "Model" then UpdateEntities(1) end
    end)
end; SetupEntities()

local function InitClient()
    Client.Player = Services.Players.LocalPlayer
    Client.Camera = workspace.CurrentCamera
    Client.Character = Client.Player.Character
    Client.Humanoid = Client.Character and Client.Character:FindFirstChildOfClass("Humanoid")
    Client.RootPart = Client.Humanoid and Client.Humanoid.RootPart
    Client.Head = Client.Character and Client.Character:FindFirstChild("Head")
    Client.Tools = {}
    Client.Resolution = Client.Camera and Client.Camera.ViewportSize
    Client.HalfResolution = Client.Resolution and Client.Resolution / 2
    
    local function OnDeath()
        Client.Character, Client.Humanoid, Client.RootPart, Client.Tools = nil, nil, nil, {}
    end
    
    local function TrackDeath()
        if not Client.Humanoid then return end
        Client.Humanoid.Died:Once(OnDeath)
        Client.Player.CharacterRemoving:Once(OnDeath)
    end; TrackDeath()
    
    local function TrackTools()
        local function AddTool(Tool)
            if Tool.ClassName ~= "Tool" or table.find(Client.Tools, Tool) then return end
            table.insert(Client.Tools, Tool)
        end
        local function RemoveTool(Tool)
            local Index = table.find(Client.Tools, Tool)
            if Index then table.remove(Client.Tools, Index) end
        end
        for _, Tool in Client.Character:GetChildren() do AddTool(Tool) end
        Connections.ClientChildAdded = Client.Character.ChildAdded:Connect(AddTool)
        Connections.ClientChildRemoved = Client.Character.ChildRemoved:Connect(RemoveTool)
    end; TrackTools()
    
    Client.Player.CharacterAdded:Connect(function(Character)
        Client.Character = Character
        repeat
            Client.Humanoid = Character:FindFirstChildOfClass("Humanoid")
            Client.RootPart = Client.Humanoid and Client.Humanoid.RootPart
            Client.Head = Character:FindFirstChild("Head")
            if not (Client.Humanoid and Client.RootPart and Client.Head) then task.wait() end
        until Client.Humanoid and Client.RootPart and Client.Head
        TrackDeath(); TrackTools()
    end)
    
    RunIn.Heartbeat.Client = function()
        Client.Camera = workspace.CurrentCamera
        Client.Resolution = Client.Camera and Client.Camera.ViewportSize
        Client.HalfResolution = Client.Resolution and Client.Resolution / 2
    end
end; InitClient()



--// HELPER FUNCTIONS



local function CleanString(String)
    return String:lower():gsub("%W", "")
end

local function FlipTransparency(Transparency)
    return math.clamp(1 - Transparency, 0, 1)
end

local function NewAutoRotation()
    return { Enabled = false, Amount = 90, Speed = 1, Start = 0, End = 360 }
end

local function NewGradient()
    return { Enabled = false, Color = ColorSequence.new(DefaultGradient), Rotation = 0, Transparency = NumberSequence.new(0), Offset = Vector2.new(0, 0) }
end

local function NewStroke(StrokeEnabled, StrokeColor)
    return { Enabled = StrokeEnabled, Color = StrokeColor or Color3.new(1, 1, 1), Transparency = 1, Thickness = 1, LineJoinMode = Enum.LineJoinMode.Miter }
end

local function MakeStyles(StrokeEnabled, StrokeColor)
    local RawGradient, RawStroke, RawStrokeGradient, RawGradientAutoRotation, RawStrokeGradientAutoRotation = NewGradient(), NewStroke(StrokeEnabled, StrokeColor), NewGradient(), NewAutoRotation(), NewAutoRotation()
    
    local GradientAutoRotation = setmetatable({}, {
        __index = RawGradientAutoRotation,
        __newindex = function(_, Key, Value)
            assert(RawGradientAutoRotation[Key] ~= nil, "Invalid Property '" .. Key .. "' For Gradient.AutoRotation")
            RawGradientAutoRotation[Key] = Value
        end,
    })
    
    local StrokeGradientAutoRotation = setmetatable({}, {
        __index = RawStrokeGradientAutoRotation,
        __newindex = function(_, Key, Value)
            assert(RawStrokeGradientAutoRotation[Key] ~= nil, "Invalid Property '" .. Key .. "' For Stroke.Gradient.AutoRotation")
            RawStrokeGradientAutoRotation[Key] = Value
        end,
    })
    
    local Gradient = setmetatable({}, {
        __index = function(_, Key)
            return Key == "AutoRotation" and GradientAutoRotation or RawGradient[Key]
        end,
        __newindex = function(_, Key, Value)
            assert(Key ~= "AutoRotation", "Cannot Set AutoRotation Directly, Use Gradient.AutoRotation.PropertyName")
            assert(RawGradient[Key] ~= nil, "Invalid Property '" .. Key .. "' For Gradient")
            RawGradient[Key] = Value
        end,
    })
    
    local StrokeGradient = setmetatable({}, {
        __index = function(_, Key)
            return Key == "AutoRotation" and StrokeGradientAutoRotation or RawStrokeGradient[Key]
        end,
        __newindex = function(_, Key, Value)
            assert(Key ~= "AutoRotation", "Cannot Set AutoRotation Directly, Use Stroke.Gradient.AutoRotation.PropertyName")
            assert(RawStrokeGradient[Key] ~= nil, "Invalid Property '" .. Key .. "' For Stroke.Gradient")
            RawStrokeGradient[Key] = Value
        end,
    })
    
    local Stroke = setmetatable({}, {
        __index = function(_, Key)
            return Key == "Gradient" and StrokeGradient or RawStroke[Key]
        end,
        __newindex = function(_, Key, Value)
            assert(Key ~= "Gradient", "Cannot Set Gradient Directly, Use Stroke.Gradient.PropertyName")
            assert(RawStroke[Key] ~= nil, "Invalid Property '" .. Key .. "' For Stroke")
            RawStroke[Key] = Value
        end,
    })
    
    return Stroke, Gradient, RawStroke, RawGradient, RawStrokeGradient, RawGradientAutoRotation, RawStrokeGradientAutoRotation
end

local function IsValid(Target)
    if not (Target and Target.Parent) then return end
    local Humanoid = Target:FindFirstChildOfClass("Humanoid")
    return Humanoid and Humanoid.Health > 0
end

local function GetTargets(Targeted, IncludeLocalPlayer)
    local ActiveTargets, ActiveSet = {}, {}
    if typeof(Targeted) == "string" then
        local List = Targeted == "players" and Players or Entities
        for _, Entity in List do
            local IsLocal = (Targeted == "players" and Entity == Client.Player) or Entity == Client.Character
            if IsLocal and not IncludeLocalPlayer then continue end
            local Character = Targeted == "players" and Entity.Character or Entity
            if not Character then continue end
            table.insert(ActiveTargets, Character)
            ActiveSet[Character] = true
        end
    elseif typeof(Targeted) == "Instance" then
        table.insert(ActiveTargets, Targeted)
        ActiveSet[Targeted] = true
    end
    return ActiveTargets, ActiveSet
end

local function CopyProperites(Target, Source, Keys)
    for _, Key in Keys do Target[Key] = Source[Key] end
end

local function CopyGradient(Target, Source, AutoRotation)
    for _, Key in GradientKeys do
        if Key == "Rotation" and AutoRotation.Enabled then continue end
        Target[Key] = Source[Key]
    end
end

local function CreateObject(EspObject, UpdateFunction)
    return setmetatable({}, {
        __index = EspObject,
        __newindex = function(_, Key, Value)
            if table.find({ "__TYPE", "__PARENT", "__OBJECTS", "Remove", "Destroy", "Stroke", "Gradient" }, Key) then
                error("You Cannot Set " .. Key)
            end
            assert(EspObject[Key] ~= nil or Key == "Target" or Key == "Origin", "Invalid Property '" .. Key .. "' For " .. EspObject.__TYPE)
            if Key == "Target" then
                if typeof(Value) == "string" then
                    Value = CleanString(Value)
                    assert(Value == "players" or Value == "entities", "Property 'Target' Must Be 'players' Or 'entities', Got '" .. Value .. "'")
                elseif typeof(Value) == "Instance" then
                    assert(Value:IsA("BasePart") or Value:IsA("Model"), "Property 'Target' Instance Must Be BasePart Or Model, Got " .. Value.ClassName)
                elseif Value ~= nil then
                    error("Property 'Target' Expects BasePart, Model, 'players', 'entities', Or nil, Got " .. typeof(Value))
                end
            elseif Key == "Origin" then
                assert(typeof(Value) == "UDim2" or typeof(Value) == "Vector2", "Property 'Origin' Expects UDim2 Or Vector2, Got " .. typeof(Value))
            elseif Key == "Value" then
                assert(typeof(Value) == "function" or typeof(Value) == "number", "Property 'Value' Expects function Or number, Got " .. typeof(Value))
            elseif Key == "Side" then
                assert(typeof(Value) == "string", "Property 'Side' Expects string, Got " .. typeof(Value))
                Value = Value:sub(1, 1):upper() .. Value:sub(2):lower()
                assert(table.find({ "Left", "Right", "Top", "Bottom" }, Value), "Property 'Side' Must Be 'Left', 'Right', 'Top', Or 'Bottom', Got '" .. Value .. "'")
            elseif Key == "ColorStages" then
                assert(typeof(Value) == "table", "Property 'ColorStages' Expects table, Got " .. typeof(Value))
            else
                assert(typeof(Value) == typeof(EspObject[Key]), "Property '" .. Key .. "' Expects " .. typeof(EspObject[Key]) .. ", Got " .. typeof(Value))
            end
            EspObject[Key] = Value
            UpdateFunction()
        end
    })
end

local function GetDistance(Target)
    if not Client.RootPart then return 0 end
    local RootPart = Target:FindFirstChild("HumanoidRootPart") or Target:FindFirstChildWhichIsA("BasePart")
    if not RootPart then return 0 end
    return math.floor((Client.RootPart.Position - RootPart.Position).Magnitude)
end

local function GetStaticBounds(Target)
    local IsModel = Target:IsA("Model")
    local Position, Size
    if IsModel then
        local Torso = Target:FindFirstChild("Torso") or Target:FindFirstChild("UpperTorso") or Target:FindFirstChildWhichIsA("BasePart")
        if not Torso then return end
        local IsR15 = Torso.Name:find("Upper")
        Position = Torso.Position - vector.create(0, IsR15 and 0.65 or 0.5, 0)
        Size = vector.create(5, IsR15 and Torso.Size.Y * 4 or 6.5, 0)
    else
        Position, Size = Target.Position, Target.Size
    end
    local Screen, OnScreen = Client.Camera:WorldToViewportPoint(Position)
    if not OnScreen then return end
    local Scale = 1 / (Client.Camera.CFrame.Position - Position).Magnitude * 500
    return { Screen.X - Size.X * Scale / 2, Screen.Y - Size.Y * Scale / 2, Size.X * Scale, Size.Y * Scale }
end

local function GetScaledSize(BaseSize, Target, Dynamic, CachedDistance)
    if not Dynamic then return BaseSize end
    local Distance = CachedDistance or GetDistance(Target)
    return Distance > 0 and math.clamp(math.floor((BaseSize * 50) / Distance), 6, BaseSize * 2) or BaseSize
end

local function GetLabelPosition(Target, Side, Offset)
    local Bounds = ActiveBoxBounds[Target] or GetStaticBounds(Target)
    if not Bounds then return end
    local ScreenPosition
    if Side == "Top" then ScreenPosition = Vector2.new(Bounds[1] + Bounds[3] / 2, Bounds[2])
    elseif Side == "Bottom" then ScreenPosition = Vector2.new(Bounds[1] + Bounds[3] / 2, Bounds[2] + Bounds[4])
    elseif Side == "Left" then ScreenPosition = Vector2.new(Bounds[1], Bounds[2] + Bounds[4] / 2)
    elseif Side == "Right" then ScreenPosition = Vector2.new(Bounds[1] + Bounds[3], Bounds[2] + Bounds[4] / 2)
    end
    return ScreenPosition and (ScreenPosition + Offset) or nil
end

local function GetHumanoidState(Target)
    local Humanoid = Target:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return "Unknown" end
    local State = Humanoid:GetState()
    if State == Enum.HumanoidStateType.Running and Humanoid.MoveDirection.Magnitude < 0.1 then return "Idle" end
    return StateNames[State] or tostring(State):match("%.(%w+)$") or "Unknown"
end

local function CleanupLabels(EspObject, ToRemove)
    for _, Target in ToRemove do
        local Label = EspObject.__OBJECTS[Target]
        if Label then pcall(Label.Destroy, Label) end
        EspObject.__OBJECTS[Target] = nil
    end
end

local function NewLabel()
    local Label = Instance.new("TextLabel", ESPUIDirectory)
    Label.BackgroundTransparency, Label.BorderSizePixel, TextStrokeTransparency, Label.AutomaticSize = 1, 0, 0, Enum.AutomaticSize.XY
    return Label
end



--// ESP FUNCTIONS



local function ESPHighlight()
    local Highlight = {
        __TYPE = "Highlight",
        __PARENT = Instance.new("Folder", ESPDirectory),
        __OBJECTS = {},
        Enabled = true,
        FillColor = Color3.new(1, 1, 1),
        FillTransparency = 0.75,
        OutlineColor = Color3.new(0, 0, 0),
        OutlineTransparency = 1,
        AlwaysOnTop = true,
        IncludeLocalPlayer = false,
    }
    
    Objects.Highlights += 1
    local HighlightIndex = Objects.Highlights
    
    Highlight.Remove = function(Self)
        RunIn.Heartbeat["UpdateHighlight" .. HighlightIndex] = nil
        for _, HighlightInstance in Self.__OBJECTS do pcall(HighlightInstance.Destroy, HighlightInstance) end
        Objects.Highlights -= 1
        pcall(Self.__PARENT.Destroy, Self.__PARENT)
        setmetatable(Self, nil)
    end; Highlight.Destroy = Highlight.Remove
    
    local function ApplyHighlight(HighlightInstance, Target)
        pcall(function()
            HighlightInstance.Parent, HighlightInstance.Adornee, HighlightInstance.Enabled, HighlightInstance.DepthMode, HighlightInstance.FillColor, HighlightInstance.FillTransparency, HighlightInstance.OutlineColor, HighlightInstance.OutlineTransparency = Highlight.__PARENT, Target, Highlight.Enabled, Highlight.AlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded, Highlight.FillColor, FlipTransparency(Highlight.FillTransparency), Highlight.OutlineColor, FlipTransparency(Highlight.OutlineTransparency)
        end)
    end
    
    local function UpdateHighlight()
        if not Highlight.Target then return end
        local ActiveTargets, ActiveSet = GetTargets(Highlight.Target, Highlight.IncludeLocalPlayer)
        local ToRemove = {}
        for Target in Highlight.__OBJECTS do
            if not ActiveSet[Target] or not IsValid(Target) then table.insert(ToRemove, Target) end
        end
        for _, Target in ToRemove do
            local ExistingHighlight = Highlight.__OBJECTS[Target]
            if ExistingHighlight then pcall(ExistingHighlight.Destroy, ExistingHighlight) end
            Highlight.__OBJECTS[Target] = nil
        end
        for _, Target in ActiveTargets do
            if not IsValid(Target) then continue end
            local HighlightInstance = Highlight.__OBJECTS[Target]
            if not HighlightInstance or not HighlightInstance.Parent then
                HighlightInstance = Instance.new("Highlight", Highlight.__PARENT)
                Highlight.__OBJECTS[Target] = HighlightInstance
                local function Remove()
                    local Existing = Highlight.__OBJECTS[Target]
                    if not Existing then return end
                    pcall(Existing.Destroy, Existing)
                    Highlight.__OBJECTS[Target] = nil
                end
                local Humanoid = Target:FindFirstChildOfClass("Humanoid")
                if Humanoid then Humanoid.Died:Connect(Remove) end
                Target.Destroying:Connect(Remove)
            end
            ApplyHighlight(HighlightInstance, Target)
        end
    end; RunIn.Heartbeat["UpdateHighlight" .. HighlightIndex] = UpdateHighlight
    
    return CreateObject(Highlight, UpdateHighlight)
end

local function ESPTracer()
    local Tracer = {
        __TYPE = "Tracer",
        __PARENT = Instance.new("Folder", ESPDirectory),
        __OBJECTS = {},
        Enabled = true,
        Color = Color3.new(1, 1, 1),
        Transparency = 1,
        Thickness = 1,
        ZIndex = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Origin = UDim2.new(0.5, 0, 1, 0),
        IncludeLocalPlayer = false,
    }
    
    Objects.Tracers += 1
    local TracerIndex = Objects.Tracers
    
    local Stroke, Gradient, RawStroke, RawGradient, RawStrokeGradient, RawGradientAutoRotation, RawStrokeGradientAutoRotation = MakeStyles(false, Color3.new(1, 1, 1))
    Tracer.Stroke, Tracer.Gradient = Stroke, Gradient
    
    Tracer.Remove = function(Self)
        RunIn.PreRender["UpdateTracer" .. TracerIndex] = nil
        for _, Line in Self.__OBJECTS do pcall(Line.Remove, Line) end
        Objects.Tracers -= 1
        pcall(Self.__PARENT.Destroy, Self.__PARENT)
        setmetatable(Self, nil)
    end; Tracer.Destroy = Tracer.Remove
    
    local function ApplyTracer(Line)
        Line.Color, Line.Transparency, Line.Thickness, Line.ZIndex, Line.AnchorPoint = Tracer.Color, Tracer.Transparency, Tracer.Thickness, Tracer.ZIndex, Tracer.AnchorPoint
        CopyProperites(Line.Stroke, RawStroke, StrokeKeys)
        CopyGradient(Line.Stroke.Gradient, RawStrokeGradient, RawStrokeGradientAutoRotation)
        CopyProperites(Line.Stroke.Gradient.AutoRotation, RawStrokeGradientAutoRotation, AutoRotationKeys)
        CopyGradient(Line.Gradient, RawGradient, RawGradientAutoRotation)
        CopyProperites(Line.Gradient.AutoRotation, RawGradientAutoRotation, AutoRotationKeys)
    end
    
    local function UpdateTracer()
        if not Tracer.Target then return end
        local ActiveTargets, ActiveSet = GetTargets(Tracer.Target, Tracer.IncludeLocalPlayer)
        local ToRemove = {}
        for Target in Tracer.__OBJECTS do
            if not ActiveSet[Target] or not IsValid(Target) then table.insert(ToRemove, Target) end
        end
        for _, Target in ToRemove do
            local ExistingLine = Tracer.__OBJECTS[Target]
            if ExistingLine then pcall(ExistingLine.Remove, ExistingLine) end
            Tracer.__OBJECTS[Target] = nil
        end
        for _, Target in ActiveTargets do
            if not IsValid(Target) then continue end
            local Line = Tracer.__OBJECTS[Target]
            if not Line then
                Line = Drawing.new("Line")
                Tracer.__OBJECTS[Target] = Line
                local function Remove()
                    local Existing = Tracer.__OBJECTS[Target]
                    if not Existing then return end
                    pcall(Existing.Remove, Existing)
                    Tracer.__OBJECTS[Target] = nil
                end
                local Humanoid = Target:FindFirstChildOfClass("Humanoid")
                if Humanoid then Humanoid.Died:Connect(Remove) end
                Target.Destroying:Connect(Remove)
            end
            ApplyTracer(Line)
            Line:Trace(Tracer.Origin, Target)
            if not Tracer.Enabled then Line.Visible = false end
        end
    end; RunIn.PreRender["UpdateTracer" .. TracerIndex] = UpdateTracer
    
    return CreateObject(Tracer, UpdateTracer)
end

local function ESPBox()
    local Box = {
        __TYPE = "Box",
        __PARENT = Instance.new("Folder", ESPDirectory),
        __OBJECTS = {},
        Enabled = true,
        Filled = true,
        Color = Color3.new(1, 1, 1),
        Transparency = 0.5,
        ZIndex = 0,
        Dynamic = true,
        IncludeAccessories = false,
        IncludeLocalPlayer = false,
    }
    
    Objects.Boxes += 1
    local BoxIndex = Objects.Boxes
    
    local Stroke, Gradient, RawStroke, RawGradient, RawStrokeGradient, RawGradientAutoRotation, RawStrokeGradientAutoRotation = MakeStyles(true, Color3.new(0, 0, 0))
    Box.Stroke, Box.Gradient = Stroke, Gradient
    
    Box.Remove = function(Self)
        RunIn.PreRenderSync["UpdateBox" .. BoxIndex] = nil
        for Target, Square in Self.__OBJECTS do
            pcall(Square.Remove, Square)
            ActiveBoxBounds[Target] = nil
        end
        Objects.Boxes -= 1
        pcall(Self.__PARENT.Destroy, Self.__PARENT)
        setmetatable(Self, nil)
    end; Box.Destroy = Box.Remove
    
    local function GetScreenBounds(Target)
        local IsModel = Target:IsA("Model")
        local PartList = IsModel and (Box.IncludeAccessories and Target:GetDescendants() or Target:GetChildren()) or { Target }
        local Hits, MinX, MinY, MaxX, MaxY = 0, math.huge, math.huge, -math.huge, -math.huge
        for _, Part in PartList do
            if not Part:IsA("BasePart") or Part.Transparency == 1 then continue end
            local PartCFrame, HalfSize = Part.CFrame, Part.Size / 2
            for _, Corner in {
                vector.create(HalfSize.X, HalfSize.Y, HalfSize.Z), vector.create(-HalfSize.X, HalfSize.Y, HalfSize.Z),
                vector.create(HalfSize.X, -HalfSize.Y, HalfSize.Z), vector.create(-HalfSize.X, -HalfSize.Y, HalfSize.Z),
                vector.create(HalfSize.X, HalfSize.Y, -HalfSize.Z), vector.create(-HalfSize.X, HalfSize.Y, -HalfSize.Z),
                vector.create(HalfSize.X, -HalfSize.Y, -HalfSize.Z), vector.create(-HalfSize.X, -HalfSize.Y, -HalfSize.Z),
            } do
                local Screen, OnScreen = Client.Camera:WorldToViewportPoint(PartCFrame * Corner)
                if not OnScreen then continue end
                Hits += 1
                MinX, MinY = math.min(MinX, Screen.X), math.min(MinY, Screen.Y)
                MaxX, MaxY = math.max(MaxX, Screen.X), math.max(MaxY, Screen.Y)
            end
        end
        return Hits > 0 and { MinX, MinY, MaxX - MinX, MaxY - MinY } or nil
    end
    
    local function ApplyBox(Square, Bounds)
        Square.Position, Square.Size, Square.AnchorPoint, Square.Visible, Square.Filled, Square.Color, Square.Transparency, Square.ZIndex = Vector2.new(Bounds[1], Bounds[2]), Vector2.new(Bounds[3], Bounds[4]), Vector2.new(0, 0), Box.Enabled, Box.Filled, Box.Color, Box.Transparency, Box.ZIndex
        Square.Stroke.Enabled, Square.Stroke.Color, Square.Stroke.Transparency, Square.Stroke.Thickness, Square.Stroke.LineJoinMode = Box.Enabled and RawStroke.Enabled, RawStroke.Color, RawStroke.Transparency, RawStroke.Thickness, RawStroke.LineJoinMode
        CopyGradient(Square.Stroke.Gradient, RawStrokeGradient, RawStrokeGradientAutoRotation)
        CopyProperites(Square.Stroke.Gradient.AutoRotation, RawStrokeGradientAutoRotation, AutoRotationKeys)
        CopyGradient(Square.Gradient, RawGradient, RawGradientAutoRotation)
        CopyProperites(Square.Gradient.AutoRotation, RawGradientAutoRotation, AutoRotationKeys)
    end
    
    local function UpdateBox()
        if not Box.Target then return end
        local ActiveTargets, ActiveSet = GetTargets(Box.Target, Box.IncludeLocalPlayer)
        local ToRemove = {}
        for Target in Box.__OBJECTS do
            if not ActiveSet[Target] or not IsValid(Target) then table.insert(ToRemove, Target) end
        end
        for _, Target in ToRemove do
            local ExistingSquare = Box.__OBJECTS[Target]
            if ExistingSquare then pcall(ExistingSquare.Remove, ExistingSquare) end
            Box.__OBJECTS[Target], ActiveBoxBounds[Target] = nil, nil
        end
        for _, Target in ActiveTargets do
            if not IsValid(Target) then continue end
            local Square = Box.__OBJECTS[Target]
            if not Square then
                Square = Drawing.new("Square")
                Box.__OBJECTS[Target] = Square
                local function Remove()
                    local Existing = Box.__OBJECTS[Target]
                    if not Existing then return end
                    pcall(Existing.Remove, Existing)
                    Box.__OBJECTS[Target], ActiveBoxBounds[Target] = nil, nil
                end
                local Humanoid = Target:FindFirstChildOfClass("Humanoid")
                if Humanoid then Humanoid.Died:Connect(Remove) end
                Target.Destroying:Connect(Remove)
            end
            local Bounds = Box.Dynamic and GetScreenBounds(Target) or GetStaticBounds(Target)
            if not Bounds then Square.Visible, Square.Stroke.Enabled, ActiveBoxBounds[Target] = false, false, nil; continue end
            ApplyBox(Square, Bounds)
            ActiveBoxBounds[Target] = Box.Enabled and Bounds or nil
        end
    end; RunIn.PreRenderSync["UpdateBox" .. BoxIndex] = UpdateBox
    
    return CreateObject(Box, UpdateBox)
end

local function ESPBar()
    local Bar = {
        __TYPE = "Bar",
        __PARENT = Instance.new("Folder", ESPDirectory),
        __OBJECTS = {},
        Enabled = true,
        Color = Color3.new(0, 1, 0),
        BackColor = Color3.new(0, 0, 0),
        Transparency = 1,
        BackTransparency = 0.5,
        Thickness = 2,
        Padding = 3,
        Side = "Left",
        ColorStages = {
            { Value = 1.0, Color = Color3.new(0, 1, 0) },
            { Value = 0.5, Color = Color3.new(1, 1, 0) },
            { Value = 0.0, Color = Color3.new(1, 0, 0) },
        },
        Value = function(Target)
            local Humanoid = Target:FindFirstChildOfClass("Humanoid")
            if not Humanoid then return 1 end
            return Humanoid.Health / math.max(Humanoid.MaxHealth, 1)
        end,
        IncludeLocalPlayer = false,
    }
    
    Objects.Bars += 1
    local BarIndex = Objects.Bars
    
    local Stroke, Gradient, RawStroke, RawGradient, RawStrokeGradient, RawGradientAutoRotation, RawStrokeGradientAutoRotation = MakeStyles(true, Color3.new(0, 0, 0))
    Bar.Stroke, Bar.Gradient = Stroke, Gradient
    
    Bar.Remove = function(Self)
        RunIn.PreRender["UpdateBar" .. BarIndex] = nil
        for _, Pair in Self.__OBJECTS do
            pcall(Pair.Fill.Remove, Pair.Fill)
            pcall(Pair.Back.Remove, Pair.Back)
        end
        Objects.Bars -= 1
        pcall(Self.__PARENT.Destroy, Self.__PARENT)
        setmetatable(Self, nil)
    end; Bar.Destroy = Bar.Remove
    
    local function GetFillColor(FillValue)
        local Stages = Bar.ColorStages
        if not Stages or #Stages == 0 then return Bar.Color end
        local UpperStage, LowerStage
        for _, Stage in Stages do
            if Stage.Value >= FillValue and (not UpperStage or Stage.Value < UpperStage.Value) then UpperStage = Stage end
            if Stage.Value <= FillValue and (not LowerStage or Stage.Value > LowerStage.Value) then LowerStage = Stage end
        end
        if not UpperStage then return LowerStage and LowerStage.Color or Bar.Color end
        if not LowerStage then return UpperStage.Color end
        if UpperStage.Value == LowerStage.Value then return UpperStage.Color end
        return LowerStage.Color:Lerp(UpperStage.Color, (FillValue - LowerStage.Value) / (UpperStage.Value - LowerStage.Value))
    end
    
    local function GetBarValue(Target)
        local BarValue = Bar.Value
        if typeof(BarValue) == "function" then
            local Success, Result = pcall(BarValue, Target)
            return Success and math.clamp(Result or 0, 0, 1) or 0
        end
        return math.clamp(BarValue, 0, 1)
    end
    
    local function ComputeBarLayout(Target)
        local BoxBounds = ActiveBoxBounds[Target]
        local Bounds = BoxBounds or GetStaticBounds(Target)
        if not Bounds then return end
        local IsVertical, BarPadding, BarValue, BoundsX, BoundsY, BoundsWidth, BoundsHeight = Bar.Side == "Left" or Bar.Side == "Right", BoxBounds and Bar.Padding or math.max(1, Bar.Padding - 2), GetBarValue(Target), Bounds[1], Bounds[2], Bounds[3], Bounds[4]
        local BackX, BackY, BackWidth, BackHeight, FillX, FillY, FillWidth, FillHeight
        
        if IsVertical then
            BackWidth, BackHeight, BackY = Bar.Thickness, BoundsHeight, BoundsY
            BackX = Bar.Side == "Left" and BoundsX - BarPadding - Bar.Thickness or BoundsX + BoundsWidth + BarPadding
            FillWidth, FillHeight = BackWidth, math.max(0, BackHeight * BarValue)
            FillX, FillY = BackX, BackY + BackHeight - FillHeight
        else
            BackWidth, BackHeight, BackX = BoundsWidth, Bar.Thickness, BoundsX
            BackY = Bar.Side == "Top" and BoundsY - BarPadding - Bar.Thickness or BoundsY + BoundsHeight + BarPadding
            FillX, FillY, FillWidth, FillHeight = BackX, BackY, math.max(0, BackWidth * BarValue), BackHeight
        end
        
        return { BackX, BackY, BackWidth, BackHeight }, { FillX, FillY, FillWidth, FillHeight }, BarValue
    end
    
    local function ApplyBar(Pair, BackBounds, FillBounds, BarValue)
        local Back, Fill = Pair.Back, Pair.Fill
        Back.Position, Back.Size, Back.AnchorPoint, Back.Color, Back.Transparency, Back.Filled, Back.Visible, Back.ZIndex = Vector2.new(BackBounds[1], BackBounds[2]), Vector2.new(BackBounds[3], BackBounds[4]), Vector2.new(0, 0), Bar.BackColor, Bar.BackTransparency, true, Bar.Enabled, 1
        Back.Stroke.Enabled, Back.Stroke.Color, Back.Stroke.Transparency, Back.Stroke.Thickness, Back.Stroke.LineJoinMode = Bar.Enabled and RawStroke.Enabled, RawStroke.Color, RawStroke.Transparency, RawStroke.Thickness, RawStroke.LineJoinMode
        CopyGradient(Back.Stroke.Gradient, RawStrokeGradient, RawStrokeGradientAutoRotation)
        CopyProperites(Back.Stroke.Gradient.AutoRotation, RawStrokeGradientAutoRotation, AutoRotationKeys)
        Fill.Position, Fill.Size, Fill.AnchorPoint, Fill.Color, Fill.Transparency, Fill.Filled, Fill.Visible, Fill.ZIndex, Fill.Stroke.Enabled = Vector2.new(FillBounds[1], FillBounds[2]), Vector2.new(FillBounds[3], FillBounds[4]), Vector2.new(0, 0), GetFillColor(BarValue), Bar.Transparency, true, Bar.Enabled and (FillBounds[3] > 0 and FillBounds[4] > 0), 2, false
        CopyGradient(Fill.Gradient, RawGradient, RawGradientAutoRotation)
        CopyProperites(Fill.Gradient.AutoRotation, RawGradientAutoRotation, AutoRotationKeys)
    end
    
    local function UpdateBar()
        if not Bar.Target then return end
        local ActiveTargets, ActiveSet = GetTargets(Bar.Target, Bar.IncludeLocalPlayer)
        local ToRemove = {}
        for Target in Bar.__OBJECTS do
            if not ActiveSet[Target] or not IsValid(Target) then table.insert(ToRemove, Target) end
        end
        for _, Target in ToRemove do
            local ExistingPair = Bar.__OBJECTS[Target]
            if ExistingPair then pcall(ExistingPair.Fill.Remove, ExistingPair.Fill); pcall(ExistingPair.Back.Remove, ExistingPair.Back) end
            Bar.__OBJECTS[Target] = nil
        end
        for _, Target in ActiveTargets do
            if not IsValid(Target) then continue end
            local Pair = Bar.__OBJECTS[Target]
            if not Pair then
                Pair = { Back = Drawing.new("Square"), Fill = Drawing.new("Square") }
                Bar.__OBJECTS[Target] = Pair
                local function Remove()
                    local Existing = Bar.__OBJECTS[Target]
                    if not Existing then return end
                    pcall(Existing.Fill.Remove, Existing.Fill)
                    pcall(Existing.Back.Remove, Existing.Back)
                    Bar.__OBJECTS[Target] = nil
                end
                local Humanoid = Target:FindFirstChildOfClass("Humanoid")
                if Humanoid then Humanoid.Died:Connect(Remove) end
                local Player = Services.Players:GetPlayerFromCharacter(Target)
                if Player then Player.CharacterRemoving:Connect(Remove) end
                Target.Destroying:Connect(Remove)
            end
            local BackBounds, FillBounds, BarValue = ComputeBarLayout(Target)
            if not BackBounds then Pair.Back.Visible, Pair.Fill.Visible = false, false; continue end
            ApplyBar(Pair, BackBounds, FillBounds, BarValue)
        end
    end; RunIn.PreRender["UpdateBar" .. BarIndex] = UpdateBar
    
    return CreateObject(Bar, UpdateBar)
end

local function ESPName()
    local Name = {
        __TYPE = "Name",
        __PARENT = Instance.new("Folder", ESPDirectory),
        __OBJECTS = {},
        Enabled = true,
        Color = Color3.new(1, 1, 1),
        Size = 13,
        Transparency = 1,
        ZIndex = 1,
        Side = "Top",
        Offset = Vector2.new(0, -4),
        Font = Enum.Font.Roboto,
        UseDisplayName = true,
        Dynamic = false,
        IncludeLocalPlayer = false,
    }
    
    Objects.Names += 1
    local NameIndex = Objects.Names
    Name.Remove = function(Self)
        RunIn.PreRender["UpdateName" .. NameIndex] = nil
        for _, Label in Self.__OBJECTS do pcall(Label.Destroy, Label) end
        Objects.Names -= 1
        pcall(Self.__PARENT.Destroy, Self.__PARENT)
        setmetatable(Self, nil)
    end; Name.Destroy = Name.Remove
    
    local function UpdateName()
        if not Name.Target then return end
        local ActiveTargets, ActiveSet = GetTargets(Name.Target, Name.IncludeLocalPlayer)
        local ToRemove = {}
        for Target in Name.__OBJECTS do
            if not ActiveSet[Target] or not IsValid(Target) then table.insert(ToRemove, Target) end
        end
        CleanupLabels(Name, ToRemove)
        for _, Target in ActiveTargets do
            if not IsValid(Target) then continue end
            local Label = Name.__OBJECTS[Target]
            if not Label then
                Label = NewLabel()
                Name.__OBJECTS[Target] = Label
                local function Remove()
                    local ExistingLabel = Name.__OBJECTS[Target]
                    if not ExistingLabel then return end
                    pcall(ExistingLabel.Destroy, ExistingLabel)
                    Name.__OBJECTS[Target] = nil
                end
                local Humanoid = Target:FindFirstChildOfClass("Humanoid")
                if Humanoid then Humanoid.Died:Connect(Remove) end
                Target.Destroying:Connect(Remove)
            end
            local ScreenPosition = GetLabelPosition(Target, Name.Side, Name.Offset)
            if not ScreenPosition then Label.Visible = false; continue end
            local Player = Services.Players:GetPlayerFromCharacter(Target)
            local DisplayName = Player and (Name.UseDisplayName and Player.DisplayName or Player.Name) or Target.Name
            Label.Visible, Label.TextColor3, Label.TextTransparency, Label.TextSize, Label.Font, Label.Text, Label.ZIndex, Label.AnchorPoint, Label.Position = Name.Enabled, Name.Color, 1 - Name.Transparency, GetScaledSize(Name.Size, Target, Name.Dynamic), Name.Font, DisplayName, Name.ZIndex, SideAnchor[Name.Side], UDim2.fromOffset(ScreenPosition.X, ScreenPosition.Y)
        end
    end; RunIn.PreRender["UpdateName" .. NameIndex] = UpdateName
    
    return CreateObject(Name, UpdateName)
end

local function ESPDistance()
    local Distance = {
        __TYPE = "Distance",
        __PARENT = Instance.new("Folder", ESPDirectory),
        __OBJECTS = {},
        Enabled = true,
        Color = Color3.new(1, 1, 1),
        Size = 12,
        Transparency = 1,
        ZIndex = 1,
        Side = "Bottom",
        Offset = Vector2.new(0, 4),
        Suffix = "m",
        Font = Enum.Font.Roboto,
        Dynamic = false,
        IncludeLocalPlayer = false,
    }
    
    Objects.Distances += 1
    local DistanceIndex = Objects.Distances
    
    Distance.Remove = function(Self)
        RunIn.PreRender["UpdateDistance" .. DistanceIndex] = nil
        for _, Label in Self.__OBJECTS do pcall(Label.Destroy, Label) end
        Objects.Distances -= 1
        pcall(Self.__PARENT.Destroy, Self.__PARENT)
        setmetatable(Self, nil)
    end; Distance.Destroy = Distance.Remove
    
    local function UpdateDistance()
        if not Distance.Target then return end
        local ActiveTargets, ActiveSet = GetTargets(Distance.Target, Distance.IncludeLocalPlayer)
        local ToRemove = {}
        for Target in Distance.__OBJECTS do
            if not ActiveSet[Target] or not IsValid(Target) then table.insert(ToRemove, Target) end
        end
        CleanupLabels(Distance, ToRemove)
        for _, Target in ActiveTargets do
            if not IsValid(Target) then continue end
            local Label = Distance.__OBJECTS[Target]
            if not Label then
                Label = NewLabel()
                Distance.__OBJECTS[Target] = Label
                local function Remove()
                    local ExistingLabel = Distance.__OBJECTS[Target]
                    if not ExistingLabel then return end
                    pcall(ExistingLabel.Destroy, ExistingLabel)
                    Distance.__OBJECTS[Target] = nil
                end
                local Humanoid = Target:FindFirstChildOfClass("Humanoid")
                if Humanoid then Humanoid.Died:Connect(Remove) end
                Target.Destroying:Connect(Remove)
            end
            local ScreenPosition = GetLabelPosition(Target, Distance.Side, Distance.Offset)
            if not ScreenPosition then Label.Visible = false; continue end
            local TargetDistance = GetDistance(Target)
            Label.Visible, Label.TextColor3, Label.TextTransparency, Label.TextSize,
            Label.Font, Label.Text, Label.ZIndex, Label.AnchorPoint, Label.Position = Distance.Enabled, Distance.Color, 1 - Distance.Transparency, GetScaledSize(Distance.Size, Target, Distance.Dynamic, TargetDistance), Distance.Font, TargetDistance .. Distance.Suffix, Distance.ZIndex, SideAnchor[Distance.Side], UDim2.fromOffset(ScreenPosition.X, ScreenPosition.Y)
        end
    end; RunIn.PreRender["UpdateDistance" .. DistanceIndex] = UpdateDistance
    
    return CreateObject(Distance, UpdateDistance)
end

local function ESPState()
    local State = {
        __TYPE = "State",
        __PARENT = Instance.new("Folder", ESPDirectory),
        __OBJECTS = {},
        Enabled = true,
        Color = Color3.new(1, 1, 1),
        Size = 12,
        Transparency = 1,
        ZIndex = 1,
        Side = "Right",
        Offset = Vector2.new(4, 0),
        Font = Enum.Font.Roboto,
        Dynamic = false,
        IncludeLocalPlayer = false,
    }
    
    Objects.States += 1
    local StateIndex = Objects.States
    
    State.Remove = function(Self)
        RunIn.PreRender["UpdateState" .. StateIndex] = nil
        for _, Label in Self.__OBJECTS do pcall(Label.Destroy, Label) end
        Objects.States -= 1
        pcall(Self.__PARENT.Destroy, Self.__PARENT)
        setmetatable(Self, nil)
    end; State.Destroy = State.Remove
    
    local function UpdateState()
        if not State.Target then return end
        local ActiveTargets, ActiveSet = GetTargets(State.Target, State.IncludeLocalPlayer)
        local ToRemove = {}
        for Target in State.__OBJECTS do
            if not ActiveSet[Target] or not IsValid(Target) then table.insert(ToRemove, Target) end
        end
        CleanupLabels(State, ToRemove)
        for _, Target in ActiveTargets do
            if not IsValid(Target) then continue end
            local Label = State.__OBJECTS[Target]
            if not Label then
                Label = NewLabel()
                State.__OBJECTS[Target] = Label
                local function Remove()
                    local ExistingLabel = State.__OBJECTS[Target]
                    if not ExistingLabel then return end
                    pcall(ExistingLabel.Destroy, ExistingLabel)
                    State.__OBJECTS[Target] = nil
                end
                local Humanoid = Target:FindFirstChildOfClass("Humanoid")
                if Humanoid then Humanoid.Died:Connect(Remove) end
                Target.Destroying:Connect(Remove)
            end
            local ScreenPosition = GetLabelPosition(Target, State.Side, State.Offset)
            if not ScreenPosition then Label.Visible = false; continue end
            Label.Visible, Label.TextColor3, Label.TextTransparency, Label.TextSize, Label.Font, Label.Text, Label.ZIndex, Label.AnchorPoint, Label.Position = State.Enabled, State.Color, 1 - State.Transparency, GetScaledSize(State.Size, Target, State.Dynamic), State.Font, GetHumanoidState(Target), State.ZIndex, SideAnchor[State.Side], UDim2.fromOffset(ScreenPosition.X, ScreenPosition.Y)
        end
    end; RunIn.PreRender["UpdateState" .. StateIndex] = UpdateState
    
    return CreateObject(State, UpdateState)
end

local function ESPTool()
    local Tool = {
        __TYPE = "Tool",
        __PARENT = Instance.new("Folder", ESPDirectory),
        __OBJECTS = {},
        Enabled = true,
        Color = Color3.new(1, 1, 1),
        Size = 11,
        IconSize = 30,
        Transparency = 1,
        ZIndex = 1,
        Side = "Bottom",
        Offset = Vector2.new(0, 6),
        ShowIcon = true,
        ShowName = true,
        Font = Enum.Font.Roboto,
        LabelPosition = "Below",
        Dynamic = false,
        IncludeLocalPlayer = false,
    }
    
    Objects.Tools += 1
    local ToolIndex = Objects.Tools
    
    Tool.Remove = function(Self)
        RunIn.PreRender["UpdateTool" .. ToolIndex] = nil
        for _, Pair in Self.__OBJECTS do
            pcall(Pair.Label.Destroy, Pair.Label)
            pcall(function() Pair.Icon:Destroy() end)
        end
        Objects.Tools -= 1
        pcall(Self.__PARENT.Destroy, Self.__PARENT)
        setmetatable(Self, nil)
    end; Tool.Destroy = Tool.Remove
    
    local function UpdateTool()
        if not Tool.Target then return end
        local ActiveTargets, ActiveSet = GetTargets(Tool.Target, Tool.IncludeLocalPlayer)
        local ToRemove = {}
        for Target in Tool.__OBJECTS do
            if not ActiveSet[Target] or not IsValid(Target) then table.insert(ToRemove, Target) end
        end
        for _, Target in ToRemove do
            local ExistingPair = Tool.__OBJECTS[Target]
            if ExistingPair then
                pcall(ExistingPair.Label.Destroy, ExistingPair.Label)
                pcall(function() ExistingPair.Icon:Destroy() end)
            end
            Tool.__OBJECTS[Target] = nil
        end
        for _, Target in ActiveTargets do
            if not IsValid(Target) then continue end
            local Pair = Tool.__OBJECTS[Target]
            if not Pair then
                local Icon = Instance.new("ImageLabel", ESPUIDirectory)
                Icon.BackgroundTransparency, Icon.BorderSizePixel, Icon.AnchorPoint = 1, 0, Vector2.new(0.5, 0.5)
                Pair = { Icon = Icon, Label = NewLabel() }
                Tool.__OBJECTS[Target] = Pair
                local function Remove()
                    local Existing = Tool.__OBJECTS[Target]
                    if not Existing then return end
                    pcall(Existing.Label.Destroy, Existing.Label)
                    pcall(function() Existing.Icon:Destroy() end)
                    Tool.__OBJECTS[Target] = nil
                end
                local Humanoid = Target:FindFirstChildOfClass("Humanoid")
                if Humanoid then Humanoid.Died:Connect(Remove) end
                local Player = Services.Players:GetPlayerFromCharacter(Target)
                if Player then Player.CharacterRemoving:Connect(Remove) end
                Target.Destroying:Connect(Remove)
            end
            
            local ScreenPosition, EquippedTool = GetLabelPosition(Target, Tool.Side, Tool.Offset), Target:FindFirstChildOfClass("Tool")
            
            if not ScreenPosition or not EquippedTool or not Tool.Enabled then
                Pair.Icon.Visible, Pair.Label.Visible = false, false; continue
            end
            
            local TextureId, TargetDistance, IconX, IconY, LabelX, LabelY = EquippedTool.TextureId ~= "" and EquippedTool.TextureId or "rbxasset://textures/ui/GuiImagePlaceholder.png", GetDistance(Target), ScreenPosition.X, 0, ScreenPosition.X, 0
            local ScaledTextSize, ScaledIconSize = GetScaledSize(Tool.Size, Target, Tool.Dynamic, TargetDistance), Tool.Dynamic and math.clamp(math.floor(Tool.IconSize * 30 / math.max(TargetDistance, 1)), 6, Tool.IconSize * 2) or Tool.IconSize
            local HalfIconSize = ScaledIconSize / 2
            
            if Tool.ShowIcon and Tool.ShowName then
                if Tool.LabelPosition == "Above" then
                    LabelY, IconY = ScreenPosition.Y, ScreenPosition.Y + ScaledTextSize + 2 + HalfIconSize
                else
                    IconY, LabelY = ScreenPosition.Y + HalfIconSize, ScreenPosition.Y + HalfIconSize * 2 + 2
                end
            elseif Tool.ShowIcon then
                IconY = ScreenPosition.Y + HalfIconSize
            elseif Tool.ShowName then
                LabelY = ScreenPosition.Y
            end
            
            if Tool.ShowIcon then
                Pair.Icon.Visible, Pair.Icon.Image, Pair.Icon.ImageTransparency, Pair.Icon.ZIndex, Pair.Icon.Position, Pair.Icon.Size = true, TextureId, 1 - Tool.Transparency, Tool.ZIndex, UDim2.fromOffset(IconX, IconY), UDim2.fromOffset(ScaledIconSize, ScaledIconSize)
            else
                Pair.Icon.Visible = false
            end
            
            if Tool.ShowName then
                Pair.Label.Visible, Pair.Label.TextColor3, Pair.Label.TextTransparency, Pair.Label.TextSize, Pair.Label.Font, Pair.Label.Text, Pair.Label.ZIndex, Pair.Label.AnchorPoint, Pair.Label.Position = true, Tool.Color, 1 - Tool.Transparency, ScaledTextSize, Tool.Font, EquippedTool.Name, Tool.ZIndex, Vector2.new(0.5, 0), UDim2.fromOffset(LabelX, LabelY)
            else
                Pair.Label.Visible = false
            end
        end
    end; RunIn.PreRender["UpdateTool" .. ToolIndex] = UpdateTool
    
    return CreateObject(Tool, UpdateTool)
end



--// ESP API



local ESPFunctions = {
    highlight = ESPHighlight,
    tracer = ESPTracer,
    box = ESPBox,
    bar = ESPBar,
    name = ESPName,
    distance = ESPDistance,
    state = ESPState,
    tool = ESPTool,
}

function ESP.new(Type)
    assert(typeof(Type) == "string", "Expected ESP Type (string), Got " .. typeof(Type))
    local Function = ESPFunctions[CleanString(Type)]
    assert(Function, "Invalid ESP Type: " .. Type)
    return Function()
end



--// CONNECTIONS



Services.Run:BindToRenderStep("ESPPreRender", 200, function(DeltaTime)
    for _, UpdateFunction in RunIn.PreRenderSync do UpdateFunction(DeltaTime) end
    for _, UpdateFunction in RunIn.PreRender do task.spawn(UpdateFunction, DeltaTime) end
end)

Services.Run.Heartbeat:Connect(function(DeltaTime)
    for _, UpdateFunction in RunIn.Heartbeat do task.spawn(UpdateFunction, DeltaTime) end
end)

return ESP
