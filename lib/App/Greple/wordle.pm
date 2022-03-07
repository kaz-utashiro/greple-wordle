package App::Greple::wordle;
use v5.14;
use warnings;
use utf8;

our $VERSION = "0.07";

use Data::Dumper;
use List::Util qw(shuffle);
use Getopt::EX::Colormap qw(colorize ansi_code);
use Text::VisualWidth::PP 0.05 'vwidth';
use App::Greple::wordle::word_all    qw(%word_all);
use App::Greple::wordle::word_hidden qw(@word_hidden);
use App::Greple::wordle::game;

use Getopt::EX::Hashed; {
    has answer  => ' =s   ' , default => $ENV{WORDLE_ANSWER} ;
    has index   => ' =s n ' , default => $ENV{WORDLE_INDEX} , any => qr/^[-+]?\d+$/;
    has try     => ' =i   ' , default => 6 ;
    has total   => ' =i   ' , default => 30 ;
    has random  => ' !    ' , default => 0 ;
    has series  => ' =s s ' , default => 1 ;
    has compat  => '      ' , action  => sub { $_->{series} = 0 } ;
    has keymap  => ' !    ' , default => 1 ;
    has result  => ' !    ' , default => 1 ;
    has correct => ' =s   ' , default => "\N{U+1F389}" ; # PARTY POPPER
    has wrong   => ' =s   ' , default => "\N{U+1F4A5}" ; # COLLISION SYMBOL
}
no Getopt::EX::Hashed;

sub parseopt {
    my $app = shift;
    my $argv = shift;
    use Getopt::Long qw(GetOptionsFromArray Configure);
    Configure qw(bundling no_getopt_compat pass_through);
    $app->getopt($argv) || die "Option parse error.\n";
}

sub _days {
    use Date::Calc qw(Delta_Days);
    my($mday, $mon, $year, $yday) = (localtime(time))[3,4,5,7];
    Delta_Days(2021, 6, 19, $year + 1900, $mon + 1, $mday);
}

sub get_index {
    my $app = shift;
    local $_ = $app->{index};
    $_   = int rand @word_hidden if $app->{random};
    $_ //= _days;
    $_  += _days if /^[-+]/;
    $_;
}

######################################################################

my $app = __PACKAGE__->new or die;
my $game;

sub initialize {
    my($mod, $argv) = @_;
    $app->parseopt($argv);

    my $answer = make_answer();
    $game = App::Greple::wordle::game->new(answer => $answer);

    push @$argv, wordle_patterns($answer);
    push @$argv, '--interactive', ('/dev/stdin') x $app->{total}
	if -t STDIN;
}

sub respond {
    local $_ = $_;
    my $chomped = chomp;
    use List::Util qw(max);
    print ansi_code("{CHA}{CUU}") if $chomped;
    print ansi_code(sprintf("{CHA}{CUF(%d)}", max(8, vwidth($_) + 2)));
    print s/(?<=.)\z/\n/r for @_;
}

sub make_answer {
    if ($app->{series} > 0) {
	srand($app->{series});
	@word_hidden = shuffle @word_hidden;
    }
    my $answer = $app->{answer};
    $answer ||= $word_hidden[ $app->get_index ];
    $answer =~ /^[a-z]{5}$/i or die "$answer: wrong word\n";
    return $answer;
}

sub wordle_patterns {
    my $answer = shift;
    my @re = map
	    { sprintf "(?<=^.{%d})%s", $_, substr($answer, $_, 1) }
	    0 .. length($answer) - 1;
    my $green  = join '|', @re;
    my $yellow = "[$answer]";
    my $black  = "(?=[a-z])[^$answer]";

    map { ( '--re' => $_ ) } $green, $yellow, $black;
}

sub show_answer {
    say colorize('#6aaa64', uc $game->answer);
}

sub show_result {
    printf("\n%s %s%s %d/%d\n\n",
	   'Greple::wordle',
	   $app->{series} == 0 ? '' : sprintf("%d-", $app->{series}),
	   $app->get_index,
	   $game->attempt, $app->{try});
    say $game->result;
}

sub check {
    my $it = lc s/\n//r;
    if (not $word_all{$it}) {
	respond $app->{wrong};
	$_ = '';
    } else {
	$game->try($it);
	print ansi_code '{CUU}';
    }
}

sub inspect {
    if ($game->solved) {
	respond $app->{correct} x ($app->{try} - $game->attempt + 1);
	show_result if $app->{result};
	exit 0;
    }
    length or return;
    if ($game->attempt >= $app->{try}) {
	show_answer;
	exit 1;
    }
    $app->{keymap} and respond $game->keymap;
}

1;

__DATA__

mode function

define GREEN  #6aaa64
define YELLOW #c9b458
define BLACK  #787c7e

option default \
	-i --need 1 --no-filename \
	--cm 555/GREEN  \
	--cm 555/YELLOW \
	--cm 555/BLACK

# --interactive is set in initialize() when stdin is a tty

option --interactive \
       --if 'head -1' \
       --begin    __PACKAGE__::check   \
       --end      __PACKAGE__::inspect \
       --epilogue __PACKAGE__::show_answer
