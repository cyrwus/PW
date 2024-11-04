/* ----------------------------------------------------------------------------

  Elementy interfejsu aplikacji

  UWAGI:
  - komunikacja z uzytkownikiem odbywa sie wylacznie przez terminal tekstowy;
  - przyjeto nastepujaca konwencje podzialu elementow interfejsu:
    (msg) - komunikaty
    (dlg) - dialogi, z petlami wyboru okreslonych znakow "kluczy"
    (wnd) - tabulogramy

  Autor:  Artur Cyrwus                                    Data:  08-06-2021 r.

---------------------------------------------------------------------------- */

#include <string>
#include <iostream>
#include "dlgs.h"
#include "grid.h"

using namespace std;


/* Funkcje wydruku krotkich wiadomosci */


void msgHello() {
    // Wydrukowanie powitania na wyczyszczonym ekranie
    cout.flush();
    cout << "*** PROGRAM GRAFY ***";
    cout << endl;
}


void msgUnknownOperation() {
    // Wydrukowanie komunikatu o nieznanej operacji
    cout << "\nNieznane polecenie.";
    cout << "\nAby wyswietlic pomoc wcisnij klawisz H\n";
    cout << endl;
}


void msgEmptyProject() {
    // Wydrukowanie komunikatu o braku danych niezbednych do analizy
    cout << "\nBrak danych!";
    cout << "\nNajpierw nalezy wczytac dane z pliku.\n";
    cout << endl;
}


void msgSourceInfo() {
    // Wydrukowanie informacji o zrodle i rodzaju danych
    cout << "\nProgram korzysta z danych zapisanych w pliku tekstowym na dysku.";
    cout << "\nPlik musi zawierac liczby rozdzielone spacjami, tabulacja lub nowa linia.";
    cout << "\nWartosci te maja okreslac tzw. macierz sasiedztwa wierzcholkow grafu.";
    cout << endl;
}


void msgFileNotFound() {
    // Wydrukowanie komunikatu o nieudanej probie otwarcia pliku
    cout << "\nZbyt wiele prob otwarcia pliku zakonczylo sie niepowodzeniem.";
    cout << "\nSprawdz, czy podana nazwa pliku lub sciezka dostepu jest prawidlowa.";
    cout << "\nNiedozwolone sa spacje, tzw. polskie znaki, ani inne znaki specjalne.";
    cout << "\nUpewnij sie takze, czy plik istnieje w folderze programu lub podanej przez ciebie lokalizacji.\n";
    cout << endl;
}


void msgDataLoaded(string filename) {
    // Wypisanie komunikatu o wczytaniu danych
    cout << "\nWprowadzono dane z pliku " << filename << endl;
    cout << endl;
}


void msgDataIncorrect(string filename) {
    // Wypisanie komunikatu o nieprawidlowych danych
    cout << "\nBledne dane w pliku " << filename;
    cout << "\nDopuszczalne sa nieujemne liczby calkowite rozdzielone spacjami, tabulacja lub nowa linia.\n";
    cout << endl;
}


void msgDataIncomplete(string filename) {
    // Wypisanie komunikatu o niekompletnych danych
    cout << "\nNiekompletne dane w pliku " << filename;
    cout << "\nIlosc zapisanych danych musi zapewniac utworzenie kwadratowej macierzy sasiedztwa grafu.\n";
    cout << endl;
}


void msgNodeNotFound() {
    // Wypisanie komunikatu o braku wezla
    cout << "Wprowadzasz wezel, ktorego nie mozna znalezc.\n";
    cout << "Sprawdz jeszcze raz zadany graf i wywolaj polecenie ponownie.";
    cout << endl;
}


void msgUnknownError() {
    // Wypisanie komunikatu o nieznanym bledzie
    cout << "\nCos poszlo nie tak :(";
    cout << "\nSkontaktuj sie z autorem programu. Byc moze uda sie znalezc przyczyne problemu.\n";
    cout << endl;
}


