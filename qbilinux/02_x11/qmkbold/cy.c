/*
  ��ʬ�Ѥ����Ѵؿ���
  Aug.17,2001
*/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdarg.h>
#include <ctype.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <errno.h>

/*
  ���顼�����å��դ�malloc��realloc
*/
void *xmalloc( size_t size )
{
    void *rt ;
    rt=malloc(size) ;
    if( rt==NULL ){
        fprintf(stderr,"���꤬���ݤǤ��ʤ��ä�\n") ;
        exit(1) ;
    }
    return(rt) ;
}

void *xrealloc( void *ptr, size_t size )
{
    void *rt ;
    rt=realloc(ptr,size) ;
    if( rt==NULL ){
        fprintf(stderr,"���꤬���ݤǤ��ʤ��ä�\n") ;
        exit(1) ;
    }
    return(rt) ;
}

/* 
   FORTRAN�����˽񤫤줿�ǡ����ե�������ɤ�
   �����ͤ�0�ʳ��ʤ饨�顼��
*/
long int scanlong( char *adr, int len, int *rt_status )
{
    char *endptr ;
    long int rt ;
    char bb[len+1] ;
    /* int i,f=0,fl ; */
    strncpy(bb,adr,len) ;
    bb[len]='\0' ;
    /*
    for( i=0 ; i<len ; i++ ){
        fl=isdigit((int)(bb[i])) ;
        if( fl!=0 ) f|=1 ;
    }
    *rt=atoi(bb) ;
    */
    errno=0 ;
    rt=strtol(bb,&endptr,10) ;
    if( errno ==  ERANGE || *endptr!='\0' ) *rt_status=-1 ;
    else *rt_status=0 ;
    return( rt ) ;
}
double scandouble( char *adr, int len, int *rt_status )
{
    double rt ;
    char *endptr ;
    char bb[len+1] ;
    /* int i,f=0,fl ; */
    strncpy(bb,adr,len) ;
    bb[len]='\0' ;
    /*
    for( i=0 ; i<len ; i++ ){
        fl=isdigit((int)(bb[i])) ;
        if( fl!=0 ) f|=1 ;
    }
    *rt=atof(bb) ;
    */
    errno=0 ;
    rt=strtod(bb,&endptr) ;
    if( errno ==  ERANGE || *endptr!='\0' ) *rt_status=-1 ;
    else *rt_status=0 ;
    return( rt ) ;
}

#define DELIM " \t,"
int dchk( char c )
{
    int l,i,rt=0 ;
    l=strlen(DELIM) ;
    for( i=0 ; i<l ; i++ ){
	if( c == *(DELIM+i) ){
	    rt=1 ;
	    break ;
	}
    }
    return(rt) ;
}

/* 
   awk '{print $2}' ����褦�ʴؿ�
   sel...1,2,3...
   return... *rts, *bufsize
   �֤��ͤ�ʸ���������顼�λ���-1
*/
int alstrselstr( char *buf_in, int sel, char **rts, size_t *bufsize )
{
    int i,fl,len,blen ;
    char *st=NULL, *ed=NULL ;
    char *buf_rt=*rts ;
    
    blen=strlen(buf_in) ;
    for( i=0,fl=0 ; i<=blen ; i++ ){
        if( st==NULL ){
            if(i==0){
		if( dchk(buf_in[i])==0 ) fl++ ;
            }
            else if( dchk(buf_in[i])==0 && dchk(buf_in[i-1])!=0 ){
                fl++ ;
            }
            if( fl==sel ) st=buf_in+i ;
        }
        else{
            if( dchk(buf_in[i])!=0 || buf_in[i]=='\0' ){
                ed=buf_in+i ;
                break ;
            }
        }
    }
    if( st==NULL || ed==NULL ){	/* ��!! */
	return(-1) ;
    }
    else{
	len=ed-st ;
	len++ ;
	if(buf_rt==NULL){
	    buf_rt=(char *)xmalloc(sizeof(char)*len) ;
	    *bufsize=len ;
	}
	else{
	    if( *bufsize<len ){
		buf_rt=(char *)xrealloc(buf_rt,sizeof(char)*len) ;
		*bufsize=len ;
	    }
	}
	len-- ;
	strncpy(buf_rt,st,len) ;
	buf_rt[len]='\0' ;
	*rts=buf_rt ;
	return(len) ;
    }
}

