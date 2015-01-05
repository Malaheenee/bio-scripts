#! /usr/bin/perl

#perl2exe_info FileDescription=Program for calculating & extracting genes
#perl2exe_info FileVersion=4.0.2.0025
#perl2exe_info CompanyName=Charles Malaheenee
#perl2exe_info ProductName=Arabella Extractor 2007
#perl2exe_info ProductVersion=4.0.2.0025
#perl2exe_info InternalName=NUCLEOTIDE SEQUENCE EXTRACTOR
#perl2exe_info LegalCopyright=Copyright © 2004-2009 Charles Malaheenee.  All right reserved.
#perl2exe_info LegalTrademarks=Extractor from Charles Malaheenee
#perl2exe_info OriginalFilename=EXTRACTOR_402_0025.exe

use Cwd;
use Spreadsheet::WriteExcel;
use Win32::GUI qw(CW_USEDEFAULT CSIDL_PERSONAL WS_EX_CLIENTEDGE WS_CLIPCHILDREN WS_POPUP WS_CAPTION WS_THICKFRAME WS_EX_TOPMOST MB_USERICON MB_ICONINFORMATION MB_ICONQUESTION MB_ICONWARNING MB_ICONERROR MB_OK);
use Win32::GUI::Grid;
use Arabella::Icons;

#perl2exe_include "Cwd.pm";
#perl2exe_include "Spreadsheet/WriteExcel.pm";
#perl2exe_include "Win32/GUI.pm";
#perl2exe_include "Win32/GUI/BitmapInline.pm";
#perl2exe_include "Win32/GUI/Grid.pm";
#perl2exe_include "Arabella/Icons.pm";

