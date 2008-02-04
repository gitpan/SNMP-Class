package SNMP::Class;

=head1 NAME

SNMP::Class - A convenience class around the NetSNMP perl modules. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

This module aims to enable snmp-related tasks to be carried out with the best possible ease and expressiveness while at the same time allowing advanced features like subclassing to be used without hassle.

	use SNMP::Class;
	
	#create a session to a managed device -- 
	#community will default to public, version will be autoselected from 2,1
	my $s = SNMP::Class->new({DestHost => 'myhost'});    
	
	#modus operandi #1
	#walk the entire table
	my $ifTable = $s->walk("ifTable");
	#-more compact- 
	my $ifTable = $s->ifTable;
	
	#get the ifDescr.3
	my $if_descr_3 = $ifTable->object("ifDescr")->instance("3");
	#more compact
	my $if_descr_3 = $ifTable->object(ifDescr).3;

	#iterate over interface descriptions -- method senses list context and returns array
	for my $descr ($ifTable->object"ifDescr")) { 
		print $descr->get_value,"\n";
	}
	
	#get the speed of the instance for which ifDescr is en0
	my $en0_speed = $ifTable->find("ifDescr","en0")->object("ifSpeed")->get_value;  
	#
	#modus operandi #2 - list context
	while($s->ifDescr) {
		print $_->get_value;
	}
 
   
=head1 METHODS

=cut

use warnings;
use strict;
use Carp;
use Data::Dumper;
use SNMP;
use SNMP::Class::ResultSet;
use SNMP::Class::Varbind;
use SNMP::Class::OID;
use SNMP::Class::Utils;
use Class::Std;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
	level=>$INFO,
	layout => "%M:%L %m%n",
});
my $logger = get_logger();



my (%session,%name,%version,%community,%deactivate_bulkwalks) : ATTRS;


=head2 new({DestHost=>$desthost,Community=>$community,Version=>$version,DestPort=>$port})

This method creates a new session with a managed device. At this point Version can only be 1 or 2. If Version is not present, the library will try to probe by querying sysName.0 from the device using version 2 and then version 1, whichever succeeds first. This method croaks if a session cannot be created. If the managed node cannot return the sysName.0 object, the method will also croak. 

=cut
 

sub BUILD {

	my ($self, $obj_ID, $arg_ref) = @_;

	my $session;
	my @versions = ( $arg_ref->{Version} );


	#if the user did not specify a version, then we will try one after the other
	if ( !defined($arg_ref->{Version})) {
		@versions = ( "2" , "1" );
	}	

	#if the user has not supplied a community, why not try a default one?
	if (!defined($arg_ref->{Community})) {
		$arg_ref->{Community} = "public";
	}	

	if (!defined($arg_ref->{RemotePort})) {
		$logger->debug("setting port to default (161)");
		$arg_ref->{RemotePort} = 161;
	}

	$logger->info("Host is $arg_ref->{DestHost}, community is $arg_ref->{Community}");
	
	for my $version (@versions) {
		$logger->debug("trying version $version");
		
		#set $arg_ref->{Version} to $version
		$arg_ref->{Version}=$version;

		#construct a string for debug purposes and log it
		my $debug_str = join(",",map( "$_=>$arg_ref->{$_}", (keys %{$arg_ref})));
		$logger->debug("doing SNMP::Session->new($debug_str)");

		#construct the arguments we will be passing to SNMP::Session->new
		my @argument_array = map { $_ => $arg_ref->{$_}  } (keys %{$arg_ref});
		$session{$obj_ID} = SNMP::Session->new(@argument_array);
		if(!$session{$obj_ID}) {
			$logger->debug("null session. Next.");
		}
		my $name;
		if(eval { $name = $self->getOid('sysName',0) }) {
			$logger->debug("getOID(sysName,0) success. Name = $name");
			#if we got to this point, then this means that
			#we were able to retrieve the sysname variable from the session
			#session is probably good
			$logger->debug("Session should be ok.");
			$name{$obj_ID} = $name;	
			$version{$obj_ID} = $version;
			$community{$obj_ID} = $arg_ref->{Community};
			return 1;
		} else { 
			$logger->debug("getOID(sysName,0) failed. Error is $@");
			$logger->debug("Going to next community");
			next;
		}
		
	}
	#if we got here, the session could not be created
	$logger->debug("session could not be created");
	croak "cannot initiate object for $arg_ref->{DestHost},$arg_ref->{Community}";

}

