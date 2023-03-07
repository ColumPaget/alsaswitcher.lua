
require("stream")
require("strutil")
require("terminal")
require("process")
require("filesys")



function CommandLineParse(args)
local cmd={}

if #args == 0 then cmd.act="tui_menu"
else
	if args[1]=="-?" or args[1]=="-h" or args[1]=="-help" or args[1]=="--help" then cmd.act="help"
	else cmd.act=args[1]
	end
if cmd.act=="use" then cmd.dev=args[2] end
end

return cmd
end

function SoundDevices()
local mod

mod={}
mod.devices={}

mod.add=function(self, id, name)
  local dev, toks

  dev = {}
  dev.id = id

  toks=strutil.TOKENIZER(id, ":|,|.", "m")
  dev.subtype=toks:next()
  dev.devnum=toks:next()
  dev.subnum=toks:next()

  if strutil.strlen(name) == 0 then dev.name = id 
  else dev.name = name
  end

  table.insert(self.devices, dev)

  return dev
end


mod.read_pcm=function(self, name, toks)
local dev, str, bracecount

dev = self:add(name)
while str ~= "{" do str=toks:next() end
bracecount=1

str=toks:next()
while str ~= nil
do
  if str == "type" then self:readvalue(dev, "subtype", toks)
	elseif str == "device" then self:readvalue(dev, "device", toks) 
	elseif str == "{" then bracecount=bracecount + 1
	elseif str == "}" then bracecount=bracecount - 1
	end

	if bracecount < 1 then break end
str=toks:next()
end

end



mod.setvalue=function(self, dev, name, value)

  if name == "subtype"
    then
    dev.subtype = value
    if strutil.strlen(dev.device) > 0 then dev.name = dev.subtype .. "@" .. dev.device end
  end

  if name == "device"
    then
    dev.device = value
    if strutil.strlen(dev.subtype) > 0 then dev.name = dev.subtype .. "@" .. dev.device end
  end

end

mod.readvalue=function(self, dev, name, toks)
local str

str=toks:next()
while str==" " do str=toks:next()
self:setvalue(dev, name, str)
end	
end

mod.load_asoundrc=function(self, path)
  local S, str, toks, dev

  S = stream.STREAM(path, "r")
  if S ~= nil
    then
    toks = strutil.TOKENIZER(S:readdoc(), "\\S|{|}", "mQs")
    S:close()


    str = toks:next()
    while str ~= nil
      do

      if string.sub(str, 1, 4) == "pcm." then self:read_pcm(string.sub(str, 5), toks) end
      str = toks:next()
    end
  end

end



mod.parse_dev=function(self, id)
  local devnum, subnum
  local toks, tok

  toks = strutil.TOKENIZER(id, "-")
  devnum = tonumber(toks:next())
  tok = toks:next()
  if tok ~= nil then subnum = tonumber(tok) end

  id = "hw:" .. tostring(devnum) .. "," .. tostring(subnum)
  dev = self:add(id)
end


mod.load_pcms=function(self)
  local S, id, tok
  local playback_found = false

  S = stream.STREAM("/proc/asound/pcm", "r")
  if S ~= nil
    then
    str = S:readln()
    while str ~= nil
      do
      dev = nil
      toks = strutil.TOKENIZER(str, ":")
      id = strutil.trim(toks:next())
      tok = toks:next()

      while tok ~= nil
        do
        tok = strutil.trim(tok)
        if string.sub(tok, 1, 9) == "playback " 
          then
          self:parse_dev(id)
          playback_found = true
          break
        end
        tok = toks:next()
      end

      str = S:readln()
    end

    S:close()
  end

  return playback_found
end


mod.update_devs=function(self, dev_id, name)
  local id, dev

  for id, dev in pairs(self.devices)
    do
    toks = strutil.TOKENIZER(dev.id, ",")
    if toks:next() == dev_id  then dev.name = strutil.trim(name) end
  end

end


mod.load=function(self)
  local S, devnum, tok

  S = stream.STREAM("/proc/asound/cards", "r")
  if S ~= nil
    then
    str = S:readln()
    while str ~= nil
      do
      toks = strutil.TOKENIZER(str, "[|]:", "m")
      devnum = tonumber(strutil.trim(toks:next()))
      tok = toks:next() --throw away next token
      mod:update_devs("hw:" .. devnum, toks:remaining())

      str = S:readln() --throw away next line
      str = S:readln()
    end

    S:close()
  end

