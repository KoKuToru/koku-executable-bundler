koku-executable-bundler
=======================

Bundles a executable into a shell script and make it runnable on every linux system.

*It copies the libraries the executeable uses !*

If you want to shared the generated `shell-script`.
Make sure you are allowed to share the libraries !

Usage
-----
`sh createArchive.sh my_executeable file2_my_executeable_needs file2_my_executeable_needs`

How I use it
-----
Developing software on my desktop linux (Arch Linux).  
Make it very easy runnable on my server linux (very old Ubuntu).

How it works
------
Uses `ldd` to get the librarys the executeable needs to run.
Creates a `tar.gz` for these files.
Puts a payloader and the `tar.gz` into a shell-script.

When the shell-script gets executes,
it will extract to `/tmp` and execute the bundled executeable.

Todo
------
* Make it work with other loaders (only works with `ld-linux-x86-64.so.2` for now)
* Make a `--extract` for extracting the bundle...