/*
 �֤��ͤϤ��δؿ��������ΰ�
 ���顼�λ���NULL���֤�
*/
char *ststrselstr( char *buf_in, int sel )
{
    static char *rts=NULL ;
    static size_t siz ;
    int f ;
    f=alstrselstr( buf_in, sel, &rts, &siz ) ;
    if( f==-1 ) return(NULL) ;
    else return(rts) ;
}

#define  FRLBUFSIZE 256
/*
  �������ݤ���1���ɤ߽Ф�(�٤�����)
  �֤��ͤ�EOF�ʤ齪λ
*/
int alfgetline( FILE *fp, char **rt, size_t *bufsize )
{
    char *tadr=*rt ;
    size_t cn=*bufsize ;
    size_t i ;
    int ch ;

    if(tadr==NULL){
	cn=FRLBUFSIZE ;
	tadr=(char *)xmalloc(sizeof(char)*cn) ;
    }
    i=0 ;
    while( (ch=fgetc(fp))!=EOF ){
	if( cn==i ){
	    cn+=FRLBUFSIZE ;
	    tadr=(char *)xrealloc(tadr,sizeof(char)*cn) ;
	}
	if( ch=='\n' ){
	    tadr[i]='\0' ;
	    break ;
	}
	tadr[i]=ch ;
	i++ ;
    }
    *rt=tadr ;
    *bufsize=cn ;
    return(ch) ;
}
#undef  FRLBUFSIZE

/*
 �֤��� *rt �Ϥ��δؿ��������ΰ�
*/
int stfgetline( FILE *fp, char **rt )
{
    static size_t bufsize ;
    static char *buf=NULL ;
    int ret ;
    ret=alfgetline(fp,&buf,&bufsize) ;
    *rt=buf ;
    return(ret) ;
}

#define SPBUFSIZE 256
/*
  �ΰ����ݤ��� sprintf ���롥
  glibc2.1�ʹߤǤ��Բ�
 */
/*
int alsprintf( char **dist, size_t *bufsize, const char *argsformat, ... )
{
    char *adr=*dist ;
    size_t siz=*bufsize ;
    va_list ap ;
    int i ;

    if( adr==NULL ){
	siz=SPBUFSIZE ;
	adr = (char *)xmalloc(sizeof(char)*siz) ;
    }

    va_start( ap, argsformat ) ;
    do{
        i=vsnprintf( adr,siz,argsformat,ap ) ;
        if(i==-1){
            siz += SPBUFSIZE ;
            adr = (char *)xrealloc(adr,sizeof(char)*siz) ;
        }
    } while(i==-1) ;
    va_end(ap) ;
    *dist=adr ;
    *bufsize=siz ;
    return(i) ;
}
*/
/*
 �֤���*dist�Ϥ��δؿ��������ΰ�
*/
/*
int stsprintf( char **dist, const char *argsformat, ... )
{
    static char *adr=NULL ;
    static size_t siz ;
    va_list ap ;
    int i ;

    if( adr==NULL ){
	siz=SPBUFSIZE ;
	adr = (char *)xmalloc(sizeof(char)*siz) ;
    }
    va_start( ap, argsformat ) ;
    do{
        i=vsnprintf( adr,siz,argsformat,ap ) ;
        if(i==-1){
            siz += SPBUFSIZE ;
            adr = (char *)xrealloc(adr,sizeof(char)*siz) ;
        }
    } while(i==-1) ;
    va_end(ap) ;
    *dist=adr ;
    return(i) ;
}
#undef SPBUFSIZE
*/

