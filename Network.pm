#!/usr/bin/perl

use warnings;
use strict;
use Readonly;

our $VERSION = 1.0.0;

package Network;

use City;

Readonly::Scalar my $RANDOM_DISTANCE => 100;
Readonly::Scalar my $MIN_DISTANCE => 3;


############################################################################################################################
#                                                                                                                         
#     new                                                                                                                  
#                                                                                                                          
############################################################################################################################
#                                                                                                                          
# (#) DESCRIPTION:                                                                                                         
#     builds a new instance of a Network object.                                                                              
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
#     param   $class   The package that called this, in this case the Network package.
#     returns $self    A reference to the Object.
#
############################################################################################################################
sub new
{
  ##First get the object that class package from whoever called this.##
  my $class = shift;

  ##Now setup the hash that will store the values for this objects instance.##
  my $self = {
    _total => undef,
    _nodes => undef,
  };

  ##Bless the class to get a reference to the instance of this new object and return the reference.##
  bless $self, $class;
  return $self;
}





############################################################################################################################
#                                                                                                                         
#     set_total                                                                                                                 
#                                                                                                                          
############################################################################################################################
#                                                                                                                          
# (#) DESCRIPTION:                                                                                                         
#     Sets the current total number of cities in the network.                                                                              
#                                                                      
# (#) ABSTRACT:
#     This subroutine gets the arguements passed to it and then sets the total value of this network object.
#
# (#) LIMITATIONS:
#     None
#
############################################################################################################################
#
#     param   $self             The package that called this, in this case the city package.
#     param   $total            The total number of cities in the current network.
#     returns $self->{_total}   The objects current total number of cities.
#
############################################################################################################################
sub set_total
{
  ##Retreive the arguments passed to this subroutine.##
  my ( $self, $total ) = @_;

  ##Set the object total value to the value passed.##
  if(defined $total)
  {
   $self->{_total} = $total;
  }

  ##Return the network object's current value for its total.##
  return $self->{_total};
}





############################################################################################################################
#                                                                                                                         
#     get_total                                                                                                                  
#                                                                                                                          
############################################################################################################################
#                                                                                                                          
# (#) DESCRIPTION:                                                                                                         
#     Gets the total number of cities in the network.                                                                              
#                                                                      
# (#) ABSTRACT:
#     Gets a reference to the object and returns the total number of cities in the network.
#
# (#) LIMITATIONS:
#     None
#
############################################################################################################################
#
#     param   $self              A reference to the object.
#     returns $self->{_total}    The current total number of cities in the object.
#
############################################################################################################################
sub get_total
{
  ##Get the object reference that called this and return its total.##
  my( $self ) = @_;
  return $self->{_total};
}





############################################################################################################################
#                                                                                                                         
#     get_nodes                                                                                                                  
#                                                                                                                          
############################################################################################################################
#                                                                                                                          
# (#) DESCRIPTION:                                                                                                         
#     Gets a reference to the array that contains all the cities in the network.                                                                            
#                                                                      
# (#) ABSTRACT:
#     This subroutine gets the reference to the object that called it and then returns a reference
#     to the network array that holds all the cities in the network.
#
# (#) LIMITATIONS:
#     None.
#
############################################################################################################################
#
#     param   $self              A reference to the object.
#     returns $self->{_nodes}    A reference to the network array.
#
############################################################################################################################
sub get_nodes
{
  ##Get the object reference that called this and return the refernce to nodes.##
  my( $self ) = @_;
  return $self->{_nodes};
}





############################################################################################################################
#                                                                                                                         
#     add_node                                                                                                                  
#                                                                                                                          
############################################################################################################################
#                                                                                                                          
# (#) DESCRIPTION:                                                                                                         
#     Inserts a node into the network giving it random distances to all the other cities in the network.                                                                             
#                                                                      
# (#) ABSTRACT:
#     This subroutine will insert a new node into the network. If the node to be inserted is the first node
#     in the network then, the the first ciry will be number zero and the will be set to zero distance to itself.
#     If there are already nodes in the network then the will be put at the end of the network array and will
#     be named according to its position in the network array. Then the new city and all other cities in the 
#     network need to be updated with new distance to the city that has been added. The new city object will be returned.
#
# (#) LIMITATIONS:
#     None.
#
############################################################################################################################
#
#     param   $self      A reference to the object that called this.
#     returns $new_city  The new city object that was added to the network.
#
############################################################################################################################
sub add_node
{
  ##Get the object reference that called this.##
  my( $self ) = @_;

  ##decalre the newcity variable.##
  my $new_city;

  ##If the network cities array has already been setup, then other cities must be updated.##
  if(defined $self->{_nodes})
  {

    ##Use the reference to create an array the holds the cities in the network.##
    my $node_ref = $self->{_nodes};
    my @nodes = @{$node_ref};

    ##Create a new city and set its number to the next aviable number, which is##
    ##the total number of cities in the network before the city was added.     ##
    $new_city = City->new();
    $new_city->set_number($self->{_total});

    ##Update the new network total now that the city has been created for both the network and the city.##
    $self->{_total} = $self->{_total} + 1;
    $new_city->set_total($self->{_total});

    ##insert the new city into the last spot in the network array and set##
    ##a reference to the network array in the network object.            ##
    push @nodes, $new_city;
    $self->{_nodes} = \@nodes;

    ##Cycle through for every city currently in the network and update the other and total values.##
    for my $count (0 .. ($self->{_total} - 2))
    {
      ##Create a random number that wiil represent the distance between the cities.##
      my $random_number = (int rand $RANDOM_DISTANCE) + $MIN_DISTANCE;

      ##Set the new city's city distance array with the new distance.##
      $new_city->set_others($count, $random_number);

      ##Update the exhisting cities' city distance arrays and total values.##
      $nodes[$count]->set_total($self->{_total});
      $nodes[$count]->set_others(($self->{_total} - 1), $random_number);
    }

    ##Set the last position of the new city's city distance array. It is the distance to itself which is zero.##
    $new_city->set_others($self->{_total} - 1, 0);
  }
  else ##The nodes array is empty and the first city can be created and inserted.##
  {
    ##Update the network to have a total of one cities in it for the new city that is being added.##
    $self->{_total} = 1;

    ##Create the first city and give it intial values.##
    $new_city = City->new();
    $new_city->set_number(0);
    $new_city->set_total($self->{_total});
    $new_city->set_others(0, 0);

    ##Create the new array, and add the new city to it.##
    my @nodes;
    push @nodes, $new_city;

    ##Set the networks network array to reference the nodes in the network.##
    $self->{_nodes} = \@nodes;
  }

  ##Return the city that was just added.
  return $new_city;
}

1;