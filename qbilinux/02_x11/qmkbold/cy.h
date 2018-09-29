#ifndef _CY_H
#define _CY_H
#include <stdio.h>
#include <stdarg.h>
/* エラーチェック付きmallocとrealloc */
extern void *xmalloc( size_t ) ;
extern void *xrealloc( void *, size_t ) ;
/* FORTRAN向きに書かれたデータファイルを読む */
extern long int scanlong( char *, int , int * ) ;
extern double scandouble( char *, int , int * ) ;
/* メモリを確保して文字列から指定の桁の文字列を取り出す */
extern int alstrselstr( char *, int , char **, size_t * ) ;
extern char *ststrselstr( char *, int ) ;
/* メモリを確保して1行読み出す(遅いけど) */
extern int alfgetline( FILE *, char **, size_t * ) ;
extern int stfgetline( FILE *, char ** ) ;
/* メモリを確保して1行読み出す(遅いけど) */
/* glibc2.1以降では使えない */
extern int cy_asprintf( char **, const char *, ... ) ;
extern int cy_vasprintf( char **, const char *, va_list ) ;
/* 子プロセスの実行 */
extern int vspawnvp( const char *, ... ) ;
/* "0000"に"56"を埋め込んで "0056"にする関数 */
extern int alstrrset( char *, char *, char **, int * ) ;
extern int ststrrset( char *, char *, char ** ) ;
/* C言語向きのデータアレイを読む */
extern int readcdataarray( char *, int *, int *, double *** ) ;

#endif
