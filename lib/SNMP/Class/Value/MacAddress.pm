package SNMP::Class::Value::MacAddress;

use SNMP;
use warnings;
use strict;
use Carp qw(cluck carp croak confess);
use Data::Dumper;

use base "SNMP::Class::Value";

sub get_value {
	my $self = shift(@_);
	croak "self appears to be undefined" unless ref $self;
	return join(':',map(sprintf("%02X",$_),unpack("CCCCCC",$self->SUPER::get_value)));
}


1;
