#!/usr/bin/python3
  
for width in range(0,17):
  for pos in range(0,17-width):
    #print("pos ",pos," width ",width)
    print("  dc.w %"+"0"*pos+"1"*width+"0"*(16-pos-width))
    if width == 0:
      break
print(";---------")
for pos in range(0,17):
  for width in range(0,17-pos):
    #print("pos ",pos," width ",width)
    print("  dc.w %"+"0"*pos+"1"*width+"0"*(16-pos-width))
    if pos== 0:
      break

print("startpattern:")
for width in range(16,0,-1):
  pos=16-width
  print("  dc.w %"+"0"*pos+"1"*width+"0"*(16-pos-width))
print("endpattern:")
for width in range(1,17):
  pos=0
  print("  dc.w %"+"0"*pos+"1"*width+"0"*(16-pos-width))
