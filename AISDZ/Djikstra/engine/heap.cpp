/* ----------------------------------------------------------------------------

  Kopiec binarny typu minimalnego

  UWAGI:
  - n-elementowy kopiec w tablicowej strukturze o (1+ n) elementach;
  - indeksowanie elementow kopca zaczyna sie od 1;
  - elementami kopca sa wskazniki na 64-bitowe liczby calkowite;
  - ilosc elementow w kopcu okresla liczba wskazywana przez H[0];
  - sortowanie elementow kopca odbywa sie w porzadku "na szczycie wskaznik
    do wartosci minimalnej".

  Autor:  Artur Cyrwus                                    Data:  09-06-2021 r.

---------------------------------------------------------------------------- */

#include "common.h"
#include "heap.h"


INT64** initHeap(int n) {
    // Zainicjowanie kopca, tj. ...
    // ... alokacja tablicy wskaznikow na 64-bitowe liczby calkowite, ...
    INT64** H = new INT64*[1+ n];
    // ... utworzenie elementu zerowego (licznika elementow kopca) ...
    H[0] = new INT64;
    // ... i wyzerowanie licznika
    heapSize(H, 0);
    // Zwrocenie zainicjowanej struktury tablicowej kopca
    return H;
}


void killHeap(INT64* H[]) {
    // Skasowanie kopca, tj. ...
    // ... najpierw skasowanie elementu zerowego (licznik elementow kopca), ...
    delete H[0];
    // ... nastepnie skasowanie tablicy
    delete[] H;
}
// UWAGA
// Stos nie kasuje elementow, ktore byly do niego wprowadzone, gdyz zaklada sie
// mozliwosc korzystania z nich w innej czesci kodu.


void _heapifyMin(INT64* H[], int p) {
    int n = heapSize(H);
/*
  Ustalenie indeksu "potomka minimalnego"
*/
    // Obliczenie indeksu potomka lewego (c = 2 * p)
    int c = p << 1;
    // Sprawdzenie czy lewy potomek lezy w zakresie tablicy, ...
    if (c > n)
        // ... jesli nie, to koniec (podany rodzic nie ma potomka)
        return;
    // Sprawdzenie czy prawy potomek lezy w zakresie tablicy
    // oraz czy zawiera wartosc mniejsza niz potomek lewy ...
    if (c < n && *H[c] > *H[c +1])
        // ... jesli tak, to "potomkiem minimalnym" jest prawy (c +1)
        c++;
    // ... w przeciwnym razie potomek lewy pozostaje "potomkiem minimalnym"
/*
  Sprawdzenie czy rodzic zawiera wartosc niewieksza niz "potomek minimalny"
*/
    // Porownanie "potomka minimalnego" z rodzicem, ...
    if (*H[c] < *H[p]) {
        // ... jesli potomek zawiera mniejsza wartosc niz rodzic,
        // konieczna jest zamiana tych elementow miejscami ...
        INT64 *x = H[p];
                   H[p] = H[c];
                          H[c] = x;
        // ... i rekurencyjne porzadkowanie kopca w dol struktury
        _heapifyMin(H, c);
    }
}


void buildHeap(INT64* H[]) {
    // Ustalenie indeksu najodleglejszego rodzica ...
    int p = heapSize(H) >> 1;
    // ... i porzadkowanie kopca od tego elementu az po szczyt
    while (p > 0)
        _heapifyMin(H, p--);
}


void heapPush(INT64* H[], INT64 *item) {
    // Ustalenie indeksu dla nowo dodawanego elementu ...
    int i = heapSize(H) + 1;
    // ... i zwiekszenie licznika elementow
    heapSize(H, i);

    while (i > 1) {
        // Ustalenie indeksu potencjalnego rodzica ...
        int p = i >> 1;
        // ... porownanie go z nowo dodawanym elementem
        // (w celu sprawdzenia, czy nadaje sie on na rodzica) ...
        if (*item < *H[p]) {
            // ... jesli nowy element zawiera mniejsza wartosc niz ten rodzic,
            // konieczne jest zepchniecie rodzica do roli potomka (aby zwolnic
            // miejsce dla nowego elementu wyzej w strukturze)
            H[i] = H[p];
            // W kolejnej iteracji sprawdzenie ma dotyczyc rodzica tego rodzica
            i = p;
        }
        else break;
    }
    // Zapis nowego elementu w wolne miejsce w kopcu
    H[i] = item;
}


INT64* heapPop(INT64* H[]) {
    int n = heapSize(H);
    // O ile kopiec jest niepusty, zdjecie elementu ze szczytu, tj. ...
    if (n > 0) {
        // ... zamiana miejscami elementu pierwszego z ostatnim w kopcu, ...
        INT64 *x = H[1];
                   H[1] = H[n];
                          H[n] = x;
        // ... zmniejszenie licznika elementow ...
        heapSize(H, --n);
        // ... i porzadkowanie kopca od szczytu w dol struktury
        _heapifyMin(H, 1);
        // Na koniec zwrocenie elementu, ktory byl na szczycie
        return x;
    }
    else return NULL;
}
// INFORMACJA
// Zdejmowane ze szczytu elementy pozostaja w tablicy, lecz trafiaja poza zakres
// okreslony przez licznik elementow kopca. Tym samym, sukcesywne zdejmowanie
// elementow ze szczytu tworzy w tablicy posortowany liniowo ciag wartosci.
// Wlasnosc te mozna wykorzystac do sortowania na kopcu.
