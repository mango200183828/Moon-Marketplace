-- ============================================
-- 🌝 Moon Marketplace v1.0
-- Senior Developer Script for Roblox Executors
-- Only works in Studio Lite (Game ID: 10959918411)
-- ============================================

local ALLOWED_GAME_ID = 10959918411
if game.PlaceId ~= ALLOWED_GAME_ID then
    warn("[Moon Marketplace] This script only works in Studio Lite!")
    return
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

if CoreGui:FindFirstChild("MoonMarketplace") then
    CoreGui:FindFirstChild("MoonMarketplace"):Destroy()
end

-- ============================================
-- THEME
-- ============================================
local Theme = {
    Primary = Color3.fromRGB(255, 140, 0),
    PrimaryDark = Color3.fromRGB(200, 100, 0),
    PrimaryLight = Color3.fromRGB(255, 180, 50),
    Accent = Color3.fromRGB(255, 200, 80),
    Background = Color3.fromRGB(25, 25, 30),
    BackgroundSecondary = Color3.fromRGB(35, 35, 42),
    BackgroundTertiary = Color3.fromRGB(45, 45, 55),
    Surface = Color3.fromRGB(40, 40, 50),
    SurfaceHover = Color3.fromRGB(55, 55, 68),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 190),
    TextMuted = Color3.fromRGB(120, 120, 135),
    Border = Color3.fromRGB(60, 60, 75),
    Success = Color3.fromRGB(80, 200, 120),
    Error = Color3.fromRGB(255, 80, 80),
    Warning = Color3.fromRGB(255, 200, 50),
    Shadow = Color3.fromRGB(0, 0, 0),
    TracerColor = Color3.fromRGB(255, 140, 0),
    SelectionGlow = Color3.fromRGB(255, 160, 30),
    Font = Enum.Font.GothamBold,
    FontMedium = Enum.Font.GothamMedium,
    FontRegular = Enum.Font.Gotham,
    CornerRadius = UDim.new(0, 8),
    CornerRadiusSmall = UDim.new(0, 5),
    CornerRadiusLarge = UDim.new(0, 12),
}

-- ============================================
-- STATE
-- ============================================
local State = {
    IsOpen = true,
    CurrentTab = "Browse",
    SelectedObject = nil,
    SelectionMode = false,
    PlacementMode = false,
    PlacingObject = nil,
    PlacingClone = nil,
    PublishedAssets = {},
    SearchQuery = "",
    CategoryFilter = "All",
    HoveredObject = nil,
    DragStart = nil,
    DragOffset = nil,
    IsDragging = false,
    Minimized = false,
    TracerEnabled = true,
    HoverEnabled = true,
    GridSnap = 1,
    RotationSnap = 15,
    CurrentRotation = 0,
    Notifications = {},
    PlacedCount = 0,
    HeightOffset = 0,
}

-- ============================================
-- UTILITY
-- ============================================
local Util = {}

function Util.Create(className, properties, children)
    local inst = Instance.new(className)
    if properties then
        for prop, val in pairs(properties) do
            if prop ~= "Parent" then
                pcall(function()
                    inst[prop] = val
                end)
            end
        end
        if properties.Parent then
            inst.Parent = properties.Parent
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    return inst
end

function Util.AddCorner(parent, radius)
    return Util.Create("UICorner", {
        CornerRadius = radius or Theme.CornerRadius,
        Parent = parent,
    })
end

function Util.AddStroke(parent, color, thickness, transp)
    return Util.Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transp or 0,
        Parent = parent,
    })
end

function Util.AddPadding(parent, top, right, bottom, left)
    return Util.Create("UIPadding", {
        PaddingTop = UDim.new(0, top or 8),
        PaddingRight = UDim.new(0, right or 8),
        PaddingBottom = UDim.new(0, bottom or 8),
        PaddingLeft = UDim.new(0, left or 8),
        Parent = parent,
    })
end

function Util.AddGradient(parent, colors, rotation)
    local colorSeq
    if typeof(colors) == "ColorSequence" then
        colorSeq = colors
    elseif type(colors) == "table" then
        local keypoints = {}
        for i, c in ipairs(colors) do
            table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), c))
        end
        colorSeq = ColorSequence.new(keypoints)
    end
    return Util.Create("UIGradient", {
        Color = colorSeq,
        Rotation = rotation or 90,
        Parent = parent,
    })
end

function Util.AddShadow(parent, size, transp)
    return Util.Create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.new(1, size or 30, 1, size or 30),
        ZIndex = parent.ZIndex - 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Theme.Shadow,
        ImageTransparency = transp or 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Parent = parent,
    })
end

function Util.Tween(object, properties, duration, easingStyle, easingDirection)
    if not object or not object.Parent then
        return nil
    end
    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.3,
            easingStyle or Enum.EasingStyle.Quart,
            easingDirection or Enum.EasingDirection.Out
        ),
        properties
    )
    tween:Play()
    return tween
end

function Util.GetBoundingBox(object)
    if not object or not object.Parent then
        return nil, nil
    end
    if object:IsA("Model") then
        local success, cf, size = pcall(function()
            return object:GetBoundingBox()
        end)
        if success then
            return cf, size
        end
        return nil, nil
    elseif object:IsA("BasePart") then
        return object.CFrame, object.Size
    end
    return nil, nil
end

function Util.GetObjectCategory(object)
    if object:IsA("Model") then
        if object:FindFirstChildWhichIsA("Humanoid") then
            return "Characters"
        end
        return "Models"
    elseif object:IsA("BasePart") then
        return "Parts"
    elseif object:IsA("Tool") then
        return "Tools"
    elseif object:IsA("Sound") then
        return "Audio"
    elseif object:IsA("Decal") or object:IsA("Texture") then
        return "Decals"
    elseif object:IsA("Light") then
        return "Lighting"
    elseif object:IsA("ParticleEmitter") or object:IsA("Fire") or object:IsA("Smoke") or object:IsA("Sparkles") then
        return "Effects"
    elseif object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript") then
        return "Scripts"
    elseif object:IsA("Folder") then
        return "Folders"
    end
    return "Other"
end

function Util.GetObjectIcon(object)
    if object:IsA("Model") then
        if object:FindFirstChildWhichIsA("Humanoid") then
            return "[\xF0\x9F\x91\xA4]"
        end
        return "[Box]"
    elseif object:IsA("SpawnLocation") then
        return "[Flag]"
    elseif object:IsA("MeshPart") then
        return "[Mesh]"
    elseif object:IsA("UnionOperation") then
        return "[Union]"
    elseif object:IsA("WedgePart") then
        return "[Wedge]"
    elseif object:IsA("Part") then
        return "[Part]"
    elseif object:IsA("BasePart") then
        return "[Base]"
    elseif object:IsA("Tool") then
        return "[Tool]"
    elseif object:IsA("Sound") then
        return "[Sound]"
    elseif object:IsA("Decal") then
        return "[Decal]"
    elseif object:IsA("PointLight") or object:IsA("SpotLight") or object:IsA("SurfaceLight") then
        return "[Light]"
    elseif object:IsA("Fire") then
        return "[Fire]"
    elseif object:IsA("Smoke") then
        return "[Smoke]"
    elseif object:IsA("Sparkles") or object:IsA("ParticleEmitter") then
        return "[FX]"
    elseif object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript") then
        return "[Script]"
    elseif object:IsA("Folder") then
        return "[Folder]"
    elseif object:IsA("Camera") then
        return "[Cam]"
    end
    return "[Obj]"
end

function Util.DeepClone(object)
    local success, clone = pcall(function()
        return object:Clone()
    end)
    if success and clone then
        return clone
    end
    return nil
end

function Util.GetDescendantCount(object)
    local success, count = pcall(function()
        return #object:GetDescendants()
    end)
    return success and count or 0
end

function Util.FormatNumber(n)
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    end
    return tostring(n)
end

function Util.Truncate(str, maxLen)
    if #str > maxLen then
        return str:sub(1, maxLen - 3) .. "..."
    end
    return str
end

-- ============================================
-- MAIN GUI
-- ============================================
local ScreenGui = Util.Create("ScreenGui", {
    Name = "MoonMarketplace",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
    Parent = CoreGui,
})

-- ============================================
-- NOTIFICATION SYSTEM
-- ============================================
local NotificationHolder = Util.Create("Frame", {
    Name = "NotificationHolder",
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -320, 0, 10),
    Size = UDim2.new(0, 300, 1, -20),
    Parent = ScreenGui,
})

Util.Create("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    Parent = NotificationHolder,
})

