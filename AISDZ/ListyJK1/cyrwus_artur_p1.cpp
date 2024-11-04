/* ----------------------------------------------------------------------------

   Przedmiot:  639B-ETxxx-IEP-AISDZ (Algorytmy i Struktury Danych - 2021L)

   Temat P1:   Listy jednokierunkowe

   Program wczytuje z klawiatury dane o figurach geometrycznych do n kolejnych
   rekordow laczac je w jednokierunkowa liste oraz drukuje na ekranie elementy
   utworzonej listy. Nastepnie program usuwa z listy druga w kolejnosci figure,
   dla ktorej liczba bokow jest wieksza od figury poprzedniej, (o ile znajdzie
   taki przypadek), a potem wczytuje z klawiatury dane o kolejnej figurze oraz
   dopisuje nowo wczytany rekord na drugiej pozycji listy. Po zakonczeniu tych
   operacji program ponownie drukuje na ekranie liste.
   Na koniec cala lista zostaje skasowana, po czym raz jeszcze wykonywane jest
   polecenie wydruku listy.

   Autor:  Artur Cyrwus                                   Data:  05-05-2021 r.

----------------------------------------------------------------------------- */

#include <iostream>
#include <iomanip>
#include <string>

using namespace std;


// Element listy jednokierunkowej z polami danych o figurze geometrycznej
struct TFigure {
    TFigure *next;
    string name;
    int sides;
    double area;
};

// Ilosc rekordow (figur geometrycznych) do wprowadzenia
const int n = 5;


/*-----------------------------------------------------------------------------
  Wczytuje z klawiatury dane o figurze geometrycznej (bez testow poprawnosci
  tych danych) i zapisuje je w podanym rekordzie wynikowym typu TFigure.
  Rekordy tego typu moga tworzyc listy jednokierunkowe.
/---
  Argumenty:
    item  - wskaznik na rekord typu TFigure, do ktorego maja byc wpisane dane
/---
  Zwracana wartosc:  wskaznik na rekord wynikowy
*/
TFigure* readItem(TFigure *item) {
    // Wprowadzenie danych o figurze geometrycznej, tj. ...
    // ... nazwa figury
    cout << "- nazwa: ";
    cin >> item->name;
    // ... liczba bokow
    cout << "- liczba bokow: k = ";
    cin >> item->sides;
    // ... pole powierzchni
    cout << "- pole powierzchni: A = ";
    cin >> item->area;

    // Zwrocenie adresu rekordu wynikowego
    return item;
}


/*-----------------------------------------------------------------------------
  Drukuje na ekranie (w postaci tabulogramu) dane z rekordow tworzacych liste
  jednokierunkowa, poczawszy od podanego elementu bazowego, az do ostatniego
  elementu listy.
/---
  Argumenty:
    base   - wskaznik na rekord typu TFigure, jednoczesnie pierwszy element
             jednokierunkowej listy przeznaczonej do wydruku
*/
void printList(TFigure *base) {
    // Wydruk naglowka tabulogramu
    cout << "-----------------------------------------------\n";
    cout << " nazwa figury       l.bokow      p.powierzchni \n";
    cout << "-----------------------------------------------\n";
    cout << setprecision(4);
    // Dla wszystkich elementow dostepnych na liscie, ...
    for (TFigure *item = base; item != NULL; item = item->next) {
        // ... drukowanie sformatowanej zawartosci pol rekordow
        cout << " ";
        cout << setw(18) << left  << item->name;
        cout << setw(5)  << right << item->sides;
        cout << setw(22) << fixed << item->area;
        cout << endl;
    }
    cout << "-----------------------------------------------\n";
}


/*-----------------------------------------------------------------------------
  Usuwa podany rekord typu TFigure oraz wszystkie powiazane z nim elementy
  tworzace jednokierunkowa liste.
/---
  Argumenty:
    base  - referencja wskaznika na rekord typu TFigure, a zarazem pierwszego
            elementu jednokierunkowej listy przeznaczonej do usuniecia
/---
  Zwracana wartosc:  wyzerowany wskaznik na rekord bazowy (przez referencje)
*/
void eraseList(TFigure* &base) {
    // Skopiowanie adresu podanego elementu bazowego
    TFigure *item = base;
    // Poczawszy od elementu bazowego az do ostatniego, ...
    while (item != NULL) {
        // ... skopiowanie adresu elementu (by za chwile usunac go z pamieci)
        //     i ucieczka w element nastepny ...
        TFigure *d = item;  item = item->next;
        // ... usuniece zbednego elementu
        delete d;
    }
    // Wyczyszczenie adresu bazowego
    base = NULL;
}




