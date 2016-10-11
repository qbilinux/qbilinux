#!/usr/bin/perl

# initial version : ca 05/02
# modified for GNOME
# Time-stamp: <2006-04-13 14:34:55 kojima>

# makedesc.pl �� Plamo Linux �Υѥå���������ե�����(desc �ե�����)����
# ���󥹥ȡ������ɬ�פʳƼ�����ե������������륳�ޥ�ɤǤ���
#
# ���줾��Υǥ��쥯�ȥ�ˤ������ desc �ե�����(ap.desc ��)�Υե����ޥ�
# �Ȥ϶��Ԥ��쥳���ɥ��ѥ졼����& �������ƥॻ�ѥ졼����
# 
# ------------------------------------
# a & Plamo Base system                      (0)
#
# aaa_base & y & y & y & y                   (1)
# &
# Linux �δ���Ū�ʥե����륷���ƥ�ѥå����� (2)
# &
# ����Ū�ʥǥ��쥯�ȥ깽¤��������ơ�root �Υ᡼��ܥå���
# �� Linux ���ޥ᡼����ɲä��ޤ���:-) ���Υѥå������ϡ�
# ���ֺǽ�˥��󥹥ȡ��뤵�졢�褷�ƥ��󥤥󥹥ȡ��뤷�Ƥ�
# �����ޤ���                               (3)
# &
# Basic Linux file system package            (4)
# &
# This package makes basic directory structure and adds an
# email to root's mailbox welcoming them to Linux. :)
# This package should be installed first, and never
# uninstalled.                                (5)
#
# --------------------------------------------------
# �Ȥ�����¤�Ȥʤ롥�嵭�Τ��� (0) �� desc �ե��������Ƭ���֤��졤
# ���� desc �ե�����Τ���ǥ��쥯�ȥ�Ȥ��β���򵭽Ҥ���
#
# (1) �� �ѥå�����̾�ȡ֤�����ץ��󥹥ȡ���ǥ��󥹥ȡ��뤹�뤫�ݤ���
# ���������줾��֤�����פ� s(X ���饤����ȥ�٥�)��m(ɸ��Ū), k(m + KDE)��
# g(m + GNOME) �򼨤�

# �ѥå�����̾�� longname(aaa_base-4.0-i386-P1.tgz) �Ǥ� shortname(aaa_base)
# �����������Ѳ�ǽ������longname �ξ��ϥѥå�����̾�ȥС���������ޤǰ��פ�����
# ɬ�פ����뤿�ᡤ�̾�� shortname �ǵ��Ҥ���longname �� (2)(4)�Υѥå���������
# ���˽񤯤��Ȥ�˾�ޤ���
#
# (2) �ϥѥå����������ܸ쳵�ס�(3) �Ϥ��ܺ٤����ܸ����
# (4) �ϥѥå������αѸ쳵�ס�(5) �ϱѸ����Ȥʤ롥

# ���Υ�����ץ�(makedesc.pl)�Ǥ� desc �ե����뤫���ɤ߹�����ǡ����򸵤�
# @filelist �˥ѥå�����̾�Υꥹ�Ȥ���¸����Ϣ������
#
#    $tag_s{$i} : ������ s �ǥ��󥹥ȡ��뤹�뤫�ɤ��� [y/n]
#    $tag_m{$i} : ������ m �ǥ��󥹥ȡ��뤹�뤫�ɤ��� [y/n]
#    $tag_k{$i} : ������ k �ǥ��󥹥ȡ��뤹�뤫�ɤ��� [y/n]
#    $tag_g{$i} : ������ d �ǥ��󥹥ȡ��뤹�뤫�ɤ��� [y/n]
#    $jtitle{$i}: ���ܸ쳵��
#    $jdesc{$i} : ���ܸ����
#    $etitle{$i}: �Ѹ쳵��
#    $edesc{$i} : �Ѹ����
#
# �ˤ��줾��Υǡ������Ǽ���Ƥ��롥�ޤ���(0) �Υǥ��쥯�ȥ�̾�� $set��
# �ǥ��쥯�ȥ�β���� $kind  �Ȥ����ѿ��˳�Ǽ���롥
#
# makedesc �Υ��ץ����ϰʲ����̤�
# -m : (e)maketag �� (e)maketag.ez ���������
# -t : 5��(tagfile, tagfile.s, tagfile.m, tagfile.k, tagfile.g)���������
# -d : (e)diskXXX �ե�������������
# -a : �嵭 3 ���ޤȤ�Ƽ¹Ԥ���
# -c : desc �ե�����ε��Ҥȥǥ��쥯�ȥ���Υѥå����������פ��Ƥ��뤫�Υƥ���
# -v : �ʹԾ������Ĺɽ������
# -s : desc �ե������ alphabet ����¤��Ѥ���ɸ����Ϥ˽��Ϥ���
# -h : �إ�ץ�å�����

&print_usage if ($#ARGV < 1);

use Getopt::Std;
getopts("admtcvhs");

$datafile = $ARGV[0];

&print_usage() if $opt_h;

sub print_usage {
    print "$0 [-avcmth] <datafile>\n";
    print " -m : create (e)maketag(.ez)\n";
    print " -t : cretate tagfiles \n";
    print " -d : cretate (e)diskXXX \n";
    print " -a : create all \n";
    print " -c : check tgz files \n";
    print " -v : be vorbose \n";
    print " -h : show this message \n";
    print " -s : sort desc file in alphabetical order \n";
    print " <datafile> : diskset description file \n";
    exit;
}

sub truncate {
    $old = $_[0];
    $new = $old;
    # $new =~ s/\n//g;
    $new =~ s/^[\s]+//;
    $new =~ s/[\s]+$//;
    return ($new);
}

sub check_name {
    $pkgname = $_[0];
    $c = (@part) = split("-", $pkgname);
    if ( $c >= 3 && $part[$#part] =~ /^P[0-9]+/ ) { # new style
	$build = pop(@part);
	$arch = pop(@part);
	$vers = pop(@part);
	$pkgbase = join("-", @part);
    }
    else {
	$pkgbase = $pkgname;
    }
    return $pkgbase;
}

$/ = "";
if ( ! -f $datafile) {
    print "cannot find diskset description file!! \n";
    exit;
}
open (IN, "$datafile");
$tmpdt = <IN>;
($set, $kind) = split(/&/, $tmpdt);
$set = &truncate($set);
$kind = &truncate($kind);
print "set:$set, kind:$kind\n" if $opt_v;
@lines = <IN>;
close(IN);
for $i (@lines) {
    $data_count = @tmpdt = split(/&/, $i);
    if ( $data_count == 9) {
        ($tmpd1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9) = split(/&/, $i);
    }
    else {
        ($tmpd1, $d2, $d3, $d4, $d5, $d6, $d7) = split(/&/, $i);
    }

    $tmpd1 = &truncate($tmpd1);
    push(@filenamelist, $tmpd1);

    $d1 = &check_name($tmpd1);
    for $j (1..9) {
    	$tmp = "d".$j;
    	$$tmp = &truncate($$tmp);
    }

    if ( $data_count == 9 ) {
	push(@tmplist, $d1);
	$tag_s{$d1}  = $d2;
	$tag_m{$d1}  = $d3;
	$tag_k{$d1}  = $d4;
	$tag_g{$d1}  = $d5;
	$jtitle{$d1} = $d6;
	$jdesc{$d1} = $d7;
	$jdesc{$d1} =~ s/\\n//g;
	$etitle{$d1} = $d8;
	$edesc{$d1} = $d9;
	$edesc{$d1} =~ s/\\n//;
    }
    else {  # old format
	push(@tmplist, $d1);
	$tag_s{$d1}  = $d2;
	$tag_m{$d1}  = $d3;
	$tag_k{$d1}  = "y";
	$tag_g{$d1}  = "y";
	$jtitle{$d1} = $d4;
	$jdesc{$d1} = $d5;
	$jdesc{$d1} =~ s/\\n//g;
	$etitle{$d1} = $d6;
	$edesc{$d1} = $d7;
	$edesc{$d1} =~ s/\\n//;
    }
}
@filelist = sort( @tmplist );

&checkfiles() if $opt_c;
&sortdesc() if $opt_s;

if ( $opt_a ) {
    $opt_t = $opt_d = $opt_m = $opt_a;
}

if ( $opt_d ) {
    &diskfile;
    &ediskfile;
}

if ( $opt_m ) {
    &maketag;
    &maketag_ez;
    &emaketag;
    &emaketag_ez;
}

if ( $opt_t ) {
    &tagfiles;
}

sub format {
    require 'fold.pl';
    $text = $_[0];
    my $bytes = 60;
    my $results = "";
    while (length($text)) {
	(my $folded, $text) = fold($text, $bytes,0,1,'t', 1);
	$results = $results.$folded."\n";
    }
    return $results;
}

sub diskfile {
    $name = "disk".$set;
    print "making $name\n" if $opt_v;
    # system("mv $name $name.old") if ( -f $name);

    open (OUT, ">$name");
    print OUT "CONTENTS: ";
    for $i (@filelist) {
	print OUT "$i ";
    }
    print OUT "\n";
    for $i (@filelist) {
	@tmplines = split(/\n/, $jdesc{$i});
	printf(OUT "%s %s\n", $i.":", $jtitle{$i});
	printf(OUT "%s \n", $i.":");
	for ($j = 2; $j < 11; $j++) {
	    printf(OUT "%s %s\n", $i.":", $tmplines[$j-2]);
	}
    }
    close(OUT);
    chmod(0664, $name);
}

sub ediskfile {
    $name = "edisk".$set;
    print "making $name\n" if $opt_v;
    # system("mv $name $name.old") if ( -f $name);

    open (OUT, ">$name");
    print OUT "CONTENTS: ";
    for $i (@filelist) {
	print OUT "$i ";
    }
    print OUT "\n";
    for $i (@filelist) {
	@tmplines = split(/\n/, $edesc{$i});
	printf(OUT "%s %s\n", $i.":", $etitle{$i});
	printf(OUT "%s \n", $i.":");
	for ($j = 2; $j < 11; $j++) {
	    printf(OUT "%s %s\n", $i.":", $tmplines[$j-2]);
	}
    }
    close(OUT);
    chmod(0664, $name);
}

sub maketag {
    print "making maketag\n" if $opt_v;
    # system("mv maketag maketag.old") if ( -f "maketag");

    open (OUT, ">maketag");
    print OUT "#!/bin/sh\n";
    print OUT "cat /dev/null > /tmp/SeTnewtag\n";
    print OUT "dialog --title \"$set($kind)���꡼��������\" \\\n";
    print OUT "  --checklist \"$set ���꡼�����椫�饤�󥹥ȡ��뤷�����ѥå������� \\\n";
    print OUT "����Ǥ�����������������ξ岼������ \\\n";
    print OUT "�оݤ����򤷡�space �����ǥޡ���(X)���ޤ��� \\\n";
    print OUT "Enter �����ǥ��󥹥ȡ���򳫻Ϥ��ޤ���\" 24 72 15 \\\n";
    for $i (@filelist) {
	printf(OUT "\"%s\" \"%s\" \"%s\" \\\n", $i, $jtitle{$i}, $tag_s{$i} =~ /[Yy]/ ? "on" : "off");
    }
    print OUT "2> /tmp/SeTpkgs\n";
    print OUT "if [ \$\? = 1 -o \$\? = 255 ]; then\n";
    print OUT "  rm -f /tmp/SeTpkgs\n";
    print OUT "  > /tmp/SeTnewtag\n";
    print OUT "  for pkg in ";
    for $i (@filelist){ print OUT "$i "};
    print OUT " ; do \n";
    print OUT "  echo \"\$pkg: SKP\" >> /tmp/SeTnewtag\n";
    print OUT "  done\n";
    print OUT "  exit\n";
    print OUT "fi\n";
    print OUT "cat /dev/null > /tmp/SeTnewtag\n";
    print OUT "for PACKAGE in ";
    for $i (@filelist) {print OUT "$i "};
    print OUT " ; do\n";
    print OUT "    if grep \"\$PACKAGE\" /tmp/SeTpkgs 1> /dev/null 2> /dev/null ; then\n";
    print OUT "        echo \"\$PACKAGE: ADD\" >> /tmp/SeTnewtag\n";
    print OUT "    else echo \"\$PACKAGE: SKP\" >> /tmp/SeTnewtag\n";
    print OUT "    fi\n";
    print OUT "done\n";
    print OUT "rm -f /tmp/SeTpkgs\n";

    close(OUT);
    chmod(0664, "maketag");
}

sub emaketag {
    print "making emaketag\n" if $opt_v;
    # system("mv emaketag emaketag.old") if ( -f "emaketag");

    open (OUT, ">emaketag");
    print OUT "#!/bin/sh\n";
    print OUT "cat /dev/null > /tmp/SeTnewtag\n";
    print OUT "dialog --title \"select pkgs from $set($kind)\" \\\n";
    print OUT "  --checklist \"select packages from $set series. \\\n";
    print OUT "You can move cursor with UP/DOWN key and push space \\\n";
    print OUT "key to select pkgs. After finish selecting, \\\n";
    print OUT "push Enter to start installation. \" 24 72 15 \\\n";
    for $i (@filelist) {
	printf(OUT "\"%s\" \"%s\" \"%s\" \\\n", $i, $etitle{$i}, $tag_s{$i} =~ /[Yy]/ ? "on" : "off");
    }
    print OUT "2> /tmp/SeTpkgs\n";
    print OUT "if [ \$\? = 1 -o \$\? = 255 ]; then\n";
    print OUT "  rm -f /tmp/SeTpkgs\n";
    print OUT "  > /tmp/SeTnewtag\n";
    print OUT "  for pkg in ";
    for $i (@filelist){ print OUT "$i "};
    print OUT " ; do \n";
    print OUT "  echo \"\$pkg: SKP\" >> /tmp/SeTnewtag\n";
    print OUT "  done\n";
    print OUT "  exit\n";
    print OUT "fi\n";
    print OUT "cat /dev/null > /tmp/SeTnewtag\n";
    print OUT "for PACKAGE in ";
    for $i (@filelist) {print OUT "$i "};
    print OUT " ; do\n";
    print OUT "    if grep \"\$PACKAGE\" /tmp/SeTpkgs 1> /dev/null 2> /dev/null ; then\n";
    print OUT "        echo \"\$PACKAGE: ADD\" >> /tmp/SeTnewtag\n";
    print OUT "    else echo \"\$PACKAGE: SKP\" >> /tmp/SeTnewtag\n";
    print OUT "    fi\n";
    print OUT "done\n";
    print OUT "rm -f /tmp/SeTpkgs\n";

    close(OUT);
    chmod(0664, "emaketag");
}

sub maketag_ez {
    print "making maketag_ez\n" if $opt_v;
    # system("mv maketag.ez maketag.ez.old") if ( -f "maketag.ez");

    open (OUT, ">maketag.ez");
    print OUT "#!/bin/sh\n";

    $count_s = 0;
    for $i (@filelist) {
	$count_s++ if ($tag_s{$i} !~ /[Yy]/ );
    }

    if ( $count_s > 0) {
	print OUT "cat /dev/null > /tmp/SeTnewtag\n";
	print OUT "dialog --title \"$set($kind)���꡼��������\" \\\n";
	print OUT "  --checklist \"$set ���꡼�����椫�饤�󥹥ȡ��뤷�����ѥå������� \\\n";
	print OUT "����Ǥ��������������ƥ��ɬ�ܤΥѥå������� \\\n";
	print OUT "��ưŪ�˥��󥹥ȡ��뤵���Τ�ɽ������ޤ��� \\\n";
	print OUT "��������ξ岼�������оݤ����򤷡� \\\n";
	print OUT "space �����ǥޡ���(X)���ޤ��� \\\n";
	print OUT "Enter �����ǥ��󥹥ȡ���򳫻Ϥ��ޤ���\" 24 72 12 \\\n";
	for $i (@filelist) {
	    if ($tag_s{$i} !~ /[Yy]/ ) {
		printf(OUT "\"%s\" \"%s\" \"%s\" \\\n", $i, $jtitle{$i}, $tag_m{$i} =~ /[Yy]/ ? "on" : "off");
	    }
	}
	print OUT "2> /tmp/SeTpkgs\n";
	print OUT "if [ \$\? = 1 -o \$\? = 255 ]; then\n";
	print OUT "  rm -f /tmp/SeTpkgs\n";
	print OUT "  > /tmp/SeTnewtag\n";
	print OUT "  for pkg in ";
	for $i (@filelist){ print OUT "$i "};
	print OUT " ; do \n";
	print OUT "  echo \"\$pkg: SKP\" >> /tmp/SeTnewtag\n";
	print OUT "  done\n";
	print OUT "  exit\n";
	print OUT "fi\n";
    }
    print OUT "cat /dev/null > /tmp/SeTnewtag\n";
    print OUT "for PACKAGE in ";
    for $i (@filelist) {
	if ( $tag_s{$i} =~ /[Yy]/ ) {
	    print OUT "$i ";
	}
    }
    print OUT " ; do\n";
    print OUT "    echo \"\$PACKAGE: ADD\" >> /tmp/SeTnewtag\n";
    print OUT "done\n";
    print OUT "for PACKAGE in ";
    for $i (@filelist) {
	if ( $tag_s{$i} !~ /[Yy]/) {
	    print OUT "$i ";
	}
    }
    print OUT "  ; do\n";
    print OUT "    if grep \"\$PACKAGE\" /tmp/SeTpkgs 1> /dev/null 2> /dev/null ; then\n";
    print OUT "        echo \"\$PACKAGE: ADD\" >> /tmp/SeTnewtag\n";
    print OUT "    else echo \"\$PACKAGE: SKP\" >> /tmp/SeTnewtag\n";
    print OUT "    fi\n";
    print OUT "done\n";
    print OUT "rm -f /tmp/SeTpkgs\n";

    close(OUT);
    chmod(0664, "maketag.ez");
}

sub emaketag_ez {
    print "making emaketag_ez\n" if $opt_v;
    # system("mv emaketag.ez emaketag.ez.old") if ( -f "emaketag.ez");

    open (OUT, ">emaketag.ez");
    print OUT "#!/bin/sh\n";
    print OUT "cat /dev/null > /tmp/SeTnewtag\n";
    print OUT "dialog --title \"select pkgs from $set($kind)\" \\\n";
    print OUT "  --checklist \"select packages from $set series. Mandatory packages  \\\n";
    print OUT "are automatically selected and wouldn't apper this list. \\\n";
    print OUT "Move cursor with UP/DOWN key and push space key to select(mark). \\\n";
    print OUT "Push Enter to start install. \" 24 72 14 \\\n";
    for $i (@filelist) {
	if ($tag_s{$i} !~ /[Yy]/ ) {
	    printf(OUT "\"%s\" \"%s\" \"%s\" \\\n", $i, $etitle{$i}, $tag_m{$i} =~ /[Yy]/ ? "on" : "off");
	}
    }
    print OUT "2> /tmp/SeTpkgs\n";
    print OUT "if [ \$\? = 1 -o \$\? = 255 ]; then\n";
    print OUT "  rm -f /tmp/SeTpkgs\n";
    print OUT "  > /tmp/SeTnewtag\n";
    print OUT "  for pkg in ";
    for $i (@filelist){ print OUT "$i "};
    print OUT " ; do \n";
    print OUT "  echo \"\$pkg: SKP\" >> /tmp/SeTnewtag\n";
    print OUT "  done\n";
    print OUT "  exit\n";
    print OUT "fi\n";
    print OUT "cat /dev/null > /tmp/SeTnewtag\n";
    print OUT "for PACKAGE in ";
    for $i (@filelist) {
	if ( $tag_s{$i} =~ /[Yy]/ ) {
	    print OUT "$i ";
	}
    }
    print OUT " ; do\n";
    print OUT "    echo \"\$PACKAGE: ADD\" >> /tmp/SeTnewtag\n";
    print OUT "done\n";
    print OUT "for PACKAGE in ";
    for $i (@filelist) {
	if ( $tag_s{$i} !~ /[Yy]/) {
	    print OUT "$i ";
	}
    }
    print OUT "  ; do\n";
    print OUT "    if grep \"\$PACKAGE\" /tmp/SeTpkgs 1> /dev/null 2> /dev/null ; then\n";
    print OUT "        echo \"\$PACKAGE: ADD\" >> /tmp/SeTnewtag\n";
    print OUT "    else echo \"\$PACKAGE: SKP\" >> /tmp/SeTnewtag\n";
    print OUT "    fi\n";
    print OUT "done\n";
    print OUT "rm -f /tmp/SeTpkgs\n";

    close(OUT);
    chmod(0664, "emaketag.ez");
}

sub tagfiles {
    print "making tagfiles\n" if $opt_v;

    # for $i ('tagfile', 'tagfile.l', 'tagfile.m', 'tagfile.s') {
    #	system("mv $i $i.old") if ( -f $i );
    # }

    for $i ('tagfile', 'tagfile.m', 'tagfile.l', 'tagfile.k', 'tagfile.g' ){
	unlink( $i ) if ( -f $i);
    }

    open (OUT, ">tagfile");
    for $i (@filelist) {
	printf(OUT "%s %s\n", $i.":", $tag_m{$i} =~ /[Yy]/ ? "ADD": "SKP");
    }
    close(OUT);
    chmod (0664, "tagfile");

    open (OUT, ">tagfile.s");
    for $i (@filelist) {
	printf(OUT "%s %s\n", $i.":", $tag_s{$i} =~ /[Yy]/ ? "ADD": "SKP");
    }
    close(OUT);
    chmod (0664, "tagfile.s");

    open (OUT, ">tagfile.m");
    for $i (@filelist) {
	printf(OUT "%s %s\n", $i.":", $tag_m{$i} =~ /[Yy]/ ? "ADD": "SKP");
    }
    close(OUT);
    chmod (0664, "tagfile.m");


    open (OUT, ">tagfile.k");
    for $i (@filelist) {
        printf(OUT "%s %s\n", $i.":", $tag_k{$i} =~ /[Yy]/ ? "ADD":"SKP");
    }
    close(OUT);
    chmod (0664, "tagfile.k");

    open (OUT, ">tagfile.g");
    for $i (@filelist) {
	printf(OUT "%s %s\n", $i.":", $tag_g{$i} =~ /[Yy]/ ? "ADD": "SKP");
    }
    close(OUT);
    chmod (0664, "tagfile.g");

}

sub checkfiles {
    opendir (DIR, ".");
    @tmpfiles = sort grep { /tgz$/ } readdir(DIR);
    closedir(DIR);
    for $i ( @tmpfiles ) {
	$i =~ s/.tgz//;
	push (@tgzs, $i);
    }

    $warn = 0;
    for $i ( @filenamelist ) {
	$match = 0;
	for $j ( @tgzs ) {
	    if ( $i eq $j ) {
		$match = 1;
		break;
	    }
	}

	# desc file �� short name �ǡ�tgz �� long name �ξ��
	if ($match != 1) {
	    for $j ( @tgzs ) {
		if ( $i eq &check_name($j) ) {
		    $match = 1;
		    break;
		}
	    }
	}	    
	# desc file �� long name �ǡ�tgz �� short name �ξ��
	if ($match != 1) {
	    for $j ( @tgzs ) {
		if ( &check_name($i) eq $j ) {
		    $match = 1;
		    break;
		}
	    }
	}	    

	if ($match != 1) {
	    print "$i is in descfile($datafile) but not $i.tgz or $i-XXX-XXX-P1.tgz found here.\n";
	    $warn++;
	}
    }
    for $i ( @tgzs ) {
	$match = 0;
	for $j ( @filenamelist ) {
	    if ( $i eq $j ) {
		$match = 1;
		$break;
	    }
	}

	# tgz �� short name �� desc file �� long name �ξ��
	if ( $match != 1 ) {
	    for $j ( @filenamelist ) {
		if ( $i eq &check_name($j) ) {
		    $match = 1;
		    $break;
		}
	    }
	}

	# tgz �� long name �� desc file �� short name �ξ��
	if ( $match != 1 ) {
	    for $j ( @filenamelist ) {
		if ( &check_name($i) eq $j ) {
		    $match = 1;
		    $break;
		}
	    }
	}

	if ( $match != 1 ) {
	    print "$i.tgz exists but not in descfile($datafile)\n";
	    $warn++;
	}
    }
    if ( $warn == 0 ) {
	print "No error found\n";
    }
    else {
	print "Total warn: $warn\n";
    }
}

sub sortdesc {
    # system("mv $datafile $datafile.old")
    
    print "$set & $kind\n\n";

    for $i (@filelist) {
	printf("%s & ", $i);
	printf("%s & %s & %s & %s\n", $tag_s{$i}, $tag_m{$i}, $tag_k{$i}, $tag_g{$i});
	printf("&\n%s\n&\n%s\n", $jtitle{$i}, $jdesc{$i});
	printf("&\n%s\n&\n%s\n\n", $etitle{$i}, $edesc{$i});
    }
}	