local function Notify(title, message, notifType, duration)
    local colors = {
        success = Theme.Success,
        error = Theme.Error,
        warning = Theme.Warning,
        info = Theme.Primary,
    }
    local accentColor = colors[notifType or "info"] or Theme.Primary

    local notif = Util.Create("Frame", {
        Name = "Notification",
        BackgroundColor3 = Theme.BackgroundSecondary,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Parent = NotificationHolder,
    })
    Util.AddCorner(notif, Theme.CornerRadiusSmall)
    Util.AddStroke(notif, accentColor, 1, 0.5)

    Util.Create("Frame", {
        BackgroundColor3 = accentColor,
        Size = UDim2.new(0, 4, 1, 0),
        BorderSizePixel = 0,
        Parent = notif,
    })

    Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 8),
        Size = UDim2.new(1, -50, 0, 18),
        Font = Theme.Font,
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })

    Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 28),
        Size = UDim2.new(1, -24, 0, 30),
        Font = Theme.FontRegular,
        Text = message,
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = notif,
    })

    local closeBtn = Util.Create("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -25, 0, 5),
        Size = UDim2.new(0, 20, 0, 20),
        Font = Theme.FontRegular,
        Text = "X",
        TextColor3 = Theme.TextMuted,
        TextSize = 12,
        Parent = notif,
    })

    local progressBg = Util.Create("Frame", {
        BackgroundColor3 = Theme.BackgroundTertiary,
        Position = UDim2.new(0, 4, 1, -3),
        Size = UDim2.new(1, -4, 0, 3),
        BorderSizePixel = 0,
        Parent = notif,
    })

    local progressFill = Util.Create("Frame", {
        BackgroundColor3 = accentColor,
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        Parent = progressBg,
    })

    Util.Tween(notif, {Size = UDim2.new(1, 0, 0, 65)}, 0.3, Enum.EasingStyle.Back)

    local dur = duration or 4
    Util.Tween(progressFill, {Size = UDim2.new(0, 0, 1, 0)}, dur, Enum.EasingStyle.Linear)

    local function dismiss()
        Util.Tween(notif, {Size = UDim2.new(1, 0, 0, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.35, function()
            if notif and notif.Parent then
                notif:Destroy()
            end
        end)
    end

    closeBtn.MouseButton1Click:Connect(dismiss)
    task.delay(dur, dismiss)
end

-- ============================================
-- SELECTION HIGHLIGHTS
-- ============================================
local SelectionBox = Util.Create("Highlight", {
    Name = "MoonSelection",
    FillColor = Theme.SelectionGlow,
    FillTransparency = 0.7,
    OutlineColor = Theme.Primary,
    OutlineTransparency = 0,
    DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
    Parent = ScreenGui,
})

local HoverBox = Util.Create("Highlight", {
    Name = "MoonHover",
    FillColor = Theme.Accent,
    FillTransparency = 0.85,
    OutlineColor = Theme.PrimaryLight,
    OutlineTransparency = 0.3,
    DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
    Parent = ScreenGui,
})

-- ============================================
-- TRACER SYSTEM
-- ============================================
local TracerFolder = Util.Create("Folder", {
    Name = "MoonTracers",
    Parent = ScreenGui,
})

local tracerFrame = Util.Create("Frame", {
    Name = "TracerLine",
    BackgroundColor3 = Theme.TracerColor,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 2, 0, 0),
    Visible = false,
    ZIndex = 100,
    Parent = TracerFolder,
})
Util.AddCorner(tracerFrame, UDim.new(0, 1))

local tracerDot = Util.Create("Frame", {
    Name = "TracerDot",
    BackgroundColor3 = Theme.Primary,
    Size = UDim2.new(0, 8, 0, 8),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Visible = false,
    ZIndex = 101,
    Parent = TracerFolder,
})
Util.AddCorner(tracerDot, UDim.new(1, 0))
Util.AddStroke(tracerDot, Theme.PrimaryLight, 1, 0)

local tracerGlow = Util.Create("Frame", {
    Name = "TracerGlow",
    BackgroundColor3 = Theme.Primary,
    BackgroundTransparency = 0.5,
    Size = UDim2.new(0, 16, 0, 16),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Visible = false,
    ZIndex = 100,
    Parent = TracerFolder,
})
Util.AddCorner(tracerGlow, UDim.new(1, 0))

local function UpdateTracer(target)
    if not State.TracerEnabled or not target then
        tracerFrame.Visible = false
        tracerDot.Visible = false
        tracerGlow.Visible = false
        return
    end

    local cf, _ = Util.GetBoundingBox(target)
    if not cf then
        tracerFrame.Visible = false
        tracerDot.Visible = false
        tracerGlow.Visible = false
        return
    end

    local screenPos, onScreen = Camera:WorldToViewportPoint(cf.Position)
    if not onScreen then
        tracerFrame.Visible = false
        tracerDot.Visible = false
        tracerGlow.Visible = false
        return
    end

    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local targetPos = Vector2.new(screenPos.X, screenPos.Y)
    local delta = targetPos - screenCenter
    local distance = delta.Magnitude
    local angle = math.atan2(delta.Y, delta.X)

    tracerFrame.Visible = true
    tracerDot.Visible = true
    tracerGlow.Visible = true

    tracerFrame.Position = UDim2.new(0, screenCenter.X, 0, screenCenter.Y)
    tracerFrame.Size = UDim2.new(0, 2, 0, distance)
    tracerFrame.Rotation = math.deg(angle) - 90

    tracerDot.Position = UDim2.new(0, targetPos.X, 0, targetPos.Y)
    tracerGlow.Position = UDim2.new(0, targetPos.X, 0, targetPos.Y)

    local pulse = (math.sin(tick() * 4) + 1) / 2
    tracerGlow.BackgroundTransparency = 0.4 + pulse * 0.4
    tracerGlow.Size = UDim2.new(0, 14 + pulse * 6, 0, 14 + pulse * 6)
end

-- ============================================
-- MAIN WINDOW
-- ============================================
local MainFrame = Util.Create("Frame", {
    Name = "MainFrame",
    BackgroundColor3 = Theme.Background,
    Position = UDim2.new(0.5, -300, 0.5, -230),
    Size = UDim2.new(0, 600, 0, 460),
    ClipsDescendants = false,
    Parent = ScreenGui,
})
Util.AddCorner(MainFrame, Theme.CornerRadiusLarge)
Util.AddStroke(MainFrame, Theme.Border, 1, 0.3)
Util.AddShadow(MainFrame, 50, 0.4)

-- Title Bar
local TitleBar = Util.Create("Frame", {
    Name = "TitleBar",
    BackgroundColor3 = Theme.BackgroundSecondary,
    Size = UDim2.new(1, 0, 0, 42),
    BorderSizePixel = 0,
    Parent = MainFrame,
})
Util.AddCorner(TitleBar, Theme.CornerRadiusLarge)

Util.Create("Frame", {
    BackgroundColor3 = Theme.BackgroundSecondary,
    Position = UDim2.new(0, 0, 1, -12),
    Size = UDim2.new(1, 0, 0, 12),
    BorderSizePixel = 0,
    Parent = TitleBar,
})

local titleAccent = Util.Create("Frame", {
    BackgroundColor3 = Theme.Primary,
    Size = UDim2.new(1, 0, 0, 2),
    Position = UDim2.new(0, 0, 1, 0),
    BorderSizePixel = 0,
    Parent = TitleBar,
})
Util.AddGradient(titleAccent, {Theme.Primary, Theme.Accent, Theme.PrimaryDark}, 0)

local TitleIcon = Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(0, 32, 1, 0),
    Font = Theme.Font,
    Text = "M",
    TextColor3 = Theme.Primary,
    TextSize = 22,
    Parent = TitleBar,
})

Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 42, 0, 0),
    Size = UDim2.new(0, 200, 1, 0),
    Font = Theme.Font,
    Text = "Moon Marketplace",
    TextColor3 = Theme.TextPrimary,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = TitleBar,
})

Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 195, 0, 2),
    Size = UDim2.new(0, 40, 1, -2),
    Font = Theme.FontRegular,
    Text = "v1.0",
    TextColor3 = Theme.Primary,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    Parent = TitleBar,
})

