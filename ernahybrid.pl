#! /usr/bin/perl

# Automated work with RNAhybrid

use File::Basename;
use Statistics::Distributions;
use Getopt::Long;
Getopt::Long::Configure 'gnu_getopt', 'no_auto_abbrev', 'no_ignore_case';

GetOptions(
"help|h" => sub {UsageVersion($_[0])},
"b=i"    => \$HitNumber,
"r"      => \$Restrict,
"d"      => \$DifferentReuslts,
"v"      => \$BeVerbose,
"seed=i" => \$SeedSearch,
) or die $!;

unless (@ARGV) {
print "Data dir not present!\n";
exit 1;
}

my $PNAME = "RNAhybrid enhanced 21";

$WorkDir = shift;
$HitNumber = 5 if $HitNumber eq undef;
$Restrict = 0 if $Restrict eq undef;
$SeedSearch = 0 if $SeedSearch eq undef;
$DifferentReuslts = 0 if $DifferentReuslts eq undef;
$BeVerbose = 0 if $BeVerbose eq undef;
my $Splitter = "\t";
my (@MirFiles, @MirPos, @GeneFiles, @GenePos, @stringst, @stringse,
@stringsp, @stringsm);
my ($gcd, $gp, $mcd, $x1, $x1d, $x2, $x2d, $x2mn, $x2q, $x2qc, $x3, $x4,
$x5, $x5old, $x6, $x6old, $x7s, $x7l, $string, $strings, $delta, $sd, $t, $p, $po,
$pr, $score, $r);
my (%MirInfo, %GeneInfo, %CalculatedGenes);
my %Restrictions = (
  "27" => [70,   5.15],
  "26" => [71,   3.05],
  "25" => [72,   2.16],
  "24" => [73,   1.68],
  "23" => [74,   1.37],
  "22" => [75,   1.16],
  "21" => [76,   1.00],
  "20" => [77,   1.13],
  "19" => [78,   1.27],
  "18" => [80,   1.40],
  "17" => [82.5, 1.53],
  "16" => [85,   1.67]);

print $PNAME, "\n";

opendir(WORK_DIR, $WorkDir);
  @MirFiles = grep {/\.mir/i} readdir(WORK_DIR);
closedir(WORK_DIR);

if ($#MirFiles == -1) {
  print "No miRNAs found!\n";
  exit 1;
}

