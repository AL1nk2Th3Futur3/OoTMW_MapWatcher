local socket = require('socket')
local http = require('socket.http')

local HOST, PORT, FPORT = '127.0.0.1', 50001, 8000

local client, err
local mainform, usernameTxt, passwordTxt, roomTxt, colourTxt, connect, disconnect
local usernameLbl, passwordLbl, roomLbl, colourLbl
local username, password, room, colour
local keepaliveRoutine

local currentLocation = mainmemory.read_u16_be(0x1C8544)
local items = mainmemory.readbyterange(0x11A644, 24)
local equipment = mainmemory.readbyterange(0x11A66B, 3)
local upgrades = mainmemory.readbyterange(0x11A670, 4)
local questitems = mainmemory.readbyterange(0x11A674, 4)
local maxhearts = mainmemory.read_u16_be(0x11A5FE)
local currenthearts = mainmemory.read_u16_be(0x11A600)
local rupees = mainmemory.read_u16_be(0x11A604)
local skulltulas = mainmemory.read_u16_be(0x11A6A0)

function splitstr (str, n)
  info = {}
	for s in string.gmatch(str, "([^"..n.."]+)") do
		table.insert(info, s)
	end
  return info
end

-- Exit function
event.onexit(function ()
	forms.destroy(mainform)
end)

-- Keepalive function
function keepalive ()
  if not err then
    local start = os.time()
    while true do
      local now = os.time()
      if os.difftime(now, start) >= 5 then
        start = now
        local alive = client:send(now)
        if not alive then
          break
        end
        coroutine.yield(true)
      else
        coroutine.yield(false)
      end
    end
  end
end

-- Connect button
function Connect (args)
  -- Keepalive routine
  keepaliveRoutine = coroutine.create(keepalive)
  client, err = socket.connect(HOST, PORT)
  if not err then
    -- print("Connected to server")
    username = forms.gettext(usernameTxt)
    username = username:gsub(",", "")
    colour = forms.gettext(colourTxt)
    colour = colour:gsub(",", "")
    room = forms.gettext(roomTxt)
    room = room:gsub(",", "")
    password = forms.gettext(passwordTxt)
    password = password:gsub(",", "")
    data = http.request('http://' .. HOST .. ":" .. FPORT .. "/checkRoom?room=" .. room .. "&password=" .. password)
    data = splitstr(data, ',')
    local tmpItems = items[0]
    for i=1,23 do
      tmpItems = tmpItems .. "," .. items[i]
    end
    local tmpUpgrades = upgrades[0]
    for i=1,3 do
      tmpUpgrades = tmpUpgrades .. ',' .. upgrades[i]
    end
    local tmpQuest = questitems[0]
    for i=1,3 do
      tmpQuest = tmpQuest .. ',' .. questitems[i]
    end
    print(data[1])
    if data[1] ~= "Password incorrect" then
      print(currentLocation)
      client:send('join,'
        .. username .. ','
        .. colour .. ','
        .. room .. ','
        .. password .. ','
        .. data[2] .. ','
        .. currentLocation .. ','
        .. tmpItems .. ','
        .. equipment[1] .. ',' .. equipment[2] .. ','
        .. tmpUpgrades .. ','
        .. tmpQuest .. ','
        .. maxhearts .. ',' .. currenthearts .. ','
        .. rupees .. ','
        .. skulltulas

      )
      forms.setproperty(usernameTxt, 'Enabled', false)
      forms.setproperty(passwordTxt, 'Enabled', false)
      forms.setproperty(colourTxt, 'Enabled', false)
      forms.setproperty(roomTxt, 'Enabled', false)
      forms.setproperty(connect, 'Enabled', false)
      forms.setproperty(disconnect, 'Enabled', true)
      return
    end
    client:close()
    client = nil
  end
end

-- Disconnect Function
function Disconnect ()
  client:close()
  client = nil
  forms.setproperty(usernameTxt, 'Enabled', true)
  forms.setproperty(passwordTxt, 'Enabled', true)
  forms.setproperty(colourTxt, 'Enabled', true)
  forms.setproperty(roomTxt, 'Enabled', true)
  forms.setproperty(connect, 'Enabled', true)
  forms.setproperty(disconnect, 'Enabled', false)
  print("Disconnected")
end

-- GUI
mainform = forms.newform(200, 300, "Map Watcher")
  -- Text boxes
  usernameTxt = forms.textbox(mainform, "", 90, 20, nil, 70, 20, false, false)
  colourTxt = forms.textbox(mainform, "#000000", 90, 20, nil, 70, 50, false, false)
  roomTxt = forms.textbox(mainform, "", 90, 20, nil, 70, 80, false, false)
  passwordTxt = forms.textbox(mainform, "", 90, 20, nil, 70, 110, false, false)
  -- Labels
  usernameLbl = forms.label(mainform, "Username:", 10, 22)
  colourLbl = forms.label(mainform, "Colour:", 27, 52)
  roomLbl = forms.label(mainform, "Room:", 29, 82)
  passwordLbl = forms.label(mainform, "Password:", 11, 112)
  -- Buttons
  connect = forms.button(mainform, "Connect", Connect, 10, 140, 151, 20)
  disconnect = forms.button(mainform, "Disconnect", Disconnect, 10, 165, 151, 20)
  -- Settings
  forms.setproperty(disconnect, 'Enabled', false)
  forms.setproperty(passwordTxt, 'PasswordChar', '*')


-- Main loop
while true do
  if forms.gettext(mainform) == "" then
		return
	end
  if client then
    local status, info = coroutine.resume(keepaliveRoutine)
    if coroutine.status(keepaliveRoutine) == 'dead' then
      print("Server closed")
      client:close()
      client = nil
      forms.setproperty(usernameTxt, 'Enabled', true)
      forms.setproperty(passwordTxt, 'Enabled', true)
      forms.setproperty(colourTxt, 'Enabled', true)
      forms.setproperty(roomTxt, 'Enabled', true)
      forms.setproperty(connect, 'Enabled', true)
      forms.setproperty(disconnect, 'Enabled', false)
    end

    -- Send the server the user's location each time it changes
    if currentLocation ~= mainmemory.read_u16_be(0x1C8544) then
      currentLocation = mainmemory.read_u16_be(0x1C8544)
      if currentLocation <= 109 then
        client:send("location," .. currentLocation)
      end
    end

    -- When a new item is obtained
    if table.concat(items) ~= table.concat(mainmemory.readbyterange(0x11A644, 24)) then
      items = mainmemory.readbyterange(0x11A644, 24)
      local msg = 'items'
      for i=0,23 do
        msg = msg .. "," .. items[i]
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
      end
      client:send(msg)
    end

    -- When a quest item is obtained, send it
    if table.concat(questitems) ~= table.concat(mainmemory.readbyterange(0x11A674, 4)) then
      questitems = mainmemory.readbyterange(0x11A674, 4)
      msg = 'questitems'
      for i=0,3 do
        msg = msg .. "," .. questitems[i]
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

    -- Add game reading code here
  end
  emu.yield()
  emu.yield()
end
