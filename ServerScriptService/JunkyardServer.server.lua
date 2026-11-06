-- Junkyard simulator server gameplay, persistence, and remote validation.
-- Place in ServerScriptService as JunkyardServer.server.lua.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local store = DataStoreService:GetDataStore("JunkyardSimulator_v1")
local remoteFolder = ReplicatedStorage:FindFirstChild("JunkyardRemotes") or Instance.new("Folder")
remoteFolder.Name = "JunkyardRemotes"
remoteFolder.Parent = ReplicatedStorage
local action = remoteFolder:FindFirstChild("Action") or Instance.new("RemoteFunction")
action.Name = "Action"
action.Parent = remoteFolder
local notice = remoteFolder:FindFirstChild("Notice") or Instance.new("RemoteEvent")
notice.Name = "Notice"
notice.Parent = remoteFolder

local world = workspace:FindFirstChild("JunkyardWorld") or Instance.new("Folder")
world.Name = "JunkyardWorld"
world.Parent = workspace
local scrapFolder = world:FindFirstChild("Scrap") or Instance.new("Folder")
scrapFolder.Name = "Scrap"
scrapFolder.Parent = world
local spawnPoint = workspace:FindFirstChildWhichIsA("SpawnLocation")
local MAX_CAPACITY = 20
local BASE_RANGE = 14
local scrapTypes = {
 {name="Metal Can", value=5, color=Color3.fromRGB(160,170,176), size=Vector3.new(1,1,1)},
 {name="Old Tire", value=12, color=Color3.fromRGB(35,35,38), size=Vector3.new(2,1,2)},
 {name="Copper Coil", value=25, color=Color3.fromRGB(190,105,58), size=Vector3.new(1.2,1.2,1.2)},
 {name="Engine Part", value=60, color=Color3.fromRGB(90,110,120), size=Vector3.new(1.8,1.4,1.5)},
}
local profiles = {}
local function tell(player, text) notice:FireClient(player, text) end
local function spawnScrap()
 if #scrapFolder:GetChildren() >= 70 then return end
 local data = scrapTypes[math.random(1,#scrapTypes)]
 local part = Instance.new("Part")
 part.Name = data.name
 part.Size = data.size
 part.Color = data.color
 part.Material = Enum.Material.Metal
 part.Anchored = true
 part.CanCollide = true
 part.Position = Vector3.new(math.random(-90,90), 2, math.random(-90,90))
 part:SetAttribute("ScrapValue", data.value)
 part:SetAttribute("ScrapName", data.name)
 part.Parent = scrapFolder
 local prompt = Instance.new("ProximityPrompt")
 prompt.ActionText = "Collect"
 prompt.ObjectText = data.name
 prompt.HoldDuration = 0.25
 prompt.MaxActivationDistance = 10
 prompt.Parent = part
 prompt.Triggered:Connect(function(player)
  local profile = profiles[player]
  if not profile or not part.Parent then return end
  local capacity = MAX_CAPACITY + profile.BagLevel * 10
  if profile.scrap >= capacity then tell(player, "Your bag is full. Sell your scrap first!") return end
  profile.scrap += 1
  profile.scrapValue += data.value
  part:Destroy()
  tell(player, "Collected " .. data.name .. " (" .. profile.scrap .. "/" .. capacity .. ")")
 end)
end
for i=1,45 do spawnScrap() end

task.spawn(function()
 while true do task.wait(2.5); spawnScrap() end
end)

local function save(player)
 local p = profiles[player]
 if not p then return end
 local data = {Cash=p.cash, BagLevel=p.BagLevel, ToolLevel=p.ToolLevel}
 pcall(function() store:SetAsync("u"..player.UserId, data) end)
end
local function makeStats(player, p)
 local leaderstats = Instance.new("Folder")
 leaderstats.Name = "leaderstats"
 leaderstats.Parent = player
 local cash = Instance.new("IntValue")
 cash.Name = "Cash"
 cash.Value = p.cash
 cash.Parent = leaderstats
end
Players.PlayerAdded:Connect(function(player)
 local data
 local ok, result = pcall(function() return store:GetAsync("u"..player.UserId) end)
 if ok and type(result) == "table" then data=result end
 local p = {cash=math.max(0, tonumber(data and data.Cash) or 0), scrap=0, scrapValue=0,
  BagLevel=math.clamp(tonumber(data and data.BagLevel) or 0,0,25), ToolLevel=math.clamp(tonumber(data and data.ToolLevel) or 0,0,25), lastAction=0}
 profiles[player]=p
 makeStats(player,p)
end)
Players.PlayerRemoving:Connect(function(player) save(player); profiles[player]=nil end)

game:BindToClose(function()
 for _, player in ipairs(Players:GetPlayers()) do save(player) end
 if RunService:IsStudio() then task.wait(1) end
end)
local function updateCash(player,p)
 local stats=player:FindFirstChild("leaderstats")
 if stats and stats:FindFirstChild("Cash") then stats.Cash.Value=p.cash end
end
local function price(kind, level)
 if kind == "Bag" then return 100 * (level+1)^2 end
 return 150 * (level+1)^2
end
action.OnServerInvoke=function(player, command)
 local p=profiles[player]
 if not p or type(command)~="string" then return {ok=false,message="Please try again."} end
 if os.clock()-p.lastAction < 0.15 then return {ok=false,message="Wait a moment."} end
 p.lastAction=os.clock()
 if command=="GetState" then
  return {ok=true,cash=p.cash,scrap=p.scrap,scrapValue=p.scrapValue,capacity=MAX_CAPACITY+p.BagLevel*10,bagLevel=p.BagLevel,toolLevel=p.ToolLevel,bagPrice=price("Bag",p.BagLevel),toolPrice=price("Tool",p.ToolLevel)}
 elseif command=="Sell" then
  if p.scrap==0 then return {ok=false,message="Collect some scrap before selling."} end
  local total=p.scrapValue
  p.cash+=total; p.scrap=0; p.scrapValue=0; updateCash(player,p)
  return {ok=true,message="Sold your scrap for $"..total.."!"}
 elseif command=="BuyBag" or command=="BuyTool" then
  local isBag=command=="BuyBag"
  local key=isBag and "BagLevel" or "ToolLevel"
  local cost=price(isBag and "Bag" or "Tool",p[key])
  if p[key]>=25 then return {ok=false,message="Upgrade level is already maxed."} end
  if p.cash<cost then return {ok=false,message="You need $"..cost.." for this upgrade."} end
  p.cash-=cost; p[key]+=1; updateCash(player,p)
  return {ok=true,message=(isBag and "Bag" or "Tool").." upgraded to level "..p[key].."!"}
 end
 return {ok=false,message="Unknown action."}
end
