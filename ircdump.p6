#!/usr/bin/perl6

## Perl 6 script to extract content from irclog.perlgeek.de
##
## Designed for easy inlining of IRC discussions in bug reports for Perl 6.
## Example use case: While writing a bug report in vi, one can just enter:
##   :r !ircdump.p6 'http://irclog.perlgeek.de/perl6/2016-04-23#i_12381181'
## After that the exctracted lines can be adjusted
## 
## Usage:
##   ircdump.p6 [-l|--lines=<Int>] <url_full>   # default for -l is 20
##   ircdump.p6 [-u|--until=<Str>] <url_full>   # format for -u is 'HH:MM'

use v6;
use LWP::Simple;

my $github_link_script = 'https://github.com/usev6/dump-irc-logs';

my Regex $time = / \d\d\:\d\d /;

subset HourMin of Str where { $_ && $_ ~~ /^ $time $/  }

sub pretty_print(Str $line) {
    ## remove leading timestamp
    $line.subst(/^ $time \s*/, '');
}

sub get_start_time(Str $url) {
    my $anchor = $url.subst(/^.*\#/,'');
    for LWP::Simple.get($url).lines {
        return m/$time/ when / '<td class="time" id="' $anchor '">' /
    }
}

multi MAIN(Str $url_full, Int :l(:$lines) = 20) {
    my $time_start = get_start_time($url_full);
    my $txt = LWP::Simple.get($url_full.subst(/\#.*$/,'/text'));

    say "==== start of discussion on IRC -- cmp. $url_full";
    my Bool $start_found;
    my Int $line_counter = 0;
    for $txt.lines {
        $start_found = True if m/^ $time_start /;
	if $start_found {
            say pretty_print($_);
	    $line_counter++;
	    last if $line_counter == $lines;
	}
    }
    say "==== end of discussion on IRC -- powered by $github_link_script";
}

multi MAIN(Str $url_full, HourMin :u(:$until)) {
    my $time_start = get_start_time($url_full);
    my $txt = LWP::Simple.get($url_full.subst(/\#.*$/,'/text'));

    say "==== start of IRC discussion -- cmp. $url_full";
    for $txt.lines {
        say pretty_print($_) if /^ $time_start / ff /^ $until /;
    }
    say "==== end of IRC discussion -- powered by $github_link_script";
}
