


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

