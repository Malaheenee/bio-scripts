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
"crd|c"     => \$CRD,
"mirfile=s" => \$mirna_sls_file,
) or die $!;

unless (@ARGV) {
  Error("Data dir not present!");
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

($summ_sls) = CollectmiRNAs("txt") if defined $TXT;
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

  $summ_gbk = CollectGenes("gbk", $gb_file) if defined $GBK;
  $summ_txt = CollectGenes("txt", $gb_file) if defined $TXT;
  $mir_num = CollectmiRNAs("gbk", $gb_file) if defined $GBK;

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
              $Founded_gbk{$x2}->{$x1}->{$x0} = ["-", "+", "-"];
            }
          }
        }
      }
    }
    print DATA_FILE "\n---gbk only";
    foreach $x0 (keys %Founded_gbk) {
      foreach $x1 (keys %{$Founded_gbk{$x0}}) {
        foreach $x2 (keys %{$Founded_gbk{$x0}->{$x1}}) {
          print DATA_FILE "\n$x0\t$x1\t$x2\t$Founded_gbk{$x0}->{$x1}->{$x2}->[0]\t$Founded_gbk{$x0}->{$x1}->{$x2}->[1]\t$Founded_gbk{$x0}->{$x1}->{$x2}->[2]";
        }
      }
    }
    print "Ready.\n";
  }

  # Поиск по файлам miRBase
  if (defined $TXT) {
    print "\n    Searching miRNAs in miRBase... ";
    foreach $x2 (keys %mirnas_txt) {
      foreach $x1 (sort keys %genes_txt) {
        foreach $x0 (sort keys %{$genes_txt{$x1}}) {
          if ($genes_txt{$x1}->{$x0} =~ m/$mirnas_txt{$x2}/i) {
            $Founded_txt{$x2}->{$x1}->{$x0} = ["+", "-", "-"];
          }
        }
      }
    }
    print DATA_FILE "\n---txt only";
    foreach $x0 (keys %Founded_txt) {
      foreach $x1 (keys %{$Founded_txt{$x0}}) {
        foreach $x2 (keys %{$Founded_txt{$x0}->{$x1}}) {
          print DATA_FILE "\n$x0\t$x1\t$x2\t$Founded_txt{$x0}->{$x1}->{$x2}->[0]\t$Founded_txt{$x0}->{$x1}->{$x2}->[1]\t$Founded_txt{$x0}->{$x1}->{$x2}->[2]";
        }
      }
    }
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
  my $hash_ref = ReadGeneBankFile($gb_file);

  if ($Action =~ m/txt/i) {
    open (TEMP_FILE, "<", $TempFile) or die ("Can't open file  $TempFile: $!");
      foreach $z (keys %$hash_ref) {
        $summ_txt++;
        $gene = $z;
        $complement = $hash_ref->{$z}->{Information}->{Complementary};
        @nuc_pos_list = @{$hash_ref->{$z}->{mRNA}->{Position}};

        if ($complement eq "c") {$ein = ($#nuc_pos_list+1)/2;}
        elsif ($complement eq "w") {$ein = 1;}

#        $seq = "";
#        seek (TEMP_FILE, ($nuc_pos_list[0]-1), 0);
#        read (TEMP_FILE, $seq, ($nuc_pos_list[-1] - ($nuc_pos_list[0]-1)), length($seq));
#        $seq = NucCompl($seq, "CR") if $complement eq "c";
#        $genes_txt{$gene}->{"Full"} = $seq;

        for ($i = 0; $i <= $#nuc_pos_list; $i += 2 ) {

          if ($complement eq "c") {
            if ($nuc_pos_list[$i] <= $hash_ref->{$z}->{mRNA}->{Information}->{"3-utr"}->[-1]) {$crd = "3-";}
            elsif ($nuc_pos_list[$i] >= $hash_ref->{$z}->{mRNA}->{Information}->{"Coding"}->[0] &&
                   $nuc_pos_list[$i] <= $hash_ref->{$z}->{mRNA}->{Information}->{"Coding"}->[-1]) {$crd = "C-";}
            elsif ($nuc_pos_list[$i] >= $hash_ref->{$z}->{mRNA}->{Information}->{"5-utr"}->[0]) {$crd = "5-";}
          }
          elsif ($complement eq "w") {
            if ($nuc_pos_list[$i] <= $hash_ref->{$z}->{mRNA}->{Information}->{"5-utr"}->[-1]) {$crd = "5-";}
            elsif ($nuc_pos_list[$i] >= $hash_ref->{$z}->{mRNA}->{Information}->{"Coding"}->[0] &&
                   $nuc_pos_list[$i] <= $hash_ref->{$z}->{mRNA}->{Information}->{"Coding"}->[-1]) {$crd = "C-";}
            elsif ($nuc_pos_list[$i] >= $hash_ref->{$z}->{mRNA}->{Information}->{"3-utr"}->[0]) {$crd = "3-";}
          }

          next if $nuc_pos_list[$i] == $nuc_pos_list[-1];

          $seq = "";
          seek (TEMP_FILE, ($nuc_pos_list[$i]-1), 0);
          read (TEMP_FILE, $seq, ($nuc_pos_list[$i+1] - ($nuc_pos_list[$i]-1)), length($seq));
          $seq = NucCompl($seq, "CR") if $complement eq "c";
          $genes_txt{$gene}->{$crd."Exon".$ein} = $seq;
          $genes_txt{$gene}->{"Full"} .= $seq;

          next if $nuc_pos_list[$i] == $nuc_pos_list[-2];

          if ($complement eq "c") {$ein--;}

          $seq = "";
          seek (TEMP_FILE, ($nuc_pos_list[$i+1]-1), 0);
          read (TEMP_FILE, $seq, (($nuc_pos_list[$i+2]-1) - $nuc_pos_list[$i+1]), length($seq));
          $seq = NucCompl($seq, "CR") if $complement eq "c";
          $genes_txt{$gene}->{$crd."Intron".$ein} = $seq;
          $genes_txt{$gene}->{"Full"} .= $seq;

          if ($complement eq "w") {$ein++;}
        }
      }
    close TEMP_FILE;
    return ($summ_txt);
  }
  elsif ($Action =~ m/gbk/i) {
    foreach $z (keys %$hash_ref) {
      $summ_gbk++;
      $gene = $z;
      $complement = $hash_ref->{$z}->{Information}->{Complementary};
      @nuc_pos_list = @{$hash_ref->{$z}->{mRNA}->{Position}};
      if ($complement eq "c") {$ein = ($#nuc_pos_list+1)/2;}
      elsif ($complement eq "w") {$ein = 1;}

      $genes_gbk{$gene}->{"Full"} = [$nuc_pos_list[0], $nuc_pos_list[-1]];

      for ($i = 0; $i <= $#nuc_pos_list; $i += 2 ) {
        if ($complement eq "c") {$ein--;}
        elsif ($complement eq "w") {$ein++;}

        if ($nuc_pos_list[$i] <= $hash_ref->{$z}->{mRNA}->{Information}->{"5-utr"}->[-1]) {$crd = "5-";}
        elsif ($nuc_pos_list[$i] >= $hash_ref->{$z}->{mRNA}->{Information}->{"Coding"}->[0] &&
               $nuc_pos_list[$i] <= $hash_ref->{$z}->{mRNA}->{Information}->{"Coding"}->[-1]) {$crd = "C-";}
        elsif ($nuc_pos_list[$i] >= $hash_ref->{$z}->{mRNA}->{Information}->{"3-utr"}->[0]) {$crd = "3-";}

        next if $nuc_pos_list[$i] == $nuc_pos_list[-1];

        $genes_gbk{$gene}->{$crd."Exon".$ein} = [$nuc_pos_list[$i], $nuc_pos_list[$i+1]];

        next if $nuc_pos_list[$i] == $nuc_pos_list[-2];

        $genes_gbk{$gene}->{$crd."Intron".$ein} = [$nuc_pos_list[$i+1], $nuc_pos_list[$i+2]];
      }
    }
    return ($summ_gbk);
  }
}

########################################################
# Parse GeneBank file
########################################################
sub ReadGeneBankFile ($) {
  my $GeneBankFileName = shift;
  my @SearchKeywords = (mRNA, CDS);
  my ($Keyword, $Keyworde, $seq_num, $gb_line, $nuc_pos,
      $nuc_seq, $gene, $a1, $a2, $a3, $gene_num, $sec_num,
      $i, $j, $GeneName, $note, $complement) = "";
  my (@nuc_pos_list, @posV, @lk1, @lk2, @lk3, @lk5, @lk7, @lk3i, @lk5i, @lk7i);
  my (%seen, %seen2) = ();

  my %GenesInGeneBankFile = ();

  open (GB_FILE, "<", $GeneBankFileName) or die ("Can't open file $GeneBankFileName: $!");
  foreach $Keyword (@SearchKeywords) {
    $Keyworde = "  ".$Keyword."  ";
    seek (GB_FILE, 0, 0);
    $seq_num = 0;
    while($gb_line = <GB_FILE>) {
      if ($gb_line =~ m/$Keyworde/) {
        $gene_num = 0;
        $nuc_pos = "";
        $nuc_seq = "";
        $note = "";
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
        $gene =~ s/[\;\:\*\?\"\<\>\|]/_/g;
        $nuc_pos =~ s/$Keyword//;
        $nuc_pos =~ s/join//;
        $nuc_pos =~ s/\s//g;
        $nuc_pos =~ s/\(//g;
        $nuc_pos =~ s/\)//g;
        $nuc_pos =~ s/\<//g;
        $nuc_pos =~ s/\>//g;
        if ($nuc_pos =~ m/complement/) {$complement = "c";}
        else {$complement = "w";}
        $nuc_pos =~ s/complement//;
        @nuc_pos_list = split(/,/, $nuc_pos);
        splice @posV, 0;
        foreach (@nuc_pos_list) {push (@posV, split(/\.\./, $_));}
        $seq_num++;
        $GenesInGeneBankFile{$gene."_".$complement."_".$seq_num}->{$Keyword}->{Position} = [@posV];
        $GenesInGeneBankFile{$gene."_".$complement."_".$seq_num}->{Information}->{Complementary} = $complement;
      }
    }
  }
  close GB_FILE;

  foreach $GeneName (sort keys %GenesInGeneBankFile) {
    next unless exists $GenesInGeneBankFile{$GeneName}->{mRNA};
    next unless exists $GenesInGeneBankFile{$GeneName}->{CDS};

      splice @lk1, 0;
      %seen = ();
      foreach $a2 (@{$GenesInGeneBankFile{$GeneName}->{CDS}->{Position}}) {
        $seen{$a2} = 1;
      }
      foreach $a3 (@{$GenesInGeneBankFile{$GeneName}->{mRNA}->{Position}}) {
        unless ($seen{$a3}) {
          push (@lk1, $a3);
        }
      }
      if ($#lk1 == 0) {
        $lk1[1] = $lk1[0];
        $lk1[0] = 1;
      }

      splice @lk2, 0;
      %seen2 = ();
      foreach $a2 (@{$GenesInGeneBankFile{$GeneName}->{mRNA}->{Position}}) {
        $seen2{$a2} = 1;
      }
      foreach $a3 (@{$GenesInGeneBankFile{$GeneName}->{CDS}->{Position}}) {
        unless ($seen2{$a3}) {
          push (@lk2, $a3);
        }
      }
      if ($#lk2 == 0) {
        $lk2[1] = $lk2[0];
        $lk2[0] = 1;
      }

      splice @lk5, 0;
      splice @lk3, 0;
      push (@lk3, $lk2[-1]);
      for ($i = 0; $i <= $#lk1; $i++) {
        for ($j = 0; $j <= $#lk2; $j++) {
          if (($lk2[$j] > $lk1[$i]) && ($lk1[$i] < $lk2[0])) {splice (@lk5, $i, 1, $lk1[$i]);}
          elsif (($lk2[$j] < $lk1[$i]) && ($lk3[-1] != $lk1[$i]) && ($lk1[$i] > $lk2[-1])) {splice (@lk3, $i, 1, $lk1[$i]);}
        }
      }
      push (@lk5, $lk2[0]);

      splice @lk5i, 0;
      $lk5i[0] = 1;
      $lk5i[1] = 0;
      for ($i = 0; $i <= $#lk5; $i += 2) {
        $lk5i[1] += $lk5[$i+1] - ($lk5[$i] - 1);
      }
      $lk5i[1]-- if $lk5i[1] >= 1;
      $lk5i[0]-- if $lk5i[1] <= 0;

      @lk7 = @{$GenesInGeneBankFile{$GeneName}->{CDS}->{Position}};
      splice @lk7i, 0;
      $lk7i[0] = $lk7i[1] = $lk5i[1]+1;
      for ($i = 0; $i <= $#lk7; $i += 2) {
        $lk7i[1] += $lk7[$i+1] - ($lk7[$i] - 1);
      }
      $lk7i[1]--;

      splice @lk3i, 0;
      $lk3i[0] = $lk3i[1] = $lk7i[1]+1;
      for ($i = 0; $i <= $#lk3; $i += 2) {
        $lk3i[1] += $lk3[$i+1] - ($lk3[$i] - 1);
      }
      $lk3i[1]--;
      $lk3i[1] = $lk3i[0] if $lk3i[1] <= 0;

      if ($GenesInGeneBankFile{$GeneName}->{Information}->{Complementary} eq "c") {
        $GenesInGeneBankFile{$GeneName}->{mRNA}->{Information}->{"3-utr"} = [@lk5[0], @lk5[-1]];
        $GenesInGeneBankFile{$GeneName}->{mRNA}->{Information}->{"Coding"} = [@lk7[0], @lk7[-1]];
        $GenesInGeneBankFile{$GeneName}->{mRNA}->{Information}->{"5-utr"} = [@lk3[0], @lk3[-1]];
      }
      elsif ($GenesInGeneBankFile{$GeneName}->{Information}->{Complementary} eq "w") {
        $GenesInGeneBankFile{$GeneName}->{mRNA}->{Information}->{"5-utr"} = [@lk5[0], @lk5[-1]];
        $GenesInGeneBankFile{$GeneName}->{mRNA}->{Information}->{"Coding"} = [@lk7[0], @lk7[-1]];
        $GenesInGeneBankFile{$GeneName}->{mRNA}->{Information}->{"3-utr"} = [@lk3[0], @lk3[-1]];
      }
  }
  return \%GenesInGeneBankFile;
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
          if ($ReadString =~ m/\[gap\s+(\d+).+\]/i) {
            $ReadString = "n" x $1;
          }
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
    print "\nUsage: $0 [options] [--mirfile=<string>] directory\n\n";
    print "Options:\n";
    print "-v, --version \t print version\n";
    print "-h, --help \t print this help text\n";
    print "-g, --gbk \t search miRNA in gbk files\n";
    print "-t, --txt \t search miRNA in sequences\n";
    print "-i, --int \t search intergenic miRNA in gbk files\n";
    print "-s, --seq \t search intergenic miRNA in global seqeunce (very, very slow!)\n";
    print "-c, --crd \t define coordinates of miRNA\n";
    print "--mirfile=<string>  file with miRNA sequences (default \"mirna_sls_t.txt\")\n";
    print "\nReport bugs to ", 'malaheenee@gmx.fr', "\n\n";
  }
  exit 0;
}

