/*
 * proxy.c - Web proxy for COMPSCI 512
 *
 */

#include <stdio.h>
#include "csapp.h"
#include <pthread.h>

#define   FILTER_FILE   "proxy.filter"
#define   LOG_FILE      "proxy.log"
#define   DEBUG_FILE	"proxy.debug"


/*============================================================
 * function declarations
 *============================================================*/

int  find_target_address(char * uri,
                         char * target_address,
                         char * path,
                         int  * port);


void  format_log_entry(char * logstring,
                       int sock,
                       char * uri,
                       int size);

void *forwarder(void* args);
void *webTalk(void* args);
void secureTalk(int clientfd, int serverfd);
void ignore();

int debug;
int proxyPort;
int debugfd;
int logfd;
pthread_mutex_t mutex;

/* main function for the proxy program */

int main(int argc, char *argv[])
{
    int count = 0;
    int listenfd, connfd, clientlen, optval, serverPort, i;
    struct sockaddr_in clientaddr;
    struct hostent *hp;
    char *haddrp;
    sigset_t sig_pipe;
    pthread_t tid;
    int *args;
    
    if (argc < 2) {
        printf("Usage: ./%s port [debug] [webServerPort]\n", argv[0]);
        exit(1);
    }
    if(argc == 4)
        serverPort = atoi(argv[3]);
    else
        serverPort = 80;
    
    Signal(SIGPIPE, ignore);
    
    if(sigemptyset(&sig_pipe) || sigaddset(&sig_pipe, SIGPIPE))
        unix_error("creating sig_pipe set failed");
    if(sigprocmask(SIG_BLOCK, &sig_pipe, NULL) == -1)
        unix_error("sigprocmask failed");
    
    proxyPort = atoi(argv[1]);
    
    if(argc > 2)
        debug = atoi(argv[2]);
    else
        debug = 0;
    
    
    /* start listening on proxy port */
    
    listenfd = Open_listenfd(proxyPort);
    
    optval = 1;
    setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, (const void*)&optval, sizeof(int));
    
    if(debug) debugfd = Open(DEBUG_FILE, O_CREAT | O_TRUNC | O_WRONLY, 0666);
    
    logfd = Open(LOG_FILE, O_CREAT | O_TRUNC | O_WRONLY, 0666);
    
    
    /* if writing to log files, force each thread to grab a lock before writing
     to the files */
    
    pthread_mutex_init(&mutex, NULL);
    
    while(1) {
        
        clientlen = sizeof(clientaddr);
        
        /* accept a new connection from a client here */
        
        connfd = Accept(listenfd, (SA *)&clientaddr, &clientlen);
        
        /* you have to write the code to process this new client request */
        
        /* create a new thread (or two) to process the new connection */
        // if(tid<=0){
        //}
        // else{
        // pthread_t thread;
        void *args = malloc(sizeof(int)*2);
        *((int *)args) = connfd;
        *((int *)args+1) = serverPort;
        Pthread_create(&tid, NULL, webTalk, (void *)args);
        
        Pthread_detach(tid);
        
        //}
    }
    
    if(debug) Close(debugfd);
    Close(logfd);
    pthread_mutex_destroy(&mutex);
    
    return 0;
}

/* a possibly handy function that we provide, fully written */

void parseAddress(char* url, char* host, char** file, int* serverPort)
{
    char *point1;
    char *point2;
    char *saveptr;
    
    if(strstr(url, "http://"))
        url = &(url[7]);
    else if(strstr(url, "https://"))
        url = url+8;
    *file = strchr(url, '/');
    
    strcpy(host, url);
    
    /* first time strtok_r is called, returns pointer to host */
    /* strtok_r (and strtok) destroy the string that is tokenized */
    
    /* get rid of everything after the first / */
    
    strtok_r(host, "/", &saveptr);
    
    /* now look to see if we have a colon */
    
    point1 = strchr(host, ':');
    if(!point1) {
//        *serverPort = 80;
        return;
    }
    
    /* we do have a colon, so get the host part out */
    strtok_r(host, ":", &saveptr);
    
    /* now get the part after the : */
    *serverPort = atoi(strtok_r(NULL, "/",&saveptr));
}



/* this is the function that I spawn as a thread when a new
 connection is accepted */

/* you have to write a lot of it */

