#! /usr/bin/perl 

use warnings;
use strict;
use Readonly;
use English '-no_match_vars';
use Carp;

our $VERSION = 1.1.0;

use autodie;
use Tkx;
use City;
use Network;
use List::Permutor;

############################################################################################################################
# intialize package variables
############################################################################################################################

Readonly::Scalar my $LARGE_NUM_CITY => 14;     ##The number of cities is to large to print clear paths.            ##
Readonly::Scalar my $PERCENT_VALUE => 100;     ##Multple the decimal by this to get the percent.                   ##
Readonly::Scalar my $GUI_REFRESH => 10_000;    ##Cycles of TSP processing ebfore reresfhing the GUI.               ##
Readonly::Scalar my $PERCENT_REFRESH => 1_000; ##Cycles of TSP processing boefore refreshing the percent.          ##
Readonly::Scalar my $ADD_REFRESH => 1_000;     ##Cycles of processing before refreshing th GUI when adding cities. ##
Readonly::Scalar my $ADD_CITY_COUNT => 25;     ##The interval to update that a certain number of cities were added.##

##Time Constants##
Readonly::Scalar my $SEC_IN_MIN  => 60;
Readonly::Scalar my $SEC_IN_HOUR => 60  * $SEC_IN_MIN;
Readonly::Scalar my $SEC_IN_DAY  => 24  * $SEC_IN_HOUR;
Readonly::Scalar my $SEC_IN_MON  => 30  * $SEC_IN_DAY;
Readonly::Scalar my $SEC_IN_YEAR => 365 * $SEC_IN_DAY;
Readonly::Scalar my $SEC_IN_100Y => 100 * $SEC_IN_YEAR;

my $num_cities    = 0; ##Current number of cities in the network.       ##
my $num_city_lbl  = 0; ##Number of cities to be printed in the label.   ##
my $progresscount = 0; ##Progress bar counter.                          ##
my $brutequit     = 0; ##A flag t signal brute force solver to quit.    ##
my $totaltime     = 0; ##The total time a solution is predicted to take.##
my $timeelap      = 0; ##The time a soultion has already taken.         ##

my $percentdisp   = '0%';                    ##Progress Bar counter percent display.     ##
my $currentbest   = 'Solution Undetermined'; ##Current best solution path.               ##
my $permutesvar   = '0';                     ##Number of steps taken in current solution.##
my $etavar        = 'ETA:';                  ##Time till solution is complete.           ##

my @currentlist; ##A current shortest path list.                     ##
my $mynetwork;   ##The network object.                               ##

############################################################################################################################
# set up the main window 
############################################################################################################################

##Create and title the main window.##
my $main_window = Tkx::widget->new(q{.});
$main_window->g_wm_title('TSP solver');
$main_window->g_wm_protocol('WM_DELETE_WINDOW', sub{destroy();});

##configure how main window will organize its columns and rows.##
$main_window->g_grid_columnconfigure(0, -weight => 1);
$main_window->g_grid_rowconfigure   (0, -weight => 1);

############################################################################################################################
# create the window frames and organize the 
# frames inside the main window
############################################################################################################################

##Create the frames.##
my $textframe     = $main_window->new_ttk__frame();
my $numberframe   = $main_window->new_ttk__frame();
my $networkframe  = $main_window->new_ttk__frame();
my $solutionframe = $main_window->new_ttk__frame();

##Organize the frames inside the main window.##
$textframe->g_grid    (-column => 0, -row => 2, -sticky => 'nsew', -padx => 10, -pady => 10, -columnspan => 3);
$numberframe->g_grid  (-column => 0, -row => 0, -sticky => 'nsew', -padx => 10, -pady => 10);
$networkframe->g_grid (-column => 1, -row => 0, -sticky => 'nsew', -padx => 10, -pady => 10);
$solutionframe->g_grid(-column => 0, -row => 1, -sticky => 'nsew', -padx => 10, -pady => 10, -columnspan => 2);

############################################################################################################################
# create, organize and configure 
# the widgets for the $solutionframe
############################################################################################################################

##Create the widgets for the solution frame.##
my $solutionprogress = $solutionframe->new_ttk__progressbar
  (-orient => 'horizontal', -mode => 'determinate', -length => 400);

my $solutionlbl      = $solutionframe->new_ttk__label (-text => 'Solution Undetermined', -anchor => 'center');
my $percentlbl       = $solutionframe->new_ttk__label (-text => '0%', -anchor => 'center');
my $etalbl           = $solutionframe->new_ttk__label (-text => 'ETA:', -anchor => 'e');
my $permuteslbl      = $solutionframe->new_ttk__label (-text => '0/0', -anchor => 'e');
my $totaltimelbl     = $solutionframe->new_ttk__label (-text => '0/0', -anchor => 'e');
my $timelaplbl       = $solutionframe->new_ttk__label (-text => '0/0', -anchor => 'e');
my $stopbutton       = $solutionframe->new_ttk__button(-text => 'Quit', -command => sub {destroy();});
my $clearlogbutton   = $solutionframe->new_ttk__button(-text => 'Clear Log', -command => sub {clearlog();});