=head2 deactivate_bulkwalks

If called, this method will permanently deactivate usage of bulkwalk for the session. Mostly useful for broken agents, some buggy versions of Net-SNMP etc. 
=cut

sub deactivate_bulkwalks {
	my $self = shift(@_) or croak "deactivate_bulkwalks called outside of an object context";
	my $id = ident $self;
	$deactivate_bulkwalks{$id} = 1 ;
	return;	
}


sub getOid :RESTRICTED() {
	
	my $self = shift(@_) or croak "getvar called outside of an object context";
	my $oid = shift(@_) or croak "first arg to getvar (oid), missing";
	my $instance = shift(@_); #instance could be 0, so we do not check
	if (!defined($instance)) { confess "second arg to getvar (instance), missing" }
	my $id = ident $self;

	my $vars = new SNMP::VarList([$oid,$instance]) or confess "Internal Error: Could not create a new SNMP::VarList for $oid.$instance";

	my @a = $session{$id}->get($vars);

	###print Dumper(@a);

	croak $session{$id}->{ErrorStr} if ($session{$id}->{ErrorNum} != 0);
	croak "Got error when tried to ask $session{$id}->{DestHost} for $oid.$instance" if ($a[0] eq "NOSUCHINSTANCE");

	return $a[0];
}


=head2 getVersion

Returns the SNMP version of the session object.

=cut

#This method returns the SNMP version of the object
sub getVersion {
	my $self = shift(@_) or confess "sub getVersion called outside of an object context";
	my $id = ident $self;
	return $version{$id};
}


=head2 walk

A generalized walk method. Takes 1 argument, which is the object to walk. Depending on whether the session object is version 1 or 2, it will respectively try to use either SNMP GETNEXT's or GETBULK. On all cases, an SNMP::Class::ResultSet is returned. If something goes wrong, the method will croak.

One should probably also take a look at L<SNMP::Class::ResultSet> pod to see what's possible.

=cut

#Does snmpwalk on the session object. Depending on the version, it will try to either do a
#normal snmpwalk, or, in the case of SNMPv2c, bulkwalk.
sub walk {
	my $self = shift(@_) or confess "sub walk called outside of an object context";
	my $id = ident $self;
	my $oid_name = shift(@_) or confess "First argument missing in call to get_data";
	
	if ($deactivate_bulkwalks{$id}) { 
		return $self->_walk($oid_name);
	}

	if ($self->getVersion > 1) {
		return $self->bulk($oid_name);
	} else {
		return $self->_walk($oid_name);
	}
}

sub bulk:RESTRICTED() {
	my $self = shift(@_) or confess "Incorrect call to bulk, self argument missing";
	my $id = ident $self;
	my $oid = shift(@_) or confess "First argument missing in call to bulk";	
	
	#wait, wait, wait...did we get a symbolic name, a numeric oid or a hybrid???
	#ok...I 'll just feed it to SNMP::Class::OID and get the numeric form
	$oid = SNMP::Class::OID->new($oid);
	$logger->debug("Object to bulkwalk is ".$oid->to_string);

	#create the varbind
	my $vb = SNMP::Class::Varbind->new($oid) or confess "cannot create new varbind for $oid";

	#create the bag
	my $ret = SNMP::Class::ResultSet->new();

	#the first argument is definitely 0, we don't want to just emulate an snmpgetnext call
	#the second argument is tricky. Setting it too high (example: 100000) tends to berzerk some snmp agents, including netsnmp.
	#setting it too low will degrade performance in large datasets since the client will need to generate more traffic
	#So, let's set it to some reasonable value, say 10.
	#we definitely should consider giving to the library user some knob to turn.
	#After all, he probably will have a good sense about how big the walk he is doing is.
	
	my ($temp) = $session{$id}->bulkwalk(0,10,$vb->get_varbind); #magic number 10 for the time being
	#make sure nothing went wrong
	confess $session{$id}->{ErrorStr} if ($session{$id}->{ErrorNum} != 0);

	####my $ret;
	for my $object (@{$temp}) {
		###my ($oid_name,$instance,$value,$type) = @{$object};
		###print Dumper($object);
		my $vb = SNMP::Class::Varbind->new_from_varbind($object);
		
		$logger->debug($vb->get_oid->to_string."=".$vb->get_value." Object is ".$vb->get_object->to_string.",instance is ".$vb->get_instance_numeric);
		
		#put it in the bag
		$ret->push($vb);
	}					
	return $ret;
}


