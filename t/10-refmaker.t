use strict;
use warnings;
use Test::More tests => 63;
use Cwd qw/abs_path getcwd/;
use File::Temp qw/tempdir/;
use File::Slurp;
use Digest::MD5;
use JSON;

use npg_tracking::util::build qw/git_tag/;


# test the Ref_Maker script by building references for E coli
# confirm md5 checksum of expected output files

SKIP: {
  skip 'Third party bioinformatics tools required. Set TOOLS_INSTALLED to true to run.', 63 unless ($ENV{'TOOLS_INSTALLED'});
my $startDir = getcwd();
my $fastaMaster = abs_path('t/data/references/E_coli/K12/fasta/E-coli-K12.fa');
unless (-e $fastaMaster) {
    die "Cannot find FASTA master file $fastaMaster\n";
}
my $tmp = tempdir('Ref_Maker_test_XXXXXX', CLEANUP => 0, DIR => '/tmp' );
print "Created temporary directory: ".abs_path($tmp)."\n";
my $tmpFasta = $tmp."/fasta";
mkdir($tmpFasta);
system("cp $fastaMaster $tmpFasta");
local $ENV{'PATH'} = join q[:], join(q[/], $startDir, 'scripts'), $ENV{'PATH'};

chdir($tmp);

diag $ENV{'PWD'} . "  Before refmaker according to env";
diag getcwd() . "  Before refmaker according to perl";
is(system("cd $tmp && $startDir/bin/Ref_Maker"), 0, 'Ref_Maker exit status');

diag $ENV{'PWD'} . "  After refmaker according to env";
diag getcwd() . "  After refmaker according to perl";
# can't use checksum on Picard .dict, as it contains full path to fasta file
my $picard = "$tmp/picard/E-coli-K12.fa.dict";
ok(-e $picard, "Picard .dict file exists");

ok(-e "$tmp/smalt/E-coli-K12.fa.sma", 'Smalt .sma file exists');

# now verify md5 checksum for all other files
my %expectedMD5 = (
    "$tmp/bowtie/E-coli-K12.fa.1.ebwt" => '3c990c336037da8dcd5b1e7794c3d9de',
    "$tmp/bowtie/E-coli-K12.fa.2.ebwt" => 'de2a7524129643b72c0b9c12289c0ec2',
    "$tmp/bowtie/E-coli-K12.fa.3.ebwt" => 'be250db6550b5e06c6d7c36beeb11707',
    "$tmp/bowtie/E-coli-K12.fa.4.ebwt" => 'b5a28fd5c0e83d467e6eadb971b3a913',
    "$tmp/bowtie/E-coli-K12.fa.rev.1.ebwt" => '65c083971ad3b8a8c0324b80c4398c3c',
    "$tmp/bowtie/E-coli-K12.fa.rev.2.ebwt" => 'cead6529b4534fd0e0faf09d69ff8661',
    "$tmp/bowtie2/E-coli-K12.fa.1.bt2" => '757da19e3e1425b223004881d61efa48',
    "$tmp/bowtie2/E-coli-K12.fa.2.bt2" => 'aa8c2b1e74071eb0296fc832e33f5094',
    "$tmp/bowtie2/E-coli-K12.fa.3.bt2" => 'be250db6550b5e06c6d7c36beeb11707',
    "$tmp/bowtie2/E-coli-K12.fa.4.bt2" => 'b5a28fd5c0e83d467e6eadb971b3a913',
    "$tmp/bowtie2/E-coli-K12.fa.rev.1.bt2" => '8c9502dfff924d4dac0b33df0d20b07e',
    "$tmp/bowtie2/E-coli-K12.fa.rev.2.bt2" => '5a3d15836114aa132267808e4b281066',
    "$tmp/bwa/E-coli-K12.fa.amb" => 'fd2be0b3b8f7e2702450a3c9dc1a5d93',
    "$tmp/bwa/E-coli-K12.fa.ann" => '84365967cebedbee51467604ae27a1f9',
    "$tmp/bwa/E-coli-K12.fa.bwt" => '08006d510fa01d61a2ae4e3274f9a031',
    "$tmp/bwa/E-coli-K12.fa.pac" => 'ca740caf5ee4feff8a77d456ad349c23',
    "$tmp/bwa/E-coli-K12.fa.rbwt" => 'd164645e1a53de56145e7d167b554cf3',
    "$tmp/bwa/E-coli-K12.fa.rpac" => '19897ea393ad8f7439ad3242dc0ce480',
    "$tmp/bwa/E-coli-K12.fa.rsa" => '70128b51beecb212e442d758bb005db7',
    "$tmp/bwa/E-coli-K12.fa.sa" => 'f4a3e35b8e2567dc4f6d90df42c1739b',
    "$tmp/bwa0_6/E-coli-K12.fa.amb" => 'fd2be0b3b8f7e2702450a3c9dc1a5d93',
    "$tmp/bwa0_6/E-coli-K12.fa.ann" => '84365967cebedbee51467604ae27a1f9',
    "$tmp/bwa0_6/E-coli-K12.fa.bwt" => '09f551b8f730df82221bcb6ed8eea724',
    "$tmp/bwa0_6/E-coli-K12.fa.pac" => 'ca740caf5ee4feff8a77d456ad349c23',
    "$tmp/bwa0_6/E-coli-K12.fa.sa" => '6e5b71027ce8766ce5e2eea08d1da0ec',
    "$tmp/fasta/E-coli-K12.fa" => '7285062348a4cb07a23fcd3b44ffcf5d',
    "$tmp/fasta/E-coli-K12.fa.fai" => '3bfb02378761ec6fe2b57e7dc99bd2b5',
    "$tmp/samtools/E-coli-K12.fa.fai" => '3bfb02378761ec6fe2b57e7dc99bd2b5',
    "$tmp/smalt/E-coli-K12.fa.smi" => 'aa85b6852d707d45b90edf714715ee6b',
    );

ok (-e "$tmp/npgqc/E-coli-K12.fa.json", 'json file exists');

my $json_hash = {'reference_path'=>"$tmp/fasta/E-coli-K12.fa",'_summary'=>{'ref_length'=>4639675,'counts'=>{'A'=>1142228,'T'=>1140970,'C'=>1179554,'G'=>1176923}}};
my $json = from_json(read_file("$tmp/npgqc/E-coli-K12.fa.json"));
delete $json->{__CLASS__};
is_deeply($json,$json_hash,'Compare the JSON file');

chdir($startDir);
foreach my $path (keys %expectedMD5) {
    my $file = join q[/], $tmp, $path;
    ok(-e $file, "file $file exists");
    open my $fh, "<", $file || die "Cannot open $file for reading";
    is(Digest::MD5->new->addfile($fh)->hexdigest, $expectedMD5{$path}, 
       "$path MD5 checksum");
    close $fh;
}
} # end SKIP no tool installed
1;
