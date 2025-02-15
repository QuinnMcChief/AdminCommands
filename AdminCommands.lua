-- Services:
local Players = game:GetService("Players")
local http = game:GetService("HttpService")
local sss = game:GetService("ServerScriptService")
local gs = game:GetService("GroupService")

local prefix = ';' --> This is the exclusive character that precedes all admin commands. No admin command will work without this character before it!

local Admins = {
	
	--> Game owner / group owner does not need to put their ID!
	
	
}

--> For ease of access, the player that owns this game or owns the group that owns this game
--> should be automatically given admin. To do that, below, we determine whether the owner of the game is a
--> player or group, then decide whether to simply insert their UserId into Admins in the case that a player owns this game,
--> OR fetch the group owner through a web request via GroupService, THEN insert the UserId into Admins..
if game.CreatorType == Enum.CreatorType.User then
	table.insert(Admins, game.CreatorId)
else
	table.insert(Admins, gs:GetGroupInfoAsync(game.CreatorId).Owner)
end


		-------------------------------
		-- [ Some GETTER Functions ] --
		-------------------------------

--> Uses chattedString to find player whose username most closely resembles the admin's chatted string.
--> getPlayer finds username that closest matches chattedString by taking the lowered substring of
--> each player's name (starting at the beginning) and seeing whether they match chattedString. If multiple
--> players' usernames match chattedString, getPlayer returns nil.
--> EXAMPLE USE CASE: ";kill jo" getPlayer would use "jo" and return the player "JohnDoe", and the kill function would kill JohnDoe.
local function getPlayer(chattedString: string): Player | nil
	if not chattedString then return end
	chattedString = tostring(chattedString)
	
	local listOfPlayers = Players:GetPlayers()
	local candidates = {}
	local chattedStringLength = chattedString:len()
	
	for _, player in ipairs(listOfPlayers) do
		local playerNameSubstring = player.Name:sub(1, chattedStringLength):lower()
		if playerNameSubstring == chattedString then
			candidates[#candidates + 1] = player
		end
	end
	if #candidates == 1 then
		return candidates[1]
	end
	
	return nil
end

local function getClosestChildByName(chattedString: string, parent: Instance): Instance | nil
	if not parent then warn("parent not given for getClosestChildByName!") return end
	chattedString = tostring(chattedString)
	local children = parent:GetChildren()
	local candidates = {}
	local chattedStringLength = chattedString:len()
	for _, child in ipairs(children) do
		local childNameSubstring = child.Name:sub(1, chattedStringLength):lower()
		if childNameSubstring == chattedString then
			table.insert(candidates, child)
		end
	end
	if #candidates == 1 then
		return candidates[1]
	end
	return nil
end


		------------------------
		-- [ ADMIN COMMANDS ] --
		------------------------

local commands = {
	
	["Tp"] = function(speaker, args)
		--> Teleports either one player to another, or one player to a mana well, depending on the arguments given.
		--> example args: {[1] = somePlayer}
		--> example command 1: ";tp somePlayer" (teleports speaker to somePlayer)
		
		--> example args: {[1] = somePlayer, [2] = to, [3] = anotherPlayer}
		--> example command 2: ";tp somePlayer to anotherPlayer" (teleports somePlayer to anotherPlayer)
		
		--> example args: {[1] = somePlayer, [2] = to, [3] = manaWellName}
		--> example command 3: ";tp somePlayer to manaWellName" (teleports somePlayer to specified mana well)
		
		local player1 = getPlayer(args[1])
		if not player1 then return end
		local character1 = player1.Character
		if not character1 then return end
		local selfCharacter: Model = speaker.Character
		
		if not args[3] then
			if selfCharacter then
				selfCharacter:PivotTo(character1.HumanoidRootPart.CFrame)
			end
		end
		
		--> "Mana Wells" are UNIQUELY NAMED objectives players can capture.
		--> Retrieves a mana well from player's chatted string, if any well name matches:
		local manaWell: Model? = getClosestChildByName(args[3], workspace:FindFirstChild("Wells"))
		if manaWell then
			if selfCharacter then
				--> Place character directly on top of the mana well.
				selfCharacter:PivotTo(CFrame.new(manaWell:GetBoundingBox().Position + Vector3.new(0, 2.25, 0) + Vector3.new(0, (manaWell:GetExtentsSize().Y / 2), 0)))
			end
		end
		local player2 = getPlayer(args[3])
		if not player2 then return end
		local character2 = player2.Character
		if not character2 then return end
		
		character1:PivotTo(character2.HumanoidRootPart.CFrame) --> I would just move HumanoidRootParts themselves, but that doesn't work with R6 and I might use R6.
	end,
	
	["SetHealth"] = function(speaker, args)
		--> Sets a player's current health to a specified amount, depending on arguments given.
		--> example args 1: {[1] = healthAmount}
		--> example command: ";sethealth 25" (sets speaker's health to 25)
		
		--> example args 2: {[1] = somePlayer, [2] = healthAmount}
		--> example command: ";sethealth somePlayer 25" (sets player's health to 25)

		local arg1 = args[1]
		if tonumber(arg1) then
			local character = speaker.Character
			if character then
				character.Humanoid.Health = arg1
			end
		else
			local player = getPlayer(args[1])
			local healthAmount = args[2]
			if player and player.Character and tonumber(healthAmount) then
				player.Character.Humanoid.Health = healthAmount
			end
		end
		
	end,
	
	["SetWS"] = function(speaker, args) --> WS = "WalkSpeed"
		--> Sets a player's WalkSpeed to a specified amount, depending on arguments given.
		--> example args 1: {[1] = newWalkspeed}
		--> example command: ";setws 25" (sets speaker's walkspeed to 25)

		--> example args 2: {[1] = somePlayer, [2] = newWalkspeed}
		--> example command: ";sethealth somePlayer 25" (sets player's walkspeed to 25)
		
		local arg1 = args[1]
		if tonumber(arg1) then
			local character = speaker.Character
			if character then
				character.Humanoid.WalkSpeed = arg1
			end
		else
			local player = getPlayer(args[2])
			local walkspeedAmount = args[4]
			if player and player.Character and walkspeedAmount then
				player.Character.Humanoid.WalkSpeed = walkspeedAmount
			end
		end
	end,
	
	["SetJP"] = function(speaker, args) --> JP = "JumpPeight"
		--> Sets a player's JumpPower to a specified amount, depending on arguments given.
		--> example args 1: {[1] = newJumpPower}
		--> example command: ";setjp 25" (sets speaker's jumpPower to 25)

		--> example args 2: {[1] = somePlayer, [2] = newJumpHeight}
		--> example command: ";setjp somePlayer 25" (sets player's jumpPower to 25)
		
		local arg1 = args[1]
		if tonumber(arg1) then
			local character = speaker.Character
			if character then
				character.Humanoid.JumpPower = arg1
				print("A")
			end
		else
			local player = getPlayer(args[1])
			local jumpheightAmount = args[2]
			if player and player.Character and jumpheightAmount then
				player.Character.Humanoid.JumpPower = jumpheightAmount
			end
		end
	end,
	
	["SetHipHeight"] = function(speaker, args) 
		--> Sets a player's JumpHeight to a specified amount, depending on arguments given.
		--> example args 1: {[1] = newHipHeight}
		--> example command: ";sethipheight 18" (sets speaker's sethipheight to 18)

		--> example args 2: {[1] = somePlayer, [2] = newHipHeight}
		--> example command: ";sethipheight somePlayer 18" (sets player's sethipheight to 18)

		local amount = args[1] == "default" and 1.998 or tonumber(args[1])
		if amount then
			local character = speaker.Character
			if character then
				character.Humanoid.HipHeight = amount
			end
		else
			local player = getPlayer(args[2])
			local walkspeedAmount = args[4]
			if player and player.Character and walkspeedAmount then
				player.Character.Humanoid.HipHeight = walkspeedAmount
			end
		end
	end,
	
	["Damage"] = function(speaker, args)
		--> Damages a player a specified amount, depending on arguments given.
		--> example args: {[1] = somePlayer, [2] = damageAmount}
		--> example command: ";damage somePlayer damageAmount"
		
		local victim = getPlayer(args[1])
		if not victim then warn(`No victim player found!`) return end
		local victimCharacter = victim.Character
		if not victimCharacter then warn(`No victim character!`) return end
		
		local damageAmount = tonumber(args[2])
		if not damageAmount then warn(`No number given for damageAmount!`) return end
		
		victimCharacter.Humanoid:TakeDamage(damageAmount)
	end,
	
	["Kill"] = function(_, args)
		--> Kills a player based on the argument given. Pretty self-explanatory.
		--> example args: {[1] = somePlayer}
		--> example command: ";kill somePlayer"
		
		local victimPlayer = getPlayer(args[1])
		if victimPlayer and victimPlayer.Character then
			victimPlayer.Character.Humanoid.Health = 0
		end
	end,
	
	["Respawn"] = function(speaker, args)
		--> Respawns a player's character, pivoting their new character's CFrame to the CFrame their previous character had before the respawn.
		--> example args: {[1] = somePlayer}
		--> example command: ";respawn somePlayer"
		
		local playerToRespawn = getPlayer(args[1]) or speaker
		print(`player to respawn is {playerToRespawn}!`)

		if playerToRespawn then
			local character = playerToRespawn.Character
			local lastCFrame;
			if character then
				lastCFrame = character.HumanoidRootPart.CFrame
			end
			playerToRespawn:LoadCharacter()
			if lastCFrame then
				playerToRespawn.Character:PivotTo(lastCFrame)
			end
		end
	end,
	
	["ChangeTeam"] = function(speaker, args)
		--> Changes team of somePlayer to specified team, based on arguments given.
		--> example args: {[1] = somePlayer, ...}
		--> example command: ";changeteam somePlayer newTeam"
		--> (Keep in mind, team name could consist of multiple words, so we string all arguments after somePlayer together to account for that)
		print("A")
		local arg1 = args[1]
		if not arg1 then warn("No arg1 was given for ChangeTeam!") return end
		local victimPlayer = getPlayer(args[1])
		if victimPlayer then
			print("B1")
			
			--> In case this game has teams with multiple words, we need to string together the rest of the arguments
			--> and pass that into getClosestChildByName, instead of simply passing args[2] into it!
			local entireTeamString = ""
			for i = 2, #args do
				entireTeamString = entireTeamString .. args[i] .. ' '
			end
			entireTeamString = entireTeamString:sub(1, entireTeamString:len() - 1) -- Remove the extra space at the end!
			local teamToChangeTo = getClosestChildByName(entireTeamString, game.Teams)
			if teamToChangeTo then
				print("C1")
				victimPlayer.Team = teamToChangeTo
			end
		else
			print("B2")
			local teamToChangeTo = getClosestChildByName(arg1, game.Teams)
			if teamToChangeTo then
				print("C2")
				speaker.Team = teamToChangeTo
			end
		end
	end,
	
	["Give"] = function(speaker, args)
		--> Gives specified player a specific amount of a specified currency, depending on arguments given.
		--> example args: {[1] = somePlayer, [2] = amount, [3] = currency}
		--> example command: ";give somePlayer 5 cash"
		local playerToGiveTo = getPlayer(args[1])
		if not playerToGiveTo then return end
		
		local amount = args[2] and tonumber(args[2])
		if not amount then return end
		
		local thingToGive = args[3]
		if not thingToGive then return end
		
		local currency: ValueBase? = getClosestChildByName(thingToGive, playerToGiveTo.leaderstats)
		if currency then
			currency.Value += amount
		end
		
		print("Couldn't find currency...")
	end,
	
	["Remove"] = function(speaker, args)
		--> Removes a specific amount of currency from a specified player, depending on arguments provided
		--> example args: {[1] = amount, [2] = currency, [3] = "from", [4] = somePlayer}
		--> example command: ";remove 5 cash from somePlayer"
		local amount = args[1] and tonumber(args[1])
		if not amount then return end
		
		local thingToRemove = args[2]
		if not thingToRemove then return end
		
		local playerToRemoveFrom = getPlayer(args[4])
		
		local currency: ValueBase? = getClosestChildByName(thingToRemove, playerToRemoveFrom.leaderstats)
		if currency then
			local difference = currency.Value - amount
			if difference >= 0 then
				currency.Value = difference
			else
				currency.Value = 0
			end
		end
	end,
	
	["Kick"] = function(speaker, args)
		--> Kicks specified player from the game, depending on argument given.
		--> example args: {[1] = somePlayer}
		local player = getPlayer(args[1])
		if not player then return end
		
		local personDoingTheKicking = speaker and speaker.Name or "[Could not find user]"
		
		player:Kick(`You have been kicked by {personDoingTheKicking}. If you think this is a mistake... try to contact someone higher up.`)
	end,
}





Players.PlayerAdded:Connect(function(player)
	local playerIsAdmin = table.find(Admins, player.UserId)
	if --[[playerIsAdmin]]true then
		player.CharacterAdded:Connect(function(character)
			script.ClickToTeleport:Clone().Parent = character
		end)
		
		player.Chatted:Connect(function(message)
			--> Check if the first character of the message is the prefix character. If not, it's not an admin command! (See top of script for more info)
			local len = message:len()
			if len <= 1 and message:sub(1, 1) ~= prefix then 
				return 
			end
			
			--> Isolate rest of message from prefix:
			local messageWithoutPrefix = message:sub(2, message:len()):lower()
			local args = messageWithoutPrefix:split(' ')
			--> Admin often issues commands on or involving themselves, so a short reference to their own name is paramount! 
			--> The use of "me" refers to the speaker, so we substitute each instance of "me" with the player's name below:
			for idx, arg in ipairs(args) do
				if arg == "me" then
					args[idx] = player.Name:lower()
				end
			end
			
			--> The name of the command will ALWAYS be the first argument of the player's message (admin command).
			--> Therefore, we use it to index the commands table to find the admin command function the player is trying to use!
			local chattedCommandName = args[1]
			for commandName: string, commandFunc in pairs(commands) do
				if commandName:lower() == chattedCommandName then
					--> The arguments we pass into the function don't need the command name itself, so we get rid of it here.
					table.remove(args, 1)
					commandFunc(player, args)
					return
				end
			end
		end)
	end
end)