foreach $x2 (@MirFiles) {
  $x2d = $WorkDir.$x2;
  $strings = "";
  open (MIR_FILE, "<", $x2d) or die "$!";
    while($string = <MIR_FILE>) {
      chomp($string);
        if ($string !~ m/^\>/) {
          $strings .= $string;
        }
        else {
          $string =~ s/^\>//;
          @MirPos = split (/$Splitter/, $string);
#          $mcd = splice @MirPos, 0, 1;
          $MirPos[0] =~ s/\s//g;
        }
      }
    $x6 = $strings =~ tr/ACGTUacgtu//;
    $x6old = $x6 if $x6 > $x6old;
    $MirInfo{$MirPos[0]}->{"Length"} = $x6;
    $MirInfo{$MirPos[0]}->{"GC"} = ($strings =~ tr/GgCc//)/$x6;
    $MirInfo{$MirPos[0]}->{"MRB-code"} = $MirPos[1];
    $MirInfo{$MirPos[0]}->{"Gene-ori"} = $MirPos[2];
    $MirInfo{$MirPos[0]}->{"Chr"} = $MirPos[3];
  close MIR_FILE;
}
$x6 = $x6old if $x6old > $x6;
print $#MirFiles+1, " miRNAs found. Max length: $x6.\n";

opendir(WORK_DIR, $WorkDir);
  @GeneFiles = grep {/\.gene/i} readdir(WORK_DIR);
closedir(WORK_DIR);

if ($#GeneFiles == -1) {
  print "No genes found!\n";
  exit 1;
}

foreach $x1 (@GeneFiles) {
  $x1d = $WorkDir.$x1;
  $strings = "";
  open (GENE_FILE, "<", $x1d) or die "$!";
    while ($string = <GENE_FILE>) {
      chomp($string);
        if ($string !~ m/^\>/) {
          $string =~ s/\W//g;
          $string =~ s/\d//g;
          $strings .= $string;
        }
        else {
          $string =~ s/^\>//;
          @GenePos = split (/ \| /, $string);  #
          $gcd = splice @GenePos, 0, 1;
          $gcd =~ s/\s//g;
#          $GeneInfo{$gcd}->{"Coord"};
          foreach $gp (@GenePos) {
            $gp =~ s/\s//g;
            push (@{${$GeneInfo{$gcd}}{"Coord"}}, split(/-/, $gp));
          }
        }
      }
    $x5 = length($strings);
    $x5old = $x5 if $x5 > $x5old;
    $GeneInfo{$gcd}->{"Length"} = $x5;
    if ($DifferentReuslts > 0) {
      $GeneInfo{$gcd}->{"GC"}->{"5-utr"} = $GeneInfo{$gcd}->{"GC"}->{"cds"} = $GeneInfo{$gcd}->{"GC"}->{"3-utr"} = 0;
      $x7s = substr($strings, ($GeneInfo{$gcd}->{"Coord"}->[0]-1), $GeneInfo{$gcd}->{"Coord"}->[1]);
      $x7l = length($x7s);
      $GeneInfo{$gcd}->{"GC"}->{"5-utr"} = ($x7s=~ tr/GgCc//)/$x7l if $x7l ne 0;
      $x7s = substr($strings, ($GeneInfo{$gcd}->{"Coord"}->[2]-1), ($GeneInfo{$gcd}->{"Coord"}->[3]-($GeneInfo{$gcd}->{"Coord"}->[2]-1)));
      $x7l = length($x7s);
      $GeneInfo{$gcd}->{"GC"}->{"cds"} = ($x7s=~ tr/GgCc//)/$x7l if $x7l ne 0;
      $x7s = substr($strings, ($GeneInfo{$gcd}->{"Coord"}->[4]-1), $GeneInfo{$gcd}->{"Coord"}->[5]);
      $x7l = length($x7s);
      $GeneInfo{$gcd}->{"GC"}->{"3-utr"} = ($x7s=~ tr/GgCc//)/$x7l if $x7l ne 0;
    }
    $GeneInfo{$gcd}->{"GC"}->{"All"} = ($strings =~ tr/GgCc//)/$x5;
  close GENE_FILE;
}
$x5 = $x5old if $x5old > $x5;
print $#GeneFiles+1, " genes found. Max length: $x5.\n";

print "Calculating... ";
if ($Restrict > 0) {
  open (RES_FILE3, ">", $WorkDir."r-table_all_re.txt") or die "$!";
    print RES_FILE3 "\nRestricted results file\nGenes energies\nGene\tmiRNA\tNumber\tPosition\tWhere\tEnergy (kcal/mol)\tP\tScore\tmir-len\tmir-gen\tmir-chr\n";
}
if ($SeedSearch > 0) {
  open (RES_FILE4, ">", $WorkDir."r-results_all_seed.txt") or die "$!";
  print RES_FILE4 "\nGenes with seed more than $SeedSearch\nGene\tmiRNA\tLoops\tNumber\tPosition\tWhere\tEnergy (kcal/mol)\tPicture\n";
}
open (RES_FILE2, ">", $WorkDir."r-table_all.txt") or die "$!";
  print "\n  Calculating miRNAs self-energies...\n" if $BeVerbose > 0;
  print RES_FILE2 "miRNAs energies\nmiRNA\tEnergy (kcal/mol)\tPosition\tLength\tGC content\tGene\tChromosome\n";
  foreach $x2 (@MirFiles) {
    print "    $x2\n" if $BeVerbose > 0;
    $x2d = $WorkDir.$x2;
    $x2q = "";
    open (X2, "<", $x2d) or die "$!";
      while($string = <X2>) {
      chomp($string);
        if ($string !~ m/^\>/) {
          $x2q .= $string;
        }
        else {
          $string =~ s/^\>//;
          @MirPos = split (/$Splitter/, $string);
          $MirPos[0] =~ s/\s//g;
          $x2mn = splice @MirPos, 0, 1;
        }
      }
      $x2qc = NucCompl($x2q, "CR");
    close X2;
    
    $x3 = (open RNAHYBDRID_READ, "RNAhybrid -d -nan,-nan -t $x2d $x2qc |") or die "$!";
      while ($string = <RNAHYBDRID_READ>) {
        if ($string =~ m/^target:/) {
          chomp $string;
          @stringst = split(/\s*:\s*/, $string);
          $string = "";
          $strings = "";
          until ($string =~ m/^miRNA  3'/) {
            if ($string =~ m/^mfe:/) {
              chomp $string;
              @stringse = split(/\s*:\s*/, $string);
              $stringse[1] =~ s/\s*kcal\/mol//;
              $MirInfo{$stringst[1]}->{"nrg"} = $stringse[1];
              $string = "";
            }
            if ($string =~ m/^position/) {
              chomp $string;
              @stringsp = split(/ /, $string);
              $string = "";
            }
            if ($string =~ m/^miRNA :/ || 
                $string =~ m/^length/  ||
                $string =~ m/^p-value/ ||
                $string =~ m/^\n/) {
              $string = "";
            }
              $strings .= $string;
              $string = <RNAHYBDRID_READ>;
            }
            $strings .= $string;
            print RES_FILE2 $stringst[1], "\t", $stringse[1], "\t", $stringsp[-1], "\t",
            $MirInfo{$stringst[1]}->{Length}, "\t", $MirInfo{$stringst[1]}->{GC}, "\t",
            $MirInfo{$stringst[1]}->{"Gene-ori"}, "\t", $MirInfo{$stringst[1]}->{Chr}, "\n";
          }
        }
      close RNAHYBDRID_READ;
  }

print RES_FILE2 "\nGenes information\nGene\tLength\t5-utr\tcoding\t3-utr\tGC-content (all)";
if ($DifferentReuslts > 0) {
  print RES_FILE2 "\tGC-content (5-utr)\tGC-content (cds)\tGC-content (3-utr)";
}
print RES_FILE2 "\n";
foreach (sort keys %GeneInfo) {
  print RES_FILE2 $_, "\t", $GeneInfo{$_}->{"Length"}, "\t",
  $GeneInfo{$_}->{"Coord"}->[0], "-", $GeneInfo{$_}->{"Coord"}->[1], "\t",
  $GeneInfo{$_}->{"Coord"}->[2], "-", $GeneInfo{$_}->{"Coord"}->[3], "\t",
  $GeneInfo{$_}->{"Coord"}->[4], "-", $GeneInfo{$_}->{"Coord"}->[5], "\t",
  $GeneInfo{$_}->{"GC"}->{"All"};
  if ($DifferentReuslts > 0) {
    print RES_FILE2 "\t", $GeneInfo{$_}->{"GC"}->{"5-utr"}, "\t",
    $GeneInfo{$_}->{"GC"}->{"cds"}, "\t", $GeneInfo{$_}->{"GC"}->{"3-utr"};
  }
  print RES_FILE2 "\n";
}
print "  Calculating Gene-miRNA energies...\n" if $BeVerbose > 0;
print RES_FILE2 "\nGenes energies\nGene\tmiRNA\tLoops\tNumber\tPosition\tWhere\tEnergy (kcal/mol)\tDelta energy\tSD\tT\tP\tScore\tmir-len\tp-ori\tmir-gen\tmir-chr\n";
foreach $x1 (@GeneFiles) {
  print "    $x1\n" if $BeVerbose > 0;
  ($x1b, $x1p, $x1e) = fileparse($WorkDir.$x1, '\..*');
  $x1d = $WorkDir.$x1;
  $x1r = $WorkDir."r-results_$x1b.txt";
  open (RES_FILE, ">", $x1r) or die "$!";
  print RES_FILE "\nGene\tmiRNA\tLoops\tNumber\tPosition\tWhere\tEnergy (kcal/mol)\tScore\tPicture\n";
  foreach $x2 (@MirFiles) {
    $x2d = $WorkDir.$x2;
    foreach $x4 ("1+1") { # "0+0", "2+2", "3+3") {
      $num = 0;
      @x4s = split(/\+/, $x4);
      $x3 = (open RNAHYBDRID_READ, "RNAhybrid -d -nan,-nan -b $HitNumber -u $x4s[0] -v $x4s[1] -m $x5 -n $x6 -t $x1d -q $x2d |") or die "$!";
        while ($string = <RNAHYBDRID_READ>) {
          if ($string =~ m/^target:/) {
            $num++;
            chomp $string;
            @stringst = split(/\s*:\s*/, $string);
            $string = "";
            $strings = "";
            until ($string =~ m/^miRNA  3'/) {
              if ($string =~ m/^miRNA :/) {
                chomp $string;
                @stringsm = split(/\s*:\s*/, $string);
                $string = "";
              }
              if ($string =~ m/^mfe:/) {
                chomp $string;
                @stringse = split(/\s*:\s*/, $string);
                $stringse[1] =~ s/\s*kcal\/mol//;
                $string = "";
              }
              if ($string =~ m/^position/) {
                chomp $string;
                @stringsp = split(/ /, $string);
                $strings_pos = $stringsp[-1];
                
                if ($#{$GeneInfo{$stringst[1]}->{"Coord"}} == -1) {
                  $strings_pos .= "\tunknown";
                }
                elsif ($stringsp[-1] <= $GeneInfo{$stringst[1]}->{"Coord"}->[1]) {
                  $strings_pos .= "\t5-utr";
                }
                elsif ($GeneInfo{$stringst[1]}->{"Coord"}->[2] <= $stringsp[-1] &&
                       $stringsp[-1] <= $GeneInfo{$stringst[1]}->{"Coord"}->[3]) {
                  $strings_pos -= ($GeneInfo{$stringst[1]}->{"Coord"}->[2]-1) if $DifferentReuslts > 0;
                  $strings_pos .= "\tcoding";
                }
                elsif ($stringsp[-1] >= $GeneInfo{$stringst[1]}->{"Coord"}->[4]) {
                  $strings_pos -= ($GeneInfo{$stringst[1]}->{"Coord"}->[4]-1) if $DifferentReuslts > 0;
                  $strings_pos .= "\t3-utr";
                  }
                else {
                  $strings_pos .= "\tunknown";
                }
                $string = "";
              }
              if ($string =~ m/^length/ || $string =~ m/^p-value/ || $string =~ m/^\n/) {
                $string = "";
              }
              $strings .= $string;
              $string = <RNAHYBDRID_READ>;
            }
            $strings .= $string;
            
            if ($SeedSearch > 0) {
              if ($strings =~ m/[ACGU]{$SeedSearch}/i) {
                print RES_FILE4 "\n$stringst[1]\t$stringsm[1]\t$x4\t$num\t$strings_pos\t$stringse[1]\t see next line \n$strings\n";
              }
            }

            $delta = $stringse[1]-($MirInfo{$stringsm[1]}->{nrg}/2);
            $sd = 0.031 * $MirInfo{$stringsm[1]}->{nrg};
            $t = $delta/$sd;
            $po = Statistics::Distributions::tprob(4, $t);
            if ($MirInfo{$stringsm[1]}->{Length} <= 21) {
              $p = $po * $Restrictions{$MirInfo{$stringsm[1]}->{Length}}->[1];
            }
            elsif ($MirInfo{$stringsm[1]}->{Length} >= 22) {
              $p = $po / $Restrictions{$MirInfo{$stringsm[1]}->{Length}}->[1];
            }
            $score = 100*($stringse[1]/$MirInfo{$stringsm[1]}->{nrg});

            print RES_FILE "\n$stringst[1]\t$stringsm[1]\t$x4\t$num\t$strings_pos\t$stringse[1]\t$score\t see next line \n$strings\n";

            print RES_FILE2 $stringst[1], "\t", $stringsm[1], "\t", $x4, "\t", $num, 
            "\t", $strings_pos, "\t", $stringse[1], "\t", $delta, "\t", $sd, "\t",
            $t, "\t", $p, "\t", $score, "\t", $MirInfo{$stringsm[1]}->{Length},
            "\t", $po, "\t", $MirInfo{$stringsm[1]}->{"Gene-ori"}, "\t",
            $MirInfo{$stringsm[1]}->{Chr}, "\n";            

            if ($Restrict > 0) {
              if ($score >= $Restrictions{$MirInfo{$stringsm[1]}->{Length}}->[0]) {
                print RES_FILE3 $stringst[1], "\t", $stringsm[1], "\t", $num, "\t", $strings_pos,
                "\t", $stringse[1], "\t", $p, "\t", $score, "\t", $MirInfo{$stringsm[1]}->{Length},
                "\t", $MirInfo{$stringsm[1]}->{"Gene-ori"}, "\t", $MirInfo{$stringsm[1]}->{Chr}, "\n";
              }
            }
          }
        }
      close RNAHYBDRID_READ;
    }
  }
  close RES_FILE;
}
close RES_FILE2;
if ($Restrict > 0) {close RES_FILE3;}
if ($SeedSearch > 0) {close RES_FILE4;}

print "done.\n";

exit $x3;

########################################################
# Constructing the complementary sequence - from
# Arabella::Sequencer
########################################################
sub NucCompl ($$) {
  my $Sequence = $_[0];
  my $ReverseComplement = uc($_[1]);
  my @symbols = undef;
  my $i = 0;
 
  if ($ReverseComplement =~ m/C/) {
  @symbols = split (//, $Sequence);
    for ($i = 0; $i < ($#symbols+1); $i++) {
      if($symbols[$i] eq "a") { $symbols[$i] = "t"; next; }
      if($symbols[$i] eq "a") { $symbols[$i] = "u"; next; }
      if($symbols[$i] eq "t") { $symbols[$i] = "a"; next; }
      if($symbols[$i] eq "u") { $symbols[$i] = "a"; next; } 
      if($symbols[$i] eq "g") { $symbols[$i] = "c"; next; }
      if($symbols[$i] eq "c") { $symbols[$i] = "g"; next; }    
      if($symbols[$i] eq "A") { $symbols[$i] = "T"; next; }
      if($symbols[$i] eq "A") { $symbols[$i] = "U"; next; }
      if($symbols[$i] eq "T") { $symbols[$i] = "A"; next; }
      if($symbols[$i] eq "U") { $symbols[$i] = "A"; next; }
      if($symbols[$i] eq "G") { $symbols[$i] = "C"; next; }
      if($symbols[$i] eq "C") { $symbols[$i] = "G"; next; }
      if($symbols[$i] eq "N") { $symbols[$i] = "N"; }    
    }   
    $Sequence = join ("", @symbols);
  }
  $Sequence = reverse($Sequence) if $ReverseComplement =~ m/R/;
  return $Sequence;
}
########################################################

sub UsageVersion ($) {
  print "\n$PNAME\n";
  print "\nBy Charles Malaheenee (C) 2012";
  print "\nUsage: $0 [options] directory\n\n";
  print "Options:\n";
  print "-h, --help \t print this help text\n";
  print "-b number \t Maximal number of hits to show (default 5)\n";
  print "-d \t\t Differencial results (default no)\n";
  print "-r \t\t Restricted result data (default no)\n";
  print "-v \t\t Be verbose (default no)\n";
  print "--seed=number \t Seed search (default no)";
  print "\nReport bugs to ", 'malaheenee@gmx.fr', "\n\n";
  exit 0;
}
