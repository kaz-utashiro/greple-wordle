package App::Greple::wordle::game;
use v5.14;
use warnings;

use Data::Dumper;
use List::MoreUtils qw(pairwise);
use Getopt::EX::Colormap qw(colorize);

use Mo qw(is required default); {
    has answer   => ( is => 'ro', required => 1 );
    has attempts => ( default => [] );
}
no Mo;

sub try {
    my $obj = shift;
    push @{$obj->{attempts}}, @_;
    $obj->solved;
}

sub attempt {
    my $obj = shift;
    int @{$obj->{attempts}};
}

sub solved {
    my $obj = shift;
    lc $obj->{answer} eq lc $obj->{attempts}->[-1];
}

######################################################################
# keymap
######################################################################

my %cmap = (
    G => '555/#6aaa64',
    Y => '555/#c9b458',
    K => '#787c7e/#787c7e',
    _ => '555/#787c7e',
    );

sub keymap {
    my $obj = shift;
    my %keys = _keymap(map { lc } $obj->{answer}, @{$obj->{attempts}});
    my $keys = join '', map colorize($cmap{$keys{$_}//'_'}, $_), 'a'..'z';
    $keys;
}

sub _keymap {
    my $answer = shift;
    my %a = map { $_ => 1 } my @a = $answer =~ /./g;
    my %keys;
    for my $try (@_) {
	my @b = $try =~ /./g;
	pairwise { $keys{$a} = 'G' if $a eq $b } @a, @b;
	$keys{$_} ||= $a{$_} ? 'Y' : 'K' for @b;
    }
    %keys;
}

######################################################################
# result
######################################################################

my %square = (
    G => "\N{U+1F7E9}", # LARGE GREEN SQUARE
    Y => "\N{U+1F7E8}", # LARGE YELLOW SQUARE
    K => "\N{U+2B1C}",  # WHITE LARGE SQUARE
    );

sub result {
    my $obj = shift;
    my @result = _result(map lc, $obj->{answer}, @{$obj->{attempts}});
    my $result = join "\n", map s/([GYK])/$square{$1}/ger, @result;
    $result;
}

sub _result {
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
