package pfappserver::Controller::Config::HighAvailability;

=head1 NAME

pfappserver::Controller::Config::Networks - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

use HTTP::Status qw(:constants is_error is_success);
use Moose;
use namespace::autoclean;

BEGIN {
    extends 'pfappserver::Base::Controller';
    with 'pfappserver::Base::Controller::Crud::Config' => { -excludes => [ qw(getForm) ] };
}

=head1 METHODS

=cut
sub highavailability :Local :Args(0) {
    my ( $self, $c ) = @_;

    my @interfaces;
    my $interfaces_ref = $c->model("Interface")->get('all');

    for my $interface ( values %$interfaces_ref ) {
        next if ( ($interface->{type} =~ /other/) || ($interface->{type} =~ /none/) );
        push @interfaces, { type => $interface->{type}, name => $interface->{name}, ipaddress => $interface->{ipaddress}, netmask => $interface->{netmask} };
    }

    my $form = $c->form("Config::Network::HighAvailability");
    $form->process(init_object => { interfaces => \@interfaces});
    $c->stash(form => $form);
}

=head1 COPYRIGHT

Copyright (C) 2012-2013 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

__PACKAGE__->meta->make_immutable;

1;
