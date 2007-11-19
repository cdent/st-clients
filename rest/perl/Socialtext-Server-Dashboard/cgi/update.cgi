#!/bin/sh
echo "Content-Type: text/plain"
echo
echo "Updating the dashboard"

/usr/bin/st-create-server-dashboard 2>&1