void mnuOptionsDSP() {
    // Wypisanie informacji o grafie i dostepnych opcjach poszukiwania najkrotszych sciezek
    cout << "\nWyznaczanie najkrotszych sciezek w grafie (algorytm E.Dijkstry)";
    cout << "\n---------------------------------------------------------------";
    cout << endl;
    cout << "\nW zadanym grafie mozesz wyznaczyc:\n";
    cout << "[1] dlugosci najkrotszych sciezek z podanego wezla zrodlowego do wszystkich pozostalych wezlow\n";
    cout << "[2] sposob przejscia po najkrotszej sciezce z podanego wezla zrodlowego do innego wezla w grafie\n";
    cout << endl;
}


/* Funkcje wydruku tabulogramow */


void wndHelp() {
    // Inicjalizacja siatki napisow
    SGrid *S = new SGrid;
    initGrid(S, 8, 2);

    cout << endl;
    // Ustawienie tytulu i naglowkow siatki
    S->title = "Lista dostepnych polecen w programie";
    S->headers[0] = "skrot";
    S->headers[1] = "opis funkcji";
    // Wypelnienie siatki lista dostepnych funkcji programu, tj. ...
    // ... lista skrotow polecen, ...
    S->cells[0][0] = "c, C";
    S->cells[1][0] = "l, L";
    S->cells[2][0] = "g, G";
    S->cells[3][0] = "n, N";
    S->cells[4][0] = "e, E";
    S->cells[5][0] = "p, P";
    S->cells[6][0] = "h, H";
    S->cells[7][0] = "q, Q";
    // ... lista z opisami funkcji
    S->cells[0][1] = "wyczyszczenie okna terminala";
    S->cells[1][1] = "wczytanie danych o grafie z pliku na dysku";
    S->cells[2][1] = "przeglad podstawowych informacji o grafie";
    S->cells[3][1] = "zestawienie danych o wezlach (wierzcholkach) grafu tj. listy wezlow, listy sasiedztwa, ...";
    S->cells[4][1] = "zestawienie danych o krawedziach grafu tj. wezly incydentne, wagi krawedzi, ...";
    S->cells[5][1] = "poszukiwanie najkrotszych sciezek w grafie (wg algorytmu Dijkstry) i prezentacja wynikow.";
    S->cells[6][1] = "ekran pomocy o dostepnych funkcjach programu";
    S->cells[7][1] = "zakonczenie programu";

    // Ustawienie szerokosci kolumn dopasowanych do tresci, ...
    adjustWidths(S);
    // ... i wydrukowanie siatki napisow
    printGrid(S);
    cout << endl;

    // Skasowanie siatki napisow
    killGrid(S);
    delete S;
}


void wndGraph(string properties[]) {
    // Inicjalizacja siatki napisow
    SGrid *S = new SGrid;
    initGrid(S, 7, 2);

    cout << endl;
    // Ustawienie tytulu
    S->title = "Cechy charakterystyczne grafu";
    // Wypelnienie siatki wynikami, tj. ...
    // ... lista z etykietami wlasciwosci, ...
    S->cells[0][0] = "Ilosc wezlow (wierzcholkow) ...........";
    S->cells[1][0] = "Ilosc krawedzi unikalnych .............";
    S->cells[2][0] = "Ilosc cykli (pierscieni) ..............";
    S->cells[3][0] = "Ilosc wezlow izolowanych ..............";
    S->cells[4][0] = "Czy graf spojny? ......................";
    S->cells[5][0] = "Czy graf skierowany?...................";
    S->cells[6][0] = "Czy graf wazony? ......................";
    // ... lista obliczonych wielkosci
    for (int i = 0; i < 7; i++)
        S->cells[i][1] = properties[i];
    // Ustawienie szerokosci kolumn dopasowanych do tresci, ...
    adjustWidths(S);
    // ... i wydrukowanie siatki napisow
    printGrid(S);
    cout << endl;

    // Skasowanie siatki napisow
    killGrid(S);
    delete S;
}


