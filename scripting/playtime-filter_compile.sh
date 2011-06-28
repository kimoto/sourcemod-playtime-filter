#!/bin/sh

set -x

rm ./compiled/playtime-filter.smx;
yes | ./compile.exe ./include/playtime-filter.inc ./playtime-filter.sp; cp ./compiled/playtime-filter.smx ../plugins 