#define VSPAWN   256
/*
  �ҥץ�����¹Ԥ�����λ����ޤ��Ԥ�
  vspawnvp("cp %s .",filename) ; �Τ褦�ʴ���
*/
int vspawnvp( const char *argsformat, ... )
{
    pid_t pid ;
    int status ;
    va_list ap ;
    char *adr ;
    char **argv ;
    char *args ;
    int siz = VSPAWN ;
    int i ;

    adr = (char *)xmalloc(sizeof(char)*siz) ;
    
    va_start( ap, argsformat ) ;
    do{
	i=vsnprintf( adr,siz,argsformat,ap ) ;
	if(i==-1){
	    siz += VSPAWN ;
	    adr = xrealloc(adr,sizeof(char)*siz) ;
	}
    } while(i==-1) ;
    va_end(ap) ;

    i=0 ;
    siz = VSPAWN ;
    argv = (char **)xmalloc(sizeof(char *)*siz) ;
    args = adr ;
    argv[i] = strtok(args," \n") ;
    while( argv[i]!=NULL ){
	if( siz<=++i ){
	    siz += VSPAWN ;
	    argv = xrealloc(argv,sizeof(char *)*siz) ;
	}
	argv[i] = strtok(NULL," \n") ;
    }
    if( ( pid = fork() ) < 0 ) return( -1 ) ;
    if( pid == 0 ){
	/* child process */
	execvp( *argv, argv ) ;
	_exit(1) ;
    }
    while(wait(&status)!=pid) ;
    free(argv) ;
    free(adr) ;
    /* wait! */
    if( WIFEXITED(status) ) return( 0 ) ;
    return( -1 ) ;
}
#undef VSPAWN

int alstrrset( char *base, char *data, char **rts, int *bufsize )
{
    int baselen,datalen,ofs,status,clen ;

    datalen=strlen(data) ;
    baselen=strlen(base) ;
    baselen++ ;
    if( *rts == NULL ){
	*bufsize=baselen ;
	*rts=(char *)xmalloc(sizeof(char)*(*bufsize)) ;
    }
    else{
	if( *bufsize < baselen ){
	    *bufsize=baselen ;
	    *rts=(char *)xrealloc(*rts,sizeof(char)*(*bufsize)) ;
	}
    }
    baselen-- ;
    strncpy(*rts,base,baselen) ;
    (*rts)[baselen]='\0' ;
    ofs=baselen-datalen ;
    if( ofs<0 ){
	status=-1 ;
	ofs=0 ;
	clen=baselen ;
    }
    else{
	status=0 ;
	clen=datalen ;
    }
    strncpy(*rts+ofs,data,clen) ;
    return( status ) ;
}

int ststrrset( char *base, char *data, char **rts )
{
    static char *buf=NULL ;
    static int bufsize ;
    int status ;
    status=alstrrset(base,data,&buf,&bufsize) ;
    *rts=buf ;
    return(status) ;
}

/* ��������ޤ�ޤǤκ�¦��ʸ������Ĵ�٤� */
int strdotlen( char *s )
{
    char *dot ;
    int rt ;
    dot=strchr(s,'.') ;
    if( dot==NULL ) rt=strlen(s) ;
    else{
	rt=dot-s ;
	rt++ ;	/* dot��ʬ */
    }
    return(rt) ;
}

/* �������ޤǤα�¦��ʸ������Ĵ�٤� */
int strdotrlen( char *s )
{
    char *dot ;
    int rt ;
    dot=strchr(s,'.') ;
    if( dot==NULL ) rt=0 ;
    else{
	s+=strlen(s) ;
	s-- ;
	rt=s-dot ;
    }
    return(rt) ;
}

