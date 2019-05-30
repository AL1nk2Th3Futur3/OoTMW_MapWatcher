local socket = require('socket')

local HOST, PORT, USERNAME, COLOUR
local RECONATMP = 0

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
    if os.difftime(now, start) >= 1 then
      pong = client:send("ping,")
      if not pong then
        printOutput("Disconnected from server")
        HOST, PORT, USERNAME, COLOUR = nil
				client:close()
				forms.setproperty(connect, 'Enabled', true)
				forms.setproperty(disconnect, 'Enabled', false)
        coroutine.yield(true)
      else
	      s, status, partial = client:receive("*l")
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

-- local inventory = mainmemory.readbyterange(0x11A644, 24)
-- print(inventory)

function Connect (args)
  HOST = forms.gettext(host)
  HOST = HOST:gsub(",", "")
  HOST = HOST:gsub(" ", "")
  PORT = forms.gettext(port)
  PORT = PORT:gsub(",", "")
  PORT = PORT:gsub(" ", "")
  USERNAME = forms.gettext(username)
  USERNAME = USERNAME:gsub(",", "")
  USERNAME = USERNAME:gsub(" ", "")
  COLOUR = forms.gettext(colour)
  COLOUR = COLOUR:gsub(",", "")
  COLOUR = COLOUR:gsub(" ", "")
  COLOUR = COLOUR:gsub("ping", "")
	file = io.open("info.txt", 'w')
	file:write(USERNAME .. "," .. HOST .. "," .. PORT .. "," .. COLOUR)
	file:close()
  forms.setproperty(connect, 'Enabled', false)
  forms.setproperty(disconnect, 'Enabled', true)
end

function Disconnect (args)
	disconn = true
	HOST, PORT, USERNAME, COLOUR = nil
	printOutput("Disconnected from server")
  forms.setproperty(connect, 'Enabled', true)
  forms.setproperty(disconnect, 'Enabled', false)
end

-- GUI
mainform = forms.newform(370, 240, "Map Watcher")
username = forms.textbox(mainform, un, 90, 20, nil, 70, 20, false, false)
host = forms.textbox(mainform, ip, 90, 20, nil, 70, 50, false, false)
port = forms.textbox(mainform, pt, 90, 20, nil, 70, 80, false, false)
colour = forms.textbox(mainform, cl, 90, 20, nil, 70, 110, false, false)
lblUsername = forms.label(mainform, "Username:", 10, 22)
lblHost = forms.label(mainform, "Host IP:", 22, 52)
lblPort = forms.label(mainform, "Port:", 38, 82)
lblColour = forms.label(mainform, "Colour:", 27, 112)
output = forms.textbox(mainform, "", 170, 170, nil, 170, 20, true, true, 'Vertical')
forms.setproperty(output, "ReadOnly", true)
connect = forms.button(mainform, "Connect", Connect, 10, 140, 151, 20)
disconnect = forms.button(mainform, "Disconnect", Disconnect, 10, 170, 151, 20)
forms.setproperty(disconnect, 'Enabled', false)

-- Checks to see if connection information is provided
function checkInfo ()
  while true do
    -- print("Here")
    if not HOST and not PORT and not USERNAME and not COLOUR then
      emu.frameadvance()
			coroutine.yield(false)
    else
      -- Create the client and connect
      printOutput("Attempting to connect to server...")
      client, err = socket.connect(HOST, PORT)
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
			client:send("username," .. USERNAME .. "," .. currentLocation .. "," .. COLOUR)
		end
	  while true do
	    -- Start the keepalive routine
	    status, check = coroutine.resume(pingRoutine)
	    if check then
				-- Reconnection code WIP
					-- client, err = socket.connect(HOST, PORT)
					-- if err then
					-- 	RECONATMP = RECONATMP + 1
					-- 	printOutput("Attempting to reconnect (" .. RECONATMP .. "/3)")
					-- end
					-- emu.frameadvance()
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
	    emu.frameadvance()
	  end
	end
end
