#!/bin/bash

curl -H "Content-Type: application/json" -X POST https://hooks.slack.com/services/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 -d @<(cat <<EOI
{
    "channel"    : "#monitoring",
    "username"   : "cartalk-{{ release_stage }}",
    "icon_emoji" : ":car:",
    "text"       : "[$MONIT_SERVICE] - $MONIT_DESCRIPTION"
}

EOI
)
