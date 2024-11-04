#ifndef AC_PROJECT_H
#define AC_PROJECT_H

#include <string>
#include "book.h"
#include "engine/graph.h"
#include "engine/dsp.h"

using namespace std;


/*
  Struktura "Zadanie projektowe"
  blank     - znacznik pustego projektu
  filename  - nazwa pliku, z ktorego wczytano dane
  data      - ksiazka danych zrodlowych (jednokierunkowa lista stron z danymi)
  graph     - struktura szkieletowa grafu
  journal   - dziennik obliczen DSP (Dijkstra Shortest Path)
  summary   - karta charakterystyki zadania projektowego
*/
struct TProject {
    bool blank;
    string filename;
    TBook *data;
    TGraph *graph;
    TJournal *journal;
};


TProject* initProject();
void killProject(TProject* &P);
void clearProject(TProject *P);

int checkData(TProject *P);

bool startEngine(TProject *P);
void stopEngine(TProject *P);


#endif // AC_PROJECT_H
