[![Actions Status](https://github.com/lizmat/IRC-Client-Plugin-Logger/actions/workflows/linux.yml/badge.svg)](https://github.com/lizmat/IRC-Client-Plugin-Logger/actions) [![Actions Status](https://github.com/lizmat/IRC-Client-Plugin-Logger/actions/workflows/macos.yml/badge.svg)](https://github.com/lizmat/IRC-Client-Plugin-Logger/actions) [![Actions Status](https://github.com/lizmat/IRC-Client-Plugin-Logger/actions/workflows/windows.yml/badge.svg)](https://github.com/lizmat/IRC-Client-Plugin-Logger/actions)

NAME
====

IRC::Client::Plugin::Logger - IRC logger for historic purposes

SYNOPSIS
========

```raku
use IRC::Client;
use IRC::Client::Plugin::Logger;

.run with IRC::Client.new(
  :nick<SomeBot>,
  :host<irc.libera.chat>,
  :channels<#channel1 #channel2>,
  :plugins(IRC::Client::Plugin::Logger.new(
     :directory<logs>,
     :debug,
     :normalizer(&normalizer),
     :now({ DateTime.now }),
     :next-date( -> $, $date { say $date }),
   )),
)
```

DESCRIPTION
===========

The `IRC::Client::Plugin::Logger` distribution exports a `IRC::Client::Plugin::Logger` class that is to be used as a plugin of the [`IRC::Client`](https://raku.land/zef:lizmat/IRC::Client) framework.

It is a simple IRC logger for `historical` purposes, so **not** for forensic logging. As such, it does **not** keep IP number information, user names nor exact timestamps.

It produces logs compatible with the "raw" format of the colabti.org IRC logger, which contains hh::mm timestamps, join / leave / nick notices and messages sent to the channel. It will not log messages that start with '[off]'.

PARAMETERS
==========

directory
---------

The directory in which the logs should be placed. It should be writable by the process that runs the `IRC::Client`.

debug
-----

A numeric value to indicate debug level. If it is non-zero, it will produce debugging output on STDERR.

next-date
---------

A `Callable` that should take the `IRC::CLient::Plugin::Logger` object as the first positional, and a string in the form of "YYYY-MM-DD" as the second positional argument. It will be called about 1 minute after the first message has been received on a new date. By default, the text "$yyyy-mm-dd has started on $directory" will be noted.

normalizer
----------

A `Callable` that should take the text to be logged and remove anything that is not considered fit for logging, and return that. Defaults to logic that removes control characters.

The default handler for `normalizer` can be obtained with the `default-normalizer` class method.

now
---

A `Callable` that should return a `DateTime` object to be used to determine date and time an event should be logged. Defaults to the current time in UTC. Mostly intended for testing purposes to get a reproducible logging result, but can also be used to e.g. have times logged in local time.

The default handler for `now` can be obtained with the `default-now` class method.

DIRECTORY STRUCTURE
===================

From the given directory, a directory will be made for each channel (excluding the `#` prefix). Inside it, a directory will be made for each year in which messages are logged. Inside that, a file will be made for each day that messages are logged, with the name of the format `YYYY-MM-DD`.

So, for logging the #raku channel on 22 April 2021 with a directory setting of `~/logs`, you will get:

    ~/logs/raku/2021/2021-04-22

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/IRC-Client-Plugin-Logger . Comments and Pull Requests are welcome.

If you like this module, or what I'm doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

COPYRIGHT AND LICENSE
=====================

Copyright 2021, 2025 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

