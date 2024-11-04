/* ----------------------------------------------------------------------------

  Przedmiot:  639B-ETxxx-IEP-AISDZ (Algorytmy i Struktury Danych - 2021L)

  Temat P3:   Teoria grafow / algorytm Dijkstry

  Z pliku o nazwie podanej przez uzytkownika, program wczytuje graf w postaci
  macierzy sasiedztwa a nastepnie tworzy liste sasiedztwa opisujaca ten graf.
  Na podstawie tej listy metoda Dijkstry wyznacza najkrotsza sciezke w grafie
  dla dwoch wezlow wskazanych przez uzytkownika.
  Na koniec cala struktura danych zostaje skasowana z pamieci.

  Autor:  Artur Cyrwus                                    Data:  08-06-2021 r.

---------------------------------------------------------------------------- */

#include "app.h"


int main()
{
    // Zainicjowanie i uruchomienie aplikacji
    initApp();
    int status = runApp();

    // Skasowanie utworzonych struktur po zakonczeniu pracy
    killApp();

    return status;
}
