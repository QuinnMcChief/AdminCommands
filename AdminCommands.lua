--[[ 
	The following section retrieves key Roblox services.
	Using game:GetService ensures that the service is loaded (or waits until it is) before proceeding.
--]]
local Players = game:GetService("Players")
local http = game:GetService("HttpService")
local sss = game:GetService("ServerScriptService")
local gs = game:GetService("GroupService")

--[[ 
	For admin commands, there needs to be a way to distinguish them between a player's normal chat messages.
	The prefix variable holds the unique character that signals a chat message is an admin command.
--]]
local prefix = ';'

local Admins = {
	
	--> Game owner / group owner does not need to put their ID!
	
	
}

--[[
	This block determines the game’s creator type.
	If the creator is an individual user (CreatorType.User), we directly insert the game.CreatorId.
	If the creator is a group (CreatorType.Group), we make an asynchronous call via GroupService to fetch group info
	and then extract the Owner field. This demonstrates how we (I?) can branch logic based on the game’s metadata.
--]]
if game.CreatorType == Enum.CreatorType.User then
	table.insert(Admins, game.CreatorId)
else
	table.insert(Admins, gs:GetGroupInfoAsync(game.CreatorId).Owner)
end


		-------------------------------
		-- [ Some GETTER Functions ] --
		-------------------------------

--[[
	getPlayer takes a string (from chat input) and attempts to identify a unique player whose name starts 
	with that string. The function iterates through each player's Name and extracts the beginning segment of it equal in length to the input.
	Then, it compares the lowercased substring with the lowercased input. If exactly one candidate is found, that player is returned.
	This technique uses string manipulation and table accumulation to do a loose comparison of the strings.
	EXAMPLE USE CASE: for ";kill jo", getPlayer would use "jo" and return the player "JohnDoe", and the kill function would kill JohnDoe.
--]]
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

--[[
	getClosestChildByName functions similarly to getPlayer, but it operates on the children of a given parent Instance.
	The function:
		First retrieves all children of the provided parent using GetChildren().
		Secondly, for each child, it extracts the starting segment of the child's Name that matches the length of the input string.
		Third, it compares the lowercased substring with the lowercased chat input.
		Finally, it returns the child instance if exactly one candidate matches.
	This provides a simple semi-string-matching mechanism for instance names within some sort of explorer hierarchy.
	EXAMPLE USE CASE: getClosestChildByName("the hidd", game.Teams) would retrieve the "The HiddenDevs Team" team.
--]]
local function getClosestChildByName(chattedString: string, parent: Instance): Instance | nil
	if not parent then warn("parent not given for getClosestChildByName!") return end
	chattedString = tostring(chattedString)
	local children = parent:GetChildren()
	local candidates = {}
	local chattedStringLength = chattedString:len()
	for _, child in ipairs(children) do
		-- Extract and lower-case the starting portion of the player's name.
		local childNameSubstring = child.Name:sub(1, chattedStringLength):lower()
		if childNameSubstring == chattedString then
			table.insert(candidates, child)
		end
	end

	-- Only return a result if there is an unambiguous (single) match.
	if #candidates == 1 then
		return candidates[1]
	end
	return nil
end


		------------------------
		-- [ ADMIN COMMANDS ] --
		------------------------

--[[
	The commands table maps string keys (command names) to functions.
	Each function processes its own set of arguments (parsed from chat) and executes a particular behavior.
	These functions demonstrate how to manipulate players and their characters by using internal properties and methods.
--]]

