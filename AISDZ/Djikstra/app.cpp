/* ----------------------------------------------------------------------------

  Glowna petla z obsluga polecen aplikacji

  UWAGI:
  - aplikacja przetwarza polecenia w petli i oddelegowuje ich wykonanie do
    odpowiednich funkcji (lub konczy prace gdy polecono jej zamkniecie);
  - polecenia wydaje sie przez wpisanie za znakiem zachety rozpoznawalnego
    przez aplikacje znaku "klucza";
  - aplikacja tworzy i zachowuje komunikacje z dynamiczna struktura TProject,
    na ktorej skupia sie: ladowanie danych i sprawdzanie ich poprawnosci,
    uruchomienie silnika obliczeniowego, zlecenie mu obliczen i zapamietanie
    wynikow w strukturach;
  - niektore funkcje obslugi polecen realizuja przygotowanie wynikow obliczen
    do wydruku;
  - maksymalna ilosc linii do wydruku na ekranie mozna ograniczyc ze wzgledow
    praktycznych wartoscia identyfikatora MAX_LINES (przyjeto 1000 linii);
  - jedna instancja aplikacji moze pracowac nad jednym projektem.

  Autor:  Artur Cyrwus                                    Data:  08-06-2021 r.

---------------------------------------------------------------------------- */

#include <string>
#include <iostream>
#include <fstream>
#include "app.h"
#include "project.h"
#include "engine/graph.h"
#include "engine/dsp.h"
#include "shell/dlgs.h"

using namespace std;


TProject *P;


void initApp() {
    // Alokacja i inicjacja nowego projektu
    P = initProject();
}


void killApp() {
    // Skasowanie projektu
    killProject(P);
}


//--- Deklaracje funkcji prywatnych zdefiniowanych dalej w tym pliku
//    (dlatego celowo sa poza plikiem naglowkowym)

int cmdLoadFile(TProject *P);
int cmdGraphInfo(TProject *P);
int cmdNodeInfo(TProject *P);
int cmdEdgeInfo(TProject *P);
int cmdPathfinder(TProject *P);

//---


#define CMD_OK                   0x00
#define CMD_CANCEL               0xf0
#define CMD_ERROR                0xff

#define CMD_L_DATA_OK            0x10
#define CMD_L_DATA_INCORRECT     0x11
#define CMD_L_DATA_INCOMPLETE    0x12
#define CMD_L_FILE_NOTFOUND      0x14
#define CMD_L_FILE_UNDEFINED     0x18


int runApp() {
    // Wydrukowanie powitania i ekranu pomocy
    msgHello();
    wndHelp();

    int status = 0;

    char cKey;
    do {
        // Wydrukowanie znaku zachety
        cout << "GRAFY> ";

        // Interakcja: Wczytanie skrotu polecenia
        cin >> cKey;
        cin.ignore(80, '\n');
        cin.clear();

        // Interpretacja polecenia
        switch (cKey)
        {
            /* Obsluga polecenia "wyczyszczenie ekranu" */
            case 'c': cKey = 'C';
            case 'C': system("cls");
                      break;

            /* Obsluga polecenia "wczytanie danych z pliku" */
            case 'l': cKey = 'L';
            case 'L': if (P->blank)
                        msgSourceInfo();
                      else {
                        if (dlgOverride() != DLG_OK)
                          break;
                      }
                      clearProject(P);
                      status = cmdLoadFile(P);
                      if (status == CMD_L_DATA_OK) {
                        if (startEngine(P))
                          status = CMD_OK;
                        else
                          status = CMD_ERROR;
                      }
                      break;

            /* Obsluga polecenia "wydruk informacji o grafie" */
            case 'g': cKey = 'G';
            case 'G': if (P->blank)
                        msgEmptyProject();
                      else
                        status = cmdGraphInfo(P);
                      break;

            /* Obsluga polecenia "wydruk informacji o wezlach grafu */
            case 'n': cKey = 'N';
            case 'N': if (P->blank)
                        msgEmptyProject();
                      else
                        status = cmdNodeInfo(P);
                      break;

            /* Obsluga polecenia "wydruk informacji o krawedziach grafu" */
            case 'e': cKey = 'E';
            case 'E': if (P->blank)
                          msgEmptyProject();
                      else
                        status = cmdEdgeInfo(P);
                      break;

            /* Obsluga polecenia "wyszukiwanie najkrotszych sciezek w grafie" */
            case 'p': cKey = 'P';
            case 'P': if (P->blank)
                          msgEmptyProject();
                      else
                        status = cmdPathfinder(P);
                      break;

            /* Obsluga polecenia "ekran pomocy o funkcjach programu" */
            case 'h': cKey = 'H';
            case 'H': wndHelp();
                      break;

            /* Obsluga polecenia "zakonczenia programu" */
            case 'q': cKey = 'Q';
            case 'Q': if (dlgQuit() == DLG_OK)
                        // Zwrocenie kodu prawidlowego zamkniecia podsystemu
                        return CMD_OK;
                      break;

            /* SERWISOWE polecenie "zrzut danych" */
            case 'd': cKey = 'D';
            case 'D': dumpWords(P->data);
                      break;

            /* Nieznane polecenie */
            default : msgUnknownOperation();
        }
    } while (status != CMD_ERROR);

    msgUnknownError();

    // Zwrocenie kodu zamkniecia podsystemu
    return status;
}




