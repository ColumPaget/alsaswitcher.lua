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
