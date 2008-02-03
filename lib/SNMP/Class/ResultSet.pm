package SNMP::Class::ResultSet;

=head1 SNMP::Class::ResultSet

SNMP::Class::ResultSet - Holds a set of varbinds

=head1 VERSION

Version 0.01

=cut

our $version = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use SNMP::Class::ResultSet;

    my $foo = SNMP::Class::ResultSet->new();
    ...

=cut

use SNMP;
use warnings;
use strict;
use Carp;
use SNMP::Class::OID;
use Data::Dumper;
use UNIVERSAL qw(isa);
use Class::Std;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use overload 
	'@{}' => \&varbinds,
	'.' => \&dot,
##	'""'  => \&to_scalar,
	'+' => \&plus,
	fallback => 1;

#class fields
my (%varbinds,%index_object,%index_instance,%index_value,%index_oid) : ATTRS();

sub to_scalar {
	#####my $self = shift(@_) or croak "Incorrect call to to_scalar";
	confess "to scalar method not implemented yet";
}
	
#sub new {
#	my $class = shift(@_) or croak "Incorrect call to new";
#	my $self = { varbinds=>[],numeric_oid_index=>{},oid_index=>{} };
#	return bless $self,$class;
#}


sub BUILD {
	my ($self, $id, $arg_ref) = @_;
	$varbinds{$id} = [];
	$index_oid{$id} = {};
	$index_object{$id} = {};
	$index_instance{$id} = {};
	$index_value{$id} = {};
}

sub varbinds {
	my $self = shift(@_) or croak "Incorrect call to varbind";
	my $id = ident $self;
	return $varbinds{$id};
}

sub index_oid {
	my $self = shift(@_) or croak "Incorrect call to index_oid";
	my $id = ident $self;
	return $index_oid{$id};
}

sub index_object {
	my $self = shift(@_) or croak "Incorrect call to index_object";
	my $id = ident $self;
	return $index_object{$id};
}

sub index_instance {
	my $self = shift(@_) or croak "Incorrect call to index_instance";
	my $id = ident $self;
	return $index_instance{$id};
}

sub index_value {
	my $self = shift(@_) or croak "Incorrect call to index_value";
	my $id = ident $self;
	return $index_value{$id};
}

sub dump {
	my $self = shift(@_) or croak "Incorrect call to dump";
	my $id = ident $self;
	return Dumper($varbinds{$id},$index_oid{$id},$index_object{$id},$index_instance{$id},$index_value{$id});
}


sub push {
	my $self = shift(@_) or croak "Incorrect call to push";
	my $id = ident $self;
	my $payload = shift(@_) or croak "Missing payload";

	#make sure that this is of the correct class
	if (! eval $payload->isa('SNMP::Class::Varbind')) {
		die "Payload is not an SNMP::Class::Varbind";
	}
	push @{$self->varbinds},($payload);
	$self->index_oid->{$payload->get_oid->numeric} = \$payload;
	push @{$self->index_object->{$payload->get_object->numeric}},(\$payload);
	push @{$self->index_instance->{$payload->get_instance_numeric}},(\$payload);
	push @{$self->index_value->{$payload->get_value}},(\$payload);
	
	#using the get_oid inside a hash key will force it to use the overloaded '""' quote_oid subroutine
	###$self->{oid_index}->{$payload->get_oid}->{$payload->get_instance_numeric} = \$payload;
	
}

#take a list with possible duplicate elements
#return a list with each element unique
sub unique {
	my @ret;
	while(my $elem = shift(@_)) {
		CORE::push @ret,($elem) if(!(grep {$elem == $_} @ret));
	}
	return @ret;
}


sub get_oids {
	my $self = shift(@_) or croak "Incorrect call to get_oids";
	return unique(map($_->get_oid,@{$self->varbinds}));
}

sub get_objects {
	my $self = shift(@_) or croak "Incorrect call to get_objects";
	return unique(map($_->get_object,@{$self->varbinds}));
}
	
