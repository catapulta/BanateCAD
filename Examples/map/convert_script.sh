#!/bin/sh
set -e
cd Examples/map

echo "download color map from NASA"
# curl https://svs.gsfc.nasa.gov/vis/a000000/a004700/a004720/lroc_color_poles.tif -o lroc_color_poles.tif
# alternatively pay for
# https://cubebrush.co/tuomaskankola/products/5usnya/92k-moon-color-map

echo "download bump map from NASA"
# curl https://svs.gsfc.nasa.gov/vis/a000000/a004700/a004720/ldem_64_uint.tif -o ldem_64_uint.tif


echo "shrink color map"
# convert lroc_color_poles.tif -sample 8000x4000 -normalize -type grayscale moonColorMap.8k.png
# convert Earth_21k_Nightlights_v001.tif -sample 8000x4000 -normalize -type grayscale -gaussian-blur 50x6 earthColorMap-blur.8k.png
# small polka
# convert Earth_8k_Nightlights_v001.tif -sample 8000x4000 -type grayscale -black-threshold 10% -modulate 100 -morphology Dilate 'Disk:3' -morphology Dilate 'Disk:2' -normalize earthColorMap.8k.png
# big polka
# convert Earth_8k_Nightlights_v001.tif -sample 8000x4000 -type grayscale -black-threshold 40% -modulate 100 -morphology Dilate 'Disk:12' -normalize earthColorMap.8k.png
# milk
convert Earth_8k_Nightlights_v001.tif -sample 8000x4000 -type grayscale -black-threshold 1% -modulate 1000 -normalize -morphology Dilate 'Disk:2' earthColorMap.8k.png
# convert Earth_21k_Nightlights_v001.tif -sample 4800x2400 -negate -normalize -type grayscale earthColorMap.8k.png
# convert lroc_color_poles.tif -sample 4800x2400 -normalize -type grayscale moonColorMap.4.8k.png
# convert lroc_color_poles.tif -sample 3840x1920 -normalize -type grayscale moonColorMap.3.84k.png
# convert lroc_color_poles.tif -sample 3600x1800 -normalize -type grayscale moonColorMap.3.6k.png

echo "shrink bump map"
# convert ldem_64_uint.tif -sample 8000x4000 -normalize -type grayscale moonBumpMap.8k.png
# convert ldem_64_uint.tif -sample 4800x2400 -normalize -type grayscale moonBumpMap.4.8k.png
# convert ldem_64_uint.tif -sample 3840x1920 -normalize -type grayscale moonBumpMap.3.84k.png
# convert ldem_64_uint.tif -sample 3600x1800 -normalize -type grayscale moonBumpMap.3.6k.png
# convert -size 8000x4000 -depth 16 xc:black flat.8k.png
convert Earth_8k_Disp_v001.tif -sample 8000x4000 -type grayscale -normalize earthBumpMap.8k.png

# add lights to surface for increased definiton (surface quality suffers though)
# convert \( earth_spec.tif -normalize -negate +level 0,25% -sample 8000x4000 \) \
#         \( earthColorMap.8k.png -negate +level 0,10% \) \
#         \( earthBumpMap.8k.png +level 0,65% \) \
#         -background black -compose plus -layers flatten -normalize earthBumpAddInvertedColorMap.8k.png

# combine with continental borders
convert \( earth_spec.tif -normalize -negate +level 0,20% -sample 8000x4000 \) \
        \( earthBumpMap.8k.png +level 0,80% \) \
        -background black -compose plus -layers flatten -normalize earthBumpAddInvertedColorMap.8k.png

# add "lightening" (ie white only) gaussian blur
# convert earthColorMap.8k.png \( +clone -define convolve:scale='1.0' -morphology Convolve Gaussian:0x4 \) -compose Lighten -composite -normalize earthColorMap.8k.png
convert earthColorMap.8k.png \( +clone -define convolve:scale='1.1' -morphology Convolve Gaussian:0x5 \) -compose Lighten -composite -normalize earthColorMap.8k.png

# # get rid of super thin areas
# # convert \( earthBumpAddInvertedColorMap.8k.png +level 0,50% \)  \( earthColorMap.8k.png +level 0,50% -negate \) -compose plus -flatten -negate -modulate 145 low_and_bright.png
# convert \( earthBumpAddInvertedColorMap.8k.png +level 0,10% \)  \( earthColorMap.8k.png -negate +level 0,10% \) -compose plus -flatten -negate -modulate 145 low_and_bright.png
# convert \( earthBumpAddInvertedColorMap.8k.png \)  \( earthColorMap.8k.png -negate \) -compose plus  -composite output.png
# # create a wall thickness compensator
# # exterior diameter, interior diameter, image width, image height, output filename, inverse multiplier (shouldn't need much tweaking)
# lua wall_depth.lua 218 215.8 4000 8000 wall_thick.png 11
# convert \( wall_thick.png -negate \) low_and_bright.png -compose multiply -flatten wlow_and_bright.png
# # difference subtracts the darker of the two constituent colors from the lighter
# convert \( wlow_and_bright.png -modulate 10 -negate \) earthColorMap.8k.png -compose Darken -composite -normalize earthColorMap.8k.png
# # convert \( wlow_and_bright.png -modulate 90 -negate \) earthColorMap.8k.png -compose multiply -flatten earthColorMap.8k.png

# echo "combine color and bump map"
# convert moonColorMap.8k.png -negate +level 0,50% invertedColorMap.8k.0.5.tif
# convert moonBumpMap.8k.png +level 0,50% moonBumpMap.8k.0.5.tif
# convert invertedColorMap.8k.0.5.tif moonBumpMap.8k.0.5.tif -background black -compose plus -layers flatten -normalize moonBumpAddInvertedColorMap.8k.png
# convert moonColorMap.4.8k.png -negate +level 0,50% invertedColorMap.4.8k.0.5.tif
# convert moonBumpMap.4.8k.png +level 0,50% moonBumpMap.4.8k.0.5.tif
# convert invertedColorMap.4.8k.0.5.tif moonBumpMap.4.8k.0.5.tif -background black -compose plus -layers flatten -normalize moonBumpAddInvertedColorMap.4.8k.png
# convert moonColorMap.3.84k.png -negate +level 0,50% invertedColorMap.3.84k.0.5.tif
# convert moonBumpMap.3.84k.png +level 0,50% moonBumpMap.3.84k.0.5.tif
# convert invertedColorMap.3.84k.0.5.tif moonBumpMap.3.84k.0.5.tif -background black -compose plus -layers flatten -normalize moonBumpAddInvertedColorMap.3.84k.png
# convert moonColorMap.3.6k.png -negate +level 0,50% invertedColorMap.3.6k.0.5.tif
# convert moonBumpMap.3.6k.png +level 0,50% moonBumpMap.3.6k.0.5.tif
# convert invertedColorMap.3.6k.0.5.tif moonBumpMap.3.6k.0.5.tif -background black -compose plus -layers flatten -normalize moonBumpAddInvertedColorMap.3.6k.png
