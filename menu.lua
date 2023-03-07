
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