##Organize the widgets.##
$solutionlbl->g_grid     (-column => 0, -row => 0, -pady => 5, -sticky => 'we', -columnspan => 3);
$solutionprogress->g_grid(-column => 0, -row => 1, -pady => 5, -padx => 10, -sticky => 'w', -columnspan => 3);
$percentlbl->g_grid      (-column => 3, -row => 1, -pady => 5, -sticky => 'w', -padx => 5);
$stopbutton->g_grid      (-column => 3, -row => 0, -pady => 5, -sticky => 'e', -padx => 5);
$etalbl->g_grid          (-column => 0, -row => 2, -pady => 5, -sticky => 'w', -padx => 5);
$permuteslbl->g_grid     (-column => 1, -row => 2, -pady => 5, -sticky => 'w', -padx => 5);
$totaltimelbl->g_grid    (-column => 0, -row => 3, -pady => 5, -sticky => 'w', -padx => 5);
$timelaplbl->g_grid      (-column => 2, -row => 2, -pady => 5, -sticky => 'w', -padx => 5, -columnspan => 2);
$clearlogbutton->g_grid  (-column => 3, -row => 3, -pady => 5, -sticky => 'w', -padx => 5);

##Configure the widgets.##
$percentlbl->configure  (-textvariable => \$percentdisp);
$solutionlbl->configure (-textvariable => \$currentbest);
$etalbl->configure      (-textvariable => \$etavar);
$permuteslbl->configure (-textvariable => \$permutesvar);
$totaltimelbl->configure(-textvariable => \$totaltime);
$timelaplbl->configure  (-textvariable => \$timeelap);

############################################################################################################################
# create, organize and configure 
# the widgets for the $textframe
############################################################################################################################

##Create the widgets.##
my $textdisplay = $textframe->new_tk__text(-height => 15, -width => 60 );
my $scroller    = $main_window->new_ttk__scrollbar (-command => [$textdisplay, 'yview'], -orient => 'vertical');

##Organize the widgets.##
$textdisplay->g_grid(-column => 0, -row => 0, -sticky => 'nsew', -pady => 5, -columnspan => 3);
$scroller->g_grid   (-column => 2, -row => 2, -sticky => 'ns');

##Configure the widgets.##
$textdisplay->configure(-yscrollcommand => [$scroller, 'set']);

############################################################################################################################
# create, organize and configure 
# the widgets for the $numberframe
############################################################################################################################

##Create the widgets.##
my $numberlbl   = $numberframe->new_ttk__label (-text => 'Number of Cities to Build:');
my $numberentry = $numberframe->new_ttk__entry (-width => 4);
my $brutebutton = $numberframe->new_ttk__button(-text => 'Brute Force', -command => sub {brutesolver($solutionprogress);});
my $nnbutton    = $numberframe->new_ttk__button(-text => 'Nearest Neighbor', -command => sub {nearest_neighbor();});
my $optbutton   = $numberframe->new_ttk__button(-text => 'Opt solver', -command => sub {optimizedsolver(1);});

##Organize the widgets.##
$numberlbl->g_grid  (-column => 0, -row => 0, -pady => 5, -columnspan => 2);
$numberentry->g_grid(-column => 2, -row => 0, -pady => 5, -sticky => 'w');
$brutebutton->g_grid(-column => 0, -row => 1, -pady => 5, -padx => 5, -sticky => 'w');
$optbutton->g_grid  (-column => 1, -row => 1, -pady => 5, -padx => 5);
$nnbutton->g_grid   (-column => 2, -row => 1, -pady => 5, -padx => 5);

##Configure the widgets.##
$numberentry->insert(0, 0);
$optbutton->state   ('disabled');
$brutebutton->state ('disabled');
$nnbutton->state    ('disabled');

############################################################################################################################
# create, organize and configure 
# the widgets for the $networkframe
############################################################################################################################

##Create the widgets.##
my $buildbutton = $networkframe->new_ttk__button
  (-text => 'Build Network', -command => sub {build_network($solutionprogress);});

my $buildstatus = $networkframe->new_ttk__label(-anchor => 'w', );
my $buildlbl    = $networkframe->new_ttk__label(-text => 'Current Number of Cities:', -anchor => 'center');

##Organize the widgets.##
$buildbutton->g_grid(-column => 0, -row => 1, -pady => 7, -sticky => 'nsew');
$buildstatus->g_grid(-column => 1, -row => 0, -pady => 5, -sticky => 'w');
$buildlbl->g_grid   (-column => 0, -row => 0, -pady => 5);

##Configure the widgets.##
$buildstatus->configure(-textvariable => \$num_city_lbl);

############################################################################################################################
# Run the mainloop
############################################################################################################################

##The main loop builds and runs the GUI.##
Tkx::MainLoop;

sub destroy{
	kill('HUP', $$);
	exit 0;
}


