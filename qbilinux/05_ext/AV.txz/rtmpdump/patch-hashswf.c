--- build/librtmp/hashswf.c.orig	2016-02-29 01:15:13 UTC
+++ build/librtmp/hashswf.c
@@ -57,10 +57,10 @@
 #include <openssl/sha.h>
 #include <openssl/hmac.h>
 #include <openssl/rc4.h>
-#define HMAC_setup(ctx, key, len)	HMAC_CTX_init(&ctx); HMAC_Init_ex(&ctx, (unsigned char *)key, len, EVP_sha256(), 0)
-#define HMAC_crunch(ctx, buf, len)	HMAC_Update(&ctx, (unsigned char *)buf, len)
-#define HMAC_finish(ctx, dig, dlen)	HMAC_Final(&ctx, (unsigned char *)dig, &dlen);
-#define HMAC_close(ctx)	HMAC_CTX_cleanup(&ctx)
+#define HMAC_setup(ctx, key, len)	HMAC_Init_ex(ctx, (unsigned char *)key, len, EVP_sha256(), 0)
+#define HMAC_crunch(ctx, buf, len)	HMAC_Update(ctx, (unsigned char *)buf, len)
+#define HMAC_finish(ctx, dig, dlen)	HMAC_Final(ctx, (unsigned char *)dig, &dlen);
+#define HMAC_close(ctx)	HMAC_CTX_free(ctx)
 #endif
 
 extern void RTMP_TLS_Init();
@@ -289,7 +289,7 @@ leave:
 struct info
 {
   z_stream *zs;
-  HMAC_CTX ctx;
+  HMAC_CTX *ctx;
   int first;
   int zlib;
   int size;
