#ifndef AC_ENGINE_DSP_H
#define AC_ENGINE_DSP_H

#include "common.h"
#include "graph.h"
#include "heap.h"


/*
  Struktura definiujaca wpis do dziennika obliczen
  We wpisie umieszcza sie jednostkowe wyniki obliczen DSP dla wezla
  distance  - dystans dzielacy dany wezel od wezla startowego
  Id        - indeks wezla, ktorego dotyczy wpis
  prevId    - indeks wezla, ktory w najkrotszej sciezce poprzedza w/w wezel
  visited   - wartosc logiczna okreslajaca czy wezel zostal zwiedzony
*/
struct TEntry {
    INT64 distance;
//---
    int Id;
    int prevId;
    bool visited;
};


/*
  Struktura definiujaca dziennik obliczen DSP (Dijkstra Shortest Path)
  length    - ilosc wpisow dziennika
  entries   - lista wpisow, tj. n-elementowa tablica dynamiczna, przechowujaca
              wskazniki wszystkich wpisow dziennika
*/
struct TJournal {
    int length;
    TEntry **entries;
};


// *** Otoczki typowych funkcji kopca binarnego
//   - implementacja priorytetowej kolejki wpisow dziennika ***


inline TEntry** initQueue(int n) {
    // Zainicjowanie kolejki priorytetowej
    return (TEntry**)initHeap(n);
}

inline void killQueue(TEntry* Q[]) {
    // Skasowanie kolejki priorytetowej
    killHeap((INT64**)Q);
}

inline int queueSize(TEntry* Q[]) {
    // Zwrocenie ilosci elementow w kolejce priorytetowej
    return heapSize((INT64**)Q);
}

inline void queueSize(TEntry* Q[], int n) {
    // Ustawienie ilosci elementow w kolejce priorytetowej
    heapSize((INT64**)Q, n);
}

inline TEntry* queueTop(TEntry* Q[]) {
    // O ile kolejka jest niepusta, ...
    if (queueSize(Q) > 0)
        // ... zwrocenie znajdujacego sie na czele kolejki wskaznika na wpis
        return Q[1];
    // ... w przeciwnym razie zwrocenie adresu pustego
    else return NULL;
}

inline void queueSort(TEntry* Q[]) {
    // Przesortowanie kolejki priorytetowej
    // (na czele kolejki wpis z minimalna wartoscia pola INT64*)
    buildHeap((INT64**)Q);
}

inline void enqueue(TEntry* Q[], TEntry *item) {
    // Wprowadzenie do kolejki priorytetowej wskaznika na wpis
    heapPush((INT64**)Q, (INT64*)item);
}

inline TEntry* dequeue(TEntry* Q[]) {
    // Zdjecie znajdujacego sie na czele kolejki wskaznika na wpis
    // i zwrocenie tego wskaznika
    return (TEntry*)heapPop((INT64**)Q);
}


// *** Funkcje dziennika obliczen DSP (Dijkstra Shortest Path) ***


inline TEntry* entry(TJournal *J, int Id) {
    // Wybor z listy wpisow wskaznika na wpis o podanym Id
    // i zwrocenie tego wskaznika
    return J->entries[Id];
}


TJournal* initJournal(int length);
void killJournal(TJournal* &J);

void exploreGraph(TJournal *J, TGraph *G, int startId);
int shortestPath(TJournal *J, int endId, int Ids[]);
INT64 getDistance(TJournal *J, int endId);


#endif // AC_ENGINE_DSP_H