############################################################################################################################
#     
#     clearlog
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     This subroutine deletes all the text in the text display box.
#
# (#) ABSTRACT:
#     This subroutine use the the textdisplay function delete to clear 
#     the all the text inside the text display box. It passes the parameters
#     '1.0' (to start deleting at the begining) and 'end' (to delete to the end)
#
# (#) LIMITATIONS:
#     None.
#
############################################################################################################################
#
#     returns 1 on completion
#
############################################################################################################################
sub clearlog
{
  ##Delete all the text in text display.##
  $textdisplay->delete('1.0', 'end');
  return 1;
}

############################################################################################################################
#     
#     timecalc
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     This subroutine prints the correct time and time units to the passed widget.
#
# (#) ABSTRACT:
#     The subroutine will check the time in seconds passed to it, and convert it
#     to the correct time units and then apply the units to the correct label 
#     in the main window.
#
# (#) LIMITATIONS:
#     None.
#
############################################################################################################################
#
#     param   $widget_ref the reference to the widgets text variable
#     param   $tempsec    the time in seconds that is to be displayed
#     param   $widgettype the widget type, a string that displays correctly in the widget
#     returns 1 on completion
#
############################################################################################################################
sub timecalc
{
  ##Get arguments passed.##
  my ($widget_ref, $tempsec, $widgettype) = @ARG;

  ##Setup some temp variables.##
  my $tempeta;
  my $timevalue;
  my $timeunit;

  ##This is compareable to an if-else statement, it compares how seconds to a the constants##
  ##and then selects the correct time unit to apply.                                       ##
  while (1)
  {
    if($tempsec < $SEC_IN_MIN) {$timevalue = 1;            $timeunit = 'seconds';   last;}
    if($tempsec < $SEC_IN_HOUR){$timevalue = $SEC_IN_MIN;  $timeunit = 'minutes';   last;}
    if($tempsec < $SEC_IN_DAY) {$timevalue = $SEC_IN_HOUR; $timeunit = 'hours';     last;}
    if($tempsec < $SEC_IN_MON) {$timevalue = $SEC_IN_DAY;  $timeunit = 'days';      last;}
    if($tempsec < $SEC_IN_YEAR){$timevalue = $SEC_IN_MON;  $timeunit = 'months';    last;}
    if($tempsec > $SEC_IN_100Y){$timevalue = $SEC_IN_YEAR; $timeunit = '>100 years';last;}
                                $timevalue = $SEC_IN_YEAR; $timeunit = 'years';     last;
  }

  ##Now format and set the value to the widget.##
  $tempeta = $tempsec/$timevalue;
  $tempeta = sprintf '%.2f', $tempeta;
  ${$widget_ref} = "$widgettype $tempeta $timeunit";

  return 1;
}

