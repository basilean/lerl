#!/usr/bin/perl -w

=pod

=head1 NAME

LerL

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

A list for a team based in perl.

=head1 DESCRIPTION

This tool intends to be a team shared list todo simple as possible.

It stores all the information on simple text or csv files.

=cut

=head1 SETTINGS

=head2 Files and Directories

Directories where checklists (csv) and notes (txt) are located.

 $DIR_LIST = "list";
 $DIR_NOTES = "notes";

This file (csv) will be updated each time that an item is locked, unlocked or a check is set.

 $FILE_STATS = "stats.csv";

=cut

my $DIR_LIST = "list";
my $DIR_NOTES = "notes";
my $FILE_STATS = "stats.csv";

=head2 Status

This reference array list the possibles states for a check.

 $STATUS = ['TODO', 'DONE', 'ERROR', 'SKIP'];

=cut

my $STATUS = ['TODO', 'DONE', 'ERROR', 'SKIP'];

=head2 Style CSS

It will be posted inside the header between <style \> tags.

 body {}
 #head {}
 #left {}
 #right {}
 #foot {}

=cut

my $CSS = <<EOF;
body {float: left; width: 98%; background-color: #111;}

#head {float: left; width: 98%; margin: 1%; height: 20px;}
span.LEFT {float: left; width: 25%; text-align: left;}
#head span.LEFT a {color: blue;}
span.CENTER {float: left; width: 50%; text-align: center;}
#head span.CENTER {font-size: large; color: green;}
span.RIGHT {float: left; width: 25%; text-align: right;}
#head span.RIGHT {color: white;}

#left {float: left; width: 30%; background-color: #eee;}
div.ITEM {float: left; width: 100%; border: thin solid #111; font-size: large;}
div.ITEM a {display: inline; font-size: medium;}
div.ITEM form table {float: left; display: inline; font-size: small;}
span.INFO, div.INFO {float: left; margin-left: 1%; width: 35%; text-align: center;}
span.WIP {background-color: orange; margin-left: 10px;}
div.GRAP {float: right; width: 62%;}
span.DONE, div.DONE {background-color: green;}
span.ERROR, div.ERROR {background-color: red;}
span.TODO, div.TODO {background-color: yellow;}

#right {float: right; width: 68%; background-color: #111;}
div.NOTE {margin-top: 20px; float: left; width: 100%; background-color: #111; border-top: thin solid #ccc; border-left: thin solid #ccc;}
div.NOTE div.UP {width: 100%; float: right; background-color: #111; color: #eee; text-align: right;}
div.NOTE div.MID {width: 98%; padding: 1%; background-color: #ccc; white-space: pre-wrap;}
div.NOTE div.MID div {white-space: normal;}
div.NOTE div.DOWN {}
div.NOTE div.DOWN form { display: inline; background-color: #111;}
div.NOTE div.DOWN form textarea {float: left; width: 90%; margin-left: 1px; height: 50px;}

#foot {float: left; width: 98%; margin: 1%; height: 20px;}

#help {float: left; margin: 1%;}
EOF

=head1 Functions

All the subs needed to work.

=over

=head2 main

This is the script itself.

=cut

my $ARG = {};
my $postdata;
if ($ENV{'REQUEST_METHOD'} =~ /POST/i) {
 read(STDIN, $postdata, $ENV{'CONTENT_LENGTH'});
 $postdata .= "&".$ENV{'QUERY_STRING'};
}
else {
 $postdata .= $ENV{'QUERY_STRING'};
}
foreach (split('&', $postdata)) {
 my $key = [split('=', $_)];
 if ($ARG->{$key->[0]}) {
  my $tmp = $ARG->{$key->[0]};
  $ARG->{$key->[0]} = [];
  push($ARG->{$key->[0]}, $tmp, $key->[1])
 }
 else {
  $ARG->{$key->[0]} = $key->[1];
 }
}

if (my $do = $ARG->{'do'}) {
 if ($do eq "check") {
  print &print_item($ARG->{'item'});
 }
 elsif ($do eq "addnote") {
  my ($item, $check) = &do_addnote();
  if ($item) {
   print &print_item($item);
  }
  elsif ($check) {
   print &print_help($check, $check);
  }
  else {
   print &print_stats();
  }
 }
 elsif ($do eq "set") {
  my $out = &do_set();
  print &print_item($out);
 }
 elsif ($do eq "lock") {
  my $out = &do_lock();
  print &print_item($out);
 }
 elsif ($do eq "unlock") {
  my $out = &do_unlock();
  print &print_item($out);
 }
 elsif ($do eq "refresh") {
  my $out = &do_refresh();
  print &print_stats();
 }
 elsif ($do eq "help") {
  print &print_help($ARG->{'check'}, $ARG->{'check'});
 }
 else {
  print &print_index("Error".$do, "7200", undef, undef);
 }
}
else {
 print &print_stats();
}

=head2 do

The do group are the subs of actions from the main function handler.

=head3 do_refresh()

Refresh statics collecting checklist status for each item.
At first if loads the actual list and users locking items.
Then it generates a new list based on the list directory,
getting stats for each item. At the end it adds a new line
for each item and write it to disk.

=cut

sub do_refresh() {
 my $locklist = {};
 foreach my $line (&get_file($FILE_STATS)) {
  my ($item, $lock) = split(',', $line);
  $locklist->{$item} = $lock;
 }
 my $cont;
 foreach my $file (&list_file($DIR_LIST, ".csv")) {
  $file =~ s/\.csv//;
  my ($total, $done, $error) = &get_stats($DIR_LIST."/".$file.".csv");
  $locklist->{$file} ||= "";
  $cont .= $file.",".$locklist->{$file}.",".localtime.",".$total.",".$done.",".$error."\n";
 }
 &new_file($FILE_STATS, $cont);
 return $cont;
}

=head3 do_addnote()

Add or append a note to a given file.

 $ENV{REMOTE_USER}
 $DIR_NOTES;
 $ARG->{'file'};
 $ARG->{'item'};

=cut

sub do_addnote() {
 if ($ARG->{'item'}) {
  &add_file($DIR_NOTES."/".$ARG->{'file'},
   localtime."\t".$ARG->{'item'}."\tinfo\tNOTE\t".$ENV{REMOTE_USER}."\n".$ARG->{$ARG->{'file'}}."\n"
  );
  return ($ARG->{'item'});
 }
 else {
  &add_file($DIR_NOTES."/".$ARG->{'file'},
   localtime."\tNOTE\t".$ENV{REMOTE_USER}."\n".$ARG->{$ARG->{'file'}}."\n"
  );
  return (undef, $ARG->{'check'});
 }
}

=head3 do_set()

Set the status for a checkpoint.

=cut

sub do_set() {
 &up_file($DIR_LIST."/".$ARG->{'item'}.".csv",
  $ARG->{'check'}.",".$ARG->{$ARG->{'check'}}.",".$ENV{REMOTE_USER}.",".localtime."\n",
  $ARG->{'check'}
 );
 &add_file($DIR_NOTES."/".$ARG->{'item'}.".txt",
  localtime."\t".$ARG->{'item'}."\t".$ARG->{'check'}."\t".$ARG->{$ARG->{'check'}}."\t".$ENV{REMOTE_USER}."\n"
 );
 return $ARG->{'item'};
}

=head3 do_lock() - TO REVIEW

Lock the item to be edit by the user.

=cut

sub do_lock() {
 my ($total, $done, $error) = &get_stats($DIR_LIST."/".$ARG->{'item'}.".csv");
 &up_file($FILE_STATS,
  $ARG->{'item'}.",".$ENV{REMOTE_USER}.",".localtime.",".$total.",".$done.",".$error."\n",
  $ARG->{'item'}
 );
 &add_file($DIR_NOTES."/".$ARG->{'item'}.".txt",
  localtime."\t".$ARG->{'item'}."\tinfo\tLOCK\t".$ENV{REMOTE_USER}."\n");
 return $ARG->{'item'};
}

=head3 do_unlock() - TO REVIEW

Unlock the item to be edit by the user.

=cut

sub do_unlock() {
 my $user = $ENV{REMOTE_USER};
 my $item = $ARG->{'item'};
 my $check = $ARG->{'check'};
 my $status = $ARG->{$check};
 my $timestamp = localtime;
 my $list = "$DIR_LIST/$item.csv";
 my ($total, $done, $error) = &get_stats($list);
 my $line = "$item,,,$total,$done,$error\n";
 &up_file($FILE_STATS, $line, $item);
 my $notes = "$DIR_NOTES/$item.txt";
 my $pre = "$timestamp\t$item\tinfo\tUNLOCK\t$user\n";
 &add_file($notes, $pre);
 return $item;
}


=head2 File Access

=head3 get_file()

Read a file from disk and load it on an memory array.

=cut

sub get_file() {
 my ($file) = @_;
 open(FILE_READ, $file);
 my @content = (<FILE_READ>);
 close(FILE_READ);
 return @content;
}

=head3 get_file_line()

Get a pre formated line with an unique id on a file.

=cut

sub get_file_line() {
 my ($file, $uniq) = @_;
 my $line = "";
 open(FILE_READ, $file);
 while (<FILE_READ>) {
  if ($_ =~ /^$uniq\,/) {
   $line = $_;
  }
 }
 close(FILE_READ);
 return $line;
}

=head3 new_file()

New file in disk or truncate an existing one.

=cut

sub new_file() {
 my ($file, $cont) = @_;
 open(FILE_WRITE, ">", $file);
 print FILE_WRITE $cont;
 close(FILE_WRITE);
 return undef;
}

=head3 add_file()

Append pre formated text to file.

=cut

sub add_file() {
 my ($file, $pre) = @_;
 open(FILE_WRITE, ">>", $file);
 print FILE_WRITE $pre;
 close(FILE_WRITE);
 return undef;
}

=head3 up_file()

Update a pre formated line with a unique id on a file.

=cut

sub up_file() {
 my ($file, $line, $uniq) = @_;
 my @content;
 open(FILE_READ, $file);
 while (my $old_line = <FILE_READ>) {
  if ($old_line =~ /^$uniq\,/) {
   push(@content, $line);
  }
  else {
   push(@content, $old_line);
  }
 }
 close(FILE_READ);
 open(FILE_WRITE, ">", $file);
 print FILE_WRITE @content;
 close(FILE_WRITE);
 return undef;
}

=head3 list_file()

List and filter files on a directory.

=cut

sub list_file() {
 my ($dir, $filter) = @_;
 opendir(DIR_READ, $dir);
 my @files = grep {!/^\./ and /$filter/} readdir(DIR_READ); 
 closedir(DIR_READ);
 return sort(@files);
}

=head2 Uncategorized

=head3 grap()

This function creates a color bar with the stats.

=cut

sub grap() {
 my ($total, $ok, $err) = @_;
 my $todo = $total - $ok - $err;
 my $html = "<div class='GRAP'>";
 while ($ok > 0) {
  $html .= "<span class='".$STATUS->[1]."'>/</span>";
  $ok--;
 }
 while ($err > 0) {
  $html .= "<span class='".$STATUS->[2]}."'>!</span>";
  $err--;
 }
 while ($todo > 0) {
  $html .= "<span class='".$STATUS->[0]}."'>.</span>";
  $todo--;
 }
 $html .= "</div>";
 return $html;
}

=head3 info()

This function checks if the item is locked and shows the item and user.

=cut

sub info() {
 my ($item, $lock) = @_;
 my $html = "<div class='INFO'>";
 if ($lock) {
  $html .= "<span class='WIP'>$lock - <a href='index.pl?do=check&item=".$item."'>$item</a></span>";
 }
 else {
  $html .= "<a href='index.pl?do=check&item=".$item."'>$item</a></span>";
 }
 $html .= "</div>";
 return $html;
}

=head3 list()

This function list the items showing the info and grap.

=cut

sub list() {
 my ($item) = @_;
 my ($html, $action, $edit);
 if ($item) {
  my (undef, $lock) = split(',', &get_file_line($FILE_STATS, $item));
  if ($lock eq $ENV{REMOTE_USER}) {
   $action = "<a href='index.pl?do=unlock&item=".$item."'>(unlock)</a></span>";
   $edit = 1;
  }
  elsif (!$lock) {
   $action = "<a href='index.pl?do=lock&item=".$item."'>(lock)</a></span>";
   $edit = 0;
  }
  else {
   $action = "";
   $edit = 0;
  }
  $html = $cgi->div({-class => 'ITEM'},
   $cgi->span({-class => 'LEFT'}, ""),
   $cgi->span({-class => 'CENTER'}, $item),
   $cgi->span({-class => 'RIGHT'}, $action),
  );
  my $file = "$DIR_LIST/$item.csv";
  foreach my $line (&get_file($file)) {
   my ($check, $status, $lock, $timestamp) = split(',', $line);
   my $form = "";
   if ($edit) {
    $form .= $cgi->start_form(-method  => 'post', -action => "index.pl?do=set&item=$item&check=$check", -encoding => &CGI::URL_ENCODED);
    $form .= $cgi->radio_group(-name => $check, -values  => $STATUS, -default => $status, -columns => 3, -rows => 1);
    $form .= $cgi->submit(-value => 'Set');
    $form .= $cgi->end_form();
   }
   $html .= $cgi->div({-class => 'ITEM'}, $cgi->span({-class => $status}, $check), $cgi->a({href=>"./", onclick=>"return popitup('index.pl?do=help&check=$check')"}, "(help)"), $form);
  }
 }
 else {
  foreach my $line (&get_file($FILE_STATS)) {
   my ($item, $lock, $timestamp, $total, $ok, $err) = split(',', $line);
   $html .= $cgi->div({-class => 'ITEM', -id => $item}, &info($item, $lock), &grap($total, $ok, $err));
  }
 }
 return $html;
}

=head3 note_form()

This function creates an add note form for a file.

=cut

sub note_form() {
 my ($file, $item, $help) = @_;
 my $html;
 if ($item =~ /^_/) {
  $html .= $cgi->start_form(-method  => 'post',
   -action => "index.pl?do=addnote&file=$file",
   -encoding => &CGI::URL_ENCODED
  );
 }
 elsif ($help) {
  $html .= $cgi->start_form(-method  => 'post',
   -action => "index.pl?do=addnote&file=$file&check=$help",
   -encoding => &CGI::URL_ENCODED
  );
 }
 else {
  $html .= $cgi->start_form(-method  => 'post',
   -action => "index.pl?do=addnote&file=$file&item=$item",
   -encoding => &CGI::URL_ENCODED
  );
 }
 $html .= $cgi->textarea(-name => $file, -value => '', -maxlength => 2048);
 $html .= $cgi->submit(-value => 'Add');
 $html .= $cgi->end_form();
 return $html;
}

=head3 notes()

List shared notes or note for an item.

=cut

sub notes() {
 my ($note, $help) = @_;
 my $html;
 $note ||= "_";
 foreach my $file (&list_file($DIR_NOTES, "^$note")) {
  my $form;
  if ($help) {
   $form = $cgi->div({-class => 'DOWN'}, &note_form($file, $note, $help));
  }
  else {
   $form = $cgi->div({-class => 'DOWN'}, &note_form($file, $note));
  }
  $html .= $cgi->div({-class => 'NOTE'},
   $cgi->div({-class => 'UP'}, $cgi->strong($file)),
   $cgi->div({-class => 'MID'}, &get_file("$DIR_NOTES/$file")),
   $form
  );
 }
 return $html;
}

=head3 get_stats()

Read stats file from disk and load it on an memory array.

=cut

sub get_stats() {
 my ($file) = @_;
 my $stats = {};
 foreach (@{$STATUS}) {
  $stats->{$_} = 0;
 }
 my $total = 0;
 foreach my $line (&get_file($file)) {
  my ($check, $status) = split(',', $line);
  foreach (@{$STATUS}) {
   if ($status =~ $_) {
    $stats->{$_}++;
   }
  }
  $total++;
 }
 return ($total, $stats->{$STATUS->[1]}, $stats->{$STATUS->[2]});
}

=head2 User Interface

=head3 print_index()

Generates the base html that will be printed.

=cut

sub print_stats() {
 return &print_index("Stats", "60", &list(undef), &notes(undef));
}

sub print_item() {
 my ($item) = @_;
 return &print_index("Checklist -> ".$item, "7200", &list($item), &notes($item));
}

sub print_help() {
 my ($note, $help) = @_;
 my $html = $cgi->header();
 $html .= $cgi->start_html(
  -title => "Lerl - Help",
  -style => { -code => $CSS },
 );
 $html .= $cgi->div({-id => 'help'}, &notes($note, $help));
 $html .= $cgi->end_html();
 return $html;
}

sub print_index() {
 my ($title, $ref, $left, $right) = @_;
 my $html = $cgi->header();
 $html .= $cgi->start_html(
  -title => "Lerl - ".$title,
  -style => { -code => $CSS },
  -script => $JAVASCRIPT,
  -head => $cgi->meta({
   -http_equiv => 'Refresh',
   -content    => $ref
  }),
  -onload => 'loadScroll()',
  -onunload => 'saveScroll()'
 );
 $html .= $cgi->div({-id => 'head'},
  $cgi->span({-class => 'LEFT'}, $cgi->a({href=>"./"}, "|^| (home)"), $cgi->a({href=>"?do=refresh"}, "(refresh)")),
  $cgi->span({-class => 'CENTER'}, "Lerl!"),
  $cgi->span({-class => 'RIGHT'}, $ENV{REMOTE_USER}." - ".$ENV{REMOTE_ADDR})
 );
 $html .= $cgi->div({-id => 'left'}, $left);
 $html .= $cgi->div({-id => 'right'}, $right);
 $html .= $cgi->div({-id => 'foot'}, "");
 $html .= $cgi->end_html();
 return $html;
}

=head1 AUTHOR

Andres Basile (basile@gmail.com)

=cut
1;
