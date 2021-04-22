[![Actions Status](https://github.com/lizmat/IRC-Client-Plugin-Logger/workflows/test/badge.svg)](https://github.com/lizmat/IRC-Client-Plugin-Logger/actions)

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
  :host<irc.freenode.org>,
  :channels<#channel1 #channel2>,
  :plugins(IRC::Client::Plugin::Logger.new(:directory<logs>,:debug)),
)
```

DESCRIPTION
===========

IRC::Client::Plugin::Logger exports a class that is to be used as a plugin of the [IRC::Client](IRC::Client) framework.

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

now
---

A `Callable` that should return a `DateTime` object to be used to determine date and time an event should be logged. Defaults to the current time in UTC. Mostly intended for testing purposes to get a reproducible logging result, but can also be used to e.g. have times logged in local time.

DIRECTORY STRUCTURE
===================

From the given directory, a directory will be made for each channel (excluding the `#` prefix). Inside it, a directory will be made for each year in which messages are logged. Inside that, a file will be made for each day that messages are logged, with the name of the format `YYYY-MM-DD`.

So, for logging the #raku channel on 22 April 2021 with a directory setting of `~/logs`, you will get:

    ~/logs/raku/2021/2021-04-22

AUTHOR
======

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/IRC-Client-Plugin-Logger . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