-- Window buttons
local function CreateWindowButton(name, text, position, color, hoverColor)
    local btn = Util.Create("TextButton", {
        Name = name,
        BackgroundColor3 = color or Theme.BackgroundTertiary,
        Position = position,
        Size = UDim2.new(0, 28, 0, 28),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Theme.FontRegular,
        Text = text,
        TextColor3 = Theme.TextSecondary,
        TextSize = 14,
        AutoButtonColor = false,
        Parent = TitleBar,
    })
    Util.AddCorner(btn, Theme.CornerRadiusSmall)
    btn.MouseEnter:Connect(function()
        Util.Tween(btn, {BackgroundColor3 = hoverColor or Theme.SurfaceHover}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Util.Tween(btn, {BackgroundColor3 = color or Theme.BackgroundTertiary}, 0.15)
    end)
    return btn
end

local MinimizeBtn = CreateWindowButton("Minimize", "-", UDim2.new(1, -100, 0.5, 0), nil, nil)
local CloseBtn = CreateWindowButton("Close", "X", UDim2.new(1, -32, 0.5, 0), Theme.BackgroundTertiary, Theme.Error)

-- Dragging
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        State.IsDragging = true
        State.DragStart = input.Position
        State.DragOffset = Vector2.new(
            MainFrame.Position.X.Offset - input.Position.X,
            MainFrame.Position.Y.Offset - input.Position.Y
        )
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if State.IsDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        MainFrame.Position = UDim2.new(
            MainFrame.Position.X.Scale,
            input.Position.X + State.DragOffset.X,
            MainFrame.Position.Y.Scale,
            input.Position.Y + State.DragOffset.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        State.IsDragging = false
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    Util.Tween(MainFrame, {Size = UDim2.new(0, 600, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.delay(0.35, function()
        State.IsOpen = false
        if ScreenGui and ScreenGui.Parent then
            ScreenGui:Destroy()
        end
    end)
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    State.Minimized = not State.Minimized
    if State.Minimized then
        Util.Tween(MainFrame, {Size = UDim2.new(0, 600, 0, 44)}, 0.3, Enum.EasingStyle.Quart)
        MinimizeBtn.Text = "+"
    else
        Util.Tween(MainFrame, {Size = UDim2.new(0, 600, 0, 460)}, 0.3, Enum.EasingStyle.Quart)
        MinimizeBtn.Text = "-"
    end
end)

-- ============================================
-- CONTENT AREA
-- ============================================
local ContentArea = Util.Create("Frame", {
    Name = "ContentArea",
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 44),
    Size = UDim2.new(1, 0, 1, -44),
    ClipsDescendants = true,
    Parent = MainFrame,
})

-- ============================================
-- SIDEBAR
-- ============================================
local Sidebar = Util.Create("Frame", {
    Name = "Sidebar",
    BackgroundColor3 = Theme.BackgroundSecondary,
    Size = UDim2.new(0, 55, 1, 0),
    BorderSizePixel = 0,
    Parent = ContentArea,
})

Util.Create("Frame", {
    BackgroundColor3 = Theme.Border,
    Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.new(0, 1, 1, 0),
    BorderSizePixel = 0,
    Parent = Sidebar,
})

Util.Create("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Parent = Sidebar,
})

Util.Create("UIPadding", {
    PaddingTop = UDim.new(0, 8),
    Parent = Sidebar,
})

local TabButtons = {}
local Tabs = {
    {Name = "Browse", Icon = "B", Tooltip = "Browse Assets"},
    {Name = "Select", Icon = "S", Tooltip = "Select from Game"},
    {Name = "Published", Icon = "P", Tooltip = "Published Assets"},
    {Name = "Place", Icon = "L", Tooltip = "Place Assets"},
    {Name = "Settings", Icon = "G", Tooltip = "Settings"},
}

local TabIndicator = Util.Create("Frame", {
    Name = "TabIndicator",
    BackgroundColor3 = Theme.Primary,
    Size = UDim2.new(0, 3, 0, 30),
    Position = UDim2.new(0, 0, 0, 12),
    BorderSizePixel = 0,
    ZIndex = 5,
    Parent = Sidebar,
})
Util.AddCorner(TabIndicator, UDim.new(0, 2))
TabIndicator.LayoutOrder = -1

local TabPages = {}

for i, tab in ipairs(Tabs) do
    local tabBtn = Util.Create("TextButton", {
        Name = tab.Name .. "Tab",
        BackgroundColor3 = Theme.BackgroundSecondary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 0, 42),
        Font = Theme.Font,
        Text = tab.Icon,
        TextColor3 = Theme.Primary,
        TextSize = 18,
        AutoButtonColor = false,
        LayoutOrder = i,
        Parent = Sidebar,
    })
    Util.AddCorner(tabBtn, Theme.CornerRadiusSmall)

    local tooltip = Util.Create("TextLabel", {
        BackgroundColor3 = Theme.Surface,
        Position = UDim2.new(1, 8, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 0, 0, 26),
        Font = Theme.FontMedium,
        Text = "  " .. tab.Tooltip .. "  ",
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        AutomaticSize = Enum.AutomaticSize.X,
        Visible = false,
        ZIndex = 200,
        Parent = tabBtn,
    })
    Util.AddCorner(tooltip, Theme.CornerRadiusSmall)
    Util.AddStroke(tooltip, Theme.Primary, 1, 0.5)

    tabBtn.MouseEnter:Connect(function()
        if State.CurrentTab ~= tab.Name then
            Util.Tween(tabBtn, {BackgroundTransparency = 0.5, BackgroundColor3 = Theme.SurfaceHover}, 0.15)
        end
        tooltip.Visible = true
    end)

    tabBtn.MouseLeave:Connect(function()
        if State.CurrentTab ~= tab.Name then
            Util.Tween(tabBtn, {BackgroundTransparency = 1}, 0.15)
        end
        tooltip.Visible = false
    end)

    TabButtons[tab.Name] = tabBtn
end

-- ============================================
-- TAB PAGES
-- ============================================
local ContentFrame = Util.Create("Frame", {
    Name = "ContentFrame",
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 56, 0, 0),
    Size = UDim2.new(1, -56, 1, 0),
    ClipsDescendants = true,
    Parent = ContentArea,
})

local function CreateTabPage(name)
    local page = Util.Create("Frame", {
        Name = name .. "Page",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = name == "Browse",
        Parent = ContentFrame,
    })
    TabPages[name] = page
    return page
end

local function SwitchTab(tabName)
    State.CurrentTab = tabName
    for name, page in pairs(TabPages) do
        page.Visible = (name == tabName)
    end
    for name, btn in pairs(TabButtons) do
        if name == tabName then
            Util.Tween(btn, {BackgroundTransparency = 0, BackgroundColor3 = Theme.Surface}, 0.2)
        else
            Util.Tween(btn, {BackgroundTransparency = 1}, 0.2)
        end
    end
    local idx = 0
    for i, t in ipairs(Tabs) do
        if t.Name == tabName then
            idx = i
            break
        end
    end
    local yPos = 8 + (idx - 1) * (42 + 4) + 6
    Util.Tween(TabIndicator, {Position = UDim2.new(0, 0, 0, yPos)}, 0.3, Enum.EasingStyle.Back)
end

for _, tab in ipairs(Tabs) do
    TabButtons[tab.Name].MouseButton1Click:Connect(function()
        SwitchTab(tab.Name)
    end)
end

-- ============================================
-- BROWSE TAB
-- ============================================
local BrowsePage = CreateTabPage("Browse")

local browseHeader = Util.Create("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 80),
    Parent = BrowsePage,
})

Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 8),
    Size = UDim2.new(1, -24, 0, 24),
    Font = Theme.Font,
    Text = "Moon - Browse Workspace",
    TextColor3 = Theme.TextPrimary,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = browseHeader,
})

Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 30),
    Size = UDim2.new(1, -24, 0, 16),
    Font = Theme.FontRegular,
    Text = "Explore all objects in the game workspace",
    TextColor3 = Theme.TextMuted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = browseHeader,
})

local searchBar = Util.Create("Frame", {
    BackgroundColor3 = Theme.Surface,
    Position = UDim2.new(0, 12, 0, 50),
    Size = UDim2.new(1, -24, 0, 30),
    Parent = browseHeader,
})
Util.AddCorner(searchBar, Theme.CornerRadiusSmall)
local searchStroke = Util.AddStroke(searchBar, Theme.Border, 1, 0.5)

Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 0, 0),
    Size = UDim2.new(0, 24, 1, 0),
    Font = Theme.FontRegular,
    Text = ">",
    TextColor3 = Theme.Primary,
    TextSize = 14,
    Parent = searchBar,
})

local searchInput = Util.Create("TextBox", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 34, 0, 0),
    Size = UDim2.new(1, -44, 1, 0),
    Font = Theme.FontRegular,
    PlaceholderText = "Search objects...",
    PlaceholderColor3 = Theme.TextMuted,
    Text = "",
    TextColor3 = Theme.TextPrimary,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    Parent = searchBar,
})

searchInput.Focused:Connect(function()
    Util.Tween(searchStroke, {Color = Theme.Primary}, 0.2)
end)

searchInput.FocusLost:Connect(function()
    Util.Tween(searchStroke, {Color = Theme.Border}, 0.2)
end)

