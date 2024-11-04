/* ----------------------------------------------------------------------------

  Tablice - funkcje elementarne

  UWAGI:
  - zaklada sie, ze tablice przekazawane w parametrze wywolania sa tablicami
    statycznymi lub tablicami alokowanymi dynamicznie, dla ktorych zostal
    juz przydzielony obszar pamieci o odpowiednim rozmiarze;
  - funkcje nie wykonuja sprawdzania poprawnosci przekazanych parametrow;

  Autor:  Artur Cyrwus                                    Data:  01-06-2021 r.

---------------------------------------------------------------------------- */


int* _clearArray(int A[], int n) {
    // Wyzerowanie wszystkich elementow tablicy A
    for (int i = 0; i < n; i++)
        A[i] = 0;
    // Zwrocenie tej tablicy
    return A;
}

int _countValues(int V[], int n) {
    int c = 0;
    // Zliczenie ilosci wystapien niezerowych wartosci w tablicy V
    for (int i = 0; i < n; i++)
        if (V[i] != 0)
            c++;
    // Zwrocenie licznika wartosci niezerowych
    return c;
}

int _trimValues(int V[], int n) {
    int c = 0;
    // Sciecie do jedynki wszystkich niezerowych wartosci w tablicy V
    for (int i = 0; i < n; i++)
        if (V[i] != 0)
            V[i] = 1;
    // Zwrocenie licznika wartosci niezerowych
    return c;
}

int _findValues(int V[], int n, int F[]) {
    int c = 0;
    // Zwrocenie do tablicy F indeksow wszystkich niezerowych wartosci w tablicy V
    for (int i = 0; i < n; i++)
        if (V[i] != 0)
            F[c++] = i;
    // Zwrocenie licznika wartosci niezerowych
    return c;
}

int* _copyValues(int V[], int n, int C[]) {
    // Skopiowanie do tablicy C zawartosci tablicy V
    for (int i = 0; i < n; i++)
        C[i] = V[i];
    // Zwrocenie tej tablicy
    return C;
}
