package SNMP::Class::Varbind;

use SNMP;
use warnings;
use strict;
use Carp;
use SNMP::Class::OID;
use Data::Dumper;

	
sub new {
        my $class = shift(@_) or croak "Incorrect call to new";
	my $self = {};
	###my $reftype = ref(@_[0]);
	if (eval { $_[0]->isa("SNMP::Class::OID") }) {
		$self->{varbind} = SNMP::Varbind->new([$_[0]->numeric]) or croak "Cannot invoke SNMP::Varbind::new method with ".$_[0]->numeric." \n";
	} 
	else {
		confess "Argument was not an SNMP::Class::OID";
	}
	
	###maybe unneeded
	###else {
        ###	$self->{varbind} = $class->SUPER::new(@_) or croak "Cannot invoke SUPER::new method with ".join(',',@_),"\n";
	###}
       	return bless $self,$class;
}

sub new_from_varbind {
	my $class = shift(@_) or croak "Incorrect call to new_from_varbind";
	my $varbind = shift(@_) or croak "2nd argument (varbind) missing from call to new_from_varbind";
	my $self = {};
	if(eval { $varbind->isa("SNMP::Varbind") } ) {
			$self->{varbind} = $varbind;
	}
	else {
		croak "new_from_varbind was called with an argument that was not an SNMP::Varbind.";
	}
	return bless $self,$class;
}

#return the varbind
sub get_varbind {
	my $self = shift(@_) or croak "Incorrect call to get_varbind";
	return $self->{varbind};
}

#returns the object part of the varbind. (example: ifName or .1.2.3)
#The type of the object returned is SNMP::Class::OID
sub get_object {
	my $self = shift(@_) or croak "Incorrect call to get_object";
	return new SNMP::Class::OID($self->get_varbind->[0]);
}

#returns the instance part of the varbind. (example: 10.10.10.10)
#If the instance is '', it will return undef (surprise,surprise!)
sub get_instance {
	my $self = shift(@_) or croak "Incorrect call to get_instance";
	if ($self->get_varbind->[1] eq '') {
		return;
	}
	return SNMP::Class::OID->new($self->get_varbind->[1]);
}

#returns a string numeric representation of the instance
sub get_instance_numeric {
	my $self = shift(@_) or croak "Incorrect call to get_instance_oid";
	if(!$self->get_instance) {
		return '';
	}
	return $self->get_instance->numeric;
}

#returns the full oid of this varbind. 
#type returned is SNMP::Class::OID
#also handles correctly the case where the instance is undef
sub get_oid {
	my $self = shift(@_) or croak "Incorrect call to get_oid";
	if(!$self->get_instance) {
		return $self->get_object;
	} 
	return $self->get_object + $self->get_instance;
}
	
sub get_value {
	my $self = shift(@_) or croak "Incorrect call to get_value";
	return $self->get_varbind->[2];
}

sub get_type {
	my $self = shift(@_) or croak "Incorrect call to get_type";
	return $self->get_varbind->[3];
}

sub normalize {
	my $self = shift(@_) or croak "Incorrect call to normalize";
	$self->get_varbind->[0] = $self->get_oid->numeric;
}

	

=head1 NAME

SNMP::Class::Varbind - The great new SNMP::Class::Varbind!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use SNMP::Class::Varbind;

    my $foo = SNMP::Class::Varbind->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Athanasios Douitsis, C<< <aduitsis at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-snmp-class-varbind at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SNMP::Class>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SNMP::Class

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SNMP::Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SNMP::Class>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SNMP::Class>

=item * Search CPAN

L<http://search.cpan.org/dist/SNMP::Class>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Athanasios Douitsis, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SNMP::Class::Varbind