-- Category Bar
local categoryBar = Util.Create("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 80),
    Size = UDim2.new(1, 0, 0, 32),
    Parent = BrowsePage,
})

local categoryScroll = Util.Create("ScrollingFrame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    ScrollBarThickness = 0,
    ScrollingDirection = Enum.ScrollingDirection.X,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.X,
    Parent = categoryBar,
})

Util.Create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = categoryScroll,
})

Util.Create("UIPadding", {
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12),
    Parent = categoryScroll,
})

local Categories = {"All", "Models", "Parts", "Characters", "Tools", "Audio", "Decals", "Effects", "Lighting", "Scripts", "Folders", "Other"}
local CategoryButtons = {}

for i, cat in ipairs(Categories) do
    local catBtn = Util.Create("TextButton", {
        Name = cat,
        BackgroundColor3 = (cat == "All") and Theme.Primary or Theme.Surface,
        Size = UDim2.new(0, 0, 0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Theme.FontMedium,
        Text = "  " .. cat .. "  ",
        TextColor3 = (cat == "All") and Theme.Background or Theme.TextSecondary,
        TextSize = 11,
        AutoButtonColor = false,
        LayoutOrder = i,
        Parent = categoryScroll,
    })
    Util.AddCorner(catBtn, UDim.new(0, 12))
    CategoryButtons[cat] = catBtn
end

-- Browse List
local browseListFrame = Util.Create("ScrollingFrame", {
    Name = "BrowseList",
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 116),
    Size = UDim2.new(1, 0, 1, -116),
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Theme.Primary,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent = BrowsePage,
})

Util.Create("UIListLayout", {
    Padding = UDim.new(0, 3),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = browseListFrame,
})

Util.Create("UIPadding", {
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    PaddingTop = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 8),
    Parent = browseListFrame,
})

-- Forward declarations
local RefreshBrowseList
local RefreshPublishedList

local function CreateBrowseItem(object, layoutOrder)
    local category = Util.GetObjectCategory(object)
    local icon = Util.GetObjectIcon(object)
    local descCount = Util.GetDescendantCount(object)

    local item = Util.Create("Frame", {
        Name = "Item_" .. object.Name,
        BackgroundColor3 = Theme.Surface,
        Size = UDim2.new(1, 0, 0, 48),
        LayoutOrder = layoutOrder or 0,
        Parent = browseListFrame,
    })
    Util.AddCorner(item, Theme.CornerRadiusSmall)

    Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0, 30, 1, 0),
        Font = Theme.FontRegular,
        Text = icon,
        TextColor3 = Theme.Primary,
        TextSize = 11,
        Parent = item,
    })

    Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0, 6),
        Size = UDim2.new(1, -160, 0, 18),
        Font = Theme.FontMedium,
        Text = Util.Truncate(object.Name, 30),
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = item,
    })

    Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0, 24),
        Size = UDim2.new(1, -160, 0, 16),
        Font = Theme.FontRegular,
        Text = category .. " | " .. object.ClassName .. " | " .. Util.FormatNumber(descCount) .. " children",
        TextColor3 = Theme.TextMuted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = item,
    })

    local publishBtn = Util.Create("TextButton", {
        Name = "PublishBtn",
        BackgroundColor3 = Theme.Primary,
        Position = UDim2.new(1, -110, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 65, 0, 26),
        Font = Theme.FontMedium,
        Text = "Publish",
        TextColor3 = Theme.Background,
        TextSize = 11,
        AutoButtonColor = false,
        Parent = item,
    })
    Util.AddCorner(publishBtn, Theme.CornerRadiusSmall)

    publishBtn.MouseEnter:Connect(function()
        Util.Tween(publishBtn, {BackgroundColor3 = Theme.PrimaryLight}, 0.15)
    end)
    publishBtn.MouseLeave:Connect(function()
        Util.Tween(publishBtn, {BackgroundColor3 = Theme.Primary}, 0.15)
    end)

    publishBtn.MouseButton1Click:Connect(function()
        local assetData = {
            Name = object.Name,
            ClassName = object.ClassName,
            Category = category,
            Icon = icon,
            Object = object,
            DescendantCount = descCount,
            PublishedAt = os.time(),
            Publisher = LocalPlayer.Name,
        }
        table.insert(State.PublishedAssets, assetData)
        RefreshPublishedList()
        Notify("Asset Published", object.Name .. " has been published to Moon Marketplace!", "success", 3)
        publishBtn.Text = "Done!"
        Util.Tween(publishBtn, {BackgroundColor3 = Theme.Success}, 0.2)
        task.delay(1.5, function()
            if publishBtn and publishBtn.Parent then
                publishBtn.Text = "Publish"
                Util.Tween(publishBtn, {BackgroundColor3 = Theme.Primary}, 0.2)
            end
        end)
    end)

    local focusBtn = Util.Create("TextButton", {
        Name = "FocusBtn",
        BackgroundColor3 = Theme.BackgroundTertiary,
        Position = UDim2.new(1, -40, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 30, 0, 26),
        Font = Theme.FontRegular,
        Text = "Eye",
        TextColor3 = Theme.TextSecondary,
        TextSize = 9,
        AutoButtonColor = false,
        Parent = item,
    })
    Util.AddCorner(focusBtn, Theme.CornerRadiusSmall)

    focusBtn.MouseEnter:Connect(function()
        Util.Tween(focusBtn, {BackgroundColor3 = Theme.SurfaceHover}, 0.15)
    end)
    focusBtn.MouseLeave:Connect(function()
        Util.Tween(focusBtn, {BackgroundColor3 = Theme.BackgroundTertiary}, 0.15)
    end)

    focusBtn.MouseButton1Click:Connect(function()
        State.SelectedObject = object
        SelectionBox.Adornee = object
        if object:IsA("BasePart") or object:IsA("Model") then
            local cf = Util.GetBoundingBox(object)
            if cf then
                Util.Tween(Camera, {CFrame = cf * CFrame.new(0, 10, 20)}, 0.5)
            end
        end
        Notify("Object Selected", object.Name .. " is now selected", "info", 2)
    end)

    item.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Util.Tween(item, {BackgroundColor3 = Theme.SurfaceHover}, 0.15)
            if (object:IsA("BasePart") or object:IsA("Model")) and State.HoverEnabled then
                HoverBox.Adornee = object
            end
        end
    end)

    item.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Util.Tween(item, {BackgroundColor3 = Theme.Surface}, 0.15)
            HoverBox.Adornee = nil
        end
    end)

    return item
end

RefreshBrowseList = function()
    for _, child in ipairs(browseListFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local search = searchInput.Text:lower()
    local order = 0

    local function addObjects(parent)
        local success, children = pcall(function()
            return parent:GetChildren()
        end)
        if not success then
            return
        end
        for _, obj in ipairs(children) do
            if obj.Name == "MoonTracer" or obj.Name == "MoonTracers" or obj.Name == "MoonMarketplace" then
                continue
            end
            if obj == Camera then
                continue
            end
            pcall(function()
                if obj:IsA("Terrain") then
                    return
                end
            end)

            local category = Util.GetObjectCategory(obj)
            local matchCategory = State.CategoryFilter == "All" or category == State.CategoryFilter
            local matchSearch = search == "" or obj.Name:lower():find(search, 1, true) or obj.ClassName:lower():find(search, 1, true)

            if matchCategory and matchSearch then
                order = order + 1
                CreateBrowseItem(obj, order)
            end
        end
    end

    addObjects(workspace)

    pcall(function()
        addObjects(game:GetService("ReplicatedStorage"))
    end)

    pcall(function()
        addObjects(game:GetService("Lighting"))
    end)

    if order == 0 then
        Util.Create("TextLabel", {
            Name = "EmptyLabel",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 100),
            Font = Theme.FontRegular,
            Text = "Moon\nNo objects found",
            TextColor3 = Theme.TextMuted,
            TextSize = 14,
            Parent = browseListFrame,
        })
    end
end

-- Category button connections
for _, cat in ipairs(Categories) do
    local catBtn = CategoryButtons[cat]
    catBtn.MouseButton1Click:Connect(function()
        State.CategoryFilter = cat
        for c, b in pairs(CategoryButtons) do
            if c == cat then
                Util.Tween(b, {BackgroundColor3 = Theme.Primary, TextColor3 = Theme.Background}, 0.2)
            else
                Util.Tween(b, {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.TextSecondary}, 0.2)
            end
        end
        RefreshBrowseList()
    end)

    catBtn.MouseEnter:Connect(function()
        if State.CategoryFilter ~= cat then
            Util.Tween(catBtn, {BackgroundColor3 = Theme.SurfaceHover}, 0.15)
        end
    end)

    catBtn.MouseLeave:Connect(function()
        if State.CategoryFilter ~= cat then
            Util.Tween(catBtn, {BackgroundColor3 = Theme.Surface}, 0.15)
        end
    end)
