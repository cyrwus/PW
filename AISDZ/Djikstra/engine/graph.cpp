/* ----------------------------------------------------------------------------

  TGraph - struktura szkieletowa grafu

  UWAGI:
  - bazowa struktura opisujaca graf jest macierz sasiedztwa - jest to macierz
    liczb calkowitych, przy czym niezerowe elementy okreslaja wagi krawedzi
    laczacych wezly grafu (macierz w ukladzie: wezel poczatkowy w wierszu,
    wezly koncowe w kolumnach);
  - wezlom grafu mozna przypisac nazwy, jednak unikalnosc tych nazw w calym
    grafie nie jest sprawdzana.

  Autor:  Artur Cyrwus                                    Data:  09-06-2021 r.

---------------------------------------------------------------------------- */

#include "array.h"
#include "graph.h"


TGraph* initGraph(int order) {
    // Alokacja nowego grafu, ...
    TGraph *G = new TGraph;
    // ... z ustawieniem podanego rzedu
    G->order = order;

    // Alias na rzad grafu (ilosc wezlow)
    const int &n = G->order;

    // Alokacja macierzy sasiedztwa (2-wym. tablicy), tj. ...
    // najpierw tablica wskaznikow na wiersze, ...
    G->adjMatrix = new int*[n];
    // ... nastepnie alokacja wierszy, z wyzerowaniem ich zawartosci
    for (int i = 0; i < n; i++)
        G->adjMatrix[i] = _clearArray(new int[n], n);

    // Wyczyszczenie wskaznikow na niezainicjowane jeszcze struktury podrzedne
    G->nodes = NULL;
    G->edges = NULL;
    G->profile = NULL;

    // Zwrocenie wskaznika na zainicjowany graf
    return G;
}


//--- Deklaracje funkcji prywatnych zdefiniowanych dalej w tym pliku
//    (dlatego celowo sa poza plikiem naglowkowym)

int countEdges(TGraph *G);

void createNodeList(TGraph *G);
void createAdjList(TGraph *G);
void createProfile(TGraph *G);
void createEdgeList(TGraph *G, int e);

void deleteEdgeList(TGraph *G, int e);
void deleteProfile(TGraph *G);
void deleteAdjList(TGraph *G);
void deleteNodeList(TGraph *G);

//---


void killGraph(TGraph* &G) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (G == NULL)
        return;

    // Alias na rzad grafu (ilosc wezlow)
    const int &n = G->order;

    // Skasowanie macierzy sasiedztwa (2-wym. tablicy), tj. ...
    for (int i = 0; i < n; i++) {
        // ... najpierw skasowanie wierszy, ...
        delete[] G->adjMatrix[i];
        G->adjMatrix[i] = NULL;
    }
    // ... nastepnie skasowanie tablicy wskaznikow na wiersze
    delete[] G->adjMatrix;
    G->adjMatrix = NULL;

    // Skasowanie struktur podrzednych
    deleteEdgeList(G, countEdges(G));
    deleteProfile(G);
    deleteAdjList(G);
    deleteNodeList(G);

    // Skasowanie grafu i zwrocenie przez parametr wyzerowanego wskaznika
    delete G;
    G = NULL;
}


void buildModel(TGraph *G) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (G == NULL)
        return;

    // Utworzenie struktur podrzednych w oparciu o zadana macierz sasiedztwa
    createNodeList(G);
    createAdjList(G);
    createProfile(G);
    createEdgeList(G, countEdges(G));
}


void createNodeList(TGraph *G) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (G == NULL)
        return;

    // Alias na rzad grafu
    const int &n = G->order;

    // Alokacja listy wezlow (tj. tablicy wskaznikow na wezly)
    G->nodes = new TNode*[n];

    // Wypelnienie listy wezlow, tzn. dla kazdego wezla grafu ...
    for (int i = 0; i < n; i++) {
        // ... alokacja struktury wezla, ...
        TNode *node = new TNode;
        // ... wyzerowanie jej pol ...
        node->Id = i;
        node->name = "";
        node->degree = 0;
        // ... i zapisanie jej wskaznika na liscie wezlow
        G->nodes[i] = node;
    }
}


int _createAdjTuple(int *V, int n, int* &T) {
    // Alokacja tablicy roboczej
    int *A = new int[n];

    // Dla podanego wektora sasiedztwa V ...
    // Wyszukanie w podanym wektorze sasiedztwa V indeksow wezlow sasiednich
    // (tj. indeksow niezerowych elementow) oraz zliczenie ich ...
    int d = _findValues(V, n, A);
    // ... alokacja tablicy T (tj. nowego wiersza do listy sasiedztwa)
    // o dlugosci dostosowanej do zliczonej ilosci wezlow sasiednich ...
    T = new int[d];
    // ... i skopiowanie do niej indeksow znalezionych wezlow sasiednich
    _copyValues(A, d, T);

    // Skasowanie tablicy roboczej
    delete[] A;

    // Zwrocenie ilosci znalezionych wezlow sasiednich (tzn. stopnia wezla)
    return d;
}


void createAdjList(TGraph *G) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (G == NULL)
        return;

    // Alias na rzad grafu (ilosc wezlow)
    const int &n = G->order;

    // Alokacja listy sasiedztwa (2-wym. tablicy), tj.
    // najpierw tablica wskaznikow na wiersze, ...
    G->adjList = new int*[n];
    // ... nastepnie alokacja wierszy, z utworzeniemm ich zawartosci ...
    for (int i = 0; i < n; i++) {
        int d = _createAdjTuple(G->adjMatrix[i], n, G->adjList[i]);
        // ... i zapamietywaniem ich dlugosci (w strukturze wezla)
        G->nodes[i]->degree = d;
    }
}


