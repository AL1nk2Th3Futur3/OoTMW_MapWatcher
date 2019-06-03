local socket = require('socket')

local HOST, PORT, USERNAME, COLOUR, PASSWORD
local RECONATMP = 0

-- Store used credentials for later
file = io.open("info.txt", 'r+')
if not file then
	file = io.open('info.txt', 'w+')
	un = " "
	ip = " "
	pt = "50001"
	cl = "#000000"
	file:write(un .. "," .. ip .. "," .. pt .. "," .. cl)
else
	info = {}
	for str in string.gmatch(file:read(), "([^,]+)") do
		table.insert(info, str)
	end
	un = info[1]
	ip = info[2]
	pt = info[3]
	cl = info[4]
end
file:close()

-- Handle the closing of the application
event.onexit(function ()
	client:close()
	forms.destroy(mainform)
end)

-- Add a line to the output. Inserts a timestamp to the string
-- Taken directly from bizhawk co-op.lua
function printOutput(str)
	local text = forms.gettext(output)
	local pos = #text
	forms.setproperty(output, "SelectionStart", pos)

	str = string.gsub (str, "\n", "\r\n")
	str = "[" .. os.date("%H:%M:%S", os.time()) .. "] " .. str
	if pos > 0 then
		str = "\r\n" .. str
	end

	forms.setproperty(output, "SelectedText", str)
end

-- Keepalive function. Sends a ping every second telling the server it's still here
function keepalive ()
  start = os.time()
  while true do
    now = os.time()
		emu.yield()
		emu.yield()
    if os.difftime(now, start) >= 5 then
      pong = client:send("ping,")
			emu.yield()
	    emu.yield()
      if not pong then
        printOutput("Disconnected from server")
        HOST, PORT, USERNAME, COLOUR = nil
				client:close()
				forms.setproperty(connect, 'Enabled', true)
				forms.setproperty(disconnect, 'Enabled', false)
				start = now
        coroutine.yield(true)
      else
	      -- s, status, partial = client:receive("*l")
	      start = now
			end
    end
    coroutine.yield(false)
  end
end

-- Grab initial starting position
local currentLocation = mainmemory.read_u16_be(0x1C8544)

-- Variables for use later when I want to get pintpoint accuracy
-- local respawnLocation = mainmemory.read_u16_be(0x11B948)
-- local x = mainmemory.read_u16_be(0x1DAA54)
-- local y = mainmemory.read_u16_be(0x1DAA58)
-- local z = mainmemory.read_u16_be(0x1DAA5C)

local items = mainmemory.readbyterange(0x11A644, 24)
local equipment = mainmemory.readbyterange(0x11A66B, 3)
local upgrades = mainmemory.readbyterange(0x11A670, 4)
local questitems = mainmemory.readbyterange(0x11A674, 4)
local maxhearts = mainmemory.read_u16_be(0x11A5FE)
local currenthearts = mainmemory.read_u16_be(0x11A600)
local rupees = mainmemory.read_u16_be(0x11A604)
local skulltulas = mainmemory.read_u16_be(0x11A6A0)

-- Connect button
function Connect (args)
  HOST = forms.gettext(hostTxt)
  HOST = HOST:gsub(",", "")
  HOST = HOST:gsub(" ", "")
  PORT = forms.gettext(portTxt)
  PORT = PORT:gsub(",", "")
  PORT = PORT:gsub(" ", "")
  USERNAME = forms.gettext(usernameTxt)
  USERNAME = USERNAME:gsub(",", "")
  USERNAME = USERNAME:gsub(" ", "")
  COLOUR = forms.gettext(colourTxt)
  COLOUR = COLOUR:gsub(",", "")
  COLOUR = COLOUR:gsub(" ", "")
  COLOUR = COLOUR:gsub("ping", "")
	PASSWORD = forms.gettext(passwordTxt)
	PASSWORD = PASSWORD:gsub(",", "")
	file = io.open("info.txt", 'w')
	file:write(USERNAME .. "," .. HOST .. "," .. PORT .. "," .. COLOUR .. ",")
	file:close()
  forms.setproperty(connect, 'Enabled', false)
  forms.setproperty(disconnect, 'Enabled', true)
