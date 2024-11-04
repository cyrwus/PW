/* ----------------------------------------------------------------------------

  TJournal / TEntry - struktury algorytmu DSP (Dijkstra Shortest Path)

  UWAGI:
  - algorytm wyszukuje w zadanym grafie najkrotsze sciezki od podanego wezla
    poczatkowego do wszystkich pozostalych wezlow, wyliczajac rowniez "koszt"
    przejscia kazdej z tych sciezek, zgodnie z algorytmem Dijkstry;
  - w trakcie przejscia przez wezly grafu w poszukiwaniu najkrotszych sciezek
    wyniki analizy zapisywane sa na biezaco w dzienniku obliczen;
  - dziennik obliczen to zbior "wpisow", w ktorych umieszcza sie jednostkowe
    wyniki obliczen DSP dla kazdego wezla;
  - wpisy z dziennika obliczen przetwarzane sa w kolejce priorytetowej, ktora
    "promuje" do nastepnego kroku obliczeniowego wpis o najkorzystniejszym
    biezacym wyniku jednostkowym (czyli wpis zwiazany z wezlem zlokalizowanym
    na najkrotszej sciezce).

  Autor:  Artur Cyrwus                                    Data:  09-06-2021 r.

---------------------------------------------------------------------------- */

#include "common.h"
#include "dsp.h"


TJournal* initJournal(int length) {
    // Alokacja nowego dziennika, ...
    TJournal *J = new TJournal;
    // ... z ustawieniem podanej wielosci
    J->length = length;

    // Alias na wielkosc dziennika
    const int &n = J->length;

    // Alokacja listy wpisow dziennika, tj. ...
    // ... najpierw tablica wskaznikow na wpisy, ...
    J->entries = new TEntry*[n];
    // ... nastepnie alokacja wszystkich wpisow
    for (int i = 0; i < n; i++) {
        J->entries[i] = new TEntry;
        J->entries[i]->Id = i;
    }

    // Zwrocenie wskaznika na zainicjowany dziennik obliczen DSP
    return J;
}


void killJournal(TJournal* &J) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (J == NULL)
        return;

    // Alias na wielkosc dziennika
    const int &n = J->length;

    // Skasowanie listy wpisow dziennika, tj. ...
    for (int i = 0; i < n; i++)
        // ... najpierw skasowanie wpisow, ...
        delete J->entries[i];
    // ... nastepnie skasowanie tablicy wskaznikow na wpisy
    delete[] J->entries;
    J->entries = NULL;

    // Skasowanie dziennika i zwrocenie przez parametr wyzerowanego wskaznika
    delete J;
    J = NULL;
}


TEntry* _clearEntry(TEntry *E) {
    // Ustawienie danych poczatkowych w podanym wpisie, tj. ...
    E->distance = 2147483647;  // ... dystans od wezla poczatkowego - nieznany
    E->prevId = -1;            // ... Id wezla poprzedzajacego - nieznany
    E->visited = false;        // ... status - nie zwiedzony

    // Zwrocenie wskaznika na ten wpis
    return E;
}

void exploreGraph(TJournal *J, TGraph *G, int startId) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (J == NULL || G == NULL)
        return;

    // Alias na wielkosc dziennika
    const int &n = J->length;

// *** Umieszczenie wpisow dziennika w kolejce priorytetowej ***

    // Zainicjowanie kolejki ...
    TEntry **Q = initQueue(n);
    // ... wprowadzenie do kolejki wskaznikow na wpisy, 
    // z ustawieniem w nich wartosci poczatkowych
    for (int i = 0; i < n; i++)
        enqueue(Q, _clearEntry(entry(J, i)));

// *** Analiza grafu z umieszczaniem wynikow w dzienniku obliczen DSP ***

    // Wyzerowanie dystansu we wpisie zwiazanym w wezlem startowym
    entry(J, startId)->distance = 0;
    // Przesortowanie* kolejki wpisow (*tzn. przywrocenie struktury kopca binarnego)
    queueSort(Q);

    // Tak dlugo jak w kolejce czekaja niegotowe wpisy, ...
    while (queueSize(Q) > 0) {
        // ... odczyt Id wezla z czola kolejki priorytetowej ...
        int currId = queueTop(Q)->Id;
        // ... i dla kazdego wezla sasiadujacego z nim ...
        for (int i = 0; i < nodeDegree(G, currId); i++) {
            // ... ustalenie indeksu wezla nastepnego, aby ...
            int nextId = nodeNeighbour(G, currId, i)->Id;
            // ... o ile tamten wezel nie byl juz wczesniej zwiedzony, ...
            if (! entry(J, nextId)->visited) {
                // ... ustalic jaki bylby laczny dystans wezla nastepnego
                // od punktu startu (jako suma dystansu znanego w wezle biezacym
                // i dlugosci krawedzi do nastepnego) ...
                INT64 d = entry(J, currId)->distance + edgeWeight(G, currId, nextId);
                // ... i sprawdzic czy dystans we wpisie zwiazanym z tamtym wezlem
                // nie jest wiekszy niz ten, ktory wlasnie udalo sie ustalic, ...
                if (entry(J, nextId)->distance > d) {
                    // ... bo gdy droga krotsza -- ZAPIS ...
                    entry(J, nextId)->distance = d;
                    entry(J, nextId)->prevId = currId;
                    // ... i przesortowanie kolejki wezlow
                    queueSort(Q);
                }
            }
        }
        // Zdjecie z kolejki biezacego wpisu i oznaczenie statusu jako "zwiedzony"
        dequeue(Q)->visited = true;
    }

    // Skasowanie kolejki priorytetowej przetworzonych wpisow
    killQueue(Q);
}


int shortestPath(TJournal *J, int endId, int Ids[]) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (J == NULL)
        return -1;

// Zaklada sie, ze dla podanej tablicy wynikowej przydzielono pamiec
// w rozmiarze wystarczajacym do wpisania calej sekwencji wezlow.

    int currId = endId;
    // Zebranie w tablicy wynikowej sekwencji wezlow po najkrotszej sciezce,
    // od wezla koncowego do startowego, z ktorego graf byl eksplorowany
    int n = 0;
    do {
        Ids[n++] = currId;
        currId = entry(J, currId)->prevId;
    } while (currId != -1);

    // Odwrocenie kolejnosci elementow w tablicy wynikowej
    for (int i = 0; i < n / 2; i++) {
        int x = Ids[i];
                Ids[i] = Ids[n -1 -i];
                         Ids[n -1 -i] = x;
    }

    // Zwrocenie ilosci elementow w tablicy wynikowej
    return n;
}


INT64 getDistance(TJournal *J, int endId) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (J == NULL)
        return -1;

    // Zwrocenie dystansu dzielacego wezel koncowy o podanym Id
    // od wezla poczatkowego, z ktorego graf byl eksplorowany
    return entry(J, endId)->distance;
}
