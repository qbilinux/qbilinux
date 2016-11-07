#!/usr/bin/python

import os
import sys
import fnmatch
import shutil

args=sys.argv

#print args
#print os.path.dirname(args[0])

def fild_all_files(directory):
    for root, dirs, files in os.walk(directory):
        yield root
        for file in files:
            yield os.path.join(root, file)

for file in fild_all_files(args[1]):
    if fnmatch.fnmatch(file, '*/00header.desc'):
        print "###########"
        print file
        srcpath=os.path.dirname(file)
        srcfile=os.path.basename(file)
        srcparentpath=os.path.dirname(srcpath)
        dstpath=os.path.join(args[2], srcpath)
        dstfile=os.path.join(dstpath, srcfile)
        #print srcpath
        #print srcparentpath
        #print srcfile
        #print dstpath
        #print dstfile
        pkglist = []
        desclist = []
        for ll in os.listdir(srcpath):
            if os.path.isdir(os.path.join(srcpath, ll)):
                basename = ll
                for lll in os.listdir(os.path.join(srcpath, ll)):
                    # Plamobuild.bash-4.3.30, bash-4.3.30-x86_64-P1.txz, bash.desc
                    if fnmatch.fnmatch(lll, basename+'.desc'):
                        for llll in os.listdir(os.path.join(srcpath, ll)):
                            #if fnmatch.fnmatch(llll, basename+'-'+version+'*.txz'):
                            if fnmatch.fnmatch(llll, basename+'*.txz'):
                                pkglist.append(os.path.join(srcpath, ll, llll))
                                desclist.append(os.path.join(srcpath, ll, basename+'.desc'))
        #print pkglist
        #print desclist
        if not os.path.exists(dstpath) :
            print "mkdir: "+dstpath
            os.makedirs(dstpath)
            pass

        # copy pkg file
        for i in pkglist:
            print "copy: "+i
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
        out = open(of, 'a')
        for l in lines:
            out.write(l)
        out.write('\n')
        f.close()
        for i in desclist:
            f = open(i, 'r')
            out.write(f.read())
            out.write('\n')
            f.close()
        out.close()
        os.system("cd "+os.path.dirname(of)+"; "+os.path.abspath(os.path.dirname(args[0]))+'/makedesc.pl -a '+os.path.basename(of))