############################################################################################################################
#     
#     optimizedsolver
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     This subroutine sets up and operates the recursive seach through the network.
#
# (#) ABSTRACT:
#     The factor is the value of how many nearest nieghbor nodes to check. The function
#     will check each city in the network by calling the recursive checking function for 
#     every city. The recursive function builds a global list of the shortest path it finds.
#     This subroutine will then print out the list. To get the nearest neighbor route, pass
#     a factor of 1 to the function
#
# (#) LIMITATIONS:
#     This subroutine only prints the correct shortest path with a factor of 1. The
#     algorithm needs to be researched more for a greater factor of nearest nieghbors.
#
############################################################################################################################
#
#     param   $factor the number of nearest neighbors to search
#     returns 1 on completion
#
############################################################################################################################
sub optimizedsolver
{
  ##$factor represents how many different routes to explore. Only 1 works well.##
  my ($factor) = @ARG;

  ##Always subtract 1 for looping purposes##
  $factor = $factor - 1;

  ##Initialize variables that will be used through out the subroutine.##
  my $networkpercent = 0;
  my $currentpercent = 0;
  my $percent;
  my $timer = time;

  ##Initialize arrays that will record the shortest path. Shortcitys array is##
  ##used for the current test path. currentlist is for the best know path.   ##
  my @shortcitys = ();
  @currentlist = ();

  ##Get the network array using the reference from the network object.##
  my $node_ref = $mynetwork->get_nodes();
  my @nodearray = @{$node_ref};

  ##Get the network total and first city in order to began main loop.##
  my $networktotal = $mynetwork->get_total() - 1;
  my $currentcity = $nodearray[0];

  ##Loops through the network and checks the distances the closest nearest neighbors depending on##
  ##the factor value.                                                                            ##
  for my $count (0..$networktotal)
  {#---enter main for-loop---#

    ##increase the count of total tests run and update the current percent.##
    $networkpercent++;
    $percent = int(($networkpercent/$networktotal)*$PERCENT_VALUE);

    ##If every $PERCENT_VALUE operations, update time values.##
    if($networkpercent % $PERCENT_VALUE == 0)
    {
      ##intialize time values to be used in the timecalc subroutine.##
      my $temptime = time() - $timer;
      my $tempprog = $networkpercent/$networktotal;
      my $tempsec = (($temptime/$tempprog) - $temptime);
      my $temptotal = ($temptime/$tempprog);

      ##update the 3 time widgets.##
      timecalc(\$etavar, $tempsec, 'Time Left:');
      timecalc(\$totaltime, $temptotal, 'Total Time:');
      timecalc(\$timeelap, $temptime, 'Time Elasped:');

      ##if the percent changes update the progress bar and GUI.##
      if($currentpercent < $percent)
      {
        $currentpercent = $percent;
        $progresscount = $currentpercent;
        $percentdisp = "$percent%";
        $permutesvar = "tests run: $networkpercent";

        ##update GUI.##
        Tkx::update();
      }
    }

    ##clear shortcitys and call recurseopto to find the list of the next closet cities.##
    @shortcitys = ();
    @shortcitys = recurseopto($factor, $currentcity, 0);

    ##Get the total number of shortcitys found from the recurseopto call.##
    my $shortcitystotal = scalar(@shortcitys) - 1;

    ##if no citys were found then you have reached the end of the network.##
    if(!(@shortcitys))
    {
      ##end the for loop and try the next city.##
      last;
    }

    ##shortdistances record the current shortest distance, so that the next city can be checked.##
    my $shortdistances;

    ##this for-loop loops through all the nearest neighbors to select the next city to traverse to.##
    for my $count2 (0..$shortcitystotal)
    {
      ##if there is another city to check, then ##
      if(defined $shortcitys[$count2])
      {
        ##Get the next city to check.##
        my $nextcity = $shortcitys[$count2];

        ##Get a list of the other cities distances to the current city.##
        my $others_ref = $currentcity->get_others();
        my @others = @{$others_ref};

        ##get the next cities name or number so that it can be used to find the distance to the current city.##
        my $city_num = $nextcity->get_number();

        ##get the distance between the current and the next city.##
        my $distcost = $others[$city_num];

        ##find the sum of the next cities nearest neighbor to determine if this next city is##
        ##the best candidate to traverse to.                                                ##
        my $tempdist = recurseopto($factor, $nextcity, 1);

        ##puts the cost of the traversal into the decision process.##
        $tempdist = $tempdist/$distcost;

        ##if there has already been a next city selected as a possible candidate## 
        ##then compare it to the latest candidate.                              ##
        if(defined $shortdistances)
        {
          ##if the new candidate is less then the past candidate, select it.##
          if($tempdist < $shortdistances)
          {
            $shortdistances = $tempdist;
            $currentcity = $nextcity;
          }
        }
        else ##we have no cadidates at the moment, so select the current regardless.##
        {
          $shortdistances = $tempdist;
          $currentcity = $nextcity;

        }##---end of "if(defined $shortdistances)"---##

      }##---end of "if(defined $shortcitys[$count2])"---##

    }##---end of "for my $count2 (0..$shortcitystotal)"---##

  }##---end of enter main for-loop---##

  ##output the results.##
  $textdisplay->insert_end("Nearest Nieghbor Path: @currentlist");

  ##print out total distance of the cities in the list.## 
  my $sum = 0;
  for my $count (0..($mynetwork->{_total} - 2))
  {
    ##get the next city in the list.##
    my $city = $nodearray[$currentlist[$count+1]];

    ##get a list of the current cities distances to other cities.##
    my $array_ref = $city->get_others();
    my @others = @{$array_ref};

    ##add the distance between the current city and the next city.##
    $sum = $sum + $others[$currentlist[$count]];
  }

  ##display the sum of the distances.##
  $textdisplay->insert_end(" at a distance of $sum\n");
  $textdisplay->see('end');

  ##reset current list.##
  @currentlist = ();

  return 1;
}

