#!/usr/bin/perl

use warnings;
use strict;

our $VERSION = 1.0.0;

package City;


############################################################################################################################
#                                                                                                                         
#     new                                                                                                                  
#                                                                                                                          
############################################################################################################################
#                                                                                                                          
# (#) DESCRIPTION:                                                                                                         
#     builds a new instance of a City object.                                                                              
#                                                                      
# (#) ABSTRACT:
#     This subroutine will build the object by creating a hash that will hold the values of the object. It then blesses
#     the self to create the object reference and then returns the reference.
#
# (#) LIMITATIONS:
#     None
#
############################################################################################################################
#
#     param   $class   The package that called this, in this case the city package.
#     returns $self    A reference to the Object.
#
############################################################################################################################
sub new
{
  ##First get the object that class package from whoever called this.##
  my $class = shift;

  ##Now setup the hash that will store the values for this objects instance.##
  my $self =
  {
    _number => undef,
    _total => undef,
    _others => undef
  };

  ##Bless the class to get a reference to the instance of this new object and return the reference.##
  bless $self, $class;
  return $self;
}





############################################################################################################################
#     
#     set_number
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     sets the number of the city object, which is also the name of the city.
#
# (#) ABSTRACT:
#     Take the number passed to it and sets the number value of the current object instance to it. Then returns the number.
#
# (#) LIMITATIONS:
#     None
#
############################################################################################################################
#
#     param   $self            The object that called this.
#     param   $number          The number to be set for this city.
#     returns $self->{_number} The number that was set.
#
############################################################################################################################
sub set_number
{
  ##Retreive the arguments passed to this subroutine.##
  my ( $self, $number ) = @_;

  ##Set the object number value to the number passed.##
  if(defined $number)
  {
    $self->{_number} = $number;
  }

  ##Return the city objects current value for its number.##
  return $self->{_number};
}





############################################################################################################################
#     
#     get_number
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     Gets the current number of the city object.
#
# (#) ABSTRACT:
#     Returns the number of the city.
#
# (#) LIMITATIONS:
#     None.
#
############################################################################################################################
#
#     param   $self            The object that called this.
#     returns $self->{_number} The number of the city.
#
############################################################################################################################
sub get_number
{
  ##Get the object reference that called this and return its number.##
  my( $self ) = @_;
  return $self->{_number};
}





############################################################################################################################
#     
#     set_total
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     Sets the total number of cities that belong to the network this city is in.
#
# (#) ABSTRACT:
#     Takes the number passed to the subroutine and sets the total value to record the current number of cities in the
#     network.
#
# (#) LIMITATIONS:
#     None.
#
############################################################################################################################
#
#     param   $self            The object that called this.
#     param   $total           The total number of cities that are currently in the network.
#     return $self->{_total}   The total number of cities in the network is returned.
#
############################################################################################################################
sub set_total
{
  ##Get the arguments passed to this subroutine.##
  my( $self, $total ) = @_;

  ##Set the current city objects total number of cities to the values passed.##
  if(defined $total)
  {
    $self->{_total} = $total;
  }

  ##Return the current value of the total number of cities in the network.##
  return $self->{_total};
}





############################################################################################################################
#     
#     get_total
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     Gets the total number of cities that belong to the network this city is in.
#
# (#) ABSTRACT:
#     Returns the number of the cities that belong to the current network.
#
# (#) LIMITATIONS:
#     None.
#
############################################################################################################################
#
#     param   $self            The object that called this.
#     returns $self->{_total}  The number of the cities in the current network.
#
############################################################################################################################
sub get_total
{
  ##Get the reference to the object that called this subroutine and return the total number of cities in the network.##
  my( $self ) = @_;
  return $self->{_total};
}





############################################################################################################################
#     
#     set_others
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     Sets the distance of another city to this city.
#
# (#) ABSTRACT:
#     This subroutine takes in the city to be added to this city's city distance array and the distance that city is 
#     from this city. The citys are stored in the array by there numbers which also happens to be their name. It then 
#     inserts the city into the array. A reference to the city distances array is then returned. 
#
# (#) LIMITATIONS:
#     None.
#
############################################################################################################################
#
#     param   $self            The object that called this.
#     param   $position        The number of the city that is to be added to the city distance array.
#     param   $distance        The distance that the city that is being added is from this city.
#     returns $self->{_others} A reference to the city distance array.
#
############################################################################################################################
sub set_others
{
  ##Get the arguements passed to this subroutine.##
  my ( $self, $position, $distance ) = @_;

  ##create an array referance.##
  my $array_ref = $self->{_others};

  ##If the city distance array has already had cities inserted then:##
  if(defined $self->{_others})
  {
    ##Get the array and insert the distance of the other city at the correct city's postion.##
    my @array = @{$array_ref};
    splice @array, $position, 1, $distance;
    $self->{_others} = \@array;
  }
  else ##No cities have been put into distance.##
  {
    ##Put the other city's distance into the city distance array.##
    my @array;
    push @array, $distance;
    $self->{_others} = \@array;
  }

  ##Return a reference to the city distance array.##
  return $self->{_others};
}





############################################################################################################################
#     
#     get_others
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     Gets the array that holds the distances of all other cities to this city.
#
# (#) ABSTRACT:
#     Returns the city's city distance array reference.
#
# (#) LIMITATIONS:
#     None.
#
############################################################################################################################
#
#     param   $self            The object that called this.
#     returns $self->{_others} A reference to the city distance array.
#
############################################################################################################################
sub get_others
{
  ##Get the object reference that called this subtroutine and return a reference to the city distance array.##
  my( $self ) = @_;
  return $self->{_others};
}

1;