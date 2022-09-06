#!/usr/bin/python

from PIL import Image

file = open("sim/lcd.mem", "r")
lines = file.readlines()

rawimg = []
pal = [  0,   0,   0,
         0,   0, 127,
       127,   0,   0,
       127,   0, 127,
         0, 127,   0,
         0, 127, 127,
       127, 127,   0,
       127, 127, 127,
         0,   0,   0,
         0,   0, 255,
       255,   0,   0,
       255,   0, 255,
         0, 255,   0,
         0, 255, 255,
       255, 255,   0,
       255, 255, 255,
]

for line in lines:
    if line.startswith('//') == 0:
        for i in range(0, 4):
            if (line[i] != "X"):
                rawimg.append(int(line[i], 16))
            else:
                rawimg.append(0)

img = Image.frombuffer("P", (640, 480), bytes(rawimg), 'raw', "P", 0, 1)
img.putpalette(pal)
img = img.resize((1920, 1080))
img.save("sim/screen.png")