local commands = {
	
	["Tp"] = function(speaker, args)
		--[[
			This function handles teleportation commands.
			It examines the provided arguments to decide between several behaviors:
				If only one argument is provided, it teleports the speaker to the target player's location.
				If a second argument ("to") and a third argument are provided, it may attempt to teleport either:
					a player to another player's location, or
					the speaker to a "mana well" location.
			The function utilizes getPlayer and getClosestChildByName functions to resolve string inputs to actual Instances.
			It then uses the PivotTo method on a character's model, which changes its CFrame.

			Example args 1: {[1] = somePlayer}
			example command 1: ";tp somePlayer" (teleports speaker to somePlayer.)
		
			Example args 2: {[1] = somePlayer, [2] = to, [3] = anotherPlayer}
			Example command 2: ";tp somePlayer to anotherPlayer" (teleports somePlayer to anotherPlayer.)
		
			Example args 3: {[1] = somePlayer, [2] = to, [3] = manaWellName}
			Example command 3: ";tp somePlayer to manaWellName" (teleports somePlayer to specified mana well.)
		--]]
		
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
		
		local manaWell: Model? = getClosestChildByName(args[3], workspace:FindFirstChild("Wells"))
		if manaWell then
			if selfCharacter then
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
		--[[
			This function adjusts a player's health value.
			It first checks if the first argument is numeric.
				If numeric, the function interprets it as a health value for the speaker.
				Otherwise, it treats the first argument as a player identifier and the second as the health value.
			The health is set by directly updating the Humanoid.Health property.
		
			example args 1: {[1] = healthAmount}
			example command: ";sethealth 25" (sets speaker's health to 25)
			
			example args 2: {[1] = somePlayer, [2] = healthAmount}
			example command: ";sethealth somePlayer 25" (sets player's health to 25)
		--]]

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
		--[[
			SetWS adjusts a player's WalkSpeed.
			It uses the exact same branching structure I chose for SetHealth:
				If the first argument is numeric, it applies the change to the speaker's character.
				Otherwise, it attempts to resolve a target player.
		
			Example args 1: {[1] = newWalkspeed}
			Example command 1: ";setws 25" (Sets speaker's walkspeed to 25.)

			Example args 2: {[1] = somePlayer, [2] = newWalkspeed}
			Example command 2: ";sethealth somePlayer 25" (Sets player's walkspeed to 25.)
		--]]
		
		local arg1 = args[1]
		if tonumber(arg1) then
			local character = speaker.Character
			if character then
				character.Humanoid.WalkSpeed = arg1
			end
		else
			local player = getPlayer(args[1])
			local walkspeedAmount = args[2]
			if player and player.Character and walkspeedAmount then
				player.Character.Humanoid.WalkSpeed = walkspeedAmount
			end
		end
	end,
	
	["SetJP"] = function(speaker, args) --> JP = "JumpPeight"
		--[[
		SetJP adjusts a player's JumpPower.
		Uses identical structure as SetHealth and SetWS in terms of parsing arguments.
				If the first argument is numeric, it applies the change to the speaker's character.
				Otherwise, it attempts to resolve a target player, and change their character's health instead.
		This function updates the Humanoid.JumpPower property, which influences jump height.
		
		Example args 1: {[1] = newJumpPower}
		Example command 1: ";setjp 25" (sets speaker's jumpPower to 25)

		Example args 2: {[1] = somePlayer, [2] = newJumpHeight}
		Example command 2: ";setjp somePlayer 25" (sets player's jumpPower to 25)
		]]
		
		local arg1 = args[1]
		if tonumber(arg1) then
			local character = speaker.Character
			if character then
				character.Humanoid.JumpPower = arg1
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
		--[[
			SetHipHeight adjusts the HipHeight property of a player's character.
			The function first checks if the argument equals the string "default". If so, it resets to the default Humanoid HipHeight.
			(90% of people don't know what the default value for HipHeight is and 100% of people don't remember it. 1.998 is NOT intuitive, so this is a good idea.)
			However, if the argument isn't "default", it attempts to convert the argument to a number.
			Similar to previous functions, it applies the change either to the speaker or, in the alternate branch,
			tries to resolve a target player.
		
			Example args 1: {[1] = newHipHeight}
			Example command 1: ";sethipheight 18" (Sets speaker's HipHeight to 18.)

			Example args 2: {[1] = somePlayer, [2] = newHipHeight}
			Example command 2: ";sethipheight somePlayer 18" (Sets somePlayer's HipHeight to 18.)
		]]

		local amount = args[1] == "default" and 1.998 or tonumber(args[1])
		if amount then
			local character = speaker.Character
			if character then
				character.Humanoid.HipHeight = amount
			end
		else
			local player = getPlayer(args[1])
			local walkspeedAmount = args[2]
			if player and player.Character and walkspeedAmount then
				player.Character.Humanoid.HipHeight = walkspeedAmount
			end
		end
	end,
	
	["Damage"] = function(speaker, args)
		--[[
			The Damage command subtracts a specified amount of health from a target player.
			It first uses getPlayer to resolve the target from a string. Unlike previous functions, there is no built-in parsing system to target the speaker.
			If the target and its character exist, the function converts the damage amount argument into a number and deals it using the TakeDamage metamethod.
			It should be noted that targets with forcefields will take no damage. If you don't like this feature, replace the following line of code:
				victimCharacter.Humanoid:TakeDamage(damageAmount)
			With this:
				victimCharacter.Humanoid.Health -= damageAmount
		

			Example args: {[1] = somePlayer, [2] = damageAmount}
			Example command: ";damage somePlayer damageAmount" (Subtracts damageAmount from somePlayer's current health, assuming they don't have a forcefield.)
		
		--]]
		
		local victim = getPlayer(args[1])
		if not victim then warn(`No victim player found!`) return end
		local victimCharacter = victim.Character
		if not victimCharacter then warn(`No victim character!`) return end
		
		local damageAmount = tonumber(args[2])
		if not damageAmount then warn(`No number given for damageAmount!`) return end
		
		victimCharacter.Humanoid:TakeDamage(damageAmount)
	end,
	
	["Kill"] = function(_, args)
		--[[
			The Kill command sets a player's health to zero.
			It resolves the target via getPlayer and, if successful, directly updates the Humanoid.Health property.
			This is better than using :TakeDamage(player's current health), because TakeDamage ignores players who use forcefields.
			Overall, setting the Humanoid.Health property is more reliable. If you're looking for the most reliable way of setting a player's health, this is it!

			Example args: {[1] = somePlayer}
			Example command: ";kill somePlayer" (Sets the player's health to zero)
		--]]
		
		local victimPlayer = getPlayer(args[1])
		if victimPlayer and victimPlayer.Character then
			victimPlayer.Character.Humanoid.Health = 0
		end
	end,
	
	["Respawn"] = function(speaker, args)
		--[[
			Respawn first attempts to get a player from the arguments (and subsequently, their character), OR defaults to the speaker player's character
			It then captures the current CFrame of the character's HumanoidRootPart (if present) so that after a character reload,
			the new character can be repositioned to the same CFrame.
			The player:LoadCharacter() method replaces the current character, and the subsequent call to PivotTo repositions it.

			Example args: {[1] = somePlayer}
			Example command: ";respawn somePlayer"
		--]]
		
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
		--[[
			ChangeTeam allows an admin to reassign a player's team.
			The function first checks if arg[1] can resolve to a target player.
			If a player is successfully found from arg[1], the remaining arguments (...) are concatenated to form a string that is used to search 
			through the game.Teams children via getClosestChildByName.
			
			On the other hand, if NO player is resolved from arg[1], the function interprets ALL arguments (including arg[1]) as part of the TEAM name,
			and applies the team change to the SPEAKER instead!

			Example args: {[1] = somePlayer, ...}
			Example command: ";changeteam somePlayer newTeam"
		--]]

		local arg1 = args[1]
		if not arg1 then warn("No arg1 was given for ChangeTeam!") return end
		local victimPlayer = getPlayer(args[1])
		if victimPlayer then
			
			-- Concatenate arguments 2 through end to allow multi-word team names.
			local entireTeamString = ""
			for i = 2, #args do
				entireTeamString = entireTeamString .. args[i] .. ' '
			end
			
			-- Remove the trailing space.
			entireTeamString = entireTeamString:sub(1, entireTeamString:len() - 1)
			local teamToChangeTo = getClosestChildByName(entireTeamString, game.Teams)
			if teamToChangeTo then
				victimPlayer.Team = teamToChangeTo
			end
		else
			-- If no player was resolved, treat ALL arguments as part of the new team name for the speaker!.
			local entireTeamString = ""
			for i = 1, #args do
				entireTeamString = entireTeamString .. args[i] .. ' '
			end
			
			-- Remove the trailing space.
			entireTeamString = entireTeamString:sub(1, entireTeamString:len() - 1)
			local teamToChangeTo = getClosestChildByName(entireTeamString, game.Teams)
			if teamToChangeTo then
				speaker.Team = teamToChangeTo
			end
		end
	end,
	
	["Give"] = function(speaker, args)
		--[[
			This code not only attempts to add money to a player's leaderboard, but allows for specification of currency!
			(Currency defaults to "Cash" though.)
			The function first gets target player using the getPlayer function at the top of the script.
			It then converts the second argument into a numeric value.
			Using getClosestChildByName on the player's leaderstats, it locates the currency ValueBase.
			If found, it increments its Value property.
			This demonstrates chained lookups and arithmetic on Instance properties.

			Example args: {[1] = somePlayer, [2] = amount, [3] = currency}
			Example command: ";give somePlayer 5 cash"
			Example result: somePlayer.leaderstats.Cash.Value += 5
		--]]
		--> Gives specified player a specific amount of a specified currency, depending on arguments given.
		--> example args: {[1] = somePlayer, [2] = amount, [3] = currency}
		--> example command: ";give somePlayer 5 cash"
		local playerToGiveTo = getPlayer(args[1])
		if not playerToGiveTo then return end
		
		local amount = args[2] and tonumber(args[2])
		if not amount then return end
		
		local thingToGive = args[3] or "Cash"
		if not thingToGive then return end
		
		local currency: ValueBase? = getClosestChildByName(thingToGive, playerToGiveTo.leaderstats)
		if currency then
			currency.Value += amount
		else
			print("Couldn't find currency...")
		end
	end,
	
	["Remove"] = function(speaker, args)
		--[[
			This code attempts to remove a specified amount of currency from a player's leaderboard, though currency defaults to "Cash" when given a nil value.
			The function first gets target player using the getPlayer function at the top of the script.
			It then converts the second argument into a numeric value.
			Using getClosestChildByName on the player's leaderstats, it locates the currency ValueBase.
			If found, it increments its Value property.
			This demonstrates chained lookups and arithmetic on Instance properties.

			Example args: {[1] = amount, [2] = currency, [3] = "from", [4] = somePlayer}
			Example command: ";remove 5 cash from somePlayer"
		--]]
		
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
		--[[
			The kick command uses getPlayer to resolve a player from arg[1], then dynamically generates a kick message using the speakers name, 
			a clear showcase of what I believe is referred to as "string interpolation".

			Example args: {[1] = somePlayer}
			Example command: ";kick somePlayer" (Kicks the player from the game, giving them the dynamically generated kick message.))
		--]]

		local player = getPlayer(args[1])
		if not player then return end
		
		local personDoingTheKicking = speaker and speaker.Name or "[Could not find user]"
		
		player:Kick(`You have been kicked by {personDoingTheKicking}. If you think this is a mistake... try to contact someone higher up.`)
	end,
}




--[[
	Some admin command systems use special command bars to input their commands. In our case, we'll be using roblox's default chat system!
	The tricky part about using Roblox's chat system is that admins frequently use it for purposes other than initiating admin commands,
	so differentiating between normal chat messages and commands can, at first, seem like a challenge... But not to worry, there's a simple solution! 
	Since there needs to be a way to distinguish them between a player's normal chat messages, we define a "prefix" variable at the top of the script, 
	which holds the unique character that signals a chat message is an admin command. (I set it be default to be a semicolon ';')

	Here's what a normal roblox chat message would look like:
	"kill me"

	Here's what a roblox chat message intended as an admin command would appear as:
	";kill me"

	Now, let's review the following code:
	
	It connects an anonymous function to the PlayerAdded event with "player" as the parameter.
	If player's UserId is in the Admins table:
		Connect an anonymous function to the Chatted event, with "message" as the parameter.
		If first character is prefix:
			Declare "args" as lowercase version of message split into individual words 
			Replace all instances of "me" in args with player's Name.
			Remove command name from args
			Iterate over the commands table to find a matching command name (case-insensitive) and, if found,
			calls the corresponding function with the remaining arguments
		
--]]
	
Players.PlayerAdded:Connect(function(player)
	local playerIsAdmin = table.find(Admins, player.UserId)
	if playerIsAdmin then
		player.Chatted:Connect(function(message)
			--> Check if the first character of the message is the prefix character. If not, it's not an admin command! (See top of script for more info)
			local len = message:len()
			if len <= 1 or message:sub(1, 1) ~= prefix then 
				return 
			end
			
			--> Isolate rest of message from prefix:
			local messageWithoutPrefix = message:sub(2, message:len()):lower()
			-- Split the message into individual arguments using space as the separator.
			local args = messageWithoutPrefix:split(' ')
			-- Replace any occurrence of "me" with the player's own name (lowercased).
			for idx, arg in ipairs(args) do
				if arg == "me" then
					args[idx] = player.Name:lower()
				end
			end
			
			-- The first argument is taken as the command name.
			local chattedCommandName = args[1]
			-- Iterate over all defined commands, checking case-insensitively for a match.
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
