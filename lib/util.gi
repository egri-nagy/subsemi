################################################################################
##
## SubSemi
##
## Util functions
##
## Copyright (C) 2013  Attila Egri-Nagy
##

#time related #should go to SGPDEC!
InstallGlobalFunction(TimeInSeconds,
        function() return IO_gettimeofday().tv_sec; end);

#this does not work TODO
InstallGlobalFunction(RandomizeBySystemClock,
function()
  Reset(GlobalMersenneTwister, TimeInSeconds);
  Print("#Random seed:", State(GlobalMersenneTwister), "\n");
end);
