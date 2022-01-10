#!/bin/bash
old_version=$1
new_version=$2

ggrep -niR "$old_version" 2>/dev/null | cut -d : -f1 | uniq| while read -r file; do 
    gsed -i "s/$old_version/$new_version/g" "$file"; 
done
