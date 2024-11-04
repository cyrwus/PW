/* ----------------------------------------------------------------------------

   Przedmiot:  639B-ETxxx-IEP-AISDZ (Algorytmy i Struktury Danych - 2021L)

   Temat P0:   Tablice statyczne i dynamiczne
               Funkcje iteracyjne i rekurencyjne

   Program, w zaleznosci od wyboru uzytkownika, realizuje jeden z trzech nizej
   podanych wariantow tworzenia i wypelniania jednowymiarowej tablicy rekordow
   o polach typu {char, int}:
   (1) do zwyklej tablicy statycznej A[n] o rozmiarze okreslonym przez stala n
       wpisywane sa odpowiednie wartosci losowe w petli iteracyjnej;
   (2) do zwyklej tablicy statycznej B[n] o rozmiarze okreslonym przez stala n
       wpisywane sa odpowiednie wartosci losowe w petli rekurencyjnej;
   (3) do tablicy dynamicznej D[k], ktorej rozmiar zostaje okreslony zmienna k
       wpisywane sa odpowiednie wartosci losowe w petli iteracyjnej.
   W kazdym z ww. przypadkow, do pol typu char zostana wpisane losowe literki
   duze od 'A' do 'Z', a do pol typu int -- losowe liczby z zakresu od 0 do G.
   Na koniec, program drukuje na ekranie 20 ostatnich rekordow z tablicy oraz
   rozmiar tablicy i wielkosc zajmowanej przez nia pamieci.

   Autor:  Artur Cyrwus                                   Data:  26-04-2021 r.

----------------------------------------------------------------------------- */

#include <iostream>
#include <iomanip>
#include <time.h>

using namespace std;


// Modelowy rekord o polach typu {char, int}
struct TProduct {
    char Category;
    int Quantity;
};

// Stala parametryczna dla wielkosci losowych
const int G = 80;

// Przyjety rozmiar tablic statycznych  ( A-max: 129136,  B-max: 129136 )
const int n = 1024;


/*-----------------------------------------------------------------------------
  Ustawia i zwraca rekord typu TProduct w taki sposob, ze w polu Category
  wpisywana jest losowa litera z zakresu od 'A' do 'Z', a w polu Quantity
  liczba losowa z zakresu od 0 do G (stala).
/---
  Uwaga: Przed stosowaniem tej funkcji zainicjowac generator liczb losowych!
*/
TProduct randProduct() {
    TProduct p;
    // Zainicjowanie rekordu nowymi wartosciami losowymi,
    // spelniajacymi zadane kryteria
    p.Category = 'A' + rand() % 26;
    p.Quantity =  0 + rand() % (1+ G);
    // Zwrocenie zawartosci
    return p;
}


/*-----------------------------------------------------------------------------
  Ustawia w rekordzie przekazanym przez referencje dane z rekordu zrodlowego.
/---
  Argumenty:
    p      - referencja rekordu wynikowego typu TProduct
    source - zrodlowy rekord typu TProduct
*/
void setItem(TProduct &p, TProduct source) {
    // Przepisanie danych z rekordu zrodlowego
    p = source;
}


/*-----------------------------------------------------------------------------
  Drukuje na standardowym urzadzeniu wyjsciowym dane z podanego rekordu.
/---
  Argumenty:
    p      - przeznaczony do wydruku rekord typu TProduct
*/
void printItem(TProduct p) {
    // Wypisanie sformatowanej zawartosci rekordu na ekranie
    cout << "( ";
    cout << p.Category << "," << setw(3) << p.Quantity;
    cout << " )";
}


/*-----------------------------------------------------------------------------
  Wypelnia cala lub czesc podanej tablicy typu TProduct rekordami zawierajacymi
  dane losowe. Ustawianie zawartosci rekordow odbywa sie w petli iteracyjnej,
  poczawszy od rekordu o zadanym indeksie iStart do rekordu o indeksie iEnd.
/---
  Argumenty:
    P      - tablica rekordow typu TProduct
    iStart - indeks poczatkowy (domyslnie 0)
    iEnd   - indeks koncowy (domyslnie n -1, gdzie n = ilosc elementow tablicy)
*/
void fillArray(TProduct P[], int iStart = 0, int iEnd = n -1) {
    // Jesli zakres okreslono poprawnie, ...
    if ((0 <= iStart) && (iStart <= iEnd))
        // ... to w petli iteracyjnej (domyslnie od poczatku do konca tablicy)
        for (int i = iStart; i <= iEnd; i++)
            // ... wpisanie danych losowych
            setItem(P[i], randProduct());
}


/*-----------------------------------------------------------------------------
  Wypelnia ciagly obszar (tablice statyczna) zlozony z rekordow typu TProduct
  danymi losowymi. Zawartosc rekordow ustawiana jest w petli rekurencyjnej,
  w zakresie wyznaczonym przez zadane rekordy skrajne pLeft i pRight.
  (np. element z poczatku i z konca tablicy)
/---
  Argumenty:
    pLeft  - referencja rekordu poczatkowego (z nizszym indeksem w tablicy)
    pRight - referecja rekordu koncowego (z wyzszym indeksem w tablicy)
*/
void fillArray(TProduct &pLeft, TProduct &pRight) {
    // Wpisanie danych losowych, ...
    setItem(pLeft, randProduct());
    setItem(pRight, randProduct());
    // ... w petli rekurencyjnej postepujacej obustronnie ku srodkowi tablicy
    if (&pLeft < &pRight)
        fillArray(*(&pLeft +1), *(&pRight -1));

    // ALGORYTM:
    // W kazdym kolejnym wywolaniu, funkcja operuje na parze zadanych rekordow
    // (przekazanych przez referencje), przy czym proces rozpoczyna sie od pary
    // przeciwleglych elementow na skraju zadanego obszaru, zmierzajac ku jego
    // srodkowi i konczy sie wraz z osiagnieciem pary elementow zlokalizowanych
    // na srodku tego obszaru.
}


