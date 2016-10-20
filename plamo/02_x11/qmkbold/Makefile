qmkbold: qmkbold.o cy.o
	gcc -o qmkbold qmkbold.o cy.o

cy.o: cy.c cy.h
	gcc -c -o cy.o cy.c

qmkbold.o: qmkbold.c
	gcc -c -o qmkbold.o qmkbold.c

install: qmkbold
	mkdir -p $(DESTDIR)/usr/bin
	install qmkbold $(DESTDIR)/usr/bin