############################################################################################################################
#     
#     recurseopto
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     This subroutine is the recursive part of the optimized solver function.
#
# (#) ABSTRACT:
#     This subroutine will get a node and check for top shortest nearest neighbors based
#     on how the $factor value that is passed to it. It will then call itself on the top
#     nearest nieghbors found. It is always checking to see if the current path is the shortest
#     and updating a global array if the current path found is better. the subroutine also 
#     functions as a distance calculator. The $ndistance flag will set it to only calculate the
#     distances of the nearest nieghbors combined. This vale is then returned for a decision
#     making process in the same function.
#
# (#) LIMITATIONS:
#     This subroutine only works for the shortest path with a factor of 1. The
#     algorithm needs to be researched more for a greater factor of nearest nieghbors.
#
############################################################################################################################
#
#     param   $factor           the factor, telling how many nearest nieghbors to check
#     param   $currentnode_ref  a reference to the current node in the network
#     param   $ndistance        this is a flag alerting the function to get distance or a list of the next nearest neighbors
#     returns $sum              the sum of the nearest neighbors distances if $ndistance equals 1
#     returns @actualshortcitys a list of the new shortest citys to check if $ndistance equals 0
#     returns 0 on error
#
############################################################################################################################
sub recurseopto
{
  ##get the arguments passed to this subroutine.##
  my ( $factor, $currentnode, $ndistance) = @ARG;

  ##get the number value from the current city.##
  my $currentcitynum = $currentnode->get_number();

  ##If the the flag ndistance is not set then this subroutine is to find a list of the next nearest nieghbors.##
  if($ndistance == 0)
  {
    ##the current city has been selected from whoever called this. save the selection to currentlist for later.##
    push @currentlist, $currentcitynum;
  }

  ##get the other cities distance from the current city.##
  my $others_ref = $currentnode->get_others();
  my @others = @{$others_ref};

  ##intitialize some values.##
  my @actualshortcitys = ();
  my @shortcitys = ();
  my $currentshortest;
  my $currenttotal = $currentnode->get_total() - 1;
  my $shortcitytotal = scalar(@shortcitys) - 1;

  ##get a list the size of $factor of the nearest nieghbors.##
  for my $count1 (0..$factor)
  {
    ##in each loop we will reset current shortest city number.##
    $currentshortest = undef;

    ##check every city in the network.##
    for my $count2 (0..$currenttotal)
    {
      ##if a previous city has been found, then check and see if the current city is shorter.##
      if(defined $currentshortest)
      {
        ##check to make sure that the current city is not the same as the one being checked, then compare the distances.##
        if( $currentcitynum != $count2 and $others[$currentshortest] >= $others[$count2])
        {
          ##checks to make sure the city that has been found is not already in the lists.##
          shortest_city_finder(\$currentshortest, $count2, @shortcitys);
        }
      }
      else ##no previous cities have been found yet we, need to start the list.##
      {
        ##This is normal case.##
        if($currentcitynum != $count2)
        {
          ##checks to make sure the city that has been found is not already in the lists.##
          shortest_city_finder(\$currentshortest, $count2, @shortcitys);
        }
        else ##This is the special intial case, that the first city is being check against itself.##
        {
          ##checks to make sure the city that has been found is not already in the lists.##
          shortest_city_finder(\$currentshortest, $count2, @shortcitys);

          ##because the current shortest cant point to itself, we increase to the next city,##
          ##and assume maybe this is the shortest                                           ##
          if(defined $currentshortest)
          {
           $currentshortest++;
          }
        }
      }
    }

    ##if a new shortest city was found then we need to add it to the lists.##
    if(defined $currentshortest)
    {
      ##get the network array.##
      my $nodes_ref = $mynetwork->get_nodes();
      my @nodes = @{$nodes_ref};

      ##get the next shortest city object.##
      my $tempshortcity = $nodes[$currentshortest];

      ##add the city number and the city object a respective list.##
      push @shortcitys, $currentshortest;
      push @actualshortcitys, $tempshortcity;
    }
  }

  ##if the ndistance flag is not set then we are looking for a list of the next shortest cities.##
  if($ndistance == 0)
  {
    return @actualshortcitys;
  }
  else  ##we are looking for the sum of the distance of the next shortest cities.##
  {
    my $sum = 0;

    ##check if there are any citys to add.##
    if(@actualshortcitys)
    {
      ##add each city to the sum.##
      for my $count (0..(scalar(@actualshortcitys) - 1))
      {
        if(defined $actualshortcitys[$count])
        {
          ##get the city.##
          my $tempcity = $actualshortcitys[$count];

          ##find the distance from one of the nearest neighbors to the current city.## 
          my $tempcityname = $tempcity->get_number();
          $sum = $sum + $others[$tempcityname];
        }
      }
    }
    ##return the sume fo the distances of the neareast neighbors of the current city being checked.##
    return $sum;
  }
  return 0;
}

############################################################################################################################
#     
#     shortest_city_finder
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     This subroutine is a helper subroutine for the recursive funtion, with get the shortest
#     distance of all cities connected to the current node.
#
# (#) ABSTRACT:
#     This subroutine works by checking if the list passed to it is defined or not. If the list is defined
#     then that means that the list must be checked against the current global list to make sure there are no
#     repeats. If the list is not defined then we can just check against the list passed list of cities 
#     to make sure there are no repeats. If a city is already found in any of the list then the current
#     city being checked is not the shortest. If a new shortest is found, the check flag will not be set,
#     so we can add this city to the shortest path list.
#
# (#) LIMITATIONS:
#     None.
#
############################################################################################################################
#
#     param   $currentshortest_ref this is a reference to the current shortest distance city to be added to the list
#     param   $city                this is the city that is being checked to see if it is the new shortest path
#     param   @list                this is the current shortest list being checked and built
#     returns 1 on completion
#
############################################################################################################################
sub shortest_city_finder
{
  ##get the arguments passed.##
  my ($currentshortest_ref, $city, @list) = @ARG;

  ##intialize the check flag.##
  my $check = 0;

  ##if the list that is passed is not empty then check agaisnt that.##
  if(@list)
  {
    ##check to see if this city is in that list.##
    $check = short_city_checker($city, @list);
  }
  else ##the list is empty so check if it is not in the current list.##
  {
    ##check to see if this city is in that list.##
    $check = short_city_checker($city, @currentlist);
  }

  ##if the city was not already found, then we can add this to the lists.##
  if($check == 0)
  {
    ${$currentshortest_ref} = $city;
  }

  return 1;
}