void wndNodes(string *nodes[], int n) {
    // Inicjalizacja siatki napisow
    SGrid *S = new SGrid;
    initGrid(S, n, 3);

    cout << endl;
    // Ustawienie tytulu i naglowkow siatki
    S->title = "Zestawienie wezlow (wierzcholkow) grafu";
    S->headers[0] = "wezel ";
    S->headers[1] = "stopien ";
    S->headers[2] = "lista wezlow sasiednich (z dlugoscia krawedzi laczacej)";

    // Wypelnienie siatki z lista wezlow grafu, tj. ...
    for (int i = 0; i < n; i++) {
        S->cells[i][0] = nodes[i][0] + " ";      // wezel
        S->cells[i][1] = nodes[i][1] + "    ";   // stopien wezla
        S->cells[i][2] = nodes[i][2];            // lista wezlow sasiednich
    }
    // Ustawienie szerokosci kolumn dopasowanych do tresci, ...
    adjustWidths(S);
    // ... a takze kierunkow wyrownywania napisow ...
    S->align[0] = 1;
    S->align[1] = 1;
    S->align[2] = 0;
    // ... i wydrukowanie siatki napisow
    printGrid(S);
    cout << n << " wierszy";

    // Skasowanie siatki napisow
    killGrid(S);
    delete S;
}


void wndEdges(string *edges[], int n) {
    // Inicjalizacja siatki napisow
    SGrid *S = new SGrid;
    initGrid(S, n, 3);

    cout << endl;
    // Ustawienie tytulu i naglowkow siatki
    S->title = "Zestawienie krawedzi grafu";
    S->headers[0] = " w.pocz.";
    S->headers[1] = " w.konc.";
    S->headers[2] = " dlugosc";

    // Wypelnienie siatki z lista krawedzi grafu, tj. ...
    for (int i = 0; i < n; i++) {
        S->cells[i][0] = edges[i][0] + " ";    // wezel poczatkowy
        S->cells[i][1] = edges[i][1] + " ";    // wezel koncowy
        S->cells[i][2] = edges[i][2];          // dlugosc (waga) krawedzi
    }
    // Ustawienie szerokosci kolumn dopasowanych do tresci, ...
    adjustWidths(S);
    // ... a takze kierunkow wyrownywania napisow ...
    S->align[0] = 1;
    S->align[1] = 1;
    S->align[2] = 1;
    // ... i wydrukowanie siatki napisow
    printGrid(S);
    cout << n << " wierszy";

    // Skasowanie siatki napisow
    killGrid(S);
    delete S;
}


void wndPaths(int startId, string *itinerary[], int n) {
    // Inicjalizacja siatki napisow
    SGrid *S = new SGrid;
    initGrid(S, n, 3);

    cout << endl;
    // Ustawienie tytulu i naglowkow siatki
    S->title = "Tablica najkrotszych drog z wezla: " + to_string(startId);
    S->headers[0] = "  do celu  ";
    S->headers[1] = "  dystans  ";
    S->headers[2] = "przez wezel";

    // Wypelnienie siatki z lista najkrotszych drog do wezlow, tj. ...
    for (int i = 0; i < n; i++) {
        S->cells[i][0] = itinerary[i][0] + "  ";    // do wezla
        S->cells[i][1] = itinerary[i][1] + "  ";    // dystans
        S->cells[i][2] = itinerary[i][2] + "  ";    // przez wezel
    }
    // Ustawienie szerokosci kolumn dopasowanych do tresci, ...
    adjustWidths(S);
    // ... a takze kierunkow wyrownywania napisow ...
    S->align[0] = 1;
    S->align[1] = 1;
    S->align[2] = 1;
    // ... i wydrukowanie siatki napisow
    printGrid(S);
    cout << n << " wierszy";

    // Skasowanie siatki napisow
    killGrid(S);
    delete S;
}


/* Funkcje wydruku i obslugi dialogow */


int dlgYesNo(string ask) {
    // Wydrukowanie tresci dialogowej
    cout << ask;

    char cKey;
    do {
        // Wczytanie skrotu decyzji
        cin >> cKey;
        cin.ignore(80, '\n');
        cin.clear();

        // Interpretacja decyzji
        switch (cKey)
        {
            // Interakcja: potwierdzenie
            case 't': cKey = 'T';
            case 'T': return DLG_OK;

            // Interakcja: rezygnacja
            case 'n': cKey = 'N';
            case 'N': cout << endl;
                      return DLG_CANCEL;

            // Interakcja: nieznany skrot
            default : cout << "Tak, czy nie? [T/N]  ";
                      cKey = '?';
        }
    } while (cKey == '?');

    // Zwrocenie kodu bledu
    return DLG_ERROR;
}