int cmdLoadFile(TProject* P) {
    // Utworzenie strumienia wejsciowego
    ifstream *fsInput = new ifstream;

    int tries = 3;
    do {
        cout << "\nPodaj nazwe pliku:  ";
        // Interakcja: wczytanie nazwy pliku zrodlowego
        string name;
        cin >> name;
        cin.ignore(80, '\n');
        cin.clear();

        // Proba otwarcia takiego pliku
        fsInput->open(name.c_str());

        // Sprawdzenie czy plik zostal otwarty, ...
        if (fsInput->is_open()) {
            // ... jesli tak, to zapisanie w projekcie nazwy pliku zrodlowego
            // oraz wyjscie z petli w celu prowadzenia kolejnych operacji
            P->filename = name;
            break;
        }
        else
            // ... a jesli nie, to (o ile nie wyczerpano limitu prob) ...
            if (--tries) {
                // ... zapytanie o kolejna probe wczytania nazwy pliku, ...
                if (dlgRetry() == DLG_OK)
                    // ... jesli zgoda - wznowienie w kolejnym cyklu petli
                    continue;
                else
                    // ... przy braku checi - zakonczenie polecenia
                    return CMD_L_FILE_UNDEFINED;
            }
            else {
                // ... a w razie wyczerpania limitu prob - wydrukowanie
                // komunikatu o braku pliku i zakonczenie polecenia
                msgFileNotFound();
                return CMD_L_FILE_NOTFOUND;
            }
    } while (tries);

    // Wczytanie otwartego pliku do ksiazki danych zrodlowych
    loadWords(P->data, fsInput);

    // Zamkniecie pliku zrodlowego ...
    fsInput->close();
    // ... i skasowanie strumienia wejsciowego
    delete fsInput;

    // Wykonanie testow poprawnosci danych, wydrukowanie komunikatow (o sukcesie
    // lub porazce) i zwrocenie stosownego kodu zakonczenia polecenia
    switch (checkData(P)) {
        case  0 : msgDataLoaded(P->filename);
                  // Zgaszenie znacznika pustego projektu, gdy dane wygladaja Ok.
                  P->blank = false;
                  return CMD_L_DATA_OK;

        case -1 : msgDataIncorrect(P->filename);
                  return CMD_L_DATA_INCORRECT;

        case -2 : msgDataIncomplete(P->filename);
                  return CMD_L_DATA_INCOMPLETE;
    }

    // Zwrocenie kodu nietypowego zakonczenia polecenia
    return CMD_ERROR;
}




