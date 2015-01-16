#! /usr/bin/perl

# Search for miRNA's origins

# use Cwd;
use File::Basename;
use Tie::IxHash;
use Getopt::Long;
Getopt::Long::Configure 'gnu_getopt', 'no_auto_abbrev', 'no_ignore_case';

# Переменные
my $NAME    = "miRNA Finder";
my $VERSION = "2.2";

# Загрузка опций
GetOptions(
"version|v" => sub {UsageVersion($_[0])},
"help|h"    => sub {UsageVersion($_[0])},
"gbk|g"     => \$GBK,
"txt|t"     => \$TXT,
"int|i"     => \$INT,
"seq|s"     => \$SEQ,
"mirfile=s" => \$mirna_sls_file,
) or die $!;

unless (@ARGV) {
  Error("Data file not present!");
}

my $WorkDir = shift;
my $DataFile = $WorkDir."/mirnas_in_genes.txt";
$mirna_sls_file = "mirna_sls_t.txt" if $mirna_sls_file eq undef;

my %mirnas_txt;
my %mirnas_txt_c;
my %mirnas_gbk;
my %genes_txt;
my %genes_gbk;
tie %genes_gbk, "Tie::IxHash";
my %Founded_gbk;
my %Founded_txt;
my %Founded_ig_gbk;
my %Founded_ig_txt;

my $gb_keyword_gene = "  mRNA  ";
my $gb_keyword_ncrna = "  ncRNA  ";

my ($summ_txt, $summ_gbk, $summ_ms, $summ_sls) = 0;
my ($gb_line, $nuc_pos, $nuc_seq, $gene, $seq_num, $complement, $mir_num, $note, $mir_src) = 0;

if ($GBK == 0 && $INT == 0 && $SEQ == 0 && $TXT == 0) {
  Error("What to search?!");
}

$TXT = 1 if defined $SEQ;

print "\n    $NAME $VERSION ($0)\n";

print "\n    Collecting miRNAs... ";

opendir(GB_DIR, $WorkDir);
  my @gb_files_list = grep {/\.gb*/i} readdir(GB_DIR);
closedir(GB_DIR);

($summ_sls) = CollectmiRNAs("txt");
print "$summ_sls stem-loop miRNAs collected.\n";

open (DATA_FILE, ">>", $DataFile) or die ("Can't open file  $DataFile: $!");
  print DATA_FILE "\n\nmiRNA\tGene\tExon-Intron (GENE)\tmiRBase\tGenBank\tPosition\n";

