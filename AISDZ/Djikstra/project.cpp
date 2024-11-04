/* ----------------------------------------------------------------------------

  TProject - struktura "Zadanie projektowe"

  UWAGI:
  - struktura ta wczytuje, przechowuje i sprawdza poprawnosc danych o grafie;
  - dane wczytywane sa z pliku i zapisywane w ksiazce danych zrodlowych;
  - wyspecjalizowane funkcje logiczne badaja czy caly zbior danych zrodlowych
    mozna zamienic na liczby naturalne, a takze czy ilosc danych jest liczba
    kwadratowa;
  - funkcje na strukturze uruchamiaja i zatrzymuja silnik obliczeniowy.

  Autor:  Artur Cyrwus                                    Data:  09-06-2021 r.

---------------------------------------------------------------------------- */

#include <string>
#include <cmath>
#include "book.h"
#include "project.h"
#include "engine/graph.h"
#include "engine/dsp.h"

using namespace std;


TProject* initProject() {
    // Alokacja nowego projektu ...
    TProject *P = new TProject;
    // ... z "wyzerowaniem" wartosci kontrolnych projektu ...
    P->blank = true;
    P->filename = "";
    // ... oraz zainicjowaniem ksiazki danych zrodlowych
    P->data = initBook();

    // Struktury grafu pozostaja na razie niezainicjowane
    // (do czasu uruchomienia silnika obliczeniowego, po wczytaniu danych)
    P->graph = NULL;
    P->journal = NULL;

    // Zwrocenie wskaznika na zainicjowany projekt
    return P;
}


void killProject(TProject* &P) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (P == NULL)
        return;

    // Zatrzymanie silnika obliczeniowego (ze skasowaniem jego struktur!) ...
    stopEngine(P);
    // ... i skasowanie ksiazki danych zrodlowych
    killBook(P->data);

    // Skasowanie projektu i zwrocenie przez parametr wyzerowanego wskaznika
    delete P;
    P = NULL;
}


void clearProject(TProject *P) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (P == NULL)
        return;

    // Zatrzymanie silnika obliczeniowego (ze skasowaniem jego struktur!) ...
    stopEngine(P);
    // ... i wyczyszczenie ksiazki danych zrodlowych (bez kasowania) ...
    clearBook(P->data);
    // ... oraz "wyzerowanie" wartosci kontrolnych projektu
    P->blank = true;
    P->filename = "";
}


bool isCardinal(string s) {
    // Zakonczenie, gdy podany napis jest pusty
    if (s == "")
        return false;

    // Proba konwersji napisu na wartosc calkowita
    int v = atoi(s.c_str());
    if (v < 0)
        // Jesli uzyskana wartosc jest ujemna, to jest niedozwolona
        return false;

    if (v > 0)
        // Jesli uzyskana wartosc jest dodatnia, to moze byc Ok. pod warunkiem,
        // ze w wyniku konwersji zwrotnej uzyska sie identyczny napis, ...
        return (s == to_string(v));
    else
        // ... w przeciwnym razie gdy wartosc jest zerowa - podlega sprawdzeniu
        // (trzeba rozstrzygnac czy faktycznie jest zerem, czy moze jest to wynik
        //  bledu konwersji?)
        return (s.length() == 1) ? (s[0] == '0') : false;
}

bool allCardinals(TBook *B) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (B == NULL)
        return false;

    // Przejscie przez wszystkie strony ksiazki danych zrodlowych, ...
    for (TPage *curr = B;  curr != NULL;  curr = curr->next)
        // ... z przekazaniem wszystkich slow do sprawdzenia ...
        for (int i = 0; i < curr->count; i++)
            // ... czy daja sie zamienic na liczby naturalne, ...
            if (! isCardinal(curr->words[i])) {
                // ... bo jesli choc jedna z nich nie podda sie konwersji,
                // to wczytany zbior slow nie moze zostac uznany za poprawny
                return false;
            }
    // Wszystkie slowa w ksiazce danych zrodlowych to liczby naturalne
    return true;
}

bool squareSize(TBook *B) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (B == NULL)
        return false;

    // Ustalenie ilosci wszystkich slow w ksiazce danych zrodlowych ...
    int w = countWords(B);
    // ... i sprawdzenie czy ta ilosc jest liczba kwadratowa, ...
    if (w > 0) {
        double i;
        // ... (przez wyliczenie reszty z pierwiastka kwadratowego), ...
        return (modf(sqrt(w), &i) == 0);
        // ... bo jesli ilosc slow nie spelnia zaleznosci kwadratowej,
        // to wczytany zbior slow nie moze zostac uznany za kompletny
    }
    // Brak danych!
    return false;
}

int checkData(TProject *P) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (P == NULL)
        return -3;

    // Sprawdzenie czy ilosc slow w ksiazce danych zrodlowych jest liczba
    // kwadratowa (co pozwoli jednoznacznie wypelnic macierz kwadratowa), ...
    if (! squareSize(P->data)) {
        // ... bo jesli nie, to wczytany zbior slow nie jest kompletny
        return -2;
    }
    // Sprawdzenie czy wszystkie slowa da sie zamienic na liczby naturalne, ...
    if (! allCardinals(P->data)) {
        // ... bo jesli nie, to czytany zbior slow nie jest poprawny
        return -1;
    }
    // Zawartosc ksiazki danych wyglada prawidlowo
    return 0;
}


bool startEngine(TProject *P) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (P == NULL)
        return false;

    // Ustalenie ilosci slow w ksiazce danych zrodlowych ...
    int w = countWords(P->data);
    if (w == 0)
        // ... i ewentualne zakonczenie, gdy danych brak
        return false;

    // Obliczenie rzedu grafu
    int n = (int)sqrt(w);

    // Wykonanie pelnego testu poprawnosci danych zrodlowych ...
    if (checkData(P) != 0)
        // ... i ewentualne wyjscie, gdy dane nie wygladaja prawidlowo
        return false;

    // Zainicjowanie struktury grafu ...
    P->graph = initGraph(n);
    // ... oraz przejscie przez cala ksiazke danych, ...
    for (TPage *curr = P->data;  curr != NULL;  curr = curr->next)
        // ... z konwersja wszystkich slow na wartosci liczbowe ...
        for (int i = w = 0;  i < curr->count;  i++, w++) {
            // ... i wpisaniem ich do macierzy sasiedztwa w grafie
            P->graph->adjMatrix[w / n][w % n] = atoi(curr->words[i].c_str());
        }

    // Zbudowanie modelu grafu
    buildModel(P->graph);

    // Zainicjowanie dziennika obliczen DSP
    P->journal = initJournal(n);

    // Silnik uruchomiony, zasilony danymi zrodlowymi i gotowy do analiz grafu
    return true;
}


void stopEngine(TProject *P) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (P == NULL)
        return;

    // Skasowanie (o ile zostaly zainicjowane) dziennika obliczen DSP, ...
    if (P->journal != NULL)
        killJournal(P->journal);
    // ... i struktury grafu
    if (P->graph != NULL)
        killGraph(P->graph);
}
