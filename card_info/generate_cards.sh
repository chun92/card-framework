#!/bin/bash

# card info
suits=("spade" "heart" "diamond" "club")
values=("2" "3" "4" "5" "6" "7" "8" "9" "10" "J" "Q" "K" "A")

# create json files
for suit in "${suits[@]}"; do
    for value in "${values[@]}"; do
        card_name="${suit}_${value}"
        file_name="${card_name}.json"
        front_image="card${suit^}s${value}.png"
        cat <<EOF > "$file_name"
{
    "name": "${card_name}",
    "front_image": "${front_image}",
    "suit": "${suit}",
    "value": "${value}"
}
EOF
    done
done

echo "Card JSON files generated."