end

searchInput:GetPropertyChangedSignal("Text"):Connect(function()
    State.SearchQuery = searchInput.Text
    RefreshBrowseList()
end)

-- ============================================
-- SELECT TAB
-- ============================================
local SelectPage = CreateTabPage("Select")

Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 8),
    Size = UDim2.new(1, -24, 0, 24),
    Font = Theme.Font,
    Text = "Interactive Selection",
    TextColor3 = Theme.TextPrimary,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = SelectPage,
})

Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 32),
    Size = UDim2.new(1, -24, 0, 32),
    Font = Theme.FontRegular,
    Text = "Click on any object in the 3D world to select it. An orange tracer will mark your selection.",
    TextColor3 = Theme.TextMuted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextWrapped = true,
    Parent = SelectPage,
})

local selectModeBtn = Util.Create("TextButton", {
    BackgroundColor3 = Theme.Surface,
    Position = UDim2.new(0, 12, 0, 72),
    Size = UDim2.new(1, -24, 0, 44),
    Font = Theme.FontMedium,
    Text = "",
    AutoButtonColor = false,
    Parent = SelectPage,
})
Util.AddCorner(selectModeBtn, Theme.CornerRadius)
local selectModeStroke = Util.AddStroke(selectModeBtn, Theme.Border, 1, 0.5)

local selectModeDot = Util.Create("Frame", {
    BackgroundColor3 = Theme.Error,
    Position = UDim2.new(0, 12, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    Size = UDim2.new(0, 12, 0, 12),
    Parent = selectModeBtn,
})
Util.AddCorner(selectModeDot, UDim.new(1, 0))

local selectModeLabel = Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 32, 0, 0),
    Size = UDim2.new(1, -44, 1, 0),
    Font = Theme.FontMedium,
    Text = "Selection Mode: OFF - Click to Enable",
    TextColor3 = Theme.TextSecondary,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = selectModeBtn,
})

selectModeBtn.MouseButton1Click:Connect(function()
    State.SelectionMode = not State.SelectionMode
    if State.SelectionMode then
        selectModeLabel.Text = "Selection Mode: ON - Click objects in game"
        Util.Tween(selectModeDot, {BackgroundColor3 = Theme.Success}, 0.2)
        Util.Tween(selectModeBtn, {BackgroundColor3 = Color3.fromRGB(35, 50, 40)}, 0.2)
        selectModeStroke.Color = Theme.Success
        Notify("Selection Mode", "Click on any object in the game world to select it!", "info", 3)
    else
        selectModeLabel.Text = "Selection Mode: OFF - Click to Enable"
        Util.Tween(selectModeDot, {BackgroundColor3 = Theme.Error}, 0.2)
        Util.Tween(selectModeBtn, {BackgroundColor3 = Theme.Surface}, 0.2)
        selectModeStroke.Color = Theme.Border
        HoverBox.Adornee = nil
    end
end)

-- Selection info panel
local selectionInfoFrame = Util.Create("Frame", {
    Name = "SelectionInfo",
    BackgroundColor3 = Theme.Surface,
    Position = UDim2.new(0, 12, 0, 126),
    Size = UDim2.new(1, -24, 0, 200),
    Visible = false,
    Parent = SelectPage,
})
Util.AddCorner(selectionInfoFrame, Theme.CornerRadius)
Util.AddStroke(selectionInfoFrame, Theme.Primary, 1, 0.5)

Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 8),
    Size = UDim2.new(1, -24, 0, 20),
    Font = Theme.Font,
    Text = "Selected Object",
    TextColor3 = Theme.Primary,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = selectionInfoFrame,
})

local selInfoName = Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 30),
    Size = UDim2.new(1, -24, 0, 18),
    Font = Theme.FontMedium,
    Text = "",
    TextColor3 = Theme.TextPrimary,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = selectionInfoFrame,
})

local selInfoClass = Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 50),
    Size = UDim2.new(1, -24, 0, 14),
    Font = Theme.FontRegular,
    Text = "",
    TextColor3 = Theme.TextMuted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = selectionInfoFrame,
})

local selInfoDetails = Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 68),
    Size = UDim2.new(1, -24, 0, 50),
    Font = Theme.FontRegular,
    Text = "",
    TextColor3 = Theme.TextSecondary,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextWrapped = true,
    Parent = selectionInfoFrame,
})

local selPublishBtn = Util.Create("TextButton", {
    BackgroundColor3 = Theme.Primary,
    Position = UDim2.new(0, 12, 1, -42),
    Size = UDim2.new(0.45, -16, 0, 32),
    Font = Theme.FontMedium,
    Text = "Publish",
    TextColor3 = Theme.Background,
    TextSize = 12,
    AutoButtonColor = false,
    Parent = selectionInfoFrame,
})
Util.AddCorner(selPublishBtn, Theme.CornerRadiusSmall)

selPublishBtn.MouseEnter:Connect(function()
    Util.Tween(selPublishBtn, {BackgroundColor3 = Theme.PrimaryLight}, 0.15)
end)
selPublishBtn.MouseLeave:Connect(function()
    Util.Tween(selPublishBtn, {BackgroundColor3 = Theme.Primary}, 0.15)
end)

local selPlaceBtn = Util.Create("TextButton", {
    BackgroundColor3 = Theme.Success,
    Position = UDim2.new(0.45, 4, 1, -42),
    Size = UDim2.new(0.55, -16, 0, 32),
    Font = Theme.FontMedium,
    Text = "Clone and Place",
    TextColor3 = Theme.Background,
    TextSize = 12,
    AutoButtonColor = false,
    Parent = selectionInfoFrame,
})
Util.AddCorner(selPlaceBtn, Theme.CornerRadiusSmall)

selPlaceBtn.MouseEnter:Connect(function()
    Util.Tween(selPlaceBtn, {BackgroundColor3 = Color3.fromRGB(100, 220, 140)}, 0.15)
end)
selPlaceBtn.MouseLeave:Connect(function()
    Util.Tween(selPlaceBtn, {BackgroundColor3 = Theme.Success}, 0.15)
end)

local function UpdateSelectionInfo(object)
    if not object then
        selectionInfoFrame.Visible = false
        return
    end
    selectionInfoFrame.Visible = true
    local icon = Util.GetObjectIcon(object)
    local category = Util.GetObjectCategory(object)
    local descCount = Util.GetDescendantCount(object)

    selInfoName.Text = icon .. " " .. object.Name
    selInfoClass.Text = "Class: " .. object.ClassName .. " | Category: " .. category

    local details = "Descendants: " .. descCount
    if object:IsA("BasePart") then
        details = details .. "\nSize: " .. tostring(object.Size)
        details = details .. "\nPosition: " .. string.format("(%.1f, %.1f, %.1f)", object.Position.X, object.Position.Y, object.Position.Z)
        details = details .. "\nMaterial: " .. tostring(object.Material)
    elseif object:IsA("Model") then
        local cf, size = Util.GetBoundingBox(object)
        if cf and size then
            details = details .. "\nBounding: " .. string.format("(%.1f, %.1f, %.1f)", size.X, size.Y, size.Z)
        end
    end
    selInfoDetails.Text = details
end

selPublishBtn.MouseButton1Click:Connect(function()
    if State.SelectedObject and State.SelectedObject.Parent then
        local obj = State.SelectedObject
        local assetData = {
            Name = obj.Name,
            ClassName = obj.ClassName,
            Category = Util.GetObjectCategory(obj),
            Icon = Util.GetObjectIcon(obj),
            Object = obj,
            DescendantCount = Util.GetDescendantCount(obj),
            PublishedAt = os.time(),
            Publisher = LocalPlayer.Name,
        }
        table.insert(State.PublishedAssets, assetData)
        RefreshPublishedList()
        Notify("Asset Published", obj.Name .. " published successfully!", "success", 3)
    end
end)

selPlaceBtn.MouseButton1Click:Connect(function()
    if State.SelectedObject and State.SelectedObject.Parent then
        local clone = Util.DeepClone(State.SelectedObject)
        if clone then
            State.PlacementMode = true
            State.PlacingClone = clone
            State.CurrentRotation = 0
            State.HeightOffset = 0
            SwitchTab("Place")
            Notify("Placement Mode", "Click in game to place. R = Rotate, X = Cancel", "info", 4)
        else
            Notify("Clone Failed", "Could not clone this object.", "error", 3)
        end
    end
end)

