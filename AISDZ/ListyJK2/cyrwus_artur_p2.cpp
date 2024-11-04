/* ----------------------------------------------------------------------------

  Przedmiot:  639B-ETxxx-IEP-AISDZ (Algorytmy i Struktury Danych - 2021L)

  Temat P2:   Listy jednokierunkowe / algorytmy sortowania

  Z pliku o nazwie podanej przez uzytkownika, program wczytuje dane o figurach
  geometrycznych do kolejnych rekordow umieszczanych na koncu jednokierunkowej
  listy.  Nastepnie, w obrebie jednej rozbudowanej funkcji, program manipuluje
  elementami listy:
   a)  wstawia nowa figure o zadanych danych za co 2-gi rekord, ktorego pole
       powierzchni jest mniejsze od pola drugiej figury na liscie oraz przed
       co n-ty rekord, o polu powierzchni mniejszym od sredniego pola takich
       figur z listy, ktore maja wiecej bokow niz zadano. (Dane nowej figury
       zadana liczba bokow oraz parametr n sa argumentami wywolania funkcji)
   b)  kasuje z listy wszystkie rekordy znajdujace sie przed pierwsza figura
       z mniejsza niz zadana liczba bokow, w ich miejsce wstawia nowa figure
       o zadanej nazwie, a polu powierzchni i liczbie bokow wyliczonych jako
       mediany z odpowiednich wartosci w rekordach skasowanych.
   c)  po kazdej z ww. operacji drukuje z zadanym naglowkiem zawartosc listy
       za pomoca odrebnej funkcji.
  Na koniec cala lista zostaje skasowana z pamieci.

  Autor:  Artur Cyrwus                                    Data:  12-05-2021 r.

----------------------------------------------------------------------------- */

#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>

using namespace std;


struct TFigure {
    TFigure *next;
    string name;
    int sides;
    double area;
};


/*-----------------------------------------------------------------------------
  Tworzy nowy rekord i zapisuje w jego polach dane o figurze geometrycznej.
/---
  Argumenty:
    name   - nazwa figury     |
    sides  - liczba bokow     | dane figury geometrycznej
    area   - pole powierzchni |
/---
  Zwracana wartosc:  wskaznik na zainicjowany danymi rekord typu TFigure
*/
TFigure* newItem(string name, int sides, double area) {
    // Utworzenie nowego rekordu w pamieci, ...
    TFigure *item = new TFigure();
    // ... zasilenie pol rekordu danymi ...
    item->name = name;
    item->sides = sides;
    item->area = area;
    // ... i ustawienie terminatora
    item->next = NULL;

    // Zwrocenie zainicjowanego rekordu
    return item;
}


/*-----------------------------------------------------------------------------
  Tworzy i dolacza na koncu listy rozpoczynajacej sie pod zadanym adresem
  nowy rekord z danymi o figurze geometrycznej.
/---
  Argumenty:
    list   - adres pusty lub wskaznik na rekord typu TFigure, bedacy pierwszym
             elementem listy, do ktorej zostanie dolaczony nowy element
    name   - nazwa figury     |
    sides  - liczba bokow     | dane nowej figury geometrycznej
    area   - pole powierzchni |
*/
void addItem(TFigure *list, string name, int sides, double area) {
    // O ile podana lista jest niepusta, ...
    if (list != NULL) {
        // ... przejscie do ostatniego niepustego elementu listy ...
        while (list->next != NULL)
            list = list->next;
        // ... i dolaczenie na koncu listy nowego zainicjowanego rekordu
        list->next = newItem(name, sides, area);
    }
}


/*-----------------------------------------------------------------------------
  Drukuje na ekranie (w postaci tabulogramu) dane z rekordow tworzacych liste
  jednokierunkowa, poczawszy od podanego elementu az do konca listy.
  Na koncu umieszcza informacje o liczbie wydrukowanych rekordow.
/---
  Argumenty:
    list   - wskaznik na rekord typu TFigure, jednoczesnie pierwszy element
             jednokierunkowej listy przeznaczonej do wydruku
*/
void printList(TFigure *list) {
    // Wydruk naglowka tabulogramu
    cout << "-----------------------------------------------\n";
    cout << " nazwa figury        ilosc            pole     \n";
    cout << " geometrycznej       bokow         powierzchni \n";
    cout << "-----------------------------------------------\n";
    cout << setprecision(4);
    int c = 0;
    // Dla wszystkich elementow dostepnych na liscie, ...
    for (TFigure *item = list; item != NULL; item = item->next, c++) {
        // ... drukowanie sformatowanej zawartosci pol rekordow
        cout << " ";
        cout << setw(18) << left  << item->name;
        cout << setw(5)  << right << item->sides;
        cout << setw(22) << fixed << item->area;
        cout << endl;
    }
    cout << "-----------------------------------------------\n";
    // Podsumowanie liczby wydrukowanych elementow
    cout << c << " rekordow\n";
}




