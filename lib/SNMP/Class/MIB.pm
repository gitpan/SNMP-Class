package SNMP::Class::MIB;

=head1 NAME

SNMP::Class::MIB::System - Models the system mib of a managed node 

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

=cut

#we descend from an SNMP::Class object
use base qw(SNMP::Class);


use Class::Std;
use warnings;
use strict;
use Carp qw(cluck confess carp croak);
use Data::Dumper;

use Log::Log4perl qw(:easy);
my $logger = get_logger();


my %module :ATTR;

sub add {
	my $self = shift(@_) or confess "missing self argument";
	LOOP: while (my $module = shift(@_)) {
		my $temp;
		if (eval { $temp = $self->SUPER::walk($module) }) {
			$logger->debug("fetched contents of $module");
			if ($temp->is_empty) {
				carp "Module $module not there";
				next LOOP;
			} 
			$module{ident $self}->{$module} = $temp;
		} else {
			cluck "attempt to walk $module failed";
			$logger->debug("error getting contents of $module");
		}
	}

}


sub has {
	my $self = shift(@_) or confess "Incorrect call to has_module : this is a method";
	my $module = shift(@_) or croak "Missing 1st argument to has";	
	
	return 1 if (defined($module{ident $self}->{$module}));
	return;
}

sub modules {
	my $self = shift(@_) or confess "Incorrect call to modules : this is a method";
	return (sort keys %{$module{ident $self}});
}
	


sub get {
	my $self = shift(@_) or confess "Incorrect call to get_module: this is a method";
	my $module = shift(@_) or croak "Missing 1st argument to get_module";		
	
	if($self->has($module)) {
		return $module{ident $self}->{$module};
	} else {
		cluck "call to get_module($module) on an object that has no $module";
		return;
	}
}

1;	