int cmdGraphInfo(TProject *P) {
    const int *R = P->graph->profile;

    string S[7];
    // Obrobka wynikow, ...
    S[0] = to_string(R[gpNodes]);                   // wrs. "ilosc wezlow (wierzcholkow)"
    S[1] = to_string(R[gpEdges]);                   // wrs. "ilosc krawedzi unikalnych"
    S[2] = to_string(R[gpCycles]);                  // wrs. "ilosc cykli (pierscieni)"
    if (R[gpCycles] < 0)
        S[2] = "-";
    S[3] = to_string(R[gpIsolated]);                // wrs. "ilosc wezlow bez sasiedztwa"
    S[4] = (R[gpIsolated] == 0) ? "tak" : "nie";    // wrs. "czy graf spojny"
    S[5] = (R[gpDirected] == 0) ? "nie" : "tak";    // wrs. "czy graf skierowany"
    S[6] = (R[gpWeighted] == 0) ? "nie" : "tak";    // wrs. "czy graf wazony"
    // ... i wydrukowanie karty charakterystyki
    wndGraph(S);

    // Zwrocenie kodu zakonczenia polecenia
    return CMD_OK;
}




#define MAX_LINES  1000


string _strAdjacency(TGraph *G, int Id) {
    const int n = nodeDegree(G, Id);

    string sAdj = "";
    // Przejscie przez liste wezlow sasiednich, aby ...
    for (int a = 0; a < n; a++) {
        // ... Id wezla sasiedniego ...
        int adjId = nodeNeighbour(G, Id, a)->Id;
        // ... i dlugosc krawedzi, jaka laczy go z zadanym wezlem ...
        int weight = edgeWeight(G, Id, adjId);
        // ... skonwertowac na napis
        sAdj += to_string(adjId) + " (" + to_string(weight) + ")";
        // (wstawienie separatora)
        sAdj += (a < n -1) ? ", " : "";
    }
    // Zwrocenie napisu zawierajacego liste sasiedztwa wezla
    // wraz z przypisami w nawiasie jaki dystans dzieli dana pare wezlow
    return sAdj;
}


int cmdNodeInfo(TProject *P) {
    const int n = P->graph->order;

    // Nalozenie ograniczenia ilosci drukowanych linii
    int m = (n > MAX_LINES) ? MAX_LINES : n;

    // Obrobka danych, tj. ...
    string **S = new string*[m];
    // ... dla kazdego wezla, ...
    for (int i = 0; i < m; i++)
    {
        TNode *item = P->graph->nodes[i];
        // ... wygenerowanie wiersza do wydruku danych
        S[i] = new string[3];
        S[i][0] = to_string(item->Id);                  // kol. "wezel"
        S[i][1] = to_string(item->degree);              // kol. "stopien wezla"
        S[i][2] = _strAdjacency(P->graph, item->Id);    // kol. "wezly sasiednie"
    }
    // ... i wydrukowanie listy wezlow, ...
    wndNodes(S, m);
    // ... z ewentualnym uzupelnieniem komunikatu o ilosci wierszy
    if (n > m)
        cout << " z " << MAX_LINES << " (wydruk ograniczony)";
    cout << "\n\n";

    // Skasowanie tablicy napisow
    for (int i = 0; i < m; i++) {
        delete[] S[i];
        S[i] = NULL;
    }
    delete S;
    S = NULL;

    // Zwrocenie kodu zakonczenia polecenia
    return CMD_OK;
}




int cmdEdgeInfo(TProject *P) {
    const int e = countEdges(P->graph);

    // Nalozenie ograniczenia ilosci drukowanych linii
    int m = (e > MAX_LINES) ? MAX_LINES : e;

    // Obrobka danych, tj. ...
    string **S = new string*[m];
    // ... dla kazdej krawedzi, ...
    for (int i = 0; i < m; i++)
    {
        TEdge *item = P->graph->edges[i];
        // ... wygenerowanie wiersza do wydruku danych
        S[i] = new string[3];
        S[i][0] = to_string(item->startId);    // kol. "wezel poczatkowy"
        S[i][1] = to_string(item->stopId);     // kol. "wezel koncowy"
        S[i][2] = to_string(item->weight);     // kol. "dlugosc krawedzi"
    }
    // Wydrukowanie listy odcinkow, ...
    wndEdges(S, m);
    // ... z ewentualnym uzupelnieniem komunikatu o ilosci wierszy
    if (e > m)
        cout << " z " << MAX_LINES << " (wydruk ograniczony)";
    cout << "\n\n";

    // Skasowanie tablicy napisow
    for (int i = 0; i < m; i++) {
        delete[] S[i];
        S[i] = NULL;
    }
    delete S;
    S = NULL;

    // Zwrocenie kodu zakonczenia polecenia
    return CMD_OK;
}




