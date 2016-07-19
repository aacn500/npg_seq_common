#!/bin/bash

# This script was adapted from work by Keith James (keithj). The original source
# can be found as part of the wtsi-npg/data_handling project here:
#
#   https://github.com/wtsi-npg/data_handling

set -e -x

sudo apt-get install libgd2-xpm-dev # For npg_tracking
sudo apt-get install liblzma-dev # For npg_qc
sudo apt-get install --yes nodejs

pushd /tmp

# illumina2bam
export ILLUMINA2BAM_VERSION="1.19"
wget https://github.com/wtsi-npg/illumina2bam/releases/download/V${ILLUMINA2BAM_VERSION}/Illumina2bam-tools-V${ILLUMINA2BAM_VERSION}.zip
unzip Illumina2bam-tools-V${ILLUMINA2BAM_VERSION}.zip
export CLASSPATH=/tmp/Illumina2bam-tools-V${ILLUMINA2BAM_VERSION}:$CLASSPATH


### Install third party tools ###
# bwa
sudo apt-get install bwa

sudo apt-get install samtools
# samtools with cram
#git clone --branch develop --depth 1 https://github.com/samtools/htslib.git
#pushd htslib
#make
#sudo make install
#popd
#git clone --branch develop --depth 1 https://github.com/jkbonfield/samtools.git
#git clone --depth 1 git://git.savannah.gnu.org/autoconf-archive.git
#pushd autoconf-archive
#wget https://github.com/samtools/samtools/files/62424/ax_with_htslib.m4.txt
#mv ax_with_htslib.m4.txt ax_with_htslib.m4
#popd
#pushd samtools
#aclocal -I ../autoconf-archive/m4
#autoconf
#./configure
#make
#sudo make install
#popd


# samtools_irods
git clone --depth 1 https://github.com/wtsi-npg/samtools.git samtools_irods
pushd samtools_irods
aclocal -I ../autoconf-archive/m4
autoconf
./configure
make
sudo make install
popd


# picard
export PICARD_VERSION="2.5.0" #https://github.com/broadinstitute/picard/releases
# still in /tmp
wget https://github.com/broadinstitute/picard/releases/download/${PICARD_VERSION}/picard-tools-${PICARD_VERSION}.zip
unzip picard-tools-${PICARD_VERSION}.zip
export CLASSPATH=/tmp/picard-tools-${PICARD_VERSION}:$CLASSPATH

#biobambam
# still in /tmp
git clone https://github.com/gt1/libmaus.git
pushd libmaus
autoreconf -i -f
./configure
make
popd

git clone https://github.com/gt1/biobambam.git
pushd biobambam
autoreconf -i -f
./configure --with-libmaus=../libmaus --prefix=${HOME}/biobambam
sudo make install
popd

popd

export TOOLS_INSTALLED=true
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
