/* ----------------------------------------------------------------------------

  SGrid - Formatowany tabulogram drukowany na ekranie

  UWAGI:
  - dane tabulogramu umieszczane sa w 2-wym. tablicy typu string, o rozmiarach
    (rows x cols) okreslanych w trakcie inicjowania struktury;
  - szerokosci poszczegolnych kolumn mozna okreslic indywidualnie albo zlecic
    ich dobor automatycznie, gdy tablica napisow jest juz wypelniona, a wtedy
    tabulogram dostosuje szerokosci kolumn, tak aby pomiescily najszerszy opis
    obecny w kolumnie;
  - w tabulogramie mozna okreslic tytul oraz naglowki kolumn.

  Autor:  Artur Cyrwus                                    Data:  01-06-2021 r.

---------------------------------------------------------------------------- */

#include <string>
#include <iostream>
#include <iomanip>
#include "grid.h"

using namespace std;


void initGrid(SGrid *S, int rows, int cols) {
    // Ustawienie ilosci wierszy i kolumn w siatce napisow
    S->rows = rows;
    S->cols = cols;

    // Alokacja siatki napisow (2-wym. tablicy), tj. ...
    // ... najpierw tablica wskaznikow na wiersze, ...
    S->cells = new string*[rows];
    // ... nastepnie alokacja komorek
    for (int i = 0; i < rows; i++) {
        S->cells[i] = new string[cols];
    }

    // Alokacja tablicy naglowkow kolumn
    S->headers = new string[cols];

    // Alokacja tablic z parametrami dla kolumn, w tym: ...
    // ... szerokosci kolumn (z wyzerowaniem wartosci)
    S->widths = new int[cols];
    for (int i = 0; i < cols; i++)
        S->widths[i] = 0;
    // ... kierunki wyrownywania napisow
    S->align = new int[cols];
    for (int i = 0; i < cols; i++)
        S->align[i] = 0;
}


void killGrid(SGrid *S) {
    // Skasowanie siatki napisow (2-wym. tablicy), tj. ...
    for (int i = 0; i < S->rows; i++) {
        // ... najpierw skasowanie komorek, ...
        delete[] S->cells[i];
    }
    // ... nastepnie skasowanie tablicy wskaznikow na wiersze
    delete[] S->cells;

    // Skasowanie tablicy naglowkow kolumn
    delete[] S->headers;

    // Skasowanie tablic z parametrami dla kolumn, w tym: ...
    // ... szerokosci kolumn
    delete[] S->widths;
    // ... kierunki wyrownywania napisow
    delete[] S->align;
}


void resetWidths(SGrid *S, int W[]) {
    // Ustawienie szerokosci kolumn w siatce napisow
    for (int j = 0; j < S->cols; j++)
        S->widths[j] = W[j];
}


void adjustWidths(SGrid *S) {
    // Alokacja roboczej tablicy szerokosci kolumn
    int* W = new int[S->cols];

    // Ustalenie szerokosci napisow zawartych w naglowkach kolumn
    // i zapisanie tych wartosci w tablicy roboczej
    for (int j = 0; j < S->cols; j++) {
        W[j] = S->headers[j].length();
    }
    // Dla kazdego wiersza siatki, ...
    for (int i = 0; i < S->rows; i++)
        // ... ustalanie szerokosci napisow zawartych w komorkach,
        // z ewentualnym wnoszeniem korekty wartosci zapisanych w tablicy roboczej
        // o ile znaleziona szerokosc jest wieksza niz zapisana w tej tablicy
        for (int j = 0; j < S->cols; j++) {
            int w = S->cells[i][j].length();
            if (W[j] < w)
                W[j] = w;
        }
    // Przeniesienie wartosci z tablicy roboczej do tablicy szerokosci kolumn
    // o ile znaleziona szerokosc jest wieksza niz zapisana w tej tablicy
    for (int j = 0; j < S->cols; j++) {
        if (S->widths[j] < W[j])
            S->widths[j] = W[j];
    }

    // Skasowanie tablicy roboczej
    delete[] W;
}


bool hasTitle(SGrid *S) {
    // Zwrocenie wartosci logicznej czy siatka ma jakis tytul
    return (! S->title.empty());
}


bool hasHeaders(SGrid *S) {
    int c = S->cols;
    int j = 0;
    while (j < c) {
        // Przejscie przez tablice naglowkow, by sprawdzic czy istnieje
        // jakikolwiek napis niepusty, ...
        if (! S->headers[j].empty())
            // ... jesli tak, to przerwanie analizy
            break;
        j++;
    }
    // Zwrocenie wartosci logicznej czy w siatce sa jakies naglowki
    return (j < c);
}


bool printTitle(SGrid *S) {
    if (! hasTitle(S))
        return false;

    // Wydruk tytulu, o ile istnieje
    cout << S->title << endl;

    // Zwrocenie wartosci logicznej czy nastapil wydruk tytulu
    return true;
}


bool printHeaders(SGrid *S) {
    if (! hasHeaders(S))
        return false;

    // Wydruk naglowkow, o ile istnieja, tj. ...
    for (int j = 0; j < S->cols; j++) {
        // ... ustalenie szerokosci kolumny, ...
        int width = S->widths[j];
        // ... wydruk naglowka
        cout << ' ';
        cout << left << setw(width) << S->headers[j];
        cout << ' ';
    }
    cout << endl;

    // Zwrocenie wartosci logicznej czy nastapil wydruk naglowka
    return true;
}


void printRow(SGrid *S, int i) {
    // Wydrukowanie komorek w wierszu, tj. ...
    for (int j = 0; j < S->cols; j++) {
        // ... ustalenie szerokosci kolumny, ...
        int width = S->widths[j];
        // ... wydruk komorki
        cout << CSPAN;
        if (S->align[j] > 0)
            cout << right << setw(width) << S->cells[i][j];
        else cout << left << setw(width) << S->cells[i][j];
        cout << CSPAN;
    }
    cout << endl;
}


void printLine(SGrid *S) {
    // Wydrukowanie poziomej linii na calej szerokosci zajmowanej przez siatke
    cout << setfill('-');
    for (int j = 0; j < S->cols; j++) {
        // ... ustalenie szerokosci kolumny, ...
        int width = S->widths[j] +1;
        // ... wydruk komorki
        cout << '-';
        cout << left << setw(width);
        cout << '-';
    }
    cout << setfill(' ') << endl;
}


void printGrid(SGrid *S) {
    // Wydruk tytulu (o ile istnieje), ...
    if (printTitle(S))
        printLine(S);
    // ... naglowkow kolumn wraz z linia rozdzielajaca (o ile istnieja), ...
    if (printHeaders(S))
        printLine(S);
    // ... wierszy ...
    for (int i = 0; i < S->rows; i++)
        printRow(S, i);
    // ... i stopki
    printLine(S);
}
