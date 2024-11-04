#ifndef AC_SHELL_GRID_H
#define AC_SHELL_GRID_H

#include <string>

using namespace std;


/*
  Struktura definiujaca siatke napisow
  title     - tytul siatki
  rows      - liczba wierszy siatki
  cols      - liczba kolumn siatki
  widths    - tablica okreslajaca szerokosci kazdej kolumny
  headers   - tablica okreslajaca naglowek kazdej kolumny
  cells     - siatka napisow, tj. 2-wym. tablica dynamiczna o zadeklarowanym
              rozmiarze (rows x cols)
*/
struct SGrid {
    string title;
    int rows;
    int cols;
    int *widths;
    int *align;
    string *headers;
    string **cells;
};

#define CSPAN ' '


void initGrid(SGrid *S, int rows, int cols);
void killGrid(SGrid *S);

void resetWidths(SGrid *S, int W[]);
void adjustWidths(SGrid *S);

bool hasTitle(SGrid *S);
bool hasHeaders(SGrid *S);
bool printTitle(SGrid *S);
bool printHeaders(SGrid *S);
void printRow(SGrid *S, int i);
void printLine(SGrid *S);
void printGrid(SGrid *S);


#endif // AC_SHELL_GRID_H
