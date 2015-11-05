all:
	gcc -o proxy -pedantic proxy.c csapp.c -ggdb3 -lpthread