end


mod.find=function(self, devid)
local i, dev

for i,dev in ipairs(self.devices)
do
	if dev.id==devid then return dev end
end

return nil
end


mod.init=function(self)
  self:load_pcms(self.devices) 
  self:load()
  self:load_asoundrc("/etc/asound.conf")
  -- self:load_asoundrc(process.getenv("HOME") .. ".asoundrc")
end


mod:init()
return mod

end
function AsoundRC(devs, dev)
local mod={}


mod.open=function(self)
self.S=stream.STREAM(process.getenv("HOME").."/.asoundrc", "w")
if self.S ~= nil then return true end
return false
end

mod.close=function(self)
if self.S ~= nil then self.S:close() end
end


mod.write_hw_dev=function(self, dev)
	self.S:writeln("# "..dev.name.."\n")
	self.S:writeln("pcm.dev" .. dev.devnum.." {\n")
  self.S:writeln(" type hw\n")
  self.S:writeln(" card " .. dev.devnum .. " \n")
	self.S:writeln("}\n\n")
end

mod.write_bluealsa_dev=function(self, dev)
	self.S:writeln("# "..dev.id.."\n")
	self.S:writeln("pcm." .. dev.id.." {\n")
  self.S:writeln(" type plug\n")
  self.S:writeln(" slave.pcm { type bluealsa; service org.bluealsa; device \"" .. dev.device .. "\"; profile a2dp}\n")
	self.S:writeln("}\n\n")
end



mod.write_dev=function(self, dev)

if self.S ~= nil
then
	if dev.subtype == "hw" then self:write_hw_dev(dev) 
	elseif dev.subtype == "bluealsa" then self:write_bluealsa_dev(dev)
	end
end

end


mod.write_default=function(self, dev)

if dev.subtype=="hw" then self.S:writeln("pcm.!default {type=plug; slave.pcm=\"" .. "dev" .. dev.devnum .. "\"}\n")
else self.S:writeln("pcm.!default {type=plug; slave.pcm=\"" .. dev.id .. "\"}\n")
end

end

mod.process=function(self, devs, default_dev)
local i, dev

if self:open() == true
then
	for i, dev in ipairs(devs)
	do
	self:write_dev(dev)
	end

self:write_default(default_dev)
self:close()
end
end

mod:process(devs, dev)

end

function DeviceMenu(Term, devs, x, y, wide, high)
local Menu, i, dev, str

Menu=terminal.TERMMENU(Term, x, y, wide, high)
for i,dev in ipairs(devs.devices)
do
 Menu:add(dev.id..": "..dev.name, tostring(i))
end

str=Menu:run()
if strutil.strlen(str) > 0 then AsoundRC(devs.devices, devs.devices[tonumber(str)]) end

end

function DialogsProcessCmd(cmd, input)
local S, pid, str, status

S=stream.STREAM(cmd)
pid=S:getvalue("PeerPID")
if strutil.strlen(input) > 0 then S:writeln(input) end
S:commit()
str=S:readdoc()
if str ~= nil then str=strutil.trim(str) end
S:close()

status=process.childStatus(pid)
while status == "running"
do
process.sleep(0)
status=process.childStatus(pid)
end

--detect pressing 'cancel' and return nil
if status ~= "exit:0" then return nil end

-- str will be nil if user pressed cancel
if strutil.strlen(str) > 0
then 
toks=strutil.TOKENIZER(str, ":")
val=tonumber(toks:next())
if val ~= nil and val > 0 then AsoundRC(devs.devices, devs.devices[val]) end
end

return str
end




function ZenityStyleMenu(cmd, text, devs, title, width, height)
local str, val
local i, dev

str="cmd:"..cmd.." --list --hide-header --text='"..text.."' "
if width ~= nil and width > 0 then str=str.." --width "..tostring(width) end
if height ~= nil and height > 0 then str=str.." --height "..tostring(height) end
if title ~= nil then str=str.." --title='"..title.."' " end

