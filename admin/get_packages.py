#! /usr/bin/python3
# -*- coding: euc-jp -*-;

'''
�ѥå����������ե�����Τ���ǥ��쥯�ȥ� (/var/log/packages) �ʲ��ˤ���
�ե����뤫��ѥå�����̾�Ȥ��Υѥå������˴ޤޤ��ե�����̾����Ф���
�ǡ����١��� ./depends.sql3 �˵�Ͽ���롥sudo �Ǽ¹Ԥ��뤳�Ȥ�˾�ޤ�����

./depends.sql3 �ˤ� packages �Ȥ����ơ��֥뤬���ꡤ���Υơ��֥�ι�¤��
(name text, basename text, realname text) �ȤʤäƤ��롥
  name �� �ѥå�����̾��
  basename �� �ޤޤ��ե�����̾
  realname : �嵭�ե�����̾�Υѥ�̾�դ���̾��

��ĤΥѥå�����̾(�㤨�� file)���Ф��ơ��ǡ����١����ˤϤ��Τ褦���¤�Ǥ���
 file|doinst.sh|install/doinst.sh
 file|file|usr/bin/file
 file|magic.h|usr/include/magic.h

�ǡ����١����򹹿�����ˤϺ��٤��Υ��ޥ�ɤ�¹Ԥ���Ф褤��
'''

import sqlite3, os, subprocess, sys, time, re

def init_db(dbname):
    conn = sqlite3.connect(dbname)
    conn.execute('''create table packages
       (name text, basename text, realname text)''')
    conn.close

def clear_table(dbname):
    conn = sqlite3.connect(dbname)
    conn.execute('''drop table if exists packages''')
    conn.close
    init_db(dbname)

def insert_db(dbname, t):
    conn = sqlite3.connect(dbname)
    try:
        print(("inserting ", t))
        conn.execute('insert into packages values(?, ?, ?)', t)
        conn.commit()
    except sqlite3.Error as e:
        print(("An error occurred:", e.args[0]))
        conn.rollback()

def get_files(path):
    exclude_dirs = ['include', 'etc', 'src', 'share', 'texmf', 'var', 'tmp', '/lib/modules' ]
    test = os.walk(path,followlinks=False)
    elfs = []
    for root, dirs, files in test:
        for i in files:
            path = os.path.join(root,i)
            if os.path.islink(path) == False:
                print(("{0} is append".format(path)))
                elfs.append(path)
    return elfs

def main():
    
    dbname = './depends.sql3'
    if os.access(dbname, os.R_OK) == False:
        c = init_db(dbname)
    else:
        c = clear_table(dbname)

    # lastflag = './lastchecked'
    # last_checked = get_lastchecked(lastflag)
    # print("last_checked:", time.ctime(last_checked))

    search_dirs = ['/var/log/packages']

    for dir in search_dirs:
        files = get_files(dir)
        list = []
        for file in files:
            name = os.path.basename(file)
            with open(file) as f:
                list_flag = False
                for line in f:
                    tmp = line.strip()
                    if 'FILE LIST:' == tmp:
                        list_flag = True
                        continue
                    if list_flag:
                        if re.match('.*/$', tmp):
                            continue
                        else:
                            basename = os.path.basename(tmp)
                            t = (name, basename, tmp)
                            list.append(t)

        conn = sqlite3.connect(dbname)
        conn.executemany('insert into packages values(?, ?, ?)', list)
        conn.commit()

if __name__ == "__main__":
    main()

