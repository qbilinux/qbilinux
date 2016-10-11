#! /usr/bin/python
# -*- coding: euc-jp -*-;

'''
get_depends.py�Ǻ������� ~/depends.sql3 �ǡ����١����򸵤ˡ�
ELF�����ΥХ��ʥ�ե����뤬ɬ�פȤ��붦ͭ�饤�֥��򸡺�(������)�����ꡤ
��ͭ�饤�֥���ȤäƤ���Х��ʥ�ե�����򸡺�(�հ���)�����ꤹ�롥
-b, -p ���������ǡ�-b �ϥե�����Υ١���̾(�㤨�� cat)�Τߤ򸡺��оݤˤ��롥
������-p �Ǥϥե�����Υѥ�̾(/bin/cat)�⸡���оݤˤ��롥

-s, -r ���հ����ǡ�-s ����ͭ�饤�֥���soname(libuuid.so.1)���顤
���ζ�ͭ�饤�֥���ȤäƤ���ե������Ĵ�٤롥-r ����ꤹ���
����ͭ�饤�֥��ؤΥѥ�̾(/usr/lib64/libuuid.so.1)�⸡���оݤˤ��롥
'''

import sqlite3, os, getopt, sys

def usage():
    print("Usage:")
    print(" {0} [-b name] [-p path ] [-s soname ] [-r realname]".format(sys.argv[0]))
    print("   ./depends.sql3 �ǡ����١������Ѥ��ơ��饤�֥��ΰ�¸�ط���Ĵ�٤롥")
    print("   -b name: name ���ޤޤ��ELF�����ΥХ��ʥ�ե����뤬�Ȥ���ͭ�饤�֥���ɽ������")
    print("      -b cat �Ȥ���� /bin/cat �����Ǥʤ���bdftruncate �� fc-cat ��ޥå�����")
    print("      -b �ξ�硤�ѥ�̾�ϸ����ˡ��ե�����̾�ΤߤǸ�������")
    print("   -p name: �����κݤ˥ѥ�̾��ޤ�ƥޥå������롥-p /bin/cat �Ȥ���� /bin/cat �Τߤ˥ޥå�����")
    print("   -s soname: ��ͭ�饤�֥�� soname �����Ѥ���Х��ʥ�ե������ɽ������")
    print("      -s libgtk libgtk-3.so.0 �� libgtk-x11-2.0.so ��ޥå�����")
    print("      -s �ξ�硤�ѥ�̾�ϸ����ˡ���ͭ�饤�֥��̾�ΤߤǸ�������")
    print("   -r realname: �����κݤ˥饤�֥��Υѥ�̾��ޤ��")

def get_opts():
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "b:p:s:r:", ["base=","path=","soname=", "realname="])
    except getopt.GetoptError:
        usage()
        sys.exit(2)

    for o, a in opts:
        if o in ("-b", "--base"):
            cmd = 'base'
            arg = a
        elif o in ("-p", "--path"):
            cmd = 'path'
            arg = a
        elif o in ("-s", "--soname"):
            cmd = 'soname'
            arg = a
        elif o in ("-r", "--realname"):
            cmd  = 'realname'
            arg = a
        else:
            assert False, "unhundled option"
            usage()
    
    # print("result:{0},{1}".format(cmd, arg))
    return (cmd, arg)

def query(db, cmd, arg):
    conn = sqlite3.connect(db)
    cur = conn.cursor()
    sql = 'select {0} from depends where {0} like "%{1}%" group by {0};'.format(cmd, arg)
    # print sql
    cur.execute(sql)
    tgt = []
    for i in cur:
        tgt.append(i[0])

    # print tgt
    for i in tgt:
        if cmd == 'base' or cmd == 'path' :
            print("{0} needs these libraries".format(i))
        else:
            print("{0} used by these binaries".format(i))

        sql = 'select * from depends where {0}="{1}";'.format(cmd, i)
        # print sql
        cur.execute(sql)
        for row in cur:
            (base, path, soname, realname) = row
            if cmd == 'base' or cmd == 'path' :
                print("  {0}({1})".format(soname, realname))
            else:
                print("  {0}({1})".format(base, path))
        print
def main():
    dbname = './depends.sql3'
    if os.access(dbname, os.R_OK) == False:
        print("cannot open database:{0}".format(dbname))

    (cmd, arg) = get_opts()
    query(dbname, cmd, arg)

if __name__ == "__main__":
    main()
