#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>

int main() {
    char op[32];
    int a, b;

    while (scanf("%s %d %d", op, &a, &b) == 3) {
        char path[64];
        snprintf(path, sizeof(path), "./lib%s.so", op);

        void *handle = dlopen(path, RTLD_LAZY);
        if (!handle) {
            continue;
        }
      
        dlerror();
        int (*func)(int, int) = (int (*)(int, int))dlsym(handle, op);

        if (dlerror() == NULL && func != NULL) {
            printf("%d\n", func(a, b));
        }
      dlclose(handle);
    }
    return 0;
}
