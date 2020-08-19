#include <cstdio>
#include <unistd.h>
#include "shell.hh"
#include <signal.h>
#include <sys/wait.h>

int yyparse(void);
void yyrestart(FILE * file);

void Shell::prompt() {
  printf("myshell>");
  fflush(stdout);
}

extern "C" void ctrlC (int sig) {
        printf("Good Bye!!\n");
        //clear();

}

extern "C" void killzombie (int sig) {
        int status = wait3(0,0,NULL);
        while (waitpid(-1, NULL, WNOHANG) > 0) {
                printf("\n[%d] exited.",  status);
        }
}

int main() {

  if (isatty(0) == true) {
        Shell::prompt();
  }
  //yyparse();

  // Handling ctrl + C
  struct sigaction signalAction;
  signalAction.sa_handler = ctrlC;
  sigemptyset(&signalAction.sa_mask);
  signalAction.sa_flags = 0;
  int error = sigaction(SIGINT, &signalAction, NULL);
  if (error) {
        perror("sigaction");
        exit(2);
  }
  // Zombie function
  struct sigaction signalAction_zombie;
  signalAction_zombie.sa_handler = killzombie;
  sigemptyset(&signalAction_zombie.sa_mask);
  signalAction_zombie.sa_flags = SA_RESTART;
  int error_two = sigaction(SIGCHLD, &signalAction_zombie, NULL);
  if (error_two) {
        perror("sigaction");
        exit(-1);
  }

  // Creating a Default Source File: “.shellrc”
  FILE * fd = fopen(".shellrc", "r");
  if (fd) {
        yyrestart(fd);
        yyparse();
        yyrestart(stdin);
        fclose(fd);
  }
  else {
        if ( isatty(0) ) {
                Shell::prompt();
        }
  }

  yyparse();
}

Command Shell::_currentCommand;