#does an snmpwalk on the session object
sub _walk:RESTICTED() {
	my $self = shift(@_) or confess "Incorrect call to _walk, self argument missing";
	my $id = ident $self;
	my $oid = shift(@_) or confess "First argument missing in call to get_data";

	#wait, wait, wait...did we get a symbolic name, a numeric oid or a hybrid???
	#we don't care, feed it to SNMP::Class::OID and it'll figure it out
	$oid = SNMP::Class::OID->new($oid);
	$logger->debug("Object to walk is ".$oid->to_string);

	#we will store the previous-loop-iteration oid here to make sure we didn't enter some loop
	#we init it to something that can't be equal to anything
	my $previous = SNMP::Class::OID->new("0.0");##let's just assume that no oid can ever be 0.0

	#create the varbind
	my $vb = SNMP::Class::Varbind->new($oid) or confess "cannot create new varbind for $oid";

	#create the bag
	my $ret = SNMP::Class::ResultSet->new();

	LOOP: while(1) {
		#call an SNMP GETNEXT operation
		my $value = $session{$id}->getnext($vb->get_varbind);

		#make sure nothing went wrong
		confess $session{$id}->{ErrorStr} if ($session{$id}->{ErrorNum} != 0);

		$logger->debug($vb->get_oid->to_string."=".$value." Object is ".$vb->get_object->to_string.",instance is ".$vb->get_instance_numeric.",type is ".$vb->get_type);

		#handle some special types
		#For example, a type of ENDOFMIBVIEW means we should stop
		if($vb->get_type eq 'ENDOFMIBVIEW') {
			$logger->debug("We should stop because an end of MIB View was encountered");
			last LOOP;
		}

		#make sure that we got a different oid than in the previous iteration
		#(remember, the NetSNMP::OID has an overloaded '==' operator)
		if($previous == $vb->get_oid) { 
			confess "OID not increasing at ".$vb->get_oid->numeric." (".$vb->get_oid->to_string.")\n";
		}

		#make sure we are still under the original $oid -- if not we are finished
		if(!$oid->contains($vb->get_oid)) {
			$logger->debug($oid->numeric." does not contain ".$vb->get_oid->numeric." ... we should stop");
			last LOOP;
		}

		####$r->{$vb->[0]}->{$vb->[1]} = $vb->[2];
		#this is the same object all the times -- plz fix me
		$ret->push($vb);

		#Keep a copy for the next iteration
		$previous = $vb->get_oid;

		#we need to make sure that next iteration we won't overwrite the same $vb
		$vb = SNMP::Class::Varbind->new($vb->get_oid);

	};
	return $ret;
}	

=head2 AUTOMETHOD

Using a method call that coincides with an SNMP OBJECT-TYPE name is equivalent to issuing a walk with that name as argument. This is provided as a shortcut which can result to more easy to read programs. 
Also, if such a method is used in a list context, it won't return an SNMP::ResultSet object, but rather a list with the ResultSet's contents. This is pretty convenient for iterating through SNMP results using few lines of code.

=cut

sub AUTOMETHOD {
	my $self = shift(@_) or croak("Incorrect call to AUTOMETHOD");
	my $ident = shift(@_) or croak("Second argument to AUTOMETHOD missing");
	my $subname = $_;   # Requested subroutine name is passed via $_;
	$logger->debug("AUTOMETHOD called as $subname");  
	
	if (eval { my $dummy = SNMP::Class::Utils::get_attr($subname,"objectID") }) {
		$logger->debug("$subname seems like a valid OID ");
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
			return @{$self->walk($subname)->varbinds};
		}
		return $self->walk($subname);
	}

}



#note: all the following MIB parsing methods could be moved to a special module

#arr2str converts an array to a numeric oid
sub arr2str {
	return '.'.join('.',@_);
}

#str2arr converts a .1.2.3.4-style oid to an array
sub str2arr {
	my $str = shift(@_) or confess "str2arr 1st arg missing";
	my ($dummy,@ret) = split('\.',$str); 
	return @ret;
}
	



=head1 AUTHOR

Athanasios Douitsis, C<< <aduitsis at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-snmp-class at rt.cpan.org>, or through the web interface at
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

This module obviously needs the perl libraries from the excellent Net-SNMP package. Many thanks go to the people that make that package available.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Athanasios Douitsis, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SNMP::Class