############################################################################################################################
#     
#     short_city_checker
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     This subroutine is a helper function for the shortest_city_finder subroutine. It checks to see if the
#     current city passed to it is in the list passed to it.
#
# (#) ABSTRACT:
#     This will look through the list and will check to see if the current city is in the list. If the city is
#     then return 1, if not then return 0.
#
# (#) LIMITATIONS:
#     None.
#
############################################################################################################################
#
#     param   $current_city the current city we are looking for
#     param   @citylist     the list of cities to look through
#     returns 1             returns 1 if the city is found
#     returns 0             returns 0 if the city is not found
#
############################################################################################################################
sub short_city_checker
{
  ##get the arguments passed.##
  my ($current_city, @citylist) = @ARG;

  ##get the length of the list.##
  my $citylisttotal = scalar(@citylist) - 1;

  ##if the list is defined the check it.##
  if(@citylist)
  {
    for my $count (0..$citylisttotal)
    {
      ##if the city passed is found return 1.##
      if($current_city == $citylist[$count])
      {
        return 1;
      }
    }
  }
  return 0;
}

############################################################################################################################
#     
#     nearest_neighbor
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     This is the entry point for a recursive funtion that finds the nearest neighbor path in the city network.
#
# (#) ABSTRACT:
#     This sets up the intitial values that will be input into the recursive function. It also 
#     prints out the result to the text display. 
#
# (#) LIMITATIONS:
#     None.
#
############################################################################################################################
#
#     returns 1  returns 1 on completion
#
############################################################################################################################
sub nearest_neighbor
{
  ##get the network array.##
  my $node_ref = ($mynetwork->get_nodes());
  my @nodes = @{$node_ref};

  ##get the first city and intialize the list.##
  my $city = $nodes[0];
  my @shortlist = ();

  ##run the recursion.##
  @shortlist = n_n_recurse($city, 0, \@shortlist, \@nodes);

  ##the distance is the last item on the list, pop it off.##
  my $totaldist = pop @shortlist;

  ##print the result.##
  $textdisplay->insert_end("Nearest Neighbor Path: @shortlist at a distance of $totaldist\n");
  $textdisplay->see('end');

  ##update the GUI.##
  Tkx::update();

  return 1;

}

############################################################################################################################
#     
#     n_n_recurse
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     This is the recursive funtion used to find the nearest neighbor path in the network.
#
# (#) ABSTRACT:
#     This subroutine first checks all the citys that have not been placed in the list already. Then 
#     it records the shortest distance. If there is other citys to check then it calls itself on the return statement.
#     If there our no more cities to check then it insert the total distance recorded and starts the return process.
#
# (#) LIMITATIONS:
#     None.
#
############################################################################################################################
#
#     param   $city          The current city
#     param   $distsum       The sum of the distances so far
#     param   $shortlist_ref A reference to the shortcity list that records our path
#     param   $nodes_ref     A reference to the network array
#     returns @shortlist     Return the list of the nearest neighbor path
#     returns n_n_recurse()  The recursive return, each recursion will return the completed list.
#
############################################################################################################################
sub n_n_recurse
{
  ##Get teh arguments passed.##
  my ( $city, $distsum, $shortlist_ref, $nodes_ref ) = @ARG;

  ##get the arrays.##
  my $array_ref = $city->get_others();
  my @others = @{$array_ref};
  my @shortlist = @{$shortlist_ref};
  my @nodes = @{$nodes_ref};

  ##intitialize the variables.##
  my $shortestdistance;
  my $nextcitynumber;
  my $nextcityobject;
  my $totalcities = (scalar(@others) - 1);

  ##check all the cities.##
  for my $count (0..$totalcities)
  {
    ##make sure that the current city has not already been added to the list.##
    if(short_city_checker($count, @shortlist) == 0)
    {
      ##a shortest hasnt been found yet, assume this is the shortest.##
      if(! defined $shortestdistance)
      {
        ##record the distance and the city number.##
        $shortestdistance = $others[$count];
        $nextcitynumber = $count;
      }
      ##compare this distance with the most recent shortest distance recorded and make sure its not this city.##
      elsif($others[$count] < $shortestdistance && $city->get_number() != $count)
      {
        ##record the distance and the city number.##
        $shortestdistance = $others[$count];
        $nextcitynumber = $count;
      }
    }
    ##update the GUI.##
    Tkx::update();
  }

  ##if there is another city to check, the continue the recursion.##
  if( defined $nextcitynumber )
  {

    ##get the next city as an object to pass to the recursion.##
    $nextcityobject = $nodes[$nextcitynumber];

    ##save the city into the list and add to the sum of the distances.##
    push @shortlist, $nextcitynumber;
    $distsum = $distsum + $shortestdistance;

    ##continue the recursion on the return statement.##
    return n_n_recurse($nextcityobject, $distsum, \@shortlist, \@nodes );

  }
  else ##no more cities to check, time to return the result up the chain.##
  {
    ##save the distance and return.##
    push @shortlist, $distsum;
    return @shortlist;
  }
}

