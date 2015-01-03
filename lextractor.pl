#! /usr/bin/perl

# Загрузкка модулей
use Term::ANSIColor;
use Getopt::Long;
#use strict;
#use warnings;
#use File::Basename;
#use Term::ReadKey;
#use Spreadsheet::WriteExcel;

# Конфигурирование модулей
Getopt::Long::Configure 'gnu_getopt', 'no_auto_abbrev', 'no_ignore_case';

# Переменные - программа
my $ConfigFileName = "~/.arabella/settings.conf";
my $NAME    = "Arabella Extractor 2011 for Linux";
my $VERSION = "0.0.2";
my $BUILD   = "0020E3";
my $PACKET  = "Arabella Nucleotide Analyzing Suite 2011";

# Переменные - данные
my %GenesInGeneBankFile = ();
my $GBFileType = '\.gb.*';
my %TextFiles = ();
my @GBFilesList = ();
my @TempFile = ();
my @WriteModes = ();
my ($Frame2M, $Keyword_e, $Keyword, $GBFilesDir, $number, $GeneBankFileName,
$GeneBankFileName_e, $seq_num, $seq_num2, $seq_numX, $GeneBankFileDir,
$ExcelFile, $SequencesDir, $StatisticsDir);

# Конфигурация по умолчанию
my %Configuration = my %ConfigurationOriginal = (
  "Language"               => "Russian",
  "UseDefaultLanguage"     => 1,
  "Keyword"                => undef,
  "FeaturesToInclude"      => "gene, mRNA, ncRNA, CDS",
  "SequencesDir"           => "Sequences/",
  "StatisticsDir"          => "Statistics/",
  "NotCreateDirs"          => 0,
  "UpperCase"              => 1,
  "EndStar"                => 1,
  "TTOU"                   => 0,
  "NoComplementary"        => 0,
  "CORW"                   => 0,
  "IntronsNumber"          => 0,
  "GeneName"               => 1,
  "NumberOfSequence"       => 1,
  "UseExtension"           => 0,
  "Extension"              => "gene",
  "OutputFileXLS"          => "All_data.xls",
  "NotCreateFileXLS"       => 1,
  "OutputFileTXT"          => "All_data.txt",
  "IntronGroups"           => "0, 1, 2, 3, 4, 5, 1-2, 1-5, 3-5, 6-9, 6-10, 10-14, 11-15, 11-, 15-, 16-",
  "TempFileName"           => "TempSeq.dat",
  "MenuFontName"           => "Sans Serif, 8, bold,italic",
  "EditFontName"           => "Fixedsys, 12",
  "DeleteTempFiles"        => 0,
  "AllowedBrackets"        => 0,
  "AllowedHTML"            => 0,
  "WorkDir"                => $ENV{HOME},
  "DefaultAction"          => 0,
  "CalculateGenesQuantity" => 0,
  "CalculateLengths"       => 0,
  "ExtractExons"           => 0,
  "ExtractWithIntrons"     => 0,
  "ExtractSEI"             => 0,
  "ExtractWithFrame"       => 0,
  "ExtractWithoutFrame"    => 1,
  "ExtractFrame"           => undef,
  "FastaFormat"            => "0",
  "BeVerbose"              => "0",
);

my $LoadConfig = ReadConfigurationFile($ConfigFileName);

# Загрузка опций
GetOptions(
"version|v"        => sub {UsageVersion($_[0])},
"help|h"           => sub {UsageVersion($_[0])},
"verbose|b"        => \$Configuration{BeVerbose},
"length|l"         => \$Configuration{CalculateLengths},
"quantity|q"       => \$Configuration{CalculateGenesQuantity},
"exons|e"          => \$Configuration{ExtractExons},
"introns|i"        => \$Configuration{ExtractWithIntrons},
"separate|s"       => \$Configuration{ExtractSEI},
"default|d"        => \$Configuration{DefaultAction},
"fasta|f"          => \$Configuration{FastaFormat},
"keyword=s"        => \$Configuration{Keyword},
"frame:i"          => \$Configuration{ExtractFrame},
"allow-brackets|a" => \$Configuration{AllowedBrackets},
) or die $!;

# Каталог для обработки
unless (@ARGV) {
  Error("Data dir not present!");
}
$Configuration{WorkDir} = shift;

# Если задана опция -d, то вычисление действий
if ($Configuration{DefaultAction} == 1) {
  $Configuration{CalculateLength} = 1;
  $Configuration{CalculateGenesQuantity} = 1;
  $Configuration{ExtractExons} = 1;
  $Configuration{ExtractWithIntrons} = 1;
  $Configuration{ExtractSEI} = 1;
  $Configuration{Keyword} = "CDS";
  $Configuration{ExtractWithoutFrame} = 1;
}

# Обработка настроек
$Configuration{IntronGroups} =~ s/\s+//g;
$Configuration{FeaturesToInclude} =~ s/\s+//g;
$Configuration{EditFontName} =~ s/\s+//g;
$Configuration{MenuFontName} =~ s/\s+//g;
#$Configuration{Extension} = "fasta" if ($Configuration{FastaFormat} == 1);
TextFilesNames($Configuration{IntronGroups}) if ($Configuration{CalculateLength} == 1);

