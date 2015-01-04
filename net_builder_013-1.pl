#!/usr/bin/perl

use GD;
use Storable;
use Getopt::Long;

*pi = \3.1415923595933733264067382257084242187059326559802469065520496834163440897890684752378059815711250293876860624673188325650310260348017353037507287559741891028695865;

($detal, $data_file, $output_filename, $size, $transparent, $nocancer) = undef;
GetOptions(
'version|v'     => sub { Usage_Version($_[0]) },
'help|h'        => sub { Usage_Version($_[0]) },
'detal|d:i'     => \$detal,
'output|o:s'    => \$output_filename,
'size|s:i'      => \$size,
'transparent|t' => \$transparent,
'nocancer|n'    => \$nocancer) or die $!;

unless (@ARGV) {
    print STDERR "Error: data file not specified\nRun 'NetBuilder.pl -h' for help\n";
    exit 1;
}

$data_file = shift;
$detal = 13 if $detal == undef;
$size = 12000 if $size == undef;
$output_filename = 'picture.png' if $output_filename == undef;

# Создание изображения
print "Making image...";
$im = new GD::Image($size, $size);

# Назначение цветов
@Colors = (0, 0);
$Colors[0]  = $im->colorAllocate(255, 255, 255); # Белый
$Colors[1]  = $im->colorAllocate(0,   0,   0);   # Черный
$Colors[2]  = $im->colorAllocate(255, 0,   0);   # Красный
$Colors[3]  = $im->colorAllocate(181, 2,   0);   # Бордо
$Colors[4]  = $im->colorAllocate(0,   167, 255); # Голубой
$Colors[5]  = $im->colorAllocate(6,   5,   113); # Темно-синий
$Colors[6]  = $im->colorAllocate(0,   255, 0);   # Светло-зеленый
$Colors[7]  = $im->colorAllocate(17,  132, 17);  # Темно-зеленый
$Colors[8]  = $im->colorAllocate(139, 105, 20);  # Хаки
$Colors[9]  = $im->colorAllocate(88,  30,  0);   # Коричневый
$Colors[10] = $im->colorAllocate(160, 32,  240); # Сиреневый
$Colors[11] = $im->colorAllocate(255, 0,   255); # Фиолетовый
$Colors[12] = $im->colorAllocate(0,   0,   255); # Синий
$Colors[13] = $im->colorAllocate(0,   255, 255); # Циановый
$Colors[14] = $im->colorAllocate(255, 92,  88);  # Розовый
$Colors[15] = $im->colorAllocate(255, 0,   110); # Малиновый
$Colors[16] = $im->colorAllocate(255, 255, 0);   # Желтый
$Colors[17] = $im->colorAllocate(255, 132, 0);   # Оранжевый
$Colors[18] = $im->colorAllocate(191, 191, 191); # Светло-серый
$Colors[19] = $im->colorAllocate(77,  77,  77);  # Серый
$Colors[20] = $im->colorAllocate(140,  140,  140);  # Серый

# Делаем основание прозрачным и interlaced
$im->transparent($Colors[0]) if defined $transparent;
$im->interlaced('true') if defined $transparent;
$im->trueColor(1);

# Размер картинки
($w, $h) = $im->getBounds();

# Координаты центра
$centerx = $w/2;
$centery = $h/2;

# Загрузка файла данных
print "\nLoading data from file $data_file...";
open(DATA_FILE, "< $data_file") or die "\n    Can't open file $data_file: $!";
  while($string = <DATA_FILE>) {
    chomp($string);
    ($key, $value1, $value2, $value3) = split(/\t/, $string);
    @forms = split(/,/, $value2);
    @genes = split(/,/, $value3);
    if ($forms[0] == 1 && $nocancer == undef) {$forms[0] = 19;}
    else {$forms[0] = 2 + $forms[2];}
    $Genes{$key}->{Coord} = [0, 0, $forms[1], $forms[0], $forms[2]];
    if (@genes != undef) {
      $Genes{$key}->{$value1} = [@genes];
      foreach (@genes) {
        next if exists ($Genes{$_});
        $Genes{$_}->{Coord} = [0, 0, 2, 19, 13];
      }
    }
  }
close DATA_FILE;

# Число элементов
$elnum = 0;