############################################################################################################################
#     
#     brutesolver
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     This subroutine will find the shortest path in the network by using brute force method and checking every
#     possible path.
#
# (#) ABSTRACT:
#     This subtroutine will use permutations to find all the possible paths through the network and then calculates
#     the distance of this path. it will print out the current shortest path to the widget, and update progress on
#     its calculations.
#
# (#) LIMITATIONS:
#     None.
#
############################################################################################################################
#
#     returns 1 on completion
#
############################################################################################################################
sub brutesolver
{
  ##get passed arguments.##
  my $progressbar = shift;

  ##button should be disabled while processing, to prevent dual processing.##
  $brutebutton->state('disabled');

  ##initialize the widgets.##  
  $percentdisp = '0%';
  $currentbest = 'Solution Undetermined';

  ##initialize the progress bar.##
  my $currentpercent = 0;
  $progressbar->configure(-variable => \$currentpercent);

  ##intialize the variables.##
  my $timer = time;;
  my $shortsum;
  my $percentcount = 0;
  my @shortperm;
  my $sum = 1;

  ##intitialize the network array.##
  my $node_ref = ($mynetwork->get_nodes());
  my @nodes = @{$node_ref};

  ##prepare the permutations list.##
  my $permutor = List::Permutor->new (0..(($mynetwork->get_total()) - 1));

  ##This is an escape sequance flag used to quit processing and reenable the button.##
  if($brutequit == 1)
  {
    $brutequit = 0;
  }

  ##get the total permutations for the widgets by taking the factorial of the total cities.##
  for my $count (1..(($mynetwork->get_total()) - 1))
  {
    $sum = $sum * $count;
  }
  my $totalpurmutes = $sum;

  ##check every permutation.##
  while (my @permutation = $permutor->next())
  {
     ##record this as a test run.##
     $percentcount++;

     ##we only want to check routes starting from the first city, so exit the loop if not 0, the starting city.##
     if($permutation[0] != 0)
     {
       last;
     }

     ##find the distance of the current permutation path.##
     $sum = 0;
     for my $count (0..(($mynetwork->get_total()) - 2))
     {
       ##get the next city in the list.##
       my $city = $nodes[$permutation[$count+1]];

       ##get a list of the current cities distances to other cities.##
       my $array_ref = $city->get_others();
       my @others = @{$array_ref};

       ##add the distance between the current city and the next city.##
       $sum = $sum + $others[$permutation[$count]];
     }

     ##if the new sum is less then the most recent recorded sum the save it.##
     if(defined $shortsum)
     {
       if($shortsum > $sum)
       {
         ##record the new distance and path.##
         $shortsum = $sum;
         @shortperm = @permutation;

         ##if dealing with a large network, dont print best above the progess bar, instead print to text display.##
         if($mynetwork->get_total() > $LARGE_NUM_CITY)
         {
           ##print to the text display.##
           $currentbest = "Current best: total distance = $shortsum";
           $textdisplay->insert_end("\nCurrent best: path = @shortperm, total distance = $shortsum\n");
           $textdisplay->see('end');
         }
         else
         {
           ##print above the progress bar.##
           $currentbest = "Current best: path = @shortperm, total distance = $shortsum";
         }

         ##save the distance on the end of the path.
         push @shortperm, $sum;
       }
     }
     else ##no distance has been defined yet, assusme the first path is the shortest.##
     {
       ##record the distance and path.##
       $shortsum = $sum;
       @shortperm = @permutation;

       ##save the distance on the end of the path.
       push @shortperm, $sum;
     }

     ##calculate the new percent.##
     my $percent = int(($percentcount/$totalpurmutes)*$PERCENT_VALUE);

     ##update the gui time widgets.##
     if($percentcount % $GUI_REFRESH == 0)
     {
       ##intitialize the time variables.##
       my $temptime = time() - $timer;
       my $tempprog = $percentcount/$totalpurmutes;
       my $tempsec = (($temptime/$tempprog) - $temptime);
       my $temptotal = ($temptime/$tempprog);

       ##call the time calculator for each widget.##
       timecalc(\$etavar, $tempsec, 'Time Left:');
       timecalc(\$totaltime, $temptotal, 'Total Time:');
       timecalc(\$timeelap, $temptime, 'Time Elasped:');
     }

     ##update the gui and check if the escape flag has been set.##
     if($percentcount % $PERCENT_REFRESH == 0)
     {
       Tkx::update();

       ##if the flag has been set then set it back and quit loop.##
       if($brutequit == 1)
       {
         $brutequit = 0;
         last;
       }
     }

     ##if the percent has changed, then update the GUI.##
     if($currentpercent < $percent)
     {
       $permutesvar = "tests run: $percentcount";
       $currentpercent = $percent;
       $progresscount = $currentpercent;
       $percentdisp = "$percent%";
       Tkx::update();
     }
  }

  ##re-enable the buttom at the end of the subroutine.##
  $brutebutton->state('!disabled');

  ##get the distance of the shrotest path.##
  my $tempsum = pop @shortperm;

  ##print the distance of the shortest path and the path to the text display.##
  $textdisplay->insert_end("Shortest Path: @shortperm at a distance of $tempsum\n");
  $textdisplay->see('end');

  return 1;
}

