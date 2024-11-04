#ifndef AC_BOOK_H
#define AC_BOOK_H

#include <string>
#include <fstream>

using namespace std;


/*
  Struktura "Strona danych zrodlowych"
  size   - rozmiar strony (dopuszczalna ilosc slow przyjeto domyslnie na 4096)
  count  - licznik slow zapisanych na stronie
  words  - tablica przechowujaca wczytane slowa
  next   - wskaznik na nastepna strone (nastepny element listy jednokierunkowej)
*/
struct TPage {
    int size;
    int count;
    string *words;
    TPage *next;
};

/*
  Struktura "Ksiazka danych zrodlowych"
  Strona i ksiazka sa tozsame, bo ksiazka to jednokierunkowa lista stron
*/
typedef TPage TBook;


TBook* initBook(int size = 4096);
void clearBook(TBook *B);
void killBook(TBook* &B);

int loadWords(TBook *B, ifstream *fsInput);
int dumpWords(TBook *B);
int countWords(TBook *B);
int countPages(TBook *B);


#endif // AC_BOOK_H