# Назначение цветов
foreach $new1 (keys %Genes) {
  $elnum++;
  $c = 2;
  foreach $new2 (keys %{$Genes{$new1}}) {
    next if $new2 eq "Coord";
    push (@{${$Genes{$new1}}{$new2}}, $Colors[$c]);
    $c++;
  }
}

# Построение сети
print "\nBuilding gene network...";
$ret = MakeSubNet($centerx, $centery, $elnum, $detal);

# Запись картинки
if ($ret == 1) {
  print "\nWriting image to file $output_filename...";
  open(PICTURE, ">", $output_filename) or die ("Can't open file $output_filename for writing");
    binmode PICTURE;
    print PICTURE $im->png;
  close PICTURE;
  print "\n\n";
}
else {
  print "Error! Unable to build gene network!\n\n";
  sleep (1);
}
exit $ret;

##########################################
# Строит генную сеть из имеющихся данных
##########################################
sub MakeSubNet {
  # Координаты центров
  my $centerx = $_[0];
  my $centery = $_[1];
  
  # Число элементов
  my $elnum = $_[2];
  my %elnum;
  my @keys2 = (0, 0);
  
  # Уровень детализации
  my $detal = $_[3];
  my $d = undef;
  if ($detal == 5) {$d = 2;}
  elsif ($detal == 13) {$d = 4;}
  
  foreach $new1 (keys %Genes) {
    @keys2 = keys %{$Genes{$new1}};
    if ($#keys2 == 0) {$elnum{X}++;}
    else {
      foreach (0..$detal-1) {
        if ($Genes{$new1}->{Coord}->[$d] == $_) {$elnum{$_}++;}
      }
    }
  }
  
  # Прочие переменные
  my ($new1, $new2, $new3, $x, $y, $poly) = undef;
  
  if ($elnum != 0) {
    # Шаг поворота
    my $turn_step = (2*$pi/$elnum);
    
    # Радиус
    my $r = 6*$pi*$elnum;
  
    # Половина длины стороны квадрата
    my $half_length = sqrt(1.5*$r);
  
    # Координаты центров
    my $a = 0;
    my %a;
    my %Centers;
    foreach (0..$detal-1) {
      $Centers{$_} = [$r*cos($a) + $centerx, $r*sin($a) + $centery];
      $a += (2*$pi/$detal);
    }
    
    foreach $new1 (keys %Genes) {
      @keys2 = keys %{$Genes{$new1}};
      if ($#keys2 == 0) {
        $x = (8*$pi*$elnum{X})*cos($a{X}) + $centerx;
        $y = (8*$pi*$elnum{X})*sin($a{X}) + $centery;
        $a{X} += (2*$pi/$elnum{X});
      }
      else {
        foreach (0..$detal-1) {
        if ($Genes{$new1}->{Coord}->[$d] == $_) {
          $x = (6*$pi*$elnum{$_})*cos($a{$_}) + $Centers{$_}->[0];
          $y = (6*$pi*$elnum{$_})*sin($a{$_}) + $Centers{$_}->[1];
          $a{$_} += (2*$pi/$elnum{$_});
          }
        }
      }
      $Genes{$new1}->{Coord}->[0] = $x;
      $Genes{$new1}->{Coord}->[1] = $y;
    }

    # Построение линий
    foreach $new1 (keys %Genes) {
      foreach $new2 (keys %{$Genes{$new1}}) {
        next if $new2 eq "Coord";
        foreach $new3 (@{${$Genes{$new1}}{$new2}}) {
          next if $new3 =~ m/^\d/;
          if (($Genes{$new1}->{Coord}->[2] == $Genes{$new3}->{Coord}->[2]) && 
              ($Genes{$new1}->{Coord}->[3] == $Genes{$new3}->{Coord}->[3]) &&
              ($Genes{$new1}->{Coord}->[$d] == $Genes{$new3}->{Coord}->[$d])) {
            $im->dashedLine($Genes{$new1}->{Coord}->[0], $Genes{$new1}->{Coord}->[1], $Genes{$new3}->{Coord}->[0], $Genes{$new3}->{Coord}->[1], $Genes{$new1}->{Coord}->[3]);
          }
          else {
            $im->line($Genes{$new1}->{Coord}->[0], $Genes{$new1}->{Coord}->[1], $Genes{$new3}->{Coord}->[0], $Genes{$new3}->{Coord}->[1], $Genes{$new1}->{Coord}->[3]);
          }
        }
      }  
    }

    # Построение форм
    foreach $new1 (keys %Genes) {
      if ($Genes{$new1}->{Coord}->[4] == 1) {
        # Круги
        $im->filledArc($Genes{$new1}->{Coord}->[0], $Genes{$new1}->{Coord}->[1], $half_length, $half_length, 0, 360, $Genes{$new1}->{Coord}->[3]);
      }
      elsif ($Genes{$new1}->{Coord}->[4] == 2) {
        # Квадраты   
        $im->filledRectangle($Genes{$new1}->{Coord}->[0] - $half_length/2, $Genes{$new1}->{Coord}->[1] - $half_length/2, $Genes{$new1}->{Coord}->[0] + $half_length/2, $Genes{$new1}->{Coord}->[1] + $half_length/2, $Genes{$new1}->{Coord}->[3]);
      }
      elsif ($Genes{$new1}->{Coord}->[4] == 4) {
        # Треугольники
        $poly = new GD::Polygon;
        $poly->addPt($Genes{$new1}->{Coord}->[0], $Genes{$new1}->{Coord}->[1] - $half_length/2);
        $poly->addPt($Genes{$new1}->{Coord}->[0] + $half_length/2, $Genes{$new1}->{Coord}->[1] + $half_length/2);
        $poly->addPt($Genes{$new1}->{Coord}->[0] - $half_length/2, $Genes{$new1}->{Coord}->[1] + $half_length/2);
        $im->filledPolygon($poly, $Genes{$new1}->{Coord}->[3]);
      }
      elsif ($Genes{$new1}->{Coord}->[4] == 5) {
        # Перевернутые треугольники
        $poly = new GD::Polygon;
        $poly->addPt($Genes{$new1}->{Coord}->[0] - $half_length/2, $Genes{$new1}->{Coord}->[1] - $half_length/2);
        $poly->addPt($Genes{$new1}->{Coord}->[0] + $half_length/2, $Genes{$new1}->{Coord}->[1] - $half_length/2);
        $poly->addPt($Genes{$new1}->{Coord}->[0], $Genes{$new1}->{Coord}->[1] + $half_length/2);
        $im->filledPolygon($poly, $Genes{$new1}->{Coord}->[3]);
      }
      elsif ($Genes{$new1}->{Coord}->[4] == 6) {
        # Ромбы
        $poly = new GD::Polygon;
        $poly->addPt($Genes{$new1}->{Coord}->[0], $Genes{$new1}->{Coord}->[1] - $half_length/2);
        $poly->addPt($Genes{$new1}->{Coord}->[0] + $half_length/2, $Genes{$new1}->{Coord}->[1]);
        $poly->addPt($Genes{$new1}->{Coord}->[0], $Genes{$new1}->{Coord}->[1] + $half_length/2);
        $poly->addPt($Genes{$new1}->{Coord}->[0] - $half_length/2, $Genes{$new1}->{Coord}->[1]);
        $im->filledPolygon($poly, $Genes{$new1}->{Coord}->[3]);
      }
      elsif ($Genes{$new1}->{Coord}->[4] == 8) {
        # Пятиугольник
        $poly = new GD::Polygon;
        $poly->addPt($Genes{$new1}->{Coord}->[0],                  $Genes{$new1}->{Coord}->[1] - $half_length/2);
        $poly->addPt($Genes{$new1}->{Coord}->[0] + $half_length/2, $Genes{$new1}->{Coord}->[1]);
        $poly->addPt($Genes{$new1}->{Coord}->[0] + $half_length/4, $Genes{$new1}->{Coord}->[1] + $half_length/2);
        $poly->addPt($Genes{$new1}->{Coord}->[0] - $half_length/4, $Genes{$new1}->{Coord}->[1] + $half_length/2);
        $poly->addPt($Genes{$new1}->{Coord}->[0] - $half_length/2, $Genes{$new1}->{Coord}->[1]);
        $im->filledPolygon($poly, $Genes{$new1}->{Coord}->[3]);
      }
      elsif ($Genes{$new1}->{Coord}->[4] == 9) {
        # Шестиугольник
        $poly = new GD::Polygon;
        $poly->addPt($Genes{$new1}->{Coord}->[0],                  $Genes{$new1}->{Coord}->[1] - $half_length/2);
        $poly->addPt($Genes{$new1}->{Coord}->[0] + $half_length/4, $Genes{$new1}->{Coord}->[1] - $half_length/4);
        $poly->addPt($Genes{$new1}->{Coord}->[0] + $half_length/4, $Genes{$new1}->{Coord}->[1] + $half_length/4);
        $poly->addPt($Genes{$new1}->{Coord}->[0],                  $Genes{$new1}->{Coord}->[1] + $half_length/2);
        $poly->addPt($Genes{$new1}->{Coord}->[0] - $half_length/4, $Genes{$new1}->{Coord}->[1] + $half_length/4);
        $poly->addPt($Genes{$new1}->{Coord}->[0] - $half_length/4, $Genes{$new1}->{Coord}->[1] - $half_length/4);
        $im->filledPolygon($poly, $Genes{$new1}->{Coord}->[3]);
      }
      elsif ($Genes{$new1}->{Coord}->[4] == 10) {
        # Прямоугольник
        $poly = new GD::Polygon;
        $poly->addPt($Genes{$new1}->{Coord}->[0] + $half_length/2, $Genes{$new1}->{Coord}->[1] - $half_length/4);
        $poly->addPt($Genes{$new1}->{Coord}->[0] + $half_length/2, $Genes{$new1}->{Coord}->[1] + $half_length/4);
        $poly->addPt($Genes{$new1}->{Coord}->[0] - $half_length/2, $Genes{$new1}->{Coord}->[1] + $half_length/4);
        $poly->addPt($Genes{$new1}->{Coord}->[0] - $half_length/2, $Genes{$new1}->{Coord}->[1] - $half_length/4);
        $im->filledPolygon($poly, $Genes{$new1}->{Coord}->[3]);
      }
      elsif ($Genes{$new1}->{Coord}->[4] == 11) {
        # Перевернутый прямоугольник
        $poly = new GD::Polygon;
        $poly->addPt($Genes{$new1}->{Coord}->[0] + $half_length/4, $Genes{$new1}->{Coord}->[1] - $half_length/2);
        $poly->addPt($Genes{$new1}->{Coord}->[0] + $half_length/4, $Genes{$new1}->{Coord}->[1] + $half_length/2);
        $poly->addPt($Genes{$new1}->{Coord}->[0] - $half_length/4, $Genes{$new1}->{Coord}->[1] + $half_length/2);
        $poly->addPt($Genes{$new1}->{Coord}->[0] - $half_length/4, $Genes{$new1}->{Coord}->[1] - $half_length/2);
        $im->filledPolygon($poly, $Genes{$new1}->{Coord}->[3]);
      }
    }

    # Вписывание текста в формы
    foreach $new1 (keys %Genes) {
      $im->string(GD::Font->Large, $Genes{$new1}->{Coord}->[0] - 16, $Genes{$new1}->{Coord}->[1] + 18, "$new1", $Colors[1]);;
    }
  
    return 1;
  }
  else {
    return 0;
  }
}

##########################################
# Выводит справку и версию
##########################################
sub Usage_Version ($) {
    if ($_[0] eq "version") {
      print "\nGeneNet Builder 0.13.1\n";
      print "By Charles Malaheenee (C) 2010\n";
      print "Almaty, Kazakhstan\n\n";
    }
    elsif ($_[0] eq "help") {
      print "\nUsage: NetBuilder.pl [options] file\n\n";
      print "Options:\n";
      print "-v, --version - print version\n";
      print "-h, --help - print this help text\n";
      print "-d, --detail=<detalisation> - detalisation for building, may be 5 or 13 (defaults to 13)\n";
      print "-o, --output=<output filename> - output file name (defaults to picture,png)\n";
      print "-s, --size=<image size> - image size (defaults to 12000)\n";
      print "-t, --transparent - transparent image (defaults no)\n";
      print "-n, --nocancer - do not show oncogenes by greycolor (defaults no)\n";
#      print "-c, --nocolor \t\t\t (defaults yes)\n";
#      print "-f, --noforms \t\t\t (defaults yes)\n";
      print "\nReport bugs to ", 'malaheenee@gmx.fr', "\n\n";
    }
    exit 0;
}