void *webTalk(void* args)
{
    int numBytes, lineNum, serverfd, clientfd, serverPort;
    int tries = 20;
    int byteCount = 0;
    char buf1[MAXLINE], buf2[MAXLINE], buf3[MAXLINE];
    char host[MAXLINE];
    char url[MAXLINE], logString[MAXLINE];
    char *token, *cmd, *version, *file, *saveptr;
    rio_t server, client;
    char slash[10];
    strcpy(slash, "/");
    serverfd = -1;
    clientfd = ((int*)args)[0];
    serverPort = ((int*)args)[1];
    free(args);
    
    Rio_readinitb(&client, clientfd);
    
    // Determine protocol (CONNECT or GET)
    
    while(1){
        numBytes=Rio_readlineb(&client,buf1,MAXLINE);
        if(numBytes > 0)
            break;
        tries--;
        if(tries < 0)
        {
            close(clientfd);
            return NULL;
        }
    }
    //  strcpy(buf2,buf1);
    cmd = strtok_r(buf1, " ", &saveptr);
//    token = strtok_r(NULL, " \r\n", &saveptr);
    strcpy(url, strtok_r(NULL, " \r\n", &saveptr));
    version = strtok_r(NULL," \r\n", &saveptr);
    serverPort = strcmp(cmd, "CONNECT") ? serverPort : 443; 
    parseAddress(url, host, &file, &serverPort);

    if(file == NULL){
        file = slash;
    }
    
    while(1){
        serverfd = Open_clientfd(host, serverPort);
        tries--;
        if(serverfd > -1) break;
        if(tries < 0)
        {
            close(clientfd);
            return NULL;
        }        
    }
    // CONNECT: call a different function, securetalk, for HTTPS
    // GET: open connection to webserver (try several times, if necessary)
    tries = 10;
    if (!strcmp(cmd, "CONNECT")) {       
        secureTalk(clientfd, serverfd);
    }
    else if( !strcmp(cmd, "GET")  || !strcmp(cmd, "POST") || !strcmp(cmd, "PUT")){        
        int length = 0;
        if(serverfd >= 0){
            sprintf(buf2, "%s %s %s\r\n", cmd, file, version);
            fprintf(stdout, "%s", buf2);fflush(stdout);
            Rio_writen(serverfd, buf2, strlen(buf2));
            
            char *magicwords = "Connection: close\r\n";
            char *contentlength = "Content-Length: ";
            Rio_writen(serverfd, magicwords, strlen(magicwords));

            while((numBytes = Rio_readlineb(&client, buf2, MAXLINE)) > 0){
                if(!strcasecmp(buf2, "Connection: keep-alive\r\n")){                    
                    continue;
                }
                else if(strstr(buf2, contentlength) != NULL)
                {
                    length = atoi(buf2+strlen(contentlength));
                }
                Rio_writen(serverfd, buf2, numBytes);
                if(!strcmp(buf2, "\r\n")){
                    break;
                }
            }
            if(length > 0)
            {
                int curr_length = client.rio_cnt < length ? client.rio_cnt : length;
                /* buf2[curr_length] = 0; */
                /* fprintf(stdout, "%s", buf2);fflush(stdout); */
                Rio_writen(serverfd, client.rio_bufptr, curr_length);
                length -= curr_length;
                while(length > 0)
                {
                    numBytes = Rio_readp(clientfd, (void *)buf2, length < (MAXLINE-1) ? length : (MAXLINE-1));
                    /* buf2[numBytes] = 0 */;
                    /* fprintf(stdout, "%s", buf2);fflush(stdout); */
                    length -= numBytes;
                    Rio_writen(serverfd, buf2, numBytes);
                }
            }
            
            while(1){
                numBytes = Rio_readp(serverfd, (void *)buf3, MAXLINE - 1);
                if(numBytes <= 0) break;
                /* buf3[numBytes] = 0; */
                if(strcmp(cmd, "POST") == 0){fprintf(stdout, "%s", buf3);fflush(stdout);}
                Rio_writen(clientfd, buf3, numBytes);
            }
        }
    }
//    else if(!strcmp(cmd, "PUSH")){
    else
    {        fprintf(stdout, "CMD is %s\n", cmd); fflush(stdout);}
    //  }
    close(serverfd);
    close(clientfd);
    return NULL;
}



/* this function handles the two-way encrypted data transferred in
 an HTTPS connection */

