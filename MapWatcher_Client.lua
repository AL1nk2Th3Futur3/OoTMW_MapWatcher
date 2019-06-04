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
	clientMap:close()
	forms.destroy(mainformMap)
end)

-- Add a line to the outputMap. Inserts a timestamp to the string
-- Taken directly from bizhawk co-op.lua
function printOutputMap(str)
	local text = forms.gettext(outputMap)
	local pos = #text
	forms.setproperty(outputMap, "SelectionStart", pos)

	str = string.gsub (str, "\n", "\r\n")
	str = "[" .. os.date("%H:%M:%S", os.time()) .. "] " .. str
	if pos > 0 then
		str = "\r\n" .. str
	end

	forms.setproperty(outputMap, "SelectedText", str)
end

-- Keepalive function. Sends a ping every second telling the server it's still here
function keepalive ()
  start = os.time()
  while true do
    now = os.time()
		emu.yield()
		emu.yield()
    if os.difftime(now, start) >= 5 then
      pong = clientMap:send("ping,")
			emu.yield()
	    emu.yield()
      if not pong then
        printOutputMap("Disconnected from server")
        HOST, PORT, USERNAME, COLOUR = nil
				clientMap:close()
				forms.setproperty(connect, 'Enabled', true)
				forms.setproperty(disconnect, 'Enabled', false)
				start = now
        coroutine.yield(true)
      else
	      -- s, status, partial = clientMap:receive("*l")
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
	printOutputMap("Disconnected from server")
  forms.setproperty(connect, 'Enabled', true)
  forms.setproperty(disconnect, 'Enabled', false)
end

-- GUI
mainformMap = forms.newform(370, 265, "Map Watcher")
usernameTxt = forms.textbox(mainformMap, un, 90, 20, nil, 70, 20, false, false)
hostTxt = forms.textbox(mainformMap, ip, 90, 20, nil, 70, 50, false, false)
portTxt = forms.textbox(mainformMap, pt, 90, 20, nil, 70, 80, false, false)
colourTxt = forms.textbox(mainformMap, cl, 90, 20, nil, 70, 110, false, false)
passwordTxt = forms.textbox(mainformMap, "", 90, 20, nil, 70, 140, false, false)
lblUsername = forms.label(mainformMap, "Username:", 10, 22)
lblHost = forms.label(mainformMap, "Host IP:", 22, 52)
lblPort = forms.label(mainformMap, "Port:", 38, 82)
lblColour = forms.label(mainformMap, "Colour:", 27, 112)
lblPassword = forms.label(mainformMap, "Password:", 10, 142)
outputMap = forms.textbox(mainformMap, "", 170, 195, nil, 170, 20, true, true, 'Vertical')
forms.setproperty(outputMap, "ReadOnly", true)
forms.setproperty(passwordTxt, 'PasswordChar', '*')
connect = forms.button(mainformMap, "Connect", Connect, 10, 170, 151, 20)
disconnect = forms.button(mainformMap, "Disconnect", Disconnect, 10, 195, 151, 20)
forms.setproperty(disconnect, 'Enabled', false)

-- Checks to see if connection information is provided
function checkInfo ()
  while true do
    if not HOST and not PORT and not USERNAME and not COLOUR then
      emu.yield()
	    emu.yield()
			coroutine.yield(false)
    else
      -- Create the clientMap and connect
      printOutputMap("Attempting to connect to server...")
      clientMap, err = socket.connect(HOST, PORT)
			clientMap:setoption('linger', {['on']=false, ['timeout']=0})
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
	-- End script if mainformMap is closed
	if forms.gettext(mainformMap) == "" then
		return
	end
  status, retInfo = coroutine.resume(checkRoutine)
	if retInfo then
		-- If the socket couldn't connect, print and message and end everything
		if err then
			printOutputMap("Cannot connect to " .. HOST .. " on port " .. PORT)
			HOST, PORT, USERNAME, COLOUR = nil
		  forms.setproperty(connect, 'Enabled', true)
		  forms.setproperty(disconnect, 'Enabled', false)
		else
			printOutputMap("Connected to server!")
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
			clientMap:send(msg)
		end
	  while true do
			-- End script if mainformMap is closed
			if forms.gettext(mainformMap) == "" then
				return
			end
	    -- Start the keepalive routine
	    status, check = coroutine.resume(pingRoutine)
			-- print(status)
	    if status then
				-- Reconnection code WIP
					-- clientMap, err = socket.connect(HOST, PORT)
					-- if err then
					-- 	RECONATMP = RECONATMP + 1
					-- 	printOutputMap("Attempting to reconnect (" .. RECONATMP .. "/3)")
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
	        clientMap:send("location," .. currentLocation)
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
				clientMap:send(msg)
			end
			-- When new equipment is obtained, send it
			if table.concat(equipment) ~= table.concat(mainmemory.readbyterange(0x11A66B,3)) then
				equipment = mainmemory.readbyterange(0x11A66B,3)
				clientMap:send("equipment," .. equipment[1] .. ',' .. equipment[2])
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
				clientMap:send(msg)
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
				clientMap:send(msg)
			end
			-- When a new heart container is obtained, send it
			-- WIP Sending live heart data
			if maxhearts ~= mainmemory.read_u16_be(0x11A5FE) then --or currenthearts ~= mainmemory.read_u16_be(0x11A600) then
				maxhearts = mainmemory.read_u16_be(0x11A5FE)
				-- currenthearts = mainmemory.read_u16_be(0x11A600)
				clientMap:send("maxhearts," .. maxhearts)-- .. ',' .. currenthearts)
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
						clientMap:send('ping,')
						break
			    else
			      start = now
			    end
			  end
				if rupees == mainmemory.read_u16_be(0x11A604) then
					clientMap:send("rupees," .. rupees)
				end
			end
			-- When a skulltula is collected
			if skulltulas ~= mainmemory.read_u16_be(0x11A6A0) then
				skulltulas = mainmemory.read_u16_be(0x11A6A0)
				clientMap:send("skulltulas," .. skulltulas)
			end
	    emu.yield()
	    emu.yield()
	  end
	end
end
