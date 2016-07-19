#!/bin/bash

# This script was adapted from work by Keith James (keithj). The original source
# can be found as part of the wtsi-npg/data_handling project here:
#
#   https://github.com/wtsi-npg/data_handling


set -e -x

unset PERL5LIB

cpanm --notest --installdeps . || find /home/travis/.cpanm/work -cmin -1 -name '*.log' -exec tail -n20  {} \;
perl Build.PL
./Build

./Build test --verbose
