local socket = require('socket')

-- Variables that will need to be given via GUI
local HOST, PORT = "localhost", 9999
local USERNAME = "ALinkToTheFuture"
local COLOUR = "#FF00FF"

-- Create the client and connect
client, err = socket.connect(HOST, PORT)

-- Keepalive function. Sends a ping every second telling the server it's still here
function keepalive ()
  start = os.time()
  while true do
    now = os.time()
    if os.difftime(now, start) >= 1 then
      pong = client:send("ping,")
      if not pong then
        print("Server closed")
        coroutine.yield(true)
      end
      s, status, partial = client:receive("*l")
      start = now
    end
    coroutine.yield(false)
  end
end

-- Create the coroutine for the keepalive function
pingRoutine = coroutine.create(keepalive)

-- Grab initial starting position
local currentLocation = mainmemory.read_u16_be(0x1C8544)

-- Variables for use later when I want to get pintpoint accuracy
local respawnLocation = mainmemory.read_u16_be(0x11B948)
local x = mainmemory.read_u16_be(0x1DAA54)
local y = mainmemory.read_u16_be(0x1DAA58)
local z = mainmemory.read_u16_be(0x1DAA5C)

-- If the socket couldn't connect, print and message and end everything
if err then
  print("Cannot connect to " .. HOST .. " on port " .. PORT)
else
  -- Send the identifying information to the server and start the main loop
  client:send("username," .. USERNAME .. "," .. currentLocation .. "," .. COLOUR)
  while true do
    -- Start the keepalive routine
    status, check = coroutine.resume(pingRoutine)
    if check then
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
