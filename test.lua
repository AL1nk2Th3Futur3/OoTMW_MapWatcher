local http = require("socket.http")

-- Variables
local username, password, roomname
local loggedIn = false
local id = nil
local ip = "10.144.110.73"
local port = "5000"

-- Room submission function
function submit_room (args)
  -- print(forms.gettext(username))
  -- print(forms.gettext(password))
  -- print(forms.gettext(roomname))
  local currentLocation = mainmemory.read_u16_be(0x1C8544)
  data = http.request('http://'..ip..':'..port..'/login' ..
    "?username=" .. forms.gettext(username) ..
    "&password=" .. forms.gettext(password) ..
    "&roomname=" .. forms.gettext(roomname) ..
    "&location=" .. currentLocation
  )
  id = data
  loggedIn = true
end

-- GUI
mainform = forms.newform(200, 300, "MapWatcher")
lblUsername = forms.label(mainform, "Username:", 10, 20)
username = forms.textbox(mainform, "", 160, 20, nil, 10, 45, false, false)
lblPassword = forms.label(mainform, "Password:", 10, 80)
password = forms.textbox(mainform, "", 160, 20, nil, 10, 105, false, false)
lblRoomname = forms.label(mainform, "Room Name:", 10, 140)
roomname = forms.textbox(mainform, "", 160, 20, nil, 10, 165, false, false)
submit = forms.button(mainform, "Submit", submit_room, 10, 200, 160, 20)
forms.setproperty(password, 'PasswordChar', '*')


-- Main loop
while true do
  if loggedIn == true then
    if currentLocation ~= mainmemory.read_u16_be(0x1C8544) then
      currentLocation = mainmemory.read_u16_be(0x1C8544)
      if currentLocation <= 109 then
        data, err = http.request("http://"..ip..':'..port.."/updatemap" ..
          "?location=" .. currentLocation ..
          "&id=" .. id
        )
      end
    end
  end
  -- gui.text(0,110,currentLocation)
  emu.frameadvance()
end
