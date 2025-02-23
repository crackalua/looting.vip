
assert(Drawing, "Your exploit does not support the Drawing API!")

local Players = game:GetService("Players")
local players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera



local LocalPlayer = Players.LocalPlayer
local PlayerService = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Mannequin = ReplicatedStorage.Assets.Mannequin
local LootBins = Workspace.Map.Shared.LootBins
local Randoms = Workspace.Map.Shared.Randoms
local Vehicles = Workspace.Vehicles.Spawned
local Characters = Workspace.Characters
local Corpses = Workspace.Corpses
local Zombies = Workspace.Zombies
local Loot = Workspace.Loot
local last_hitbox_update = 0


local Framework = require(ReplicatedFirst:WaitForChild("Framework"))
Framework:WaitForLoaded()

repeat task.wait() until Framework.Classes.Players.get()
local PlayerClass = Framework.Classes.Players.get()

local Globals = Framework.Configs.Globals
local World = Framework.Libraries.World
local Network = Framework.Libraries.Network
local Cameras = Framework.Libraries.Cameras
local Bullets = Framework.Libraries.Bullets
local Lighting = Framework.Libraries.Lighting
local Interface = Framework.Libraries.Interface
local Resources = Framework.Libraries.Resources
local Raycasting = Framework.Libraries.Raycasting
local Characters = Workspace.Characters
local Corpses = Workspace.Corpses
local Zombies = Workspace.Zombies
local Maids = Framework.Classes.Maids
local Animators = Framework.Classes.Animators
local VehicleController = Framework.Classes.VehicleControler

local Firearm = nil
task.spawn(function() 
    setthreadidentity(2)
    Firearm = require(ReplicatedStorage.Client.Abstracts.ItemInitializers.Firearm)
end)

local ItemData = Framework.Configs.ItemData
local Tick = tick()
local InstanceNew = Instance.new
local last_shot_time = 0
local Events = getupvalue(Network.Add, 1)
local GetFireImpulse = getupvalue(Bullets.Fire, 6)
local GetSpreadAngle = getupvalue(Bullets.Fire, 1)
local GetSpreadVector = getupvalue(Bullets.Fire, 3)
local CastLocalBullet = getupvalue(Bullets.Fire, 4)
local LightingState = getupvalue(Lighting.GetState, 1)
local AnimatedReload = getupvalue(Firearm, 7)

local Decimals = 4
local Clock = os.clock()
local ValueText = "Value Is Now :"

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/drillygzzly/Roblox-UI-Libs/main/1%20Tokyo%20Lib%20(FIXED)/Tokyo%20Lib%20Source.lua"))({
    cheatname = "looting.vip", 
    gamename = "AR2", 
})

library:init()

local Window = library.NewWindow({
	title = "Looting.vip",
	size = UDim2.new(0, 525, 0, 650)
})

local tabs = {
    Tab1 = Window:AddTab("Visuals"),
    Tab2 = Window:AddTab("Combat"),
    Tab3 = Window:AddTab("Movement"),
    Settings = library:CreateSettingsTab(Window),
	
}

local sections = {
	Section1 = tabs.Tab1:AddSection("Player", 1),
    SectionG = tabs.Tab1:AddSection("Vehicle", 2),
    Section3 = tabs.Tab2:AddSection("Aim", 1),
	Section4 = tabs.Tab2:AddSection("Players", 2),
    Section5 = tabs.Tab2:AddSection("Gun Mods", 3),
    Section6 = tabs.Tab3:AddSection("Jumping", 3),

}

local function NewDrawing(Type, Properties)
    local Object = Drawing.new(Type)
    for Property, Value in pairs(Properties) do
        Object[Property] = Value
    end
    return Object
end



local ESPSettings = {
    Enabled = false,
    ShowNames = false,
    ShowDistance = false,
    ShowHealth = false,
    ShowBoxes = false,
    ShowTracers = false,
    ShowChams = false,
    MaxDistance = 10000
}


local ESPObjects = {}
local ChamsObjects = {}
local FOVCircle = Drawing.new("Circle")



local AimbotSettings = {
    Enabled = false,
    MaxDistance = 10000,
    TargetFOV = 200,
    FOVCircle = false,
    TargetPart = "Head",
    DefaultProjectileSpeed = 1000
}


local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldIndex = mt.__index
local last_hitbox_update = 0
local HitboxSettings = {
    Enabled = false,
    Size = 15
}


mt.__index = newcclosure(function(self, k)
    if k == "Size" and self:IsA("BasePart") and self.Name == "Head" then
        return Vector3.new(1.15, 1.15, 1.15)
    end
    return oldIndex(self, k)
end)


