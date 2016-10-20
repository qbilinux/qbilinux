#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cy.h"

 
unsigned long mkbold( char *, unsigned long,
		      unsigned long, int, int, int ) ;

int main( int argc, char **argv )
{
    int farg,i,bits=-1,lines=-1 ;
    int s_mode=0,e_mode=0 ;
    unsigned long mask,base ;
    FILE *fp ;
    char *buf,*mtob,*format ;

    farg=0 ;
    for( i=1 ; i<argc ; i++ ){
	if( strcmp(argv[i],"--help")==0 ){
	    farg=-1 ;
	    break ;
	}
	else if( strcmp(argv[i],"-r")==0 ) s_mode=1 ;
	else if( strcmp(argv[i],"-L")==0 ) e_mode=1 ;
	else{
	    if( (buf=strrchr(argv[i],'.'))!=NULL ){
		if( strcmp(buf+1,"bdf")==0 ) farg=i ;
	    }
	}
    }
    if( farg==-1 ){
	fprintf(stderr,"qmkbold [-r] [-L] hoge.bdf\n") ;
	fprintf(stderr,"(32ドットより大きいのはダメです)\n") ;
	return(1) ;
    }
    if( farg!=0 ){
	fp=fopen(argv[farg],"r") ;
	if( fp==NULL ){
	    fprintf(stderr,"Error: ファイルが見つかれませ〜ん\n") ;
	    return(-1) ;
	}
    }
    else fp=stdin ;

    while( stfgetline(fp,&buf)!=EOF ){
	if( *buf=='\0' ) continue ;
	mtob=strstr(buf,"Medium") ;
	if( mtob != NULL ){
	    *mtob='\0' ;
	    printf("%sBold%s\n",buf,mtob+6) ;
	    continue ;
	}
	else{
	    mtob=strstr(buf,"medium") ;
	    if( mtob != NULL ){
		*mtob='\0' ;
		printf("%sbold%s\n",buf,mtob+6) ;
		continue ;
	    }
	}
	printf("%s\n",buf) ;
	if( strncmp("BBX ",buf,4)==0 ){
	    bits=atoi(ststrselstr(buf,2)) ;
	    lines=atoi(ststrselstr(buf,3)) ;
	    break ;
	}
    }
    if( bits<0 || lines<0 ){
	fprintf(stderr,"Error: それbdfファイルぢゃないかも\n") ;
	return(-1) ;
    }
    if( (bits % 8) == 0 ) base = 0x01 ;
    else base=0x01<<(8-(bits % 8)) ;
    /* fprintf(stderr,"%x\n",base) ; */
    mask=base ;
    for( i=0 ; i<bits-1 ; i++ ){
	mask |= mask<<1 ;
    }
    /* fprintf(stderr,"%x\n",mask) ; */
    cy_asprintf(&format,"%%0%dx\n",2+2*( (bits-1)/8 )) ;

    while( stfgetline(fp,&buf)!=EOF ){
	if( *buf=='\0' ) continue ;
	printf("%s\n",buf) ;
	if( strncmp("BITMAP",buf,4)==0 ){
	    for( i=0 ; i<lines ; i++ ){
		stfgetline(fp,&buf) ;
		printf(format,
		       mkbold(buf,mask,base,bits,s_mode,e_mode)) ;
	    }
	}
    }
    if( fp!=stdin ) fclose(fp) ;
    free(format) ;
    return(0) ;
}

unsigned long mkbold( char *buf, unsigned long mask, unsigned long base, 
		      int bits, int s_mode, int e_mode )
{
    int i,b ;
    register unsigned long pat ;
    unsigned long rt_pat ;
    pat=strtol(buf,NULL,16) ;
    if( s_mode ){	/* -r */
	rt_pat=pat | (pat>>1) ;
    }
    else{		/* -l */
	rt_pat=pat | (pat<<1) ;
    }
    if( e_mode ){	/* -L */
	b=bits-1 ;
	for( i=0 ; i<bits-1 ; i++ ){
	    if( !( pat & (base<<b) ) && ( pat & (base<<(b-1)) ) ){
		mask &= ~(base<<b) ;
	    }
	    b-- ;
	}
    }
    else{		/* -R */
	for( i=0 ; i<bits-1 ; i++ ){
	    if( !( pat & (base<<i) ) && ( pat & (base<<(i+1)) ) ){
		mask &= ~(base<<i) ;
	    }
	}
    }
    rt_pat &= mask ;
    return(rt_pat) ;
}
