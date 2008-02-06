package SNMP::Class::Varbind;

use SNMP;
use warnings;
use strict;
use Carp qw(cluck carp croak confess);
use SNMP::Class::OID;
use Data::Dumper;

use overload 
	'""' => \&get_value,
	fallback => 1
;


	
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
	my $ref_self = \ shift(@_) or croak "Incorrect call to get_varbind";
	return $$ref_self->{varbind};
}

#returns the object part of the varbind. (example: ifName or .1.2.3)
#The type of the object returned is SNMP::Class::OID
sub get_object {
	my $ref_self = \ shift(@_) or croak "Incorrect call to get_object";
	return new SNMP::Class::OID($$ref_self->get_varbind->[0]);
}

#returns the instance part of the varbind. (example: 10.10.10.10)
#If the instance is '', it will return undef (surprise,surprise!)
sub get_instance {
	my $ref_self = \ shift(@_) or croak "Incorrect call to get_instance";
	if ($$ref_self->get_varbind->[1] eq '') {
		#this is an ugly hack....
		#the SNMP library will occasionally return varbinds with a '' instance, which is, well, not good
		#if we find the instance empty, we'll just stick the zeroDotzero instance and return it instead of undef
		#this happens with e.g. the sysUpTimeInstance object
		return SNMP::Class::OID->new('0.0');
	}
	return SNMP::Class::OID->new($$ref_self->get_varbind->[1]);
}

#returns a string numeric representation of the instance
sub get_instance_numeric {
	my $ref_self = \ shift(@_) or croak "Incorrect call to get_instance_oid";
	if(!$$ref_self->get_instance) {
		return '';
	}
	return $$ref_self->get_instance->numeric;
}

#returns the full oid of this varbind. 
#type returned is SNMP::Class::OID
#also handles correctly the case where the instance is undef
sub get_oid {
	my $ref_self = \ shift(@_) or croak "Incorrect call to get_oid";
	if(!$$ref_self->get_instance) {
		return $$ref_self->get_object;
	} 
	return $$ref_self->get_object + $$ref_self->get_instance;
}
	
sub get_value {
	my $ref_self = \ shift(@_);
	#my $self = shift(@_) or croak "Incorrect call to get_value";
	return $$ref_self->get_varbind->[2];
}

sub dump {
	my $self = shift(@_);
	return $self->get_object->to_string." ".$self->get_instance->to_string." ".$self->get_value." ".$self->get_type;
}

=head2 get_value_pretty

Returns the varbinds' value, where objectid oids are coverted to their respective label

=cut

sub get_pretty {
	####my $ref_to_self = \ shift;
	my $ref_self = \ shift(@_) or confess "Incorrect call";
	if ($$ref_self->get_type eq 'OBJECTID') {
		###$logger->debug("This is an objectid...I will try to translate it to a label");
		return SNMP::Class::Utils::label_of($$ref_self->get_value);
	}
	my $enum;
	if($enum = SNMP::Class::Utils::get_attr($$ref_self->get_object->to_string,"enums")) {
		my %reverse = map { $enum->{$_} => $_ } (keys %{$enum});
		return $reverse{$$ref_self->get_value};
	}
	return $$ref_self->get_value;
}

sub get_type {
	my $ref_self = \ shift(@_) or croak "Incorrect call to get_type";
	return $$ref_self->get_varbind->[3];
}

sub normalize {
	my $ref_self = \ shift(@_) or croak "Incorrect call to normalize";
	$$ref_self->get_varbind->[0] = $$ref_self->get_oid->numeric;
}

	

=head1 NAME

SNMP::Class::Varbind - The great new SNMP::Class::Varbind!

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

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