sub get_instances {
	my $self = shift(@_) or croak "Incorrect call to get_instances";
	#remember, the $_->get_instance is evaluated in list context, so
	#an undef value will not endup in the returned list
	return unique(map($_->get_instance,@{$self->varbinds}));
}

sub get_values {
	my $self = shift(@_) or croak "Incorrect call to get_values";
	return map($_->get_value,@{$self->varbinds});
}

sub to_string {
	my $self = shift(@_) or croak "Incorrect call to to_string";
	return join("\n",map($_->get_oid,@{$self->varbinds}));
}

sub object {
	my $self = shift(@_) or croak "Incorrect call to object";
	###my $object = shift(@_) or croak "1st argument -- object missing from object";
	my @matchlist = ();

	for my $object (@_) {
		if(ref($object)) {
			if ( eval $object->isa("SNMP::Class::OID") ) {
					CORE::push @matchlist,($object);
			}
			elsif (eval $object->isa('SNMP::Class::ResultSet')) {
				CORE::push @matchlist,($object->get_objects);
			}
			else { 
				croak "I don't know how to handle a ".ref($object);
			}
		}
		else {
			CORE::push @matchlist,(SNMP::Class::OID->new($object));
		}
	}

	my @matched_items = ();
	for my $match (@matchlist) {
		$logger->debug("Filtering for object=".$match->to_string);
		CORE::push @matched_items,(grep { $match == $_->get_object } @{$self->varbinds});
	}
	my $ret_set = SNMP::Class::ResultSet->new;
	for (@matched_items) {
		$ret_set->push($_);
	}

	if(wantarray) {
		return @{$ret_set->varbinds};
	}

	return $ret_set;
	
}
		
		
sub instance {
	my $self = shift(@_) or croak "Incorrect call to object";
	my @matchlist = ();

	for my $object (@_) {
		if(ref($object)) {
			if ( eval $object->isa("SNMP::Class::OID") ) {
					CORE::push @matchlist,($object);
			}
			elsif (eval $object->isa('SNMP::Class::ResultSet')) {
				CORE::push @matchlist,($object->get_instances);
			}
			else { 
				croak "I don't know how to handle a ".ref($object);
			}
		}
		else {
			CORE::push @matchlist,(SNMP::Class::OID->new($object));
		}
	}

	my @matched_items = ();
	for my $match (@matchlist) {
		$logger->debug("Filtering for instance=".$match->numeric);
		CORE::push @matched_items,(grep { $match == $_->get_instance } @{$self->varbinds});
	}
	my $ret_set = SNMP::Class::ResultSet->new;
	for (@matched_items) {
		$ret_set->push($_);
	}

	if(wantarray) {
		return @{$ret_set->varbinds};
	}

	return $ret_set;
	
}

sub value {
	my $self = shift(@_) or croak "Incorrect call to object";
	my @matchlist = ();

	for my $object (@_) {
		CORE::push @matchlist,($object);
	}

	my @matched_items = ();
	for my $match (@matchlist) {
		$logger->debug("Filtering for value=$match");
		CORE::push @matched_items,(grep { $match eq $_->get_value } @{$self->varbinds});
	}
	my $ret_set = SNMP::Class::ResultSet->new;
	for (@matched_items) {
		$ret_set->push($_);
	}

	if(wantarray) {
		return @{$ret_set->varbinds};
	}

	return $ret_set;
	
}

sub find {
	my $self = shift(@_) or croak "Incorrect call to find";

	my @matchlist = ();
	###print Dumper(@_);
	
	while(1) {
		my $object = shift(@_) or last;
		my $value = shift(@_) or last;
		$logger->debug("Searching for instances with $object == $value");
		CORE::push @matchlist,($self->object($object)->value($value)->get_instances);
	}
	
	return $self->instance(@matchlist);
}