/* asprintf�ߴ��ؿ� */
/* �٤��Ȼפ��� */
int cy_asprintf( char **ret, const char *format, ... )
{
    int f,nn ;
    FILE *fp ;
    va_list ap ;

    /* �ƥ��Ȥ��� */
    f=open("/dev/null",O_WRONLY) ;
    fp=fdopen(f,"w") ;
    va_start( ap, format ) ;
    nn=vfprintf( fp,format,ap ) ;
    va_end(ap) ;
    fclose(fp) ;
    close(f) ;
    /* ���ݤ��ƽ񤭹��� */
    *ret=(char *)xmalloc(sizeof(char)*(nn+1)) ;
    va_start( ap, format ) ;
    vsprintf(*ret,format,ap) ;
    va_end(ap) ;
    return(nn) ;
}

/* vasprintf�ߴ��ؿ� */
int cy_vasprintf( char **ret, const char *format, va_list ap )
{
    int f,nn ;
    FILE *fp ;

    /* �ƥ��Ȥ��� */
    f=open("/dev/null",O_WRONLY) ;
    fp=fdopen(f,"w") ;
    nn=vfprintf( fp,format,ap ) ;
    fclose(fp) ;
    close(f) ;
    /* ���ݤ��ƽ񤭹��� */
    *ret=(char *)xmalloc(sizeof(char)*(nn+1)) ;
    vsprintf(*ret,format,ap) ;
    return(nn) ;
}

/* C��������Υǡ������쥤���ɤ� */
/* ����϶���Ū�˳��ݤ���� */
/* dn�ϲ����������ǿ�,n�ϥǡ����θĿ� */
#define INITBUF 64
int readcdataarray( char *filename, int *dn, int *n, double ***retdata )
{
    FILE *fp ;
    char *buffer,*sbuf ;
    int i,f,bufn=INITBUF ;
    double **datatable ;
    fp=fopen(filename,"r") ;
    if( fp==NULL ){
	fprintf(stderr,"Error: Can't open file.\n") ;
	return(-1) ;
    }
    /* 1���ܤ���ǡ��������ǿ��򤭤�� */
    i=0 ;
    while( stfgetline(fp,&buffer)!=EOF ){
	sbuf=ststrselstr( buffer, 1 ) ;
	if( sbuf == NULL ) continue ;
	if( *sbuf == '#' ) continue ;
	i=1 ;
	while( ststrselstr(buffer,i+1)!=NULL ) i++ ;
	break ;
    }
    if( i==0 ){
	fprintf(stderr,"Error: Can't determine dn.\n") ;
	return(-1) ;
    }
    *dn=i ;
    datatable=xmalloc(sizeof(double *)*(*dn)) ;
    /* �ǽ�γ��ݤ򤹤� */
    for( i=0 ; i<(*dn) ; i++ ) datatable[i]=xmalloc(sizeof(double)*bufn) ;
    *n=0 ;
    do{
	sbuf=ststrselstr( buffer, 1 ) ;
	if( sbuf != NULL ){
	  if( *sbuf != '#' ){
	    /* ���꤬­��Ƥ뤫�����å� */
	    if( *n==bufn ){
		bufn+=INITBUF ;		/* �Ƴ��� */
		for( i=0 ; i<(*dn) ; i++ ) datatable[i]=xrealloc(datatable[i],sizeof(double)*bufn) ;
	    }
	    for( i=0 ; i<(*dn) ; i++ ){
		sbuf=ststrselstr( buffer, i+1 ) ;
		if( sbuf==NULL ){
		    fprintf(stderr,"Warning: Lacking data! zero was set\n") ;
		    datatable[i][*n]=0 ;
		}
		else{
		    datatable[i][*n]=atof(sbuf) ;
		}
	    }
	    (*n)++ ;
	  }
	}
	f=stfgetline(fp,&buffer) ;
    } while( f!=EOF ) ;
    *retdata=datatable ;
    fclose(fp) ;
    return(0) ;
}
#undef INITBUF
