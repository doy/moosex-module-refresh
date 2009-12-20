#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 9;

use MooseX::Module::Refresh;

use File::Temp 'tempdir';
my $tmp = tempdir( CLEANUP => 1 );

my $file = $tmp."/".'FooBar.pm';
my $rolefile = $tmp."/".'FooBarRole.pm';
push @INC, $tmp;

write_out($rolefile, <<".");
package FooBarRole;
use Moose::Role;
has foo => (is => 'ro', clearer => 'clear_foo');
sub bar { 'bar' }
1;
.

write_out($file, <<".");
package FooBar;
use Moose;
with 'FooBarRole';
around foo => sub { my (\$orig, \$self) = \@_; return \$self->\$orig . 'role' };
around bar => sub { my (\$orig, \$self) = \@_; return \$self->\$orig . 'role' };
1;
.

use_ok('FooBar', "Required our dummy module");

my $r = MooseX::Module::Refresh->new();

my $foobar = FooBar->new(foo => 'FOO');
is($foobar->bar, 'barrole', "We got the right result");
is($foobar->foo, 'FOOrole', "We got the right result");

write_out($rolefile, <<".");
package FooBarRole; 
use Moose::Role;
has baz => (is => 'ro', predicate => 'foo');
sub bar { 'baz' }
1;
.

$foobar = FooBar->new(foo => 'FOO');
is($foobar->bar, 'barrole', "We got the right result, still");
is($foobar->foo, 'FOOrole', "We got the right result, still");

$r->refresh;

$foobar = FooBar->new(baz => 'FOO');
is($foobar->bar, 'bazrole', "We got the right new result");
is($foobar->baz, 'FOO', "We got the right new result");
is($foobar->foo, '1role', "We got the right new result");
ok(!$foobar->can('clear_foo'), "the clear_foo method was removed");

sub write_out {
    my $file = shift;
    local *FH;
    open FH, "> $file" or die "Cannot open $file: $!";
    print FH $_[0];
    close FH;
}

END {
    unlink $file, $rolefile;
}