/*-----------------------------------------------------------------------------
  Manipuluje elementami zadanej listy wg przepisu podanego w preambule.
/---
  Argumenty:
    list   - adres pusty lub wskaznik na rekord typu TFigure, jednoczesnie
             pierwszy element listy jednokierunkowej
    n      - co ktore wystapienie figury jest istotne
    s      - istotna liczba bokow figury
    name   - nazwa figury     |
    sides  - liczba bokow     | dane dla nowej figury geometrycznej
    area   - pole powierzchni |
    title  - napis drukowany jako tytul/naglowek listy elementow
/---
  Zwracana wartosc (przez referencje):
    list   - wskaznik na zmodyfikowana liste rekordow typu TFigure
*/
int muddleList(TFigure* &list, int n, int s,
               string name, int sides, double area,
               string title)
{
    // Walidacja parametru n
    if (n < 1) {
        cout << "Niedozwolona wartosc parametru n.\n";
        return -1;
    }

    // *** CZESC 2.A ***
    // Wstawianie nowej figury o zadanych danych:
    // (1)  za co 2-gi rekord spelniajacy warunek taki, ze:
    //     "pole powierzchni jest mniejsze od pola drugiej figury na liscie"
    // (2)  przed co n-ty rekord spelniajacy warunek taki, ze:
    //     "pole powierzchni jest mniejsze od sredniego pola takich figur
    //      z listy, ktore maja wiecej bokow niz zadano"

    TFigure *prev = NULL;
    TFigure *curr = list;

    // Sprawdzenie czy druga (niezbedna) figura na liscie jest osiagalna, ...
    if (curr->next == NULL) {
        // ... jesli nie - zakonczenie pracy
        cout << "Za malo figur by ukonczyc zadanie.\n";
        return -1;
    }

    // 2.A.1 --- Wyliczenie/ustalenie niezbednych pol powierzchni

    int iCount = 0;
    double dArea = 0.0;
    // Tak dlugo jak biezacy element listy jest niepusty, ...
    while (curr != NULL) {
        // ... sprawdzanie czy figura ma wiecej bokow niz zadano ...
        if (curr->sides > s) {
            // ... a jesli tak, sumowanie pola oraz zliczanie wystapienia ...
            dArea += curr->area;
            iCount++;
        }
        // ... i przejscie do nastepnego elementu
        curr = curr->next;
    }
    curr = list;
    // Wyliczenie wartosci sredniej (lub wpisanie, gdy nie ma co liczyc)
    double dAvgArea;
    if (iCount > 1)
        dAvgArea = dArea / iCount;
    else dAvgArea = dArea;
    cout << "Srednie pole powierzchni tych figur: " << dAvgArea << endl;

    // Ustalenie pola powierzchni drugiej figury na liscie
    dArea = curr->next->area;

    // 2.A.2 --- Wstawianie nowych elementow w odpowiednich miejscach listy

    int iCC1 = 0;
    int iCC2 = 0;
    // Sprawdzenie czy juz pierwszy rekord spelnia warunek (2) ...
    if ((curr->area < dAvgArea) && (++iCC2 % n == 0)) {
        // ... jesli tak, to zliczenie tego przypadku, a przy n = 1
        //     utworzenie nowego zainicjowanego elementu ...
        TFigure *item = newItem(name, sides, area);
        // ... wstawienie go przed zadana lista ...
        item->next = curr;
        // ... i przestawienie glowy listy!
        list = item;
    }
    // Jesli pierwszy rekord spelnia warunek (1), ...
    if (curr->area < dArea)
        // ... zliczenie tego przypadku
        ++iCC1;
    // Inkrementacja wskaznikow roboczych
    prev = curr;
    curr = curr->next;
    // OBJASNIENIE
    // Pierwszy element zadanej listy zostal w pelni obsluzony, a wskazniki robocze
    // zostaly ustawione na elementy 1 i 2. Generalna zasada jest taka, by wskaznik
    // biezacy curr adresowal wylacznie rekordy oryginalne i pomijal rekordy dodane.
    // Taka idea wyklucza utkniecie przed jakims rekordem oryginalnym, ktory spelnia
    // warunek wstawiania przed nim nowej figury, a przy n = 1 odbywa sie to w petli
    // nieskonczonej!

    // Tak dlugo jak biezacy element listy jest niepusty, ...
    while (curr != NULL) {
        // ... sprawdzanie czy spelnia on warunek (2) ...
        if ((curr->area < dAvgArea) && (++iCC2 % n == 0)) {
            // ... jesli tak, to zliczenie tego przypadku, a gdy jest n-tym, ...
            //     utworzenie nowego zainicjowanego elementu ...
            TFigure *item = newItem(name, sides, area);
            // ... wstawienie go przed biezacym elementem (a za poprzednim) ...
            item->next = curr;
            prev->next = item;
        }
        prev = curr;
        // ... sprawdzanie czy spelnia on warunek (1) ...
        if ((curr->area < dArea) && (++iCC1 % 2 == 0)) {
            // ... jesli tak, to zliczenie tego przypadku, a gdy jest 2-gim, ...
            //     utworzenie nowego zainicjowanego elementu ...
            TFigure *item = newItem(name, sides, area);
            // ... wstawienie go przed nastepnym (a za biezacym) elementem ...
            item->next = curr->next;
            curr->next = item;
            // ... wskazniki w polkroku ...
            curr = prev = item;
        }
        // ... i przejscie do nastepnego elementu
        curr = curr->next;
    }
    curr = list;
    prev = NULL;

    // *** EPIZOD 2.C ***
    // Wydruk zmodyfikowanej listy, poprzedzonej zadanym naglowkiem
    cout << title << endl;
    printList(list);

    // *** CZESC 2.B ***
    // Skasowanie z listy wszystkich rekordow znajdujacych sie przed pierwsza figura
    // z mniejsza niz zadana liczba bokow, a w ich miejsce wstawienie nowej figury
    // o zadanej nazwie, a polu powierzchni i liczbie bokow wyliczonych jako mediany
    // z odpowiednich wartosci w rekordach skasowanych

    // 2.B.1 --- Ustalenie ilosci elementow przeznaczonych do skasowania z listy

    iCount = 0;
    // Tak dlugo jak biezacy element listy jest niepusty, ...
    while (curr != NULL) {
        // ... sprawdzanie czy figura ma mniej bokow niz zadano ...
        if (curr->sides < s)
            break;
        // ... a jesli nie, to zliczenie niechcianej figury ...
        iCount++;
        // ... i przejscie do nastepnego elementu
        curr = curr->next;
    }

    // 2.B.2 --- Wyliczenie mediany odpowiednich wartosci z figur do skasowania

    if (iCount > 0) {
        // Alokacja w pamieci dynamicznych tablic pomocniczych
        int *S = new int[iCount];
        double *A = new double[iCount];

        // 2.B.2.1 --- Zebranie wartosci do wyliczenia mediany
        curr = list;
        // Przejscie przez okreslonej dlugosci zbior elementow do skasowania, ...
        for (int i = 0; i < iCount; i++, curr = curr->next) {
            // ... z zapisem w tablicy wartosci do wyliczenia mediany
            S[i] = curr->sides;
            A[i] = curr->area;
        }
        // 2.B.2.2 --- Uporzadkowanie narastajaco wartosci w tablicy ilosci bokow
        for (int i = 0; i < iCount -1; i++)
            // Wznawiane przechodzenie przez nieuporzadkowane elementy tablicy, ...
            for (int j = 0; j < iCount -1 -i; j++)
                // ... ze sprawdzaniem czy wartosc elementu nastepnego jest mniejsza
                //     niz biezacego (co wskazuje na brak uporzadkowania), ...
                if (S[j] > S[j +1]) {
                    // ... a jesli tak, zamiana miejscami tych elementow
                    int t = S[j];
                            S[j] = S[j +1];
                                   S[j +1] = t;
                }
        // 2.B.2.3 --- Uporzadkowanie narastajaco wartosci w tablicy pol powierzchni
        for (int i = 0; i < iCount -1; i++)
            // Wznawiane przechodzenie przez nieuporzadkowane elementy tablicy, ...
            for (int j = 0; j < iCount -1 -i; j++)
                // ... ze sprawdzaniem czy wartosc elementu nastepnego jest mniejsza
                //     niz biezacego (co wskazuje na brak uporzadkowania), ...
                if (A[j] > A[j +1]) {
                    // ... a jesli tak, zamiana miejscami tych elementow
                    double t = A[j];
                               A[j] = A[j +1];
                                      A[j +1] = t;
                }
        // 2.B.2.4 --- Wyliczenie/wyszukanie mediany z niepustego zbioru liczb
        int i = iCount / 2;
        if (0 == iCount % 2) {
            // Wyliczenie mediany jako sredniej z dwoch elementow srodkowych
            sides = (S[i] + S[i -1]) / 2;
            area  = (A[i] + A[i -1]) / 2;
        }
        else {
            // ... lub wybranie jej z elementu srodkowego
            sides = S[i];
            area  = A[i];
        }

        // Usuniecie z pamieci dynamicznych tablic pomocniczych
        delete[] S;
        delete[] A;

        // 2.B.3 --- Usuniecie przeznaczonych do skasowania elementow listy

        curr = list;
        // W okreslonej dlugosci zbiorze elementow do skasowania, ...
        for (i = 0; i < iCount; i++) {
            // ... skopiowanie adresu elementu do usuniecia
            //     i ucieczka w element nastepny ...
            TFigure *d = curr;
            curr = curr->next;
            // ... oraz usuniece zbednego elementu
            delete d;
        }
        list = curr;

        // 2.B.4 --- Wstawienie na poczatku listy nowej figury z odpowiednimi danymi

        // Utworzenie nowego zainicjowanego elementu ...
        TFigure *item = newItem(name, sides, area);
        // ... i wstawienie go na poczatku listy
        item->next = list;
        list = item;
    }

    // *** EPIZOD 2.C ***
    // Wydruk zmodyfikowanej listy, poprzedzonej zadanym naglowkiem
    cout << title << endl;
    printList(list);

    return 0;
}




