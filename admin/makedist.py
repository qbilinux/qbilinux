#!/usr/bin/python

import os
import sys
import fnmatch
import shutil
import codecs

args=sys.argv
argc=len(args)

#print(args)
#print(argc)

def fild_all_files(directory):
    for root, dirs, files in os.walk(directory):
        yield root
        for file in files:
            yield os.path.join(root, file)

if (argc != 3):
    print("")
    print("copy pakege file and make tagfile form Plamo Linux distrobution.")
    print("")
    print("Usage: "+args[0]+" buildir destdie")
    print("")
    print("   buildir: directory contains package and desc file.")
    print("   destdir: direcotry for Plamo Linux distrobution")
    print("")
    print("   ex) "+args[0]+" Plamo-src/plamo Plamo-hoge/x86_64")
    quit()
    
for file in fild_all_files(args[1]):
    if fnmatch.fnmatch(file, '*/00header.desc'):
        print("###########")
        print(file)
        srcpath=os.path.dirname(file)
        srcfile=os.path.basename(file)
        srcparentpath=os.path.dirname(srcpath)
        dstpath=os.path.join(args[2], srcpath)
        dstfile=os.path.join(dstpath, srcfile)
        pkglist = []
        desclist = []
        for ll in os.listdir(srcpath):
            if os.path.isdir(os.path.join(srcpath, ll)):
                basename, ext=os.path.splitext(ll)
                flg_name = 0
                flg_head = 0
                for lll in os.listdir(os.path.join(srcpath, ll)):
                    # Plamobuild.bash-4.3.30, bash-4.3.30-x86_64-P1.txz, bash.desc
                    # if fnmatch.fnmatch(lll, basename+'.desc'):
                    #     for llll in os.listdir(os.path.join(srcpath, ll)):
                    #         #if fnmatch.fnmatch(llll, basename+'-'+version+'*.txz'):
                    #         if fnmatch.fnmatch(llll, basename+'*.txz'):
                    #             pkglist.append(os.path.join(srcpath, ll, llll))
                    #             desclist.append(os.path.join(srcpath, ll, basename+'.desc'))
                    if fnmatch.fnmatch(lll, '*.desc'):
                        basename2, ext2=os.path.splitext(lll)
                        #print("--- "+basename2)
                        #print(--- "+ext2)
                        for llll in os.listdir(os.path.join(srcpath, ll)):
                            #print(llll)
                            if fnmatch.fnmatch(llll, basename2+'-*-*-P*.txz'):
                                pkglist.append(os.path.join(srcpath, ll, llll))
                                desclist.append(os.path.join(srcpath, ll, basename2+'.desc'))
                    if fnmatch.fnmatch(lll, basename+'.desc'):
                        flg_name = 1
                    if fnmatch.fnmatch(lll, '00header.desc'):
                        flg_head = 1
                if flg_name == 1 and flg_head == 1:
                    desclist.append(os.path.join(srcpath, ll, basename+'.desc'))

        #print(pkglist)
        #print(desclist)
        if not os.path.exists(dstpath) :
            print("mkdir: "+dstpath)
            os.makedirs(dstpath)
            pass

        # copy pkg file
        for i in pkglist:
            print("copy: "+i)
            shutil.copy2(i, dstpath)
            pass
        
        # make desc file
        f = open(file, 'r')
        lines = f.readlines()
        tmp = lines[0].split('&')
        tmp2 = tmp[0].strip()+'.desc'
        of = os.path.join(dstpath, tmp2)
        if os.path.exists(of):
            os.remove(of)
        out = codecs.open(of, 'a', 'euc-jp')
        for l in lines:
            out.write(l)
        out.write('\n')
        f.close()
        for i in desclist:
            print(i)
            f = codecs.open(i, 'r', 'euc-jp')
            out.write(f.read())
            out.write('\n')
            f.close()
        out.close()
        os.system("cd "+os.path.dirname(of)+"; "+os.path.abspath(os.path.dirname(args[0]))+'/makedesc.pl -a '+os.path.basename(of))
