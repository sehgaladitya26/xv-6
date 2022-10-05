#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define STDOUT 2

int 
main(int argc, char *argv[])
{
  int i = 2;
  char *arg_exec[MAXARG];

  // Error check
  if(argc < 3){
    printf("Error(trace): Incorrect command\n");
    exit(1);
  }

  if (trace(atoi(argv[1])) < 0) {
    printf("Error(trace): integer mask invalid\n");
    exit(1);
  }
  
  while(i < argc && i < MAXARG) {
    arg_exec[i-2] = argv[i]; 
    i++;
  }

  exec(arg_exec[0], arg_exec);
  exit(0);
}