end

-- Disconnect button
function Disconnect (args)
	disconn = true
	HOST, PORT, USERNAME, COLOUR = nil
	printOutput("Disconnected from server")
  forms.setproperty(connect, 'Enabled', true)
  forms.setproperty(disconnect, 'Enabled', false)
end

-- GUI
mainform = forms.newform(370, 265, "Map Watcher")
usernameTxt = forms.textbox(mainform, un, 90, 20, nil, 70, 20, false, false)
hostTxt = forms.textbox(mainform, ip, 90, 20, nil, 70, 50, false, false)
portTxt = forms.textbox(mainform, pt, 90, 20, nil, 70, 80, false, false)
colourTxt = forms.textbox(mainform, cl, 90, 20, nil, 70, 110, false, false)
passwordTxt = forms.textbox(mainform, "", 90, 20, nil, 70, 140, false, false)
lblUsername = forms.label(mainform, "Username:", 10, 22)
lblHost = forms.label(mainform, "Host IP:", 22, 52)
lblPort = forms.label(mainform, "Port:", 38, 82)
lblColour = forms.label(mainform, "Colour:", 27, 112)
lblPassword = forms.label(mainform, "Password:", 10, 142)
output = forms.textbox(mainform, "", 170, 195, nil, 170, 20, true, true, 'Vertical')
forms.setproperty(output, "ReadOnly", true)
forms.setproperty(passwordTxt, 'PasswordChar', '*')
connect = forms.button(mainform, "Connect", Connect, 10, 170, 151, 20)
disconnect = forms.button(mainform, "Disconnect", Disconnect, 10, 195, 151, 20)
forms.setproperty(disconnect, 'Enabled', false)

-- Checks to see if connection information is provided
function checkInfo ()
  while true do
    if not HOST and not PORT and not USERNAME and not COLOUR then
      emu.yield()
	    emu.yield()
			coroutine.yield(false)
    else
      -- Create the client and connect
      printOutput("Attempting to connect to server...")
      client, err = socket.connect(HOST, PORT)
			client:setoption('linger', {['on']=false, ['timeout']=0})
      coroutine.yield(true)
    end
  end
end

-- Create the coroutine for the keepalive function
pingRoutine = coroutine.create(keepalive)
-- Create the coroutine for the checkRoutine function
checkRoutine = coroutine.create(checkInfo)

