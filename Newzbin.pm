# This program is free software; you can redistribute it and/or modify
# it under the terms of the Artistic License, which comes with Perl.

# Copyright 2009 Thomas Jager <mail@jager.no>

package Newzbin;

sub new {
	my $pakage = shift;
	my $options = shift;
	die "Missing mandetory options" if not defined $options or not ref $options;
	die "Missing mandetory username" if not defined $options->{username};
	die "Missing mandetory password" if not defined $options->{password};
	
	return bless $package, $options;
}

1; 
