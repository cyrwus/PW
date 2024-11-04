#ifndef AC_ENGINE_HEAP_H
#define AC_ENGINE_HEAP_H

#include "common.h"


inline int heapSize(INT64* H[]) {
    // Zwrocenie ilosci elementow w kopcu
    return int(*H[0]);
}

inline void heapSize(INT64* H[], int n) {
    // Zapisanie ilosci elementow w kopcu
    *H[0] = n;
}


INT64** initHeap(int n);
void killHeap(INT64* H[]);

void buildHeap(INT64* H[]);
void heapPush(INT64* H[], INT64 *item);
INT64* heapPop(INT64* H[]);


#endif // AC_ENGINE_HEAP_H
