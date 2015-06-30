#**A Friendly Unix Alarm Clock**
---

A bash shell script to simulate a 3-stage alarmclock. 
Hey, why not?! It starts gently with birdsong, then a clock chimes, then you get
the air-raid siren. Comes with bells & whistles, including coloured & flashing text, no less!

I'd appreciate your feedback! "mi55 ing" (mi55ing@protonmail.com), 
especially for later versions of OSX and more obscure distros.
If reporting an error, please state your Linux flavour & version.

**Usage:**

```./alarmclock.sh {-t HH:MM -d DD -h HH -m MM -s SS} [-msg 'yourtext']```

**Requires:**

at least one of ```aplay```, ```afplay```, ```mplayer```, or ```play```.

**OSX Notes:**

If using OSX, you can 'Enable Assistive Devices' 
to allow the screen to focus on the alarm window when the alarm goes off.
 - OSX Snow Leopard: see (System Preferences > Universal Access)
 - OSX Mavericks: (System Preferences > Security & Privacy > Privacy > Accessibility)  and check 'Terminal.app'  

In OSX, you can also enable "Visual bell" & "Audible bell" in Terminal.app, to enable the screen to flash and beep. 
 - (OSX: Terminal > Preferences > Advanced) and check the boxes for "Audible bell" & "Visual bell".

**Gnome Terminal & Konsole Notes:**

I have yet to find a way to raise the Gnome Terminal/Konsole windows to the front when the alarm goes off. The ANSI escape codes simply
do not work. If you are aware of a way to do this, please let me know! 