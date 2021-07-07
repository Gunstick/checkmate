# Idea
The concept is to use the STE line duplication feature to not need to calculate unchanging lines.
The CPU usage can mostly be modulated by how large the snammest checkerboard is.

The aim is to reach 15 layers (each color available) plus the background.

Of course in fullscreen, because it's ULM

# Single line generation
THe basic routine will be needing to draw dashed lines in 15 colors one over the other where one
cans specify the start and width of the dashes.

Slow method is to draw from back to front, so overwriting previous pixels where needed.

Intermediate is to draw from front to back into a chunky buffer. Every pixel which has already
a color is not drawn onto.

Fastest (probably) is to generate a list of all X coordinates, starting with the top layer.
Each layer generates it's coords and only enters them into the list if at that point there is still a hole.
Result is a list of X coords (horizontal segments) with the color to draw.
Data structure? Maybe a double linked list?

# Segmented list generation
1. generate all X coords of all layers, then we obtain variable width columns. This only needs to be done once per VBL
2. for each scanline, determine which colors are seen in which column, eliminating the non needed X coords
3. draw each line into a buffer. By color order or simply left to right (as if it's chunky 2 planar)
4. generate the list of duplicated scanlines for STE 

# CPU time estimation
Supposing one can generate 20 different scanlines per VBL, then the smalles square would be around 273/20=13.65 pixels

Or to be able to draw the smalles square as 8 pixel wide, we need to be able to generate 273/8 = 34.125 scanlines/VBL

This means the final CPU usage will determine the smalles checkerboard size.

# Nice to have section
- some or all color changeable per line (background rasters, rasters per layer)
- STE horizontal distorter, STE vertically wavy screen
- digisound instead of chiptune
- music with timer effect (SID) but that's really a headache.
- scrolline (overlay, no checkerboard there)
- if losta CPU left: generate some part without STE duplication, so be able to place static objects there. (then only 8 layers)

