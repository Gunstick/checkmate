# Idea
The concept is to use the STE line duplication feature to not need to calculate unchanging lines.
The CPU usage can mostly be modulated by how large the smallest checkerboard is.

The aim is to reach 15 layers (each color available) plus the background.

Of course in fullscreen, because it's ULM

# Single line generation
The basic routine will be needed to draw dashed lines in 15 colors one over the other where one
can specify the start and width of the dashes.

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
Supposing one can generate 20 different scanlines per VBL, then the smallest square would be around 273/20=13.65 pixels

Or to be able to draw the smallest square as 8 pixel wide, we need to be able to generate 273/8 = 34.125 scanlines/VBL

This means the final CPU usage will determine the smallest checkerboard size.

# Use c2p?
In here you can see that a pixel precise C2P needs 16 cycles per pixel
https://github.com/spkrsmfx/c2pdev_public/blob/master/c2p.s#L576
That costs 6528 cycles for a 408 pixel overscan (STE specific as described here 
https://dhs.nu/misc.php?t=special&feature=overscan )

So doing only C2P an nothing else, we can at max convert 160000/6528 = 24 lines

So the smallest possible checkerboard would be 12 pixels wide.

Plus add CPU time for overscan and generating the patterns into chunky buffer. 
Not a comfortable margin.

# Use blitter to draw horizontal lines?
https://www.atari-forum.com/viewtopic.php?t=27153

# use this technique
https://github.com/spkrsmfx/juxtaposition_public
which calculates first all possible masks for the line start/ends/mixes and their positions
and then draws them to screen

# clear screen, draw easy colors first
1st layer is plane 0, 2nd layer plane 1, 3rd is 2, 4th is 3
Don't overdraw, else it will make other colors. so needs to be masked all the way down.
Advantage: drawing the big 1st layer only on plane0 avoids writing zero words onto already zero words
5th is plane 0+1, 6th is plane 0+2, 7th = 0+3, 8=1+2, 9=1+3, 10=2+3
11th is 0+1+2, 12th = 0+1+3, 13=0+2+3, 14=1+2+3, 15=0+1+2+3 
(0th layer is background which is no planes)

# Nice to have section
- some or all color changeable per line (background rasters, rasters per layer)
- STE horizontal distorter, STE vertically wavy screen
- digisound instead of chiptune
- music with timer effect (SID) but that's really a headache.
- scrolline (overlay, no checkerboard there)
- if losta CPU left: generate some part without STE duplication, so be able to place static objects there. (then only 8 layers)

