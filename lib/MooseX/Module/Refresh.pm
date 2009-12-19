package MooseX::Module::Refresh;
use Moose;

extends 'Module::Refresh';

=head1 NAME

MooseX::Module::Refresh - Module::Refresh for Moose classes

=head1 SYNOPSIS

  # During each request, call this once to refresh changed modules:

  MooseX::Module::Refresh->refresh;

  # Each night at midnight, you automatically download the latest
  # Acme::Current from CPAN.  Use this snippet to make your running
  # program pick it up off disk:

  $refresher->refresh_module('Acme/Current.pm');

=head1 DESCRIPTION


=cut

sub _pm_file_to_mod {
    my ($file) = @_;
    $file =~ s{\.pm$}{};
    # XXX: is this correct on windows?
    $file =~ s{/}{::}g;
    return $file;
}

after unload_module => sub {
    my $self = shift;
    my $mod = _pm_file_to_mod($_[0]);
    my $meta = Class::MOP::class_of($mod);
    return unless defined $meta;
    return unless $meta->isa('Moose::Meta::Class');
    if ($meta->is_immutable) {
        # XXX: we can probably do better here, if we try hard enough - would
        # require walking the entire inheritance tree downwards though
        warn "Can't modify an immutable class";
        return;
    }
    $self->unload_methods($meta);
    $self->unload_attrs($meta);
    # XXX: this is probably wrong, but necessary for now, since the metaclass
    # still existing means that Moose::init_meta won't set the default base
    # class. this will break things that try to "use base" something before
    # doing "use Moose", not sure how to get around that.
    $meta->superclasses('Moose::Object');
    bless $meta, 'Moose::Meta::Class';
    # XXX: why is this breaking
    #for my $attr ($meta->meta->get_all_attributes) {
        #$attr->set_value($meta, $attr->default($meta));
    #}
};

sub unload_methods {
    my $self = shift;
    my ($meta) = @_;
    for my $meth ($meta->get_method_list) {
        # don't remove things that unload_subs didn't remove
        $meta->remove_method($meth)
            unless exists $DB::sub{$meta->name . "::$meth"};
    }
}

sub unload_attrs {
    my $self = shift;
    my ($meta) = @_;
    $meta->remove_attribute($_) for $meta->get_attribute_list;
}

no Moose;

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-moosex-module-refresh at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Module-Refresh>.

=head1 SEE ALSO


=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc MooseX::Module::Refresh

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Module-Refresh>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Module-Refresh>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Module-Refresh>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Module-Refresh>

=back

=head1 AUTHOR

  Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
