
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

