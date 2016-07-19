#!/bin/bash

set -e -x

unset PERL5LIB

export PATH=/home/travis/.nvm/versions/node/v${TRAVIS_NODE_VERSION}/bin:$PATH

# This install already happens in install.sh
#cpanm --notest --installdeps . || find /home/travis/.cpanm/work -cmin -1 -name '*.log' -exec tail -n20  {} \;
#perl Build.PL
#./Build

./Build test --verbose
