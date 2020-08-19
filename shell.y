%code requires 
{
#include <string>
#include <string.h>
#define MAXFILENAME 1024

#if __cplusplus > 199711L
#define register      // Deprecated in C++11 so remove the keyword
#endif
}

%union
{
  char        *string_val;
  // Example of using a c++ type in yacc
  std::string *cpp_string;
}

%token <cpp_string> WORD
%token NOTOKEN GREAT NEWLINE PIPE GREAT_GREAT TWO_GREAT GREAT_AMPERSAND LESS LESS_AMPERSAND GREAT_GREAT_AMPERSAND AMPERSAND

%{
//#define yylex yylex
#include <cstdio>
#include "shell.hh"
#include <regex.h>
#include <assert.h>
#include <dirent.h>
#include <string.h>
#include "command.hh"
void yyerror(const char * s); 
int yylex();

void expandWildCardsIfNecessary(std::string* arg);
void expandWildcard(char * prefix, char * arg);
bool root_direc (char * arg);

int maxEntries = 20; 
int nEntries = 0;
char ** array; //(char**) malloc(maxEntries*sizeof(char*));
%}

%%

goal: command_list;

arg_list:
        arg_list WORD {
/*              printf("   Yacc: insert argument \"%s\"\n", $2->c_str());*/
                expandWildCardsIfNecessary($2);
                /*Command::_currentSimpleCommand->insertArgument( $2 );
                /*if (strchr($2, '*') == NULL && strchr($1, '?') == NULL)
                        Command::_currentSimpleCommand->insertArgument( $1 );
                else {
                        expandWildcard("", $1);
                }*/
        }
        | /* empty string */
        ;

cmd_and_args:
        WORD {
/*              printf("   Yacc: insert command \"%s\"\n", $1->c_str());*/
                Command::_currentSimpleCommand = new SimpleCommand();
                Command::_currentSimpleCommand->insertArgument( $1 );
        } arg_list {
                Shell::_currentCommand.
                insertSimpleCommand( Command::_currentSimpleCommand );
        }
        ;

pipe_list:
        pipe_list PIPE cmd_and_args
        | cmd_and_args
        ;

io_modifier:
        GREAT_GREAT WORD {
                Shell::_currentCommand._outFile = $2;
                Shell::_currentCommand._append = 1;
                /*Shell::_currentCommand._outCounter++;*/
        }
        | GREAT WORD {
                /*printf("   Yacc: insert output \"%s\"\n", $2->c_str());*/
                if (Shell::_currentCommand._outFile) {
                        yyerror("Ambiguous output redirect\n");
                }
                Shell::_currentCommand._outFile = $2;
                /*Shell::_currentCommand._outCounter++;*/
        }
        | GREAT_GREAT_AMPERSAND WORD {
                /*printf("   Yacc: insert output \"%s\"\n", $2->c_str());*/
                Shell::_currentCommand._outFile = $2;
                Shell::_currentCommand._errFile = $2;
                Shell::_currentCommand._append = 1;
                /*Shell::_currentCommand._outCounter++;*/
        }
        | TWO_GREAT WORD {
                Shell::_currentCommand._errFile = $2;
                Shell::_currentCommand._append = 1;
        }
        | GREAT_AMPERSAND WORD {
                /*printf("   Yacc: insert output \"%s\"\n", $2->c_str());*/
                Shell::_currentCommand._outFile = $2;
                Shell::_currentCommand._errFile = $2;
                /*Shell::_currentCommand._outCounter++;*/
        }
        | LESS WORD {
                /*printf("   Yacc: insert output \"%s\"\n", $2->c_str());*/
                Shell::_currentCommand._inFile = $2;
                /*Shell::_currentCommand._inCounter++;*/
        }
        ;

io_modifier_list:
        io_modifier_list io_modifier
        | /* empty */
        ;

background_optional:
        AMPERSAND {
                Shell::_currentCommand._background = 1;
        }
        | /* empty */
        ;
command_line:
        pipe_list io_modifier_list background_optional NEWLINE {
        /*      printf("   Yacc: Execute command\n");*/
                Shell::_currentCommand.execute();
        }
        | NEWLINE
        | error NEWLINE { yyerrok; }
        ;

command_list:
        command_line |
         command_list command_line
        ;

%%

  /* Sort wildcard */

  /* Case where prefix is the root directory */
  bool root_direc (char * arg) {
        int i = 0;
        int counter = 0;
        while (arg[i] != 0) {
                if (arg[i] == '*') {
                        if (counter == 1) {
                                return true;
                        }
                        else {
                                return false;
                        }
                }
                if (arg[i] == '/') {
                        counter++;
                }
                i++;
                      }
        return false;
  }

  int cmpfunc (const void *file1, const void *file2) {
        const char *_file1 = *(const char **)file1;
        const char *_file2 = *(const char **)file2;
        return strcmp(_file1, _file2);
  }

  void expandWildCardsIfNecessary(std::string * argu) {
        char * arg = (char *)argu->c_str();
        maxEntries = 20;
        nEntries = 0;
        array = (char**) malloc(maxEntries*sizeof(char*));

        if (strchr(argu->c_str(), '*') || strchr(argu->c_str(), '?')) {
                 /*expandWildcard("/", arg);*/
                expandWildcard(".", arg);
                qsort(array, nEntries, sizeof(char *), cmpfunc);
                for (int i = 0; i < nEntries; i++) {
                        std::string * arss = new std::string(array[i]);
                        Command::_currentSimpleCommand->insertArgument(arss);
                }
        }

        else {
                Command::_currentSimpleCommand->insertArgument(argu);
        }
        return;
  }

  void expandWildcard(char * prefix, char *suffix) {
  }
  
  
void
yyerror(const char * s)
{
  fprintf(stderr,"%s", s);
}

#if 0
main()
{
  yyparse();
}
#endif