int main() {
    string sFileName;
    ifstream fsInput;

    // Wypisanie informacji nt. potrzebnych danych
    cout << "Program korzysta z danych zapisanych w pliku tekstowym.\n";
    cout << "Plik musi zawierac rozdzielone spacjami pola rekordow ";
    cout << "definiujacych figury geometryczne.\n";

    // *** CZESC 1 ***
    // Wczytanie rekordow z pliku i utworzenie z nich listy jednokierunkowej,
    // poprzedzone interakcja z uzytkownikiem aby podal nazwe pliku danych

    // Interakcja 1. - Prosba o podanie nazwy pliku danych
    cout << "\nPodaj nazwe pliku: ";
    cin >> sFileName;

    // Proba otwarcia pliku ...
    fsInput.open(sFileName.c_str());
    if (!fsInput.is_open()) {
        // ... nie powiodla sie. :(
        cout << "Otwarcie pliku nie powiodlo sie.\nSprawdz nawe pliku ";
        cout << "i upewnij sie, czy podajesz prawidlowa sciezke dostepu.";
        return -1;
    };
    // ... jest ok :)

    TFigure *head = NULL;

    // Odczyt danych z pliku, tj. ...
    if (!fsInput.eof()) {
        // ... wczytanie pierwszego wiersza danych, ...
        string n;  int s;  double a;
        fsInput >> n;
        fsInput >> s;
        fsInput >> a;
        head = newItem(n, s, a);

        // ... a potem tak dlugo, jak nie osiagnieto konca pliku danych, ...
        while (!fsInput.eof()) {
            // ... wczytywanie nastepnych wierszy ...
            fsInput >> n;
            fsInput >> s;
            fsInput >> a;
            // ... i dodawanie nowych rekordow na koncu listy
            addItem(head, n, s, a);
        }
    }
    // Zamkniecie pliku
    fsInput.close();

    // Sprawdzenie czy sa figury na liscie, ...
    if (head == NULL) {
        // ... jesli nie - zakonczenie pracy
        cout << "Brak figur - koniec zadania.\n";
        return -1;
    }
    else
        // Wypisanie informacji o wprowadzeniu danych
        cout << "Dane z pliku " << sFileName << " wprowadzono do pamieci.\n";

    // Wydrukowanie listy figur
    printList(head);

    // *** CZESC 2 ***
    // Manipulowanie elementami listy

#define NTH_FIGURE 3
#define MIN_SIDES  3
    // Wypisanie informacji o planowanych zmianach na liscie
    cout << "\nZostanie teraz dodany nowy element za co 2. figura ";
    cout << "o polu mniejszym niz pole drugiej figury na liscie\n";
    cout << "oraz przed co " << NTH_FIGURE << ". figura o polu mniejszym ";
    cout << "niz srednie pole powierzchni figur z liczba bokow powyzej ";
    cout << MIN_SIDES << endl;

    // Uruchomienie manipulacji
    int err = muddleList(head, NTH_FIGURE, MIN_SIDES, "MALA ELIPSA", 0, 0.75,
                         "\nLista figur po wprowadzeniu zmian");
#undef MIN_SIDES
#undef NTH_FIGURE

    // *** CZESC 3 ***
    // Usuniecie listy z pamieci

    // Poczawszy od pierwszego elementu az do konca listy, ...
    while (head != NULL) {
        // ... skopiowanie adresu biezacego elementu (by usunac go z pamieci)
        //     i ucieczka w element nastepny ...
        TFigure *d = head;
        head = head->next;
        // ... oraz usuniece biezacego elementu
        delete d;
    }
    // Wypisanie informacji o skasowaniu listy
    cout << "Usunieto dane z pamieci.\n";

    system("print");
    return err;
}

/* -------------------------------------------------------------------------- */