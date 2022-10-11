#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char* argv[])
{
    int new_priority, proc_pid;

    if(argc != 3)
    {
        printf("Invalid number of arguments\n");
        exit(1);
    }

    new_priority = atoi(argv[1]);
    proc_pid = atoi(argv[2]);

    printf("Process priority being updated to: %d\n", setpriority(new_priority, proc_pid));
    exit(0);
}