/*-----------------------------------------------------------------------------
  Drukuje na standardowym urzadzeniu wyjsciowym dane z podanej tablicy.
  Drukowanie elementow tablicy odbywa sie w petli iteracyjnej, poczawszy
  od elementu o zadanym indeksie iStart do elementu o indeksie iEnd.
/---
  Argumenty:
    P      - tablica rekordow typu TProduct przeznaczona do wydruku
    iStart - indeks poczatkowy (domyslnie 0)
    iEnd   - indeks koncowy (domyslnie n -1, gdzie n = ilosc elementow tablicy)
*/
void printArray(TProduct P[], int iStart = 0, int iEnd = n -1) {
    // Jesli zakres okreslono poprawnie, ...
    if ((0 <= iStart) && (iStart <= iEnd))
        // ... to dla zadanego zakresu tablicy ...
        for (int i = iStart; i <= iEnd; i++) {
            // ... wypisanie na ekranie indeksow i zawartosci rekordow
            cout << setw(6) << i << ": ";  printItem(P[i]);
            cout << endl;
        }
}




int main() {
    // Tablice statyczne
    TProduct A[n];
    TProduct B[n];

    // Wskaznik tablicy dynamicznej
    TProduct* D;

    // Zainicjowanie generatora liczb losowych
    srand(time(NULL));

    // Wypisanie informacji o programie ...
    cout << "Program losuje rekordy i umieszcza je w jednowymiarowej tablicy.\n";
    cout << endl;
    // ... oraz dostepnych opcjach
    cout << "Okresl rodzaj tablicy oraz sposob jej wypelniania:\n";
    cout << " [A] - tablica statyczna z zapisem danych w petli iteracyjnej\n";
    cout << " [B] - tablica statyczna z zapisem danych w petli rekurencyjnej\n";
    cout << " [D] - tablica dynamiczna z zapisem danych w petli iteracyjnej\n";
    cout << endl;

    int k;
    char cKey;
    do {
        // INTERAKCJA: Wybor opcji
        cout << "Wcisnij i zatwierdz klawisz [A/B/D]: ";
        cin >> cKey;

        // Realizacja wybranego wariantu tworzenia i wypelniania tablicy
        switch (cKey) {
            // Wariant A
            case 'a': cKey = 'A';
            case 'A': cout << "\nWybrano tablice statyczna A";

                      // Wypelnienie tablicy A iteracyjnie
                      cout << "\nWypelnianie tablicy metoda iteracyjna ... ";
                      fillArray(A);
                      cout << "gotowe!\n";
                      // Wydrukowanie ostatnich rekordow
                      cout << "\nOstatnie 20 rekordow z tablicy A:\n";
                      printArray(A, n -20);

                      k = n;
                      break;

            // Wariant B
            case 'b': cKey = 'B';
            case 'B': cout << "\nWybrano tablice statyczna B";

                      // Wypelnienie tablicy B
                      cout << "\nWypelnianie tablicy metoda rekurencyjna ... ";
                      fillArray(B[0], B[n -1]);
                      cout << "gotowe!\n";
                      // Wydrukowanie ostatnich rekordow
                      cout << "\nOstatnie 20 rekordow z tablicy B:\n";
                      printArray(B, n -20);

                      k = n;
                      break;

            // Wariant D
            case 'd': cKey = 'D';
            case 'D': cout << "\nWybrano utworzenie tablicy dynamicznej D";
                      cout << "\nPodaj ilosc rekordow (20 <= k <= 2147483648) ";
                      // INTERAKCJA: Okreslenie rozmiaru tablicy dynamicznej
                      while (k < 20) {
                          cout << "k = ";
                          cin >> k;
                      }
                      // Alokacja tablicy w pamieci
                      D = new TProduct[k];

                      // Wypelnienie tablicy D iteracyjnie
                      cout << "\nWypelnianie tablicy metoda iteracyjna ... ";
                      fillArray(D, 0, k -1);
                      cout << "gotowe!\n";
                      // Wydrukowanie ostatnich rekordow
                      cout << "\nOstatnie 20 rekordow z tablicy D:\n";
                      printArray(D, k -20, k -1);

                      // Usuniecie tablicy z pamieci
                      delete[] D;
                      break;

            // Bledny wybor (nieznany klawisz)
            default : cKey = '?';
        }
    } while (cKey == '?');

    // Wydrukowanie informacji o wielkosci tablicy
    cout << "\nRozmiar tablicy: " << k << " rekordow ";
    cout << "(" << sizeof(TProduct) * k << " bajtow)\n";

    system("pause");
    return 0;
}

/* -------------------------------------------------------------------------- */
