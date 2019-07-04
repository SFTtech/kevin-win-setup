# kevin-win-setup
Tools to automatically download and prepare a free Windows VM for kevin.

# How
``` bash
make run
```

You will be dropped in a Windows 10 VM after a few minutes. Downloads will be cached for later.

# Status
* VirtIO storage, autologin, display resolution and a bunch more work.
* Chantal has not yet been ported to Windows, need to find out what exactly is missing for that.
* Reference setup stages for Openage are being worked on.

# U w0t? A Makefile?
Well, why not. There are a lot operations that involve building files from other files. Also this was a godd enough excuse to learn about some less well known features of `make`.
