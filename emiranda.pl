#! /usr/bin/perl

# Automated work with miRanda

use File::Basename;
use Getopt::Long;
Getopt::Long::Configure 'gnu_getopt', 'no_auto_abbrev', 'no_ignore_case';

GetOptions(
"score|s:i" => sub {$Score = "-sc ".$_[1];}
) or die $!;

unless (@ARGV) {
  print "Data dir not present!\n";
  exit 1;
}

$WorkDir = shift;

print "miRanda enhanced 2\n";

opendir(WORK_DIR, $WorkDir);
  @MirFiles = grep {/\.mir/i} readdir(WORK_DIR);
closedir(WORK_DIR);
print $#MirFiles+1, " miRNAs found.\n";

opendir(WORK_DIR, $WorkDir);
  @GeneFiles = grep {/\.gene/i} readdir(WORK_DIR);
closedir(WORK_DIR);
print $#GeneFiles+1, " genes found.\nCalculating... ";

foreach $x1 (@GeneFiles) {
  ($x1b, $x1p, $x1e) = fileparse($WorkDir.$x1, '\..*');
  $x1d = $WorkDir.$x1;
  $x1r = $WorkDir."m-results_$x1b.txt";
  open (RES_FILE, ">", $x1r) or die "Can't open $x1r: $!";
    foreach $x2 (@MirFiles) {
        $x2d = $WorkDir.$x2;
        $x3 = (open MIRANDA_READ, "miranda $x2d $x1d $Score |") or die "$!";
          while ($string = <MIRANDA_READ>) {
            if ($string =~ m/Read Sequence/) {
              $strings = "";
              until ($string =~ m{Scan Complete}) {
                $strings .= $string;
                $string = <MIRANDA_READ>;         
              }
              print RES_FILE $strings, "\n";
            }
          }
        close MIRANDA_READ;
    }
  close RES_FILE;
}

print "done.\n";
exit $x3;

