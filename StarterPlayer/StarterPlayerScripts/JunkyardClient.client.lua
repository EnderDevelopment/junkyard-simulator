-- Junkyard simulator client HUD and interaction buttons.
-- Place in StarterPlayer > StarterPlayerScripts as JunkyardClient.client.lua.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("JunkyardRemotes")
local action = remotes:WaitForChild("Action")
local notice = remotes:WaitForChild("Notice")

local gui = Instance.new("ScreenGui")
gui.Name = "JunkyardHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local function label(parent, text, size, position, color)
 local item=Instance.new("TextLabel")
 item.BackgroundTransparency=1; item.Text=text; item.TextColor3=color or Color3.new(1,1,1)
 item.TextSize=size; item.Font=Enum.Font.GothamBold; item.Size=position[1]; item.Position=position[2]
 item.TextXAlignment=Enum.TextXAlignment.Left; item.Parent=parent
 return item
end
local panel=Instance.new("Frame")
panel.Name="JunkyardPanel"; panel.BackgroundColor3=Color3.fromRGB(27,31,35); panel.BackgroundTransparency=.08
panel.Size=UDim2.fromOffset(280,190); panel.Position=UDim2.fromOffset(18,18); panel.Parent=gui
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,12)
local title=label(panel,"JUNKYARD SHIFT",20,{UDim2.new(1,-28,0,30),UDim2.fromOffset(14,10)},Color3.fromRGB(255,190,72))
local status=label(panel,"Loading...",15,{UDim2.new(1,-28,0,70),UDim2.fromOffset(14,48)},Color3.fromRGB(225,230,232))
local message=label(panel,"Collect scrap around the yard.",13,{UDim2.new(1,-28,0,36),UDim2.fromOffset(14,122)},Color3.fromRGB(168,180,187))
local function button(text, x, callback)
 local b=Instance.new("TextButton")
 b.Text=text; b.TextSize=13; b.Font=Enum.Font.GothamBold; b.TextColor3=Color3.new(1,1,1)
 b.BackgroundColor3=Color3.fromRGB(54,91,74); b.Size=UDim2.fromOffset(78,30); b.Position=UDim2.fromOffset(x,155); b.Parent=panel
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,7); b.Activated:Connect(callback); return b
end
local sell=button("SELL",14,function() end)
local bag=button("BAG",101,function() end)
local tool=button("TOOL",188,function() end)
local function refresh()
 local result=action:InvokeServer("GetState")
 if not result.ok then status.Text=result.message; return end
 status.Text=string.format("Cash: $%d\nScrap: %d / %d",result.cash,result.scrap,result.capacity)
 bag.Text="BAG $"..result.bagPrice; tool.Text="TOOL $"..result.toolPrice
end
local function doAction(command)
 local result=action:InvokeServer(command)
 if result.message then message.Text=result.message end
 refresh()
end
sell.Activated:Connect(function() doAction("Sell") end)
bag.Activated:Connect(function() doAction("BuyBag") end)
tool.Activated:Connect(function() doAction("BuyTool") end)
notice.OnClientEvent:Connect(function(text) message.Text=text; refresh() end)
task.spawn(function() while gui.Parent do refresh(); task.wait(3) end end)