for i,dev in ipairs(devs.devices)
do
str=str.. "'" .. tostring(i) .. ": ".. dev.id.." - "..dev.name .."' "
end

str=DialogsProcessCmd(str)
return str
end



function YadMenuDialog(text, devs, title)
local str, i, dev

str="cmd:yad --list --no-headers --column='c1' " 
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end

for i,dev in ipairs(devs.devices)
do
str=str.. "'" .. tostring(i) .. ": ".. dev.id.." - "..dev.name .."' "
end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str
end


function DMenuDialog(args, devs, title)
local cmd, str, i, dev

cmd="cmd:dmenu " .. args
str="" 
if strutil.strlen(title) > 0 then cmd=cmd.." -p '"..title.."'" end

for i,dev in ipairs(devs.devices)
do
str=str.. tostring(i) .. ": ".. dev.id.." - "..dev.name .."\n"
end

str=DialogsProcessCmd(cmd, str)
-- str will be nil if user pressed cancel
return str
end



function XDialogFindCommand(xdialog_types)
local path, toks, tok

path=process.getenv("PATH")
toks=strutil.TOKENIZER(xdialog_types, ",")
tok=toks:next()
while tok ~= nil
do
cmd=filesys.find(tok, path)
if strutil.strlen(cmd) > 0 then return tok,cmd end
tok=toks:next()
end

return nil
end



function XDialogMenu(devs, xdialog_types)
local cmd, dialog_type

dialog_type,cmd=XDialogFindCommand(xdialog_types)
if strutil.strlen(cmd) > 0
then
	if dialog_type=="zenity" or dialog_type=="qarma" then ZenityStyleMenu(cmd, "Select ALSA device", devs, "ALSAswitcher-"..version, 600, 200) end
	if dialog_type=="yad" then YadMenuDialog("ALSA", devs, "Select ALSA device") end
	if dialog_type=="dmenu" then DMenuDialog("", devs, "Select ALSA device") end
end

end
function PrintHelp()
print("alsaswitcher.lua version: "..version)
print("  alsaswitcher.lua             - run in 'terminal menu' mode")
print("  alsaswitcher.lua mini        - run in 'mini terminal menu' mode")
print("  alsaswitcher.lua list        - print list of available devices")
print("  alsaswitcher.lua use [dev]   - switch to specified device")
print("  alsaswitcher.lua zenity      - run in gui menu mode using zenity")
print("  alsaswitcher.lua qarma       - run in gui menu mode using zenity")
print("  alsaswitcher.lua yad         - run in gui menu mode using yad")
print("  alsaswitcher.lua gui         - run in any gui menu mode that we can")
end

function ListDevs(devs)
local i, item

for i,item in ipairs(devs.devices)
do
print(item.id .. ": " .. item.name)
end
end



function UseDev(devs, devid)
local dev, val

dev=devs:find(devid)
-- couldn't find device by id, try treating devid as an index in the devices table
if dev == nil
then
	val=tonumber(devid)
	if val ~= nil then dev=devs.devices[tonumber(devid)] end
end

print("DEV: "..tostring(dev))
if dev ~= nil then AsoundRC(devs.devices, dev) end

end





version="1.0"
devs=SoundDevices()
cmd=CommandLineParse(arg)


if cmd.act=="help" then PrintHelp(devs)
elseif cmd.act=="list" then ListDevs(devs)
elseif cmd.act=="use" then UseDev(devs, cmd.dev)
elseif cmd.act=="gui" then XDialogMenu(devs, "zenity,qarma,yad")
elseif cmd.act=="zenity" then XDialogMenu(devs, "zenity")
elseif cmd.act=="qarma" then XDialogMenu(devs, "qarma")
elseif cmd.act=="yad" then XDialogMenu(devs, "yad")
elseif cmd.act=="dmenu" then XDialogMenu(devs, "dmenu")
elseif cmd.act=="mini" then
Term=terminal.TERM(nil, "wheelmouse rawkeys save")
DeviceMenu(Term, devs, -1, -1, Term:width() -1, 1)
else
Term=terminal.TERM(nil, "wheelmouse rawkeys save")
Term:clear()
DeviceMenu(Term, devs, 1, 1, Term:width() -2, Term:length() -2)
end