int main() {
    TFigure *head = NULL;
    TFigure *tail = NULL;

//--- CZESC 1 - Utworzenie zbioru danych o figurach geometrycznych

    // Wypisanie komunikatu z zacheta do wprowadzenia danych
    cout << "*** CZESC 1 ***" << endl;
    cout << "Wprowadz dane o figurach geometrycznych / wielobokach:\n";

    if (n > 0) {
        int i = 1;
        cout << "\nfigura (" << i << " z " << n << ")\n";
        // Wprowadzenie danych dla nowo utworzonego pierwszego elementu
        head = tail = readItem(new TFigure);

        for (++i; i <= n; i++) {
            cout << "\nfigura (" << i << " z " << n << ")\n";
            // Wprowadzenie danych dla nowo utworzonego nastepnego elementu
            // oraz dowiazanie go do listy
            tail = tail->next = readItem(new TFigure);
        }
        // Koniec listy
        tail->next = NULL;
    }
    cout << "Dane wprowadzone.\n";

//--- CZESC 2 - Wydruk listy

    cout << "\n*** CZESC 2 ***" << endl;
    cout << "Lista wprowadzonych figur:\n";
    printList(head);

//--- CZESC 3a - Usuniecie z listy figury spelniajacej zadane kryteria

    cout << "\n*** CZESC 3 ***" << endl;
    cout << "Teraz przeanalizuje wprowadzone figury pod wzgledem ich liczby bokow.\n";
    cout << "Druga w kolejnosci figura, w ktorej liczba bokow jest wieksza niz ";
    cout << "w figurze poprzedniej, zostanie usunieta z listy.\n";

    int c = 0;
    for (TFigure *item = head;  item != NULL && item != tail;  item = item->next) {
        // ... czy warunek wiekszej ilosci bokow w elemencie nastepnym ...
        if (item->sides < item->next->sides)
            // ... jest spelniony po raz drugi
            if (++c == 2) {
                // Jesli tak, to usuniecie elementu nastepnego, ...
                TFigure *d = item->next;
                             item->next = d->next;
                // ... wypisanie komunikatu o usunietej figurze, ...
                cout << "Figura o nazwie " << d->name << " zostala usunieta!\n";
                // ... zwolnienie pamieci zajmowanej przez niepotrzebny juz rekord, ...
                delete d;
                // ... i przerwanie dalszych poszukiwan
                break;
            }
    }
    if (c < 2)
        cout << "Brak figur do usuniecia.\n";

//--- CZESC 3b - Dopisanie nowej figury na drugim miejscu listy

    if (head != NULL) {
        cout << "Teraz wprowadz dane jeszcze jednej figury:\n";

        // Wprowadzenie danych dla nowo utworzonego elementu
        TFigure *item = readItem(new TFigure);
        // Dopisanie elementu na drugim miejscu na liscie
        item->next = head->next;
        head->next = item;

        cout << "Ta figura zostala dodana do listy na drugiej pozycji.\n";
    }
    else
        // Drugie miejsce na liscie jest nieosiagalne (lista jest pusta)
        cout << "Nie mozna dodac nowej figury na drugiej pozycji listy!\n";

//--- CZESC 4 - Wydruk listy

    cout << "\n*** CZESC 4 ***" << endl;
    cout << "Lista figur po wprowadzeniu zmian:\n";
    printList(head);

//--- CZESC 5 - Usuniecie calej listy

    cout << "\n*** CZESC 5 ***" << endl;
    cout << "Skasowanie calej listy.\n";
    eraseList(head);

//--- CZESC 6 - Wydruk listy (pustej)

    cout << "\n*** CZESC 6 ***" << endl;
    cout << "Zawartosc listy po jej skasowaniu:\n";
    printList(head);

    system("pause");
    return 0;
}

/* -------------------------------------------------------------------------- */
