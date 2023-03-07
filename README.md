SYNOPSIS
========

A crude 'switcher' app that changes the default ALSA sound device set up in '~/.asoundrc'. It scans currently connected hardware, and also for any bluealsa devices configured in '/etc/asound.conf', and writes a '~/.asoundrc' featuring these devices, with the selected one set as the default device. 


INSTALL
=======

'make' should rebuild 'alsaswitcher.lua' if needed. 'alsaswitcher.lua' can run with 'lua alsaswitcher.lua' or can be copied to a directory in your path and run using linux's 'binfmt' system.


USAGE
=====

```
  alsaswitcher.lua             - run in 'terminal menu' mode
  alsaswitcher.lua list        - print list of available devices
  alsaswitcher.lua use [dev]   - switch to specified device
  alsaswitcher.lua mini        - run in 'mini terminal menu' mode
  alsaswitcher.lua zenity      - run in gui menu mode using zenity
  alsaswitcher.lua qarma       - run in gui menu mode using zenity
  alsaswitcher.lua yad         - run in gui menu mode using yad
  alsaswitcher.lua gui         - run in any gui menu mode that we can
```


AUTHOR/LICENSE
==============

alsaswitcher is copyright 2023 by Colum Paget. It is released under the GPL v3.