=head2 filter

filter can be used when the predefined filters (object,instance,value) are not suitable and there is the need to filter the varbinds inside the resultset using arbitrary rules. Takes one argument, which is a reference to a subroutine which will be doing the filtering. The value of each Varbind item in the ResultSet gets assigned to the $_ global variable. For example:

print $session->filter(sub {$_->get_type =~ /INTEGER/})->sysName.0;

=cut

sub filter {
	my $self = shift(@_) or croak "Incorrect call";
	my $coderef = shift(@_);
	if(ref($coderef) ne 'CODE') {
		confess "First argument must be always a reference to a sub";
	}
	my $ret_set = SNMP::Class::ResultSet->new;
	map { $ret_set->push($_) } ( grep { &$coderef; } @{$self->varbinds} );
	return $ret_set;
}

=head2

number_of_items

Returns the number of items present inside the ResultSet

=cut


sub number_of_items {
	my $self = shift(@_) or croak "Incorrect call to number_of_items";
	return scalar @{$self->varbinds};
}

sub is_empty {
	my $self = shift(@_) or croak "Incorrect call to is_empty";
	return ($self->number_of_items == 0);
}

sub dot {
	my $self = shift(@_) or croak "Incorrect call to dot";
	my $str = shift(@_); #we won't test because it could be false, e.g. ifName.0
	
	$logger->debug("dot called with $str as argument");

	return $self->instance($str)->get_value;
}

sub get_value {
	my $self = shift(@_) or croak "Incorrect call to get_value";
	if( $self->is_empty) {
		croak "get_value cannot be called on an empty result set";
	} 
	if ($self->number_of_items > 1) {
		carp "Warning: Calling get_value on a result set that has more than one items";
	} 
	return $self->varbinds->[0]->get_value;	
}

#warning: plus will not protect you from duplicates
sub plus {
	my $self = shift(@_) or croak "Incorrect call to plus";
	my $item = shift(@_) or croak "Argument to add(+) missing";

	#check that this object is an SNMP::Class::Varbind
	confess "item to add is not an SNMP::Class::ResultSet!" unless (ref($item)&&(eval $item->isa("SNMP::Class::ResultSet")));

	my $ret = SNMP::Class::ResultSet->new();

	map { $ret->push($_) } (@{$self->varbinds});
	map { $ret->push($_) } (@{$item->varbinds});

	return $ret;
}

sub append { 
	my $self = shift(@_) or croak "Incorrect call to append";
	my $item = shift(@_) or croak "Argument to append missing";
	#check that this object is an SNMP::Class::Varbind
	confess "item to add is not an SNMP::Class::ResultSet!" unless (ref($item)&&(eval $item->isa("SNMP::Class::ResultSet")));
	map { $self->push($_) } (@{$item->varbinds});
	return;
}

sub AUTOMETHOD {
	my $self = shift(@_) or confess("Incorrect call to AUTOMETHOD");
	my $id = shift(@_) or confess("Second argument (id) to AUTOMETHOD missing");
	my $subname = $_;   # Requested subroutine name is passed via $_;
	$logger->debug("ResultSet AUTOMETHOD called as $subname");  
	
	if (SNMP::Class::Utils::is_valid_oid($subname)) {
		$logger->debug("ResultSet: $subname seems like a valid OID ");
	}
	else {
		$logger->debug("$subname doesn't seem like a valid OID. Returning...");
		return;
	}
	
	#we'll just have to create this little closure and return it to the Class::Std module
	#remember: this closure will run in the place of the method that was called by the invoker
	return sub {
		if(wantarray) {
			$logger->debug("$subname called in list context");
			return @{$self->object($subname)->varbinds};
		}
		my $result = $self->object($subname);
	};

}
	
 


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
C<bug-snmp-class-resultset at rt.cpan.org>, or through the web interface at
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

1; # End of SNMP::Class::ResultSet
