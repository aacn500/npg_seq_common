#!/bin/bash

# This file was adapted from work by Keith James (keithj) and Jaime Tovar Corona
# (jmtc). The original source can be found as part of the wtsi-npg/data_handling
# and wtsi-npg/qc projects here:
#
#   https://github.com/wtsi-npg/data_handling
#   https://github.com/wtsi-npg/npg_qc


set -e -x

sudo apt-get install libgd2-xpm-dev # For npg_tracking
sudo apt-get install liblzma-dev # For npg_qc


### Install third party tools ###

pushd /tmp

# bwa

sudo apt-get install bwa
#git clone --branch 0.5.10-mt_fixes.2 --depth 1 https://github.com/wtsi-npg/bwa.git bwa
#pushd bwa
#make
#popd

# htslib/samtools

wget -q https://github.com/samtools/htslib/releases/download/${HTSLIB_VERSION}/htslib-${HTSLIB_VERSION}.tar.bz2 -O /tmp/htslib-${HTSLIB_VERSION}.tar.bz2
tar xfj /tmp/htslib-${HTSLIB_VERSION}.tar.bz2 -C /tmp
pushd /tmp/htslib-${HTSLIB_VERSION}
./configure --enable-plugins
make
popd

wget -q https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2 -O /tmp/samtools-${SAMTOOLS_VERSION}.tar.bz2
tar xfj /tmp/samtools-${SAMTOOLS_VERSION}.tar.bz2 -C /tmp
pushd /tmp/samtools-${SAMTOOLS_VERSION}
./configure --enable-plugins --with-plugin-path=/tmp/htslib-${HTSLIB_VERSION}
make all plugins-htslib
sudo make install
popd


# illumina2bam
# wget https://github.com/wtsi-npg/illumina2bam/releases/download/V${ILLUMINA2BAM_VERSION}/Illumina2bam-tools-V${ILLUMINA2BAM_VERSION}.zip
# unzip Illumina2bam-tools-V${ILLUMINA2BAM_VERSION}.zip

git clone --branch V${ILLUMINA2BAM_VERSION} --depth 1 https://github.com/wtsi-npg/illumina2bam.git illumina2bam
pushd illumina2bam
ant -lib lib/bcel jar
popd


# picard
#wget https://github.com/broadinstitute/picard/releases/download/${PICARD_VERSION}/picard-tools-${PICARD_VERSION}.zip
#unzip picard-tools-${PICARD_VERSION}.zip
wget https://sourceforge.net/projects/picard/files/picard-tools/${PICARD_VERSION}/picard-tools-${PICARD_VERSION}.zip/download -O picard-tools-${PICARD_VERSION}.zip
unzip picard-tools-${PICARD_VERSION}.zip

# libmaus/biobambam
# git clone --branch ${LIBMAUS_VERSION} --depth 1 https://github.com/gt1/libmaus.git libmaus
# pushd libmaus
# autoreconf -i -f
# ./configure
# make
# sudo make install
# popd

# git clone --branch ${BIOBAMBAM_VERSION} --depth 1 https://github.com/gt1/biobambam.git biobambam
# pushd biobambam
# autoreconf -i -f
# ./configure
# make
# sudo make install
# popd

popd

# Third party tools install done

# CPAN as in npg_npg_deploy
cpanm --notest --reinstall App::cpanminus
cpanm --quiet --notest --reinstall ExtUtils::ParseXS
cpanm --quiet --notest --reinstall MooseX::Role::Parameterized
cpanm --quiet --notest Alien::Tidyp
cpanm --no-lwp --notest https://github.com/wtsi-npg/perl-dnap-utilities/releases/download/${DNAP_UTILITIES_VERSION}/WTSI-DNAP-Utilities-${DNAP_UTILITIES_VERSION}.tar.gz

# WTSI NPG Perl repo dependencies
cd /tmp
git clone --branch devel --depth 1 https://github.com/wtsi-npg/ml_warehouse.git ml_warehouse.git
git clone --branch devel --depth 1 https://github.com/wtsi-npg/npg_tracking.git npg_tracking.git
git clone --branch devel --depth 1 https://github.com/wtsi-npg/npg_seq_common.git npg_seq_common.git
git clone --branch devel --depth 1 https://github.com/wtsi-npg/npg_qc.git npg_qc.git


repos="/tmp/ml_warehouse.git /tmp/npg_tracking.git /tmp/npg_seq_common.git /tmp/npg_qc.git"

for repo in $repos
do
  cd "$repo"
  cpanm --quiet --notest --installdeps . || find /home/travis/.cpanm/work -cmin -1 -name '*.log' -exec tail -n20  {} \;
  perl Build.PL
  ./Build
  ./Build install
done

cd "$TRAVIS_BUILD_DIR"
