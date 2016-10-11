#! /usr/bin/python
# -*- coding: euc-jp -*-;

'''
�Х��ʥ�ե�����Τ��ꤽ���ʥǥ��쥯�ȥ�(search_dirs(['/bin', '/lib', 
'/lib64', '/sbin', '/usr', '/opt']))�ʲ��ˤ���Х��ʥ�ե�����
(file ���ޥ�ɤ� ELF, dynamically linked ��
�֤��ե�����)�ˤĤ��ơ�ldd������̤�ǡ����١��� ./depends.sql3 ��
��Ͽ���롥root���¤Ǥ����ɤ�ʤ��ե�����⤢��Τǡ�sudo �Ǽ¹Ԥ��뤳�Ȥ�˾�ޤ�����

./depends.sql3 �ˤ� depends �Ȥ����ơ��֥뤬���ꡤ���Υơ��֥�ι�¤��
(base text, path text, soname text, realname text) �ȤʤäƤ��롥
  base �� �Х��ʥ�ե�����Υ١���̾(�ѥ�̵��)��
  path �� base �ؤΥѥ�
  soname : ɬ�פȤ��붦ͭ�饤�֥���soname
  realname : �嵭�饤�֥��Υѥ�̾�դ���̾��

��ĤΥ١���̾(�㤨�� cat)���Ф��ơ�path �ϰ��(/bin/cat)������
ʣ����soname ��realname ��ɬ�פȤʤ�Τǡ��ǡ����١����ˤϤ��Τ褦���¤�Ǥ���
 cat|/bin/cat|linux-vdso.so.1|none
 cat|/bin/cat|libc.so.6|/lib64/libc.so.6
 cat|/bin/cat|/lib64/ld-linux-x86-64.so.2|/lib64/ld-linux-x86-64.so.2

�ե�����ι���(�Ť��饤�֥��κ��)�����פ�����ˡ��̵���Τǡ��ǡ����١����򹹿�����ˤ�
�Ť��ե�����(./depends.sql3)�������ơ����٤��Υ��ޥ�ɤ�¹Ԥ��뤳�ȡ�
'''

import sqlite3, os, subprocess, sys, time

def init_db(dbname):
    conn = sqlite3.connect(dbname)
    conn.execute('''create table depends
       (base text, path text, soname text, realname text)''')
    conn.close

def insert_db(dbname, t):
    conn = sqlite3.connect(dbname)
    try:
        print "inserting ", t
        conn.execute('insert into depends values(?, ?, ?, ?)', t)
        conn.commit()
    except sqlite3.Error, e:
        print "An error occurred:", e.args[0]
        conn.rollback()

def get_elfs(path):
    exclude_dirs = ['include', 'etc', 'src', 'share', 'texmf', 'var', 'tmp', '/lib/modules' ]
    test = os.walk(path,followlinks=False)
    elfs = []
    for root, dirs, files in test:
        ex = False
        for exclude in exclude_dirs:
            if root.find(exclude) != -1:
                ex = True
                break

        if ex == False:
            for i in files:
                path = os.path.join(root,i)
                if os.path.islink(path) == False:
                    if check_elf(path) :
                        print("{0} is ELF".format(path))
                        elfs.append(path)
    return elfs

def check_elf(file):
    res = subprocess.check_output(['file', file])
    if res.find('ELF') > 0 and res.find('dynamically linked') > 0 and res.find('32-bit') == -1: 
        return True
    else:
        return False

def get_depends(file):
    list = []
    try:
        res = subprocess.check_output(['ldd', file])
        tmp = res.splitlines()
        for i in tmp:
            list.append(i.lstrip())

    except subprocess.CalledProcessError:
        print("error occured to ldd {0}. maybe different archs?".format(file))

    return list

def split_parts(l):
    (soname, sep, last) = l.partition(' => ')
    if soname == 'linux-vdso.so.1' :
        realname = 'none'
    elif soname.find('ld-linux') > 0:
        (t1, t2, t3) = soname.partition(' (')
        soname = t1
        realname = soname
    else:
        (realname, sep, last2) = last.partition(' (')
    
    return (soname, realname)
    
def main():
    
    dbname = './depends.sql3'
    if os.access(dbname, os.R_OK) == False:
        c = init_db(dbname)

    # lastflag = './lastchecked'
    # last_checked = get_lastchecked(lastflag)
    # print("last_checked:", time.ctime(last_checked))

    # search_dirs = ['/bin', '/etc', '/lib', '/lib64', '/opt', '/sbin', '/usr']
    search_dirs = ['/bin',  '/lib', '/lib64', '/sbin', '/usr', '/opt']

    for dir in search_dirs:
        print("searching {0}".format(dir))
        files = get_elfs(dir)
        list = []
        for file in files:
            base = os.path.basename(file)
            tmp = get_depends(file)
            for i in tmp:
                (soname, realname) = split_parts(i)
                print("{0}, {1}, {2}, {3}".format(base, file, soname, realname))
                t = (base, file, soname, realname)
                list.append(t)
            
        conn = sqlite3.connect(dbname)
        conn.executemany('insert into depends values(?, ?, ?, ?)', list)
        conn.commit()

if __name__ == "__main__":
    main()