int cmdPathfinder(TProject *P) {
    const int n = P->graph->order;

    // Wydrukowanie dostepnych opcji obliczen DSP, ...
    mnuOptionsDSP();
    // ... oraz dialog, w celu wyboru jednej z opcji
    int option = dlgOptionsDSP();
    if (option == DLG_CANCEL)
        return CMD_OK;

    cout << "\nTeraz nalezy okreslic wezel zrodlowy, ";
    cout << "wzgledem ktorego beda wyznaczane beda najkrotsze sciezki.";

    int startId;
    if (dlgNodeId("\nPodaj wezel zrodlowy", 0, n -1, startId) != DLG_OK)
        return CMD_CANCEL;

    // Eksploracja grafu w poszukiwaniu najkrotszych sciezek
    exploreGraph(P->journal, P->graph, startId);

    if (option == 1)
    {
        // Nalozenie ograniczenia ilosci drukowanych linii
        int m = (n > MAX_LINES) ? MAX_LINES : n;

        // Obrobka wynikow, tj. ...
        string **S = new string*[m];
        // ... dla kazdego wezla, ...
        for (int i = 0; i < m; i++)
        {
            TEntry *item = entry(P->journal, i);
            // ... wygenerowanie wiersza do wydruku wynikow
            S[i] = new string[3];
            S[i][0] = to_string(item->Id);               // kol. "do wezla"
            if (item->distance == 2147483647)
                 S[i][1] = "-";
            else S[i][1] = to_string(item->distance);    // kol. "dystans"
            if (item->prevId == -1)
                 S[i][2] = "-";
            else S[i][2] = to_string(item->prevId);      // kol. "przez wezel"
        }
        // Wydrukowanie listy najkrotszych drog, ...
        wndPaths(startId, S, m);
        // ... z ewentualnym uzupelnieniem komunikatu o ilosci wierszy
        if (n > m)
            cout << " z " << MAX_LINES << " (wydruk ograniczony)";
        cout << "\n";

        // Skasowanie tablicy napisow
        for (int i = 0; i < m; i++) {
            delete[] S[i];
            S[i] = NULL;
        }
        delete S;
        S = NULL;
    }

    int stopId;
    if (option == 2)
    {
        if (dlgNodeId("\nPodaj wezel koncowy", 0, n -1, stopId) != DLG_OK)
            return CMD_CANCEL;

        // Zebranie sekwencji wezlow po najkrotszej sciezce
        int *Ids = new int[n];
        int c = shortestPath(P->journal, stopId, Ids);

        cout << "\nNajkrotsza sciezka z wezla ";
        cout << startId << " do ";
        cout << stopId << " to:  ";
        // Wdyruk sekwencji wezlow po najkrotszej sciezce, ...
        if (c == 1 && Ids[0] == stopId) {
            cout << "-";
        }
        else
            for (int i = 0; i < c; i++) {
                // ... Id wezla
                cout << Ids[i];
                // (wstawienie separatora)
                cout << ((i < c -1) ? "-" : "");
            }
        cout << "\n";
        // Wydruk dystansu dzielacego wezel koncowy od zrodlowego
        cout << "Dystans dzielacy wezel ";
        cout << startId << " od ";
        cout << stopId << " wynosi lacznie: ";
        INT64 d = getDistance(P->journal, stopId);
        if (d == 2147483647)
             cout << "-";
        else cout << d;
        cout << "\n\n";
    }

    // Zwrocenie kodu zakonczenia polecenia
    return CMD_OK;
}


#undef MAX_LINES
