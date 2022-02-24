package App::Greple::wordle;
use v5.14;
use warnings;

our $VERSION = "0.01";

my $try = 6;
my $answer;

use Data::Dumper;
use App::Greple::wordle::word_all    qw(%word_all);
use App::Greple::wordle::word_hidden qw(@word_hidden);

sub initialize {
    my($mod, $argv) = @_;

    push @$argv, '--read-one-line', ('/dev/stdin') x 30
	if -t STDIN;

    my($year, $yday) = (localtime(time))[5,7];
    srand($year * 1000 + $yday);
    $answer = $word_hidden[ rand(@word_hidden) ];
    length($answer) == 5 or die;

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

    my @opt = (
	qw( --cm 555/G   --re ), "$green",
	qw( --cm 555/Y   --re ), "$yellow",
	qw( --cm 555/L10 --re ), "$black",
	);

    $mod->setopt('default',
		 $mod->default, @opt);
}

sub check {
    return unless /\A.*\n\z/;
    chomp;
    if (not $word_all{lc $_}) {
	say "error";
	$_ = '';
    } else {
	$try--;
    }
}

sub inspect {
    return if /\n./;
    if (lc $_ eq $answer) {
	say "Yes!";
	exit 0;
    }
    if ($try == 0) {
	say uc($answer);
	exit 1;
    }
}

1;

=encoding utf-8

=head1 NAME

App::Greple::wordle - world module for greple

=head1 SYNOPSIS

greple -Mwordle answer

=head1 DESCRIPTION

App::Greple::wordle is a greple module which implements wordle game.
Correctness is checked by regular expression.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__

option default --play

option --read-one-line --if 'head -1'

option --play \
       --need 1 \
       --no-filename \
       --begin &__PACKAGE__::check \
       --end   &__PACKAGE__::inspect
