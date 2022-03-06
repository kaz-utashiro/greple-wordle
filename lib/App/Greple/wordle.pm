package App::Greple::wordle;
use v5.14;
use warnings;
use utf8;

our $VERSION = "0.06";

use Data::Dumper;
use List::Util qw(shuffle min max);
use Getopt::EX::Colormap qw(colorize ansi_code);
use Text::VisualWidth::PP 0.05 'vwidth';
use App::Greple::wordle::word_all    qw(%word_all);
use App::Greple::wordle::word_hidden qw(@word_hidden);
use App::Greple::wordle::hint qw(&keymap &result);

use Getopt::EX::Hashed; {
    Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] ) ;
    has answer  => ' =s   ' , default => $ENV{WORDLE_ANSWER} ;
    has index   => ' =s n ' , default => $ENV{WORDLE_INDEX} , any => qr/^[-+]?\d+$/;
    has count   => ' =i   ' , default => 6 ;
    has max     => ' =i   ' , default => 30 ;
    has random  => ' !    ' , default => 0 ;
    has series  => ' =s s ' , default => 1 ;
    has compat  => '      ' , action  => sub { $_->{series} = 0 } ;
    has keymap  => ' !    ' , default => 1 ;
    has result  => ' !    ' , default => 1 ;
    has correct => ' =s   ' , default => "\N{U+1F389}" ; # PARTY POPPER
    has wrong   => ' =s   ' , default => "\N{U+1F4A5}" ; # COLLISION SYMBOL

    has try     => default => 0;
    has answers => default => [];
}
no Getopt::EX::Hashed;

my $app = Getopt::EX::Hashed->new or die;

sub initialize {
    my($mod, $argv) = @_;
    use Getopt::Long qw(GetOptionsFromArray Configure);
    Configure qw(bundling no_getopt_compat pass_through);
    $app->getopt($argv) || die "Option parse error.\n";
}

sub finalize {
    my($mod, $argv) = @_;
    push @$argv, '--interactive', ('/dev/stdin') x $app->max
	if -t STDIN;
}

sub respond {
    local $_ = $_;
    my $chomped = chomp;
    print ansi_code("{CHA}{CUU}") if $chomped;
    print ansi_code(sprintf("{CHA}{CUF(%d)}", max(8, vwidth($_) + 2)));
    print s/(?<=.)\z/\n/r for @_;
}

sub days {
    use Date::Calc qw(Delta_Days);
    my($mday, $mon, $year, $yday) = (localtime(time))[3,4,5,7];
    Delta_Days(2021, 6, 19, $year + 1900, $mon + 1, $mday);
}

sub wordle_patterns {
    for ($app->{index}) {
	$_   = int rand @word_hidden if $app->random;
	$_ //= days;
	$_  += days if /^[-+]/;
    }
    if ($app->series > 0) {
	srand($app->series);
	@word_hidden = shuffle @word_hidden;
    }
    my $answer = $app->answer;
    $answer ||= $word_hidden[ $app->index ];
    $answer =~ /^[a-z]{5}$/i or die "$answer: wrong word\n";

    my $green  = join '|', map sprintf("(?<=^.{%d})%s", $_, substr($answer, $_, 1)), 0..4;
    my $yellow = "[$answer]";
    my $black  = "(?=[a-z])[^$answer]";

    $app->answer($answer);
    map { ( '--re' => $_ ) } $green, $yellow, $black;
}

sub show_answer {
    say colorize('#6aaa64', uc $app->answer);
}

sub show_result {
    printf("\n%s %s%s %d/%d\n\n",
	   'Greple::wordle',
	   $app->series == 0 ? '' : sprintf("%d-", $app->series),
	   $app->index,
	   $app->try + 1, $app->count);
    say result($app->answer, @{$app->answers});
}

sub check {
    my $it = lc s/\n//r;
    if (not $word_all{$it}) {
	respond $app->wrong;
	$_ = '';
    } else {
	push @{$app->answers}, $it;
	print ansi_code '{CUU}';
    }
}

sub inspect {
    my $it = lc s/\n//r;
    if (lc $it eq lc $app->answer) {
	respond $app->correct x ($app->count - $app->try);
	show_result if $app->result;
	exit 0;
    }
    length or return;
    if (++$app->{try} >= $app->count) {
	show_answer;
	exit 1;
    }
    $app->keymap and respond keymap($app->answer, @{$app->answers});
}

1;

__DATA__

mode function

option --wordle &wordle_patterns

define GREEN  #6aaa64
define YELLOW #c9b458
define BLACK  #787c7e

option default \
	-i --need 1 --no-filename \
	--cm 555/GREEN  \
	--cm 555/YELLOW \
	--cm 555/BLACK  \
	$<move> \
	--wordle

# --interactive is set in initialize() when stdin is a tty

option --interactive \
       --if 'head -1' \
       --begin    __PACKAGE__::check   \
       --end      __PACKAGE__::inspect \
       --epilogue __PACKAGE__::show_answer
