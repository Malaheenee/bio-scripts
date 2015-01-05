#! /usr/bin/perl

#perl2exe_info FileDescription=Program for calculating nucelotide number
#perl2exe_info FileVersion=0.5.3.0006
#perl2exe_info CompanyName=Charles Malaheenee
#perl2exe_info ProductName=Arabella Calculator 2007
#perl2exe_info ProductVersion=0.5.3.0006
#perl2exe_info InternalName=NUCLEOTIDE SEQUENCE CALCULATOR
#perl2exe_info LegalCopyright=Copyright © 2004-2009 Charles Malaheenee. All right reserved.
#perl2exe_info LegalTrademarks=Calculator from Charles Malaheenee
#perl2exe_info OriginalFilename=NCALCULATOR_053_0006.exe

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

BEGIN
  {
########################################################
# Loading configuration form file (if this file exists)
########################################################
     %Configuration = (
     "Language"                => "Russian",
     "UseDefaultLanguage"      => "1",
     "UseExtension"            => "0",
	 "Extension"               => "res",
     "OutputFileXLS"           => "StatisticMono.txt",
     "NotCreateFileXLS"        => "0",
     "OutputFileTXT"           => "StatisticMono.txt",
     "FileFolder"              => cwd,
     "CountAbsATGC"            => "0",
     "CountRelATGC"            => "1",
     "CalculateTC05"           => "1",
     "CalculateAG05"           => "1",
     "CalculateCGAT"           => "1",
     "CalculateHP"             => "1",
     "CalculateCU"             => "0",
     "CalculateGCC"            => "0",
     "ExtractUseFrame"         => "0",
     "ExtractFrame"            => "1000000",
     );

     my $ConfigurationFile = open(CONFIG_FILE, "< Settings-c.ini");
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

      $Configuration{FileFolder} .= "\\" if substr($Configuration{FileFolder}, -1, 1) ne "\\";

      while (($k, $v) = each %Configuration) {$ConfigurationOriginal{$k} = $v;}

#############################################################
# Loading interface Language form file (if this file exists)
#############################################################
     %Language = (
     "WINDOW_Main"                 => "",
       "Keyword"                   => "Искать:",
       "FileFolder"                => "Папка:",
         "FileFolderBrowse"        => "Обзор...",
       "Count"                     => "Посчитать",
         "CountAbsATGC"            => "Посчитать абс. содержание A, T, G и C",
         "CountRelATGC"            => "Посчитать отн. содержание A, T, G и C",
       "Calculate"                 => "Вычислить",
         "CalculateTC05"           => "Вычислить T+C-0.5",
         "CalculateAG05"           => "Вычислить A+G-0.5",
         "CalculateCGAT"           => "Вычислить C/G-A/T",
         "CalculateHP"             => "Вычислить гидропатичность",
         "CalculateCU"             => "Вычислить частоту исп. кодонов",
         "CalculateGCC"            => "Вычислить GC-содержание",
       "ExtractUseFrame"           => "Использовать рамку",
       "Convert"                   => "Сделать",
       "Stop"                      => "Стоп",
       "Options"                   => "Настройки",
       "Help"                      => "Помощь",
       "About"                     => "О программе...",
       "Exit"                      => "Выход",
     "WINDOW_About"                => "О программе...",
       "PacketVersion"             => "Входит в состав",
       "ModuleName"                => "Модуль",
       "ModuleVersion"             => "Версия",
       "And"                       => "и",
     "WINDOW_Options"              => "Настройки",
       "LanguageSelect"            => "Выбор языка интерфейса",
         "Language"                => "Язык:",
         "UseDefaultLanguage"      => "Использовать язык по умолчанию",
       "Other"                     => "Разное",
         "OutputFileXLS"           => "Имя файла Microsoft Excel",
         "NotCreateFileXLS"        => "Не создавать файл Microsoft Excel",
         "OutputFileTXT"           => "Имя текстового файла",
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

my $temp_dir = ( $ENV{TEMP} || $ENV{TMP} || $ENV{WINDIR} || "/tmp" ) . "/p2xtmp-$$";

my $WorkDir = $Configuration{FileFolder};
my $ExcelFile = $WorkDir.$Configuration{OutputFileXLS};
my $TextFile = $WorkDir.$Configuration{OutputFileTXT};
my $abs_a = 0;
my $abs_t = 0;
my $abs_c = 0;
my $abs_g = 0;
my $hcA = -1.07;
my $hcT = -0.36;
my $hcG = -1.36;
my $hcC = -0.76;
my $hc1N = -0.89;

my $NAME    = "Arabella Calculator 2007";
my $VERSION = "0.5.3";
my $BUILD   = "0006";
my $PACKET  = "Arabella Nucleotide Analyzing Suite 2007";

my $MainWin = Win32::GUI::Window->new(
      -title       => $NAME,
      -left        => CW_USEDEFAULT,
      -size        => [615, 425],
      -minsize     => [615, 425],
      -maximizebox => 0,
      -resizable   => 0,
      -dialogui    => 1,
      -onTerminate => \&Exit,
);
$MainWin->SetIcon($MainIconCalculator);

$MainWin->AddTextfield(
   -name     => "FileFolder",
   -text     => $Configuration{FileFolder},
   -prompt   => [$Language{FileFolder}, 40],
   -pos      => [5, 5],
   -size     => [375, 25],
   -tabstop  => 1,
);

$MainWin->AddButton (
   -name     => "FileFolderBrowse",
   -pos      => [420, 5],
   -size     => [70, 25],
   -text     => $Language{FileFolderBrowse},
   -onClick  => sub{$Configuration{FileFolder} = SelectDir($Configuration{FileFolder});
                    $MainWin->FileFolder->Text($Configuration{FileFolder});},
   -tabstop  => 1,
);

$MainWin->AddGroupbox(
   -name  => "Count",
   -title => $Language{Count},
   -pos   => [5, 33],
   -size  => [240, 155],
   -group => 1,
);

$MainWin->AddCheckbox(
   -name    => "CountAbsATGC",
   -text    => $Language{CountAbsATGC},
   -pos     => [15, 49],
   -size    => [220, 20],
   -onClick => sub {$Configuration{CountAbsATGC} = $_[0]->GetCheck();},
   -tabstop => 1,
   -checked => $Configuration{CountAbsATGC},
   -disabled =>1,
);

$MainWin->AddCheckbox(
   -name    => "CountRelATGC",
   -text    => $Language{CountRelATGC},
   -pos     => [15, 71],
   -size    => [220, 20],
   -onClick => sub {$Configuration{CountRelATGC} = $_[0]->GetCheck();},
   -tabstop => 1,
   -checked => $Configuration{CountRelATGC},
   -disabled =>1,
);

$MainWin->AddGroupbox(
   -name  => "Calculate",
   -title => $Language{Calculate},
   -pos   => [250, 33],
   -size  => [240, 155],
   -group => 1,
);

$MainWin->AddCheckbox(
   -name    => "CalculateTC05",
   -text    => $Language{CalculateTC05},
   -pos     => [260, 49],
   -size    => [220, 20],
   -onClick => sub {$Configuration{CalculateTC05} = $_[0]->GetCheck();},
   -tabstop => 1,
   -checked => $Configuration{CalculateTC05},
   -disabled =>1,
);

$MainWin->AddCheckbox(
   -name    => "CalculateAG05",
   -text    => $Language{CalculateAG05},
   -pos     => [260, 71],
   -size    => [220, 20],
   -onClick => sub {$Configuration{CalculateAG05} = $_[0]->GetCheck();},
   -tabstop => 1,
   -checked => $Configuration{CalculateAG05},
   -disabled =>1,
);

$MainWin->AddCheckbox(
   -name    => "CalculateCGAT",
   -text    => $Language{CalculateCGAT},
   -pos     => [260, 93],
   -size    => [220, 20],
   -onClick => sub {$Configuration{CalculateCGAT} = $_[0]->GetCheck();},
   -tabstop => 1,
   -checked => $Configuration{CalculateCGAT},
   -disabled =>1,
);

$MainWin->AddCheckbox(
   -name    => "CalculateHP",
   -text    => $Language{CalculateHP},
   -pos     => [260, 115],
   -size    => [220, 20],
   -onClick => sub {$Configuration{CalculateHP} = $_[0]->GetCheck();},
   -tabstop => 1,
   -checked => $Configuration{CalculateHP},
   -disabled =>1,
);

$MainWin->AddCheckbox(
   -name    => "CalculateGCC",
   -text    => $Language{CalculateGCC},
   -pos     => [260, 137],
   -size    => [220, 20],
   -onClick => sub {$Configuration{CalculateGCC} = $_[0]->GetCheck();},
   -tabstop => 1,
   -checked => $Configuration{CalculateGCC},
   -disabled =>1,
);

$MainWin->AddCheckbox(
   -name    => "CalculateCU",
   -text    => $Language{CalculateCU},
   -pos     => [260, 159],
   -size    => [220, 20],
   -onClick => sub {$Configuration{CalculateCU} = $_[0]->GetCheck();},
   -tabstop => 1,
   -checked => $Configuration{CalculateCU},
   -disabled =>1,
);

$MainWin->AddCheckbox(
   -name    => "ExtractUseFrame",
   -text    => $Language{ExtractUseFrame},
   -pos     => [15, 200],
   -size    => [130, 20],
   -onClick => sub {$Configuration{ExtractUseFrame} = my $check_status = $_[0]->GetCheck();
                   if ($check_status == 1) {$MainWin->ExtractFrame->Enable();}
                   if ($check_status == 0) {$MainWin->ExtractFrame->Disable();}},
   -tabstop => 1,
   -checked => $Configuration{ExtractUseFrame},
   -disabled => 1,
);

$MainWin->AddTextfield(
   -name     => "ExtractFrame",
   -text     => $Configuration{ExtractFrame},
   -pos      => [145, 200],
   -size     => [90, 20],
   -tabstop  => 1,
   -number   => 1,
   -onChange => sub {$Configuration{ExtractFrame} = $_[0]->Text()},
   -disabled => (1 - $Configuration{ExtractUseFrame}),
);

$MainWin->AddLabel(
    -name => "LabelCopy",
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
   -name    => "Options",
   -pos     => [495, 45],
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

$MainWin->Show();
Win32::GUI::Dialog();
exit(0);

########################################################
# 
########################################################
sub About
  {
    my $self = shift;

    my ($iwidth,$iheight) = $AboutPicCalculator->Info();

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
         -bitmap => $AboutPicCalculator,
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
     my $OutputFileXLS      = $Configuration{OutputFileXLS};
     my $NotCreateFileXLS   = $Configuration{NotCreateFileXLS};
     my $OutputFileTXT      = $Configuration{OutputFileTXT};
	 
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
#          -tip   => "Выбор языка интерфейса",
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
          -name  => "Other",
          -title => $Language{Other},
          -pos   => [5, 55],
          -size  => [370, 297],
          -group => 1,
        );
		
        $OptionWin->AddTextfield(
          -name     => "OutputFileXLS",
          -text     => $OutputFileXLS,
          -prompt   => [$Language{OutputFileXLS}, 140],
          -pos      => [15, 70],
          -size     => [210, 20],
          -tabstop  => 1,
          -disabled => $Configuration{NotCreateFileXLS},
        );
		
        $OptionWin->AddTextfield(
          -name     => "OutputFileTXT",
          -text     => $OutputFileTXT,
          -prompt   => [$Language{OutputFileTXT}, 140],
          -pos      => [15, 110],
          -size     => [210, 20],
          -tabstop  => 1,
          -disabled => (1-$Configuration{NotCreateFileXLS}),
        );

        $OptionWin->AddCheckbox(
          -name    => "NotCreateFileXLS",
          -text    => $Language{NotCreateFileXLS},
          -pos     => [15, 90],
          -size    => [250, 20],
          -onClick => sub {$NotCreateFileXLS = my $check_status = $_[0]->GetCheck();
                           if ($check_status == 0) {$OptionWin->OutputFileXLS->Enable(); $OptionWin->OutputFileTXT->Disable()};
                           if ($check_status == 1) {$OptionWin->OutputFileTXT->Enable(); $OptionWin->OutputFileXLS->Disable()}},
          -tabstop => 1,
          -checked => $NotCreateFileXLS,
        );

        $OptionWin->AddButton(
          -name    => "ButtonOK",
          -text    => $Language{ButtonOK},
          -pos     => [195, 356],
          -size    => [90, 25],
          -ok  => 1,
          -default => 1,
          -onClick => sub {
                          my $Text_OutputFileXLS = $OptionWin->OutputFileXLS->Text();
                          $Text_OutputFileXLS =~ s/[\\\/\:\*\?\"\<\>\|]/N/g;
						  
                          my $Text_OutputFileTXT = $OptionWin->OutputFileTXT->Text();
                          $Text_OutputFileTXT =~ s/[\\\/\:\*\?\"\<\>\|]/N/g;

                          $OutputFileXLS = $Text_OutputFileXLS if $OutputFileXLS ne $Text_OutputFileXLS;
                          $OutputFileTXT = $Text_OutputFileTXT if $OutputFileTXT ne $Text_OutputFileTXT;

                          $Configuration{Language}           = $Language;
                          $Configuration{UseDefaultLanguage} = $UseDefaultLanguage;
                          $Configuration{OutputFileXLS}      = $OutputFileXLS;
                          $Configuration{NotCreateFileXLS}   = $NotCreateFileXLS;
                          $Configuration{OutputFileTXT}      = $OutputFileTXT;
                          
                          LoadLanguageFile($Language);
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
          my $ConfigurationFile = open(CONFIG_FILE, "> Settings-c.ini");
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

sub SelectDir
  {
     my $CurDir = shift;
     my $ReturnDir = $CurDir;
     my $RetDir = Win32::GUI::BrowseForFolder (
         -title      => $Language{SelectFileFolder},
         -directory  => $CurDir,
         -folderonly => 1,
         -editbox => 1,
     );

     $ReturnDir = $RetDir if defined $RetDir ;
     return $ReturnDir;
  }

sub SelectFile
  {
     my $CurDir = shift;
     my $ReturnFile = $CurDir."\\StatisticMono.xls";
     my $RetFile = Win32::GUI::GetOpenFileName (
         -owner => $MainWin,
         -title      => $Language{OutputFileXLS},
         -directory  => $CurDir,
         -file       => "All_data.xls",
         -filter     => ["Файлы Microsft Excel *.xls)" => "*.xls",
                         "Теесктовые файлы (*.txt)" => "*.txt",
                         "Все файлы" => "*.*"],
         -defaultextension => "xls",
         -defaultfilter    => 0,
     );

     $ReturnFile = $RetFile if defined $RetFile ;
     return $ReturnFile;
  }

sub Convert
{

my $self = shift;

my $input_dir_text = $MainWin->FileFolder->Text();
#$output_file_text = $MainWin->OutputFile->Text();

$input_dir_text =~ s/[\*\?\"\<\>\|]/N/g;
#$output_file_text =~ s/[\*\?\"\<\>\|]/N/g;

if ($WorkDir ne $input_dir_text)
  {
     $input_dir_text .= "\\" if substr($input_dir_text, -1, 1) ne "\\"; 
     $WorkDir = $input_dir_text;
	 $ExcelFile = $WorkDir.$Configuration{OutputFileXLS};
     $TextFile = $WorkDir.$Configuration{OutputFileTXT};
  }
#if ($ExcelFile ne $output_file_text )
#  {
#     $ExcelFile = $output_file_text;
#  }

$MainWin->LabelCopy->Text("Поиск файлов...");

$number = -2;
$summ = 0;
@SequncesFiles = undef;

tree ($WorkDir);

$summ = $#SequncesFiles + 1;

if ($summ <= 0)
  {
    $self->MessageBox(
     "Нет такой папки: $WorkDir или не найдено ни одного файла в ней!\r\n".
     "",
     "Внимание",
     MB_ICONWARNING | MB_OK,
    );
  }
else
  {
   $MainWin->ProgressCopy->SetStep(1);
   $MainWin->ProgressCopy->SetRange(0, $summ);

     $summ = $#SequncesFiles - 1;

     %Calc = ();

     foreach $SeqFile (@SequncesFiles)
       {
          $Value = "";
          $nuc_new_length =
          $abs_a = $abs_t = $abs_c = $abs_g =
          $rel_a = $rel_t = $rel_g = $rel_c =
          $ag_05 = $tc_05 = $cg_at = undef;

          $OpenFile = open (SEQ_FILE, "<", $SeqFile);
          $MainWin->LabelCopy->Text("Обработка $SeqFile...");
          if (defined $OpenFile)
            {
                 $Value = <SEQ_FILE>;
               close (SEQ_FILE);

#               $SeqFile =~ s/$WorkDir//;
#               $SeqFile =~ s/^\\//;
               $Value =~ s/\*//;
               $Value = lc($Value);

               $nuc_new_length = $Value =~ tr/acgt//;

               $abs_a = $Value =~ tr/a//;
               $abs_t = $Value =~ tr/t//;
               $abs_g = $Value =~ tr/g//;
               $abs_c = $Value =~ tr/c//;

               if ($nuc_new_length != 0)
                 {
                    $rel_a = $abs_a/$nuc_new_length;
                    $rel_t = $abs_t/$nuc_new_length;
                    $rel_g = $abs_g/$nuc_new_length;
                    $rel_c = $abs_c/$nuc_new_length;
                 }

               $ag_05 = $rel_a + $rel_g - 0.5 if $rel_a != 0 || $rel_g != 0;

               $tc_05 = $rel_t + $rel_c - 0.5 if $rel_t != 0 || $rel_c != 0;

               $cg_at = $rel_c/$rel_g - $rel_a/$rel_t if $rel_g != 0 && $rel_t != 0;
               
               $hc = $rel_a*$hcA + $rel_t*$hcT + $rel_g*$hcG + $rel_c*$hcC - $hc1N;

               $Calc{$SeqFile} = {"Length" => $nuc_new_length,
                                  "A" => $rel_a,
                                  "T" => $rel_t,
                                  "G" => $rel_g,
                                  "C" => $rel_c,
                                  "A+G-0,5" => $ag_05,
                                  "T+C-0,5" => $tc_05,
                                  "C/G-A/T" => $cg_at,
                                  "HC" => $hc};
            }
          $number++;
       }
	   
    if ($Configuration{NotCreateFileXLS} == 0 )
       {
         $MainWin->LabelCopy->Text("Запись файла $ExcelFile...");

      my $workbook = Spreadsheet::WriteExcel->new($ExcelFile);
      my $worksheet_mono = $workbook->add_worksheet("Mono");
#      my $worksheet_codon_usage = $workbook->add_worksheet("CodonUsage");

      my $FormatNumeric = $workbook->add_format();
         $FormatNumeric->set_num_format('0.000;[Red]-0.000');

      my $FormatTitle = $workbook->add_format();
         $FormatTitle->set_bold();
         $FormatTitle->set_align("center");
         $FormatTitle->set_align("vcenter");

      my @Top = ("Sequence", "Length", "A", "T", "G", "C", "A+G-0,5", "T+C-0,5", "C/G-A/T", "HC");

         for (my $col_m = 1, my $row_m = 2, my $i = 0; $col_m <= 6, $i <= $#Top; $i++, $col_m++)
           {
              $worksheet_mono->write($row_m, $col_m, $Top[$i], $FormatTitle);
           }

      my $row = 3;

	     foreach $key (sort keys %Calc)
           {
              my $col = 1;
                 $worksheet_mono->write($row, $col, $key);

              foreach $var (@Top)
                {
                   next if $var =~ m/sequence/i;
                   $col++;
                   if ($var =~ m/length/i)
                     {
                        $worksheet_mono->write($row, $col, ${$Calc{$key}}{$var});
                     }
                   else
                     {
                        $worksheet_mono->write($row, $col, ${$Calc{$key}}{$var}, $FormatNumeric);
                     }
                }
              $row++;
           }
         $workbook->close() or die "Невозможно закрыть файл $ExcelFile: $!";
	  }
	else
	  {
         $MainWin->LabelCopy->Text("Запись файла $TextFile...");
         open (TEXT_FILE, "> $TextFile");
         print TEXT_FILE "Sequence	Length	A	T	G	C	A+G-0,5	T+C-0,5	C/G-A/T	HC";
      my @Top = ("Sequence", "Length", "A", "T", "G", "C", "A+G-0,5", "T+C-0,5", "C/G-A/T", "HC");
	     foreach $key (sort keys %Calc)
           {
             print TEXT_FILE "\n$key";

              foreach $var (@Top)
                {
                   next if $var =~ m/sequence/i;
                   print TEXT_FILE "	${$Calc{$key}}{$var}";
                }
           }
         close TEXT_FILE or die "Невозможно закрыть файл $TextFile: $!";
      }
	   
    $cur_pos = $MainWin->ProgressCopy->GetPos();
    $max_pos = $MainWin->ProgressCopy->GetMax();
    $min_pos = $MainWin->ProgressCopy->GetMin();

    if ($cur_pos != $max_pos)
      {
         $MainWin->ProgressCopy->SetPos($max_pos);
      }
	  
    $MainWin->LabelCopy->Text("Готово");
    $self->MessageBox(
     "Найдено: $summ файлов\r\n".
     "Конвертировано: $number файлов",
     "Выполнено",
     MB_ICONINFORMATION | MB_OK,
    );

    $MainWin->ProgressCopy->SetPos($min_pos);
    $MainWin->LabelCopy->Text(" ");
  }
}

#----------------------------------------------

sub tree 
  {
    local (*WORK_DATA_DIR);
    my $work_data_dir2 = $_[0];
    my @gene_file_list_all2 = undef;

       opendir(WORK_DATA_DIR, $work_data_dir2);
         @gene_file_list_all2 = readdir(WORK_DATA_DIR);
       closedir(WORK_DATA_DIR);
  
       foreach $data_file_from_list (@gene_file_list_all2)
         {
            if ($data_file_from_list ne "." and $data_file_from_list ne "..")
              {
                 $data_file_from_list = $work_data_dir2."\\".$data_file_from_list;

                 push (@SequncesFiles, $data_file_from_list) if (-f $data_file_from_list);

                 if (-d $data_file_from_list)
                   {
                      tree ($data_file_from_list);
                   }
              }
         }
  }








