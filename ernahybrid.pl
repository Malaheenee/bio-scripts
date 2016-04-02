#! /usr/bin/perl

# Automated work with RNAhybrid

# Check the code
use strict;
use warnings;

# Import modules
use Cwd 'abs_path', 'cwd';
use File::Basename 'fileparse';
use Statistics::Distributions 'tprob';
use Getopt::Long;
Getopt::Long::Configure 'gnu_getopt', 'no_auto_abbrev', 'no_ignore_case';

# Define variables
my ($hit_number, $different_results, $seed_search, $all_in_one,
    $work_dir, $file, $content, $string, $gene, $mir, $mfe, $pos,
    $tmp, $num, $delta, $value_sd, $value_t, $value_p, $score);
my (@seq_files, @pos);
my (%mir_info, %gene_info);
my ($length, $max_mir_len, $max_gene_len) = (0, 0, 0);
my %restrictions = (
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

# Parse command-line options
GetOptions(
  "help|h" => sub {use_ver($_[0])},
  "b=i"    => \$hit_number,
  "s=i"    => \$seed_search,
  "a"      => \$all_in_one,
  "d"      => \$different_results,
) or die $!;
$hit_number = 5        if not $hit_number;
$seed_search = 0       if not $seed_search;
$all_in_one = 0        if not $all_in_one;
$different_results = 0 if not $different_results;

# Set work dir
if ( @ARGV ) {
  $work_dir = abs_path(shift);
  if (not -d $work_dir) {
    print "The directory $work_dir not exists!\n";
    exit -1;
  }
}
else {
  $work_dir = cwd();
}
print "The current work dir is $work_dir.\n";

# Prepare miRNAs
print "Looking for miRNAs \(\.mir\)... ";
opendir(WORK_DIR, $work_dir);
  @seq_files = grep {/\.mir/i} readdir(WORK_DIR);
closedir(WORK_DIR);

if ( $#seq_files == -1 ) {
  print "No miRNAs found!\n";
  exit -1;
}

foreach $file ( @seq_files ) {
  open(MIR_FILE, "<", $work_dir."/".$file) or die "$!";
    while ( $string = <MIR_FILE> ) {
      $content = "";
      if ( $string =~ m/\;/ ) {
        @pos = split(/\;/, $string);
      }
      elsif ( $string =~ m/^\>/ ) {
          until($string !~ m/^\>/) {
            $content .= $string;
            $string = <MIR_FILE>;
          }
         $content .= $string;
         @pos = split(/\s/, $content);
      }
      foreach ( @pos ) {
        $_ =~ s/\>|\s//g;
      }
      $mir_info{$pos[0]}->{"Sequence"} = $pos[-1];
      $length = length($pos[-1]);
      $max_mir_len = $length if $length > $max_mir_len;
      $mir_info{$pos[0]}->{"Length"} = $length;
      $mir_info{$pos[0]}->{"GC"} = ($pos[-1] =~ tr/GgCc//)/$length;
      $mir_info{$pos[0]}->{"MRB-code"} = $pos[1] ? $pos[1] : "";
      $mir_info{$pos[0]}->{"Gene-origin"} = $pos[2] ? $pos[2] : "";
      $mir_info{$pos[0]}->{"Chromosome"} = $pos[3] ? $pos[3] : "";
    }
  close MIR_FILE;
}
print scalar(keys(%mir_info)), " miRNAs found. Max length: $max_mir_len.\n";
@seq_files = undef;

# Prepare genes
print "Looking for genes \(\.gene\)... ";
opendir(WORK_DIR, $work_dir);
  @seq_files = grep {/\.gene/i} readdir(WORK_DIR);
closedir(WORK_DIR);

if ( $#seq_files == -1 ) {
  print "No genes found!\n";
  exit -1;
}

foreach $file ( @seq_files ) {
  $content = "";
  $file = $work_dir."/".$file;
  open(GENE_FILE, "<", $file) or die "$!";
    while ( $string = <GENE_FILE> ) {
      chomp($string);
        if ($string !~ m/^\>/) {
          $string =~ s/\W//g;
          $string =~ s/\d//g;
          $content .= $string;
        }
        else {
          $string =~ s/^\>//;
          @pos = split(/\s\|\s/, $string);
          $gene = shift(@pos);
          $gene =~ s/\s//g;
          for (my $i = 0; $i <= $#pos; $i++) {
            $pos[$i] =~ s/\s//g;
            splice(@pos, $i, 1, split(/\-/, $pos[$i]));
          }
        }
      }
    $gene_info{$gene}->{"Sequence"} = $content;
    $length = length($content);
    $max_gene_len = $length if $length > $max_gene_len;
    $gene_info{$gene}->{"Length"} = $length;
    $gene_info{$gene}->{"GC"}->{"All"} = ($content =~ tr/GgCc//)/$length;
    $gene_info{$gene}->{"Coord"} = [@pos];
    $gene_info{$gene}->{"File"} = $file;

    if ( $different_results > 0 ) {
      for (my $i = 0; $i <= $#pos; $i += 2) {
        splice(@pos, $i, 1, substr($content, $pos[$i]-1, ($pos[$i+1]-($pos[$i]-1))));
      }
      foreach ( "5-utr", "3-utr", "cds" ) {
        $gene_info{$gene}->{"GC"}->{$_} = 0;
        $string = shift(@pos);
        $tmp = shift(@pos);
        $length = length($string);
        $gene_info{$gene}->{"GC"}->{$_} = ($string =~ tr/GgCc//)/$length if $length ne 0;
      }
    }
  close GENE_FILE;
}
print scalar(keys(%gene_info)), " genes found. Max length: $max_gene_len.\n";
@seq_files = undef;

# Collect whole information in file r-table_all.txt
print "Calculating miRNA-miRNA energy... ";
open(RES_ALL, ">", $work_dir."/r-table_all.txt") or die "$!";
  # For miRNA
  print RES_ALL "miRNAs energy\nmiRNA\tEnergy (kcal/mol)\tPosition\tLength\tGC content\tGene\tChromosome\n";
  foreach (keys(%mir_info)) {
    print "\rCalculating miRNA-miRNA energy... ", $_;
    open(RNAHYBDRID_READ, "RNAhybrid -d -nan,-nan ".
          $mir_info{$_}->{"Sequence"}." ".
          nuc_compl($mir_info{$_}->{"Sequence"}, "CR").
          " |") or die "$!";
      while ($string = <RNAHYBDRID_READ>) {
        $mir_info{$_}->{"Energy"} = $1 if ( $string =~ m/^mfe\:\s+(\-?\d+.*)\s+kcal\/mol/ );
        $pos = $1 if ( $string =~ m/^position\s+(\d+)/ );
      }
      close RNAHYBDRID_READ;
      print RES_ALL $_, "\t", $mir_info{$_}->{"Energy"}, "\t",
        $pos, "\t", $mir_info{$_}->{"Length"}, "\t",
        $mir_info{$_}->{"GC"}, "\t",
        $mir_info{$_}->{"Gene-origin"}, "\t",
        $mir_info{$_}->{"Chromosome"}, "\n";
  }

  # For genes
  print RES_ALL "\nGenes information\nGene\tLength\t5-utr\tcoding\t3-utr\tGC-content (all)";
  if ($different_results > 0) {
    print RES_ALL "\tGC-content (5-utr)\tGC-content (cds)\tGC-content (3-utr)";
  }
  print RES_ALL "\n";
  foreach ( keys(%gene_info) ) {
    print RES_ALL $_, "\t", $gene_info{$_}->{"Length"}, "\t",
    $gene_info{$_}->{"Coord"}->[0], "-", $gene_info{$_}->{"Coord"}->[1], "\t",
    $gene_info{$_}->{"Coord"}->[2], "-", $gene_info{$_}->{"Coord"}->[3], "\t",
    $gene_info{$_}->{"Coord"}->[4], "-", $gene_info{$_}->{"Coord"}->[5], "\t",
    $gene_info{$_}->{"GC"}->{"All"};
    if ( $different_results > 0 ) {
      print RES_ALL "\t", $gene_info{$_}->{"GC"}->{"5-utr"}, "\t",
      $gene_info{$_}->{"GC"}->{"cds"}, "\t", $gene_info{$_}->{"GC"}->{"3-utr"};
    }
    print RES_ALL "\n";
  }

  # Calculate energy
  print "\rCalculating miRNA-miRNA energy... Done.\nCalculating Gene-miRNA energy... ";
  print RES_ALL "\nGenes energies\nGene\tmiRNA\tNumber\tPosition".
  "\tWhere\tEnergy (kcal/mol)\tDelta energy\tSD\tT\tP\tScore\tmir-len".
  "\tmir-gen\tmir-chr\n";
  foreach $gene (keys(%gene_info)) {
    $file = $all_in_one ?
      $work_dir."/r-results_all.txt" :
      $work_dir."/r-results_".fileparse($gene_info{$gene}->{"File"}, '\..*').".txt";
    open(RES_GENE, ">>", $file) or die "$!";
      print RES_GENE "\nGene\tmiRNA\tNumber\tPosition\tWhere\t".
      "Energy (kcal/mol)\tScore\tPicture\n";
      foreach $mir (keys(%mir_info)) {
        print "\rCalculating Gene-miRNA energy... ", $gene, " + ", $mir;
        $num = 0;
        open (RNAHYBDRID_READ, "RNAhybrid -d -nan,-nan -b ".
               $hit_number. "-u 1 -v 1 -m $max_gene_len -n $max_mir_len -t".
               $gene_info{$gene}->{"File"}." ".
               $mir_info{$mir}->{"Sequence"}." |") or die "$!";
          while ($string = <RNAHYBDRID_READ>) {
            if ($string =~ m/^target\:\s+$gene/) {
              $content = "";
              $num++;
              until ($string =~ m/^miRNA\s+3\'/) {
                $string = <RNAHYBDRID_READ>;
                $mfe = $1 if ($string =~ m/^mfe\:\s+(\-?\d+.*)\s+kcal\/mol/);
                $content .= $string if ($string =~ m/^target\s5\'|^\s{2,}|^miRNA\s+3\'/);

                if ($string =~ m/^position\s+(\d+)/) {
                  $pos = $1;
                  if ($#{$gene_info{$gene}->{"Coord"}} == -1) {
                    $pos .= "\tunknown";
                  }
                  elsif ($pos <= $gene_info{$gene}->{"Coord"}->[1]) {
                    $pos .= "\t5-utr";
                  }
                  elsif ($pos >= $gene_info{$gene}->{"Coord"}->[2] &&
                         $pos <= $gene_info{$gene}->{"Coord"}->[3]) {
                    $pos .= "\tcoding";
                  }
                  elsif ($pos >= $gene_info{$gene}->{"Coord"}->[4]) {
                    $pos .= "\t3-utr";
                    }
                  else {
                    $pos .= "\tunknown";
                  }
                }
              }

              $delta = $mfe - ($mir_info{$mir}->{"Energy"}/2);
              $value_sd = 0.031 * $mir_info{$mir}->{"Energy"};
              $value_t = $delta/$value_sd;
              $value_p = tprob(4, $value_t);
              if ( $mir_info{$mir}->{"Length"} <= 21 ) {
                $value_p *= $restrictions{$mir_info{$mir}->{"Length"}}->[1];
              }
              elsif ( $mir_info{$mir}->{"Length"} >= 22 ) {
                $value_p /= $restrictions{$mir_info{$mir}->{"Length"}}->[1];
              }
              $score = 100*($mfe/$mir_info{$mir}->{"Energy"});

              $string = "$gene\t$mir\t$num\t$pos\t$mfe\t$score\tLook at next line\n$content\n";
              $tmp = "$gene\t$mir\t$num\t$pos\t$mfe\t$delta\t$value_sd".
                     "\t$value_t\t$value_p\t$score\t$mir_info{$mir}->{\"Length\"}".
                     "\t$mir_info{$mir}->{\"Gene-origin\"}".
                     "\t$mir_info{$mir}->{\"Chromosome\"}\n";
              if ( $seed_search > 0 &&
                   $content =~ m/[ACGU]{$seed_search}\s{3,4}$/im ) {
                print RES_GENE $string;
                print RES_ALL $tmp;
              }
              elsif ( $seed_search == 0 ) {
                print RES_GENE $string;
                print RES_ALL $tmp;
              }
            }
          }
        close RNAHYBDRID_READ;
      }
    close RES_GENE;
  }
close RES_ALL;
print "\rCalculating Gene-miRNA energy... Done.\n";

########################################################
# Construct the complementary sequence
sub nuc_compl {
  my $sequence = $_[0];
  my $rev_com = uc($_[1]);
  my @symbols = undef;
  my $i = 0;
 
  if ($rev_com =~ m/C/) {
    @symbols = split (//, $sequence);
    for ($i = 0; $i < ($#symbols+1); $i++) {
      if($symbols[$i] eq "a") { $symbols[$i] = "u"; next; }
      if($symbols[$i] eq "u") { $symbols[$i] = "a"; next; } 
      if($symbols[$i] eq "g") { $symbols[$i] = "c"; next; }
      if($symbols[$i] eq "c") { $symbols[$i] = "g"; next; }    
      if($symbols[$i] eq "A") { $symbols[$i] = "U"; next; }
      if($symbols[$i] eq "U") { $symbols[$i] = "A"; next; }
      if($symbols[$i] eq "G") { $symbols[$i] = "C"; next; }
      if($symbols[$i] eq "C") { $symbols[$i] = "G"; }
    }   
    $sequence = join ("", @symbols);
  }
  $sequence = reverse($sequence) if $rev_com =~ m/R/;
  return $sequence;
}

########################################################
# Usage & versioninformation
sub use_ver {
  print "\nRNAhybrid enhanced 22\n";
  print "\nBy Charles Malaheenee (C) 2016";
  print "\nUsage: $0 [options] directory\n\n";
  print "Options:\n";
  print "-b number    Maximal number of hits to show (default 5)\n";
  print "-s number    Seed search (default none)\n";
  print "-a           All genes in one file (default none)\n";
  print "-d           Differencial results (default none)\n";
  print "-h           Print this help text\n";
  print "\nReport bugs to ", 'malaheenee@gmx.fr', "\n\n";
  exit 0;
}