BEGIN
  {
########################################################
# Loading configuration form file (if this file exists)
########################################################
     %Configuration = (
     "Language"                => "Russian",
     "UseDefaultLanguage"      => "1",
     "Keyword"                 => "CDS",
     "ExonsDir"                => "Exons",
     "WithIntronsDir"          => "With Introns",
     "SEIDir"                  => "SEI",
     "StatisticDir"            => "Statistic",
     "CORW"                    => "0",
     "IntronsNumber"           => "0",
     "NumberOfSequence"        => "1",
     "UseExtension"            => "0",
     "Extension"               => "res",
     "OutputFileXLS"           => "All_data.xls",
     "NotCreateFileXLS"        => "1",
     "IntronGroups"            => "0, 1, 2, 3, 4, 5, 1-2, 1-5, 3-5, 6-9, 6-10, 10-14, 11-15, 11-, 15-, 16-",
     "DeleteTempFile"          => "0",
     "AllowedBrackets"         => "0",
     "GenBankFileFolder"       => cwd,
     "CalculateGenesQuantity"  => "0",
     "CalculateLength"         => "0",
     "ExtractExons"            => "0",
     "ExtractWithIntrons"      => "0",
     "ExtractSEI"              => "0",
     "ExtractUseFrame"         => "0",
     "ExtractFrame"            => "1000000",
     );

     my $ConfigurationFile = open(CONFIG_FILE, "< Settings-e.ini");
     if (defined $ConfigurationFile)
       {
          while (<CONFIG_FILE>)
            {
                chomp;
                s/#.*//;
                s/^\s+//;
                s/\s+$//;
                next unless length;
                my ($Feature, $Value) = split(/\s*=\s*/, $_, 2);
                $Configuration{$Feature} = $Value if exists $Configuration{$Feature};
            }
          close CONFIG_FILE;
       }

      foreach ("ExonsDir", "WithIntronsDir", "SEIDir", "StatisticDir")
        {
          $Configuration{$_} =~ s/\//\\/g;
          $Configuration{$_} .= "\\" if substr($Configuration{$_}, -1, 1) ne "\\";
          $Configuration{$_} =~ s/[\:\*\?\"\<\>\|]//g;
        }

      $Configuration{GenBankFileFolder} .= "\\" if substr($Configuration{GenBankFileFolder}, -1, 1) ne "\\";

      while (($k, $v) = each %Configuration) {$ConfigurationOriginal{$k} = $v;}

      sub TextFilesNames ($)
        {
           my $Groups = $_[0];
           $Groups =~ s/\s+//g;
           %TextFiles = ();
           $Groups =~ s/\s+//g;
           my @Sp;
           my @IntronGroups = split(/,/,  $Groups);
           foreach $IG (@IntronGroups)
             {
                splice @Sp , 0;
                if ($IG =~ m/-/)
                  {
                     @Sp = split(/-/, $IG);

                     foreach (@Sp)
                       {
                          $_ = ($_ * 2) + 1;
                       }
                
                     if (defined $Sp[1])
                       {
                          $TextFiles{$IG} = [$IG." introns.txt", $Sp[0], $Sp[1]];
                       }
                     else
                       {
                          # $IG =~ s/-$//;
                          $TextFiles{$IG} = [$IG." and more introns.txt", $Sp[0]];
                       }
                  }
                else
                  {
                     $TextFiles{$IG} = [$IG." introns.txt", (($IG * 2) + 1)] if $IG != 0;
                     $TextFiles{Without} = ["Without introns.txt", (($IG * 2) + 1)] if $IG == 0;
                  }
             }
           $TextFiles{Length} = ("All_introns.txt");
         }
    TextFilesNames($Configuration{IntronGroups});

#############################################################
# Loading interface Language form file (if this file exists)
#############################################################
     %Language = (
     "WINDOW_Main"                 => "",
       "Keyword"                   => "Искать:",
       "GenBankFileFolder"         => "Папка:",
         "GenBankFileFolderBrowse" => "Обзор...",
       "Calculate"                 => "Посчитать",
         "CalculateLength"         => "Посчитать длину экзонов и интронов",
         "CalculateGenesQuantity"  => "Посчитать число генов",
       "Extract"                   => "Вырезать",
         "ExtractExons"            => "Вырезать гены без интронов",
         "ExtractWithIntrons"      => "Вырезать гены с интронами", 
         "ExtractSEI"              => "Вырезать отдельно экзоны и интроны",
         "ExtractUseFrame"         => "Использовать рамку",
       "Convert"                   => "Сделать",
       "Stop"                      => "Стоп",
       "SaveLog"                   => "Сохранить отчет",
       "Options"                   => "Настройки",
       "Help"                      => "Помощь",
       "About"                     => "О программе...",
       "Exit"                      => "Выход",
       "FileWork"                  => "Обработка файла",
       "KeyWork"                   => "Обработка",
       "UnableToSaveReportFile"    => "Невозможно сохранить файл отчета:",
       "UnableOpenOrCreateFile"    => "Невозможно открыть или создать файл",
       "GenBankFiles"              => "Файлы GenBank",
       "AllFiles"                  => "Все файлы",
       "TextFiles"                 => "Текстовые файлы",
       "SelectReportFile"          => "Выберите файл отчета",
       "SelectGenBankFileFolder"   => "Выберите папку с файлами GenBank",
       "PleaseWait"                => "Это может занять несколько минут. Пожалуйста, подождите...",
       "Searching"                 => "Поиск",
       "FilesGenBank"              => "файл(ов) GenBank.",
       "OpeningFile"               => "Открытие файла",
       "DefineFileFirst"           => "Сначала укажите файл!",
       "SearchingGenBankFiles"     => "Поиск файлов GBK в папке",
       "DefineFolderFirst"         => "Сначала укажите папку!",
       "Keyword2"                  => "Ключевое слово:",
       "Keyword3"                  => "ключевое слово",
       "AllowedWords"              => "Разрешенные слова: CDS, mRNA, tRNA, rRNA, gene, misc_feature, exon, intron, STS и т.д.",
       "BadKeyword"                => "Неверное ключевое слово для поиска:",
       "ExtractFrame"              => "Рамка для вырезания и подсчета:",
       "BadExtractFrame"           => "Неверная рамка для вырезания и подсчета:",
       "SelectedActions"           => "Выбраны действия:",
       "SelectActionFirst"         => "Сначала выберите действие - Посчитать или Вырезать!",
       "StartTime"                 => "Дата и время начала процесса:",
       "EndTime"                   => "Дата и время окончания процесса:",
       "InFile"                    => "В файле",
       "InFolder"                  => "В папке",
       "NotFound"                  => "не найдено!",
       "Founded"                   => "найдено",
       "Genes"                     => "генов",
       "And"                       => "и",
       "SuccesfullyProcessed"      => "успешно обработано",
       "UnableOpenFile"            => "Невозможно открыть файл",
     "WINDOW_About"                => "О программе...",
       "PacketVersion"             => "Входит в состав",
       "ModuleName"                => "Модуль",
       "ModuleVersion"             => "Версия",
     "WINDOW_Options"              => "Настройки",
       "LanguageSelect"            => "Выбор языка интерфейса",
         "Language"                => "Язык:",
         "UseDefaultLanguage"      => "Использовать язык по умолчанию",
       "Directories"               => "Имена папок",
         "ExonsDir"                => "Для генов без интронов:",
         "WithIntronsDir"          => "Для генов с интронами:",
         "SEIDir"                  => "Для отдельных экзонов и интронов:",
         "StatisticDir"            => "Для статистики:",
       "FormatSequenceName"        => "Включить в имя файла последовательности",
         "CORW"                    => "Комплементарность",
         "IntronsNumber"           => "Число интронов",
         "NumberOfSequence"        => "Порядковый номер",
         "UseExtension"            => "Расширение",
       "Other"                     => "Разное",
         "OutputFileXLS"           => "Имя файла Microsoft Excel",
         "NotCreateFileXLS"        => "Не создавать файл Microsoft Excel",
         "IntronGroups"            => "Группы интронов",
         "DeleteTempFile"          => "Удалять временные файлы",
         "AllowedBrackets"         => "Обрабатывать гены со значком < или >",
       "ButtonOK"                  => "OK",
       "ButtonCancel"              => "Отмена",
     "WINDOW_Attention"            => "Внимание",
     "WINDOW_Done",                => "Выполнено",
     "WINDOW_Error"                => "Ошибка",
       "UnableSaveConfigFile"      => "Невозможно сохранить файл конфигурации:",
     );

      while (my ($k, $v) = each %Language) {$DefaultLanguage{$k} = $v;}

      sub LoadLanguageFile ($)
        {
           if ($Configuration{UseDefaultLanguage} == 1)
             {
                %Language = %DefaultLanguage;
             }
           else
             {
             my $LanguageFile = open(LANG_FILE, "< ./Language/$_[0].lng");
                if (defined $LanguageFile)
                  {
                     while (<LANG_FILE>)
                       {
                          chomp;
                          s/#.*//;
                          s/^\s+//;
                          s/\s+$//;
                          next unless length;
                          ($Feature, $Value) = split(/\s*=\s*/, $_, 2);
                          $Language{$Feature} = $Value if exists $Language{$Feature};
                       }
                     close LANG_FILE;
                  }
             }
        }
      LoadLanguageFile($Configuration{Language});
  }

# sub Calculator (@);
# sub CalculateGenesQuantity ($$$);
# sub CalculatorWrite2 ($$$$@);
# sub Complement (@);
# sub ExtractExons (@);
# sub ExtractSEI ($$$$$);
# sub ExtractWithIntrons (@);
# sub MakeTemp ($$);
# sub TextFilesNames ($);

my $temp_dir = ( $ENV{TEMP} || $ENV{TMP} || $ENV{WINDIR} || "/tmp" ) . "/p2xtmp-$$";

my $NAME    = "Arabella Extractor 2007";
my $VERSION = "4.0.2";
my $BUILD   = "0025";
my $PACKET  = "Arabella Nucleotide Analyzing Suite 2007";

my $MainWin = Win32::GUI::Window->new(
      -title       => $NAME,
      -left        => CW_USEDEFAULT,
      -size        => [615, 425],
      -minsize     => [615, 425],
      -maximizebox => 0,
      -resizable   => 0,
      -dialogui    => 1,
      -onResize    => \&MainWinResize,
      -onTerminate => \&Exit,
);
$MainWin->SetIcon($MainIconExtractor);

$MainWin->AddTextfield(
   -name    => "Keyword",
   -text    => $Configuration{Keyword},
   -prompt  => [$Language{Keyword}, 50],
   -pos     => [5, 5],
   -size    => [135, 25],
   -tabstop => 1,
);

$MainWin->AddTextfield(
   -name     => "GenBankFileFolder",
   -text     => $Configuration{GenBankFileFolder},
   -prompt   => [$Language{GenBankFileFolder}, 40],
   -pos      => [200, 5],
   -size     => [175, 25],
   -tabstop  => 1,
);

$MainWin->AddButton (
   -name     => "GenBankFileFolderBrowse",
   -pos      => [420, 5],
   -size     => [70, 25],
   -text     => $Language{GenBankFileFolderBrowse},
   -onClick  => sub{$Configuration{GenBankFileFolder} = SelectDir($Configuration{GenBankFileFolder});
                    $MainWin->GenBankFileFolder->Text($Configuration{GenBankFileFolder});},
   -tabstop  => 1,
);

$MainWin->AddGroupbox(
   -name  => "Calculate",
   -title => $Language{Calculate},
   -pos   => [5, 33],
   -size  => [240, 64],
   -group => 1,
);

$MainWin->AddCheckbox(
   -name    => "CalculateGenesQuantity",
   -text    => $Language{CalculateGenesQuantity},
   -pos     => [15, 49],
   -size    => [220, 20],
   -onClick => sub {$Configuration{CalculateGenesQuantity} = $_[0]->GetCheck();},
   -tabstop => 1,
   -checked => $Configuration{CalculateGenesQuantity},
);

$MainWin->AddCheckbox(
   -name    => "CalculateLength",
   -text    => $Language{CalculateLength},
   -pos     => [15, 71],
   -size    => [220, 20],
   -onClick => sub {$Configuration{CalculateLength} = $_[0]->GetCheck();},
   -tabstop => 1,
   -checked => $Configuration{CalculateLength},
);

 $MainWin->AddCheckbox(
   -name    => "ExtractUseFrame",
   -text    => $Language{ExtractUseFrame},
   -pos     => [15, 98],
   -size    => [130, 20],
   -onClick => sub {$Configuration{ExtractUseFrame} = my $check_status = $_[0]->GetCheck();
                    if ($check_status == 1) {$MainWin->ExtractFrame->Enable();}
                    if ($check_status == 0) {$MainWin->ExtractFrame->Disable();}},
   -tabstop => 1,
   -checked => $Configuration{ExtractUseFrame},
 );

 $MainWin->AddTextfield(
   -name     => "ExtractFrame",
   -text     => $Configuration{ExtractFrame},
   -pos      => [145, 98],
   -size     => [90, 20],
   -tabstop  => 1,
   -number   => 1,
   -onChange => sub {$Configuration{ExtractFrame} = $_[0]->Text()},
   -disabled => (1 - $Configuration{ExtractUseFrame}),
 );

$MainWin->AddGroupbox(
   -name  => "Extract",
   -title => $Language{Extract},
   -pos   => [250, 33],
   -size  => [240, 83],
   -group => 1,
);

$MainWin->AddCheckbox(
   -name    => "ExtractExons",
   -text    => $Language{ExtractExons},
   -pos     => [260, 49],
   -size    => [220, 20],
   -onClick => sub {$Configuration{ExtractExons} = $_[0]->GetCheck()},
   -tabstop => 1,
   -checked => $Configuration{ExtractExons},
);

$MainWin->AddCheckbox(
   -name    => "ExtractWithIntrons",
   -text    => $Language{ExtractWithIntrons},
   -pos     => [260, 71],
   -size    => [220, 20],
   -onClick => sub {$Configuration{ExtractWithIntrons} = $_[0]->GetCheck()},
   -tabstop => 1,
   -checked => $Configuration{ExtractWithIntrons},
);

$MainWin->AddCheckbox(
   -name    => "ExtractSEI",
   -text    => $Language{ExtractSEI},
   -pos     => [260, 93],
   -size    => [220, 20],
   -onClick => sub {$Configuration{ExtractSEI} = $_[0]->GetCheck();},
   -tabstop => 1,
   -checked => $Configuration{ExtractSEI},
);

$MainWin->AddTextfield(
   -name       => "LogFile",
   -pos        => [5, 120],
   -size       => [485, 195],
   -multiline  => 1,
   -vscroll    => 1,
   -readonly   => 1,
   -background => 0xFFFFFF,
   -tabstop    => 1,
   -group      => 1,
);

$MainWin->AddButton (
   -name    => "Convert",
   -pos     => [495, 5],
   -size    => [110, 40],
   -text    => $Language{Convert},
   -onClick => \&Convert,
   -ok      => 1,
   -tabstop => 1,
   -default => 1,
);

$MainWin->AddButton (
   -name    => "SaveLog",
   -pos     => [495, 45],
   -size    => [110, 40],
   -text    => $Language{SaveLog},
   -onClick => \&LogSave,
   -tabstop => 1,
);

$MainWin->AddButton (
   -name    => "Options",
   -pos     => [495, 85],
   -size    => [110, 40],
   -text    => $Language{Options},
   -onClick => \&Options,
   -tabstop => 1,
);

$MainWin->AddButton (
   -name    => "Help",
   -pos     => [495, 265],
   -size    => [110, 40],
   -text    => $Language{Help},
   -onClick => \&LogWrite,
   -tabstop => 1,
   -disabled => 1,
);

$MainWin->AddButton (
   -name    => "About",
   -pos     => [495, 305],
   -size    => [110, 40],
   -text    => $Language{About},
   -onClick => \&About,
   -tabstop => 1,
);

$MainWin->AddButton (
   -name    => "Exit",
   -pos     => [495, 345],
   -size    => [110, 40],
   -text    => $Language{Exit},
   -onClick => \&Exit,
   -cancel  => 1,
   -tabstop => 1,
);

$MainWin->AddLabel(
    -name => "FileWork",
    -text => " ",
    -pos  => [5, 315],
    -size => [485, 15],
);

$MainWin->AddProgressBar (
   -name   => "ProgressFile",
   -pos    => [5, 330],
   -size   => [485, 20],
   -smooth => 1,
);

$MainWin->AddLabel(
    -name => "KeyWork",
    -text => " ",
    -pos  => [5, 350],
    -size => [485, 15],
);

$MainWin->AddProgressBar (
   -name   => "ProgressCopy",
   -pos    => [5, 365],
   -size   => [485, 20],
   -smooth => 1,
);

$MainWin->ProgressFile->SetStep(1);
$MainWin->ProgressCopy->SetStep(1);

$MainWin->Show();
Win32::GUI::Dialog();

########################################################
#
########################################################
sub MainWinResize {
    if (defined $MainWin) {
        my ($width, $height) = ($MainWin->GetClientRect)[2..3];

#			$MainWin->{Client}->Move(0, $MainWin->{ToolBar}->Height());
#			$MainWin->{Client}->Resize($width, ($height - $MainWin->{StatusBar}->Height() - $MainWin->{ToolBar}->Height()));
#			$MainWin->{StatusBar}->Move(0, ($height - $MainWin->{StatusBar}->Height()));
#	        $MainWin->{StatusBar}->Resize($width, $MainWin->{StatusBar}->Height());
#	        $MainWin->{StatusBar}->Text("Window size: ".$width."x".$height." StatusBar size: ".$MainWin->{StatusBar}->Width()."x".$MainWin->{StatusBar}->Height());
    }
	return 0;
}

########################################################
# 
########################################################
sub About
  {
    my $self = shift;

    my ($iwidth,$iheight) = $AboutPicExtractor->Info();

    my $AboutWin = new Win32::GUI::Window (
         -parent      => $self,
         -name        => "WINDOW_About",
         -text        => $Language{WINDOW_About},
         -size        => [405, 280],
         -left        => 100, 
         -top         => 100,
         -maximizebox => 0,
         -minimizebox => 0,
         -resizable   => 0,
         -addstyle    => WS_POPUP,
         -onClick     => sub {-1;},
       );
       $AboutWin->SetIcon($AboutIcon);
   
    my $width = $AboutWin->ScaleWidth();
    my $height = $AboutWin->ScaleHeight();

       $AboutWin->AddLabel(
         -name   => "Bitmap",
         -pos    => [5, 5],
         -size   => [$iwidth, $iheight],
         -bitmap => $AboutPicExtractor,
         -sunken => 1,
       );  
 
       $AboutWin->AddLabel(
         -name => "Name",
         -text => "$NAME ($VERSION.$BUILD)",
         -pos  => [$iwidth + 10, 5],
       );

       $AboutWin->AddLabel(
         -name => "PacketVersion",
         -text => "$Language{PacketVersion} $PACKET",
         -pos  => [$iwidth + 10, 22],
       );

       $AboutWin->AddLabel(
         -name => "TAI",
         -text => "© Timour Ivashchenko, 2001 $Language{And} © Charles Malaheenee, 2009",
         -pos  => [$iwidth + 10, 39],
       );

       $AboutWin->AddGrid (
         -name         => "ModulesInfo",
         -pos          => [$iwidth + 10, 60],
         -size         => [$width - $iwidth - 15, 157],
         -vscroll      => 1,
         -hscroll      => 1,
         -autovscroll  => 1,
         -autohscroll  => 1,
         -rows         => 8,
         -columns      => 2,
         -fixedrows    => 0,
         -fixedcolumns => 0,
         -editable     => 0,
       );
       $AboutWin->ModulesInfo->ExpandColumnsToFit();
       $AboutWin->ModulesInfo->SetCellText (0, 0, $Language{ModuleName});
       $AboutWin->ModulesInfo->SetCellText (0, 1, $Language{ModuleVersion});
       $AboutWin->ModulesInfo->SetCellText (1, 0, "Arabella::Icons");
       $AboutWin->ModulesInfo->SetCellText (1, 1, $Arabella::Icons::VERSION);
       $AboutWin->ModulesInfo->SetCellText (2, 0, "Cwd");
       $AboutWin->ModulesInfo->SetCellText (2, 1, $Cwd::VERSION);
       $AboutWin->ModulesInfo->SetCellText (3, 0, "Spreadsheet::WriteExcel");
       $AboutWin->ModulesInfo->SetCellText (3, 1, $Spreadsheet::WriteExcel::VERSION);
       $AboutWin->ModulesInfo->SetCellText (4, 0, "Win32::GUI");
       $AboutWin->ModulesInfo->SetCellText (4, 1, $Win32::GUI::VERSION);
       $AboutWin->ModulesInfo->SetCellText (5, 0, "Win32::GUI::Grid");
       $AboutWin->ModulesInfo->SetCellText (5, 1, $Win32::GUI::Grid::VERSION);

       $AboutWin->AddButton(
       -name    => "ButtonOK",
       -text    => "OK",
       -size    => [90, 25],
       -pos     => [$width - 90 - 5, $iheight + 10],
       -ok      => 1,
       -default => 1,
       -onClick => sub {-1;},
       -tabstop => 1,
       );
   
       $AboutWin->Center();
       $AboutWin->DoModal();
       0;
  }

########################################################
# 
########################################################
sub Options
  {
     my $ParentWin = shift;

     my $Language           = $Configuration{Language};
     my $UseDefaultLanguage = $Configuration{UseDefaultLanguage};
     my $ExonsDir           = $Configuration{ExonsDir};
     my $WithIntronsDir     = $Configuration{WithIntronsDir};
     my $SEIDir             = $Configuration{SEIDir};
     my $StatisticDir       = $Configuration{StatisticDir};
     my $OutputFileXLS      = $Configuration{OutputFileXLS};
     my $NotCreateFileXLS   = $Configuration{NotCreateFileXLS};
     my $IntronGroups       = $Configuration{IntronGroups};
     my $DeleteTempFile     = $Configuration{DeleteTempFile};
     my $AllowedBrackets    = $Configuration{AllowedBrackets};
     my $CORW               = $Configuration{CORW};
     my $IntronsNumber      = $Configuration{IntronsNumber};
     my $NumberOfSequence   = $Configuration{NumberOfSequence};
     my $UseExtension       = $Configuration{UseExtension};
     my $Extension          = $Configuration{Extension};
 
     my $OptionWin = Win32::GUI::DialogBox->new(
          -parent      => $ParentWin,
          -title       => $Language{WINDOW_Options},
          -left        => CW_USEDEFAULT,
          -size        => [385, 416],
          -maximizebox => 0,
          -minimizebox => 0,
          -resizable   => 0,
          -dialogui    => 1,
        );
        $OptionWin->SetIcon($SettingsIcon);

        $OptionWin->AddGroupbox(
          -name  => "LanguageSelect",
          -title => $Language{LanguageSelect},
          -pos   => [5, 5],
          -size  => [370, 50],
          -group => 1,
        );

        $OptionWin->AddLabel(
          -name => "Language",
          -text => $Language{Language},
          -pos  => [15, 28],
          -size => [65, 20],
        );

        $OptionWin->AddCheckbox(
          -name    => "UseDefaultLanguage",
          -text    => $Language{UseDefaultLanguage},
          -pos     => [180, 25],
          -size    => [185, 20],
          -onClick => sub {$UseDefaultLanguage = my $check_status = $_[0]->GetCheck();
                           if ($check_status == 0) {$OptionWin->LanguageSelectCB->Enable()};
                           if ($check_status == 1) {$OptionWin->LanguageSelectCB->Disable()};},
          -tabstop => 1,
          -checked => $UseDefaultLanguage,
        );

        $OptionWin->AddCombobox(
          -name         => "LanguageSelectCB",
          -dropdownlist => 1,
          -vscroll      => 1,
          -pos          => [70, 25],
          -size         => [100, 100],
          -onChange     => sub {$Language = $_[0]->Text();},
          -tabstop      => 1,
          -disabled     => $UseDefaultLanguage,
        );

        opendir(LANG_DIR, "./Language/");
          my @LanguagesFiles = grep {/lng/i} readdir(LANG_DIR);
        closedir(LANG_DIR);

        foreach (@LanguagesFiles) {$_ =~ s/\.lng//g;}

        $OptionWin->LanguageSelectCB->Add(@LanguagesFiles);
        $OptionWin->LanguageSelectCB->SetCurSel(0);

        $OptionWin->AddGroupbox(
          -name  => "Directories",
          -title => $Language{Directories},
          -pos   => [5, 55],
          -size  => [370, 108],
          -group => 1,
        );

        $OptionWin->AddTextfield(
          -name    => "ExonsDir",
          -text    => $ExonsDir,
          -prompt  => [$Language{ExonsDir}, 130],
          -pos     => [15, 70],
          -size    => [220, 20],
          -tabstop => 1,
        );

        $OptionWin->AddTextfield(
          -name    => "WithIntronsDir",
          -text    => $WithIntronsDir,
          -prompt  => [$Language{WithIntronsDir}, 130],
          -pos     => [15, 92],
          -size    => [220, 20],
          -tabstop => 1,
        );

        $OptionWin->AddTextfield(
          -name    => "SEIDir",
          -text    => $SEIDir,
          -prompt  => [$Language{SEIDir}, 185],
          -pos     => [15, 114],
          -size    => [165, 20],
          -tabstop => 1,
        );

        $OptionWin->AddTextfield(
          -name    => "StatisticDir",
          -text    => $StatisticDir,
          -prompt  => [$Language{StatisticDir}, 90],
          -pos     => [15, 136],
          -size    => [260, 20],
          -tabstop => 1,
        );
 
        $OptionWin->AddGroupbox(
          -name  => "FormatSequenceName",
          -title => $Language{FormatSequenceName},
          -pos   => [5, 163],
          -size  => [370, 65],
          -group => 1,
        );

        $OptionWin->AddCheckbox(
          -name    => "CORW",
          -text    => $Language{CORW},
          -pos     => [15, 175],
          -size    => [130, 26],
          -onClick => sub {$CORW = $_[0]->GetCheck();},
          -tabstop => 1,
          -checked => $CORW,
        );

        $OptionWin->AddCheckbox(
          -name    => "IntronsNumber",
          -text    => $Language{IntronsNumber},
          -pos     => [145, 175],
          -size    => [105, 26],
          -onClick => sub {$IntronsNumber = $_[0]->GetCheck();},
          -tabstop => 1,
          -checked => $IntronsNumber,
        );

        $OptionWin->AddCheckbox(
          -name    => "NumberOfSequence",
          -text    => $Language{NumberOfSequence},
          -pos     => [250, 175],
          -size    => [120, 26],
          -onClick => sub {$NumberOfSequence = $_[0]->GetCheck();},
          -tabstop => 1,
          -checked => $NumberOfSequence,
        );
 
        $OptionWin->AddCheckbox(
          -name    => "UseExtension",
          -text    => $Language{UseExtension},
          -pos     => [15, 202],
          -size    => [90, 20],
          -onClick => sub {$UseExtension = my $check_status = $_[0]->GetCheck();
                    if ($check_status == 1) {$OptionWin->Extension->Enable();}
                    if ($check_status == 0) {$OptionWin->Extension->Disable();}},
          -tabstop => 1,
          -checked => $UseExtension,
        );

        $OptionWin->AddTextfield(
          -name     => "Extension",
          -text     => $Extension,
          -pos      => [105, 202],
          -size     => [70, 20],
          -tabstop  => 1,
          -disabled => (1 - $UseExtension),
        );

        $OptionWin->AddGroupbox(
          -name  => "Other",
          -title => $Language{Other},
          -pos   => [5, 228],
          -size  => [370, 125],
          -group => 1,
        );

        $OptionWin->AddTextfield(
          -name    => "IntronGroups",
          -text    => $IntronGroups,
          -prompt  => [$Language{IntronGroups}, 100],
          -pos     => [15, 243],
          -size    => [250, 20],
          -tabstop => 1,
        );

        $OptionWin->AddTextfield(
          -name     => "OutputFileXLS",
          -text     => $OutputFileXLS,
          -prompt   => [$Language{OutputFileXLS}, 140],
          -pos      => [15, 265],
          -size     => [210, 20],
          -tabstop  => 1,
          -disabled => $Configuration{NotCreateFileXLS},
        );

        $OptionWin->AddCheckbox(
          -name    => "NotCreateFileXLS",
          -text    => $Language{NotCreateFileXLS},
          -pos     => [15, 285],
          -size    => [250, 20],
          -onClick => sub {$NotCreateFileXLS = my $check_status = $_[0]->GetCheck();
                           if ($check_status == 0) {$OptionWin->OutputFileXLS->Enable()};
                           if ($check_status == 1) {$OptionWin->OutputFileXLS->Disable()};},
          -tabstop => 1,
          -checked => $NotCreateFileXLS,
        );

        $OptionWin->AddCheckbox(
          -name     => "DeleteTempFile",
          -text     => $Language{DeleteTempFile},
          -pos      => [15, 307],
          -size     => [250, 20],
          -onClick  => sub {$DeleteTempFile = $_[0]->GetCheck();},
          -tabstop  => 1,
          -checked  => $DeleteTempFile,
        );

        $OptionWin->AddCheckbox(
          -name     => "AllowedBrackets",
          -text     => $Language{AllowedBrackets},
          -pos      => [15, 329],
          -size     => [250, 20],
          -onClick  => sub {$AllowedBrackets = $_[0]->GetCheck();},
          -tabstop  => 1,
          -checked  => $AllowedBrackets,
        );

        $OptionWin->AddButton(
          -name    => "ButtonOK",
          -text    => $Language{ButtonOK},
          -pos     => [195, 356],
          -size    => [90, 25],
          -ok  => 1,
          -default => 1,
          -onClick => sub {
                          my $Text_IntronGroups = $OptionWin->IntronGroups->Text();
                          my $Text_ExonsDir = $OptionWin->ExonsDir->Text();
                          my $Text_WithIntronsDir = $OptionWin->WithIntronsDir->Text();
                          my $Text_SEIDir = $OptionWin->SEIDir->Text();
                          my $Text_StatisticDir = $OptionWin->StatisticDir->Text();
                          my $Text_OutputFileXLS = $OptionWin->OutputFileXLS->Text();
                          my $Text_Extension = $OptionWin->Extension->Text();

                          $Text_IntronGroups =~ s/[\\\/\:\*\?\"\<\>\|]/N/g;
                          $Text_ExonsDir =~ s/[\:\*\?\"\<\>\|]/N/g;
                          $Text_WithIntronsDir =~ s/\:[\*\?\"\<\>\|]/N/g;
                          $Text_SEIDir =~ s/[\:\*\?\"\<\>\|]/N/g;
                          $Text_StatisticDir =~ s/[\:\*\?\"\<\>\|]/N/g;
                          $Text_OutputFileXLS =~ s/[\\\/\:\*\?\"\<\>\|]/N/g;
                          $Text_Extension =~ s/[\\\/\:\*\?\"\<\>\|]/N/g;

                          $IntronGroups = $Text_IntronGroups if $IntronGroups ne $Text_IntronGroups;
                          $ExonsDir = $Text_ExonsDir if $ExonsDir ne $Text_ExonsDir;
                          $WithIntronsDir = $Text_WithIntronsDir if $WithIntronsDir ne $Text_WithIntronsDir;
                          $SEIDir = $Text_SEIDir if $SEIDir ne $Text_SEIDirt;
                          $StatisticDir = $Text_StatisticDir if $StatisticDir ne $Text_StatisticDir;
                          $OutputFileXLS = $Text_OutputFileXLS if $OutputFileXLS ne $Text_OutputFileXLS;
                          $Extension = $Text_Extension if $Extension ne $Text_Extension;

                          $ExonsDir =~ s/\//\\/g;
                          $ExonsDir .= "\\" if substr($ExonsDir, -1, 1) ne "\\" ;

                          $WithIntronsDir =~ s/\//\\/g;
                          $WithIntronsDir .= "\\" if substr($WithIntronsDir, -1, 1) ne "\\";

                          $SEIDir =~ s/\//\\/g;
                          $SEIDir .= "\\" if substr($SEIDir, -1, 1) ne "\\";

                          $StatisticDir =~ s/\//\\/g;
                          $StatisticDir .= "\\" if substr($StatisticDir, -1, 1) ne "\\";

                          $Configuration{Language}           = $Language;
                          $Configuration{UseDefaultLanguage} = $UseDefaultLanguage;
                          $Configuration{ExonsDir}           = $ExonsDir;
                          $Configuration{WithIntronsDir}     = $WithIntronsDir;
                          $Configuration{SEIDir}             = $SEIDir;
                          $Configuration{StatisticDir}       = $StatisticDir;
                          $Configuration{OutputFileXLS}      = $OutputFileXLS;
                          $Configuration{NotCreateFileXLS}   = $NotCreateFileXLS;
                          $Configuration{IntronGroups}       = $IntronGroups;
                          $Configuration{DeleteTempFile}     = $DeleteTempFile;
                          $Configuration{AllowedBrackets}    = $AllowedBrackets;
                          $Configuration{CORW}               = $CORW;
                          $Configuration{IntronsNumber}      = $IntronsNumber;
                          $Configuration{NumberOfSequence}   = $NumberOfSequence;
                          $Configuration{UseExtension}       = $UseExtension;
                          $Configuration{Extension}          = $Extension;
                          
                          LoadLanguageFile($Language);
                          TextFilesNames($IntronGroups);

                         # my ($k, $v);
                         # print %Language;
                         # while (($k, $v) = each (%Language))
                         #  {
                         #     print "Key $k, Value $v, ";
                         #     if (defined $MainWin->$k)
                         #       {
                         #          print $MainWin->$k, "\n";
                         #          $MainWin->$k->Text($v);
                         #       }
                         #  }

                          $MainWin->Keyword_Prompt->Text($Language{Keyword});
						  $MainWin->GenBankFileFolder_Prompt->Text($Language{GenBankFileFolder});
						  foreach ("GenBankFileFolderBrowse", "Calculate", "CalculateGenesQuantity",
							 "CalculateLength", "ExtractUseFrame", "Extract", "ExtractExons", "ExtractWithIntrons", "ExtractSEI",
							 "Convert", "SaveLog", "Options", "Help", "About", "Exit")
							 {$MainWin->$_->Text($Language{$_});}
                          -1;},
          -tabstop => 1,
        );

        $OptionWin->AddButton(
          -name    => "ButtonCancel",
          -text    => $Language{ButtonCancel},
          -pos     => [285, 356],
          -size    => [90, 25],
          -cancel  => 1,
          -onClick => sub {-1;},
          -tabstop => 1,
        );

    $OptionWin->Center();
    $OptionWin->DoModal();
    return 1;
}

########################################################
# 
########################################################
sub SelectDir
  {
     my $CurDir = shift;
     my $ReturnDir = $CurDir;
     my $RetDir = Win32::GUI::BrowseForFolder (
         -title      => $Language{SelectGenBankFileFolder},
         -directory  => $CurDir,
         -folderonly => 1,
         -editbox => 1,
     );

     $ReturnDir = $RetDir if defined $RetDir ;
     return $ReturnDir;
  }

########################################################
# 
########################################################
sub LogWrite
  {
     my $Message = $_[0];
#     my $MessageStatus = $_[1];

     if ($Message =~ m/$NAME/i)
       {
          $MainWin->LogFile->SelectAll();
          $MainWin->LogFile->ReplaceSel("");
       }

     $Message =~ s/\n/\r\n/;
     $MainWin->LogFile->Append("$Message\r\n");
  }

########################################################
# 
########################################################
sub LogSave
  {
     my $self = shift;
     my ($from, $to, $var) = 0;

     $MainWin->LogFile->SelectAll();
     ($from, $to) = $MainWin->LogFile->GetSel();
     $var = substr($MainWin->LogFile->Text(), $from, $to - $from);

     my $RetFile = Win32::GUI::GetSaveFileName (
         -owner      => $MainWin,
         -title      => $Language{SelectReportFile},
         -file       => "Log.txt",
         -directory  => CSIDL_PERSONAL,
         -filter     => ["$Language{TextFiles} (*.txt)" => "*.txt",
                         "$Language{AllFiles}" => "*.*"],
         -defaultextension => "txt",
         -defaultfilter    => 0,
     );

     if (defined $RetFile) {
       my $LogFile = open(LOG_FILE, "> $RetFile");
          if (defined $LogFile)
            {
               print LOG_FILE $var;
               close LOG_FILE;
            }
          else
            {
               $self->MessageBox(
               "$Language{UnableToSaveReportFile}\r\n".
               "$!",
               "$Language{WINDOW_Error}",
               MB_ICONERROR | MB_OK,);
            }
      }

  }

########################################################
# 
########################################################
sub Exit
  {
     my $self = shift;
     my ($k, $v, $num) = 0;
     while (($k, $v) = each %ConfigurationOriginal)
       {
          $num++ if $ConfigurationOriginal{$k} != $Configuration{$k};
          $num++ if $ConfigurationOriginal{$k} ne $Configuration{$k};
       }

     if ($num > 0)
       {
          my $ConfigurationFile = open(CONFIG_FILE, "> Settings-e.ini");
          if (defined $ConfigurationFile)
            {
               while (($k, $v) = each (%Configuration))
                 {
                    print CONFIG_FILE "$k = $v\n";
                 }
               close CONFIG_FILE;
            }
          else
            {
               $self->MessageBox(
               "$Language{UnableSaveConfigFile}\r\n".
               "$!",
               "$Language{WINDOW_Error}",
               MB_ICONERROR | MB_OK,);
            }
       }
     exit(0);
  }

########################################################
# 
########################################################
sub Convert
  {
      my $self = shift;

      $MainWin->Convert->Text($Language{Stop});

      my $time = localtime;

      LogWrite ("$NAME ($VERSION.$BUILD).\n");
      LogWrite ("$Language{StartTime} $time.\n");

      if ($Configuration{CalculateLength}         == 0 &&
          $Configuration{CalculateGenesQuantity}  == 0 &&
          $Configuration{ExtractExons}            == 0 &&
          $Configuration{ExtractWithIntrons}      == 0 &&
          $Configuration{ExtractSEI}              == 0)
        {
            $self->MessageBox(
            "$Language{SelectActionFirst}\r\n".
            "",
            "$Language{WINDOW_Attention}",
            MB_ICONWARNING | MB_OK,);
            LogWrite ("$Language{SelectActionFirst}");
        }
      else
        {
            LogWrite ($Language{SelectedActions});
            LogWrite ($Language{CalculateLength}) if $Configuration{CalculateLength} == 1;
            LogWrite ($Language{CalculateGenesQuantity}) if $Configuration{CalculateGenesQuantity} == 1;
            LogWrite ($Language{ExtractExons}) if $Configuration{ExtractExons} == 1;
            LogWrite ($Language{ExtractWithIntrons}) if $Configuration{ExtractWithIntrons} == 1;
            LogWrite ($Language{ExtractSEI}) if $Configuration{ExtractSEI} == 1;
            LogWrite ($Language{ExtractUseFrame}) if $Configuration{ExtractUseFrame} == 1;
   
            if ($Configuration{ExtractUseFrame} == 1)
               {
                 my $Text_ExtractFrame = $MainWin->ExtractFrame->Text();
                 $Configuration{ExtractFrame} = $Text_ExtractFrame if $Configuration{ExtractFrame} ne $Text_ExtractFrame;

                 if (($Configuration{ExtractFrame} eq "" ||
                      $Configuration{ExtractFrame} == undef ||
                      $Configuration{ExtractFrame} == 0 ||
                      $Configuration{ExtractFrame} =~ m/([A-Z]|\s|\W)/ig) && $Configuration{ExtractUseFrame} == 1)
                   {
                      $self->MessageBox(
                      "$Language{BadExtractFrame} $Configuration{ExtractFrame}!\r\n".
                      "",
                      "$Language{WINDOW_Error}",
                      MB_ICONERROR | MB_OK,);
                      LogWrite ("$Language{BadExtractFrame} $Configuration{ExtractFrame}!");
                   }
                 else
                   {
                      $ramka_2M = $Configuration{ExtractFrame};
                      LogWrite ("$Language{ExtractFrame} $ramka_2M");
                   }
               }

            my $Text_Keyword = $MainWin->Keyword->Text();
            $Configuration{Keyword} = $Text_Keyword if $Configuration{Keyword} ne $Text_Keyword;
            $gb_keyword_e = $Configuration{Keyword};
            my $gb_keyword = "  ".$gb_keyword_e."  ";

            if ($gb_keyword_e eq undef ||
                $gb_keyword_e eq ""    ||
                $gb_keyword_e =~ m/([0-9]|\s|\W)/ig)
                   {
                      $self->MessageBox(
                      "$Language{BadKeyword} $gb_keyword_e!\r\n".
                      "$Language{AllowedWords}",
                      "$Language{WINDOW_Error}",
                      MB_ICONERROR | MB_OK,);
                      LogWrite ("$Language{BadKeyword} $gb_keyword_e!");
                   }
                 else
                   {
                      LogWrite ("$Language{Keyword2} $gb_keyword_e \n");

                      my $Text_GenBankFileFolder = $MainWin->GenBankFileFolder->Text();
                      $Configuration{GenBankFileFolder} = $Text_GenBankFileFolder if $Configuration{GenBankFileFolder} ne $Text_GenBankFileFolder;

                      $Configuration{GenBankFileFolder} =~ s/\//\\/g;
                      $Configuration{GenBankFileFolder} .= "\\" if substr($Configuration{GenBankFileFolder}, -1, 1) ne "\\";
                      $Configuration{GenBankFileFolder} =~ s/[\*\?\"\<\>\|]//g;

                      $MainWin->GenBankFileFolder->Text($Configuration{GenBankFileFolder});

                      my $gb_dir = $Configuration{GenBankFileFolder};
                      splice my @gb_files_list, 0;

                      if (substr($Configuration{GenBankFileFolder}, -1, 1) ne "\\" ||
                                 $Configuration{GenBankFileFolder} =~ m/.*\./)
                        {
                          $self->MessageBox(
                          "$Language{DefineFolderFirst}\r\n".
                          "",
                          "$Language{WINDOW_Attention}",
                          MB_ICONWARNING | MB_OK,);

                          LogWrite ("$Language{DefineFolderFirst}");
                        }
                      else
                        {
                          LogWrite ("$Language{SearchingGenBankFiles} $gb_dir...");
                          opendir(GB_DIR, $gb_dir);
                          @gb_files_list = grep {/\.gb*/i} readdir(GB_DIR);
                          closedir(GB_DIR);
                        }

                      if ($#gb_files_list >= 0)
                        {
                           $number = $#gb_files_list + 1;
                           $MainWin->ProgressFile->SetRange(0, $number);
                           LogWrite ("$number $Language{Founded} $Language{FilesGenBank}\n");
                           LogWrite ("$Language{Searching} $gb_keyword_e. $Language{PleaseWait}");

                            foreach $gb_file (@gb_files_list)
                              {
                                 $MainWin->FileWork->Text("$Language{FileWork} $gb_file...");
                                 $seq_num = 0;
                                 $seq_num2 = 0;
                                 $seq_numX = 0;
                                 $gb_file_e = $gb_file;

                                 $gb_file_e =~ s/\..*//i;

                                 $nuc_file_dir_2 = $gb_dir.$gb_file_e."\\";
                                 mkdir $nuc_file_dir_2, 0777;

                                 $exons_dir = $nuc_file_dir_2.$Configuration{ExonsDir};
                                 $withintrons_dir = $nuc_file_dir_2.$Configuration{WithIntronsDir};
                                 $sei_dir = $nuc_file_dir_2.$Configuration{SEIDir};
                                 $statistic_dir = $nuc_file_dir_2.$Configuration{StatisticDir};
                                 mkdir ($statistic_dir, 0777)   if ($Configuration{CalculateGenesQuantity}  == 1 || $Configuration{CalculateLength} == 1);

                                 $exel_file = $statistic_dir.$Configuration{OutputFileXLS};

                                 $gb_file = $gb_dir.$gb_file;

                                 if ($Configuration{ExtractExons} == 1 ||
                                     $Configuration{ExtractWithIntrons} == 1 ||
                                     $Configuration{ExtractSEI} == 1)
                                   {
                                      @temp_file = MakeTemp($gb_file, $nuc_file_dir_2);
                                   }
                                 if ($Configuration{CalculateGenesQuantity} == 1)
                                   {
                                       $seq_numX = CalculateGenesQuantity($gb_file, $statistic_dir, $ramka_2M);
                                       LogWrite ("$Language{InFile} $gb_file_e $Language{Genes} {$Language{NotFound}") if ($seq_numX == O);
                                   }
                                 if ($Configuration{ExtractUseFrame} == 1 && (
								     $Configuration{CalculateLength} == 1 ||
								     $Configuration{ExtractExons} == 1 ||
                                     $Configuration{ExtractWithIntrons} == 1 ||
                                     $Configuration{ExtractSEI} == 1))
                                   {
                                      $seq_num = ExtractUseFrame($gb_file, $nuc_file_dir_2, $ramka_2M, $gb_keyword);
                                   }
                                 else
                                   {
                                      $seq_num = ExtractWithoutFrame($gb_file, $nuc_file_dir_2, $gb_keyword);
                                   }

                                 if ($seq_num == O)
                                   {
                                      LogWrite ("$Language{InFile} $gb_file_e $Language{Keword3} $gb_keyword_e $Language{NotFound}");
                                   }
                                 if ($seq_numX == O && $seq_num == 0)
                                   {
                                      LogWrite ("$Language{InFile} $gb_file_e $Language{Genes} $Language{And} $gb_keyword_e $Language{NotFound}");
                                   }
                                 if  ($seq_numX != O && $seq_num != 0)
                                   {
                                      LogWrite ("$Language{InFile} $gb_file_e $seq_numX $Language{Genes} $Language{And} $seq_num $gb_keyword_e $Language{Founded}.");
                                   }
                                 if  ($seq_numX == O && $seq_num != 0)
                                   {
                                      LogWrite ("$Language{InFile} $gb_file_e $seq_num $gb_keyword_e $Language{Founded}.");
                                   }
                                 if  ($seq_numX != O && $seq_num == 0)
                                   {
                                      LogWrite ("$Language{InFile} $gb_file_e $seq_numX $Language{Genes} $Language{Founded}.");
                                   }
                                 $cur_pos_c = $MainWin->ProgressCopy->GetPos();
                                 $max_pos_c = $MainWin->ProgressCopy->GetMax();

                                 $MainWin->ProgressCopy->SetPos($max_pos_c) if $cur_pos_c != $max_pos_c;
                                 $MainWin->ProgressFile->StepIt();
                               }

                            $min_pos_c = $MainWin->ProgressCopy->GetMin();
                            $cur_pos_f = $MainWin->ProgressFile->GetPos();
                            $max_pos_f = $MainWin->ProgressFile->GetMax();
                            $min_pos_f = $MainWin->ProgressFile->GetMin();

                            $MainWin->ProgressFile->SetPos($max_pos_f) if $cur_pos_f != $max_pos_f;
 
                            $time = localtime;

                            $self->MessageBox(
                            "$Language{InFolder} $gb_dir $Language{Founded} $Language{And} $Language{SuccesfullyProcessed} $number $Language{FilesGenBank}\r\n".
                            "",
                            "$Language{WINDOW_Done}",
                            MB_ICONINFORMATION | MB_OK,);
                            LogWrite ("$Language{InFolder} $gb_dir $Language{Founded} $Language{And} $Language{SuccesfullyProcessed} $number $Language{FilesGenBank}\n");
                            LogWrite ("$Language{EndTime} $time.");
                            $MainWin->ProgressCopy->SetPos($min_pos_c);
                            $MainWin->ProgressFile->SetPos($min_pos_f);
                            $MainWin->FileWork->Text(" ");
                            $MainWin->KeyWork->Text(" ");
                         }
                       else
                         {
                            $self->MessageBox(
                            "$Language{InFolder} $gb_dir $Language{FilesGenBank} $Language{NotFound}\r\n".
                            "",
                            "$Language{WINDOW_Attention}",
                            MB_ICONWARNING | MB_OK,);
                            LogWrite ("$Language{InFolder} $gb_dir $Language{FilesGenBank} $Language{NotFound}\n");
                         }
                     }
                 }
      $MainWin->Convert->Text($Language{Convert});
  }

########################################################
# Creates temporary file with complete nucleotide sequence from original GenBank file for extracting nucleotide sequences from
########################################################
sub MakeTemp($$)
  {
    my $gb_file = $_[0];
    my $nuc_file_dir_2 = $_[1];
    my $temp_file = $nuc_file_dir_2."\\TempSeq.dat";
    my $temp_file_length = 0;
    my $gb_line = "";
    open (GB_FILE, "<$gb_file") or die ("$Language{UnableOpenFile} $gb_file: $!");
    open (TEMP_FILE, ">$temp_file") or die ("$Language{UnableOpenOrCreateFile} $temp_file: $!");
      while($gb_line = <GB_FILE>)
        {
           if($gb_line =~ m/ORIGIN/)
             {
                while($gb_line = <GB_FILE>)
                  {
                     $gb_line =~ s/\W//g;
                     $gb_line =~ s/\d//g;
                     print TEMP_FILE $gb_line;
                     $temp_file_length = $temp_file_length + length($gb_line);
                  }
             }   
        }
    close GB_FILE;
    close TEMP_FILE;
    return ($temp_file, $temp_file_length);
  }

########################################################
# Extracts nucleotide sequence from temp file with nucleotide sequence (exons only)
########################################################
sub ExtractExons(@)
  {
     my $fragment = "";
     my $seq = "";                      # Nucleotide sequence to return   
     my @pos  = (0,0);                  # Array for start and end positions
#     open (TEMP_FILE, "<$temp_file") or die ("$Language{UnableOpenFile} $temp_file: $!");
     foreach $fragment (@_)
       {
          @pos = split(/\.\./, $fragment);
          $pos[0]--;                      # Correcting start position        
          seek (TEMP_FILE, $pos[0], 0);
          read (TEMP_FILE, $seq, ($pos[1] - $pos[0]), length($seq));    
       } 
#     close TEMP_FILE;
     return $seq;
  }

########################################################
# Extracts nucleotide sequence from temp file with nucleotidesequence (gene with intron)
########################################################
sub ExtractWithIntrons(@)
  {
     my $fragment = "";
     my $seq = "";                      # Nucleotide sequence to return   
#     open (TEMP_FILE, "<$temp_file") or die ("$Language{UnableOpenFile} $temp_file: $!");
     foreach $fragment (@_) {push (@pos, split(/\.\./, $fragment ));}
     $pos[0]--;                         # Correcting start position
     seek (TEMP_FILE, $pos[0], 0);
     read (TEMP_FILE, $seq, ($pos[-1] - $pos[0]), length($seq));
#     close TEMP_FILE;
     splice @pos, 0;
     return $seq;
  }

########################################################
# 
########################################################
sub ExtractSEI ($$$$$)
  {
     my $sei_dir = $_[0];
     my $gene = $_[1];
     my $nuc_pos = $_[2];
     my $complement = $_[3];
     my $seq_num2 = $_[4];	 
     my $seq_num = 1;
     my $nuc_seq = "";
     my $nuc_file_dir;
     my ($c, $w, $numin, $numseq, $ext) = "";

     if ($Configuration{CORW} == 1) {$c = "c-"; $w = "w-";}
     if ($Configuration{IntronsNumber} == 1) {$numin = "___";}
     if ($Configuration{NumberOfSequence} == 1) {$numseq = "-sei".$seq_num2;}
     if ($Configuration{UseExtension} == 1) {$ext = ".".$Configuration{Extension};}

     my @nuc_pos_list = split(/,/, $nuc_pos);

     $sei_dir =~ s/gene=//;
     if($complement eq "yes")
       {
         $nuc_file_dir = $sei_dir.$c.$gene.$numseq;
         $seq_num = $#nuc_pos_list + 1;
       }
     else
       {
         $nuc_file_dir = $sei_dir.$w.$gene.$numseq;
         $seq_num = 1;
       }
     mkdir $nuc_file_dir, 0777;

     my $fragment = "";
     my @pos  = (0,0);                  # Array for start and end positions
#     open (TEMP_FILE, "<$temp_file[0]") or die ("$Language{UnableOpenFile} $temp_file: $!");
       foreach $fragment (@nuc_pos_list)
         {
           @pos = split(/\.\./, $fragment);
           $pos[0]--;
           seek (TEMP_FILE, $pos[0], 0);
           read (TEMP_FILE, $nuc_seq, ($pos[1] - $pos[0]), length($nuc_seq));
             if($complement eq "yes")
               {
                 $nuc_seq = Complement($nuc_seq);
               }
           my $nuc_file = $nuc_file_dir."/Exon".$seq_num.$ext;
    
           open(NUC_FILE, ">".$nuc_file) or die "$Language{UnableOpenOrCreateFile} $nuc_file: $!";      
             print NUC_FILE uc "$nuc_seq"."*";
           close NUC_FILE;
           $nuc_seq = "";
           if($complement eq "yes") {$seq_num--;}
           else {$seq_num++;}
         }

     $nuc_seq = "";

     @nuc_pos_list = split(/\.\./, $nuc_pos);
     shift @nuc_pos_list;
     pop @nuc_pos_list;
     $fragment = "";

     if($complement eq "yes") {$seq_num = $#nuc_pos_list + 1;}
     else {$seq_num = 1;}

     @pos  = (0,0);                  # Array for start and end positions
       foreach $fragment (@nuc_pos_list)
         {
            @pos = split(/,/, $fragment);
            $pos[1]--;
            seek (TEMP_FILE, $pos[0], 0);
            read (TEMP_FILE, $nuc_seq, ($pos[1] - $pos[0]), length($nuc_seq));
              if($complement eq "yes")
                {
                  $nuc_seq = Complement($nuc_seq);
                }
            $nuc_file = $nuc_file_dir."/Intron".$seq_num.$ext;     
            open(NUC_FILE, ">".$nuc_file) or die "$Language{UnableOpenOrCreateFile} $nuc_file: $!";      
              print NUC_FILE uc "$nuc_seq"."*";
            close NUC_FILE;
            $nuc_seq = "";
           if($complement eq "yes") {$seq_num--;}
           else {$seq_num++;}
         }
#     close TEMP_FILE;
  }

########################################################
# 
########################################################
sub ExtractWithoutFrame ($$$)
  {
     my $gb_file = $_[0];
     my $nuc_file_dir_2 = $_[1];
     my $gb_keyword = $_[2];
     my $seq_num = 0;
     my ($c, $w, $numin, $numseqe, $numseqi, $ext) = "";
     if ($Configuration{CORW} == 1) {$c = "c-"; $w = "w-";}
     if ($Configuration{UseExtension} == 1) {$ext = ".".$Configuration{Extension};}

        mkdir ($exons_dir, 0777)       if $Configuration{ExtractExons} == 1;
        mkdir ($withintrons_dir, 0777) if $Configuration{ExtractWithIntrons} == 1;
        mkdir ($sei_dir, 0777)         if $Configuration{ExtractSEI} == 1;

        %TextFiles2 = ();

        while (($k, $v) = each %TextFiles)
          {
             if (ref($v) eq "ARRAY")
                {
                  $TextFiles2{$k} = [$statistic_dir.${$v}[0], ${$v}[1], ${$v}[2]] if $#{$v} == 2;
                  $TextFiles2{$k} = [$statistic_dir.${$v}[0], ${$v}[1]] if $#{$v} == 1;
                }
             else {$TextFiles2{$k} = $statistic_dir.$v;}
          }
                                 
        open(GB_FILE, "< $gb_file") or die ("$Language{UnableOpenFile} $gb_file: $!");
		if (defined $temp_file[0]) {open (TEMP_FILE, "< $temp_file[0]") or die ("$Language{UnableOpenFile} $temp_file[0]: $!");}
     my $numfind = 0;
        $MainWin->ProgressCopy->SetPos($min_pos_c);
        while($gb_line = <GB_FILE>)
          {
             $numfind++ if ($gb_line =~ m/$gb_keyword/) 
          }
        $MainWin->ProgressCopy->SetRange(0, $numfind);
        seek (GB_FILE, 0, 0);
        while($gb_line = <GB_FILE>)
          {
             if ($gb_line =~ m/$gb_keyword/)    # Searching $gb_keyword
               {
                  $MainWin->ProgressCopy->StepIt();
                  $nuc_pos = "";
                  $nuc_seq = "";
                  $gene = "";
                  until($gb_line =~ m{/})
                    {
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
                  $MainWin->KeyWork->Text("$Language{KeyWork} $gene...");
                  $nuc_pos =~ s/$gb_keyword_e//;   # Removing "$gb_keyword"
                  $nuc_pos =~ s/join//;            # Removing "join"
                  $nuc_pos =~ s/\s//g;             # Removing all space symbols
                  $nuc_pos =~ s/\(//g;             # Removing all "("
                  $nuc_pos =~ s/\)//g;             # Removing all ")"
                  next if ($nuc_pos =~ m/\</ && $Configuration{AllowedBrackets} == "0");       # "<"
                  next if ($nuc_pos =~ m/\>/ && $Configuration{AllowedBrackets} == "0");       # ">"
                  if ($nuc_pos =~ m/complement/)
                    {
                       $complement = "yes";         
                    }
                  else 
                    {
                       $complement = "no";
                    }
                  $nuc_pos =~ s/complement//;              # Removing "complement"
                  @nuc_pos_list = split(/,/, $nuc_pos);

                  splice @posV, 0;
                  @nuc_pos_listV = @nuc_pos_list;
                  foreach $fragmentV (@nuc_pos_listV)
                    {
                       push (@posV, split(/\.\./, $fragmentV));
                    }
                  if ($#posV % 2)
                    {
                       if ($Configuration{IntronsNumber} == 1) {$numin = $#nuc_pos_list."-";};
                       if ($Configuration{NumberOfSequence} == 1) {$numseqe = "-e".$seq_num; $numseqi = "-i".$seq_num;}
                       if ($Configuration{CalculateLength} == 1)
                         {
                            $gb_kw = $c.$gb_keyword_e if $complement eq "yes";
                            $gb_kw = $w.$gb_keyword_e if $complement eq "no";
                            @len = Calculator(@nuc_pos_list);
                         my $num_len = $#len + 1;
                            @len = reverse(@len) if $complement eq "yes";
                            CalculatorWrite2($num_len, \%TextFiles2, $gene, $gb_kw, @len);
                            splice @len, 0;
                         }
                       if ($Configuration{ExtractExons} == 1)
                         {
                            $nuc_seq = "";
                            $nuc_seq = ExtractExons(@nuc_pos_list);
                            if($complement eq "yes")
                              {
                                 $nuc_seq = Complement($nuc_seq);
                                 $nuc_file = $exons_dir.$c.$numin.$gene.$numseqe.$ext;
                              }
                            else
                              {
                                 $nuc_file = $exons_dir.$w.$numin.$gene.$numseqe.$ext;
                              }
                            open(NUC_FILE, ">".$nuc_file) or die ("$Language{UnableOpenOrCreateFile} $nuc_file: $!");
                              print NUC_FILE uc "$nuc_seq"."*";
                            close NUC_FILE;
                         }
                       if ($Configuration{ExtractWithIntrons} == 1)
                         {
                            $nuc_seq = "";
                            $nuc_seq = ExtractWithIntrons(@nuc_pos_list);
                            if($complement eq "yes")
                              {
                                 $nuc_seq = Complement($nuc_seq);
                                 $nuc_file = $withintrons_dir.$c.$numin.$gene.$numseqi.$ext;
                              }
                            else
                              {
                                 $nuc_file = $withintrons_dir.$w.$numin.$gene.$numseqi.$ext;
                              }
                            open(NUC_FILE, ">".$nuc_file) or die ("$Language{UnableOpenOrCreateFile} $nuc_file: $!");      
                              print NUC_FILE uc "$nuc_seq"."*";
                            close NUC_FILE;
                         }
                       if ($Configuration{ExtractSEI} == 1)
                         {
                            ExtractSEI($sei_dir, $gene, $nuc_pos, $complement, $seq_num);
                         }
                       $seq_num++;
                    }
               }
          }
		if (defined $temp_file[0]) {close TEMP_FILE;}
        close GB_FILE;
        if ($Configuration{DeleteTempFile} == 1 ) {unlink($temp_file[0]);}
        if ($Configuration{CalculateLength} == 1 && $Configuration{NotCreateFileXLS} == 0)
          {
            $ExcelWriteStatus = CalculatorExcelWrite2($exel_file, \%TextFiles2);
            if ($ExcelWriteStatus != 1)
              {
                LogWrite ("$Language{UnableOpenOrCreateFile} Microsoft Excel $exel_file!");
              }
          }

        $seq_num--;
        return $seq_num;
  }

########################################################
# 
########################################################
sub ExtractUseFrame ($$$$)
  {
      my $gb_file = $_[0];
      my $nuc_file_dir_2 = $_[1];
      my $ramkaM = my $ramka_1M = my $ramka_2M = $_[2];
      my $gb_keyword = $_[3];
      my $nomer = 1;
      my $seq_num = 0;
      #my $seq_num2 = 0;
     my ($c, $w, $numin, $numseqe, $numseqi, $ext) = "";
     if ($Configuration{CORW} == 1) {$c = "c"; $w = "w";}
     if ($Configuration{UseExtension} == 1) {$ext = ".".$Configuration{Extension};}
      
      my ($nuc_file_dir_2X, $nin, $gb_line, $nuc_pos, $nuc_seq, $nuc_file, $gene, $complement, $gb_kw);

      splice my @nuc_pos_list, 0;
      splice my @posV, 0;
      splice my @nuc_pos_listV, 0;
      splice my @len, 0;

      $nuc_file_dir_2X = $nuc_file_dir_2."Group_$nomer\\";

      mkdir $nuc_file_dir_2X, 0777;
      %TextFiles2 = ();

      while (($k, $v) = each %TextFiles)
        {
           if (ref($v) eq "ARRAY")
             {
                $TextFiles2{$k} = [$nuc_file_dir_2X.${$v}[0], ${$v}[1], ${$v}[2]] if $#{$v} == 2;
                $TextFiles2{$k} = [$nuc_file_dir_2X.${$v}[0], ${$v}[1]] if $#{$v} == 1;
             }
           else {$TextFiles2{$k} = $nuc_file_dir_2X.$v;}
        }                                 

        open(GB_FILE, "< $gb_file") or die ("$Language{UnableOpenFile} $gb_file: $!");
		if (defined $temp_file[0]) {open (TEMP_FILE, "< $temp_file[0]") or die ("$Language{UnableOpenFile} $temp_file[0]: $!");}
     my $numfind = 0;
        $MainWin->ProgressCopy->SetPos($min_pos_c);
        while($gb_line = <GB_FILE>)
          {
             $numfind++ if ($gb_line =~ m/$gb_keyword/) 
          }
        $MainWin->ProgressCopy->SetRange(0, $numfind);
        seek (GB_FILE, 0, 0);
        while($gb_line = <GB_FILE>)
          {
             if ($gb_line =~ m/$gb_keyword/)    # Searching $gb_keyword
                {
                   $MainWin->ProgressCopy->StepIt();
                   $nuc_pos = "";
                   $nuc_seq = "";
                   $gene = "";
                   until($gb_line =~ m{/})
                     {
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
                   $MainWin->KeyWork->Text("$Language{KeyWork} $gene...");
                   $nuc_pos =~ s/$gb_keyword_e//;   # Removing "$gb_keyword"
                   $nuc_pos =~ s/join//;            # Removing "join"
                   $nuc_pos =~ s/\s//g;             # Removing all space symbols
                   $nuc_pos =~ s/\(//g;             # Removing all "("
                   $nuc_pos =~ s/\)//g;             # Removing all ")"
                   next if ($nuc_pos =~ m/\</ && $Configuration{AllowedBrackets} == "0");       # "<"
                   next if ($nuc_pos =~ m/\>/ && $Configuration{AllowedBrackets} == "0");       # ">"
                   if ($nuc_pos =~ m/complement/)
                     {
                      $complement = "yes";         
                     }
                   else 
                     {
                      $complement = "no";
                     }
                   $nuc_pos =~ s/complement//;              # Removing "complement"
                   @nuc_pos_list = split(/,/, $nuc_pos);

                   splice @posV, 0;
                   @nuc_pos_listV = @nuc_pos_list;
                   foreach $fragmentV (@nuc_pos_listV)
                     {
                        push (@posV, split(/\.\./, $fragmentV));
                     }
                   if ($#posV % 2)
                     {
                        splice @pos2, 0;
                        @nuc_pos_list2 = @nuc_pos_list;
                        if ($Configuration{IntronsNumber} == 1) {$numin = $#nuc_pos_list."-";};
                        foreach $fragment (@nuc_pos_list2)
                          {
                             push (@pos2, split(/\.\./, $fragment));
                          }
                        if ($ramkaM >= $pos2[-1])
                           {
                             if ($Configuration{NumberOfSequence} == 1) {$numseqe = "-e".$seq_num; $numseqi = "-i".$seq_num;}
                             if ($Configuration{CalculateLength} == 1)
                               {
                                  $gb_kw = $c.$gb_keyword_e if $complement eq "yes";
                                  $gb_kw = $w.$gb_keyword_e if $complement eq "no";
                                  @len = Calculator(@nuc_pos_list);
                               my $num_len = $#len + 1;
                                  @len = reverse(@len) if $complement eq "yes";
                                  CalculatorWrite2($num_len, \%TextFiles2, $gene, $gb_kw, @len);
                                  splice @len, 0;
                               }
                             if ($Configuration{ExtractExons} == 1)
                               {
                                  $nuc_seq = "";
                                  $nuc_seq = ExtractExons(@nuc_pos_list);
                                  if($complement eq "yes")
                                    {
                                      $nuc_seq = Complement($nuc_seq);
                                      $nuc_file = $nuc_file_dir_2X.$c.$numin.$gene.$numseqe.$ext;
                                    }
                                  else
                                    {
                                      $nuc_file = $nuc_file_dir_2X.$w.$numin.$gene.$numseqe.$ext;
                                    }
                                  open(NUC_FILE, ">".$nuc_file) or die ("$Language{UnableOpenOrCreateFile} $nuc_file: $!");
                                    print NUC_FILE uc "$nuc_seq"."*";
                                  close NUC_FILE;
                               }
                             if ($Configuration{ExtractWithIntrons} == 1)
                               {
                                  $nuc_seq = "";
                                  $nuc_seq = ExtractWithIntrons(@nuc_pos_list);
                                  if($complement eq "yes")
                                    {
                                       $nuc_seq = Complement($nuc_seq);
                                       $nuc_file = $nuc_file_dir_2X.$c.$numin.$gene.$numseqi.$ext;
                                    }
                                  else
                                    {
                                       $nuc_file = $nuc_file_dir_2X.$c.$numin.$gene.$numseqi.$ext;
                                    }
                                  open(NUC_FILE, ">".$nuc_file) or die ("$Language{UnableOpenOrCreateFile} $nuc_file: $!");      
                                    print NUC_FILE uc "$nuc_seq"."*";
                                  close NUC_FILE;
                               }
                            if ($Configuration{ExtractSEI} == 1)
                              {
                                  ExtractSEI($nuc_file_dir_2X, $gene, $nuc_pos, $complement, $seq_num);
                              }
                           }
                        else
                          {
                             $nomer++;
                             $ramkaM = $ramkaM + $ramka_1M;
                             $nuc_file_dir_2X = $nuc_file_dir_2."Group_$nomer\\";
                             mkdir $nuc_file_dir_2X, 0777;
                             while (($k, $v) = each %TextFiles)
                               {
                                 if (ref($v) eq "ARRAY")
                                   {
                                      $TextFiles2{$k} = [$nuc_file_dir_2X.${$v}[0], ${$v}[1], ${$v}[2]] if $#{$v} == 2;
                                      $TextFiles2{$k} = [$nuc_file_dir_2X.${$v}[0], ${$v}[1]] if $#{$v} == 1;
                                   }
                                 else {$TextFiles2{$k} = $nuc_file_dir_2X.$v;}
                               } 
                          }
                        $seq_num++;
                     }
                 }
          }
	  if (defined $temp_file[0]) {close TEMP_FILE;}
      close GB_FILE;
  if ($Configuration{DeleteTempFile} == 1 ) {unlink($temp_file[0]);}
      $seq_num--;
      return $seq_num;
  }

########################################################
# 
########################################################
sub CalculateGenesQuantity ($$$)
  {
      my $gb_file = $_[0];
      my $ramka = my $ramka_1 = my $ramka_2 = $_[2];
      my $gb_keyword_e = "gene";
      my $gb_keyword = "  ".$gb_keyword_e."  ";
      my $numberA = 0;
      my $numberC = 0;
      my $numberW = 0;
      my $nuc_file = $_[1]."GeneQuantity.txt";
      my ($gb_line, $nuc_pos, $nuc_seq, $gene, $seq_num, $complement) = 0;

    open(NUC_FILE, ">>".$nuc_file) or die ("$Language{UnableOpenOrCreateFile} $nuc_file: $!");
    print NUC_FILE "File: ".$gb_file.", Length: ".$temp_file[1].", Keyword: ".$gb_keyword_e.", Frame: ".$ramka."\n";
    print NUC_FILE "Frame	ALL	C	W\n";

         open(GB_FILE, "< $gb_file") or die ("$Language{UnableOpenFile} $gb_file: $!");
#     my $numfind = 0;
#        $MainWin->ProgressCopy->SetPos($min_pos_c);
#        while($gb_line = <GB_FILE>)
#          {
#             $numfind++ if ($gb_line =~ m/$gb_keyword/) 
#          }
#        $MainWin->ProgressCopy->SetRange(0, $numfind);
#        seek (GB_FILE, 0, 0);
           while($gb_line = <GB_FILE>)
             {
                if ($gb_line =~ m/$gb_keyword/)    # Searching $gb_keyword
                   {
                   #   $MainWin->ProgressCopy->StepIt();
                      $nuc_pos = "";
                      $nuc_seq = "";
                      $gene = "";
                      until($gb_line =~ m{/})
                        {
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
                  #    $gene =~ s/[\:\*\?\"\<\>\|]/_/g;
                  #    $MainWin->KeyWork->Text("$Language{KeyWork} $gene");
                      $nuc_pos =~ s/$gb_keyword_e//;   # Removing "$gb_keyword"
                      $nuc_pos =~ s/join//;            # Removing "join"
                      $nuc_pos =~ s/\s//g;             # Removing all space symbols
                      $nuc_pos =~ s/\(//g;             # Removing all "("
                      $nuc_pos =~ s/\)//g;             # Removing all ")"
                      $nuc_pos =~ s/\>//g;             # Removing all ">"
                      $nuc_pos =~ s/\<//g;             # Removing all "<"
                      if ($nuc_pos =~ m/complement/)
                        {
                         $complement = "yes";         
                        }
                      else 
                        {
                         $complement = "no";
                        }
                      $nuc_pos =~ s/complement//;              # Removing "complement"
                      my @gene_pos_list = split(/\.\./, $nuc_pos);

                      if ($Configuration{ExtractUseFrame} == 1)
                        {
                          if ($ramka >= $gene_pos_list[-1])
                            {
                               $numberA++;
                               $numberC++ if $complement eq "yes";
                               $numberW++ if $complement eq "no";
                            }
                          else
                            {
                               $numberA++;
                               $numberC++ if $complement eq "yes";
                               $numberW++ if $complement eq "no";

                               print NUC_FILE "$ramka	$numberA	$numberC	$numberW\n";

                               $numberA = 0;
                               $numberC = 0;
                               $numberW = 0;
                               $ramka = $ramka + $ramka_1;
                            }
                        }
                      else
                        {
                           $numberA++;
                           $numberC++ if $complement eq "yes";
                           $numberW++ if $complement eq "no";
                        }
                     $seq_num++;
                   }
             }
           print NUC_FILE "$ramka	$numberA	$numberC	$numberW\n";
         close GB_FILE;
    close NUC_FILE;
    return $seq_num;
  }

########################################################
# 
########################################################
sub Calculator (@)
  {
     my @nuc_pos_list = @_;
     splice my @len, 0;
     splice my @pos, 0;
     my $j = 1;
     my $i = 0;
     my $fragment1 = "";
     my $fragmnet2 = "";

        foreach $fragment1 (@nuc_pos_list)
          {
             push (@pos, split(/\.\./, $fragment1));
          }
        foreach (@pos) 
          {          
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
sub CalculatorWrite2 ($$$$@)
  {
      my $num_len = shift @_;
      my $TF = shift @_;
      my $gene = shift @_;
      my $gb_kw = shift@_;
      my @len = @_;
      my %TFHash = %$TF;
      my $key = 0;

      foreach $key (keys %TFHash)
        {
           if (ref($TFHash{$key}) eq "ARRAY")
             {
                if ($#{$TFHash{$key}} == 2)
                  {
                    if (${$TFHash{$key}}[1] <= $num_len && $num_len <= ${$TFHash{$key}}[2])
                      {
                         open(TXT_FILE, ">> ${$TFHash{$key}}[0]") or die ("$Language{UnableOpenOrCreateFile} ${$TFHash{$key}}[0]: $!");
                           print TXT_FILE "$gene ";
                           print TXT_FILE "$gb_kw ";
                           print TXT_FILE "@len \n";
                         close TXT_FILE;
                      }
                  }
                if ($#{$TFHash{$key}} == 1)
                  {
                    if (${$TFHash{$key}}[0] =~ m/.*more/i)
                      {
                         if ($num_len >= ${$TFHash{$key}}[1])
                           {
                              open(TXT_FILE, ">> ${$TFHash{$key}}[0]") or die ("$Language{UnableOpenOrCreateFile} ${$TFHash{$key}}[0]: $!");
                                print TXT_FILE "$gene ";
                                print TXT_FILE "$gb_kw ";
                                print TXT_FILE "@len \n";
                              close TXT_FILE;
                           }
                      }
                    if ($num_len == ${$TFHash{$key}}[1])
                      {
                         open(TXT_FILE, ">> ${$TFHash{$key}}[0]") or die ("$Language{UnableOpenOrCreateFile} ${$TFHash{$key}}[0]: $!");
                           print TXT_FILE "$gene ";
                           print TXT_FILE "$gb_kw ";
                           print TXT_FILE "@len \n";
                         close TXT_FILE;
                      }
                  }
             }
           else
             {
                open(TXT_FILE, ">> $TFHash{$key}") or die ("$Language{UnableOpenOrCreateFile} $TFHash{$key}: $!");      
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
sub CalculatorExcelWrite2 ($$)
  {
     my $exel_file = $_[0];
     my $TF2 = $_[1];
     my %TextFiles2 = %$TF2;

     my $workbook = Spreadsheet::WriteExcel->new($exel_file);
                            
     my $format_name = $workbook->add_format();
     my $redcolor = $workbook->set_custom_color(13, 255, 255, 153);
        $format_name->set_bg_color($redcolor);
        $format_name->set_left();
        $format_name->set_right();
                 
     my $format_cds = $workbook->add_format();
        $format_cds->set_left();
        $format_cds->set_right();
                 
     my $format_red = $workbook->add_format();
        $format_red->set_bg_color('red');
                   
     my $format_yellow = $workbook->add_format();
        $format_yellow->set_bg_color($redcolor);
        $format_yellow->set_left();
        $format_yellow->set_right();
                           
        while (($ktf2, $vtf2) = each %TextFiles2)
          {
             splice my @output_data, 0;
             $worksheet_name  = $ktf2;
                            
             if (ref($vtf2) eq "ARRAY")
               {
                  $input_data_file = ${$vtf2}[0];
               }
             else
               {
                  $input_data_file = $vtf2;
               }
          my $open = open(DATA_FILE_INPUT, "< $input_data_file");
             if (defined $open)
               {
                  @input_data_lines = <DATA_FILE_INPUT>;
                  close DATA_FILE_INPUT;
                  push @output_data, @input_data_lines;
                  splice @input_data_lines, 0;
               my $cur_worksheet = $workbook->add_worksheet($worksheet_name);
               my $row = 1;
               my $max_col = 4;
           
                  foreach $out_data (@output_data)
                    {
                       for (my $col_m = 0; $col_m <= 2; $col_m++)
                         {
                            $cur_worksheet->write($row, $col_m, '', $format_yellow);
                         }
                            
                    my @out_row = split (' ', $out_data);
                    my $col = 3;
                        
                       foreach $out_row_split (@out_row)
                         {
                            if ($col == 3)
                              {
                                 $cur_worksheet->write($row, $col, $out_row_split, $format_name);
                              }
                            elsif ($col == 4)
                              {
                                 $cur_worksheet->write($row, $col, $out_row_split, $format_cds);
                              }
                            else
                              {
                                 $cur_worksheet->write($row, $col, $out_row_split);
                              }
                            $col++;
                         }
                       $max_col = $col if $max_col < $col;
                       $row++;
                           
                       for (my $row_m = 1; $row_m <= ($row - 1); $row_m++)
                         {
                            $cur_worksheet->write($row_m, $max_col, '', $format_red);
                         }
                    }
               }
          }
     my $close = $workbook->close();
        return $close;
  }

########################################################
#  Constructing the complementary sequence
########################################################
sub Complement(@)
  {
     my $sequence = "";
     my @symbols = ();
     my $i = 0;
 
     foreach $seq (@_)
       {
        @symbols = split (//, $seq);
        for ($i = 0; $i < ($#symbols+1); $i++)
          {
           if($symbols[$i] eq "a") { $symbols[$i] = "t"; next; }
           if($symbols[$i] eq "t") { $symbols[$i] = "a"; next; }
           if($symbols[$i] eq "g") { $symbols[$i] = "c"; next; }
           if($symbols[$i] eq "c") { $symbols[$i] = "g"; next; }    
           if($symbols[$i] eq "A") { $symbols[$i] = "T"; next; }
           if($symbols[$i] eq "T") { $symbols[$i] = "A"; next; }
           if($symbols[$i] eq "G") { $symbols[$i] = "C"; next; }
           if($symbols[$i] eq "C") { $symbols[$i] = "G"; }    
          }   
        $seq = join ("", @symbols);
        $sequence = $seq;    
       } 
     return reverse($sequence);
  }








