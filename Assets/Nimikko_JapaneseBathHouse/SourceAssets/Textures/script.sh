 for i in *Occlusion*.png; do 
    echo "$i"
    magick "$i" -write MPR:orig -channel B -separate -write newR.png    \
    \( MPR:orig -channel R -separate                    -write newG.png \) \
    \( MPR:orig -channel R -separate -threshold 100%    -write newB.png \) \
    \( MPR:orig -channel G -separate -negate            -write newA.png \) \
    -combine PNG32:"$i"
 done