-- ============================================
-- PUBLISHED TAB
-- ============================================
local PublishedPage = CreateTabPage("Published")

Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 8),
    Size = UDim2.new(1, -24, 0, 24),
    Font = Theme.Font,
    Text = "Published Assets",
    TextColor3 = Theme.TextPrimary,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = PublishedPage,
})

local pubCount = Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 32),
    Size = UDim2.new(1, -24, 0, 16),
    Font = Theme.FontRegular,
    Text = "0 assets published",
    TextColor3 = Theme.TextMuted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = PublishedPage,
})

local clearAllBtn = Util.Create("TextButton", {
    BackgroundColor3 = Theme.Error,
    BackgroundTransparency = 0.8,
    Position = UDim2.new(1, -90, 0, 10),
    Size = UDim2.new(0, 78, 0, 26),
    Font = Theme.FontMedium,
    Text = "Clear All",
    TextColor3 = Theme.Error,
    TextSize = 10,
    AutoButtonColor = false,
    Parent = PublishedPage,
})
Util.AddCorner(clearAllBtn, Theme.CornerRadiusSmall)
Util.AddStroke(clearAllBtn, Theme.Error, 1, 0.5)

clearAllBtn.MouseButton1Click:Connect(function()
    State.PublishedAssets = {}
    RefreshPublishedList()
    Notify("Cleared", "All published assets have been removed.", "warning", 3)
end)

local pubListFrame = Util.Create("ScrollingFrame", {
    Name = "PubList",
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 56),
    Size = UDim2.new(1, 0, 1, -56),
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Theme.Primary,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent = PublishedPage,
})

Util.Create("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = pubListFrame,
})

Util.Create("UIPadding", {
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    PaddingTop = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 8),
    Parent = pubListFrame,
})

RefreshPublishedList = function()
    for _, child in ipairs(pubListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    pubCount.Text = #State.PublishedAssets .. " assets published"

    if #State.PublishedAssets == 0 then
        local empty = Util.Create("Frame", {
            Name = "Empty",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 120),
            Parent = pubListFrame,
        })
        Util.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Theme.FontRegular,
            Text = "Moon Marketplace\n\nNo assets published yet.\nBrowse or select objects to publish them!",
            TextColor3 = Theme.TextMuted,
            TextSize = 13,
            TextWrapped = true,
            Parent = empty,
        })
        return
    end

    for i, asset in ipairs(State.PublishedAssets) do
        local card = Util.Create("Frame", {
            Name = "Asset_" .. i,
            BackgroundColor3 = Theme.Surface,
            Size = UDim2.new(1, 0, 0, 70),
            LayoutOrder = i,
            Parent = pubListFrame,
        })
        Util.AddCorner(card, Theme.CornerRadius)
        Util.AddStroke(card, Theme.Border, 1, 0.7)

        Util.Create("Frame", {
            BackgroundColor3 = Theme.Primary,
            Size = UDim2.new(0, 4, 1, -8),
            Position = UDim2.new(0, 4, 0, 4),
            Parent = card,
        })

        Util.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 6),
            Size = UDim2.new(0, 40, 0, 30),
            Font = Theme.FontRegular,
            Text = asset.Icon,
            TextColor3 = Theme.Primary,
            TextSize = 11,
            Parent = card,
        })

        Util.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 48, 0, 8),
            Size = UDim2.new(1, -170, 0, 18),
            Font = Theme.FontMedium,
            Text = Util.Truncate(asset.Name, 25),
            TextColor3 = Theme.TextPrimary,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card,
        })

        Util.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 48, 0, 26),
            Size = UDim2.new(1, -170, 0, 14),
            Font = Theme.FontRegular,
            Text = asset.Category .. " | " .. asset.ClassName,
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card,
        })

        Util.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 48, 0, 40),
            Size = UDim2.new(1, -170, 0, 14),
            Font = Theme.FontRegular,
            Text = "By " .. asset.Publisher .. " | " .. Util.FormatNumber(asset.DescendantCount) .. " desc",
            TextColor3 = Theme.TextMuted,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card,
        })

        -- Place button
        local placeAssetBtn = Util.Create("TextButton", {
            BackgroundColor3 = Theme.Primary,
            Position = UDim2.new(1, -120, 0, 8),
            Size = UDim2.new(0, 50, 0, 24),
            Font = Theme.FontMedium,
            Text = "Place",
            TextColor3 = Theme.Background,
            TextSize = 11,
            AutoButtonColor = false,
            Parent = card,
        })
        Util.AddCorner(placeAssetBtn, Theme.CornerRadiusSmall)

        placeAssetBtn.MouseEnter:Connect(function()
            Util.Tween(placeAssetBtn, {BackgroundColor3 = Theme.PrimaryLight}, 0.15)
        end)
        placeAssetBtn.MouseLeave:Connect(function()
            Util.Tween(placeAssetBtn, {BackgroundColor3 = Theme.Primary}, 0.15)
        end)

        local capturedIndex = i
        placeAssetBtn.MouseButton1Click:Connect(function()
            local a = State.PublishedAssets[capturedIndex]
            if a and a.Object and a.Object.Parent then
                local clone = Util.DeepClone(a.Object)
                if clone then
                    State.PlacementMode = true
                    State.PlacingClone = clone
                    State.CurrentRotation = 0
                    State.HeightOffset = 0
                    SwitchTab("Place")
                    Notify("Placement Mode", "Click to place " .. a.Name .. ". R = Rotate, X = Cancel", "info", 4)
                else
                    Notify("Error", "Could not clone this asset.", "error", 3)
                end
            else
                Notify("Error", "Original object no longer exists.", "error", 3)
            end
        end)

        -- Focus
        local focusAssetBtn = Util.Create("TextButton", {
            BackgroundColor3 = Theme.BackgroundTertiary,
            Position = UDim2.new(1, -64, 0, 8),
            Size = UDim2.new(0, 24, 0, 24),
            Font = Theme.FontRegular,
            Text = "V",
            TextColor3 = Theme.TextSecondary,
            TextSize = 12,
            AutoButtonColor = false,
            Parent = card,
        })
        Util.AddCorner(focusAssetBtn, Theme.CornerRadiusSmall)

        focusAssetBtn.MouseButton1Click:Connect(function()
            local a = State.PublishedAssets[capturedIndex]
            if a and a.Object and a.Object.Parent then
                State.SelectedObject = a.Object
                SelectionBox.Adornee = a.Object
                local cf = Util.GetBoundingBox(a.Object)
                if cf then
                    Util.Tween(Camera, {CFrame = cf * CFrame.new(0, 10, 20)}, 0.5)
                end
            end
        end)

        -- Delete
        local deleteAssetBtn = Util.Create("TextButton", {
            BackgroundColor3 = Theme.BackgroundTertiary,
            Position = UDim2.new(1, -34, 0, 8),
            Size = UDim2.new(0, 24, 0, 24),
            Font = Theme.FontRegular,
            Text = "X",
            TextColor3 = Theme.Error,
            TextSize = 12,
            AutoButtonColor = false,
            Parent = card,
        })
        Util.AddCorner(deleteAssetBtn, Theme.CornerRadiusSmall)

        deleteAssetBtn.MouseButton1Click:Connect(function()
            table.remove(State.PublishedAssets, capturedIndex)
            RefreshPublishedList()
            Notify("Removed", "Asset removed from marketplace.", "warning", 2)
        end)

        -- Spawn button
        local spawnBtn = Util.Create("TextButton", {
            BackgroundColor3 = Theme.Warning,
            Position = UDim2.new(1, -120, 0, 38),
            Size = UDim2.new(0, 110, 0, 24),
            Font = Theme.FontMedium,
            Text = "Set Spawn",
            TextColor3 = Theme.Background,
            TextSize = 10,
            AutoButtonColor = false,
            Parent = card,
        })
        Util.AddCorner(spawnBtn, Theme.CornerRadiusSmall)

        spawnBtn.MouseButton1Click:Connect(function()
            local a = State.PublishedAssets[capturedIndex]
            if a and a.Object and a.Object.Parent then
                local cf = Util.GetBoundingBox(a.Object)
                if cf then
                    local spawn = Instance.new("SpawnLocation")
                    spawn.Name = "MoonSpawn_" .. a.Name
                    spawn.Size = Vector3.new(6, 1, 6)
                    spawn.Position = cf.Position + Vector3.new(0, -2, 0)
                    spawn.Anchored = true
                    spawn.BrickColor = BrickColor.new("Deep orange")
                    spawn.Material = Enum.Material.Neon
                    spawn.TopSurface = Enum.SurfaceType.Smooth
                    spawn.Parent = workspace

                    local billGui = Instance.new("BillboardGui")
                    billGui.Size = UDim2.new(0, 50, 0, 50)
                    billGui.StudsOffset = Vector3.new(0, 3, 0)
                    billGui.AlwaysOnTop = true
                    billGui.Parent = spawn

                    local moonLbl = Instance.new("TextLabel")
                    moonLbl.Size = UDim2.new(1, 0, 1, 0)
                    moonLbl.BackgroundTransparency = 1
                    moonLbl.Text = "Moon"
                    moonLbl.TextColor3 = Theme.Primary
                    moonLbl.TextSize = 16
                    moonLbl.Font = Enum.Font.GothamBold
                    moonLbl.Parent = billGui

                    Notify("Spawn Created", "Spawn location created near " .. a.Name, "success", 3)
                end
            end
        end)
    end
