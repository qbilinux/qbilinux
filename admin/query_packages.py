#! /usr/bin/python3
# -*- coding: utf-8 -*-;

'''
get_depends.py, get_packages.py で作成した ~/depends.sql3 データベースを元に，
ELF形式のバイナリファイルが必要とするパッケージ(共有ライブラリ)を検索したり，
共有ライブラリを使っているパッケージを検索(逆引き)したりする．

-b が正引きでファイル名(例えば cat)のみを検索対象にする．
-s が逆引きでその共有ライブラリを使っているパッケージを調べる．
'''

import sqlite3, os, getopt, sys

def usage():
    print("Usage:")
    print((" {0} [-b name] [-s soname ]".format(sys.argv[0])))
    print("   ./depends.sql3 データベースを用いて，ライブラリの依存関係を調べる．")
    print("   -b name: name が依存しているパッケージを表示する")
    print("      -b の場合，パス名は見ずに，ファイル名のみで検索する")
    print("   -s soname: 共有ライブラリ soname を利用するパッケージを表示する")
    print("      -s libgtk-3.so.0 libgtk-3.so.0 のみマッチする")
    print("      -s の場合，パス名は見ずに，共有ライブラリ名のみで検索する")

def get_opts():
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "b:s:", ["base=","soname="])
    except getopt.GetoptError:
        usage()
        sys.exit(2)

    for o, a in opts:
        if o in ("-b", "--base"):
            cmd = 'base'
            arg = a
            sql = "select * from depends left outer join packages on packages.basename like '%' || depends.soname || '%' where depends.base = '{0}';".format(arg)
        elif o in ("-s", "--soname"):
            cmd = 'soname'
            arg = a
            sql = "select * from packages left outer join depends on packages.realname = substr(depends.path,2) where depends.soname = '{0}' group by packages.name, packages.realname;".format(arg)
        else:
            assert False, "unhundled option"
            usage()
    
    return (cmd, sql, arg)

def query(db, cmd, sql, arg):
    conn = sqlite3.connect(db)
    cur = conn.cursor()
    cur.execute(sql)
    tgt = []
    for i in cur:
        tgt.append(i)

    # format
    if cmd == 'base' :
        print(("{0} needs these packages".format(arg)))
        result = {}
        for row in tgt:
            (base, path, soname, realname, pkgname, pkgfile, pkgpath) = row
            if pkgname in result:
                result[pkgname].append((soname, realname))
            else:
                result[pkgname] = [(soname, realname)]

        # print tgt
        for k, v in result.items():
            print(("  {0}".format(k)))
            for (s, p) in v:
                print("      {0} ({1})".format(s, p))

    else:
        print(("{0} used by these packages".format(arg)))
        result = {}
        for row in tgt:
            (pkgname, pkgfile, pkgpath, base, path, soname, realname) = row
            if pkgname in result:
                result[pkgname].append(path)
            else:
                result[pkgname] = [path]

        # print tgt
        for k, v in result.items():
            print(("  {0}".format(k)))
            for l in v:
                print("      {0}".format(l))

def main():
    dbname = './depends.sql3'
    if os.access(dbname, os.R_OK) == False:
        print(("cannot open database:{0}".format(dbname)))

    (cmd, sql, arg) = get_opts()
    query(dbname, cmd, sql, arg)

if __name__ == "__main__":
    main()
