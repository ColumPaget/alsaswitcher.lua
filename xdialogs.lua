
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
