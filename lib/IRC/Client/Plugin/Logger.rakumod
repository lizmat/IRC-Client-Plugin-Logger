use IRC::Client:ver<4.0.7>:auth<zef:lizmat>;

my sub default-normalizer($text) {
    $text.subst("\x7F", '^H', :global)
         .subst("\x17", '^W', :global)
         .subst(/ "\x03" \d? /,                             :global)
         .subst(/ <[\x00..\x1f] - [\x09..\x0a] - [\x0d]> /, :global)
         .subst(/ '[' [ \d ';' ]? \d ** 1..2 m /,           :global)
}

my sub default-now() { DateTime.now.utc }

my sub default-next-date($logger, $yyyy-mm-dd --> Nil) {
    note "$yyyy-mm-dd has started on $logger.directory()";
}

class IRC::Client::Plugin::Logger:ver<0.0.11>:auth<zef:lizmat> {
    has IO()  $.directory is required;
    has Int() $.debug      = 0;
    has       &.normalizer = &default-normalizer;
    has       &.now        = &default-now;
    has       &.next-date  = &default-next-date;
    has       %!channels;  # %!channels<nick><channel> = 1
    has str   $!last-yyyy-mm-dd = &!now().yyyy-mm-dd;

    my constant Join    = IRC::Client::Message::Join;
    my constant PrivMsg = IRC::Client::Message::Privmsg::Channel;
    my constant Mode    = IRC::Client::Message::Mode::Channel;
    my constant Nick    = IRC::Client::Message::Nick;
    my constant Numeric = IRC::Client::Message::Numeric;
    my constant Part    = IRC::Client::Message::Part;
    my constant Topic   = IRC::Client::Message::Topic;
    my constant Quit    = IRC::Client::Message::Quit;

    method !log(Str:D $channel, Str:D $text --> Nil) {
        my $now := &!now();
        my $dir := $!directory.add($channel.substr(1)).add($now.year);
        $dir.mkdir unless $dir.e;

        my str $yyyy-mm-dd = $now.yyyy-mm-dd;
        my str $hour       = $_ < 10 ?? "0" ~ $_ !! .Str given $now.hour;
        my str $minute     = $_ < 10 ?? "0" ~ $_ !! .Str given $now.minute;
        $dir.add($yyyy-mm-dd).spurt:
          '[' ~ $hour ~ ':' ~ $minute ~ '] ' ~ $text ~ "\n",
          :append;

        if $!last-yyyy-mm-dd ne $yyyy-mm-dd {
            $*SCHEDULER.cue: { &!next-date(self, $yyyy-mm-dd) }, :in(60);
            $!last-yyyy-mm-dd = $yyyy-mm-dd;
        }
    }

    method !debug($event --> Nil) {
        if $!debug > 1 {
            if $event.?channel -> $channel {
                note "$channel: $event";
            }
            else {
                note $event;
            }
        }
    }

    method irc-to-me($event) {
        $event.reply:
          "Logging {$event.channel} with Raku module {self.^name} {self.^ver}";
    }

    proto method irc-all($event) {
        note $event.^name if $!debug;
        {*}
    }

    multi method irc-all(Join:D $event --> Nil) {
        my $nick := $event.nick;

        if $nick eq $event.server.current-nick {
            self!debug($event) if $!debug;
        }
        else {
            my $channel := $event.channel;
            self!log: $channel, "*** $nick joined";
            %!channels{$nick}{$channel} := 1;
        }
    }

    multi method irc-all(PrivMsg:D $event --> Nil) {
        my $text := $event.text;

        self!log(
          $event.channel,
          $text.substr-eq("ACTION ",1)
            ?? "* $event.nick() &!normalizer($event.text.substr(8,*-1))\n"
            !! "<$event.nick()> &!normalizer($event.text)\n"
        ) unless $text.starts-with('[off]');
    }

    multi method irc-all(Mode:D $event --> Nil) {
        self!log:
          $event.channel,
          "*** $event.nick() sets mode: $event.mode() $event.nicks()\n";
    }

