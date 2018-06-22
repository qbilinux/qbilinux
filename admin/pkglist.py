#!/usr/bin/python2
# -*- coding: euc-jp -*-

import os, pickle
import sys

args=sys.argv
argc=len(args)

if (argc != 2):
    print("Script to create allpkgs.pickle for get_pkginfo.py")
    print("")
    print("Usage: "+args[0]+" topdir")
    print("")
    print("   ex) "+args[0]+" Plamo-6.x/")
    print("")
    quit()

basedir = args[1] + '/'
archdir = ('x86/', 'x86_64/', 'armv7/', 'armv7_hf/')
channel = ('plamo', 'contrib')

'''
__blockpkgs: updatepkg �����ǥ��åץǡ��ȤǤ��ʤ��ѥå������ϡ��ǥե���
�ȤǤ�ɽ�����ʤ��褦�ˤ��롥
������ get_pkginfo.py �� -b ���ץ�������ꤹ��С��������碌��ɽ
������롥
'''
blockpkgs = ['aaa_base', 'devs', 'etc', 'hdsetup', 'network_configs',
        'shadow', 'sysvinit']

'''
__replaces: ��̾��ʬ�䡤���󤵤줿�ѥå����������פ��뤿��ˡ���ѥå�
����̾�򿷥ѥå�����̾�˥ޥåפ��롥
ex: 'tamago' -> 'tamago_tsunagi'
    'python' -> 'Python2', 'Python3' -> 'Python'
'''
replace_list = {'tamago': 'tamago_tsunagi', 'python': 'Python2',
        'Python3': 'Python', 'pycups2': 'py2cups', 'pycurl2': 'py2curl'}

'''
__no_install: �����Υѥå������� updatepkg -f �ʳ��κ�Ȥ�ɬ�פˤʤ�
�Τǡ���������ɤϤǤ��뤬��ư���󥹥ȡ���Ϥ��ʤ���
'''
no_install = ['grub', 'lilo', 'kernel', 'kernel_headers', 'kernelsrc',
        'timezone', 'docbook_xml_4.1.2', 'docbook_xml_4.2', 'docbook_xml_4.3',
        'docbook_xml_4.4', 'docbook_xml_4.5', 'docbook_xml_5.0']

for arch in archdir:
    allpkgs= {}
    allpkgs['__blockpkgs'] = blockpkgs
    allpkgs['__replaces'] = replace_list
    allpkgs['__no_install'] = no_install
    for ch in channel:
        pkg_path = '{}{}{}/'.format(basedir, arch, ch)
        for root, dirs, files in os.walk(pkg_path):
            if 'old' in dirs:
                dirs.remove('old')
            if 'NG' in dirs:
                dirs.remove('NG')
            if '11_mate.old' in dirs:
                dirs.remove('11_mate.old')
            for i in files:
                if '.txz' in i or '.tgz' in i:
                    #print i
                    (base, vers, p_arch, tmp) = i.split('-')
                    (build, ext) = tmp.split('.')
                    path = root.replace(basedir + arch, '')
                    allpkgs[base] = (vers, p_arch, build, ext, path)
    with open('{}allpkgs.pickle'.format(basedir + arch), 'w') as f:
        pickle.dump(allpkgs, f)