int countEdges(TGraph *G) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (G == NULL)
        return -1;

    // Alias na rzad grafu (ilosc wezlow)
    const int &n = G->order;

    int e = 0;
    // Przejscie przez wszystkie wezly grafu ...
    for (int i = 0; i < n; i++) {
        // ... aby w oparciu o stopien wezla ustalic liczbe wszystkich krawedzi
        e += G->nodes[i]->degree;
    }
    // Zwroc liczbe krawedzi w grafie
    return e;
}


void createProfile(TGraph *G) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (G == NULL)
        return;

    // Alias na rzad grafu (ilosc wezlow)
    const int &n = G->order;

    // Alokacja tablicy charakterystyki grafu (z wyzerowaniem jej zawartosci)
    G->profile = _clearArray(new int[6], 6);

    // Dla kazdego wezla grafu ...
    for (int i = 0; i < n; i++) {
        // ... ustalenie stopnia wezla, aby ...
        int d = G->nodes[i]->degree;
        if (d > 0)
            // ... dla wszystkich wezlow sasiadujacych z tym wezlem ...
            for (int a = 0; a < d; a++) {
                // ... ustalic indeks wezla sasiedniego, ...
                int j = G->adjList[i][a];
                // ... wage krawedzi laczacej/ych wezel biezacy z sasiednim ...
                int iForth = G->adjMatrix[i][j];
                int iBack  = G->adjMatrix[j][i];
                if (iBack == iForth && (i > j))
                    // (wykluczyc podwojna analize krawedzi nieskierowanych)
                    continue;
                // ... i utworzyc nastepujace podsumowanie:
                // Adn. 1), 2), 3)
                G->profile[gpDirected] += (iForth != iBack);
                G->profile[gpWeighted] += (iForth > 1);
                G->profile[gpEdges]++;
            }
        else
            G->profile[gpIsolated]++;
    }
    G->profile[gpNodes] = n;
    // Adn. 4)
    if ((G->profile[gpIsolated] == 0)
     && (G->profile[gpDirected] == 0))
         G->profile[gpCycles] = 1+ G->profile[gpEdges] -n;
    else G->profile[gpCycles] = -1;

// ZASADY PRZYJETE W ANALIZIE CECH GRAFU:
// 1) Jesli dla jakiejkolwiek pary wezlow dlugosc laczacej je krawedzi zalezy
//    od kierunku przejscia - jest to graf skierowany;
// 2) Jesli jakakolwiek krawedz ma dlugosc wieksza od 1 - jest to graf wazony;
// 3) Jesli dana pare wezlow laczy krawedz nieskierowana zliczana jest 1 raz;
// 4) Jesli graf jest spojny i nieskierowany latwo wyliczyc w nim ilosc cykli
//    C = E - N + 1;
}


void createEdgeList(TGraph *G, int e) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (G == NULL)
        return;

    // Alias na rzad grafu (ilosc wezlow)
    const int &n = G->order;

    // Alokacja listy krawedzi (tj. tablicy wskaznikow na krawedzie)
    G->edges = new TEdge*[e];

    // Dla kazdego wezla grafu ...
    for (int i = e = 0; i < n; i++) {
        // ... ustalenie stopnia wezla, aby ...
        int d = G->nodes[i]->degree;
        // ... dla wszystkich wezlow sasiadujacych z tym wezlem ...
        for (int a = 0; a < d; a++) {
            // ... ustalic indeks wezla sasiedniego ...
            int j = G->adjList[i][a];
            // ... i dla danej pary wezlow utworzyc krawedz, w tym: ...
            // ... alokacja struktury krawedzi ...
            TEdge *edge = new TEdge;
            // ... ustawienie jej pol ...
            edge->startId = i;
            edge->stopId = j;
            edge->weight = G->adjMatrix[i][j];
            // ... i zapisanie jej wskaznika na liscie krawedzi grafu
            G->edges[e++] = edge;
        }
    }
}


void deleteEdgeList(TGraph *G, int e) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (G == NULL)
        return;

    // Skasowanie listy krawedzi, tj. ...
    for (int i = 0; i < e; i++) {
        // ... najpierw skasowanie struktur, ...
        delete G->edges[i];
        G->edges[i] = NULL;
    }
    // ... nastepnie skasowanie tablicy wskaznikow na krawedzie
    delete G->edges;
    G->edges = NULL;
}


void deleteProfile(TGraph *G) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (G == NULL)
        return;

    // Skasowanie tablicy charakterystyki grafu
    delete[] G->profile;
    G->profile = NULL;
}


void deleteAdjList(TGraph *G) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (G == NULL)
        return;

    // Alias na rzad grafu (ilosc wezlow)
    const int &n = G->order;

    // Skasowanie listy sasiedztwa (2-wym. tablicy), tj. ...
    for (int i = 0; i < n; i++) {
        // ... najpierw skasowanie wierszy, ...
        delete[] G->adjList[i];
        G->adjList[i] = NULL;
    }
    // ... nastepnie skasowanie tablic wskaznikow na wiersze
    delete G->adjList;
    G->adjList = NULL;
}


void deleteNodeList(TGraph *G) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (G == NULL)
        return;

    // Alias na rzad grafu (ilosc wezlow)
    const int &n = G->order;

    // Skasowanie listy wezlow, tj. ...
    for (int i = 0; i < n; i++) {
        // ... najpierw skasowanie struktur, ...
        delete G->nodes[i];
        G->nodes[i] = NULL;
    }
    // ... nastepnie skasowanie tablicy wskaznikow na wezly
    delete G->nodes;
    G->nodes = NULL;
}
