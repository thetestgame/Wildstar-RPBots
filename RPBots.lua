------------------------------------------------------------------------------------------------
-- 										RPBots - V.1.0.0
------------------------------------------------------------------------------------------------
--[[
The MIT License (MIT)

Copyright (c) 2015 Jordan Maxwell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
------------------------------------------------------------------------------------------------

require "Unit"
require "GameLib"
require "Window"
require "ApolloTimer"
require "ChatSystemLib"
require "ChatChannelLib"
require "PlayerPathLib"
require "ScientistScanBotProfile"
require "ICComm"
require "ICCommLib"
require "GameLib"
require "CollectiblesLib"
require "Sound"
 
-----------------------------------------------------------------------------------------------
-- RPBots Module Definition
-----------------------------------------------------------------------------------------------
local RPBots = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("RPBots", false)

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local chanRPB = "__RPB__" 

local dbDefaults = {
  profile = {
    debugMode = false,
	ignoreWhitelist = true,
	nameplates = {
		drawDistance = 150,
	},
	scanbot = {
		enabled = true,
		autoTalk = true,
		deployMessages = true,
		despawnMessages = true,
		customizeMessages = true,
		scanMessages = true,
		scanInfo = false,
		autoSummon = true,
	},
	bots = {},
    dialog = {
		scanbot = {
			greetings = {
				"Hello!",
				"Greetings.",
				"Hello again, master.",
				"Ready to work!",
				"Systems online.",
				"Another fine day.",
				"It's good to be back."
			},
			goodbyes = {
				"Goodbye!",
				"Until next time, master.",
				"I know when I'm not wanted.",
				"Powering down.",
				"Goodbye, master.",
				"I shall miss you.",
				"You got it."
			},
			call = {
				"Yes?",
				"What can I do for you?",
				"Yes master?",
				"Yeah boss?",
				"Hm?",
				"Yeah?",
				"What do you need?"
			},
			customizes = {
				"Oh, I feel stylish.",
				"I'm sure the other bots will be jealous.",
				"Thank you, master!",
				"I shall wear it with pride, master.",
				"Thanks!",
				"Error: Critical levels of style reached.",
				"My transistors are positively glowing with pride."
			},
			scans = {
				"Oooh, how interesting!",
				"Oh, that thing?",
				"It doesn't look that interesting.",	
				"Let me show you what I found!",
				"Fascinating, master.",
				"Oh, I see now!",
				"I found some interesting data.",
				"Data processed and stored.",
				"Scan completed in 2.71 seconds.",
				"Processing data...",
				"A fascinating specimen."
			},
		},
    },
  }
}
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

function RPBots:OnInitialize()
	self.xmlDoc = XmlDoc.CreateFromFile("RPBots.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-- Called when player has loaded and entered the world
function RPBots:OnEnable()

end

function RPBots:OnDisable()

end

function RPBots:OnDependencyError(strDep, strError)
  return false
end

function RPBots:SetupComms()
	self.Comm = ICCommLib.JoinChannel(chanRPB, ICCommLib.CodeEnumICCommChannelType.Global)
	self.Comm:SetJoinResultFunction("OnJoinResult", self)
	self.Comm:SetReceivedMessageFunction("OnMessageReceived", self)
	self.Comm:SetSendMessageResultFunction("OnMessageSent", self)
	self.Comm:SetThrottledFunction("OnMessageThrottled", self)
	if self.db.profile.debugMode then
		print "Comms have been successfully setup."
	end	
end

local PacketFactory={}

function PacketFactory:new(plugin)
    o = {}
    setmetatable(o, self)
    self.__index = self 
	self.plugin = plugin
	return 0
end

function PacketFactory:createChatPacket(b, n, msg, r, ch, loc, w)
	local packetTable = {
		type="chat",
		bot=b,
		name=n,
		message=msg,
		range=r,
		channel=ch,
		location={pos=loc, world=w},
	}
	return plugin.json.encode(packetTable)
end

function PacketFactory:createNameplateRegisterPacket(bot, nameplate)
	local packetTable = {
		type="nameplate",
		bot=b,
	}	
	return plugin.json.encode(packetTable)
end

-----------------------------------------------------------------------------------------------
-- RPBots RPBot class
-----------------------------------------------------------------------------------------------

local RPBot = {}

function RPBot:new(plugin, unit, customName)
    o = {}
    setmetatable(o, self)
    self.__index = self 
	self.plugin = plugin
	self.unit = unit
	self.botname = unit:GetName() or customName
	self.listeningTo = nil
	self.modules = {}
	self.hasCustomName = (self.botname ~= unit:GetName())
	if self.hasCustomName then
		self.nameplate = BotNamePlate:new(plugin, self)
	end
	if self.plugin.db.profile.debugMode then
		Print("Registered bot: " ..self.botname)
	end
    return o
end

function RPBot:say(text, range)
	local location = "(0,0,0)"
	local channel = "[Say]"
	local packet = self.plugin.packetFactory:createChatPacket(true, self.botname, message, range, channel, location, "General")
	self.plugin:SendMessage(packet)
	self.unit:AddTextBubble(message)
end

function RPBot:processInput(text, sender)
	local moduleActive = false
	if #self.modules > 0 then
		for module in self.modules do
			if module:IsValid(text) then
				module:ProcessInput(text, sender)
				moduleActive = true
				break
			end
		end
	end
	if moduleActive then
	
	end
end

function RPBot:RegisterModule(module)
	module.bot = self
	table.insert(self.modules, module)
end

function RPBot:StartLisening(target)

end

function RPBot:ResetLisening()

end

function RPBot:StopLisening()

end

-----------------------------------------------------------------------------------------------
-- RPBots RPBot Module class
-----------------------------------------------------------------------------------------------

local RPBotModule = {}

function RPBotModule:new(plugin)
    o = {}
    setmetatable(o, self)
    self.__index = self 
	self.plugin = plugin
	self.bot = nil
	self:Init() -- Call api startup function
    return o
end

function RPBotModule:Init()

end

function RPBotModule:ProcessInput(text, sender)

end

function RPBotModule:IsValid(input)
	return false
end

function RPBotModule:IsReady()
	return self.bot ~= nil
end


-----------------------------------------------------------------------------------------------
-- RPBots PetLibrary class
---------------------------------------------------------------------------------------

local PetLibrary = {}

function PetLibrary:new(plugin)
    o = {}
    setmetatable(o, self)
    self.__index = self 
	self.plugin = plugin
	
	Apollo.RegisterEventHandler("AbilityBookChange", "UpdatePetList", self)
	
	self.petList = CollectiblesLib.GetVanityPetList()
	self.activePet = nil
	return o
end

function PetLibrary:SummonPet(petId)
	if GameLib.GetPlayerUnit():IsCasting() then
		return
	end
	GameLib.SummonVanityPet(nPetId)
end

function PetLibrary:OnPetSummoned(petId)
	
end

function PetLibrary:UpdatePetList()

end

-----------------------------------------------------------------------------------------------
-- RPBots SoundLibrary class
-----------------------------------------------------------------------------------------------

local SoundLibrary = {}

function SoundLibrary:new(plugin)
    o = {}
    setmetatable(o, self)
    self.__index = self 
	self.plugin = plugin
	
	--local keyset={}
	--local n=0
	--local list = ""
	
	--for k,v in pairs(Sound) do
	--  n=n+1
	--  keyset[n]=k
	--  list = list ..", " ..k
	--end
	--Print(list)
	
	return o
end

-----------------------------------------------------------------------------------------------
-- RPBots Nameplate class
-----------------------------------------------------------------------------------------------

local BotNameplate = {}

function BotNameplate:new(plugin, bot)
    o = {}
    setmetatable(o, self)
    self.__index = self 
	self.plugin = plugin
	self.bot = bot

	self.window = nil
	self.unit = self.bot.unit
	self.isVisible = false
	self.isMyTarget = false
	
	-- Create nameplate and register it
	local unitId = self.bot.unit:GetId()
	
	if self.plugin.nameplates[unitId] ~= nil and self.plugin.db.profile.debugMode then
		Print(unitId .. " - nameplate already added")
		return
	end
	
	local nameplate = Apollo.LoadForm(self.uXml, "Nameplate", "InWorldHudStratum", self)	
	nameplate:SetUnit(self.unit)

	local wChildName = nameplate:FindChild("Name")
	wChildName:SetText(self.unit:GetName())
	wChildName:SetTextColor(self.unit:GetNameplateColor())
	
	self.plugin.nameplates[unitId] = o
	-- {
	--	window = nameplate,
	--	unit = unit,
	--	isVisible = false,
	--	isMyTarget = false,
	--}
	
	self:UpdateNameplate(unitId)

	-- Send register packet
	local packet = self.plugin.packetFactory:createNameplateRegisterPacket(self.bot, self)
	self.plugin:sendMessage(packet)
	
	return o
end


function BotNameplate:Remove()
	local unitId = self.bot.unit:GetId()
	if self.plugin.nameplates[unitId] == nil and self.plugin.db.profile.debugMode then
		Print(unitId .. " - nameplate already removed")
		return
	end
	
	self.plugin.nameplates[unitId].window:Destroy()
	self.plugin.nameplates[unitId] = nil
end

function BotNameplate:Update()
	local unitId = self.bot.unit:GetId()
	local bIsVisible = self:ShouldNameplateBeVisible(unitId)
	if self.isVisible == bIsVisible then
		return
	end
	self.window:FindChild("FlickerProtector"):Show(bIsVisible)
	self.isVisible = bIsVisible
end

function BotNameplate:ShouldNameplateBeVisible(nUnitId)
	return self.window:IsOnScreen() and not self.window:IsOccluded() and (self.plugin:GetDistanceTo(tData.unit) <= self.db.nameplates.drawDistance or self.isMyTarget)
end

function BotNameplate:UpdateTargetStatus(nUnitId, bIsTarget)
	self.isMyTarget = bIsTarget
	self:Update()
end

-----------------------------------------------------------------------------------------------
-- RPBots ChatLibrary class
-----------------------------------------------------------------------------------------------

local ChatLibrary = {}

function ChatLibrary:new(plugin)
    o = {}
    setmetatable(o, self)
    self.__index = self 
	self.plugin = plugin
	return o
end

function ChatLibrary:getScanbotGreeting()
	local greetings = self.plugin.db.profile.dialog.scanbot.greetings
	return greetings[math.random(1, #greetings)]
end

function ChatLibrary:getScanbotGoodbye()
	local goodbyes = self.plugin.db.profile.dialog.scanbot.goodbyes
	return goodbyes[math.random(1, #goodbyes)]
end

function ChatLibrary:getScanbotCustomize()
	local customizes = self.plugin.db.profile.dialog.scanbot.customizes
	return customizes[math.random(1, #customizes)]
end

function ChatLibrary:getScanbotScan()
	local scans = self.plugin.db.profile.dialog.scanbot.scans
	return scans[math.random(1, #scans)]
end

function ChatLibrary:getGenericBotSaying(bot, type)	
	local sayings = self.plugin.db.profile.dialog[bot.name][type]
	return sayings[math.random(1, #sayings)]
end

function ChatLibrary:addGenericBotSaying(bot, type, message)
	local field = self.plugin.db.profile.dialog[bot.name][type]
	if field == nil then
		local fix = {[bot.name]={[type]={}}
		table.insert(self.plugin.db.profile.dialog, fix)
	end
	table.insert(self.plugin.db.profile.dialog[bot.name][type], message)
end

function ChatLibrary:addScanbotBotSaying(type, message)
	local field = self.plugin.db.profile.dialog.scanbot[type]
	if field == nil then
		local fix = {scanbot={[type]={}}
		table.insert(self.plugin.db.profile.dialog, fix)
	end
	table.insert(self.plugin.db.profile.dialog.scanbot[type], message)
end

-----------------------------------------------------------------------------------------------
-- RPBots BotLibrary class
-----------------------------------------------------------------------------------------------

local BotsLibrary = {}

function BotsLibrary:new(plugin)
    o = {}
    setmetatable(o, self)
    self.__index = self 
	self.plugin = plugin
	self.scanbot = nil
	self.bots = self.plugin.db.profile.bots
	
	-- attempt to load saved bots
	--local saved = tSavedData.RPBots
	--for bot in saved do	
	--end
    return o
end

function BotsLibrary:hasScanbot() 
	return self.scanbot ~= nil
end

function BotsLibrary:registerScanbot(scanbot)
	local scan = RPBot:new(self.plugin, scanbot)
	self.scanbot = scan
	if self.plugin.db.profile.debugMode then
		print("Registered scanbot!")
	end
	table.insert(self.bots, scan)
	return scan
end

function BotsLibrary:registerNormalBot(bot)
	local b = RPBot:new(self.plugin, bot)
	table.insert(self.bots, b)
	table.insert(self.plugin.db.profile.bots, b)
	return b
end

function BotLibrary:DeactiveNormalBot(bot)
	
end

function BotLibrary:DeactiveScanbot()
	if self.scanbot == nil then return end
	table.remove(self.botts, self.scanbot)
	self.scanbot = nil
end

function BotsLibrary:getBotByName(name)
	local selected = nil
	if #self.bots > 0 then
		for id,bot in pairs(self.bots) do
			if bot.botname == name then
				selected = bot
			end
		end
	end
	return selected
end

function BotsLibrary:HasBots()
	return #self.bots > 0
end

-----------------------------------------------------------------------------------------------
-- RPBots OnDocLoaded
-----------------------------------------------------------------------------------------------
function RPBots:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "BotListForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
		self.wndChat = Apollo.LoadForm(self.xmlDoc, "BotChatForm", nil, self)
		if self.wndChat == nil then
			Apollo.AddAddonErrorText(self, "Could not load the chat window for some reason.")
			return
		end	
		
		self.wndCreate = Apollo.LoadForm(self.xmlDoc, "BotCreateForm", nil, self)
		if self.wndCreate == nil then
			Apollo.AddAddonErrorText(self, "Could not load the create window for some reason.")
			return
		end				
		
		self.wndCreate:Show(false, true)
		self.wndChat:Show(false, true)
	    self.wndMain:Show(false, true)
		self.xmlDoc = nil
		
		self.nameplates = {}
		--self.unitsBacklog = {}
		self.playerUnit = nil

		-- Register libraries
		self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, dbDefaults)
		self.json = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage
		self.DLG = Apollo.GetPackage("Gemini:LibDialog-1.0").tPackage
		
		-- Register plugin libraries
		self.botLibrary = BotsLibrary:new(self)
		self.chatLibrary = ChatLibrary:new(self)
		self.soundLibrary = SoundLibrary:new(self)
		self.packetFactory = PacketFactory:new(self)
	
		-- Setup comms
		self:SetupComms()

		Apollo.RegisterSlashCommand("rpb", "OnRPBotsOn", self)
		
		Apollo.RegisterEventHandler("PlayerPathScientistScanBotDeployed", "OnScanbotDeploy", self)
		Apollo.RegisterEventHandler("PlayerPathScientistScanBotDespawned", "OnScanbotDespawned", self)
		Apollo.RegisterEventHandler("PlayerPathScientistScanData", "OnScanStart", self)
		Apollo.RegisterEventHandler("PetCustomizationUpdated", "OnScanbotCustomize", self)
		Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self)
		Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
		Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
		Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)
		Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
		
		Apollo.CreateTimer("RPBots_Refresh", 0.3, true)
		Apollo.RegisterTimerHandler("RPBots_Refresh", "OnTimerRefresh", self)
		
		-- Disable Brobots if found
		-- TODO add this
		
		-- Attempt to grab any active scanbots if none is set in the library
		if self.db.profile.scanbot.enabled and self.botLibrary.scanbot == nil then
			-- Update the bot unit and name variables
			local ScanBotUnit = PlayerPathLib:ScientistGetScanBotUnit()
			if ScanBotUnit ~= nil then
				self.botLibrary:registerScanbot(ScanBotUnit)
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- RPBots General Functions
-----------------------------------------------------------------------------------------------

function RPBots:OpenChatWindow(bot) 
	self.activeChatBot = bot
	bot.autoTalk = false
	self.wndChat:Invoke()
end

function RPBots:OpenCreateWindow()
	local target = nil
	
	self.wndCreate:FindChild("BotName"):SetText(target:GetName())
	self.wndCreate:FindChild("BotPreview"):SetCostumeToCreatureId(target:getId())
	self.wndCreate:FindChild("BotPreview"):SetModelSequence(150)
	
	self.wndCreate:Invoke()
end

-----------------------------------------------------------------------------------------------
-- RPBots Event Functions
-----------------------------------------------------------------------------------------------

-- on SlashCommand "/rpb"
function RPBots:OnRPBotsOn(cmdInput, argInput)
	local args = RPBots:strsplit(" ", argInput)
	if args[1] == "chat" then
		local bot = self.botLibrary:getBotByName(args[2])
		if args[3] ~= "" and args[3] ~= nil and bot ~= nil then
			table.remove(args, 1)
			table.remove(args, 1)
			complete = ""
			for id,part in pairs(args) do
				complete = complete .. " " .. part
			end
			bot:say(complete, 10)
			return
		else
			if bot ~= nil then
				self:OpenChatWindow(bot)
			end
		end
		return
	elseif args[1] == "create" then
		self:OpenCreateWindow()
	end
	self.wndMain:Invoke() -- show the window
	self.wndCreate:Invoke()
end

function RPBots:isAuthorisedToSpeak(name)
	local contained = true
	return (name == GameLib.GetPlayerUnit():GetName()) or contained or self.db.profile.ignoreWhitelist
end

function RPBots:isLisioningChannel(name)
	return name == "Say"
end

-- ChatMessage event handler
function RPBots:OnChatMessage(channelCurrent, tMessage)
	-- Check things. Chat channel, speaker, and a bot is deployed. We're only interested in messages that meet these criteria.
	--[[
	if self:isLisioningChannel(channelCurrent:GetName()) then
		if self:isAuthorisedToSpeak(tMessage.strSender) then
			if self.botLibrary:HasBots() then
				local hasListener = false
				local activeBot = nil
				for id,bot in pairs(self.botLibrary.bots) do
					if bot.listeningTo == tMessage.strSender then
						hasListener = true
						activeBot = bot
						break
					end
				end
				local text = RPBots:RemovePunctuation(tMessage.arMessageSegments[1].strText)
				if hasListener then
					activeBot:processInput(text, tMessage.strSender)
				else
					local words = RPBots:strsplit(" ", text)
					if RPBots:CheckTextForBotNameAtStart(words) then
						for word in words do
							local bot = self.botLibrary:getBotByName(word)
							if bot ~= nil then
								activeBot = bot
								break
							end
						end
						-- Not bots were found in the message
						if activeBot == nil then
							return
						end
						
						-- Is the message only the bots name?
						if text ~= activeBot.name then
							activeBot:processInput(text, tMessage.strSender)
						end
						activeBot:StartListening(tMessage.strSender)
					end
				end
			end
		end
	end
	--]]
end

-- ScanBot deploy handler
function RPBots:OnScanbotDeploy()
	if self.db.profile.scanbot.enabled then
		-- Update the bot unit and name variables
		local ScanBotUnit = PlayerPathLib:ScientistGetScanBotUnit()
		self.botLibrary:registerScanbot(ScanBotUnit)
		if self.db.profile.scanbot.deployMessages then
			self.botLibrary.scanbot:say(self.chatLibrary:getScanbotGreeting(), 10)
		end
	end
end

-- ScanBot despawn handler
function RPBots:OnScanbotDespawned()
	if self.botLibrary:hasScanbot() and self.db.profile.scanbot.enabled then
		local scanbot = self.botLibrary.scanbot
		self.botLibrary.DeactiveScanbot()
		if self.db.profile.scanbot.despawnMessages then
			scanbot:say(self.chatLibrary:getScanbotGoodbye(), 10)
		end
	end
end

-- Scan begin handler
function RPBots:OnScanbotScanStart()
	if self.botLibrary:hasScanbot() and self.db.profile.scanbot.enabled then
		-- Update the bot name variables in case they were changed
		newName = self.botLibrary.scanbot.unit:GetName()
		self.botLibrary.scanbot.name = newName
		if self.db.profile.scanbot.scanMessages then
			self.botLibrary.scanbot:say(self.chatLibrary:getScanbotScan(), 10)
		end
	end
end

-- Pet customize updated handler
function RPBots:OnScanbotCustomize()
	if self.botLibrary:hasScanbot() and self.db.profile.scanbot.enabled then
		newName = self.botLibrary.scanbot.unit:GetName()
		if self.db.profile.scanbot.customizeMessages and self.botLibrary.scanbot.unit.botname ~= newName then
			self.botLibrary.scanbot:say(self.chatLibrary:getScanbotCustomize(), 10)
		end
		-- Update the bot name variables in case they were changed
		self.botLibrary.scanbot.name = newName
	end
end

function RPBots:OnChangeWorld()
	self.playerUnit = nil
end

function RPBots:OnUnitCreated(unit)
	--if self.playerUnit == nil then
	---	self.tUnitsBacklog[unit:GetId()] = unit
	---	return
	---end
	---if uUnit:GetType() ~= "Harvest" or uUnit:CanBeHarvestedBy(self.uPlayerUnit) ~= true or self.tNameplates[uUnit:GetId()] ~= nil then
	---	return
	---end	
	---self:AddNameplate(uUnit)
end

function RPBots:OnWorldLocationOnScreen(uHandler, uControl, bOnScreen)
	for plate in self.nameplates do
		if plate.unit:GetId() == uHandler:GetUnit():GetId() then
			self:UpdateNameplate(uHandler:GetUnit():GetId())
		end
	end
end

function RPBots:OnTargetUnitChanged(uUnit)
--[[
	if uUnit == nil then
		if self.nTargetId ~= nil then
			self:UpdateTargetStatus(self.nTargetId, false)
			self.nTargetId = nil
		end
		return
	end
	
	local nUnitId = uUnit:GetId()
	
	if self.nTargetId == nUnitId then
		return
	end
	
	if self.nTargetId ~= nil then
		self:UpdateTargetStatus(self.nTargetId, false)
	end
	
	self:UpdateTargetStatus(nUnitId, true)
	self.nTargetId = nUnitId
	--]]
end


-----------------------------------------------------------------------------------------------
-- BotListForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function RPBots:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function RPBots:OnListCancel()
	self.wndMain:Close() -- hide the window
end

-- when the create bot button is clicked
function RPBots:OnBotCreate()
	self:OpenCreateWindow() -- open the create window
	--self.wndMain:Close()
end	

-- when the delete bot button is clicked
function RPBots:OnBotDelete()
	local bot = nil
	if bot == nil then return end
	self.DLG:Register("ConfirmDialog", {
	    buttons = {
	      {
	        text = Apollo.GetString("CRB_Yes"),
	        OnClick = function(settings, data, reason)
	          	self.botLibrary:DeactivateNormalBot(bot)
				if self.db.profile.debugMode then
					Print(bot.botname.. " has been deleted.")
				end
	        end,
	      },
	      {
	        color = "Red",
	        text = Apollo.GetString("CRB_No"),
	        OnClick = function(settings, data, reason)
				--Nothing to do here.
	        end,
	      },
	    },
	    OnCancel = function(settings, data, reason)
	      --if reason == "timeout" then
	      --  Print("You can't decide?")
	      --end
	    end,
	    text = "Are you sure you want to delete " ..bot.botname.. "?",
	    duration = 30,
	    showWhileDead=true,
	})
end

-----------------------------------------------------------------------------------------------
-- BotChatForm Functions
-----------------------------------------------------------------------------------------------

-- when the Say button is clicked
function RPBots:OnSay()
	self.activeChatBot = nil
	self.wndChat:Close() -- hide the window
end

-- when the Cancel button is clicked
function RPBots:OnChatCancel()
	self.wndChat:Close() -- hide the window
end

-----------------------------------------------------------------------------------------------
-- BotCreateForm Functions
-----------------------------------------------------------------------------------------------

-- when the Cancel button is clicked
function RPBots:OnCreateCancel()
	self.wndChat:Close() -- hide the window
end

-----------------------------------------------------------------------------------------------
-- RPBots Comm Functions
-----------------------------------------------------------------------------------------------

-- Sends a message as the current user to the ICCommLib channel
function RPBots:SendMessage(packet)
	if self.Comm:IsReady() then
		if self.db.profile.debugMode then
			Print("Sending packet: " ..packet)
		end
		local processed = self:ProcessPacket(packet)
		if processed.type == "chat" and json.type.bot then
			self.Comm:SendMessage(message)
		end
	end
end

-- Decodes and processes a incoming packet from the ICCommLib channel
function RPBots:ProcessPacket(packetRaw)
	local json = self.json.decode(packetRaw)
	if json then
		if json.type == "chat" and json.type.bot then
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Say, json.message, json.name)
		end
		
		if json.type == "nameplate" then
			-- TODO add register code here
		end
	end
	return json
end

function RPBots:OnJoinResult(channel, eResult)
	local bBadName = eResult == ICCommLib.CodeEnumICCommJoinResult.BadName
	local bJoin = eResult == ICCommLib.CodeEnumICCommJoinResult.Join
	local bLeft = eResult == ICCommLib.CodeEnumICCommJoinResult.Left
	local bMissing = eResult == ICCommLib.CodeEnumICCommJoinResult.MissingEntitlement
	local bNoGroup = eResult == ICCommLib.CodeEnumICCommJoinResult.NoGroup
	local bNoGuild = eResult == ICCommLib.CodeEnumICCommJoinResult.NoGuild
	local bTooMany = eResult == ICCommLib.CodeEnumICCommJoinResult.TooManyChannels
	
	if bJoin then
		if self.db.profile.debugMode then
			Print(string.format('RPBots: Joined ICComm Channel "%s"', channel:GetName()))
			if channel:IsReady() then
				Print('RPBots: Channel is ready to transmit')
			else
				Print('RPBots: Channel is not ready to transmit')
			end
		end
	elseif bLeft then
		if self.db.profile.debugMode then
			Print('RPBots: Left ICComm Channel')
		end
	elseif bBadName then
		if self.db.profile.debugMode then
			Print('RPBots: Bad Channel Name')
		end
	elseif bMissing then
		if self.db.profile.debugMode then
			Print('RPBots: User doesn\'t have entitlement to job ICComm Channels')
		end
	elseif bNoGroup then
		if self.db.profile.debugMode then
			Print('RPBots: Group missing from channel Join attempt')
		end
	elseif bNoGuild then
		if self.db.profile.debugMode then
			Print('RPBots: Guild missing from channel Join attempt')
		end
	elseif bTooMany then
		if self.db.profile.debugMode then
			Print('RPBots: Too Many ICComm Channels exist')
		end
	else
		if self.db.profile.debugMode then
			Print('RPBots: Join Result didn\'t mat~h any of the Enum.')
		end
	end
end

function RPBots:OnMessageReceived(channel, strMessage, strSender)
   --if channel == chanRPB then
		self:processDecodedMessage(self:DecodeMessage(strMessage))
   --end
end

function RPBots:OnMessageSent(channel, eResult, idMessage)
	local mInvalid = eResult == ICCommLib.CodeEnumICCommMessageResult.InvalidText
	local mThrottled = eResult == ICCommLib.CodeEnumICCommMessageResult.Throttled
	local mMissing = eResult == ICCommLib.CodeEnumICCommMessageResult.MissingEntitlement
	local mNotIn = eResult == ICCommLib.CodeEnumICCommMessageResult.NotInChannel
    local mSent = eResult == ICCommLib.CodeEnumICCommMessageResult.Sent

	if mSent then
		if self.db.profile.debugMode then
			Print("Packet sent!")
		end		
	elseif bInvalid then
		-- this one should never happen, but I'm including it for completeness
		-- and invalid message should never be resent
		Print(string.format('RPBots: Message Invalid, Id# %d', idMessage))
	elseif bMissing then
		-- if the recipient doesn't have rights, we shouldn't bother with a resend
		Print(string.format('RPBots: Recipient Can Not Receive, Id# %d', idMessage))
	elseif bNotIn then
		-- if there not in the channel, they're not a RPF user and they can be removed from tracking
		Print(string.format('RPBots: Recipient Not In Channel, Id# %d', idMessage))
	elseif bThrottled then
		-- if it's throttled, we need to wait for a bit, then attempt a resend
		-- we'll let OnMessageThrottled handle that
		-- move the message to the throttled queue
		Print(string.format('RPBots: Message Throttled, Id# %d', idMessage))
	else
		-- if none of those enums is true, something else has gone horribly wrong
		Print(string.format('RPBots: Unknown Error, Id# %d', idMessage))
	end	
end

-----------------------------------------------------------------------------------------------
-- RPBots Timer Functions
-----------------------------------------------------------------------------------------------

function RPBots:OnTimerRefresh()
	if self.uPlayerUnit == nil then
		self.uPlayerUnit = GameLib.GetPlayerUnit()
	end
end

function RPBots:ScanbotTimer()
	if PlayerPathLib.GetPlayerPathType() == PlayerPathLib.PlayerPathType_Scientist then
		if self.playerUnit ~= nil and self.playerUnit:IsValid() then
			if (not PlayerPathLib.ScientistHasScanBot() and self.db.scanbot.autoSummon) then
				PlayerPathLib.ScientistToggleScanBot()
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- RPBots Utility Functions
-----------------------------------------------------------------------------------------------

function RPBots:GetDistanceTo(unit1, unit2)
	local tPos1 = unit1:GetPosition()
	local tPos2 = unit2:GetPosition()
	return math.sqrt(math.pow(tPos1.x - tPos2.x, 2) + math.pow(tPos1.y - tPos2.y, 2) + math.pow(tPos1.z - tPos2.z, 2))
end

-- strsplit code from WildstarNASA
-- Breaks an input string into a table of single words, cut on a provided deliminator.
function RPBots:strsplit(delim, str, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

-- Merges a table of single words back into a string, deliminated by provided character.
function RPBots:strunsplit(delim, inTable)
	local out = ""
	for i, v in ipairs(inTable) do
		out = out..v..delim
	end
	return out
end

-- Punctuation cleaner, removes punctuation marks likely to obscure words like the bot name.
function RPBots:RemovePunctuation(inText)
	inText:gsub("?", "")
	inText:gsub("!", "")
	inText:gsub(",", "")
	inText:gsub(".", "")
	return inText
end

-- Check the passed in text to see if the first words match a bot's name
function RPBots:CheckTextForBotNameAtStart(inText)
	local nameSplit = "" --BroBot:strsplit(" ", OurScanBotName)
	for i, v in ipairs(nameSplit) do
		if string.lower(inText[i]) ~= string.lower(v) then
			return false		
		end 
	end
	return true
end

