#!/bin/bash

TEMP_DIR="/tmp"
DAYS=7

find $TEMP_DIR -type f -mtime +$DAYS -exec rm -f {} \;
find $TEMP_DIR -type d -empty -delete