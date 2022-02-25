package App::Greple::wordle;
use v5.14;
use warnings;
use utf8;

our $VERSION = "0.01";

use Data::Dumper;
use charnames ':full';
use Getopt::EX::Colormap 'colorize';
use App::Greple::wordle::word_all    qw(%word_all);
use App::Greple::wordle::word_hidden qw(@word_hidden);

my $try = 6;
my $answer = $ENV{WORDLE_ANSWER};
my $random = $ENV{WORDLE_RANDOM};
my $msg_correct = "\N{PARTY POPPER}";
my $msg_wrong   = "\N{COLLISION SYMBOL}";

sub initialize {
    my($mod, $argv) = @_;

    push @$argv, '--interactive', ('/dev/stdin') x 30
	if -t STDIN;

    unless ($random) {
	my($year, $yday) = (localtime(time))[5,7];
	srand($year * 1000 + $yday);
    }
    $answer ||= $word_hidden[ rand(@word_hidden) ];
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

App::Greple::wordle - world module for greple

=head1 SYNOPSIS

greple -Mwordle

=head1 DESCRIPTION

App::Greple::wordle is a greple module which implements wordle game.
Correctness is checked by regular expression.

=head1 BUGS

Wrong position character is colored yellow always, even if it is
colored green in other position.

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

option --interactive \
       --if 'head -1' \
       --begin    &__PACKAGE__::check   \
       --end      &__PACKAGE__::inspect \
       --epilogue &__PACKAGE__::show_answer
