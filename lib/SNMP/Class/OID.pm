package SNMP::Class::OID;

use NetSNMP::OID;
use Carp;
use strict;
use warnings;
use Data::Dumper;

use overload
	'<=>' => \&oid_compare,
	'cmp' => \&str_compare,
	'+' => \&add,
	fallback => 1,
;

sub new {
	my $class = shift(@_) or croak "Incorrect call to new";
	my $oid_str = shift(@_);
	if($oid_str eq "0") {
		$oid_str = ".0";
	}
	my $self = {};
	$self->{oid} = NetSNMP::OID->new($oid_str) or confess "Cannot invoke NetSNMP::OID::new method with ".join(',',@_)."\n";
	return bless $self,$class;
}

sub new_from_netsnmpoid {
	my $class = shift(@_) or croak "Incorrect call to new_from_netsnmpoid";
	my $self = {};
	$self->{oid} = shift(@_) or croak "Missing argument from new_from_netsnmpoid";
	return bless $self,$class;
}
	

sub oid {
	my $self = shift(@_) or croak "Incorrect call to get_oid";
	return $self->{oid};
}

sub to_array {
	my $self = shift(@_) or croak "Incorrect call to to_array";
	return $self->oid->to_array;
}

sub length {
	my $self = shift(@_) or croak "Incorrect call to length";
	return $self->oid->length;
}

sub numeric {
        my $self = shift(@_) or croak "Incorrect call to numeric";
        return '.'.join('.',$self->to_array);
}

sub to_string {
	my $self = shift(@_) or croak "Incorrect call to to_string";
	return $self->oid->quote_oid;
}

sub add {
	my $self = shift(@_) or croak "Incorrect call to add";
	my $other = shift(@_) or croak "Second argument missing from add";
	return SNMP::Class::OID->new_from_netsnmpoid($self->oid->add($other->oid));
}

sub oid_compare {
	my $self = shift(@_) or croak "Incorrect call to compare";	
	my $other = shift(@_) or croak "Second argument missing from compare";
	return $self->oid->compare($other->oid);
}
       
sub str_compare {
	my $self = shift(@_) or croak "Incorrect call to str_compare";
	my $other = shift(@_) or croak "Second argument missing from str_compare";	
	return $self->oid->oidstrcmp($other->oid);
}

sub contains {
	my $self = shift(@_) or croak "Incorrect call to contains";
	my $other_oid = shift(@_) or croak "Second argument missing from contains";
	if ($self->length > $other_oid->length) { return }
	my @arr1 = $self->to_array;
	my @arr2 = $other_oid->to_array;
	for(my $i=0;$i<=$#arr1;$i++) {
		return if (!defined($arr2[$i]));
		return if ($arr1[$i] != $arr2[$i]);
		###print STDERR "iteration=$i\t$arr1[$i]\t$arr2[$i]\n";
	}
	return 1;
}

sub new_from_string {
	my $class = shift(@_) or croak "Incorrect call to new";
	my $str = shift(@_) or croak "Missing string as 1st argument";
	my $implied = shift(@_) || 0;
	my $newstr;
	if(!$implied) { $newstr = "." . CORE::length($str) }
	map { $newstr .= ".$_" } unpack("c*",$str);
	print $newstr,"\n";
	my $self={};
	$self->{oid} = NetSNMP::OID->new($newstr) or croak "Cannot invoke NetSNMP::OID::new method \n";
	return bless $self,$class;
}


=head1 NAME

SNMP::Class::OID - The great new SNMP::Class::OID!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use SNMP::Class::OID;

    my $foo = SNMP::Class::OID->new();
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
C<bug-snmp-class-oid at rt.cpan.org>, or through the web interface at
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

1; # End of SNMP::Class::OID
