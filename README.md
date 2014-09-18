### Program Name: StreamHiker

### Authors:

Jerry Mead, Alexander M. Waldman (@Alexander-M-Waldman)

### Program Description:

StreamHiker is a program for facilitating watershed analysis at the "reach" scale.

Taking user-provided input files (stream link raster and flow direction raster) and specified target reach length, the program first splits the stream link raster into segments of targeted lengths, each with a unique reach ID, then develops a "lateral" drainage raster map of the coverage area with each cell having a reach ID value for the stream reach it laterally drains to.

Finally, the program calculates network flow characteristics for use in aggregating data at the network scale (i.e. reach length, flow from, flow to, upstream junction reach ids and aggregation order).

For usage instructions, please see the wikipage (https://github.com/ANSDU-Patrick-Center-for-Env-Research/StreamHiker/wiki) which also details issues and next steps!

For more information, plesae contact Alex Waldman: amw47@drexel.edu

### License Info:

StreamHiker is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  StreamHiker is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with StreamHiker.  If not, see <http://www.gnu.org/licenses/>.