int dlgOverride() {
    // Wydrukowanie zapytania o zgode na utrate biezacych danych,
    // wczytanie, interpretacja i zwrocenie kodu decyzji uzytkownika
    return dlgYesNo(
        "\nAktualnie wprowadzone dane zostana utracone."
        "\nCzy na pewno chcesz wczytac nowe dane z pliku? [T/N]  "
    );
}


int dlgRetry() {
    // Wydrukowanie zapytania o ponowienie proby otwarcia pliku,
    // wczytanie, interpretacja i zwrocenie kodu decyzji uzytkownika
    return dlgYesNo(
        "\nOtwarcie pliku nie powiodlo sie."
        "\nCzy chcesz sprobowac jeszcze raz? [T/N]  "
    );
}


int dlgQuit() {
    // Wydrukowanie zapytania o zakonczenie programu,
    // wczytanie, interpretacja i zwrocenie kodu decyzji uzytkownika
    return dlgYesNo(
        "Zakonczyc program? [T/N]  "
    );
}


int dlgOptionsDSP() {
    // Wydrukowanie tresci dialogowej
    cout << "Wybierz opcje:  ";

    char cKey;
    do {
        // Wczytanie skrotu decyzji
        cin >> cKey;
        cin.ignore(80, '\n');
        cin.clear();

        // Interpretacja decyzji
        switch (cKey)
        {
            // Interakcja: opcja 1.
            case '1': return 1;

            // Interakcja: opcja 2.
            case '2': return 2;

            case 'c': cKey = 'c';
            case 'C': cout << endl;
                return DLG_CANCEL;

            // Interakcja: nieznany skrot
            default: cout << "Opcja 1, 2, czy przerwac? [1/2/C]  ";
            cKey = '?';
        }
    } while (cKey == '?');

    // Zwrocenie kodu bledu
    return DLG_ERROR;
}


bool _isCardinal(string s) {
    // Proba konwersji napisu na wartosc calkowita
    int v = atoi(s.c_str());
    if (v < 0)
        // Jesli uzyskana wartosc jest ujemna, to jest niedozwolona
        return false;

    if (v > 0)
        // Jesli uzyskana wartosc jest dodatnia, to moze byc Ok pod warunkiem,
        // ze w wyniku konwersji zwrotnej uda sie uzyskac taki sam napis, ...
        return (s == to_string(v));
    else
        // ... w przeciwnym razie gdy wartosc jest zerowa - podlega sprawdzeniu
        // (trzeba rozstrzygnac czy faktycznie jest zerem, czy moze jest to wynik
        //  bledu konwersji?)
        return (s.length() == 1) ? (s[0] == '0') : false;
}

int dlgNodeId(string ask, int lBound, int uBound, int &Id) {
    // Dodaj informacje o oczekiwanym zakresie wartosci
    ask = ask + " (od " + to_string(lBound) + " do " + to_string(uBound) + "):  ";

    int tries = 3;
    do {
        cout << ask;
        // Interakcja: wczytanie Id wezla
        string name;
        cin >> name;
        cin.ignore(80, '\n');
        cin.clear();

        // ... proba konwersji napisu na wartosc calkowita ...
        Id = _isCardinal(name) ? atoi(name.c_str()) : -1;
        // ... i sprawdzenie, czy wartosc ta lezy w odpowiednim zakresie
        if (lBound <= Id && Id <= uBound)
            // ... jesli tak, to wyjscie z petli w celu prowadzenia kolejnych operacji
            return DLG_OK;
        else
            // ... a jesli nie, to (o ile nie wyczerpano limitu prob) ...
            if (--tries) {
                // ... wydrukowanie komunikatu o braku wezla
                // i wznowienie w kolejnym cyklu petli
                cout << "Nie ma takiego wezla!";
                continue;
            }
            else {
                // ... a w razie wyczerpania limitu prob - wydrukowanie komunikatu
                // o przerwaniu operacji wczytania Id wezla
                msgNodeNotFound();
                return DLG_CANCEL;
            }
    } while (tries);

    // Zwrocenie kodu bledu
    return DLG_ERROR;
}
