package SNMP::Class::Cache;

=head1 NAME

SNMP::Class::Cache - An SNMP::Class::ResultSet which is also a live SNMP::Class session. 

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

=cut

#This class is both a resultset and a live session
#the order of inheritance is important, because
#we want to try the already stored results first
use base qw(SNMP::Class::ResultSet SNMP::Class );


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
			$module{ident $self}->{$module} = 1;
			$self->append($temp);
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
	


#sub get {
#	my $self = shift(@_) or confess "Incorrect call to get_module: this is a method";
#	my $module = shift(@_) or croak "Missing 1st argument to get_module";		
#	
#	if($self->has($module)) {
#		return $module{ident $self}->{$module};
#	} else {
#		cluck "call to get_module($module) on an object that has no $module";
#		return;
#	}
#}

sub AUTOMETHOD {
	my $self = shift(@_) or confess("Incorrect call to AUTOMETHOD");
	my $id = shift(@_) or confess("Second argument (id) to AUTOMETHOD missing");
	my $subname = $_;   # Requested subroutine name is passed via $_;
	$logger->debug("AUTOMETHOD called as $subname");  
	
	if (SNMP::Class::Utils::is_valid_oid($subname)) {
		$logger->debug("ResultSet: $subname seems like a valid OID ");
	}
	else {
		$logger->debug("$subname doesn't seem like a valid OID. Returning...");
		return;
	}
	
	#we are in an object that is both a resultset and a live session.
	#question: do we need to query the managed node for the object $subname,
	#or do we have it cached already? Let's check. If we don't have it, we
	#will try to append it. 
	if($self->SNMP::Class::ResultSet::object($subname)->is_empty) {
		$logger->debug("No $subname entries in the resultset...we'll try to walk first");
		my $result = $self->walk($subname);
		$self->append($result);
	}
	
	#our work is done. We'll just return so that the Class::Std can delegate control to SNMP::Class::ResultSet::AUTOMETHOD
	return;

}
	

1;	
