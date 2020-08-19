%{

#include <cstring>
#include "y.tab.hh"
#include <unistd.h>
#include <sys/wait.h>
static  void yyunput (int c,char *buf_ptr  );  

void myunputc(int c) {
  unput(c);
}
/*
char * read_line();
int mygetc(FILE * f) {
        static char *p;
        char ch;

        if (!isatty(0)) {
                return getc(f);
        }

        if (p == NULL || *p == 0) {
                char * s = read_line();
                p = s;
        }

        ch = *p;
        p++;

        return ch;
}

#undef getc
#define getc(f) mygetc(f)
*/
%}

%option noyywrap

%%

\n {
  return NEWLINE;
}

[ \t] {
  /* Discard spaces and tabs */
}

">" {
  return GREAT;
}

">&" {
  return GREAT_AMPERSAND;
}

"<" {
  return LESS;
}

"<&" {
  return LESS_AMPERSAND;
}

">>" {
  return GREAT_GREAT;
}

">>&" {
  return GREAT_GREAT_AMPERSAND;
}

"&" {
  return AMPERSAND;
}

"|" {
  return PIPE;
}

"2>" {
  return TWO_GREAT;
}

\"[^\n\"]*\" {
  /* Add support for quotations */
  char * quote_chars = new char[strlen(yytext)];
  char * text = yytext;
  int counter = 0;

  while (*text) {
        if (*text == '\"') {
                quote_chars[counter] = *(++text);
                counter++;
        }
        else {
                quote_chars[counter]= *text;
                counter++;
        }
        text++;
  }

  quote_chars[counter] = '\0';
  yylval.cpp_string = new std::string(quote_chars);
  return WORD;
}

[^ \t\n|><&]*\\[^ \t\n]* {
  /* Add support for escape characters */
  char * escape_chars = new char[strlen(yytext) * 2];
  char * text = yytext;
  int counter = 0;

  while (*text) {
        if (*text == '\\') {
                escape_chars[counter] = *(++text);
                counter++;
        }
        else {
                escape_chars[counter] = *text;
                counter++;
        }
        text++;
  }
  escape_chars[counter] = '\0';
  yylval.cpp_string = new std::string(escape_chars);
  return WORD;
}

\$\([^\n\$]*\)|`[^\n`]*` {
        std::string * command = new std::string(yytext);
        command->pop_back();
        if (strchr(command->c_str(), '`') != NULL) {
                command = new std::string(yytext+1);
                command->pop_back();
        }

        else {
                command = new std::string(yytext+2);
                command->pop_back();
        }

        int tempin = dup(0);
        int tempout = dup(1);

        // Parent will create two pipes
        int pin[2];
        int pout[2];

        pipe(pin);
        pipe(pout);

        write(pin[1], command->c_str(), command->size());
        write(pin[1], "\n", 1);
        write(pin[1], "exit", 4);
        write(pin[1], "\n", 1);
        close(pin[1]);

        dup2(pin[0], 0);
        close(pin[0]);
        dup2(pout[1], 1);
        close(pout[1]);
        int child = fork();
        if (child == 0) {
                execvp("/proc/self/exe", NULL);
                _exit(1);
        }
        else if (child < 0) {
                perror("fork");
                exit(1);
        }

        // restore input/output defaults
        dup2(tempin, 0);
        dup2(tempout, 1);
        close(tempin);
        close(tempout);

        // read from pipeout
        char chars;
        size_t size = 0;
        int counter = 0;
        char * buffer = new char[5128];
        while (read(pout[0], &chars, 1)) {
                if ( chars == '\n') {
                         buffer[counter++] = ' ';
                }
                else {
                         buffer[counter++] = chars;
                }
        }
        buffer[counter] = '\0';
        for (int i = strlen(buffer) - 1; i >= 0; i--) {
                myunputc(buffer[i]);
        }
}

[^ \t\n][^ \t\n]*  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);
  return WORD;
}
      