    multi method irc-all(Nick:D $event --> Nil) {
        my $old-nick := $event.nick;
        my $new-nick := $event.new-nick;

        self!log: $_, "*** $old-nick is now known as $new-nick\n"
          for %!channels{$old-nick}.keys;

        %!channels{$new-nick} = %!channels{$old-nick}:delete;
    }

    multi method irc-all(Numeric:D $event --> Nil) {
        if $event.command == 353 {   # listing nicks on channels
            my $channel := $event.args[2];
            %!channels{$_}{$channel} := 1 for $event.args[3].words;
        }
        else {
            self!debug($event);
        }
    }

    multi method irc-all(Part:D $event --> Nil) {
        my $nick    := $event.nick;
        my $channel := $event.channel;
        self!log: $channel, "*** $nick left";
        %!channels{$nick}{$channel}:delete;
    }

    multi method irc-all(Quit:D $event --> Nil) {
        my $nick := $event.nick;

        if %!channels{$nick}:delete -> $channels {
            self!log: $_, "*** $nick left" for $channels.keys;
        }
    }

    multi method irc-all(Topic:D $event --> Nil) {
        self!log:
          $event.channel,
          "*** $event.nick() changes topic to: $event.text()";
    }

    multi method irc-all($event --> Nil) {
        self!debug($event);
    }

    method default-normalizer() { &default-normalizer }
    method default-now()        { &default-now        }
}

=begin pod

=head1 NAME

IRC::Client::Plugin::Logger - IRC logger for historic purposes

=head1 SYNOPSIS

=begin code :lang<raku>

use IRC::Client;
use IRC::Client::Plugin::Logger;

.run with IRC::Client.new(
  :nick<SomeBot>,
  :host<irc.freenode.org>,
  :channels<#channel1 #channel2>,
  :plugins(IRC::Client::Plugin::Logger.new(
     :directory<logs>,
     :debug,
     :normalizer(&normalizer),
     :now({ DateTime.now }),
     :next-date( -> $, $date { say $date }),
   )),
)

=end code

=head1 DESCRIPTION

IRC::Client::Plugin::Logger exports a class that is to be used as a
plugin of the L<IRC::Client> framework.

It is a simple IRC logger for C<historical> purposes, so B<not> for
forensic logging.  As such, it does B<not> keep IP number information,
user names nor exact timestamps.

It produces logs compatible with the "raw" format of the colabti.org
IRC logger, which contains hh::mm timestamps, join / leave / nick
notices and messages sent to the channel.  It will not log messages
that start with '[off]'.

=head1 PARAMETERS

=head2 directory

The directory in which the logs should be placed.  It should be writable
by the process that runs the C<IRC::Client>.

=head2 debug

A numeric value to indicate debug level.  If it is non-zero, it will
produce debugging output on STDERR.

=head2 next-date

A C<Callable> that should take the C<IRC::CLient::Plugin::Logger> object
as the first positional, and a string in the form of "YYYY-MM-DD" as the
second positional argument.  It will be called about 1 minute after the
first message has been received on a new date.  By default, the text
"$yyyy-mm-dd has started on $directory" will be noted.

=head2 normalizer

A C<Callable> that should take the text to be logged and remove anything
that is not considered fit for logging, and return that.  Defaults to
logic that removes control characters.

The default handler for C<normalizer> can be obtained with the
C<default-normalizer> class method.

=head2 now

A C<Callable> that should return a C<DateTime> object to be used to
determine date and time an event should be logged.  Defaults to the
current time in UTC.  Mostly intended for testing purposes to get a
reproducible logging result, but can also be used to e.g. have times
logged in local time.

The default handler for C<now> can be obtained with the C<default-now>
class method.

=head1 DIRECTORY STRUCTURE

From the given directory, a directory will be made for each channel
(excluding the C<#> prefix).  Inside it, a directory will be made for
each year in which messages are logged.  Inside that, a file will be
made for each day that messages are logged, with the name of the
format `YYYY-MM-DD`.

So, for logging the #raku channel on 22 April 2021 with a directory
setting of C<~/logs>, you will get:

    ~/logs/raku/2021/2021-04-22

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/IRC-Client-Plugin-Logger .
Comments and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
