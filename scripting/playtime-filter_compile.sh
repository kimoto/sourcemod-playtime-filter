#!/bin/sh

set -x

rm ./compiled/playtime-filter.smx;
#yes | ./compile.exe ./playtime-filter.sp ./include/playtime-filter.inc ./include/playtime-filter_async.inc; cp ./compiled/playtime-filter.smx ../plugins 
yes | ./compile.exe ./playtime-filter.sp; cp ./compiled/playtime-filter.smx ../plugins 

