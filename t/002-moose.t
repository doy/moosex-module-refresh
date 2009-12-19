#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 14;

use MooseX::Module::Refresh;

use File::Temp 'tempdir';
my $tmp = tempdir( CLEANUP => 1 );

my $file = $tmp."/".'FooBar.pm';
push @INC, $tmp;

write_out(<<".");
package FooBar;
use Moose;
has foo => (is => 'ro', clearer => 'clear_foo');
sub bar { 'bar' }
1;
.

use_ok('FooBar', "Required our dummy module");

my $r = MooseX::Module::Refresh->new();

# is our non-file-based method available?

can_ok('FooBar', 'not_in_foobarpm');

can_ok('FooBar', 'new');
my $foobar = FooBar->new(foo => 'FOO');
is($foobar->bar, 'bar', "We got the right result");
is($foobar->foo, 'FOO', "We got the right result");
can_ok($foobar, 'clear_foo');

write_out(<<".");
package FooBar; 
has baz => (is => 'ro', predicate => 'foo');
sub quux { 'baz' }
1;
.

$foobar = FooBar->new(foo => 'FOO');
is($foobar->bar, 'bar', "We got the right result, still");
is($foobar->foo, 'FOO', "We got the right result, still");

$r->refresh;

$foobar = FooBar->new(baz => 'FOO');
is($foobar->quux, 'baz', "We got the right new result");
is($foobar->baz, 'FOO', "We got the right new result");
is($foobar->foo, 1, "We got the right new result");
ok(!$foobar->can('bar'), "the bar method was removed");
ok(!$foobar->can('clear_foo'), "the clear_foo method was removed");

# After a refresh, did we blow away our non-file-based comp?
can_ok('FooBar', 'not_in_foobarpm');

# XXX: figure out what to do about unload_subs
#$r->unload_subs($file);
#ok(!defined(&FooBar::foo), "We cleaned out the 'foo' method'");

#ok(!UNIVERSAL::can('FooBar', 'foo'), "We cleaned out the 'foo' method'");
#require "FooBar.pm";
#is(FooBar->foo, 'baz', "We got the right new result,");

sub write_out {
    local *FH;
    open FH, "> $file" or die "Cannot open $file: $!";
    print FH $_[0];
    close FH;
}

END {
    unlink $file;
}


package FooBar;
use Moose;

sub not_in_foobarpm {
    return "woo";
}

1;