void secureTalk(int clientfd, int serverfd) {
    int numBytes1, numBytes2;
    int tries;
    rio_t server;
    char buf1[MAXLINE], buf2[MAXLINE];
    pthread_t tid;
    int *args;
        
    /* Open connecton to webserver */
    /* clientfd is browser */
    /* serverfd is server */

    args = (int*)Malloc(2*sizeof(int));
    *args = clientfd;
    *(args+1) = serverfd;
    
    /* let the client know we've connected to the server */
    Rio_writep(clientfd, "HTTP/1.1 200 Connection established\r\n\r\n", strlen("HTTP/1.1 200 Connection established\r\n\r\n"));
    
    /* spawn a thread to pass bytes from origin server through to client */
    
    Pthread_create(&tid, NULL, forwarder, (void*)args);
    
    /* now pass bytes from client to server */
    args = (int*)Malloc(2*sizeof(int));
    *args = serverfd;
    *(args+1)= clientfd;
    pthread_t tid1;
    Pthread_create(&tid1, NULL, forwarder, (void*)args);
    Pthread_join(tid, NULL);
    Pthread_join(tid1, NULL);   
    
}

/* this function is for passing bytes from origin server to client */

void *forwarder(void* args)
{
    int numBytes, lineNum, serverfd, clientfd;
    int byteCount = 0;
    char buf1[MAXLINE];
    clientfd = ((int*)args)[0];
    serverfd = ((int*)args)[1];
    free(args);
    
    while(1) {
//        printf("CONNECT SUCCESSFUL!\n");
        /* serverfd is for talking to the web server */
        /* clientfd is for talking to the browser */
        numBytes = Rio_readp(serverfd,buf1, MAXLINE);
        Rio_writen(clientfd, buf1, numBytes);
        if(numBytes <= 0){
            break;
        }
    }
    return NULL;
}



void ignore(){
    ;
}


/*============================================================
 * url parser:
 *    find_target_address()
 *        Given a url, copy the target web server address to
 *        target_address and the following path to path.
 *        target_address and path have to be allocated before they
 *        are passed in and should be long enough (use MAXLINE to be
 *        safe)
 *
 *        Return the port number. 0 is returned if there is
 *        any error in parsing the url.
 *
 *============================================================*/

/*find_target_address - find the host name from the uri */
int  find_target_address(char * uri, char * target_address, char * path,
                         int  * port)

{
    //  printf("uri: %s\n",uri);
    
    
    if (strncasecmp(uri, "http://", 7) == 0) {
        char * hostbegin, * hostend, *pathbegin;
        int    len;
        
        /* find the target address */
        hostbegin = uri+7;
        hostend = strpbrk(hostbegin, " :/\r\n");
        if (hostend == NULL){
            hostend = hostbegin + strlen(hostbegin);
        }
        
        len = hostend - hostbegin;
        
        strncpy(target_address, hostbegin, len);
        target_address[len] = '\0';
        
        /* find the port number */
        if (*hostend == ':')   *port = atoi(hostend+1);
        
        /* find the path */
        
        pathbegin = strchr(hostbegin, '/');
        
        if (pathbegin == NULL) {
            path[0] = '\0';
            
        }
        else {
            pathbegin++;
            strcpy(path, pathbegin);
        }
        return 0;
    }
    target_address[0] = '\0';
    return -1;
}



/*============================================================
 * log utility
 *    format_log_entry
 *       Copy the formatted log entry to logstring
 *============================================================*/

void format_log_entry(char * logstring, int sock, char * uri, int size){
    time_t  now;
    char    buffer[MAXLINE];
    struct  sockaddr_in addr;
    unsigned  long  host;
    unsigned  char a, b, c, d;
    int    len = sizeof(addr);
    
    now = time(NULL);
    strftime(buffer, MAXLINE, "%a %d %b %Y %H:%M:%S %Z", localtime(&now));
    
    if (getpeername(sock, (struct sockaddr *) & addr, &len)) {
        /* something went wrong writing log entry */
        printf("getpeername failed\n");
        return;
    }
    
    host = ntohl(addr.sin_addr.s_addr);
    a = host >> 24;
    b = (host >> 16) & 0xff;
    c = (host >> 8) & 0xff;
    d = host & 0xff;
    
    sprintf(logstring, "%s: %d.%d.%d.%d %s %d\n", buffer, a,b,c,d, uri, size);
}
