#ifndef _CY_H
#define _CY_H
#include <stdio.h>
#include <stdarg.h>
/* ���顼�����å��դ�malloc��realloc */
extern void *xmalloc( size_t ) ;
extern void *xrealloc( void *, size_t ) ;
/* FORTRAN�����˽񤫤줿�ǡ����ե�������ɤ� */
extern long int scanlong( char *, int , int * ) ;
extern double scandouble( char *, int , int * ) ;
/* �������ݤ���ʸ���󤫤����η��ʸ�������Ф� */
extern int alstrselstr( char *, int , char **, size_t * ) ;
extern char *ststrselstr( char *, int ) ;
/* �������ݤ���1���ɤ߽Ф�(�٤�����) */
extern int alfgetline( FILE *, char **, size_t * ) ;
extern int stfgetline( FILE *, char ** ) ;
/* �������ݤ���1���ɤ߽Ф�(�٤�����) */
/* glibc2.1�ʹߤǤϻȤ��ʤ� */
extern int cy_asprintf( char **, const char *, ... ) ;
extern int cy_vasprintf( char **, const char *, va_list ) ;
/* �ҥץ����μ¹� */
extern int vspawnvp( const char *, ... ) ;
/* "0000"��"56"��������� "0056"�ˤ���ؿ� */
extern int alstrrset( char *, char *, char **, int * ) ;
extern int ststrrset( char *, char *, char ** ) ;
/* C��������Υǡ������쥤���ɤ� */
extern int readcdataarray( char *, int *, int *, double *** ) ;

#endif