############################################################################################################################
#     
#     build_network
#     
############################################################################################################################
#
# (#) DESCRIPTION:
#     This subroutine will build the network that is to eb analyzed. 
#
# (#) ABSTRACT:
#     The Subroutine will keep track of progress and build a netowrk of city objects that contain random distances
#     to other city objects.     
#
# (#) LIMITATIONS:
#     None.
#
############################################################################################################################
#
#     returns 1 on completion
#
############################################################################################################################
sub build_network
{
  my $progressbar = shift;
  
  $buildbutton->state('disabled');
  
  ##get the number of cities inputed into the widget by the user.##
  $num_cities = ($numberentry->get() - 1);

  ##intitialize the variables.##
  my $networkpercent = 0;
  my $currentpercent = 0;
  my $percent = 0;
  my $timer = time;

  ##intialize the progress bar.##
  $progressbar->configure(-variable => \$currentpercent);

  ##calculate the total tests that will be completed.##
  my $totaltests = 2 * ($num_cities*$num_cities);
  
  ##create the network object.##
  $mynetwork = Network->new();
  
  ##notify user that cities are being added to the network.##
  $textdisplay->insert_end("Adding cities.\n");
  $textdisplay->see('end');

  ##add the new cities.##
  for my $count (0..$num_cities)
  {
    ##every so often update the user of a certain amount of that have been added.##
    if($count % $ADD_CITY_COUNT == 0 && $count > 0)
    {
      $textdisplay->insert_end("$count cities added.\n");
      $textdisplay->see('end');
    }

    ##update the GUI.##
    Tkx::update();

    ##add a city.##
    $mynetwork->add_node();

    ##update the percent, because adding a new city gets time consuming with large networks the counter##
    ##networkpercent is increased by how many cities are in the network to offset the slowdown.       ##
    $networkpercent = $networkpercent + $num_cities;
    $percent = int(($networkpercent/$totaltests)*$PERCENT_VALUE);

    ##update the time widgets.##
   
    ##intialize the time variables.##
    my $temptime = time() - $timer;
    my $tempprog = $networkpercent/$totaltests;
    my $tempsec = (($temptime/$tempprog) - $temptime);
    my $temptotal = ($temptime/$tempprog);
 
    ##calculate the time values to be inserted into the widgets.##
    timecalc(\$etavar, $tempsec, 'Time Left:');
    timecalc(\$totaltime, $temptotal, 'Total Time:');
    timecalc(\$timeelap, $temptime, 'Time Elasped:');  

    ##if the percent has changed, update the progress bar and gui.##
    if($currentpercent < $percent)
    {
      $currentpercent = $percent;
      $progresscount = $currentpercent;
      $percentdisp = "$percent%";
      $permutesvar = "tests run: $networkpercent";
      Tkx::update();
    }
  }

  ##print out when all the cities have been added
  $textdisplay->insert_end("$num_cities cities have been added.\n");
  $textdisplay->see('end');
  Tkx::update();

  #now we are going to print out all the distances
  #first lets get the city nodes
  my $node_ref = $mynetwork->get_nodes();
  my @nodearray = @{$node_ref};

  $textdisplay->insert_end("\n\n");

  for my $count (0..$mynetwork->get_total() - 1)
  {
    #get the starting city
    my $city = $nodearray[$count];
    my $cityname = $city->get_number();

    #print out the current city we are about to list distances for
    $textdisplay->insert_end("City $cityname:\n");

    #get a list of all the distance of the other cities to the currentcity
    my $array_ref = $city->get_others();
    my @othercities = @{$array_ref};

    #now print out each distance to each other city
    for my $count2 (0..$mynetwork->get_total() - 1)
    {
      #keep track of the progress
      $networkpercent++;
      $percent = int(($networkpercent/$totaltests)*$PERCENT_VALUE);
      
      #print out the distance
      my $distance = $othercities[$count2];
      $textdisplay->insert_end("Distance to city $count2 = $distance.\n");
      $textdisplay->see('end');
   
      #update time variables
      if($networkpercent % $PERCENT_VALUE == 0)
      {
        my $temptime = time() - $timer;
        my $tempprog = $networkpercent/$totaltests;
        my $tempsec = (($temptime/$tempprog) - $temptime);
        my $temptotal = ($temptime/$tempprog);

        timecalc(\$etavar, $tempsec, 'Time Left:');
        timecalc(\$totaltime, $temptotal, 'Total Time:');
        timecalc(\$timeelap, $temptime, 'Time Elasped:');
        
         Tkx::update();
      }

      #update progress bar
      if($currentpercent < $percent)
      {
        $currentpercent = $percent;
        $progresscount = $currentpercent;
        $percentdisp = "$percent%";
        $permutesvar = "tests run: $networkpercent";
        Tkx::update();
      }
    }
  }
  #print network built message
  $textdisplay->insert_end("City mappings created randomly.\nNetwork has been successfully built.\n");
  $textdisplay->see('end');

  Tkx::update();

  ##re-enable the buttons.##
  $nnbutton->state('!disabled');
  $optbutton->state('!disabled');
  $brutebutton->state('!disabled');
  $buildbutton->state('!disabled');

  return 1;
}


