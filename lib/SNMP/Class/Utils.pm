package SNMP::Class::Utils;

use strict;
use warnings;
use Carp;
use Exporter;

our @ISA=qw(Exporter);

our @EXPORT = qw(get_attr children_of label_of parent_of oid_of descendants_of);


#str2arr converts a .1.2.3.4-style oid to an array
sub str2arr {
	my $str = shift(@_) or confess "str2arr 1st arg missing";
	my ($dummy,@ret) = split('\.',$str); 
	return @ret;
}
	
#get_attr takes two arguments:
#1)The oid we are interested in
#2)The attribute of that oid we are interested in
#example: get_attr('sysName','objectID')
sub get_attr {
	my $oid_name = shift(@_) or croak "Incorrect call to get_attr";
	my $attr = shift(@_) or croak "Incorrect call to get_attr";
	return $SNMP::MIB{$oid_name}->{$attr};
}

sub children_of {
	my $oid_name = shift(@_) or croak "Incorrect call to children_of";
	my $children = get_attr($oid_name,'children');
	my @children = map { $_->{label} } @{$children};
}

sub label_of {
	my $oid_name = shift(@_) or croak "Incorrect call to label_of";
	return get_attr($oid_name,'label');
}

sub parent_of {
	my $oid_name = shift(@_) or croak "Incorrect call to parent_of";
	my $parent = get_attr($oid_name , 'parent') or return;
	return $parent->{label};
}

sub oid_of {
	my $oid_name = shift(@_) or croak "Incorrect call to oid_of";
	return get_attr($oid_name,'objectID');
}

sub descendants_of {
	my $oid_name = shift(@_) or croak "Incorrect call to descendants_of";

	#we will mark visited descendant nodes through this hash
	my %descendants_of;

	#we init the stack with one member, the oid_name itself
	my @stack = (label_of($oid_name));

	#and we continue while there is still stuff inside the stack
	while(@stack) {
		my $item = pop @stack;
		$descendants_of{$item}=1;
		my @children = children_of($item);
		push @stack,(@children);
	}

	return \%descendants_of;
}
	
1;
