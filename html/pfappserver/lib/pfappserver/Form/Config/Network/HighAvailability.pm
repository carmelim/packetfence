package pfappserver::Form::Config::Network::HighAvailability;

=head1 NAME

pfappserver::Form::Config::Network::HighAvailability - Web form for high-availability support.

=head1 DESCRIPTION

Form definition to edit high-availability support.

=cut

use HTML::FormHandler::Moose;
extends 'pfappserver::Form::Config::Network';
with 'pfappserver::Base::Form::Role::Help';

use HTTP::Status qw(:constants is_success);
use pf::config;

has 'syncinterface' => ( is => 'ro' );

has_field 'syncinterface' => (
    type => 'Select',
    label => 'Synchronization interface',
);

has_field 'interfaces' => (
    type => 'Repeatable',
);
  has_field 'interfaces.type' => (
      type => 'Uneditable',
      do_label => 0,
  );
  has_field 'interfaces.name' => (
      type => 'Uneditable',
      do_label => 0,
  );
  has_field 'interfaces.ipaddress' => (
      type => 'Uneditable',
      do_label => 0,
  );
  has_field 'interfaces.netmask' => (
      type => 'Uneditable',
  );
  has_field 'interfaces.virtualip' => (
      type => 'IPAddress',
      do_label => 0,
  );


=head2 options_syncinterface

=cut
sub options_syncinterface {
    my $self = shift;

    my @interfaces;
    my $interfaces_ref = $self->ctx->model("Interface")->get('all');

    for my $interface ( keys %$interfaces_ref ) {
        next if ( ($interfaces_ref->{$interface}->{type} =~ /vlan-/) || ($interfaces_ref->{$interface}->{type} =~ /inline/) );
        push @interfaces, ( $interfaces_ref->{$interface}->{name} => $interfaces_ref->{$interface}->{name} );
    }

    return ('' => '', @interfaces);
}

=head1 COPYRIGHT

Copyright (C) 2013 Inverse inc.

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