end

-- ============================================
-- PLACE TAB
-- ============================================
local PlacePage = CreateTabPage("Place")

Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 8),
    Size = UDim2.new(1, -24, 0, 24),
    Font = Theme.Font,
    Text = "Placement Mode",
    TextColor3 = Theme.TextPrimary,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = PlacePage,
})

Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 36),
    Size = UDim2.new(1, -24, 0, 60),
    Font = Theme.FontRegular,
    Text = "Controls:\n- Left Click: Place object\n- R: Rotate 15 degrees\n- X: Cancel placement\n- Scroll: Adjust height",
    TextColor3 = Theme.TextSecondary,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextWrapped = true,
    Parent = PlacePage,
})

local placeStatus = Util.Create("Frame", {
    BackgroundColor3 = Theme.Surface,
    Position = UDim2.new(0, 12, 0, 100),
    Size = UDim2.new(1, -24, 0, 60),
    Parent = PlacePage,
})
Util.AddCorner(placeStatus, Theme.CornerRadius)
Util.AddStroke(placeStatus, Theme.Border, 1, 0.5)

local placeStatusIcon = Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(0, 30, 1, 0),
    Font = Theme.FontRegular,
    Text = "...",
    TextColor3 = Theme.Primary,
    TextSize = 18,
    Parent = placeStatus,
})

local placeStatusText = Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 48, 0, 10),
    Size = UDim2.new(1, -60, 0, 18),
    Font = Theme.FontMedium,
    Text = "No object selected for placement",
    TextColor3 = Theme.TextSecondary,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = placeStatus,
})

local placeStatusDetail = Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 48, 0, 30),
    Size = UDim2.new(1, -60, 0, 16),
    Font = Theme.FontRegular,
    Text = "Select an asset from Browse or Published tabs",
    TextColor3 = Theme.TextMuted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = placeStatus,
})

local cancelPlaceBtn = Util.Create("TextButton", {
    BackgroundColor3 = Theme.Error,
    BackgroundTransparency = 0.7,
    Position = UDim2.new(0, 12, 0, 170),
    Size = UDim2.new(1, -24, 0, 36),
    Font = Theme.FontMedium,
    Text = "X Cancel Placement",
    TextColor3 = Theme.Error,
    TextSize = 12,
    AutoButtonColor = false,
    Visible = false,
    Parent = PlacePage,
})
Util.AddCorner(cancelPlaceBtn, Theme.CornerRadiusSmall)
Util.AddStroke(cancelPlaceBtn, Theme.Error, 1, 0.5)

cancelPlaceBtn.MouseButton1Click:Connect(function()
    if State.PlacingClone then
        State.PlacingClone:Destroy()
        State.PlacingClone = nil
    end
    State.PlacementMode = false
    cancelPlaceBtn.Visible = false
    placeStatusIcon.Text = "..."
    placeStatusText.Text = "No object selected for placement"
    placeStatusDetail.Text = "Select an asset from Browse or Published tabs"
    Notify("Cancelled", "Placement cancelled.", "warning", 2)
end)

local snapFrame = Util.Create("Frame", {
    BackgroundColor3 = Theme.Surface,
    Position = UDim2.new(0, 12, 0, 220),
    Size = UDim2.new(1, -24, 0, 50),
    Parent = PlacePage,
})
Util.AddCorner(snapFrame, Theme.CornerRadius)

local gridLabel = Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 4),
    Size = UDim2.new(0.5, -12, 0, 18),
    Font = Theme.FontMedium,
    Text = "Grid Snap: " .. State.GridSnap .. " studs",
    TextColor3 = Theme.TextSecondary,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Name = "GridLabel",
    Parent = snapFrame,
})

local rotLabel = Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 26),
    Size = UDim2.new(0.5, -12, 0, 18),
    Font = Theme.FontMedium,
    Text = "Rotation: " .. State.CurrentRotation .. " deg",
    TextColor3 = Theme.TextSecondary,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Name = "RotLabel",
    Parent = snapFrame,
})

local placedCountFrame = Util.Create("Frame", {
    BackgroundColor3 = Theme.Surface,
    Position = UDim2.new(0, 12, 0, 280),
    Size = UDim2.new(1, -24, 0, 40),
    Parent = PlacePage,
})
Util.AddCorner(placedCountFrame, Theme.CornerRadius)

local placedCountLabel = Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -24, 1, 0),
    Font = Theme.FontMedium,
    Text = "Moon | Objects placed this session: 0",
    TextColor3 = Theme.TextMuted,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = placedCountFrame,
})

-- ============================================
-- SETTINGS TAB
-- ============================================
local SettingsPage = CreateTabPage("Settings")

Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 8),
    Size = UDim2.new(1, -24, 0, 24),
    Font = Theme.Font,
    Text = "Settings",
    TextColor3 = Theme.TextPrimary,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = SettingsPage,
})

local function CreateToggle(parent, label, yPos, defaultVal, callback)
    local frame = Util.Create("Frame", {
        BackgroundColor3 = Theme.Surface,
        Position = UDim2.new(0, 12, 0, yPos),
        Size = UDim2.new(1, -24, 0, 40),
        Parent = parent,
    })
    Util.AddCorner(frame, Theme.CornerRadiusSmall)

    Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Font = Theme.FontMedium,
        Text = label,
        TextColor3 = Theme.TextSecondary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    local toggleBg = Util.Create("Frame", {
        BackgroundColor3 = defaultVal and Theme.Primary or Theme.BackgroundTertiary,
        Position = UDim2.new(1, -52, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 40, 0, 22),
        Parent = frame,
    })
    Util.AddCorner(toggleBg, UDim.new(1, 0))

    local toggleDot = Util.Create("Frame", {
        BackgroundColor3 = Theme.TextPrimary,
        Position = defaultVal and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 18, 0, 18),
        Parent = toggleBg,
    })
    Util.AddCorner(toggleDot, UDim.new(1, 0))

    local toggleState = defaultVal

    local toggleBtn = Util.Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        Parent = frame,
    })

    toggleBtn.MouseButton1Click:Connect(function()
        toggleState = not toggleState
        if toggleState then
            Util.Tween(toggleBg, {BackgroundColor3 = Theme.Primary}, 0.2)
            Util.Tween(toggleDot, {Position = UDim2.new(1, -20, 0.5, 0)}, 0.2, Enum.EasingStyle.Back)
        else
            Util.Tween(toggleBg, {BackgroundColor3 = Theme.BackgroundTertiary}, 0.2)
            Util.Tween(toggleDot, {Position = UDim2.new(0, 2, 0.5, 0)}, 0.2, Enum.EasingStyle.Back)
        end
        if callback then
            callback(toggleState)
        end
    end)

    return frame
end

CreateToggle(SettingsPage, "Orange Tracer on Selection", 40, true, function(val)
    State.TracerEnabled = val
    if not val then
        tracerFrame.Visible = false
        tracerDot.Visible = false
        tracerGlow.Visible = false
    end
end)

CreateToggle(SettingsPage, "Hover Highlight", 88, true, function(val)
    State.HoverEnabled = val
    if not val then
        HoverBox.Adornee = nil
    end
end)

CreateToggle(SettingsPage, "Notification Sounds", 136, false, function(val)
    -- placeholder
end)

-- Grid Snap Settings
Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 190),
    Size = UDim2.new(1, -24, 0, 20),
    Font = Theme.FontMedium,
    Text = "Grid Snap Size",
    TextColor3 = Theme.TextSecondary,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Name = "GridSnapTitle",
    Parent = SettingsPage,
})

local snapBtnsFrame = Util.Create("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 214),
    Size = UDim2.new(1, -24, 0, 28),
    Parent = SettingsPage,
})

Util.Create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    Parent = snapBtnsFrame,
})

local snapOptions = {0.25, 0.5, 1, 2, 4, 8}
local snapBtnRefs = {}

