#ifndef AC_ENGINE_GRAPH_H
#define AC_ENGINE_GRAPH_H

#include "common.h"


/*
  Struktura definiujaca wezel (wierzcholek) grafu
  Id        - identyfikator wezla, tzn. indeks wezla na liscie wezlow
  degree    - stopien wezla, tzn. liczba wezlow sasiednich
  name      - nazwa wezla
*/
struct TNode {
    int Id;
    int degree;
    string name;
};


/*
  Struktura definiujaca krawedz grafu
  startId   - indeks wezla poczatkowego
  stopId    - indeks wezla koncowego
  weight    - waga krawedzi
*/
struct TEdge {
    int startId;
    int stopId;
    int weight;
};


/*
  Struktura definiujaca graf
  order     - rzad grafu, liczba wezlow (wierzcholkow) grafu
  adjMatrix - macierz sasiedztwa, tj. 2-wym. n-wierszowa tablica dynamiczna
              (gdzie n jest rzedem grafu), w ktorej okreslono w jaki sposob
              wezely grafu lacza sie ze soba oraz jakie sa wagi laczacych je
              krawedzi
  adjList   - lista sasiedztwa, tj. 2-wym. n-wierszowa tablica dynamiczna
              (gdzie n jest rzedem grafu) przechowujaca dla kazdego wezla
              indeksy wezlow sasiadujacych z nim
  nodes     - lista wezlow, tj. tablica dynamiczna przechowujaca wskazniki
              wszystkich wezlow grafu
  edges     - lista krawedzi, tj. tablica dynamiczna przechowujaca wskazniki
              rozpoznanych krawedzi grafu
  profile   - tablica dynamiczna przechowujaca cechy charakterystyczne grafu,
              np. ilosc cykli, czy jest grafem skierowanym, wazonym, itp.
*/
struct TGraph {
    int order;
    int **adjMatrix;
    int **adjList;
    TNode **nodes;
    TEdge **edges;
    int *profile;
};


/*
  Enumerator do tablicy cech charakterystycznych grafu
  gpNodes    - ilosc wezlow (wierzcholkow)
  gpEdges    - ilosc krawedzi unikalnych (gdzie krawedzie nieskierowane
               liczone sa jeden raz, niezaleznie od kierunku przejscia)
  gpCycles   - ilosc cykli
  gpIsolated - ilosc wezlow bez sasiedztwa (wierzcholkow izolowanych)
  gpDirected - ilosc krawedzi skierowanych (jesli 0, graf nieskierowany)
  gpWeighted - ilosc krawedzi wazonych (jesli > 0, graf wazony)
*/
enum EGraphProfile {
    gpNodes,
    gpEdges,
    gpCycles,
    gpIsolated,
    gpDirected,
    gpWeighted
};


inline TNode* node(TGraph *G, int Id) {
    // Wybor z listy wezlow wskaznika na wezel o podanym Id
    // i zwrocenie tego wskaznika
    return G->nodes[Id];
}

inline int nodeDegree(TGraph *G, int Id) {
    // Wybor z listy wezlow wskaznika na wezel o podanym Id
    // i zwrocenie stopnia tego wezla
    return G->nodes[Id]->degree;
}

inline string nodeName(TGraph *G, int Id) {
    // Wybor z listy wezlow wskaznika na wezel o podanym Id
    // i zwrocenie nazwy tego wezla
    return G->nodes[Id]->name;
}

inline void nodeName(TGraph *G, int Id, string name) {
    // Wybor z listy wezlow wskaznika na wezel o podanym Id
    // i zapisanie podanej nazwy tego wezla
    G->nodes[Id]->name = name;
}

inline TNode* nodeNeighbour(TGraph *G, int Id, int a) {
    // Pobranie z listy sasiedztwa (tj. z odpowiedniej krotki, zwiazanej
    // z wezlem o podanym Id) indeksu a-tego wezla sasiedniego, ...
    int iAdj = G->adjList[Id][a];
    // ... wybor z listy wezlow wskaznika na wezel o takim indeksie
    // i zwrocenie tego wskaznika
    return G->nodes[iAdj];
}

inline int edgeWeight(TGraph *G, int startId, int stopId) {
    // Pobranie z macierzy sasiedztwa (tj. z odpowiedniego wektora,
    // zwiazanego z wezlem poczatkowym o podanym Id) "wagi" krawedzi
    // laczacej wezel poczatkowy i koncowy oraz zwrocenie tej wartosci
    return G->adjMatrix[startId][stopId];
}


TGraph* initGraph(int order);
void killGraph(TGraph* &G);

void buildModel(TGraph *G);
int countEdges(TGraph *G);


#endif // AC_ENGINE_GRAPH_H
