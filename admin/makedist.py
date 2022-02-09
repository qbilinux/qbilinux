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
        for file in files:
            yield os.path.join(root, file)
        if 'build' in dirs:
            dirs.remove('build')
        if 'work' in dirs:
            dirs.remove('work')
        if 'old' in dirs:
            dirs.remove('old')
        if 'source' in dirs:
            dirs.remove('source')

def usage():
    print("")
    print("copy pakege file and make tagfile form qbilinux distrobution.")
    print("")
    print("Usage: "+args[0]+" buildir destdir arch")
    print("")
    print("   buildir: directory contains package and desc file.")
    print("   destdir: direcotry for qbilinux distrobution")
    print("   arch:    x86_64 x86 armv7l aarch64")
    print("")
    print("   ex) "+args[0]+" qbilinux qbilinux-0.0 x86_64")
    print("")
    
if (argc != 4):
    usage()
    quit()

#if (args[1]):
#    usage()
#    quit()

if (args[3] != "x86_64" and args[3] != "x86" and args[3] != "armv7l" and args[3] != "aarch64"):
    usage()
    quit()

source_dir=args[1]
dest_dir=args[2]+"/"+args[3]

if (args[3] == "x86"):
    arch_def="i?86"
else:
    arch_def=args[3]
    
for file in fild_all_files(source_dir):
    if fnmatch.fnmatch(file, '*/00header.desc'):
        print("###########")
        print(file)
        srcpath=os.path.dirname(file)
        srcfile=os.path.basename(file)
        srcparentpath=os.path.dirname(srcpath)
        dstpath=os.path.join(dest_dir, srcpath)
        dstfile=os.path.join(dstpath, srcfile)
        pkglist = []
        desclist = []
        for ll in os.listdir(srcpath):
            if os.path.isdir(os.path.join(srcpath, ll)):
                basename, ext=os.path.splitext(ll)
                flg_name = 0
                flg_head = 0
                for lll in os.listdir(os.path.join(srcpath, ll)):
                    # Packagebuild.bash-4.3.30, bash-4.3.30-x86_64-T1.txz, bash.desc
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
                            if fnmatch.fnmatch(llll, basename2+'-*-'+arch_def+'-*.txz') or fnmatch.fnmatch(llll, basename2+'-*-noarch-*.txz'):
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
        out = codecs.open(of, 'a', 'UTF-8')
        for l in lines:
            out.write(l)
        out.write('\n')
        f.close()
        for i in desclist:
            print(i)
            f = codecs.open(i, 'r', 'UTF-8')
            out.write(f.read())
            out.write('\n')
            f.close()
        out.close()
        os.system("cd "+os.path.dirname(of)+"; "+os.path.abspath(os.path.dirname(args[0]))+'/makedesc.pl -a '+os.path.basename(of))