foreach $gb_file (@gb_files_list) {
  print "\n    Processing file $gb_file...";
  print DATA_FILE "\n\n", $gb_file;
  %mirnas_gbk = ();
  %genes_txt = ();
  %genes_gbk = ();
  %Founded_gbk = ();
  %Founded_txt = ();
  %Founded_ig_gbk = ();
  %Founded_ig_txt = ();

  ($TempFile, $TempFileLength) = MakeTemp($gb_file, $WorkDir);
  
  $summ_gbk = CollectGenes("gbk", $gb_file);
  $summ_txt = CollectGenes("txt", $gb_file);
  $mir_num = CollectmiRNAs("gbk", $gb_file);
  
  $genes_gbk{StartEnd_w_0}->{Full} = [1, $TempFileLength];
  print " $summ_txt (txt) & $summ_gbk (gbk) sequences & $mir_num miRNAs collected.\n";

  # Поиск по файлам GenBank
  if (defined $GBK) {
    print "\n    Searching miRNAs in GenBank... ";
    foreach $x2 (sort keys (%mirnas_gbk)) { 
      @x2a = split("_", $x2);
      foreach $x1 (sort keys (%genes_gbk)) {
      @x1a = split("_", $x1);
        foreach $x0 (sort keys (%{$genes_gbk{$x1}})) {
          next if $x0 =~ m/full/i;
          if ($genes_gbk{$x1}->{$x0}->[0] <= ${$mirnas_gbk{$x2}}[0] &&
              ${$mirnas_gbk{$x2}}[-1] <= $genes_gbk{$x1}->{$x0}->[1]) {
            if ($x2a[1] eq $x1a[1]) {
              $Founded_gbk{$x2} = [$x1, $x0, "-", "+", "-"];
            }
          }
        }
      }
    }
    print DATA_FILE "\n---gbk only";
    foreach (keys %Founded_gbk) {print DATA_FILE "\n$_\t${$Founded_gbk{$_}}[0]\t${$Founded_gbk{$_}}[1]\t${$Founded_gbk{$_}}[2]\t${$Founded_gbk{$_}}[3]\t${$Founded_gbk{$_}}[4]";}
    print "Ready.\n";
  }

  # Поиск по файлам miRBase
  if (defined $TXT) {
    print "\n    Searching miRNAs in miRBase... ";
    foreach $x2 (keys %mirnas_txt) {
      foreach $x1 (sort keys %genes_txt) {
        foreach $x0 (sort keys %{$genes_txt{$x1}}) {
          if ($genes_txt{$x1}->{$x0} =~ m/$mirnas_txt{$x2}/i) {
            $Founded_txt{$x2} = [$x1, $x0, "+", "-", "-"];
          }
        }
      }
    }
    print DATA_FILE "\n---txt only";
    foreach (keys %Founded_txt) {print DATA_FILE "\n$_\t${$Founded_txt{$_}}[0]\t${$Founded_txt{$_}}[1]\t${$Founded_txt{$_}}[2]\t${$Founded_txt{$_}}[3]\t${$Founded_txt{$_}}[4]";}
    print "Ready.\n";
  }
  
  # Поиск межгенных микроРНК по файлам GenBank
  if (defined $INT) {
    print "\n    Searching miRNAs between genes in gbk files... ";
    @ggkeys = keys %genes_gbk;
    foreach $x2 (sort keys (%mirnas_gbk)) {
      @x2a = split("_", $x2);
      $x1prev = "";
      for ($i = 0; $i <= $#ggkeys; $i++) {
        $x1 = $ggkeys[$i];
        if ($x1prev eq "") {
          $x1prev = $x1;
          next;
        }
        @x1preva = split("_", $x1prev);
        @x1a = split("_", $x1);
        if ($genes_gbk{$x1prev}->{Full}->[-1] <= $mirnas_gbk{$x2}->[0] &&
            $mirnas_gbk{$x2}->[-1] <= $genes_gbk{$x1}->{Full}->[0]) {
          if ($x2a[1] eq $x1preva[1]) {
            next if ($x1preva[1] ne $x1a[1]);
            $Founded_ig_gbk{$x2} = [$x1prev, $x1, "-", "+", $mirnas_gbk{$x2}->[0]."-".$mirnas_gbk{$x2}->[-1]];
          }
        }
        $x1prev = $x1;
      }
      $x1 = "";
      for ($i = $#ggkeys; $i >= 0; $i--) {
        $x1prev = $ggkeys[$i];
        if ($x1 eq "") {
          $x1 = $x1prev;
          next;
        }
        @x1preva = split("_", $x1prev);
        @x1a = split("_", $x1);
        if ($genes_gbk{$x1prev}->{Full}->[-1] <= $mirnas_gbk{$x2}->[0] &&
            $mirnas_gbk{$x2}->[-1] <= $genes_gbk{$x1}->{Full}->[0]) {
          if ($x2a[1] eq $x1a[1]) {
            next if ($x1preva[1] ne $x1a[1]);
            $Founded_ig_gbk{$x2."-r"} = [$x1prev, $x1, "-", "+", $mirnas_gbk{$x2}->[0]."-".$mirnas_gbk{$x2}->[-1]];
          }
        }
        $x1 = $x1prev;
      }
    }
    print DATA_FILE "\n---ig-gbk only";
    foreach (keys %Founded_ig_gbk) {print DATA_FILE "\n$_\t${$Founded_ig_gbk{$_}}[0]\t${$Founded_ig_gbk{$_}}[1]\t${$Founded_ig_gbk{$_}}[2]\t${$Founded_ig_gbk{$_}}[3]\t${$Founded_ig_gbk{$_}}[4]";}
    print "Ready.\n";
  }

  # Поиск межгенных микроРНК по последовательности
  if (defined $SEQ) {
    print "\n    Searching miRNAs between genes in global sequence... ";
    open (TEMP_FILE, "<", $TempFile) or die ("Can't open file  $TempFile: $!");
      while($ReadString = <TEMP_FILE>) {
        foreach $x2 (keys %mirnas_txt) {
          if ($ReadString =~ m/$mirnas_txt{$x2}/i) {
            next if exists $Founded_txt{$x2};
            $y = ($-[0]+1)."-".$+[0];
            $Founded_ig_txt{$x2} = ["w", "w", "+", "-", $y];
          }
        }
        foreach $x2 (keys %mirnas_txt_c) {
          if ($ReadString =~ m/$mirnas_txt_c{$x2}/i) {
            next if exists $Founded_txt{$x2};
            $y = ($-[0]+1)."-".$+[0];
            $Founded_ig_txt{$x2} = ["c", "c", "+", "-", $y];
          }
        }
      }
    close TEMP_FILE;
    print DATA_FILE "\n---ig-txt only";
    foreach (keys %Founded_ig_txt) {print DATA_FILE "\n$_\t${$Founded_ig_txt{$_}}[0]\t${$Founded_ig_txt{$_}}[1]\t${$Founded_ig_txt{$_}}[2]\t${$Founded_ig_txt{$_}}[3]\t${$Founded_ig_txt{$_}}[4]";}
    print "Ready.\n";
  }
}
close DATA_FILE;
print "\n    Ready. Press any key to quit...\n\n";
$wait = <STDIN>;
exit (0);