# Действия
if ($Configuration{CalculateLength}        == 0 &&
    $Configuration{CalculateGenesQuantity} == 0 &&
    $Configuration{ExtractExons}           == 0 &&
    $Configuration{ExtractWithIntrons}     == 0 &&
    $Configuration{ExtractSEI}             == 0) {
  Error("What to do?!");
}
else {
  # Задание соответствующих режимов записи
  $WriteModes[$#WriteModes+1] = "exon" if ($Configuration{ExtractExons} == 1);
  $WriteModes[$#WriteModes+1] = "all" if ($Configuration{ExtractWithIntrons} == 1);
  $WriteModes[$#WriteModes+1] = "exon-intron" if ($Configuration{ExtractSEI} == 1);
  
  # Проверка рамки, если она задана
  if (defined $Configuration{ExtractFrame}) {
    if ($Configuration{ExtractFrame} eq "" ||
        $Configuration{ExtractFrame} == undef ||
        $Configuration{ExtractFrame} == 0 ||
        $Configuration{ExtractFrame} =~ m/([A-Z]|\s|\W)/ig) {
      Error("Bad Frame!");
    }
    else {
      $Frame2M = $Configuration{ExtractFrame};
      $Configuration{ExtractWithFrame} = 1;
      $Configuration{ExtractWithoutFrame} = 0;
    }
  }
  else {
    $Configuration{ExtractWithoutFrame} = 1;
    $Configuration{ExtractWithFrame} = 0;
  }

  # Проверка ключевого слова, если оно задано
  if (defined $Configuration{Keyword}) {
    $Keyword = $Configuration{Keyword};
    if ($Keyword =~ m/([0-9]|\s|\W)/ig) {
      Error("Bad Keyword!");
    }
  }
  else {
    $Keyword = $Configuration{FeaturesToInclude};
  }

  # Обработка рабочего каталога и поиск файлов gbk
  $Configuration{WorkDir} =~ s/\\/\//g;
  $Configuration{WorkDir} .= "\/" if substr($Configuration{WorkDir}, -1, 1) ne "\/";
  $Configuration{WorkDir} =~ s/[\*\?\"\<\>\|]//g;

  $GBFilesDir = glob($Configuration{WorkDir});
  splice @GBFilesList, 0;

  if (substr($Configuration{WorkDir}, -1, 1) ne "\/" ||
    $Configuration{WorkDir} =~ m/.*\./) {
    Error("Data dir not present!");
  }
  else {
    opendir(GB_DIR, $GBFilesDir);
      @GBFilesList = grep {/$GBFileType/i} readdir(GB_DIR);
    closedir(GB_DIR);
  }

  # Обработка всех найденных файлов
  if ($#GBFilesList >= 0) {
    $number = $#GBFilesList + 1;
    foreach $GeneBankFileName (@GBFilesList) {
      print "Processing file $GeneBankFileName...";
      $seq_num = 0;
      $seq_num2 = 0;
      $seq_numX = 0;

      # Определение каталога для записи результатов
      $GeneBankFileName_e = $GeneBankFileName;
      $GeneBankFileName_e =~ s/\..*//i;
      $GeneBankFileDir = $GBFilesDir.$GeneBankFileName_e."\/";
      mkdir $GeneBankFileDir, 0777;

      # Создание подкаталогов
      $SequencesDir = $GeneBankFileDir.$Configuration{SequencesDir};
      $StatisticsDir = $GeneBankFileDir.$Configuration{StatisticsDir};
      mkdir ($StatisticsDir, 0777) if ($Configuration{CalculateGenesQuantity} == 1 || $Configuration{CalculateLength} == 1);
      mkdir ($SequencesDir, 0777) if ($Configuration{ExtractExons} == 1 || $Configuration{ExtractWithIntrons} == 1 || $Configuration{ExtractSEI} == 1);

      $ExcelFile = $StatisticsDir.$Configuration{OutputFileXLS} if ($Configuration{NotCreateFileXLS} == 0);
      $GeneBankFileName = $GBFilesDir.$GeneBankFileName;

      # Чтение файла GenBank
      $seq_num = ReadGeneBankFile($GeneBankFileName, (split (/,/, $Configuration{FeaturesToInclude})));

      # Отработка действий
      if ($Configuration{ExtractExons} == 1 ||
          $Configuration{ExtractWithIntrons} == 1 ||
          $Configuration{ExtractSEI} == 1) {
        @TempFile = MakeTempFile($GeneBankFileName, $GeneBankFileDir);
      }
      if ($Configuration{CalculateLengths} == 1) {
        $seq_numX = CalculateLengths($GeneBankFileName, $StatisticsDir, $Frame2M);
      }
      if ($Configuration{CalculateGenesQuantity} == 1) {
        $seq_numX = CalculateGenesQuantity($GeneBankFileName, $StatisticsDir, $Frame2M);
      }
      if ($Configuration{ExtractWithFrame} == 1) {
        $seq_num = ExtractWithFrame($Keyword, $Frame2M);
      }
      elsif ($Configuration{ExtractWithoutFrame} == 1) {
        $seq_num = ExtractWithoutFrame($Keyword);
      }
 
      # Вывод результатов о работе
      print "\t";
      if ($seq_num == 0) {print "keyword $Keyword_e not found.\n";}
      if ($seq_numX == 0 && $seq_num == 0) {print "genes and $Keyword_e not found.\n";}
      if ($seq_numX != 0 && $seq_num != 0) {print "$seq_numX genes and $seq_num $Keyword_e founded.\n";}
      if ($seq_numX == 0 && $seq_num != 0) {print "$seq_num $Keyword founded.\n";}
      if ($seq_numX != 0 && $seq_num == 0) {print "$seq_numX genes founded.\n";}
    }
  }
  else {
    print "In folder $GBFilesDir GeneBank files not found.\n";
  }
}
exit 0;

##########################################
# Выводит справку и версию
##########################################
sub UsageVersion ($) {
  if ($_[0] eq "version") {
    print colored("\n$NAME\nv. $VERSION.$BUILD ($0)\n", "bold");
    print "\nPart of $PACKET\n";
    print "\nBy Charles Malaheenee (C) 2004-2012\n";
    print "By Timour Ivashchenko (C) 2000-2001\n";
    print "\nal-Farabi Kazakh national university\n";
    print "Almaty, Kazakhstan\n\n";
  }
  elsif ($_[0] eq "help") {
    print "\nUsage: $0 [options] [--keyword=<string>] directory\n\n";
    print "Options:\n";
    print "-v, --version \t\t print version\n";
    print "-h, --help \t\t print this help text\n";
    print "-b, --verbose \t\t be verbose (default no)\n";
    print "-l, --length \t\t calculate length\n";
    print "-q, --quantity \t\t calculate number of genes\n";
    print "-e, --exons \t\t extract exons\n";
    print "-i, --introns \t\t extract gene with introns\n";
    print "-s, --separate \t\t extract separately exons and introns\n";
    print "-d, --default \t\t default actions (equialent -lqeis --keyword=CDS)\n";
    print "-a, --allow--brackets \t\t uAllow extraction of sequences with > or < (default no)\n";
    print "-f, --fasta \t\t use FASTA format for the sequences (default no)\n";
    print "--keyword=<string> \t target keyword (default \"CDS\")\n";
    print "--frame=<frame> \t use frame for extraction, calculation (default no)\n";
    print "\nReport bugs to ", 'malaheenee@gmx.fr', "\n\n";
  }
  exit 0;
}

##########################################
# Вывод ошибок
##########################################
sub Error ($) {
  print STDERR colored("Error: $_[0]\nRun '$0 -h' for help", "red bold");
  print STDERR color("reset"), "\n";
  exit 1;
}

##########################################
# Вывод дополнительной информации
##########################################
sub AddInfo ($) {
  print "\n\t";
  print "Reading sequence $_[0]";
}

#############################################################
# Loading configuration from file
#############################################################
sub ReadConfigurationFile {
  my ($Feature, $Value, $Return) = undef;
  my $ConfigurationFile = open (CONFIG_FILE, "<", $_[0]);
  if (defined $ConfigurationFile) {
    while (<CONFIG_FILE>) {
      chomp;
      s/#.*//;
      s/^\s+//;
      s/\s+$//;
      next unless length;
      ($Feature, $Value) = split(/\s*=\s*/, $_, 2);
      $Configuration{$Feature} = $Value if exists $Configuration{$Feature};
    }
    close CONFIG_FILE;

    foreach ("ExonsDir", "WithIntronsDir", "SEIDir", "StatisticsDir") {
      $Configuration{$_} =~ s/\\/\//g;
      $Configuration{$_} .= "\/" if substr($Configuration{$_}, -1, 1) ne "\/";
      $Configuration{$_} =~ s/[\:\*\?\"\<\>\|]//g;
    }

    $Configuration{WorkDir} .= "\/" if substr($Configuration{WorkDir}, -1, 1) ne "\/";
    while (my ($k, $v) = each %Configuration) {$ConfigurationOriginal{$k} = $v;}
    $Return = 1;
  }
  else {$Return = 0;}
  return $Return;
}

#############################################################
# Saving configuration to file
#############################################################
sub WriteConfigurationFile {
  my ($Feature, $Value, $Return, $num) = 0;

  while (($Feature, $Value) = each %ConfigurationOriginal) {
    $num++ if $ConfigurationOriginal{$Feature} != $Configuration{$Feature};
    $num++ if $ConfigurationOriginal{$Feature} ne $Configuration{$Feature};
  }

  if ($num > 0) {
    my $ConfigurationFile = open(CONFIG_FILE, ">", $_[0]);
    if (defined $ConfigurationFile) {
      while (($Feature, $Value) = each (%Configuration)) {print CONFIG_FILE "$Feature = $Value\n";}
      close CONFIG_FILE;
      $Return = 1;
    }
    else {$Return = 0;}
  }
  return $Return;
}

#############################################################
# Имена текстовых файлов
#############################################################
sub TextFilesNames ($) {
  my $Groups = $_[0];
  my ($k, $v, $IG);
  while (($k, $v) = each(%TextFiles)) {delete($TextFiles{$k});}
  $Groups =~ s/\s+//g;
  my @Sp;
  my @IntronGroups = split(/,/,  $Groups);
  foreach $IG (@IntronGroups) {
    splice @Sp , 0;
    if ($IG =~ m/-/) {
      @Sp = split(/-/, $IG);
      foreach (@Sp) {$_ = ($_ * 2) + 1;}
      if (defined $Sp[1]) {$TextFiles{$IG} = [$IG." introns.txt", $Sp[0], $Sp[1]];}
      else {$TextFiles{$IG} = [$IG." and more introns.txt", $Sp[0]];}
    }
    else {
      $TextFiles{$IG} = [$IG." introns.txt", (($IG * 2) + 1)] if $IG != 0;
      $TextFiles{Without} = ["Without introns.txt", (($IG * 2) + 1)] if $IG == 0;
    }
  }
  $TextFiles{Length} = ("All_introns.txt");
}

########################################################
# Creates temporary file with complete nucleotide
# sequence from original GenBank file for extracting
# nucleotide sequences from
########################################################
sub MakeTempFile ($$) {
  my $GeneBankFileName = $_[0];
  my $WorkDir = $_[1];
  my $TempFile = $WorkDir."\/".$Configuration{TempFileName};
  my $TempFileLength = 0;
  my $ReadString = "";
  open (GB_FILE, "<", $GeneBankFileName) or die ("Can't open file $GeneBankFileName: $!");
  open (TEMP_FILE, ">", $TempFile) or die ("Can't create file $TempFile: $!");
    while ($ReadString = <GB_FILE>) {
      if ($ReadString =~ m/^ORIGIN/) {
        while ($ReadString = <GB_FILE>) {
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

########################################################
# Extracts nucleotide sequence from temp file with
# nucleotide sequence (all features)
########################################################
sub ExtractSequence ($$@) {
  my $Complementary = shift;
  my $Mode = shift;
  my @Positions = @_;
  my @Sequences = ();
  my ($seq, $fragment, $i, $num) = "";
  $Mode = "exon-intron" if $Mode eq "all";
  
  if ($Mode =~ m/exon/i) {
    if ($Complementary eq "c") {$num = $#Positions - 1;}
    else {$num = 0;}
    for ($i = 0; $i <= $#Positions; $i += 2) {
      $Positions[$i]--;
      seek (TEMP_FILE, $Positions[$i], 0);
      read (TEMP_FILE, $seq, ($Positions[$i+1] - $Positions[$i]), length($seq));
      $seq = NucCompl($seq, "CR") if $Complementary eq "c";
      $Sequences[$num] = $seq;
      $seq = "";
      if ($Complementary eq "c") {$num -= 2;}
      else {$num += 2;}
      $Positions[$i]++;
    }
  }

  if ($Mode =~ m/intron/i) {
    if ($Complementary eq "c") {$num = $#Positions - 2;}
    else {$num = 1;}
    for ($i = 1; $i <= $#Positions-1; $i += 2) {
      $Positions[$i+1]--;
      seek (TEMP_FILE, $Positions[$i], 0);
      read (TEMP_FILE, $seq, ($Positions[$i+1] - $Positions[$i]), length($seq));
      $seq = NucCompl($seq, "CR") if $Complementary eq "c";
      $Sequences[$num] = $seq;
      $seq = "";
      if ($Complementary eq "c") {$num -= 2;}
      else {$num += 2;}
      $Positions[$i]++;
    }
  }

  return @Sequences;
}
  
########################################################
# Parse GeneBank file
########################################################
sub ReadGeneBankFile ($@) {
  my $GeneBankFileName = shift;
  my @SearchKeywords = @_;
  my ($Keyword, $Keyworde, $seq_num, $gb_line, $nuc_pos,
      $nuc_seq, $gene, $a1, $a2, $a3, $gene_num, $sec_num,
      $i, $j, $GeneName, $note, $complement, $c1, $c2, $c3) = "";
  my (@nuc_pos_list, @posV, @lk1, @lk2, @lk3, @lk5, @lk7, @lk3i, @lk5i, @lk7i);
  my (%seen, %seen2) = ();
  
  %GenesInGeneBankFile = ();
  
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
        next if ($nuc_pos =~ m/\</ && $Configuration{AllowedBrackets} == "0");
        next if ($nuc_pos =~ m/\>/ && $Configuration{AllowedBrackets} == "0");
        if ($nuc_pos =~ m/complement/) {$complement = "c";}
        else {$complement = "w";}
        $nuc_pos =~ s/complement//;
        @nuc_pos_list = split(/,/, $nuc_pos);
        splice @posV, 0;
        foreach (@nuc_pos_list) {push (@posV, split(/\.\./, $_));}
        $gb_line = <GB_FILE>;
        while ($gb_line =~ m{^\s+C|m|n|t|g.*\s+}) {
          $note .= $gb_line;
          $gb_line = <GB_FILE>;         
        }
        if (defined $GenesInGeneBankFile{$gene}->{$Keyword}) {
          $gene_num = $#{$GenesInGeneBankFile{$gene}->{$Keyword}} + 1;
       # if ($note =~ m/transcript_id\=(.*)/) {
       #    $c1 = $1;
       #    $c1 =~ s/\"//g;
       #    $c2 = $c1;
       #    print "\n$Keyword $c1";
       #    $gene_num = 1;
        }
        else {$gene_num = 1;}
        $GenesInGeneBankFile{$gene}->{$Keyword}->[$gene_num]->{Position} = [@posV];
        $GenesInGeneBankFile{$gene}->{$Keyword}->[$gene_num]->{Information}->{IntronsNumber} = $#nuc_pos_list;
        $GenesInGeneBankFile{$gene}->{Information}->{Complementary} = $complement;
        $seq_num++;
      }
    }
  }
  close GB_FILE;
  
  foreach $GeneName (sort keys %GenesInGeneBankFile) {
    next unless exists $GenesInGeneBankFile{$GeneName}->{mRNA};
    next unless exists $GenesInGeneBankFile{$GeneName}->{CDS};
    for ($a1 = 1; $a1 <= $#{$GenesInGeneBankFile{$GeneName}->{mRNA}}; $a1++) {

      print "\n", $GeneName, ,"-", $a1, "-", $GenesInGeneBankFile{$GeneName}->{Information}->{Complementary};
      print "\nmRNA"; foreach (@{$GenesInGeneBankFile{$GeneName}->{mRNA}->[$a1]->{Position}}) {print "-", $_;}
      print "\nCDS"; foreach (@{$GenesInGeneBankFile{$GeneName}->{CDS}->[$a1]->{Position}}) {print "-", $_;}

      splice @lk1, 0;
      %seen = ();
      foreach $a2 (@{$GenesInGeneBankFile{$GeneName}->{CDS}->[$a1]->{Position}}) {
        $seen{$a2} = 1;
      }
      foreach $a3 (@{$GenesInGeneBankFile{$GeneName}->{mRNA}->[$a1]->{Position}}) {
        unless ($seen{$a3}) {
          push (@lk1, $a3);
        }
      }
#      if ($#lk1 == 0) {
#        $lk1[1] = $lk1[0];
#        $lk1[0] = 1;
#      }
      print "\nlk1"; foreach (@lk1) {print "-", $_;}
      
      splice @lk2, 0;
      %seen2 = ();
      foreach $a2 (@{$GenesInGeneBankFile{$GeneName}->{mRNA}->[$a1]->{Position}}) {
        $seen2{$a2} = 1;
      }
      foreach $a3 (@{$GenesInGeneBankFile{$GeneName}->{CDS}->[$a1]->{Position}}) {
        unless ($seen2{$a3}) {
          push (@lk2, $a3);
        }
      }
#      if ($#lk2 == 0) {
#        $lk2[1] = $lk2[0];
#        $lk2[0] = 1;
#      }
      print "\nlk2"; foreach (@lk2) {print "-", $_;}

      splice @lk5, 0;
      splice @lk3, 0;
      push (@lk3, $lk2[-1]);
      for ($i = 0; $i <= $#lk1; $i++) {
        for ($j = 0; $j <= $#lk2; $j++) {
          if (($lk2[$j] > $lk1[$i]) &&
              ($lk1[$i] < $lk2[0])) {
              splice (@lk5, $i, 1, $lk1[$i]);
          }
          elsif (($lk2[$j] < $lk1[$i]) &&
#                 ($lk3[-1] != $lk1[$i]) &&
                 ($lk3[-1] != $lk5[-1]) &&
                 ($lk1[$i] > $lk2[-1])) {
              splice (@lk3, $i, 1, $lk1[$i]);
          }
        }
      }
      push (@lk5, $lk2[0]);
      
      @lk7 = @{$GenesInGeneBankFile{$GeneName}->{CDS}->[$a1]->{Position}};

      print "\nlk5"; foreach (@lk5) {print "-", $_;}
      print "\nlk7"; foreach (@lk7) {print "-", $_;}
      print "\nlk3"; foreach (@lk3) {print "-", $_;}

      if ($GenesInGeneBankFile{$GeneName}->{Information}->{Complementary} eq "c") {
        splice @lk3i, 0;
        $lk3i[0] = 1;
        $lk3i[1] = 0;
        if ($Configuration{ExtractWithIntrons} == 1) {
          $lk3i[1] = $lk3[-1] - ($lk3[0] - 1);
        }
        elsif ($Configuration{ExtractExons} == 1) {
          for ($i = 0; $i <= $#lk3; $i += 2) {
            $lk3i[1] += $lk3[$i+1] - ($lk3[$i] - 1);
          }
        }
        $lk3i[1]-- if $lk3i[1] >= 1;
        $lk3i[0]-- if $lk3i[1] <= 0;
#        $lk3i[1] = $lk3i[0] if $lk3i[1] <= 0;
        print "\nlk3i"; foreach (@lk3i) {print "-", $_;}
      
        splice @lk7i, 0;
        $lk7i[0] = $lk7i[1] = $lk3i[1]+1;
        if ($Configuration{ExtractWithIntrons} == 1) {
          $lk7i[1] = ($lk7[-1] - ($lk7[0] - 1)) + $lk3i[-1];
        }
        elsif ($Configuration{ExtractExons} == 1) {
          for ($i = 0; $i <= $#lk7; $i += 2) {
            $lk7i[1] += $lk7[$i+1] - ($lk7[$i] - 1);
          }
        }
        $lk7i[1]--;
        print "\nlk7i"; foreach (@lk7i) {print "-", $_;}

        splice @lk5i, 0;
        $lk5i[0] = $lk5i[1] = $lk7i[1]+1;
        if ($Configuration{ExtractWithIntrons} == 1) {
          $lk5i[1] = ($lk5[-1] - ($lk5[0] - 1)) + $lk7i[-1];
        }
        elsif ($Configuration{ExtractExons} == 1) {
          for ($i = 0; $i <= $#lk5; $i += 2) {
            $lk5i[1] += $lk5[$i+1] - ($lk5[$i] - 1);
          }
        }
#        $lk5i[1]-- if $lk5i[1] >= 1;
#        $lk5i[0]-- if $lk5i[1] <= 0;
        $lk5i[1]--;
        $lk5i[1] = $lk5i[0] if $lk5i[1] <= 0;
        print "\nlk5i"; foreach (@lk5i) {print "-", $_;}
          
        $GenesInGeneBankFile{$GeneName}->{mRNA}->[$a1]->{Information}->{"5-utr"} = "$lk3i[0]-$lk3i[1]";
        $GenesInGeneBankFile{$GeneName}->{mRNA}->[$a1]->{Information}->{"Coding"} = "$lk7i[0]-$lk7i[1]";
        $GenesInGeneBankFile{$GeneName}->{mRNA}->[$a1]->{Information}->{"3-utr"} = "$lk5i[0]-$lk5i[1]";
      }
      elsif ($GenesInGeneBankFile{$GeneName}->{Information}->{Complementary} eq "w") {
        splice @lk5i, 0;
        $lk5i[0] = 1;
        $lk5i[1] = 0;
        if ($Configuration{ExtractWithIntrons} == 1) {
          $lk5i[1] = $lk5[-1] - ($lk5[0] - 1);
        }
        elsif ($Configuration{ExtractExons} == 1) {
          for ($i = 0; $i <= $#lk5; $i += 2) {
            $lk5i[1] += $lk5[$i+1] - ($lk5[$i] - 1);
          }
        }
        $lk5i[1]-- if $lk5i[1] >= 1;
        $lk5i[0]-- if $lk5i[1] <= 0;
        print "\nlk5i"; foreach (@lk5i) {print "-", $_;}
      
        splice @lk7i, 0;
        $lk7i[0] = $lk7i[1] = $lk5i[1]+1;
        if ($Configuration{ExtractWithIntrons} == 1) {
          $lk7i[1] = ($lk7[-1] - ($lk7[0] - 1)) + $lk5i[-1];
        }
        elsif ($Configuration{ExtractExons} == 1) {
          for ($i = 0; $i <= $#lk7; $i += 2) {
            $lk7i[1] += $lk7[$i+1] - ($lk7[$i] - 1);
          }
        }
        $lk7i[1]--;
        print "\nlk7i"; foreach (@lk7i) {print "-", $_;}

        splice @lk3i, 0;
        $lk3i[0] = $lk3i[1] = $lk7i[1]+1;
        if ($Configuration{ExtractWithIntrons} == 1) {
          $lk3i[1] = ($lk3[-1] - ($lk3[0] - 1)) + $lk7i[-1];
        }
        elsif ($Configuration{ExtractExons} == 1) {
          for ($i = 0; $i <= $#lk3; $i += 2) {
            $lk3i[1] += $lk3[$i+1] - ($lk3[$i] - 1);
          }
        }
        $lk3i[1]--;
        $lk3i[1] = $lk3i[0] if $lk3i[1] <= 0;
        print "\nlk3i"; foreach (@lk3i) {print "-", $_;}

        $GenesInGeneBankFile{$GeneName}->{mRNA}->[$a1]->{Information}->{"5-utr"} = "$lk5i[0]-$lk5i[1]";
        $GenesInGeneBankFile{$GeneName}->{mRNA}->[$a1]->{Information}->{"Coding"} = "$lk7i[0]-$lk7i[1]";
        $GenesInGeneBankFile{$GeneName}->{mRNA}->[$a1]->{Information}->{"3-utr"} = "$lk3i[0]-$lk3i[1]";
      }
    }
  }
  return $seq_num;
}

########################################################
# 
########################################################
sub ExtractWithoutFrame ($) {
  my @Keywords = split (/,/, $_[0]);
  my $seq_num = 0;
  my ($a1, $SequenceType, $GeneName, $GeneInfo, $Mode) = "";
  
  open (TEMP_FILE, "<", $TempFile[0]) or die ("Can't open file  $TempFile[0]: $!");
    foreach $GeneName (keys %GenesInGeneBankFile) {
      AddInfo($GeneName) if $Configuration{BeVerbose} == 1;
      foreach $SequenceType (@Keywords) {
        next unless exists $GenesInGeneBankFile{$GeneName}->{$SequenceType};
        for ($a1 = 1; $a1 <= $#{$GenesInGeneBankFile{$GeneName}->{$SequenceType}}; $a1++) {
          $GeneInfo = "";
          if ($Configuration{FastaFormat} == 1  &&
#              ($Configuration{ExtractExons} == 1 || $Configuration{ExtractWithIntrons} == 1) &&
              $SequenceType eq "mRNA") {
            $GeneInfo = ">";
            $GeneInfo .= $GeneName;
            if ($Configuration{ExtractExons} == 1) {$GeneInfo .= "-e-";}
            elsif ($Configuration{ExtractWithIntrons} == 1) {$GeneInfo .= "-i-";}
            $GeneInfo .= $a1;
            foreach ("5-utr", "Coding", "3-utr") {
              $GeneInfo .= " \| ".$GenesInGeneBankFile{$GeneName}->{$SequenceType}->[$a1]->{Information}->{$_};
            }
            $GeneInfo .= "\n";
          }
          foreach $Mode (@WriteModes) {
            if ($Mode ne "") {
              $seq_num += WriteSequence($GeneName, $SequenceType, $a1, $Mode, $GeneInfo, ExtractSequence($GenesInGeneBankFile{$GeneName}->{Information}->{Complementary}, $Mode, @{$GenesInGeneBankFile{$GeneName}->{$SequenceType}->[$a1]->{Position}}));
            }
          }
        }
      }
    }
  close TEMP_FILE;
  
  $seq_num /= $#WriteModes if $#WriteModes > 0;
#  if ($Configuration{DeleteTempFile} == 1 ) {unlink($TempFile[0]);}
#  $seq_num--;
  return $seq_num;
}

########################################################
# 
########################################################
sub WriteSequence ($$$$$@) {
  my $GeneName = shift;
  my $SequenceType = shift;
  my $a1 = shift;
  my $Mode = shift;
  my $GeneInfo = shift;
  my @Sequences = @_;
  
  my ($cw, $numin, $numseqe, $numseqi, $numsei, $ext, $GeneFileName, $b1, $b2, $nuc_dir) = "";
  my $seq_num = 1;
 
  if ($Configuration{IntronsNumber} == 1)    {$numin = $GenesInGeneBankFile{$GeneName}->{$SequenceType}->[$a1]->{Information}->{IntronsNumber}."-";};
  if ($Configuration{NumberOfSequence} == 1) {$numseqe = "-e".$a1; $numseqi = "-i".$a1; $numsei = "-sei".$a1;}
  if ($Configuration{CORW} == 1)             {$cw = $GenesInGeneBankFile{$GeneName}->{Information}->{Complementary};}
  if ($Configuration{UseExtension} == 1)     {$ext = ".".$Configuration{Extension};}
  
  if ($Mode eq "exon") {
    $GeneFileName = $SequencesDir.$cw.$numin.$SequenceType."-".$GeneName.$numseqe.$ext;
    open(GENE_FILE, ">", $GeneFileName) or die ("Can't open or create file $GeneFileName: $!");
      print GENE_FILE $GeneInfo;
      for ($b1 = 0; $b1 <= $#Sequences; $b1 += 2) {
        print GENE_FILE uc($Sequences[$b1]);
      }
      print GENE_FILE "*\n";
    close GENE_FILE;
  }
  if ($Mode eq "all") {
    $GeneFileName = $SequencesDir.$cw.$numin.$SequenceType."-".$GeneName.$numseqi.$ext;
    open(GENE_FILE, ">", $GeneFileName) or die ("Can't open or create file $GeneFileName: $!");
      print GENE_FILE $GeneInfo;
      for ($b1 = 0; $b1 <= $#Sequences; $b1++) {
        print GENE_FILE uc($Sequences[$b1]);
      }
      print GENE_FILE "*\n";
    close GENE_FILE;
  }
  if ($Mode eq "exon-intron") {
    $nuc_dir = $SequencesDir.$cw.$numin.$SequenceType."-".$GeneName.$numsei;
    mkdir $nuc_dir, 0777;
    $b2 = 1;
    for ($b1 = 0; $b1 <= $#Sequences; $b1 += 2) {
      $GeneFileName = $nuc_dir."/Exon-".$b2;
      open(GENE_FILE, ">", $GeneFileName) or die ("Can't open or create file $GeneFileName: $!");
        print GENE_FILE uc($Sequences[$b1]), "\n";
      close GENE_FILE;
      $b2++;
    }
    $b2 = 1;
    for ($b1 = 1; $b1 <= $#Sequences; $b1 += 2) {
      $GeneFileName = $nuc_dir."/Intron-".$b2;
      open(GENE_FILE, ">", $GeneFileName) or die ("Can't open or create file $GeneFileName: $!");
        print GENE_FILE uc($Sequences[$b1]), "\n";
      close GENE_FILE;
      $b2++;
    }
  }

  return $seq_num;
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
      if($symbols[$i] eq "C") { $symbols[$i] = "G"; next; }
      if($symbols[$i] eq "N") { $symbols[$i] = "N"; }    
    }   
    $Sequence = join ("", @symbols);
  }
  $Sequence = reverse($Sequence) if $ReverseComplement =~ m/R/;
  return $Sequence;
}

########################################################
# 
########################################################
sub CalculateLengths (@) {
#  %TextFiles2 = ();
#
#  while (($k, $v) = each %TextFiles) {
#    if (ref($v) eq "ARRAY") {
#      $TextFiles2{$k} = [$StatisticsDir.${$v}[0], ${$v}[1], ${$v}[2]] if $#{$v} == 2;
#      $TextFiles2{$k} = [$StatisticsDir.${$v}[0], ${$v}[1]] if $#{$v} == 1;
#    }
#    else {$TextFiles2{$k} = $StatisticsDir.$v;}
#  }
  my @nuc_pos_list = @_;
  splice my @len, 0;
  splice my @pos, 0;
  my $j = 1;
  my $i = 0;
  my $fragment1 = "";
  my $fragmnet2 = "";
  my ($n, $nn, $m, $mm) = undef;
  foreach $fragment1 (@nuc_pos_list) {push (@pos, split(/\.\./, $fragment1));}
  foreach (@pos) {          
    $n = $pos[$i] - 1;
    $nn = $pos[$j] - $n;
    if ($nn >1) {push  (@len, $nn)};
    $i++;
    $j++;
    $m = $pos[$j] - 1;
    $mm = $m - $pos[$i];
    if ($mm >1) {push  (@len, $mm)};
    $i++;
    $j++;
  }
  return @len;
}

########################################################
# 
########################################################
sub WriteLengths ($$$$@) {
  my $num_len = shift @_;
  my $TF = shift @_;
  my $gene = shift @_;
  my $gb_kw = shift @_;
  my @len = @_;
  my %TFHash = %$TF;
  my $key = 0;

  foreach $key (keys %TFHash) {
    if (ref($TFHash{$key}) eq "ARRAY") {
      if ($#{$TFHash{$key}} == 2) {
        if (${$TFHash{$key}}[1] <= $num_len && $num_len <= ${$TFHash{$key}}[2]) {
          open(TXT_FILE, ">> ${$TFHash{$key}}[0]") or die ("UnableOpenOrCreateFile ${$TFHash{$key}}[0]: $!");
            print TXT_FILE "$gene ";
            print TXT_FILE "$gb_kw ";
            print TXT_FILE "@len \n";
          close TXT_FILE;
        }
      }
      if ($#{$TFHash{$key}} == 1) {
        if (${$TFHash{$key}}[0] =~ m/.*more/i) {
          if ($num_len >= ${$TFHash{$key}}[1]) {
            open(TXT_FILE, ">> ${$TFHash{$key}}[0]") or die ("UnableOpenOrCreateFile ${$TFHash{$key}}[0]: $!");
              print TXT_FILE "$gene ";
              print TXT_FILE "$gb_kw ";
              print TXT_FILE "@len \n";
            close TXT_FILE;
          }
        }
        if ($num_len == ${$TFHash{$key}}[1]) {
          open(TXT_FILE, ">> ${$TFHash{$key}}[0]") or die ("UnableOpenOrCreateFile ${$TFHash{$key}}[0]: $!");
            print TXT_FILE "$gene ";
            print TXT_FILE "$gb_kw ";
            print TXT_FILE "@len \n";
          close TXT_FILE;
        }
      }
    }
    else {
      open(TXT_FILE, ">> $TFHash{$key}") or die ("UnableOpenOrCreateFile $TFHash{$key}: $!");      
        print TXT_FILE "$gene ";
        print TXT_FILE "$gb_kw ";
        print TXT_FILE "@len \n";
      close TXT_FILE;
    }
  }
}

########################################################
# 
########################################################
sub ExtractWithFrame ($$$$) {
  my $GeneBankFileName = $_[0];
  my $GeneBankFileDir = $_[1];
  my $FrameM = my $Frame1M = my $Frame2M = $_[2];
  my $Keyword = $_[3];
  my $Keyword_e = $Keyword;
  my $nomer = 1;
  my $seq_num = 0;
  #my $seq_num2 = 0;
  my ($c, $w, $numin, $numseqe, $numseqi, $ext, $fragmentV, $fragment) = "";
  my (@nuc_pos_list2, @pos2);
  if ($Configuration{CORW} == 1) {$c = "c"; $w = "w";}
  if ($Configuration{UseExtension} == 1) {$ext = ".".$Configuration{Extension};}
      
  my ($GeneBankFileDirX, $nin, $gb_line, $nuc_pos, $nuc_seq, $nuc_file, $gene, $complement, $gb_kw, $k, $v);

  splice my @nuc_pos_list, 0;
  splice my @posV, 0;
  splice my @nuc_pos_listV, 0;
  splice my @len, 0;

  $GeneBankFileDirX = $GeneBankFileDir."Group_$nomer\\";

  mkdir $GeneBankFileDirX, 0777;
  my %TextFiles2 = ();

  while (($k, $v) = each %TextFiles) {
    if (ref($v) eq "ARRAY") {
      $TextFiles2{$k} = [$GeneBankFileDirX.${$v}[0], ${$v}[1], ${$v}[2]] if $#{$v} == 2;
      $TextFiles2{$k} = [$GeneBankFileDirX.${$v}[0], ${$v}[1]] if $#{$v} == 1;
    }
    else {$TextFiles2{$k} = $GeneBankFileDirX.$v;}
  }                                 

  open(GB_FILE, "< $GeneBankFileName") or die ("UnableOpenFile $GeneBankFileName: $!");
  if (defined $TempFile[0]) {open (TEMP_FILE, "< $TempFile[0]") or die ("UnableOpenFile $TempFile[0]: $!");}
    while($gb_line = <GB_FILE>) {
      if ($gb_line =~ m/$Keyword/) {
        $nuc_pos = "";
        $nuc_seq = "";
        $gene = "";
        until($gb_line =~ m{/}) {
          $nuc_pos .= $gb_line;        # Adding next line to $nuc_pos
          $gb_line = <GB_FILE>;         
        }
        $gb_line =~ s/\s//g;             # Formatting gene name 
        $gb_line =~ s/\"//g;
        $gb_line =~ s{/}{}g;
        $gb_line =~ s/\/gene=//;
        $gene = $gb_line;                # Assigning gene name
        $gene =~ s/gene=//;
        $gene =~ s/locus_tag=//;
        $gene =~ s/[\:\*\?\"\<\>\|]/_/g;
        $nuc_pos =~ s/$Keyword_e//;   # Removing "$Keyword"
        $nuc_pos =~ s/join//;            # Removing "join"
        $nuc_pos =~ s/\s//g;             # Removing all space symbols
        $nuc_pos =~ s/\(//g;             # Removing all "("
        $nuc_pos =~ s/\)//g;             # Removing all ")"
        next if ($nuc_pos =~ m/\</ && $Configuration{AllowedBrackets} == "0");       # "<"
        next if ($nuc_pos =~ m/\>/ && $Configuration{AllowedBrackets} == "0");       # ">"
        if ($nuc_pos =~ m/complement/) {$complement = "yes";}
        else {$complement = "no";}
        $nuc_pos =~ s/complement//;              # Removing "complement"
        @nuc_pos_list = split(/,/, $nuc_pos);
        splice @posV, 0;
        @nuc_pos_listV = @nuc_pos_list;
        foreach $fragmentV (@nuc_pos_listV) {push (@posV, split(/\.\./, $fragmentV));}
        if ($#posV % 2) {
          splice @pos2, 0;
          @nuc_pos_list2 = @nuc_pos_list;
          if ($Configuration{IntronsNumber} == 1) {$numin = $#nuc_pos_list."-";};
          foreach $fragment (@nuc_pos_list2) {push (@pos2, split(/\.\./, $fragment));}
          if ($FrameM >= $pos2[-1]) {
            if ($Configuration{NumberOfSequence} == 1) {$numseqe = "-e".$seq_num; $numseqi = "-i".$seq_num;}
            if ($Configuration{CalculateLength} == 1) {
              $gb_kw = $c.$Keyword_e if $complement eq "yes";
              $gb_kw = $w.$Keyword_e if $complement eq "no";
              @len = CalculateLengths(@nuc_pos_list);
              my $num_len = $#len + 1;
              @len = reverse(@len) if $complement eq "yes";
              CalculateLengthsWrite2($num_len, \%TextFiles2, $gene, $gb_kw, @len);
              splice @len, 0;
            }
            if ($Configuration{ExtractExons} == 1) {
              $nuc_seq = "";
              $nuc_seq = ExtractGene(@nuc_pos_list);
              if ($complement eq "yes") {
                $nuc_seq = Complement($nuc_seq);
                $nuc_file = $GeneBankFileDirX.$c.$numin.$gene.$numseqe.$ext;
              }
              else {$nuc_file = $GeneBankFileDirX.$w.$numin.$gene.$numseqe.$ext;}
              open(NUC_FILE, ">".$nuc_file) or die ("UnableOpenOrCreateFile $nuc_file: $!");
                print NUC_FILE uc "$nuc_seq"."*";
              close NUC_FILE;
            }
            if ($Configuration{ExtractWithIntrons} == 1) {
              $nuc_seq = "";
              $nuc_seq = ExtractGeneWithIntrons(@nuc_pos_list);
              if ($complement eq "yes") {
                $nuc_seq = Complement($nuc_seq);
                $nuc_file = $GeneBankFileDirX.$c.$numin.$gene.$numseqi.$ext;
              }
              else {$nuc_file = $GeneBankFileDirX.$c.$numin.$gene.$numseqi.$ext;}
              open(NUC_FILE, ">".$nuc_file) or die ("UnableOpenOrCreateFile $nuc_file: $!");      
                print NUC_FILE uc "$nuc_seq"."*";
              close NUC_FILE;
            }
            if ($Configuration{ExtractSEI} == 1) {
              ExtractSEI($GeneBankFileDirX, $gene, $nuc_pos, $complement, $seq_num);
            }
          }
          else {
            $nomer++;
            $FrameM = $FrameM + $Frame1M;
            $GeneBankFileDirX = $GeneBankFileDir."Group_$nomer\\";
            mkdir $GeneBankFileDirX, 0777;
            while (($k, $v) = each %TextFiles) {
              if (ref($v) eq "ARRAY") {
                $TextFiles2{$k} = [$GeneBankFileDirX.${$v}[0], ${$v}[1], ${$v}[2]] if $#{$v} == 2;
                $TextFiles2{$k} = [$GeneBankFileDirX.${$v}[0], ${$v}[1]] if $#{$v} == 1;
              }
              else {$TextFiles2{$k} = $GeneBankFileDirX.$v;}
            } 
          }
          $seq_num++;
        }
      }
    }
  close TEMP_FILE;
  close GB_FILE;
  if ($Configuration{DeleteTempFile} == 1 ) {unlink($TempFile[0]);}
#  $seq_num--;
  return $seq_num;
}

########################################################
# 
########################################################
sub CalculateGenesQuantity ($$$) {
  my $GeneBankFileName = $_[0];
  my $Frame = my $Frame1 = my $Frame2 = $_[2];
  my $Keyword_e = "gene";
  my $Keyword = "  ".$Keyword_e."  ";
  my $numberA = 0;
  my $numberC = 0;
  my $numberW = 0;
  my $nuc_file = $_[1]."GeneQuantity.txt";
  my ($gb_line, $nuc_pos, $nuc_seq, $gene, $seq_num, $complement) = 0;

  open(NUC_FILE, ">>".$nuc_file) or die ("UnableOpenOrCreateFile $nuc_file: $!");
    print NUC_FILE "File: ".$GeneBankFileName.", Length: ".$TempFile[1].", Keyword: ".$Keyword_e.", Frame: ".$Frame."\n";
    print NUC_FILE "Frame\tALL\tC\tW\n";

  open(GB_FILE, "< $GeneBankFileName") or die ("UnableOpenFile $GeneBankFileName: $!");
    while($gb_line = <GB_FILE>) {
      if ($gb_line =~ m/$Keyword/) {
      $nuc_pos = "";
      $nuc_seq = "";
      $gene = "";
      until($gb_line =~ m{/}) {
        $nuc_pos .= $gb_line;        # Adding next line to $nuc_pos
        $gb_line = <GB_FILE>;         
      }
      $gb_line =~ s/\s//g;             # Formatting gene name 
      $gb_line =~ s/\"//g;
      $gb_line =~ s{/}{}g;
      $gb_line =~ s/\/gene=//;
      $gene = $gb_line;                # Assigning gene name
      $gene =~ s/gene=//;
      $gene =~ s/locus_tag=//;
      $nuc_pos =~ s/$Keyword_e//;   # Removing "$Keyword"
      $nuc_pos =~ s/join//;            # Removing "join"
      $nuc_pos =~ s/\s//g;             # Removing all space symbols
      $nuc_pos =~ s/\(//g;             # Removing all "("
      $nuc_pos =~ s/\)//g;             # Removing all ")"
      $nuc_pos =~ s/\>//g;             # Removing all ">"
      $nuc_pos =~ s/\<//g;             # Removing all "<"
      if ($nuc_pos =~ m/complement/) {$complement = "yes";}
      else {$complement = "no";}
      $nuc_pos =~ s/complement//;              # Removing "complement"
      my @gene_pos_list = split(/\.\./, $nuc_pos);

      if ($Configuration{ExtractWithFrame} == 1) {
        if ($Frame >= $gene_pos_list[-1]) {
          $numberA++;
          $numberC++ if $complement eq "yes";
          $numberW++ if $complement eq "no";
        }
        else {
          $numberA++;
          $numberC++ if $complement eq "yes";
          $numberW++ if $complement eq "no";

          print NUC_FILE "$Frame\t$numberA\t$numberC\t$numberW\n";

          $numberA = 0;
          $numberC = 0;
          $numberW = 0;
          $Frame = $Frame + $Frame1;
        }
      }
      else {
        $numberA++;
        $numberC++ if $complement eq "yes";
        $numberW++ if $complement eq "no";
      }
      $seq_num++;
    }
  }
  print NUC_FILE "$Frame\t$numberA\t$numberC\t$numberW\n";
  close GB_FILE;
  close NUC_FILE;
  return $seq_num;
}

