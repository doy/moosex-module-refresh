#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 10;

use MooseX::Module::Refresh;

use File::Temp 'tempdir';
my $tmp = tempdir( CLEANUP => 1 );

my $file = $tmp."/".'FooBar.pm';
my $subfile = $tmp."/".'FooBarSub.pm';
push @INC, $tmp;

write_out($file, <<".");
package FooBar;
use Moose;
has foo => (is => 'ro', clearer => 'clear_foo');
sub bar { 'bar' }
1;
.

write_out($subfile, <<".");
package FooBarSub;
use Moose;
extends 'FooBar';
around foo => sub { my (\$orig, \$self) = \@_; return \$self->\$orig . 'sub' };
around bar => sub { my (\$orig, \$self) = \@_; return \$self->\$orig . 'sub' };
1;
.

use_ok('FooBar', "Required our dummy module");
use_ok('FooBarSub', "Required our dummy subclass");

my $r = MooseX::Module::Refresh->new();

my $foobar = FooBarSub->new(foo => 'FOO');
is($foobar->bar, 'barsub', "We got the right result");
is($foobar->foo, 'FOOsub', "We got the right result");

write_out($file, <<".");
package FooBar; 
has baz => (is => 'ro', predicate => 'foo');
sub bar { 'baz' }
1;
.

$foobar = FooBarSub->new(foo => 'FOO');
is($foobar->bar, 'barsub', "We got the right result, still");
is($foobar->foo, 'FOOsub', "We got the right result, still");

$r->refresh;

$foobar = FooBarSub->new(baz => 'FOO');
is($foobar->bar, 'bazsub', "We got the right new result");
is($foobar->baz, 'FOO', "We got the right new result");
is($foobar->foo, '1sub', "We got the right new result");
ok(!$foobar->can('clear_foo'), "the clear_foo method was removed");

sub write_out {
    my $file = shift;
    local *FH;
    open FH, "> $file" or die "Cannot open $file: $!";
    print FH $_[0];
    close FH;
}

END {
    unlink $file, $subfile;
}