local function updateHitboxSize(size)
    if not HitboxSettings.Enabled then return end
    
    pcall(function()
        for _, player in pairs(players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local head = player.Character:FindFirstChild("Head")
                if head and typeof(head) == "Instance" then
                    head.Size = Vector3.new(size, size, size)
                end
            end
        end
    end)
end


RunService.RenderStepped:Connect(function()

    local current_time = tick()
    
    if HitboxSettings.Enabled and current_time - last_hitbox_update >= 0.1 then
        updateHitboxSize(HitboxSettings.Size)
        last_hitbox_update = current_time
    end
end)







local function GetCharacter(Player)
    return Player.Character or Workspace:FindFirstChild(Player.Name)
end


local function GetWeaponProjectileSpeed()
    local Character = GetCharacter(LocalPlayer)
    if not Character then return nil end

    local Equipped = Character:FindFirstChild("Equipped")
    if not Equipped then return nil end

    local WeaponName = Equipped.Value
    if not WeaponName then return nil end

    local WeaponData = ReplicatedStorage.ItemData.Firearms:FindFirstChild(WeaponName)
    if not WeaponData then return nil end

    local FireConfig = require(WeaponData).FireConfig
    local ProjectileSpeed = FireConfig and FireConfig.MuzzleVelocity
end


local function GetWeaponProjectileSpeed()
    local Character = GetCharacter(LocalPlayer)
    if not Character then return AimbotSettings.DefaultProjectileSpeed end

    local Equipped = Character:FindFirstChild("Equipped")
    if not Equipped or not Equipped.Value then return AimbotSettings.DefaultProjectileSpeed and print("Not equipped") end

    local WeaponName = Equipped.Value
    local WeaponData = ReplicatedStorage.ItemData.Firearms:FindFirstChild(WeaponName)
    
    if WeaponData then
   
        local FireConfig = require(WeaponData).FireConfig
        if FireConfig and FireConfig.MuzzleVelocity then
            return FireConfig.MuzzleVelocity
        end
    end

    return AimbotSettings.DefaultProjectileSpeed
end

local function UpdateAimbot()
    if not AimbotSettings.Enabled then
        
        return 
    end


    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        wait(2)
        return
    end
    local ClosestPlayer = nil
    local ClosestDistance = math.huge
    local ClosestAngle = AimbotSettings.TargetFOV

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end

        local Character = GetCharacter(Player)
        if not Character then
          
            continue
        end

        local TargetPart = Character:FindFirstChild(AimbotSettings.TargetPart) or Character:FindFirstChild("HumanoidRootPart")

        if not TargetPart then
           
            continue
        end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid or Humanoid.Health <= 0 then
            
            continue
        end

        local ScreenPos, OnScreen = Camera:WorldToViewportPoint(TargetPart.Position)
        if not OnScreen then
            
            continue
        end

        local Distance = (TargetPart.Position - Camera.CFrame.Position).Magnitude
        if Distance > AimbotSettings.MaxDistance then
           
            continue
        end

        local MousePos = UserInputService:GetMouseLocation()
        local AngleFromMouse = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude

        if AngleFromMouse < ClosestAngle then
            ClosestPlayer = Player
            ClosestDistance = Distance
            ClosestAngle = AngleFromMouse
        end
    end

    if ClosestPlayer then
        local Character = GetCharacter(ClosestPlayer)
        if Character then
            local TargetPart = Character:FindFirstChild(AimbotSettings.TargetPart)
            if TargetPart then
                local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(TargetPart.Position)
                if OnScreen then
                    local MousePos = UserInputService:GetMouseLocation()
                    mousemoverel(
                        (ScreenPosition.X - MousePos.X) / 2,
                        (ScreenPosition.Y - MousePos.Y) / 2
                    )
                    
                else
                    
                end
            else
           
            end
        end
    else
       
    end
end







local ESPObjects = {}
local ChamsObjects = {}
local FOVCircle = Drawing.new("Circle")


local function RemoveChams(Player)
    if ChamsObjects[Player] then
        ChamsObjects[Player]:Destroy()
        ChamsObjects[Player] = nil
    end
end

local function RemoveESP(Player)
    if ESPObjects[Player] then
        for _, Obj in pairs(ESPObjects[Player]) do
            Obj:Remove()
        end
        ESPObjects[Player] = nil
    end
    RemoveChams(Player)
end

local function AddChams(Player)
    if Player == LocalPlayer or ChamsObjects[Player] then return end

    local Character = Player.Character
    if not Character then return end

    local Highlight = Instance.new("Highlight")
    Highlight.Adornee = Character
    Highlight.FillColor = Color3.new(1, 0, 0)
    Highlight.OutlineColor = Color3.new(0, 0, 0)
    Highlight.FillTransparency = 0.5
    Highlight.OutlineTransparency = 0
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.Parent = Character

    ChamsObjects[Player] = Highlight
end

local function AddESP(Player)
    if Player == LocalPlayer or ESPObjects[Player] then return end



    if ESPSettings.ShowChams then
        AddChams(Player)
    end
end

local function UpdateESP(Player)
    local ESP = ESPObjects[Player]
    if not ESP then return end

    local Character = Player.Character
    local RootPart = Character and Character:FindFirstChild(AimbotSettings.TargetPart)

    if not RootPart then
        for _, Obj in pairs(ESP) do
            Obj.Visible = false
        end
        RemoveChams(Player)
        return
    end

    local Pos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
    local Distance = (Camera.CFrame.Position - RootPart.Position).Magnitude

    if OnScreen and ESPSettings.Enabled and Distance <= ESPSettings.MaxDistance then
        local ScaleFactor = 1 / (Distance / 100)
        local BoxSize = Vector2.new(40, 60) * ScaleFactor
        local TopLeft = Vector2.new(Pos.X - BoxSize.X / 2, Pos.Y - BoxSize.Y / 2)

      
    else
        for _, Obj in pairs(ESP) do
            Obj.Visible = false
        end
    end
end


Players.PlayerAdded:Connect(function(Player)
    AddESP(Player)
    Player.CharacterAdded:Connect(function()
        AddESP(Player)
    end)
end)

Players.PlayerRemoving:Connect(function(Player)
    RemoveESP(Player)
end)

for _, Player in ipairs(Players:GetPlayers()) do
    AddESP(Player)
end


RunService.RenderStepped:Connect(function()

    UpdateAimbot()






    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            UpdateESP(Player)
        end
    end
end)

local function GetHealth(Player)
    if Player and Player:FindFirstChild("Stats") then
        local Health = Player.Stats:FindFirstChild("Health")
        if Health and Health:IsA("NumberValue") then
            return Health.Value, 100
        end
    end
    return 0, 100
end

local function AddChams(Player)
    if Player == LocalPlayer or ChamsObjects[Player] then return end

    local Character = Player.Character
    if not Character then return end

    local Highlight = Instance.new("Highlight")
    Highlight.Adornee = Character
    Highlight.FillColor = Color3.new(1, 0, 0) 
    Highlight.OutlineColor = Color3.new(0, 0, 0)
    Highlight.FillTransparency = 0.5
    Highlight.OutlineTransparency = 0
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.Parent = Character

    ChamsObjects[Player] = Highlight
end


local function RemoveChams(Player)
    if ChamsObjects[Player] then
        ChamsObjects[Player]:Destroy()
        ChamsObjects[Player] = nil
    end
end


local function AddESP(Player)
    if Player == LocalPlayer or ESPObjects[Player] then return end

    ESPObjects[Player] = {
        BoxOutline = NewDrawing("Square", {Thickness = 3, Color = Color3.new(0, 0, 0), Transparency = 0.75, Visible = false}),
        Box = NewDrawing("Square", {Thickness = 1, Color = Color3.new(1, 0, 0), Transparency = 1, Visible = false}),
        TracerOutline = NewDrawing("Line", {Thickness = 3, Color = Color3.new(0, 0, 0), Transparency = 0.75, Visible = false}),
        Tracer = NewDrawing("Line", {Thickness = 1, Color = Color3.new(255, 255, 255), Transparency = 1, Visible = false}),
        NameTag = NewDrawing("Text", {Size = 13, Center = true, Outline = true, Color = Color3.new(1, 1, 1), Visible = false}),
        DistanceTag = NewDrawing("Text", {Size = 12, Center = true, Outline = true, Color = Color3.new(1, 1, 1), Visible = false}),
        HealthBarOutline = NewDrawing("Line", {Thickness = 3, Color = Color3.new(0, 0, 0), Transparency = 1, Visible = false}),
        HealthBar = NewDrawing("Line", {Thickness = 2, Color = Color3.new(0, 1, 0), Transparency = 1, Visible = false}),
    }

    if ESPSettings.ShowChams then
        AddChams(Player)
    end
end


RunService.RenderStepped:Connect(function()
    for _, Player in pairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end

        if not ESPObjects[Player] then
            AddESP(Player)
        end

        local ESP = ESPObjects[Player]
        local Character = Player.Character
        local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

        if not RootPart then
            for _, Obj in pairs(ESP) do
                Obj.Visible = false
            end
            RemoveChams(Player)
            continue
        end

        local Pos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
        local Distance = (Camera.CFrame.Position - RootPart.Position).Magnitude

        if OnScreen and ESPSettings.Enabled and Distance <= ESPSettings.MaxDistance then
            local Health, MaxHealth = GetHealth(Player)
            local HealthPercent = Health / MaxHealth

           
            if ESPSettings.ShowChams and ChamsObjects[Player] then
                ChamsObjects[Player].FillColor = Color3.fromRGB(255 - (HealthPercent * 255), HealthPercent * 255, 0)
            elseif ChamsObjects[Player] then
                RemoveChams(Player)
            end

            local ScaleFactor = 1 / (Distance / 100)
            local BoxSize = Vector2.new(40, 60) * ScaleFactor
            local TopLeft = Vector2.new(Pos.X - BoxSize.X / 2, Pos.Y - BoxSize.Y / 2)
            ESP.BoxOutline.Visible = ESPSettings.ShowBoxes
            ESP.Box.Visible = ESPSettings.ShowBoxes
            if ESPSettings.ShowBoxes then
                ESP.BoxOutline.Position = TopLeft
                ESP.BoxOutline.Size = BoxSize

                ESP.Box.Position = TopLeft
                ESP.Box.Size = BoxSize
            end

            ESP.TracerOutline.Visible = ESPSettings.ShowTracers
            ESP.Tracer.Visible = ESPSettings.ShowTracers
            if ESPSettings.ShowTracers then
                ESP.TracerOutline.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                ESP.TracerOutline.To = Vector2.new(Pos.X, Pos.Y)

                ESP.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                ESP.Tracer.To = Vector2.new(Pos.X, Pos.Y)
            end


            ESP.NameTag.Visible = ESPSettings.ShowNames
            if ESPSettings.ShowNames then
                ESP.NameTag.Text = Player.Name
                ESP.NameTag.Position = Vector2.new(Pos.X, TopLeft.Y - 15)
            end

            ESP.DistanceTag.Visible = ESPSettings.ShowDistance
            if ESPSettings.ShowDistance then
                ESP.DistanceTag.Text = string.format("[%d]", Distance)
                ESP.DistanceTag.Position = Vector2.new(Pos.X, TopLeft.Y - 30)
            end

            ESP.HealthBarOutline.Visible = ESPSettings.ShowHealth
            ESP.HealthBar.Visible = ESPSettings.ShowHealth
            if ESPSettings.ShowHealth then
                local BarHeight = BoxSize.Y
                local HealthBarHeight = BarHeight * HealthPercent

                ESP.HealthBarOutline.From = Vector2.new(TopLeft.X - 6, TopLeft.Y)
                ESP.HealthBarOutline.To = Vector2.new(TopLeft.X - 6, TopLeft.Y + BarHeight)

                ESP.HealthBar.From = Vector2.new(TopLeft.X - 6, TopLeft.Y + BarHeight)
                ESP.HealthBar.To = Vector2.new(TopLeft.X - 6, TopLeft.Y + BarHeight - HealthBarHeight)
                ESP.HealthBar.Color = Color3.fromRGB(255 - (HealthPercent * 255), HealthPercent * 255, 0)
            end
        else
            for _, Obj in pairs(ESP) do
                Obj.Visible = false
            end
        end
    end
end)


if AimbotSettings.Enabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
    UpdateAimbot()
end



for _, Player in pairs(Players:GetPlayers()) do
    AddESP(Player)
end


sections.Section1:AddToggle({
    enabled = true,
   text = "ESP Enabled",
   flag = "espEnabled", 
   callback = function(Value)
   ESPSettings.Enabled = Value
   end,
  
})

sections.Section1:AddToggle({
    enabled = true,
   text = "Show Names",
   flag = "showNames", 
     callback = function(Value)
   ESPSettings.ShowNames = Value
  end
})


sections.Section1:AddToggle({
    enabled = true,
   text = "Show Distance",
   flag = "showDistance", 
   callback = function(Value)
   ESPSettings.ShowDistance = Value
  end,
})

sections.Section1:AddToggle({
   text = "Show Boxes",
   enabled = true,
   flag = "showBoxes", 
     callback = function(Value)
   ESPSettings.ShowBoxes = Value

  end,
})

sections.Section1:AddToggle({
  enabled = true,
	text = "Show Tracers",
	flag = "showTracers",
   callback = function(Value)
   ESPSettings.ShowTracers = Value
  end,
})

sections.Section1:AddToggle({
  enabled = true,
	text = "Show Chams",
	flag = "showChams",
   callback = function(Value)
   ESPSettings.ShowChams = Value
  end,
})

sections.Section1:AddToggle({
  enabled = true,
	text = "Show Health",
	flag = "showHealth",
   callback = function(Value)
   ESPSettings.ShowHealth = Value
  end,
})

sections.Section1:AddSlider({
	text = "Max Distance", 
	flag = 'Slider_1', 
	suffix = "", 
	value = ESPSettings.MaxDistance,
	min = 1000, 
	max = 10000,
	increment = 0.001,
	tooltip = false,
	risky = false,
	callback = function(v) 
		ESPSettings.MaxDistance = v
	end
})

sections.Section3:AddToggle({
    enabled = true,
    text = "Aimbot Enabled",
    flag = "aimbotEnabled",
    callback = function(Value)
        AimbotSettings.Enabled = Value
    end,
})


sections.Section3:AddSlider({
	text = "FOV Radius", 
	flag = 'fovRadius', 
	suffix = "", 
	value = AimbotSettings.TargetFOV,
	min = 0.1, 
	max = 1000,
	increment = 0.001,
	risky = false,
	callback = function(v) 
		AimbotSettings.TargetFOV = v
	end
})

sections.Section3:AddSlider({
	text = "Max Distance", 
	flag = 'aimbotDistance', 
	suffix = "studs", 
	value = 0.000,
	min = 0.1, 
	max = 10000,
	increment = 0.001,
	risky = false,
	callback = function(v) 
		AimbotSettings.MaxDistance = v
	end
})



 sections.Section4:AddToggle({
    enabled = true,
    text = "Hitbox Expander",
    flag = "hitboxEnabled",
    callback = function(Value)
        HitboxSettings.Enabled = Value
        if not Value then
            pcall(function()
                for _, player in pairs(players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local head = player.Character:FindFirstChild("Head")
                        if head and typeof(head) == "Instance" then
                            head.Size = Vector3.new(1, 1, 1)
                        end
                    end
                end
            end)
        end
    end,
})


sections.Section4:AddSlider({
	text = "Hitbox Size", 
	flag = 'hitboxSize', 
	suffix = "", 
	value = HitboxSettings.Size,
	min = 0.1, 
	max = 20,
	increment = 0.001,
	risky = false,
	callback = function(v) 
		print("Slider Value Is Now : ".. v)
	end
})

local GunModSettings = {
    NoRecoilEnabled = false,
    RecoilValue = 1.0,
    NoReloadEnabled = false,
    NoSpreadEnabled = false,
    InstantSearchEnabled = false, 
}
local function ModifyGunRecoil(enabled, value)
    if not Firearm then return end
    
    local function modifyRecoilData(gun, property, multiplier)
        if gun.RecoilData then
            setreadonly(gun.RecoilData, false)
            gun.RecoilData[property] = gun.RecoilData[property] * multiplier
            setreadonly(gun.RecoilData, true)
        end
    end

    for _, gunData in pairs(ItemData) do
        if gunData.Type == "Firearm" then
            setreadonly(gunData, false)
            
            if enabled then
                modifyRecoilData(gunData, "KickUpBounce", value)
                modifyRecoilData(gunData, "KickUpForce", value)
                modifyRecoilData(gunData, "KickUpSpeed", value)
                modifyRecoilData(gunData, "KickUpGunInfluence", value)
                modifyRecoilData(gunData, "KickUpCameraInfluence", value)
                modifyRecoilData(gunData, "RaiseInfluence", value)
                modifyRecoilData(gunData, "RaiseBounce", value)
                modifyRecoilData(gunData, "RaiseSpeed", value)
                modifyRecoilData(gunData, "RaiseForce", value)
                modifyRecoilData(gunData, "ShiftGunInfluence", value)
                modifyRecoilData(gunData, "ShiftBounce", value)
                modifyRecoilData(gunData, "ShiftCameraInfluence", value)
                modifyRecoilData(gunData, "ShiftForce", value)
            else
                modifyRecoilData(gunData, "KickUpBounce", 1)
                modifyRecoilData(gunData, "KickUpForce", 1)
                modifyRecoilData(gunData, "KickUpSpeed", 1)
                modifyRecoilData(gunData, "KickUpGunInfluence", 1)
                modifyRecoilData(gunData, "KickUpCameraInfluence", 1)
                modifyRecoilData(gunData, "RaiseInfluence", 1)
                modifyRecoilData(gunData, "RaiseBounce", 1)
                modifyRecoilData(gunData, "RaiseSpeed", 1)
                modifyRecoilData(gunData, "RaiseForce", 1)
                modifyRecoilData(gunData, "ShiftGunInfluence", 1)
                modifyRecoilData(gunData, "ShiftBounce", 1)
                modifyRecoilData(gunData, "ShiftCameraInfluence", 1)
                modifyRecoilData(gunData, "ShiftForce", 1)
            end
            
            setreadonly(gunData, true)
        end
    end
end

sections.Section5:AddToggle({
    enabled = true,
    text = "No Recoil",
    flag = "noRecoilEnabled",
    callback = function(Value)
        GunModSettings.NoRecoilEnabled = Value
        ModifyGunRecoil(Value, GunModSettings.RecoilValue)
    end,
})

sections.Section5:AddSlider({
    text = "Recoil Multiplier",
    flag = "recoilMultiplier",
    suffix = "x",
    value = 1.0,
    min = 0,
    max = 1,
    increment = 0.01,
    tooltip = "0 = No Recoil, 1 = Full Recoil",
    callback = function(v)
        GunModSettings.RecoilValue = v
        if GunModSettings.NoRecoilEnabled then
            ModifyGunRecoil(true, v)
        end
    end
})

local OldGetFireImpulse = GetFireImpulse
GetFireImpulse = function(...)
    if GunModSettings.NoRecoilEnabled then
        local ReturnArgs = {OldGetFireImpulse(...)}
        for Index = 1, #ReturnArgs do
            ReturnArgs[Index] = ReturnArgs[Index] * (1 - GunModSettings.RecoilValue)
        end
        
        return unpack(ReturnArgs)
    end
    
    return OldGetFireImpulse(...)
end

setupvalue(Firearm, 7, function(...)
    if GunModSettings.NoReloadEnabled then
        local Args = {...}
        for Index = 0, Args[3].LoopCount do
            Args[4]("Commit", "Load")
        end
        
        Args[4]("Commit", "End")
        return true
    end
    return AnimatedReload(...)
end)

sections.Section5:AddToggle({
    enabled = true,
    text = "No Spread",
    flag = "noSpreadEnabled",
    callback = function(Value)
        GunModSettings.NoSpreadEnabled = Value
    end,
})

sections.Section5:AddToggle({
    enabled = true,
    text = "No Reload",
    flag = "noReloadEnabled",
    callback = function(Value)
        GunModSettings.NoReloadEnabled = Value
    end,
})

local ProjectileSpeed = 1000
local ProjectileGravity = Framework.Configs.Globals.ProjectileGravity
local ShotMaxDistance = Framework.Configs.Globals.ShotMaxDistance
local ProjectileDirection = Vector3.new(0, 0, 0)




local SilentAimSettings = {
    Enabled = false,
    ShowFOV = false,
    FOVSize = 100,
    HitChance = 100,
    TargetPart = "Head",
    MaxDistance = 10000,
    Prediction = true,
    PredictionMultiplier = 1.165
}

local SilentAimFOV = Drawing.new("Circle")
SilentAimFOV.Thickness = 1
SilentAimFOV.NumSides = 100
SilentAimFOV.Radius = SilentAimSettings.FOVSize
SilentAimFOV.Filled = false
SilentAimFOV.Visible = false
SilentAimFOV.ZIndex = 999
SilentAimFOV.Transparency = 1
SilentAimFOV.Color = Color3.fromRGB(255, 255, 255)

local function GetProjectileSpeed()
    if not Framework or not Framework.Classes.Players then return 1000 end
    local PlayerClass = Framework.Classes.Players.get()
    if not PlayerClass then return 1000 end
    
    local equipped = PlayerClass.equipped
    if not equipped then return 1000 end
    
    local config = equipped.FireConfig
    return config and config.MuzzleVelocity or 1000
end

local function PredictPosition(targetPart)
    if not targetPart then return nil end
    
    local velocity = targetPart.AssemblyLinearVelocity
    local position = targetPart.Position
    local distance = (position - Camera.CFrame.Position).Magnitude
    local timeToHit = distance / GetProjectileSpeed()
    
    return position + (velocity * timeToHit * SilentAimSettings.PredictionMultiplier)
end

task.spawn(function()
    OldFire = hookfunction(Bullets.Fire, newcclosure(function(Self, ...)
        local Args = {...}

        if GunModSettings.NoSpreadEnabled then
            if Args[5] and typeof(Args[5]) == "Vector3" then
                Args[5] = Vector3.new(0, 0, 0)
            end
            if Args[7] and typeof(Args[7]) == "Vector3" then
                Args[7] = Vector3.new(0, 0, 0)
            end
        end

        if SilentAimSettings.Enabled and Args[5] and typeof(Args[5]) == "Vector3" then
            if math.random(1, 100) > SilentAimSettings.HitChance then 
                return OldFire(Self, unpack(Args))
            end

            local closest = nil
            local maxDist = math.huge
            local mousePos = UserInputService:GetMouseLocation()

            for _, plr in pairs(Players:GetPlayers()) do
                if plr == LocalPlayer then continue end

                local char = plr.Character
                if not char then continue end

                local part = char:FindFirstChild(SilentAimSettings.TargetPart)
                if not part then continue end

                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if not onScreen then continue end

                local mouseDistance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if mouseDistance > SilentAimSettings.FOVSize then continue end

                local dist = (part.Position - Args[4]).Magnitude
                if dist > SilentAimSettings.MaxDistance then continue end

                if mouseDistance < maxDist then
                    closest = part
                    maxDist = mouseDistance
                end
            end

            if closest then
                local targetPos = SilentAimSettings.Prediction and PredictPosition(closest) or closest.Position
                if targetPos then
                    local direction = (targetPos - Args[4]).Unit
                    Args[5] = direction
                    Args[7] = direction
                end
            end
        end

        return OldFire(Self, unpack(Args))
    end))
end)

RunService.RenderStepped:Connect(function()
    if SilentAimSettings.ShowFOV then
        SilentAimFOV.Position = UserInputService:GetMouseLocation()
        SilentAimFOV.Radius = SilentAimSettings.FOVSize
        SilentAimFOV.Visible = true
    else
        SilentAimFOV.Visible = false
    end
end)

sections.Section3:AddToggle({
    enabled = true,
    text = "Silent Aim",
    flag = "silentAimEnabled",
    callback = function(Value)
        SilentAimSettings.Enabled = Value
    end,
})

sections.Section3:AddToggle({
    enabled = true,
    text = "Show FOV",
    flag = "silentAimFOV",
    callback = function(Value)
        SilentAimSettings.ShowFOV = Value
    end,
})

sections.Section3:AddToggle({
    enabled = true,
    text = "Use Prediction",
    flag = "silentAimPrediction",
    callback = function(Value)
        SilentAimSettings.Prediction = Value
    end,
})

sections.Section3:AddSlider({
    text = "FOV Size",
    flag = "silentAimFOVSize",
    suffix = "px",
    value = 100,
    min = 10,
    max = 500,
    increment = 1,
    callback = function(v)
        SilentAimSettings.FOVSize = v
    end
})

sections.Section3:AddSlider({
    text = "Hit Chance",
    flag = "silentAimHitChance",
    suffix = "%",
    value = SilentAimSettings.HitChance,
    min = 0,
    max = 100,
    increment = 1,
    callback = function(v)
        SilentAimSettings.HitChance = v
    end
})

sections.Section3:AddSlider({
    text = "Prediction Multiplier",
    flag = "predictionMultiplier",
    suffix = "x",
    value = 1.165,
    min = 0.1,
    max = 2.5,
    increment = 0.05,
    callback = function(v)
        SilentAimSettings.PredictionMultiplier = v
    end
})

sections.Section3:AddList({
    text = "Target Part",
    flag = "targetPart",
    values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    callback = function(selected)
        SilentAimSettings.TargetPart = selected
    end
})


local VehicleESPSettings = {
    Enabled = false, 
    MaxDistance = 5000 
}

local VehicleESPObjects = {}

local function CreateVehicleESP(vehicle)
    local nameTag = NewDrawing("Text", {
        Visible = false,
        Center = true,
        Outline = true,
        Size = 16,
        Color = Color3.new(0, 1, 0),
        Transparency = 1,
    })

    VehicleESPObjects[vehicle] = {
        Model = vehicle,
        NameTag = nameTag
    }
end

local function RemoveVehicleESP(vehicle)
    if VehicleESPObjects[vehicle] then
        VehicleESPObjects[vehicle].NameTag:Remove()
        VehicleESPObjects[vehicle] = nil
    end
end

local function UpdateVehicleESP()
    if not VehicleESPSettings.Enabled then
        for _, esp in pairs(VehicleESPObjects) do
            esp.NameTag.Visible = false
        end
        return
    end

    for vehicle, esp in pairs(VehicleESPObjects) do
        if vehicle and vehicle:IsA("Model") and vehicle.PrimaryPart then
            local primaryPart = vehicle.PrimaryPart
            local screenPosition, onScreen = Camera:WorldToViewportPoint(primaryPart.Position)

            if onScreen then
                local distance = (primaryPart.Position - Camera.CFrame.Position).Magnitude
                if distance <= VehicleESPSettings.MaxDistance then
                    esp.NameTag.Text = string.format("%s [%d]", vehicle.Name, math.floor(distance))
                    esp.NameTag.Position = Vector2.new(screenPosition.X, screenPosition.Y)
                    esp.NameTag.Visible = true
                else
                    esp.NameTag.Visible = false
                end
            else
                esp.NameTag.Visible = false
            end
        else
            esp.NameTag.Visible = false
        end
    end
end

for _, vehicle in ipairs(Vehicles:GetChildren()) do
    if vehicle:IsA("Model") then
        CreateVehicleESP(vehicle)
    end
end

Vehicles.ChildAdded:Connect(function(vehicle)
    if vehicle:IsA("Model") then
        CreateVehicleESP(vehicle)
    end
end)

Vehicles.ChildRemoved:Connect(function(vehicle)
    RemoveVehicleESP(vehicle)
end)

RunService.RenderStepped:Connect(UpdateVehicleESP)




sections.SectionG:AddToggle({
    enabled = true,
    text = "Vehicle ESP Enabled",
    flag = "vehicleESPEnabled",
    callback = function(value)
        VehicleESPSettings.Enabled = value
    end,
})

sections.SectionG:AddSlider({
    text = "Vehicle ESP Distance",
    flag = "vehicleESPDistance",
    suffix = " studs",
    value = VehicleESPSettings.MaxDistance,
    min = 1000,
    max = 10000,
    increment = 100,
    callback = function(value)
        VehicleESPSettings.MaxDistance = value
    end,
})

local CorpseESPSettings = {
    Enabled = false, 
    MaxDistance = 5000 
}

local CorpseESPObjects = {}



local function CreateCorpseESP(corpse)
    if corpse.Name == "Zombie" then return end 
    local nameTag = NewDrawing("Text", {
        Visible = false,
        Center = true,
        Outline = true,
        Size = 16,
        Color = Color3.new(1, 0, 0), 
        Transparency = 1,
    })

    CorpseESPObjects[corpse] = {
        Model = corpse,
        NameTag = nameTag
    }
end

local function RemoveCorpseESP(corpse)
    if CorpseESPObjects[corpse] then
        CorpseESPObjects[corpse].NameTag:Remove()
        CorpseESPObjects[corpse] = nil
    end
end

local function UpdateCorpseESP()
    if not CorpseESPSettings.Enabled then
        for _, esp in pairs(CorpseESPObjects) do
            esp.NameTag.Visible = false
        end
        return
    end

    for corpse, esp in pairs(CorpseESPObjects) do
        if corpse and corpse:IsA("Model") and corpse.PrimaryPart then
            local primaryPart = corpse.PrimaryPart
            local screenPosition, onScreen = Camera:WorldToViewportPoint(primaryPart.Position)

            if onScreen then
                local distance = (primaryPart.Position - Camera.CFrame.Position).Magnitude
                if distance <= CorpseESPSettings.MaxDistance then
                    esp.NameTag.Text = string.format("%s [%d studs]", corpse.Name, math.floor(distance))
                    esp.NameTag.Position = Vector2.new(screenPosition.X, screenPosition.Y)
                    esp.NameTag.Visible = true
                else
                    esp.NameTag.Visible = false
                end
            else
                esp.NameTag.Visible = false
            end
        else
            esp.NameTag.Visible = false
        end
    end
end

for _, corpse in ipairs(Corpses:GetChildren()) do
    if corpse:IsA("Model") and corpse.Name ~= "Zombie" then
        CreateCorpseESP(corpse)
    end
end

Corpses.ChildAdded:Connect(function(corpse)
    if corpse:IsA("Model") and corpse.Name ~= "Zombie" then
        CreateCorpseESP(corpse)
    end
end)

Corpses.ChildRemoved:Connect(function(corpse)
    RemoveCorpseESP(corpse)
end)

sections.Section1:AddSeparator({
    enabled = true,
    text = "Corpse ESP"
})

sections.Section1:AddToggle({
    enabled = true,
    text = "Corpse ESP Enabled",
    flag = "corpseESPEnabled",
    callback = function(value)
        CorpseESPSettings.Enabled = value
    end,
})

sections.Section1:AddSlider({
    text = "Corpse ESP Distance",
    flag = "corpseESPDistance",
    suffix = " studs",
    value = CorpseESPSettings.MaxDistance,
    min = 1000,
    max = 10000,
    increment = 100,
    callback = function(value)
        CorpseESPSettings.MaxDistance = value
    end,
})

local ZombieESPSettings = {
    Enabled = false,
    MaxDistance = 5000,
    RareOnly = false,
    RarityThreshold = 1
}

local ZombieESPObjects = {}

local function GetZombieRarity(zombieName)
    local config = workspace.Zombies.Configs:FindFirstChild(zombieName)
    if config and config:IsA("ModuleScript") then
        local success, zombieData = pcall(require, config)
        if success and zombieData and zombieData.SpawnRarity then
            return tonumber(zombieData.SpawnRarity) or 0
        end
    end
    return 0
end

local function CreateZombieESP(zombie)
    if not zombie or not zombie.Name then return end
    if not zombie:IsA("Model") then return end
    
    local rarity = GetZombieRarity(zombie.Name)
    
    local nameTag = Drawing.new("Text")
    nameTag.Visible = false
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Size = 16
    nameTag.Color = (rarity and rarity >= ZombieESPSettings.RarityThreshold) and Color3.new(1, 0, 0) or Color3.new(1, 0.5, 0)
    nameTag.Transparency = 1

    
    if not ZombieESPSettings.RareOnly or (rarity and rarity >= ZombieESPSettings.RarityThreshold) then
        if typeof(zombie) == "Instance" then
            ZombieESPObjects[zombie.Name] = {
                Model = zombie,
                NameTag = nameTag,
                Rarity = rarity
            }
        end
    else
        nameTag:Remove()
    end
end

local function RemoveZombieESP(zombie)
    if zombie and ZombieESPObjects[zombie.Name] then
        ZombieESPObjects[zombie.Name].NameTag:Remove()
        ZombieESPObjects[zombie.Name] = nil
    end
end

local function UpdateZombieESP()
    if not ZombieESPSettings.Enabled then
        for _, esp in pairs(ZombieESPObjects) do
            if esp and esp.NameTag then
                esp.NameTag.Visible = false
            end
        end
        return
    end

    for zombieName, esp in pairs(ZombieESPObjects) do
        if not esp or not esp.Model or not esp.Model.Parent then
            if esp and esp.NameTag then
                esp.NameTag:Remove()
            end
            ZombieESPObjects[zombieName] = nil
            continue
        end

        if esp.Model and esp.Model.PrimaryPart then
            local primaryPart = esp.Model.PrimaryPart
            local screenPosition, onScreen = Camera:WorldToViewportPoint(primaryPart.Position)

            if onScreen then
                local distance = (primaryPart.Position - Camera.CFrame.Position).Magnitude
                if distance <= ZombieESPSettings.MaxDistance then
                    esp.NameTag.Text = string.format("%s [%d studs] [%.2f]", 
                        esp.Model.Name, 
                        math.floor(distance),
                        esp.Rarity
                    )
                    esp.NameTag.Position = Vector2.new(screenPosition.X, screenPosition.Y)
                    esp.NameTag.Visible = true
                else
                    esp.NameTag.Visible = false
                end
            else
                esp.NameTag.Visible = false
            end
        else
            esp.NameTag.Visible = false
        end
    end
end

for _, zombie in ipairs(workspace.Zombies.Mobs:GetChildren()) do
    if zombie:IsA("Model") then
        CreateZombieESP(zombie)
    end
end

workspace.Zombies.Mobs.ChildAdded:Connect(function(zombie)
    if zombie:IsA("Model") then
        CreateZombieESP(zombie)
    end
end)

workspace.Zombies.Mobs.ChildRemoved:Connect(function(zombie)
    RemoveZombieESP(zombie)
end)

RunService.RenderStepped:Connect(UpdateZombieESP)


sections.Section1:AddSeparator({
    enabled = true,
    text = "Zombie ESP"
})

sections.Section1:AddToggle({
    enabled = true,
    text = "Zombie ESP Enabled",
    flag = "zombieESPEnabled",
    callback = function(value)
        ZombieESPSettings.Enabled = value
    end,
})

sections.Section1:AddToggle({
    enabled = true,
    text = "Rare Zombies Only",
    flag = "rareZombiesOnly",
    callback = function(value)
        ZombieESPSettings.RareOnly = value
        for _, zombie in ipairs(workspace.Zombies.Mobs:GetChildren()) do
            RemoveZombieESP(zombie)
            if zombie:IsA("Model") then
                CreateZombieESP(zombie)
            end
        end
    end,
})

sections.Section1:AddSlider({
    text = "Zombie ESP Distance",
    flag = "zombieESPDistance",
    suffix = " studs",
    value = ZombieESPSettings.MaxDistance,
    min = 1000,
    max = 10000,
    increment = 100,
    callback = function(value)
        ZombieESPSettings.MaxDistance = value
    end,
})



local function trim(s)
    return s:match("^%s*(.-)%s*$")
end


local function getMappedOptions(folderName, filterEquipSlot)
    local folder = game:GetService("ReplicatedStorage").ItemData[folderName]
    if not folder then
        warn("Folder not found: " .. folderName)
        return {}, {}
    end

    local displayList = {}
    local mapping = {}
    for _, moduleScript in ipairs(folder:GetChildren()) do
        if moduleScript:IsA("ModuleScript") then
            local success, data = pcall(require, moduleScript)
            if success and data then
                local isSpecial = data.EventItem or data.LegacyItem or data.RareItem or data.SpecialItem
                if isSpecial then
                    if filterEquipSlot then
                        if data.EquipSlot == filterEquipSlot and data.DisplayName then
                            local disp = trim(data.DisplayName)
                            mapping[disp] = trim(moduleScript.Name)
                            table.insert(displayList, disp)
                            print("Found [" .. filterEquipSlot .. "] option (DisplayName):", disp)
                        end
                    else
                        if data.DisplayName then
                            local disp = trim(data.DisplayName)
                            mapping[disp] = trim(moduleScript.Name)
                            table.insert(displayList, disp)
                            print("Found option in folder " .. folderName .. " (DisplayName):", disp)
                        end
                    end
                end
            else
                warn("ModuleScript " .. moduleScript.Name .. " failed to load or has invalid data.")
            end
        end
    end
    table.sort(displayList)
    return displayList, mapping
end

local topDisplay, topMapping = getMappedOptions("Clothing\013", "Top")
local bottomDisplay, bottomMapping = getMappedOptions("Clothing\013", "Bottom")

local hatDisplay, hatMapping = getMappedOptions("Hats\013")
local vestDisplay, vestMapping = getMappedOptions("Vests\013")
local beltDisplay, beltMapping = getMappedOptions("Belts\013")

print("Top display options:", table.concat(topDisplay, ", "))
print("Bottom display options:", table.concat(bottomDisplay, ", "))
print("Hat display options:", table.concat(hatDisplay, ", "))
print("Vest display options:", table.concat(vestDisplay, ", "))
print("Belt display options:", table.concat(beltDisplay, ", "))

local selectedClothes = {
    Top = (#topDisplay > 0 and topMapping[topDisplay[1]]) or "None",
    Bottom = (#bottomDisplay > 0 and bottomMapping[bottomDisplay[1]]) or "None",
    Hat = (#hatDisplay > 0 and hatMapping[hatDisplay[1]]) or "None",
    Vest = (#vestDisplay > 0 and vestMapping[vestDisplay[1]]) or "None",
    Belt = (#beltDisplay > 0 and beltMapping[beltDisplay[1]]) or "None",
}

local loadoutTab = Window:AddTab("Loadout")
local loadoutSection = loadoutTab:AddSection("Clothing", 1)

loadoutSection:AddList({
    text = "Select Top",
    flag = "selectTop",
    values = topDisplay,
    callback = function(value)
        selectedClothes.Top = topMapping[value]
        print("Selected Top (DisplayName):", value, "-> Module Name:", selectedClothes.Top)
    end
})

loadoutSection:AddList({
    text = "Select Bottom",
    flag = "selectBottom",
    values = bottomDisplay,
    callback = function(value)
        selectedClothes.Bottom = bottomMapping[value]
        print("Selected Bottom (DisplayName):", value, "-> Module Name:", selectedClothes.Bottom)
    end
})

loadoutSection:AddList({
    text = "Select Hat",
    flag = "selectHat",
     multi = false,
    open = true,
    values = hatDisplay,
    callback = function(value)
        selectedClothes.Hat = hatMapping[value]
        print("Selected Hat (DisplayName):", value, "-> Module Name:", selectedClothes.Hat)
    end
})

loadoutSection:AddList({
    text = "Select Vest",
    flag = "selectVest",
    values = vestDisplay,
    callback = function(value)
        selectedClothes.Vest = vestMapping[value]
        print("Selected Vest (DisplayName):", value, "-> Module Name:", selectedClothes.Vest)
    end
})

loadoutSection:AddList({
    text = "Select Belt",
    flag = "selectBelt",
    values = beltDisplay,
     multi = false,
    open = true,
    callback = function(value)
        selectedClothes.Belt = beltMapping[value]
        print("Selected Belt (DisplayName):", value, "-> Module Name:", selectedClothes.Belt)
    end
})

loadoutSection:AddButton({
    text = "Equip Clothing Loadout",
    callback = function()
        local Creator = require(game:GetService("ReplicatedStorage").Client.Abstracts.Interface.MainMenuClasses.TabClasses.Creator)
        local setEquipSlot = getupvalue(Creator, 34)
        
        print("Equipping with:")
        print(" Top: " .. selectedClothes.Top)
        print(" Bottom: " .. selectedClothes.Bottom)
        print(" Hat: " .. selectedClothes.Hat)
        print(" Vest: " .. selectedClothes.Vest)
        print(" Belt: " .. selectedClothes.Belt)
        
        setEquipSlot("Top", { Status = "Unlocked", Name = selectedClothes.Top }, true)
        setEquipSlot("Bottom", { Status = "Unlocked", Name = selectedClothes.Bottom }, true)
        setEquipSlot("Hat", { Status = "Unlocked", Name = selectedClothes.Hat }, true)
        setEquipSlot("Vest", { Status = "Unlocked", Name = selectedClothes.Vest }, true)
        setEquipSlot("Belt", { Status = "Unlocked", Name = selectedClothes.Belt }, true)
        
        print("Selected clothing loadout equipped!")
    end
})



if myList and myList.Container and #myList.values > myList.max then
    local scrollingContainer = Instance.new("ScrollingFrame")
    scrollingContainer.BackgroundTransparency = 1
    scrollingContainer.Size = UDim2.new(1,0,0, myList.max * 30)
    scrollingContainer.CanvasSize = UDim2.new(0, 0, 0, #myList.values * 30)
    scrollingContainer.ScrollBarThickness = 6
    scrollingContainer.Parent = myList.Container
    scrollingContainer.Name = "ScrollingContainer"
    
    for _, child in ipairs(myList.Container:GetChildren()) do
        if child ~= scrollingContainer then
            child.Parent = scrollingContainer
        end
    end
    
end




local InteractHeartbeat, FindItemData
for Index, Table in pairs(getgc(true)) do
    if type(Table) == "table" and rawget(Table, "Rate") == 0.05 then
        InteractHeartbeat = Table.Action
        FindItemData = getupvalue(InteractHeartbeat, 11)
        if InteractHeartbeat and FindItemData then break end
    end
end

if InteractHeartbeat and FindItemData then
    setupvalue(InteractHeartbeat, 11, function(...)
        if GunModSettings.InstantSearchEnabled then 
            local ReturnArgs = {FindItemData(...)}
            if ReturnArgs[4] then ReturnArgs[4] = 0 end
            return unpack(ReturnArgs)
        end
        return FindItemData(...)
    end)
end

sections.Section5:AddToggle({
    enabled = true,
    text = "Instant Search",
    flag = "instantSearchEnabled",
    callback = function(Value)
        GunModSettings.InstantSearchEnabled = Value
    end
})


local miscTab = Window:AddTab("Misc")
local miscZombieSection = miscTab:AddSection("Zombies", 1)

local ZombieCircleSettings = {
	Enabled = false,
	Radius = 10,     
	Speed = 500      
}

miscZombieSection:AddToggle({
	enabled = true,
	text = "Zombie Circle",
	flag = "zombieCircleEnabled",
	callback = function(value)
		ZombieCircleSettings.Enabled = value
	end,
})

miscZombieSection:AddSlider({
	text = "Zombie Circle Radius",
	flag = "zombieCircleRadius",
	suffix = " studs",
	value = ZombieCircleSettings.Radius,
	min = 7,
	max = 100,
	increment = 1,
	callback = function(v)
		ZombieCircleSettings.Radius = v
	end,
})

miscZombieSection:AddSlider({
	text = "Zombie Circle Speed",
	flag = "zombieCircleSpeed",
	suffix = " rpm",
	value = ZombieCircleSettings.Speed,
	min = 1,
	max = 10000,
	increment = 1,
	callback = function(v)
		ZombieCircleSettings.Speed = v
	end,
})

local miscMovementSection = tabs.Tab3:AddSection("Movement", 3)


local FlySettings = {
    Enabled = false,
    Speed = 0.15,
    LastTick = tick(),
    StateIndex = 1,  
    LastStateUpdate = tick(),
    LastGroundUpdate = tick()
}

miscMovementSection:AddToggle({
    enabled = true,
    text = "Fly",
    flag = "flyEnabled",
    callback = function(value)
        FlySettings.Enabled = value
    end
})

miscMovementSection:AddSlider({
    text = "Fly Speed",
    flag = "flySpeed",
    suffix = " studs",
    value = 0.09,
    min = 0.05,
    max = 0.09,
    increment = 0.01,
    callback = function(v)
        FlySettings.Speed = v
    end
})

local states = {
    {state = "Climbing", flag = "Climbing"},
    {state = "Vaulting", flag = "Vaulting"},
    {state = "SprintSwimming", flag = "Swimming"}
}

local function updateState(char)
    char.Climbing = false
    char.Vaulting = false
    char.Swimming = false
    
    FlySettings.StateIndex = (FlySettings.StateIndex % #states) + 1
    local currentState = states[FlySettings.StateIndex]
    
    char.MoveState = currentState.state
    char[currentState.flag] = true
    
    char.RubberBandReset = 0
    char.LastMoveTime = workspace:GetServerTimeNow()
    char.LastGroundTime = workspace:GetServerTimeNow()
    char.LastGroundPos = char.RootPart.Position
end

RunService.Heartbeat:Connect(function()
    if not FlySettings.Enabled then return end
    
    local char = PlayerClass.Character
    if not char or not char.RootPart then return end
    
    if tick() - FlySettings.LastTick > 0.1 then
        updateState(char)
        FlySettings.LastTick = tick()
    end
    
    local direction = Vector3.zero
    local speed = FlySettings.Speed
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        direction += Workspace.CurrentCamera.CFrame.LookVector * speed
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        direction -= Workspace.CurrentCamera.CFrame.LookVector * speed
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        direction -= Workspace.CurrentCamera.CFrame.RightVector * speed
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        direction += Workspace.CurrentCamera.CFrame.RightVector * speed
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        direction += Vector3.new(0, 1, 0) * speed
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        direction -= Vector3.new(0, 1, 0) * speed
    end
    
    if direction.Magnitude > 0 then
        for i = 1, 3 do
            local increment = direction * (1/3)
            

            local randomOffset = Vector3.new(
                math.random(-5, 5) / 100,
                math.random(-5, 5) / 100,
                math.random(-5, 5) / 100
            )
            
            char.RootPart.CFrame += increment + (randomOffset * 0.01)
            char.RootPart.AssemblyLinearVelocity = (increment.Unit + randomOffset) * 0.1
            
            task.wait(math.random(1, 2) / 100)
        end
    end
end)






RunService.RenderStepped:Connect(UpdateCorpseESP)






LocalPlayer.CharacterAdded:Connect(hookAnimations)




Players.PlayerAdded:Connect(AddESP)
Players.PlayerRemoving:Connect(RemoveChams)


