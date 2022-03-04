package App::Greple::wordle::result;
use v5.14;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = qw(&result);

use charnames ':full';
use Data::Dumper;
use List::MoreUtils qw(pairwise);
use Getopt::EX::Colormap qw(colorize);

my %square = (
    G => "\N{LARGE GREEN SQUARE}",
    Y => "\N{LARGE YELLOW SQUARE}",
    K => "\N{WHITE LARGE SQUARE}",
    );

sub result {
    my @result = make_result(map lc, @_);
    my $result = join "\n", map s/([GYK])/$square{$1}/ger, @result;
    $result;
}

sub make_result {
    my $answer = shift;
    my %a = map { $_ => 1 } my @a = $answer =~ /./g;
    map {
	my @b = /./g;
	join '', pairwise {
	    $a eq $b ? 'G' : $a{$b} ? 'Y' : 'K'
	} @a, @b;
    } @_;
}

1;
