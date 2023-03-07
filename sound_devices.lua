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
