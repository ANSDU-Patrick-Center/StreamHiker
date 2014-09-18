StreamHiker
============
Authors:
Jerry Mead, Alexander M. Waldman
====================

StreamHiker is a program for facilitating watershed analysis at the "reach" scale.

Taking user-provided input files (stream link raster and flow direction raster) and specified target reach length, the program first splits the stream link raster into segments of targeted lengths, each with a unique reach ID, then develops a "lateral" drainage raster map of the coverage area with each cell having a reach ID value for the stream reach it laterally drains to.

Finally, the program calculates network flow characteristics for use in aggregating data at the network scale (i.e. reach length, flow from, flow to, upstream junction reach ids and aggregation order).

Please see the wikipage which details issues and next steps!

For more information, plesae contact Alex Waldman: amw47@drexel.edu
