all:
	cat includes.lua command_line.lua sound_devices.lua asoundrc_write.lua menu.lua xdialogs.lua help.lua main.lua > alsaswitcher.lua
	chmod a+x alsaswitcher.lua
