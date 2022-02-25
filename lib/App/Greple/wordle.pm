package App::Greple::wordle;
use v5.14;
use warnings;
use utf8;

our $VERSION = "0.01";

use Data::Dumper;
use Date::Calc qw(Delta_Days);
use charnames ':full';
use Getopt::EX::Colormap 'colorize';
use App::Greple::wordle::word_all    qw(%word_all);
use App::Greple::wordle::word_hidden qw(@word_hidden);

my $try = 6;
my $answer = $ENV{WORDLE_ANSWER};
my $random = $ENV{WORDLE_RANDOM};
my $compat = $ENV{WORDLE_COMPAT};
my $msg_correct = "\N{PARTY POPPER}";
my $msg_wrong   = "\N{COLLISION SYMBOL}";
my @answers;

sub initialize {
    my($mod, $argv) = @_;

    push @$argv, '--interactive', ('/dev/stdin') x 30
	if -t STDIN;

    my($mday, $mon, $year, $yday) = (localtime(time))[3,4,5,7];
    my $index = Delta_Days(2021, 6, 19, $year + 1900, $mon + 1, $mday);
    unless ($compat) {
	srand($index) unless $random;
	$index = int rand(@word_hidden);
    }
    $answer ||= $word_hidden[ $index ];
    length($answer) == 5 or die "$answer: wrong word\n";

    my $green = do {
	my @green;
	for my $n (0 .. 4) {
	    my $c = substr($answer, $n, 1);
	    push @green, "(?<=^.{$n})$c";
	}
	do { $" = '|'; qr/@green/mi };
    };
    my $yellow = qr/[$answer]/i;
    my $black  = qr/(?=[a-z])[^$answer]/i;

    $mod->setopt('--wordle',
		 qw( --cm 555/G --re ), "$green",
		 qw( --cm 555/Y --re ), "$yellow",
		 qw( --cm 555/k --re ), "$black",
	);
}

sub check {
    chomp;
    if (not $word_all{lc $_}) {
	say $msg_wrong;
	$_ = '';
    } else {
	push @answers, $_;
	$try--;
    }
}

sub inspect {
    if (lc $_ eq $answer) {
	say $msg_correct;
	exit 0;
    }
    if ($try == 0) {
	show_answer();
	exit 1;
    }
}

sub show_answer {
    say colorize('555/G', uc $answer);
}

1;

=encoding utf-8

=head1 NAME

App::Greple::wordle - wordle module for greple

=head1 SYNOPSIS

greple -Mwordle

=head1 DESCRIPTION

App::Greple::wordle is a greple module which implements wordle game.
Correctness is checked by regular expression.

Rule is almost same as original wordle but answer is different.  Daily
answer is updated 0AM localtime.

=begin html

<p><img width="50%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-wordle/main/images/screen.png">

=end html

=head1 BUGS

Wrong position character is colored yellow always, even if it is
colored green in other position.

=head1 ENVIRONMENT

=over 7

=item WORDLE_ANSWER

Set answer word.

=item WORDLE_RANDOM

Generate random answer every time.

=item WORDLE_COMPAT

Generate compatible answer with the original game.

=back

=head1 SEE ALSO

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__

# --wordle option is defined in initialize()

option default --need 1 --no-filename --wordle

# --interactive is set in initialize() when stdin is a tty

option --interactive \
       --if 'head -1' \
       --begin    &__PACKAGE__::check   \
       --end      &__PACKAGE__::inspect \
       --epilogue &__PACKAGE__::show_answer

#  LocalWords:  greple wordle localtime COMPAT Kazumasa Utashiro