##########################################
# Сбор миРНК из файлов
##########################################
sub CollectmiRNAs {
  my $Action = $_[0];
  my $gb_file = $WorkDir.$_[1];
  my ($summ_ms, $summ_sls, $mir_num) = 0;
  my ($key, $value1, $value);

  if ($Action =~ m/txt/i) {
    open(MIRNA_SLS_FILE, "< $mirna_sls_file") or die "\n    Can't open $mirna_sls_file: $!";
      while($string = <MIRNA_SLS_FILE>) {
        chomp($string);
        ($key, $value1, $value) = split(/\t/, $string);
        $key =~ s/hsa-let-/LET/i;
        $key =~ s/hsa-mir-/MIR/i;
        $key =~ s/^\>//;
        $mirnas_txt{uc($key)} = $value;
        $mirnas_txt_c{uc($key)} = NucCompl($value, "CR");
        $summ_sls++;
      }
    close MIRNA_SLS_FILE;
    return ($summ_sls, $summ_ms);
  }
  elsif ($Action =~ m/gbk/i) {
    open (GB_FILE, "<", $gb_file) or die ("Can't open file  $WorkDir.$gb_file: $!");
      while($gb_line = <GB_FILE>) {
        if ($gb_line =~ m/$gb_keyword_ncrna/) {
          $nuc_pos = $nuc_seq = $gene = $note = "";
          until ($gb_line =~ m{/}) {
            $nuc_pos .= $gb_line;
            $gb_line = <GB_FILE>;         
          }
          $gb_line =~ s/\s//g;
          $gb_line =~ s/\"//g;
          $gb_line =~ s{/}{}g;
          $gene = $gb_line;
          $gene =~ s/gene=//;
          $gene =~ s/locus_tag=//;
          $gene =~ s/[\:\*\?\"\<\>\|]/_/g;
          $nuc_pos =~ s/$gb_keyword_ncrna//;
          $nuc_pos =~ s/join//;
          $nuc_pos =~ s/\s//g;
          $nuc_pos =~ s/\(//g;
          $nuc_pos =~ s/\)//g;
          $nuc_pos =~ s/\<//g;
          $nuc_pos =~ s/\>//g;
          if ($nuc_pos =~ m/complement/) {$complement = "_c";}
          else {$complement = "_w";}
          $nuc_pos =~ s/complement//;
          @nuc_pos_list = split(/\.\./, $nuc_pos);
          
          $gb_line = <GB_FILE>;
          while ($gb_line =~ m{/}) {
            $note .= $gb_line;
            $gb_line = <GB_FILE>;         
          }
          if ($note =~ m/mirbase/i) {$mir_src = "_mrb";}
          else {$mir_src = "_cmp";}
       
          if ($note =~ m/miRNA/g) {
            $mir_num++;
            $mirnas_gbk{$gene.$complement.$mir_src.$mir_num} = [@nuc_pos_list];
          }
        }
      }
    close GB_FILE;
    return ($mir_num);
  }
}

##########################################
# Сбор генов из файлов
##########################################
sub CollectGenes {
  my $Action = $_[0];
  my $gb_file = $WorkDir.$_[1];
  my ($summ_txt, $summ_gbk) = 0;
  my ($seq_num, $num) = 0;
  
  if ($Action =~ m/txt/i) {
  open(GB_FILE, "<", $gb_file) or die ("Can't open file  $gb_file: $!");
  open (TEMP_FILE, "<", $TempFile) or die ("Can't open file  $TempFile: $!");
    while($gb_line = <GB_FILE>) {
      if ($gb_line =~ m/$gb_keyword_gene/) {
        $nuc_pos = "";
        $nuc_seq = "";
        $gene = "";
        until($gb_line =~ m{/}) {
          $nuc_pos .= $gb_line;
          $gb_line = <GB_FILE>;         
        }
        $gb_line =~ s/\s//g;
        $gb_line =~ s/\"//g;
        $gb_line =~ s{/}{}g;
        $gb_line =~ s/\/gene=//;
        $gene = $gb_line;
        $gene =~ s/gene=//;
        $gene =~ s/locus_tag=//;
        $gene =~ s/[\:\*\?\"\<\>\|]/_/g;
        $nuc_pos =~ s/$gb_keyword_gene//;
        $nuc_pos =~ s/join//;
        $nuc_pos =~ s/\s//g;
        $nuc_pos =~ s/\(//g;
        $nuc_pos =~ s/\)//g;
        $nuc_pos =~ s/\<//g;
        $nuc_pos =~ s/\>//g;
        if ($nuc_pos =~ m/complement/) {$complement = "_c";}
        else {$complement = "_w";}
        $nuc_pos =~ s/complement//;
        @nuc_pos_list = split(/,/, $nuc_pos);
        splice @posV, 0;
        foreach (@nuc_pos_list) {push (@posV, split(/\.\./, $_));}
        if ($#posV % 2) {
          $seq = "";
          if ($complement eq "_c") {$num = $#posV + 1;}
          else {$num = 1;}
          for ($i = 0; $i <= $#posV; $i += 2) {
            $posV[$i]--;
            seek (TEMP_FILE, $posV[$i], 0);
            read (TEMP_FILE, $seq, ($posV[$i+1] - $posV[$i]), length($seq));
            $seq = NucCompl($seq, "CR") if $complement eq "_c";
            $genes_txt{$gene.$complement."_sei".$seq_num}->{"Exon".$num} = $seq;
            $seq = "";
            if ($complement eq "_c") {$num--;}
            else {$num++;}
            $posV[$i]++;
          }
          
          if ($complement eq "_c") {$num = $#posV + 1;}
          else {$num = 1;}
          for ($i = 1; $i <= $#posV-1; $i += 2) {
            $posV[$i+1]--;
            seek (TEMP_FILE, $posV[$i], 0);
            read (TEMP_FILE, $seq, ($posV[$i+1] - $posV[$i]), length($seq));
            $seq = NucCompl($seq, "CR") if $complement eq "_c";
            $genes_txt{$gene.$complement."_sei".$seq_num}->{"Intron".$num} = $seq;
            $seq = "";
            if ($complement eq "_c") {$num--;}
            else {$num++;}
          }
        }
        $seq_num++;
      }
    }
    close TEMP_FILE;
    close GB_FILE;
    $summ_txt = $seq_num;
    return ($summ_txt);
  }
  elsif ($Action =~ m/gbk/i) {
    open (GB_FILE, "<", $gb_file) or die ("Can't open file  $WorkDir.$gb_file: $!");
      while($gb_line = <GB_FILE>) {
        if ($gb_line =~ m/$gb_keyword_gene/) {
          $nuc_pos = "";
          $nuc_seq = "";
          $gene = "";
          until($gb_line =~ m{/}) {
            $nuc_pos .= $gb_line;
            $gb_line = <GB_FILE>;
          }
          $gb_line =~ s/\s//g;
          $gb_line =~ s/\"//g;
          $gb_line =~ s{/}{}g;
          $gene = $gb_line;
          $gene =~ s/gene=//;
          $gene =~ s/locus_tag=//;
          $gene =~ s/[\:\*\?\"\<\>\|]/_/g;
          $nuc_pos =~ s/$gb_keyword_gene//;
          $nuc_pos =~ s/join//;
          $nuc_pos =~ s/\s//g;
          $nuc_pos =~ s/\(//g;
          $nuc_pos =~ s/\)//g;
          $nuc_pos =~ s/\<//g;
          $nuc_pos =~ s/\>//g;
          if ($nuc_pos =~ m/complement/) {$complement = "_c";}
          else {$complement = "_w";}
          $nuc_pos =~ s/complement//;
          @nuc_pos_list0 = split(/,/, $nuc_pos);
          splice @nuc_pos_list, 0;
          foreach (@nuc_pos_list0) {push (@nuc_pos_list, split(/\.\./, $_));}
          $summ_gbk++;
          if ($gene !~ m/^MIR\d+/i) {
            if ($complement eq "_c") {$ein = ($#nuc_pos_list+1)/2;}
            elsif ($complement eq "_w") {$ein = 1;}
            $genes_gbk{$gene.$complement."_".$summ_gbk}->{"Full"} = [$nuc_pos_list[0], $nuc_pos_list[-1]];
            for ($i = 0; $i<=($#nuc_pos_list); $i += 2 ) {
              if ($complement eq "_c") {$ein--;}
              elsif ($complement eq "_w") {$ein++;}
              next if $nuc_pos_list[$i] == $nuc_pos_list[-1];
              $genes_gbk{$gene.$complement."_".$summ_gbk}->{"Exon".$ein} = [$nuc_pos_list[$i], $nuc_pos_list[$i + 1]];
              next if $nuc_pos_list[$i] == $nuc_pos_list[-2];
              $genes_gbk{$gene.$complement."_".$summ_gbk}->{"Intron".$ein} = [$nuc_pos_list[$i + 1], $nuc_pos_list[$i + 2]];
            }
          }
        }
      }
    close GB_FILE;
    return ($summ_gbk);
  }
}

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
      if($symbols[$i] eq "C") { $symbols[$i] = "G"; }     
    }   
    $Sequence = join ("", @symbols);
  }
  $Sequence = reverse($Sequence) if $ReverseComplement =~ m/R/;
  return $Sequence;
}

########################################################
# Creates temporary file with complete nucleotide
# sequence from original GenBank file for extracting
# nucleotide sequences from
########################################################
sub MakeTemp ($$) {
  my $GeneBankFileName = $_[0];
  my $WorkDir = $_[1];
  my $TempFile = $WorkDir."\/"."TempSeq.dat";
  my $TempFileLength = 0;
  my $ReadString = "";
  open (GB_FILE, "<", $WorkDir.$GeneBankFileName) or die ("Can't open file $GeneBankFileName: $!");
  open (TEMP_FILE, ">", $TempFile) or die ("Can't create file $TempFile: $!");
    while($ReadString = <GB_FILE>) {
      if($ReadString =~ m/ORIGIN/) {
        while($ReadString = <GB_FILE>) {
          $ReadString =~ s/\W//g;
          $ReadString =~ s/\d//g;
          print TEMP_FILE $ReadString;
          $TempFileLength += length($ReadString);
        }
      }   
    }
  close GB_FILE;
  close TEMP_FILE;
  return ($TempFile, $TempFileLength);
}

##########################################
# Ошибки
##########################################
sub Error ($) {
  print STDERR "Error: $_[0]\nRun '$0 -h' for help\n";
  exit 1;
}

##########################################
# Выводит справку и версию
##########################################
sub UsageVersion ($) {
  if ($_[0] eq "version") {
    print "\n$NAME $VERSION ($0)\n";
    print "\nBy Charles Malaheenee (C) 2010-2011\n";
    print "Almaty, Kazakhstan\n\n";
  }
  elsif ($_[0] eq "help") {
    print "\nUsage: $0 [options] [--file=<string>] directory\n\n";
    print "Options:\n";
    print "-v, --version \t print version\n";
    print "-h, --help \t print this help text\n";
    print "-g, --gbk \t search miRNA in gbk files\n";
    print "-t, --txt \t search miRNA in sequences\n";
    print "-i, --int \t search intergenic miRNA in gbk files\n";
    print "-s, --seq \t search intergenic miRNA in global seqeunce (very, very slow!)\n";
    print "--mirfile=<string>  file with miRNA sequences (default \"mirna_sls_t.txt\")\n";
    print "\nReport bugs to ", 'malaheenee@gmx.fr', "\n\n";
  }
  exit 0;
}

