#!/bin/bash
########################################################################
# Version: 0.3
# License: AGPL-3.0 (https://choosealicense.com/licenses/agpl-3.0/)
########################################################################
{
MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized
ME="${0##*/}"

INDEX="$1"
[[ ! $INDEX ]] && echo "Please provide path to source TW index.html" && exit 1
[[ ! -f $INDEX ]] && echo "Fichier TW absent. $INDEX" && exit 1

WISHKEY="$2"
[[ ! $WISHKEY ]] && echo "Please provide IPFS publish key" && exit 1
WNS=$(ipfs key list -l | grep -w $WISHKEY | cut -d ' ' -f1)

# Extract tag=tube from TW
tiddlywiki --verbose --load ${INDEX} --output ~/.zen/tmp --render '.' 'tiddlers.json' 'text/plain' '$:/core/templates/exporters/JsonFile' 'exportFilter' '[tag[tube]]'

## Extract URL from text field
for yurl in $(cat -r /home/fred/.zen/tmp/tiddlers.json | jq '.[].text' | grep 'http'); do
        echo "Detected $yurl"
        echo "Start Downloading"

        rm -Rf ~/.zen/tmp/tube
        mkdir -p ~/.zen/tmp/tube

        yt-dlp -f "[height=480]/best" --no-mtime --embed-thumbnail --add-metadata -o ~/.zen/tmp/tube/%(title)s.%(ext)s ${yurl}
        FILE=$(ls ~/.zen/tmp/tube/)

        echo "~/.zen/tmp/tube/$FILE downloaded"

        echo "Adding to IPFS"
        ILINK=$(ipfs add -q ~/.zen/tmp/tube/$FILE | tail -n 1)
        echo "/ipfs/$ILINK ready"


        MIME=$(file --mime-type ~/.zen/tmp/tube/$FILE | cut -d ' ' -f 2)
        echo "MIME TYPE : $MIME"

        echo "Creating Youtube tiddler"

        echo '[
  {
    "title": "'$FILE'",
    "type": "'$MIME'",
    "text": "''",
    "tags": "'$:/isAttachment $:/isEmbedded ipfs youtube'",
    "_canonical_uri": "'/ipfs/${ILINK}'"
  }
]
' > ~/.zen/tmp/tube/tube.json

        echo
        echo "Adding tiddler to TW"

        rm -f ~/.zen/tmp/newindex.html
        tiddlywiki --verbose --load $INDEX \
                        --import ~/.zen/tmp/tube/tube.json "application/json" \
                        --output ~/.zen/tmp --render "$:/core/save/all" "newindex.html" "text/plain"

        if [[ -s ~/.zen/tmp/newindex.html ]]; then

            echo "Updating $INDEX"
            cp ~/.zen/tmp/newindex.html $INDEX

            echo "ipfs name publish -k $WISHKEY"
            ILINK=$(ipfs add -q $INDEX | tail -n 1)
            ipfs name publish -k $WISHKEY /ipfs/$ILINK
            echo "/ipfs/$ILINK"


        fi

done

# Removing tag=tube
--deletetiddlers '[tag[tube]]'

}
