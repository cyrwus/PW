/* ----------------------------------------------------------------------------

  TBook / TPage - strukury "Ksiazka / strona danych zrodlowych"

  UWAGI:
  - ksiazka to jedna lub wiele stron, na ktorych moga byc przechowywane slowa;
  - kazda strona zawiera tablice typu string przeznaczona do zapisywania slow
    (domyslny rozmiar tablicy przyjeto na 4096 elementow);
  - ksiazka moze skladac sie z wielu stron polaczonych w liste jednokierunkowa;
  - nowe slowa dopisywane sa na koncu istniejacego zbioru slow;
  - jesli na biezacej stronie wyczerpalo sie miejsce, nowe slowo dodawane jest
    na automatycznie utworzonej stronie nastepnej;
  - slowa moga byc wprowadzane pojedynczo albo masowo - z otwartego strumienia
    plikowego.

  Autor:  Artur Cyrwus                                    Data:  09-06-2021 r.

---------------------------------------------------------------------------- */

#include <string>
#include <iostream>
#include <fstream>
#include "book.h"

using namespace std;


TPage* initPage(int size) {
    // Alokacja nowej strony (wraz z tablica dynamiczna dla slow), ...
    TPage *page = new TPage;
    page->words = new string[size];
    // ... z wyzerowaniem licznika slow i wskanika na strone nastepna
    page->size = size;
    page->next = NULL;
    page->count = 0;

    // Zwrocenie wskaznika na utworzona strone
    return page;
}


TPage* addPage(TPage *curr, TPage *next) {
    // Dolaczenie za strona biezaca podanej strony nastepnej
    if (curr != NULL) {
        curr->next = next;
    }
    // Zwrocenie wskaznika na strone nastepna
    return next;
}


void clearPage(TPage *curr) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (curr == NULL)
        return;

    // Wyczyszczenie zawartosci tablicy slow na stronie biezacej, ...
    for (int i = 0; i < curr->count; i++)
        curr->words[i] = "";
    // ... z wyzerowaniem licznika slow i wskaznika na strone nastepna
    curr->count = 0;
    curr->next = NULL;
}


void killPage(TPage* &curr) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (curr == NULL)
        return;

    // Przejscie przez wszystkie elementy jednokierunkowej listy, ...
    do {
        TPage *del = curr;
        curr = curr->next;
        // ... w celu ich skasowania wraz z dynamiczna tablica slow
        delete[] del->words;
        delete del;
        del = NULL;
    }
    while (curr != NULL);
    // Zwrocenie przez parametr wyzerowanego wskaznika na skasowana strone
}


TBook* initBook(int size) {
    // Zwrocenie wskaznika na utworzona pierwsza i jedyna strone
    return initPage(size);
}


void clearBook(TBook *B) {
    // Zakonczenie, gdy podany wskaznik jest pusty
    if (B == NULL)
        return;

    // Skasowanie ewentualnych stron nastepnych ...
    if (B->next != NULL)
        killPage(B->next);
    // ... i wyczyszczenie zawartosci podanej strony (pierwszej)
    clearPage(B);
}


void killBook(TBook* &B) {
    // Skasowanie calej ksiazki, ...
    killPage(B);
    // Zwrocenie przez parametr wyzerowanego wskaznika na skasowana ksiazke
}


int addWord(TPage* &curr, string word) {
    // Zakonczenie, gdy podany wskaznik jest pusty*, ...
    if (curr == NULL)
        // ... ze zwroceniem zerowej ilosci dodanych stron
        return 0;

    int p = 0;
    // Sprawdzenie czy na podanej stronie biezacej mozna dopisac slowo, ...
    if (curr->count == curr->size) {
        // ... bo jesli wyczerpalo sie miejsce na biezacej stronie,
        // to utworzenie nowej strony, dodanie jej i przejscie na nia
        curr = addPage(curr, initPage(curr->size));
        p++;
    }
    // Dopisanie slowa na stronie
    curr->words[curr->count++] = word;

    // Zwrocenie wartosci:
    // 0, gdy slowo zapisano na podanej stronie biezacej *lub nie zapisano go!
    // 1, jesli konieczne bylo dodanie nowej strony do zapisania slowa
    return p;
    // Zwrocenie przez parametr wskaznika na podana lub ewentualnie dodana strone
}


int loadWords(TBook *B, ifstream *fsInput) {
    // Zakonczenie, gdy podany wskaznik jest pusty, ...
    if (B == NULL || fsInput == NULL)
        // ... ze zwroceniem zerowej ilosci wczytanych slow
        return 0;

    // Sprawdzenie czy strumien wejsciowy jest otwarty, ...
    if (! fsInput->good())
        // ... jesli nie, zwrocenie zerowej ilosci wczytanych slow
        return 0;

    int p = 0;
    // Dopoki strumien wejsciowy nie wyczerpie sie, ...
    while (! fsInput->eof()) {
        // ... wczytywanie slow ze strumienia ...
        string word;
        *fsInput >> word;
        // ... i dopisywanie ich do ksiazki
        p += addWord(B, word);
    }
    // Korekta licznika slow wczytanych na biezacej/ostatniej stronie ksiazki
    // (bo strumien wejsciowy zwraca pusty napis, gdy przed EOF jest nowa linia)
    if (B->words[B->count -1] == "")
        B->count--;

    // Zwrocenie lacznej ilosci wczytanych slow
    return B->count + (B->size * p);
}


int dumpWords(TBook *B) {
    int w = 0;
    // Przejscie przez wszystkie strony ksiazki, ...
    for (TPage *curr = B;  curr != NULL;  curr = curr->next) {
        // ... z przekazaniem wszystkich slow ...
        for (int i = 0; i < curr->count; i++, w++) {
            // ... do wydrukowania (czynnosc SERWISOWA)
            cout << curr->words[i] << endl;
        }
    }
    // Zwrocenie lacznej ilosci wydrukowanych slow
    return w;
}


int countWords(TBook *B) {
    int w = 0;
    // Przejscie przez wszystkie strony ksiazki, ...
    for (TPage *curr = B;  curr != NULL;  curr = curr->next) {
        // ... z ustaleniem lacznej ilosci wszystkich slow
        w += curr->count;
    }
    // Zwrocenie lacznej ilosci slow
    return w;
}


int countPages(TBook *B) {
    int p = 0;
    // Przejscie przez wszystkie strony ksiazki, ...
    for (TPage *curr = B;  curr != NULL;  curr = curr->next)
        // ... ze zliczeniem jej stron
        p++;
    // Zwrocenie ilosci stron
    return p;
}