for _, val in ipairs(snapOptions) do
    local isActive = (val == State.GridSnap)
    local snapBtn = Util.Create("TextButton", {
        BackgroundColor3 = isActive and Theme.Primary or Theme.Surface,
        Size = UDim2.new(0, 52, 1, 0),
        Font = Theme.FontMedium,
        Text = tostring(val),
        TextColor3 = isActive and Theme.Background or Theme.TextSecondary,
        TextSize = 11,
        AutoButtonColor = false,
        Parent = snapBtnsFrame,
    })
    Util.AddCorner(snapBtn, Theme.CornerRadiusSmall)
    snapBtnRefs[val] = snapBtn

    snapBtn.MouseButton1Click:Connect(function()
        State.GridSnap = val
        gridLabel.Text = "Grid Snap: " .. val .. " studs"
        for v, b in pairs(snapBtnRefs) do
            if v == val then
                Util.Tween(b, {BackgroundColor3 = Theme.Primary, TextColor3 = Theme.Background}, 0.15)
            else
                Util.Tween(b, {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.TextSecondary}, 0.15)
            end
        end
    end)
end

-- Credits
local creditsFrame = Util.Create("Frame", {
    BackgroundColor3 = Theme.Surface,
    Position = UDim2.new(0, 12, 1, -80),
    Size = UDim2.new(1, -24, 0, 68),
    Parent = SettingsPage,
})
Util.AddCorner(creditsFrame, Theme.CornerRadius)
Util.AddStroke(creditsFrame, Theme.Primary, 1, 0.7)

Util.Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(1, 0, 1, 0),
    Font = Theme.FontRegular,
    Text = "Moon Marketplace v1.0\nDesigned for Studio Lite\nGame ID: 10959918411\n\nPress F6 to toggle UI",
    TextColor3 = Theme.TextMuted,
    TextSize = 10,
    TextWrapped = true,
    Parent = creditsFrame,
})

-- ============================================
-- 3D SELECTION AND PLACEMENT INPUT
-- ============================================
Mouse.Button1Down:Connect(function()
    -- Selection mode click
    if State.SelectionMode and not State.PlacementMode then
        local target = Mouse.Target
        if target then
            local obj = target
            if target.Parent and target.Parent:IsA("Model") and target.Parent ~= workspace then
                obj = target.Parent
            end
            State.SelectedObject = obj
            SelectionBox.Adornee = obj
            UpdateSelectionInfo(obj)
            Notify("Selected", Util.GetObjectIcon(obj) .. " " .. obj.Name .. " selected!", "info", 2)
        end
    end

    -- Placement mode click
    if State.PlacementMode and State.PlacingClone then
        local hit = Mouse.Hit
        if hit then
            local clone = State.PlacingClone
            local snapGrid = State.GridSnap

            local pos = hit.Position + Vector3.new(0, State.HeightOffset, 0)
            if snapGrid > 0 then
                pos = Vector3.new(
                    math.round(pos.X / snapGrid) * snapGrid,
                    math.round(pos.Y / snapGrid) * snapGrid,
                    math.round(pos.Z / snapGrid) * snapGrid
                )
            end

            if clone:IsA("Model") then
                local primary = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
                if primary then
                    clone.PrimaryPart = primary
                    pcall(function()
                        clone:SetPrimaryPartCFrame(CFrame.new(pos) * CFrame.Angles(0, math.rad(State.CurrentRotation), 0))
                    end)
                end
            elseif clone:IsA("BasePart") then
                clone.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(State.CurrentRotation), 0)
                clone.Anchored = true
            end

            clone.Parent = workspace

            -- Create spawn location
            local spawn = Instance.new("SpawnLocation")
            spawn.Name = "MoonSpawn_" .. clone.Name
            spawn.Size = Vector3.new(6, 1, 6)
            spawn.Position = pos + Vector3.new(0, -1, 8)
            spawn.Anchored = true
            spawn.BrickColor = BrickColor.new("Deep orange")
            spawn.Material = Enum.Material.Neon
            spawn.Transparency = 0.3
            spawn.TopSurface = Enum.SurfaceType.Smooth
            spawn.Parent = workspace

            local billGui = Instance.new("BillboardGui")
            billGui.Size = UDim2.new(0, 50, 0, 50)
            billGui.StudsOffset = Vector3.new(0, 3, 0)
            billGui.AlwaysOnTop = true
            billGui.Parent = spawn

            local moonLbl = Instance.new("TextLabel")
            moonLbl.Size = UDim2.new(1, 0, 1, 0)
            moonLbl.BackgroundTransparency = 1
            moonLbl.Text = "Moon"
            moonLbl.TextColor3 = Theme.Primary
            moonLbl.TextSize = 14
            moonLbl.Font = Enum.Font.GothamBold
            moonLbl.Parent = billGui

            State.PlacedCount = State.PlacedCount + 1
            placedCountLabel.Text = "Moon | Objects placed this session: " .. State.PlacedCount

            Notify("Placed!", clone.Name .. " placed with spawn location!", "success", 3)

            -- Prepare next clone
            local nextClone = Util.DeepClone(clone)
            if nextClone then
                State.PlacingClone = nextClone
            else
                State.PlacementMode = false
                State.PlacingClone = nil
                cancelPlaceBtn.Visible = false
                placeStatusText.Text = "Placement complete"
                placeStatusIcon.Text = "OK"
            end
        end
    end
end)

-- Keyboard
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.R and State.PlacementMode then
        State.CurrentRotation = (State.CurrentRotation + State.RotationSnap) % 360
        rotLabel.Text = "Rotation: " .. State.CurrentRotation .. " deg"
    end

    if input.KeyCode == Enum.KeyCode.X and State.PlacementMode then
        if State.PlacingClone then
            State.PlacingClone:Destroy()
            State.PlacingClone = nil
        end
        State.PlacementMode = false
        cancelPlaceBtn.Visible = false
        placeStatusText.Text = "Placement cancelled"
        placeStatusIcon.Text = "..."
        Notify("Cancelled", "Placement cancelled.", "warning", 2)
    end

    if input.KeyCode == Enum.KeyCode.F6 then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Scroll for height
UserInputService.InputChanged:Connect(function(input)
    if State.PlacementMode and input.UserInputType == Enum.UserInputType.MouseWheel then
        State.HeightOffset = State.HeightOffset + input.Position.Z * State.GridSnap
    end
end)

-- ============================================
-- RENDER LOOP
-- ============================================
RunService.RenderStepped:Connect(function()
    -- Tracer update
    if State.SelectedObject and State.SelectedObject.Parent then
        UpdateTracer(State.SelectedObject)
    else
        UpdateTracer(nil)
        if State.SelectedObject then
            State.SelectedObject = nil
            SelectionBox.Adornee = nil
            UpdateSelectionInfo(nil)
        end
    end

    -- Hover highlight
    if State.SelectionMode and not State.PlacementMode and State.HoverEnabled then
        local target = Mouse.Target
        if target then
            local obj = target
            if target.Parent and target.Parent:IsA("Model") and target.Parent ~= workspace then
                obj = target.Parent
            end
            if State.HoveredObject ~= obj then
                State.HoveredObject = obj
                HoverBox.Adornee = obj
            end
        else
            if State.HoveredObject then
                State.HoveredObject = nil
                HoverBox.Adornee = nil
            end
        end
    end

    -- Placement status updates
    if State.PlacementMode and State.PlacingClone then
        cancelPlaceBtn.Visible = true
        placeStatusIcon.Text = ">>"
        placeStatusText.Text = "Placing: " .. (State.PlacingClone.Name or "Object")
        placeStatusDetail.Text = "Click to place | R rotate (" .. State.CurrentRotation .. " deg) | X cancel"
        gridLabel.Text = "Grid Snap: " .. State.GridSnap .. " studs"
        rotLabel.Text = "Rotation: " .. State.CurrentRotation .. " deg"
    end

    -- Title pulse
    local pulse = (math.sin(tick() * 2) + 1) / 2
    TitleIcon.TextTransparency = pulse * 0.3
end)

-- ============================================
-- INITIALIZE
-- ============================================
RefreshBrowseList()
RefreshPublishedList()
SwitchTab("Browse")

-- Entry animation
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

Util.Tween(MainFrame, {
    Size = UDim2.new(0, 600, 0, 460),
    Position = UDim2.new(0.5, -300, 0.5, -230),
}, 0.5, Enum.EasingStyle.Back)

Notify("Welcome!", "Moon Marketplace loaded! Browse, select, and publish assets. Press F6 to toggle.", "info", 5)

print("[Moon Marketplace] v1.0 loaded successfully!")
print("[Moon Marketplace] Game: Studio Lite | Place ID: " .. tostring(game.PlaceId))
print("[Moon Marketplace] Player: " .. LocalPlayer.Name)