-- Main loop
while true do
	disconn = false
	-- End script if mainform is closed
	if forms.gettext(mainform) == "" then
		return
	end
  status, retInfo = coroutine.resume(checkRoutine)
	if retInfo then
		-- If the socket couldn't connect, print and message and end everything
		if err then
			printOutput("Cannot connect to " .. HOST .. " on port " .. PORT)
			HOST, PORT, USERNAME, COLOUR = nil
		  forms.setproperty(connect, 'Enabled', true)
		  forms.setproperty(disconnect, 'Enabled', false)
		else
			printOutput("Connected to server!")
			-- Send the identifying information to the server and start the main loop
			msg = "username," .. USERNAME .. "," .. currentLocation .. "," .. COLOUR
			for i=0,23 do
				msg = msg .. "," .. items[i]
				emu.yield()
		    emu.yield()
			end
			msg = msg .. ',' .. equipment[1] .. ',' .. equipment[2] .. ',' .. PASSWORD
			for i=0,3 do
				msg = msg .. "," .. upgrades[i]
				emu.yield()
		    emu.yield()
			end
			for i=0,3 do
				msg = msg .. "," .. questitems[i]
				emu.yield()
		    emu.yield()
			end
			msg = msg .. ',' .. maxhearts  .. ',' .. currenthearts .. ',' .. rupees .. ',' .. skulltulas
			client:send(msg)
		end
	  while true do
			-- End script if mainform is closed
			if forms.gettext(mainform) == "" then
				return
			end
	    -- Start the keepalive routine
	    status, check = coroutine.resume(pingRoutine)
			-- print(status)
	    if status then
				-- Reconnection code WIP
					-- client, err = socket.connect(HOST, PORT)
					-- if err then
					-- 	RECONATMP = RECONATMP + 1
					-- 	printOutput("Attempting to reconnect (" .. RECONATMP .. "/3)")
					-- end
					-- emu.yield()
					-- if RECONATMP == 3 then
					-- 	break
					-- end
	      break
	    end
			if disconn then
				break
			end
	    -- Send the server the user's location each time it changes
	    if currentLocation ~= mainmemory.read_u16_be(0x1C8544) then
	      currentLocation = mainmemory.read_u16_be(0x1C8544)
	      if currentLocation <= 109 then
	        client:send("location," .. currentLocation)
	      end
	    end
			-- When a new item is obtained, send it
			if table.concat(items) ~= table.concat(mainmemory.readbyterange(0x11A644, 24)) then
				items = mainmemory.readbyterange(0x11A644, 24)
				msg = 'items'
				for i=0,23 do
					msg = msg .. "," .. items[i]
					emu.yield()
			    emu.yield()
				end
				client:send(msg)
			end
			-- When new equipment is obtained, send it
			if table.concat(equipment) ~= table.concat(mainmemory.readbyterange(0x11A66B,3)) then
				equipment = mainmemory.readbyterange(0x11A66B,3)
				client:send("equipment," .. equipment[1] .. ',' .. equipment[2])
			end
			-- When an upgrade is obtained, send it
			if table.concat(upgrades) ~= table.concat(mainmemory.readbyterange(0x11A670, 4)) then
				upgrades = mainmemory.readbyterange(0x11A670, 4)
				msg = 'upgrades'
				for i=0,3 do
					msg = msg .. "," .. upgrades[i]
					emu.yield()
			    emu.yield()
				end
				client:send(msg)
			end
			-- When a quest item is obtained, send it
			if table.concat(questitems) ~= table.concat(mainmemory.readbyterange(0x11A674, 4)) then
				questitems = mainmemory.readbyterange(0x11A674, 4)
				msg = 'questitems'
				for i=0,3 do
					msg = msg .. "," .. questitems[i]
					emu.yield()
			    emu.yield()
				end
				client:send(msg)
			end
			-- When a new heart container is obtained, send it
			-- WIP Sending live heart data
			if maxhearts ~= mainmemory.read_u16_be(0x11A5FE) then --or currenthearts ~= mainmemory.read_u16_be(0x11A600) then
				maxhearts = mainmemory.read_u16_be(0x11A5FE)
				-- currenthearts = mainmemory.read_u16_be(0x11A600)
				client:send("maxhearts," .. maxhearts)-- .. ',' .. currenthearts)
			end
			-- When rupees are gained/lost, send it
			-- There has to be a better way to do this
			if rupees ~= mainmemory.read_u16_be(0x11A604) then
				rupees = mainmemory.read_u16_be(0x11A604)
				local s = os.time()
				while true do
				  local n = os.time()
				  emu.yield()
				  emu.yield()
				  if os.difftime(n, s) >= 1 then
						client:send('ping,')
						break
			    else
			      start = now
			    end
			  end
				if rupees == mainmemory.read_u16_be(0x11A604) then
					client:send("rupees," .. rupees)
				end
			end
			-- When a skulltula is collected
			if skulltulas ~= mainmemory.read_u16_be(0x11A6A0) then
				skulltulas = mainmemory.read_u16_be(0x11A6A0)
				client:send("skulltulas," .. skulltulas)
			end
	    emu.yield()
	    emu.yield()
	  end
	end
end
