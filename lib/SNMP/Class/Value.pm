package SNMP::Class::Value;

use SNMP;
use warnings;
use strict;
use Carp qw(cluck carp croak confess);
use Data::Dumper;

use overload
        '""' => \&get_value,
        fallback => 1
;

#BEGIN {
#	my $module_location = $INC{'SNMP/Class/Value.pm'};
#	$module_location =~ s/.pm$//g;
#	my @modules = glob("$module_location/*");
#	for my $module (@modules) {
#		require $module;	
#	}
#}

sub new {
	my $self = shift(@_) or confess "incorrect call to constructor";
	my $value = shift(@_); 
	return bless { value => $value }, $self;
}

sub get_value {
	my $self = shift(@_);
	croak "self appears to be undefined" unless ref $self;
	return $self->{value};
}

sub to_ethermac {
	my $self = shift(@_);
	croak "self appears to be undefined" unless ref $self;
	return join(':',map(sprintf("%02X",$_),unpack("CCCCCC",$self->get_value)));
}




1;
