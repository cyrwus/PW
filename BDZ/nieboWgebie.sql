CREATE SCHEMA ng AUTHORIZATION dbo;


-------------------------------------------------------------------------------
-- Procedura inicjująca struktury (tworzenie tabel, zwiazkow i ograniczen)
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.PrzygotujStruktury AS
BEGIN
    -- Tabela kategorii
    -- W zadaniu określono dwie kategorie pracochłonności przygotowania 
    -- potraw: 'szybkie', 'pracochłonne' z odpowiadającymi im limitami czasu
    -- W definicji tabeli zakładam ograniczenia dopuszczalnych wartości.
    --
    CREATE TABLE ng.Kategoria (
        KategoriaID INT IDENTITY,
        Nazwa       NCHAR(16) NOT NULL DEFAULT 'szybkie',
        LimitCzasu  SMALLINT  NOT NULL DEFAULT 15,
        CONSTRAINT  PK_Kategoria PRIMARY KEY (KategoriaID),
        CONSTRAINT  CHK_Nazwa CHECK (
             Nazwa = 'szybkie'
          OR Nazwa = 'pracochłonne'
        ),
        CONSTRAINT  CHK_LimitCzasu CHECK (
             LimitCzasu = 15
          OR LimitCzasu = 60
        )
    );

    -- Tabela rodzajow potraw
    -- Rodzaje odpowiadają typowym działom w menu restauracyjnym, jak np.:
    -- 'Przystawki', 'Dania główne', 'Desery', 'Pizza', 'Kawa', 'Herbata', ...
    --
    CREATE TABLE ng.Rodzaj (
        RodzajID    INT IDENTITY,
        Nazwa       NVARCHAR(40) NOT NULL,
        CONSTRAINT  PK_Rodzaj PRIMARY KEY (RodzajID)
    );

    -- Tabela potraw
    -- Określane tu będą nazwy i ceny wszystkich potraw, a także ich 
    -- przyporządkowanie do odpowiedniego rodzaju i kategorii.
    -- 
    CREATE TABLE ng.Potrawa (
        PotrawaID   INT IDENTITY,
        KategoriaID INT NOT NULL,
        RodzajID    INT NOT NULL,
        Nazwa       NVARCHAR(60) NOT NULL,
        Cena        DECIMAL(8,2) NOT NULL,
        CONSTRAINT  PK_Potrawa PRIMARY KEY (PotrawaID),
        CONSTRAINT  FK_Potrawa_Kategoria FOREIGN KEY (KategoriaID) REFERENCES ng.Kategoria(KategoriaID),
        CONSTRAINT  FK_Potrawa_Rodzaj FOREIGN KEY (RodzajID) REFERENCES ng.Rodzaj(RodzajID)
    );

    -- Tabela składników potraw
    -- Każdą potrawę tworzy się z jakichś składników.
    -- Ich nazwy i ceny jednostkowe (wraz z jednostką miary) gromadzone będą,
    -- by możliwe było wyciąganie listy składników dla danej potrawy, jak również
    -- wyliczanie kosztów przygotowania danej potrawy - jak wymaga zadanie.
    --
    CREATE TABLE ng.Skladnik (
        SkladnikID  INT IDENTITY,
        Nazwa       NVARCHAR(80) NOT NULL,
        Jednostka   NCHAR(8) NOT NULL,
        CenaJedn    SMALLMONEY NOT NULL,
        CONSTRAINT  PK_Skladnik PRIMARY KEY (SkladnikID)
    );

    -- Tabela asocjacyjna  Potrawa <-> Skladnik
    -- Określa przyporządkowanie składników do poszczególnych potraw, ale również
    -- ich ilość (wyrażoną w jednostce bazowej podanej dla danego składnika).
    --
    CREATE TABLE ng.Sklad (
        PotrawaID   INT NOT NULL,
        SkladnikID  INT NOT NULL,
        IloscJedn   REAL NOT NULL,
        CONSTRAINT  CHK_IloscJedn CHECK (0 <= IloscJedn),
        CONSTRAINT  PK_Sklad PRIMARY KEY (PotrawaID, SkladnikID),
        CONSTRAINT  FK_Sklad_Potrawa FOREIGN KEY (PotrawaID) REFERENCES ng.Potrawa(PotrawaID),
        CONSTRAINT  FK_Sklad_Skladnik FOREIGN KEY (SkladnikID) REFERENCES ng.Skladnik(SkladnikID)
    );

    -- Wydzielona tabela z danymi osobowymi pracowników/kucharzy.
    -- W modelu założyłem, że Kucharz - jako encja - pozostaje na stałe, natomiast
    -- jego dane osobowe mogą zostać usunięte, przez co staje się bytem anonimowym.
    -- Rozwiązanie to łączy wymgania postawione w zdaniu:
    -- a) zawsze wiadomo ile razy obsługa zawiodła i kto zawinił w badanym okresie
    -- b) dane zwolnionych pracowników nie są przechowywane.
    --
    CREATE TABLE ng.OsobaKucharz (
        OsobaID     INT IDENTITY,
        Nazwisko    NVARCHAR(40) NOT NULL,
        Imie        NVARCHAR(40) NOT NULL,
        Adres       NVARCHAR(80) NOT NULL,
        Telefon     NCHAR(16) NOT NULL,
        DataZatrudnienia DATE NOT NULL,
        CONSTRAINT  PK_OsobaKucharz PRIMARY KEY (OsobaID)
    );
    -- Tabela kucharzy
    -- Kucharz to celowo wydzielona encja anonimowa. Kucharze pełnią główną rolę
    -- w modelowanych procesach.
    -- Dla urozmaicenia dokładam pole Status, które decyduje czy kucharz jest
    -- na miejscu pracy, czy nie (przecież realnie nie wszyscy zawsze są ;)
    --
    CREATE TABLE ng.Kucharz (
        KucharzID   INT IDENTITY,
        OsobaID     INT NULL,
        Status      CHAR(2) NOT NULL DEFAULT 'P',
        CONSTRAINT  PK_Kucharz PRIMARY KEY (KucharzID),
        CONSTRAINT  FK_Kucharz_Osoba FOREIGN KEY (OsobaID) REFERENCES ng.OsobaKucharz(OsobaID)
    );

    -- Tabela asocjacyjna  Kucharz <-> Potrawa
    -- Określa zakres specjalizacji poszczególnych kucharzy. W zadaniu określono,
    -- że każdy kucharz potrafi wykonać co najmniej 17 potraw.
    --
    CREATE TABLE ng.Umiejetnosc (
        KucharzID   INT NOT NULL,
        PotrawaID   INT NOT NULL,
        CONSTRAINT  PK_Umiejetnosc PRIMARY KEY (KucharzID, PotrawaID),
        CONSTRAINT  FK_Umiejetnosc_Kucharz FOREIGN KEY (KucharzID) REFERENCES ng.Kucharz(KucharzID),
        CONSTRAINT  FK_Umiejetnosc_Potrawa FOREIGN KEY (PotrawaID) REFERENCES ng.Potrawa(PotrawaID)
    );

    -- Wydzielona tabela z danymi osobowymi pracowników/kucharzy.
    -- W modelu założyłem, że Kucharz - jako encja - pozostaje na stałe, natomiast
    -- jego dane osobowe mogą zostać usunięte, przez co staje się bytem anonimowym.
    -- Zgodnie z warunkami zadania dane klienta są usuwane, gdy upłynął conajmniej 
    -- rok od jego "wizyty" w restaurcji.
    -- Dane klientów nie są obligatoryjne (przecież nie każdy klient je udostępni).
    -- Przewidziano jednak strukturę gotową na przyjęcie ewentualnych pełnych danych,
    -- koniecznych np. do zamówień telefonicznych z dostawą pod adres ;)
    --
    CREATE TABLE ng.OsobaKlient (
        OsobaID     INT IDENTITY,
        Nazwisko    NVARCHAR(40) NULL,
        Imie        NVARCHAR(40) NULL,
        Adres       NVARCHAR(80) NULL,
        Telefon     NCHAR(16) NULL,
        CONSTRAINT  PK_OsobaKlient PRIMARY KEY (OsobaID)
    );
    -- Tabela klientów
    -- Klient to celowo wydzielona encja anonimowa. Klienci odgrywają ważną rolę
    -- w modelowanych procesach.
    --
    CREATE TABLE ng.Klient (
        KlientID    INT IDENTITY,
        OsobaID     INT NULL,
        CONSTRAINT  PK_Klient PRIMARY KEY (KlientID), 
        CONSTRAINT  FK_Klient_Osoba FOREIGN KEY (OsobaID) REFERENCES ng.OsobaKlient(OsobaID)
    );

    -- Tabela skarg
    -- Gromadzone tu będą skargi klienta. Zakładam, że chodzi o niedługie informacje
    -- tekstowe, które mogą dotyczyć konkretnych/-ej potraw/-y w zamówionym posiłku.
    -- Zadanie mówi: "dla każdej potrawy w posiłku klienta rejestrowany jest (...) 
    -- i dane związane z ewentualną skargą.
    --
    CREATE TABLE ng.Skarga (
        SkargaID    INT NOT NULL IDENTITY, 
        KlientID    INT NOT NULL, 
        Opis        NVARCHAR(240) NOT NULL, 
        CONSTRAINT  PK_Skarga PRIMARY KEY (SkargaID),
        CONSTRAINT  FK_Skarga_Klient FOREIGN KEY (KlientID) REFERENCES ng.Klient (KlientID)
    );

    -- Tabela posiłków
    -- Posiłek to logiczny 'nadzbiór' dla potrawy. Klient zamawia w restauracji
    -- posiłek, w posiłku może być jedna lub więcej potraw, a potraw może być jedna
    -- lub więcej porcji.
    --
    CREATE TABLE ng.Posilek (
        PosilekID   INT NOT NULL IDENTITY,
        KlientID    INT NOT NULL,
        DataZamowienia DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT  PK_Posilek PRIMARY KEY (PosilekID),
        CONSTRAINT  FK_Posilek_Klient FOREIGN KEY (KlientID) REFERENCES ng.Klient (KlientID)
    );

    -- Tabela zleceń
    -- Zlecenie to encja kluczowa w modelowanym procesie. 
    -- W tabeli zleceń rejestrowane jest każde zdarzenie polegające na powierzeniu
    -- kucharzowi zadania (przez 'szefa kuchni') przygotowania potrawy, wchodzącej
    -- w sklad posiłku. Oprócz referencji do encji Potrawa, Posilek, zapisywane są
    -- czas przyjęcia i wydania gotowego zlecenia.
    -- Jakość wykonanego zlecenia może być przedmiotem zaskarżona przez klienta.
    -- Jesli tak sie stanie, to zapisana zostanie rowież referencja do złożonej skargi.
    --
    CREATE TABLE ng.Zlecenie (
        ZlecenieID  INT NOT NULL IDENTITY,
        PotrawaID   INT NOT NULL,
        Porcje      SMALLINT NOT NULL DEFAULT 1,
        PosilekID   INT NOT NULL,
        KucharzID   INT NULL,
        DataPrzyjecia DATETIME NULL,
        DataOdbioru DATETIME NULL,
        SkargaID    INT NULL,
        CONSTRAINT  CHK_Porcje CHECK (0 < Porcje),
        CONSTRAINT  PK_Zlecenie PRIMARY KEY (ZlecenieID),
        CONSTRAINT  FK_Zlecenie_Kucharz FOREIGN KEY (KucharzID) REFERENCES ng.Kucharz (KucharzID),
        CONSTRAINT  FK_Zlecenie_Posilek FOREIGN KEY (PosilekID) REFERENCES ng.Posilek (PosilekID),
        CONSTRAINT  FK_Zlecenie_Potrawa FOREIGN KEY (PotrawaID) REFERENCES ng.Potrawa (PotrawaID),
        CONSTRAINT  FK_Zlecenie_Skarga  FOREIGN KEY (SkargaID)  REFERENCES ng.Skarga (SkargaID)
    );

    -- Tabela rankingów
    --
    CREATE TABLE ng.Ranking (
        KucharzID   INT NOT NULL,
        PotrawaID   INT NOT NULL,
        Opoznienia  INT NOT NULL DEFAULT 0,
        Skargi      INT NOT NULL DEFAULT 0,
        CONSTRAINT  PK_Ranking PRIMARY KEY (KucharzID, PotrawaID),
        CONSTRAINT  FK_Ranking_Umiejetnosc
            FOREIGN KEY (KucharzID, PotrawaID)
            REFERENCES ng.Umiejetnosc (KucharzID, PotrawaID)
    );


    ---------------------------------------------------------------------------
    -- Założenie indeksów unikalnych na wybranych tabelach
    --
    CREATE UNIQUE INDEX UIX_Kategoria_Nazwa ON ng.Kategoria(Nazwa);
    CREATE UNIQUE INDEX UIX_Rodzaj_Nazwa ON ng.Rodzaj(Nazwa);
    CREATE UNIQUE INDEX UIX_Potrawa_Nazwa ON ng.Potrawa(Nazwa);
    CREATE UNIQUE INDEX UIX_Skladnik_Nazwa ON ng.Skladnik(Nazwa);

END;




-------------------------------------------------------------------------------
-- Procedura wstawiająca modelowe dane do przygotowanych struktur.
-- Oferta kulinarna na podstawie rzeczywistego menu w Bleik Restaurant ;)
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.WstawDane
AS
BEGIN
    -- Wprowadzenie kategorii potraw do tabeli Kategoria
    INSERT INTO ng.Kategoria ( Nazwa, LimitCzasu)
    VALUES
        ( 'szybkie', 15),
        ( 'pracochłonne', 60);

    -- Wprowadzenie rodzajów potraw do tabeli Rodzaj
    INSERT INTO ng.Rodzaj ( Nazwa)
    VALUES
        ( 'Przystawki'),
        ( 'Zupy'),
        ( 'Sałatki'),
        ( 'Dania główne'),
        ( 'Makarony'),
        ( 'Ryby'),
        ( 'Pizze'),
        ( 'Desery'),
        ( 'Inne'),
        ( 'Kawy'),
        ( 'Herbaty'),
        ( 'Napoje bezalkoholowe');

    -- Wprowadzenie listy wszystkich potraw (wraz z cenami) do tabeli Potrawa, ...
    INSERT INTO ng.Potrawa ( KategoriaID, RodzajID, Nazwa, Cena)
    VALUES
        -- ... Przystawki
        ( 1,  1, 'Tatar z polędwicy wołowej',         56.00),
        ( 1,  1, 'Tatar z pomidora',                  35.00),
        ( 1,  1, 'Carpaccio wołowe',                  49.00),
        ( 1,  1, 'Wątróbka',                          28.00),
        ( 1,  1, 'Krewetki oliwi',                    42.00),
        -- ... Zupy
        ( 1,  2, 'Żurek',                             24.00),
        ( 1,  2, 'Domowy rosół z trzech mięs',        19.00),
        ( 1,  2, 'Strogonow z dzika',                 27.00),
        ( 1,  2, 'Zupa tajska - kurczak',             22.00),
        ( 1,  2, 'Zupa tajska - krewetki',            30.00),
        -- ... Sałatki
        ( 2,  3, 'Sałata Cezar - kurczak',            38.00),
        ( 2,  3, 'Sałata Cezar - krewetki',           56.00),
        ( 2,  3, 'Sałata z polędwicą wołową',         40.00),
        ( 2,  3, 'Panzanella',                        38.00),
        -- ... Dania główne
        ( 2,  4, 'Sznycel cielęcy',                   48.00),
        ( 2,  4, 'Schabowy z kością',                 43.00),
        ( 2,  4, 'Kaczka',                            72.00),
        ( 2,  4, 'Golonka',                           47.00),
        ( 2,  4, 'Żeberka wieprzowe sousvide',        75.00),
        ( 2,  4, 'Polik wołowy',                      56.00),
        ( 2,  4, 'Królik',                            56.00),
        ( 2,  4, 'Polędwica wołowa',                  99.00),
        ( 2,  4, 'Kurczak kukurydziany',              54.00),
        ( 2,  4, 'Parmigiana di melanzane',           36.00),
        ( 2,  4, 'Pierogi z żebrem wołowym',          52.00),
        -- ... Makarony
        ( 2,  5, 'Makaron frutti di mare',            55.00),
        ( 2,  5, 'Spaghetti Carbonara',               39.00),
        -- ... Ryby
        ( 2,  6, 'Łosoś',                             62.00),
        ( 2,  6, 'Gadus',                             53.00),
        -- ... Pizze
        ( 1,  7, 'Margarita',                         27.00),
        ( 1,  7, 'Capriciosa',                        32.00),
        ( 1,  7, 'Cztery sery',                       42.00),
        ( 1,  7, 'Diavola spianata',                  35.00),
        ( 1,  7, 'Skampi',                            45.00),
        ( 1,  7, 'Prosciutto crudo',                  32.00),
        ( 1,  7, 'Burrata',                           32.00),
        ( 1,  7, 'Chorizo',                           37.00),
        ( 1,  7, 'Uowo secretto',                     32.00),
        ( 1,  7, 'Villagio',                          38.00),
        ( 1,  7, 'Wołowina',                          38.00),
        ( 1,  7, 'Kurczak grillowany',                32.00),
        -- ... Desery
        ( 2,  8, 'Cream Brullee',                     30.00),
        ( 2,  8, 'Tartaletka',                        36.00),
        ( 2,  8, 'Mini eklery',                       35.00),
        ( 2,  8, 'Lava cake',                         34.00),
        -- ... Kawy
        ( 1, 10, 'Espresso',                           9.00),
        ( 1, 10, 'Americano',                         10.00),
        ( 1, 10, 'Flat White',                        13.00),
        ( 1, 10, 'Cappuccino',                        12.00),
        ( 1, 10, 'Latte',                             15.00),
        ( 1, 10, 'Doppio',                            11.00),
        ( 1, 10, 'Irish coffee',                      28.00),
        -- ... Herbaty
        ( 1, 11, 'Ginger paradise',                   12.00),
        ( 1, 11, 'Raspberry pear',                    12.00),
        ( 1, 11, 'Ceylon gold',                       12.00),
        ( 1, 11, 'Mexican dream',                     12.00),
        ( 1, 11, 'Yerba mate lemon',                  12.00),
        ( 1, 11, 'Peppermint green',                  12.00),
        ( 1, 11, 'Mango Maui',                        12.00),
        ( 1, 11, 'Green Yasmine',                     12.00),
        ( 1, 11, 'English breakfast',                  8.00),
        ( 1, 11, 'Gunpowder green',                    8.00),
        ( 1, 11, 'Earlgrey blue',                      8.00),
        -- ... Napoje (bezalkoholowe)
        ( 1, 12, 'Pepsi',                              9.00),
        ( 1, 12, '7 UP',                               9.00),
        ( 1, 12, 'Mirinda',                            9.00),
        ( 1, 12, 'Tonic',                              9.00),
        ( 1, 12, 'Lipton Ice Tea',                     9.00),
        ( 1, 12, 'Sok jabłkowy',                       9.00),
        ( 1, 12, 'Sok pomarańczowy',                   9.00),
        ( 1, 12, 'Świeży sok wyciskany - pomarańcza', 21.00),
        ( 1, 12, 'Świeży sok wyciskany - grejpfrut',  21.00),
        ( 1, 12, 'Świeży sok wyciskany - mix',        21.00),
        ( 1, 12, 'Lemoniada klasyczna',               20.00),
        ( 1, 12, 'Lemoniada marakuja',                20.00);

    -- Wprowadzenie danych o wszystkich składnikach do tabeli Skladnik, ...
    INSERT INTO ng.Skladnik ( Nazwa, Jednostka, CenaJedn)
    VALUES
        ( 'anchois',                             '',   0.00),
        ( 'awokado',                             '',   0.00),
        ( 'bagietka',                            '',   0.00),
        ( 'bakłażan',                            '',   0.00),
        ( 'bazylia',                             '',   0.00),
        ( 'bekon',                               '',   0.00),
        ( 'biała kiełbasa',                      '',   0.00),
        ( 'boczniaki',                           '',   0.00),
        ( 'brokuł bimi',                         '',   0.00),
        ( 'burak',                               '',   0.00),
        ( 'buratta',                             '',   0.00),
        ( 'burbon',                              '',   0.00),
        ( 'cebula',                              '',   0.00),
        ( 'cebula marynowana',                   '',   0.00),
        ( 'cebulki cipollini',                   '',   0.00),
        ( 'chilli',                              '',   0.00),
        ( 'chips ziemniaczany',                  '',   0.00),
        ( 'chorizo Gran Vela Rojo',              '',   0.00),
        ( 'chrust ziemniaczany',                 '',   0.00),
        ( 'chrzan',                              '',   0.00),
        ( 'crostini chlebowe',                   '',   0.00),
        ( 'cukinia grillowana',                  '',   0.00),
        ( 'cykoria',                             '',   0.00),
        ( 'czipsy z batata',                     '',   0.00),
        ( 'czosnek',                             '',   0.00),
        ( 'dressing orientalny',                 '',   0.00),
        ( 'dymka',                               '',   0.00),
        ( 'dynia piklowana',                     '',   0.00),
        ( 'emulsja z żółtka',                    '',   0.00),
        ( 'filet z dorsza z pieca',              '',   0.00),
        ( 'frużelina malinowa',                  '',   0.00),
        ( 'frytki z batata',                     '',   0.00),
        ( 'glazura piwno-bbq',                   '',   0.00),
        ( 'glazurowane buraki',                  '',   0.00),
        ( 'gnocchi buraczane',                   '',   0.00),
        ( 'golonka wieprzowa',                   '',   0.00),
        ( 'gorgonzola',                          '',   0.00),
        ( 'grana padano',                        '',   0.00),
        ( 'granat',                              '',   0.00),
        ( 'grillowane bataty',                   '',   0.00),
        ( 'groszek zielony',                     '',   0.00),
        ( 'grzanka wieloziarnista',              '',   0.00),
        ( 'grzanka z mozzarellą',                '',   0.00),
        ( 'grzanki',                             '',   0.00),
        ( 'grzyby shimeji',                      '',   0.00),
        ( 'grzyby słomiane',                     '',   0.00),
        ( 'guanciale',                           '',   0.00),
        ( 'gzik',                                '',   0.00),
        ( 'jabłka',                              '',   0.00),
        ( 'jajko',                               '',   0.00),
        ( 'jajko poche',                         '',   0.00),
        ( 'jajko sadzone',                       '',   0.00),
        ( 'jarmuż',                              '',   0.00),
        ( 'kaczka',                              '',   0.00),
        ( 'kalmary',                             '',   0.00),
        ( 'kapary',                              '',   0.00),
        ( 'kapusta zasmarzana',                  '',   0.00),
        ( 'karczochy',                           '',   0.00),
        ( 'kawior owocowy',                      '',   0.00),
        ( 'koper',                               '',   0.00),
        ( 'kotlet panierowany',                  '',   0.00),
        ( 'kozi ser',                            '',   0.00),
        ( 'krem brzoskwina',                     '',   0.00),
        ( 'krem cappuccino',                     '',   0.00),
        ( 'krem chrzanowy',                      '',   0.00),
        ( 'krem dzika róża',                     '',   0.00),
        ( 'krem pistacjowy',                     '',   0.00),
        ( 'krewetki',                            '',   0.00),
        ( 'krokiet ziemniaczany',                '',   0.00),
        ( 'kukurydza',                           '',   0.00),
        ( 'kurczak',                             '',   0.00),
        ( 'kurczak grillowany',                  '',   0.00),
        ( 'lody śmietankowe',                    '',   0.00),
        ( 'majonez szczypiorkowy',               '',   0.00),
        ( 'makaron',                             '',   0.00),
        ( 'makaron ryżowy',                      '',   0.00),
        ( 'maliny',                              '',   0.00),
        ( 'małże nowozelandzkie',                '',   0.00),
        ( 'marchew mini',                        '',   0.00),
        ( 'marchewka',                           '',   0.00),
        ( 'masło',                               '',   0.00),
        ( 'mizeria',                             '',   0.00),
        ( 'mleko kokosowe',                      '',   0.00),
        ( 'mozzarella',                          '',   0.00),
        ( 'mozzarella fior di late',             '',   0.00),
        ( 'mus jabłkowy',                        '',   0.00),
        ( 'mus malinowy',                        '',   0.00),
        ( 'mus wiśniowy',                        '',   0.00),
        ( 'musztarda',                           '',   0.00),
        ( 'natka pietruszki',                    '',   0.00),
        ( 'noga z kurczaka',                     '',   0.00),
        ( 'ogórek świeży',                       '',   0.00),
        ( 'oliwa',                               '',   0.00),
        ( 'oliwki',                              '',   0.00),
        ( 'orzechy',                             '',   0.00),
        ( 'owoce',                               '',   0.00),
        ( 'pak-choi w glazurze Hoisin',          '',   0.00),
        ( 'Pecorino Romano',                     '',   0.00),
        ( 'pesto',                               '',   0.00),
        ( 'pieczarki',                           '',   0.00),
        ( 'pieczywo',                            '',   0.00),
        ( 'pierś z kurczaka',                    '',   0.00),
        ( 'pikle',                               '',   0.00),
        ( 'piklowana cebula',                    '',   0.00),
        ( 'pistacje',                            '',   0.00),
        ( 'podsuszana polędwica wołowa',         '',   0.00),
        ( 'polewa z białej czekolady',           '',   0.00),
        ( 'polędwica wołowa',                    '',   0.00),
        ( 'polędwica z dzika',                   '',   0.00),
        ( 'policzki wołowe',                     '',   0.00),
        ( 'pomidor',                             '',   0.00),
        ( 'pomidor cherry',                      '',   0.00),
        ( 'pomidory cherry',                     '',   0.00),
        ( 'popcorn z gryki',                     '',   0.00),
        ( 'Prosciutto Crudo',                    '',   0.00),
        ( 'puree ziemniaczane z chrzanem',       '',   0.00),
        ( 'puree ziemniaczane',                  '',   0.00),
        ( 'ravioli z ricottą',                   '',   0.00),
        ( 'rukola',                              '',   0.00),
        ( 'rzodkiewka',                          '',   0.00),
        ( 'salami spianata',                     '',   0.00),
        ( 'sałata rzymska',                      '',   0.00),
        ( 'scamorza',                            '',   0.00),
        ( 'ser gorgonzola',                      '',   0.00),
        ( 'sezam',                               '',   0.00),
        ( 'shimeji',                             '',   0.00),
        ( 'skoki z królika',                     '',   0.00),
        ( 'sos balsamiczny',                     '',   0.00),
        ( 'sos cesarski',                        '',   0.00),
        ( 'sos custard',                         '',   0.00),
        ( 'sos demi glace',                      '',   0.00),
        ( 'sos Jack Daniels',                    '',   0.00),
        ( 'sos małżowy',                         '',   0.00),
        ( 'sos polski',                          '',   0.00),
        ( 'sos pomidorowy',                      '',   0.00),
        ( 'sos śmietanowy',                      '',   0.00),
        ( 'sos typu jus',                        '',   0.00),
        ( 'sos z zielonego pieprzu',             '',   0.00),
        ( 'sticksy z buraka',                    '',   0.00),
        ( 'suszone grzyby',                      '',   0.00),
        ( 'suszony pomidor',                     '',   0.00),
        ( 'szczypior dymka',                     '',   0.00),
        ( 'szpinak baby',                        '',   0.00),
        ( 'szpinak w śmietanie',                 '',   0.00),
        ( 'szynka',                              '',   0.00),
        ( 'szynka cotto',                        '',   0.00),
        ( 'śmietana',                            '',   0.00),
        ( 'świeże owoce',                        '',   0.00),
        ( 'świeże warzywa',                      '',   0.00),
        ( 'tagliolini sephi',                    '',   0.00),
        ( 'tofu',                                '',   0.00),
        ( 'trufla',                              '',   0.00),
        ( 'tymianek',                            '',   0.00),
        ( 'udo z kaczki',                        '',   0.00),
        ( 'udo z kurczaka',                      '',   0.00),
        ( 'vinegret pietruszkowy',               '',   0.00),
        ( 'warzywa sezonowe z patelni',          '',   0.00),
        ( 'warzywa w tempurze',                  '',   0.00),
        ( 'wątróbka drobiowa',                   '',   0.00),
        ( 'wiejski chleb',                       '',   0.00),
        ( 'wino',                                '',   0.00),
        ( 'wołowina',                            '',   0.00),
        ( 'Wongole',                             '',   0.00),
        ( 'ziemniak pieczony',                   '',   0.00),
        ( 'ziemniaki z masłem',                  '',   0.00),
        ( 'żeberka wieprzowe',                   '',   0.00),
        ( 'żółtko',                              '',   0.00);

    -- Zbudowanie asocjacji Potrawa <-> Skladnik, ...
    INSERT INTO ng.Sklad (PotrawaID, SkladnikID, IloscJedn)
    VALUES
        ( 1, 108,  0.00),  ( 1, 103,  0.00),  ( 1,  29,  0.00),  ( 1,  24,  0.00),  ( 1,  74,  0.00),
        ( 2, 111,  0.00),  ( 2, 120,  0.00),  ( 2, 103,  0.00),  ( 2,   5,  0.00),  ( 2,  93,  0.00),  ( 2,  42,  0.00),
        ( 3, 108,  0.00),  ( 3,  87,  0.00),  ( 3, 119,  0.00),  ( 3, 104,  0.00),  ( 3,  38,  0.00),  ( 3, 152,  0.00),
        ( 4, 159,  0.00),  ( 4, 160,  0.00),  ( 4,  13,  0.00),  ( 4,   6,  0.00),  ( 4,  86,  0.00),  ( 4,  88,  0.00),
        ( 5,  68,  0.00),  ( 5,  25,  0.00),  ( 5,  16,  0.00),
        ( 5, 113,  0.00),  ( 5, 161,  0.00),  ( 5,  81,  0.00),  ( 5,  89,  0.00),  ( 5,   3,  0.00),
        ( 6,  69,  0.00),  ( 6,  21,  0.00),  ( 6,  65,  0.00),  ( 6,  50,  0.00),  ( 6,   6,  0.00),  ( 6,   7,  0.00),
        ( 7,  71,  0.00),  ( 7, 162,  0.00),  ( 7,  54,  0.00),  ( 7,  80,  0.00),  ( 7,  75,  0.00),  ( 7,  91,  0.00),
        ( 8, 109,  0.00),  ( 8, 140,  0.00),  ( 8,  80,  0.00),  ( 8, 147,  0.00),  ( 8,  43,  0.00),
        ( 9, 102,  0.00),  ( 9,  83,  0.00),  ( 9,  76,  0.00),  ( 9,  46,  0.00),  ( 9, 151,  0.00),  ( 9,  41,  0.00),  ( 9,  16,  0.00),
        (10, 68,   0.00),  (10,  83,  0.00),  (10,  76,  0.00),  (10,  46,  0.00),  (10, 151,  0.00),  (10,  41,  0.00),  (10,  16,  0.00),
        (11, 102,  0.00),  (11, 122,  0.00),  (11, 129,  0.00),  (11,   1,  0.00),  (11,  44,  0.00),  (11,   6,  0.00),  (11,   2,  0.00),
        (12, 68,   0.00),  (12, 122,  0.00),  (12, 129,  0.00),  (12,   1,  0.00),  (12,  44,  0.00),  (12,   6,  0.00),  (12,   2,  0.00),
        (13, 106,  0.00),  (13, 124,  0.00),  (13,  92,  0.00),  (13,  77,  0.00),  (13,  39,  0.00),  (13,  13,  0.00),  (13, 156,  0.00),
        (14, 119,  0.00),  (14, 128,  0.00),  (14,  10,  0.00),  (14,  28,  0.00),  (14,  62,  0.00),  (14, 112,  0.00),  (14,  95,  0.00),
        (15, 61,   0.00),  (15, 165,  0.00),  (15,  60,  0.00),  (15,  52,  0.00),  (15,  38,  0.00),  (15,  82,  0.00),
        (16, 61,   0.00),  (16, 165,  0.00),  (16,  60,  0.00),  (16,  52,  0.00),  (16,  38,  0.00),  (16,  82,  0.00),
        (17, 154,  0.00),  (17, 117,  0.00),  (17,  34,  0.00),  (17, 137,  0.00),  (17,  49,  0.00),  (17,  97,  0.00),
        (18, 36,   0.00),  (18,  57,  0.00),  (18, 101,  0.00),  (18,  89,  0.00),  (18,  20,  0.00),  (18,  19,  0.00),
        (19, 166,  0.00),  (19,  33,  0.00),  (19,  32,  0.00),  (19, 149,  0.00),  (19,  26,  0.00),
        (20, 110,  0.00),  (20, 117,  0.00),  (20,  53,  0.00),  (20,  80,  0.00),  (20,   8,  0.00),  (20,  79,  0.00),  (20,  17,  0.00),
        (21, 127,  0.00),  (21,  35,  0.00),  (21, 157,  0.00),  (21, 136,  0.00),  (21, 153,  0.00),  (21,  27,  0.00),  (21,   9,  0.00),
        (22, 108,  0.00),  (22, 144,  0.00),  (22, 117,  0.00),  (22, 134,  0.00),  (22,  68,  0.00),
        (23, 155,  0.00),  (23, 164,  0.00),  (23,  48,  0.00),  (23, 157,  0.00),  (23, 138,  0.00),
        (24, 4,    0.00),  (24,  99,  0.00),  (24,  84,  0.00),  (24,  38,  0.00),
        (25, 12,   0.00),  (25, 131,  0.00),  (25, 126,  0.00),  (25,  41,  0.00),  (25,  27,  0.00),  (25, 114,  0.00),
        (26, 67,   0.00),  (26,  55,  0.00),  (26,  78,  0.00),  (26, 163,  0.00),  (26, 150,  0.00),
        (27, 47,   0.00),  (27, 167,  0.00),  (27,  98,  0.00),
        (28, 40,   0.00),  (28, 132,  0.00),  (28,  23,  0.00),  (28, 158,  0.00),  (28, 125,  0.00),
        (29, 30,   0.00),  (29, 133,  0.00),  (29, 118,  0.00),  (29, 143,  0.00),  (29, 112,  0.00),  (29, 139,  0.00),
        (30, 135,  0.00),  (30,  85,  0.00),  (30,   5,  0.00),
        (31, 135,  0.00),  (31,  85,  0.00),  (31, 146,  0.00),  (31, 100,  0.00),  (31,  13,  0.00),
        (32, 136,  0.00),  (32,  85,  0.00),  (32,  37,  0.00),  (32,  62,  0.00),  (32,  98,  0.00),  (32,  89,  0.00),
        (33, 135,  0.00),  (33,  85,  0.00),  (33, 121,  0.00),  (33,  16,  0.00),  (33,  25,  0.00),  (33, 119,  0.00),
        (34, 135,  0.00),  (34,  85,  0.00),  (34,  68,  0.00),  (34,  58,  0.00),  (34, 145,  0.00),  (34,  16,  0.00),  (34,  25,  0.00),  ( 34,  89,  0.00),
        (35, 135,  0.00),  (35,  85,  0.00),  (35, 119,  0.00),  (35, 112,  0.00),  (35, 115,  0.00),  (35,  38,  0.00),
        (36, 135,  0.00),  (36,  85,  0.00),  (36,  11,  0.00),  (36, 112,  0.00),  (36, 119,  0.00),  (36,  99,  0.00),
        (37, 135,  0.00),  (37,  85,  0.00),  (37,  18,  0.00),  (37,  56,  0.00),  (37,  94,  0.00),  (37,   1,  0.00),
        (38, 136,  0.00),  (38,  85,  0.00),  (38,  22,  0.00),  (38, 111,  0.00),  (38,  14,  0.00),  (38,  51,  0.00),
        (39, 135,  0.00),  (39,  85,  0.00),  (39, 146,  0.00),  (39, 121,  0.00),  (39, 100,  0.00),  (39,  13,  0.00),  (39, 123,  0.00),
        (40, 135,  0.00),  (40,  85,  0.00),  (40, 106,  0.00),  (40,  45,  0.00),  (40,  15,  0.00),  (40, 142,  0.00),
        (41, 135,  0.00),  (41,  85,  0.00),  (41,  72,  0.00),  (41,  13,  0.00),  (41, 141,  0.00),  (41,  70,  0.00),  (41, 112,  0.00),
        (42, 148,  0.00),  (42, 105,  0.00),
        (43, 31,   0.00),  (43,  96,  0.00),  (43,  67,  0.00),
        (44, 66,   0.00),  (44,  63,  0.00),  (44,  64,  0.00),  (44, 107,  0.00),  (44,  96,  0.00),
        (45, 130,  0.00),  (45,  73,  0.00),  (45,  96,  0.00),  (45,  87,  0.00),  (45,  59,  0.00);

    -- Wprowadzenie danych osobowych do tabeli OsobaKucharz, ...
    INSERT INTO ng.OsobaKucharz ( Nazwisko, Imie, Adres, Telefon, DataZatrudnienia)
    VALUES
        ( 'Michalski',     'Michał',   'Warszawa, ul. Tajna 13',          '123-456-789', '2020.02.03'),
        ( 'Jakubowski',    'Jakub',    'Warszawa, ul. Niewiadomska 1',    '234-567-891', '2020.03.04'),
        ( 'Piotrowski',    'Piotr',    'Warszawa, ul. 11 Września 200/1', '345-678-912', '2020.04.06'),
        ( 'Romańska',      'Roma',     'Warszawa, ul. Warszawska 17',     '456-789-123', '2022.09.01'),
        ( 'Juliańska',     'Julia',    'Marki, ul. Walutowa 2',           '567-891-234', '2022.08.01'),
        ( 'Lukasiewicz',   'Łukasz',   'Legionowo, ul. Legii 4',          '678-912-345', '2021.07.01'),
        ( 'Majewska',      'Maja',     'Warszawa, ul. 3 Maja 3',          '789-123-456', '2021.06.02'),
        ( 'Wojciechowski', 'Wojciech', 'Pruszków, ul. Mafii 3',           '891-234-567', '2021.06.02'),
        ( 'Kalińska',      'Kalina',   'Piaseczno, ul. Piaskowa 7',       '912-345-678', '2023.10.02');

    -- Wprowadzenie pracowników do tabeli Kucharz (z określeniem ich bieżącego statusu), ...
    INSERT INTO ng.Kucharz ( OsobaID, Status)
    VALUES
        ( 1, 'P'), -- pracuje
        ( 2, 'P'), -- pracuje
        ( 3, 'U'), -- urlop
        ( 4, 'L'), -- zwolnienie lekarskie
        ( 5, 'N'), -- nieobecny (2 zmiana)
        ( 6, 'N'), -- nieobecny (2 zmiana)
        ( 7, 'P'), -- pracuje
        ( 8, 'P'), -- pracuje
        ( 9, 'P'); -- pracuje

    -- Zbudowanie asocjacji Kucharz <-> Potrawa, ...
    INSERT INTO ng.Umiejetnosc (KucharzID, PotrawaID)
    VALUES
        -- potrawy (zakładam jeden nie spełniony warunek 3 kucharzy dla potrawy 25 - więc powinna nie być serwowana)
        (1, 1), (1, 2), (1, 3), (1, 6), (1, 7), (1, 8), (1,14), (1,15), (1,16), (1,17), (1,18), (1,19), (1,20), (1,21), (1,22), (1,23), (1,24), (1,42), (1,43), (1,44), (1,45),
        (2, 1), (2, 3), (2, 7), (2, 8), (2,13), (2,15), (2,16), (2,18), (2,19), (2,20), (2,21), (2,22), (2,28), (2,29), (2,42), (2,43), (2,44), (2,45),
        (3, 2), (3, 5), (3, 9), (3,10), (3,11), (3,12), (3,13), (3,14), (3,24), (3,26), (3,27), (3,28), (3,29), (3,42), (3,43), (3,44), (3,45),
        (4, 4), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4,10), (4,11), (4,12), (4,13), (4,14), (4,17), (4,23), (4,24), (4,25), (4,28), (4,29),
        (5, 4), (5, 5), (5, 7), (5, 8), (5,15), (5,16), (5,17), (5,18), (5,19), (5,20), (5,21), (5,22), (5,23), (5,24), (5,25), (5,26), (5,27),
        (6,26), (6,27), (6,30), (6,31), (6,32), (6,33), (6,34), (6,35), (6,36), (6,37), (6,38), (6,39), (6,40), (6,41), (6,42), (6,43), (6,44), (6,45),
        (7,15), (7,16), (7,17), (7,18), (7,19), (7,20), (7,21), (7,30), (7,31), (7,32), (7,33), (7,34), (7,35), (7,36), (7,37), (7,38), (7,39), (7,40), (7,41),
        (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8,30), (8,31), (8,32), (8,33), (8,34), (8,35), (8,36), (8,37), (8,38), (8,39), (8,40), (8,41),
        (9, 1), (9, 2), (9, 3), (9, 4), (9, 5), (9, 6), (9, 9), (9,10), (9,11), (9,12), (9,13), (9,14), (9,22), (9,23), (9,26), (9,27), (9,28), (9,29),
        -- napoje (wszyscy ogarniają temat)
        (1,46), (1,47), (1,48), (1,49), (1,50), (1,51), (1,52), (1,53), (1,54), (1,55), (1,56), (1,57), (1,58), (1,59), (1,60), (1,61), (1,62), (1,63), (1,64), (1,65), (1,66), (1,67), (1,68), (1,69), (1,70), (1,71), (1,72), (1,73), (1,74), (1,75),
        (2,46), (2,47), (2,48), (2,49), (2,50), (2,51), (2,52), (2,53), (2,54), (2,55), (2,56), (2,57), (2,58), (2,59), (2,60), (2,61), (2,62), (2,63), (2,64), (2,65), (2,66), (2,67), (2,68), (2,69), (2,70), (2,71), (2,72), (2,73), (2,74), (2,75),
        (3,46), (3,47), (3,48), (3,49), (3,50), (3,51), (3,52), (3,53), (3,54), (3,55), (3,56), (3,57), (3,58), (3,59), (3,60), (3,61), (3,62), (3,63), (3,64), (3,65), (3,66), (3,67), (3,68), (3,69), (3,70), (3,71), (3,72), (3,73), (3,74), (3,75),
        (4,46), (4,47), (4,48), (4,49), (4,50), (4,51), (4,52), (4,53), (4,54), (4,55), (4,56), (4,57), (4,58), (4,59), (4,60), (4,61), (4,62), (4,63), (4,64), (4,65), (4,66), (4,67), (4,68), (4,69), (4,70), (4,71), (4,72), (4,73), (4,74), (4,75),
        (5,46), (5,47), (5,48), (5,49), (5,50), (5,51), (5,52), (5,53), (5,54), (5,55), (5,56), (5,57), (5,58), (5,59), (5,60), (5,61), (5,62), (5,63), (5,64), (5,65), (5,66), (5,67), (5,68), (5,69), (5,70), (5,71), (5,72), (5,73), (5,74), (5,75),
        (6,46), (6,47), (6,48), (6,49), (6,50), (6,51), (6,52), (6,53), (6,54), (6,55), (6,56), (6,57), (6,58), (6,59), (6,60), (6,61), (6,62), (6,63), (6,64), (6,65), (6,66), (6,67), (6,68), (6,69), (6,70), (6,71), (6,72), (6,73), (6,74), (6,75),
        (7,46), (7,47), (7,48), (7,49), (7,50), (7,51), (7,52), (7,53), (7,54), (7,55), (7,56), (7,57), (7,58), (7,59), (7,60), (7,61), (7,62), (7,63), (7,64), (7,65), (7,66), (7,67), (7,68), (7,69), (7,70), (7,71), (7,72), (7,73), (7,74), (7,75),
        (8,46), (8,47), (8,48), (8,49), (8,50), (8,51), (8,52), (8,53), (8,54), (8,55), (8,56), (8,57), (8,58), (8,59), (8,60), (8,61), (8,62), (8,63), (8,64), (8,65), (8,66), (8,67), (8,68), (8,69), (8,70), (8,71), (8,72), (8,73), (8,74), (8,75),
        (9,46), (9,47), (9,48), (9,49), (9,50), (9,51), (9,52), (9,53), (9,54), (9,55), (9,56), (9,57), (9,58), (9,59), (9,60), (9,61), (9,62), (9,63), (9,64), (9,65), (9,66), (9,67), (9,68), (9,69), (9,70), (9,71), (9,72), (9,73), (9,74), (9,75);

    -- Wstawienienie danych osobowych do tabeli Klient, ...
    INSERT INTO ng.OsobaKlient ( Nazwisko, Imie, Adres, Telefon)
    VALUES
        ( '',              'Adam',        '',                                               ''),
        ( 'Kowalska',      'Katarzyna',   '00-001 Warszawa, ul. Marszałkowska',             ''),
        ( '',              'Joanna',      '',                                               ''),
        ( 'Wójcik',        'Magdalena',   '00-011 Warszawa, ul. Nowy Świat',                ''),
        ( '',              'Aleksandra',  '',                                               ''),
        ( 'Nowakowska',    'Agnieszka',   '00-075 Warszawa, ul. Krakowskie Przedmieście',   ''),
        ( 'Wojciechowski', 'Jakub',       '',                                               ''),
        ( '',              'Marcin',      '',                                               ''),
        ( '',              'Karolina',    '',                                               ''),
        ( 'Piotrowska',    'Justyna',     '00-506 Warszawa, ul. Hoża',                      ''),
        ( '',              'Agata',       '',                                               ''),
        ( 'Adamczyk',      'Julia',       '00-506 Warszawa, ul. Chmielna',                  ''),
        ( '',              'Przemysław',  '',                                               ''),
        ( '',              'Weronika',    '',                                               ''),
        ( 'Nowak',         '',            '',                                               ''),
        ( '',              'Rafał',       '',                                               ''),
        ( 'Jasiński',      'Szymon',      '00-807 Warszawa, ul. Aleje Jerozolimskie',       ''),
        ( '',              'Tomasz',      '',                                               ''),
        ( 'Sikora',        '',            '',                                               ''),
        ( 'Zając',         'Kinga',       '',                                               ''),
        ( '',              'Michał',      '',                                               ''),
        ( '',              'Marek',       '',                                               ''),
        ( 'Kowalczyk',     'Karolina',    '00-580 Warszawa, ul. Złota',                     ''),
        ( '',              'Przemysław',  '',                                               ''),
        ( '',              'Wiktoria',    '',                                               ''),
        ( 'Szymański',     'Damian',      '00-546 Warszawa, ul. Foksal',                    ''),
        ( 'Kaczmarek',     'Karolina',    '00-555 Warszawa, ul. Kredytowa',                 ''),
        ( '',              'Kamil',       '',                                               ''),
        ( '',              'Bartosz',     '',                                               ''),
        ( 'Lewandowska',   'Aleksandra',  '00-688 Warszawa, ul. Mickiewicza',               '');

    -- Wprowadzenie klientów do tabeli Klient, ...
    INSERT INTO ng.Klient ( OsobaID)
    VALUES
        (  1),
        (  2),
        (  3),
        (  4),
        (  5),
        (  6),
        (  7),
        (  8),
        (  9),
        ( 10),
        ( 11),
        ( 12),
        ( 13),
        ( 14),
        ( 15),
        ( 16),
        ( 17),
        ( 18),
        ( 19),
        ( 20),
        ( 21),
        ( 22),
        ( 23),
        ( 24),
        ( 25),
        ( 26),
        ( 27),
        ( 28),
        ( 29),
        ( 30);

    -- Wprowadzenie posilkow do tabeli Posilek, ...
    INSERT INTO ng.Posilek ( KlientID, DataZamowienia)
    VALUES
        (  1, '2022.07.27 16:32'),
        (  2, '2022.07.27 17:55'),
        (  3, '2022.08.27 18:27'),
        (  4, '2022.08.27 19:13'),
        (  2, '2022.08.27 19:51'),
        (  5, '2022.10.07 19:02'),
        (  6, '2022.10.21 21:19'),
        (  7, '2022.10.30 17:36'),
        (  5, '2022.11.11 17:22'),
        (  8, '2022.11.18 21:24'),
        (  9, '2022.12.05 16:15'),  -- ^^ pierwszych 9 klientów nie odwiedza restauracji od ponad roku
        ( 10, '2022.12.27 16:10'),  -- klient 10. również zawitał przeszło rok temu po raz pierwszy, ale nie dawno zjawił się raz jeszcze
        (  4, '2023.01.29 19:07'),  -- klient  4. długo nie ponawia wizyty, ale trzymamy jego historię, gdyż nie minął jeszcze rok
        ( 11, '2023.02.04 18:56'),
        ( 12, '2023.02.04 21:47'),
        ( 13, '2023.03.08 19:01'),
        ( 14, '2023.03.14 20:15'),
        ( 15, '2023.03.17 16:57'),
        ( 16, '2023.03.26 16:51'),
        ( 17, '2023.04.06 19:35'),
        ( 12, '2023.05.30 18:34'),
        ( 18, '2023.06.04 20:26'),
        ( 19, '2023.06.06 17:11'),
        ( 20, '2023.06.10 16:47'),
        ( 12, '2023.07.28 17:48'),
        ( 21, '2023.07.28 17:50'),
        ( 18, '2023.07.31 18:33'),
        ( 14, '2023.07.31 19:54'),
        ( 22, '2023.08.02 17:29'),
        ( 16, '2023.08.08 17:16'),
        ( 23, '2023.09.03 16:02'),
        ( 10, '2023.09.06 21:39'),  -- dawny klient 10. ponowił tu wizytę
        ( 12, '2024.01.22 15:58'),  -- niektórzy, jak np. 12. odwiedzają restaurację wielokrotnie
        ( 24, '2024.01.22 16:07'),
        ( 25, '2024.01.22 16:19'),
        ( 26, '2024.01.22 16:44'),
        ( 27, '2024.01.22 17:09'),
        ( 28, '2024.01.22 17:21'),
        ( 29, '2024.01.22 18:01'),
        ( 30, '2024.01.22 18:14');

    -- Wprowadzenie posilkow do tabeli Posilek, ...
    INSERT INTO ng.Zlecenie ( PotrawaID, Porcje, PosilekID, KucharzID, DataPrzyjecia, DataOdbioru)
    VALUES
        ( 31, 1,   1,  7, '2022.07.27 16:32', '2022.07.27 16:47'), --<--  1
        ( 24, 1,   1,  1, '2022.07.27 16:32', '2022.07.27 17:00'),
        ( 73, 3,   1,  2, '2022.07.27 16:32', '2022.07.27 16:36'),
        ( 19, 2,   2,  1, '2022.07.27 17:55', '2022.07.27 18:37'), --<--  2
        ( 65, 2,   2,  2, '2022.07.27 17:55', '2022.07.27 17:57'),
        ( 12, 3,   3,  9, '2022.08.27 18:27', '2022.08.27 19:00'), --<--  3
        ( 66, 2,   3,  2, '2022.08.27 18:27', '2022.08.27 18:28'),
        ( 20, 3,   4,  1, '2022.08.27 19:13', '2022.08.27 20:13'), --<--  4
        (  8, 2,   4,  2, '2022.08.27 19:13', '2022.08.27 19:29'),
        ( 59, 1,   4,  7, '2022.08.27 19:13', '2022.08.27 19:16'),
        ( 15, 3,   5,  1, '2022.08.27 19:51', '2022.08.27 20:26'), --<--  2
        ( 13, 2,   5,  2, '2022.08.27 19:51', '2022.08.27 20:19'),
        ( 44, 3,   5,  2, '2022.08.27 19:19', '2022.08.27 20:43'), ----------- przydział ze zwłoką
        ( 66, 2,   5,  7, '2022.08.27 19:51', '2022.08.27 19:52'),
        ( 36, 2,   6,  7, '2022.10.07 19:02', '2022.10.07 19:16'), --<--  5
        ( 57, 1,   6,  1, '2022.10.07 19:02', '2022.10.07 19:04'),
        ( 23, 2,   7,  1, '2022.10.21 21:19', '2022.10.21 22:03'), --<--  6
        ( 26, 1,   7,  9, '2022.10.21 21:19', '2022.10.21 21:51'),
        ( 46, 1,   7,  2, '2022.10.21 21:19', '2022.10.21 21:21'),
        (  2, 1,   8,  1, '2022.10.30 17:36', '2022.10.30 17:47'), --<--  7
        ( 67, 3,   9,  1, '2022.11.11 17:22', '2022.11.11 17:24'), --<--  5
        (  7, 1,   9,  2, '2022.11.11 17:22', '2022.11.11 17:28'),
        ( 56, 1,   9,  7, '2022.11.11 17:22', '2022.11.11 17:24'),
        ( 66, 3,  10,  1, '2022.11.18 21:24', '2022.11.18 21:25'), --<--  8
        ( 75, 3,  11,  1, '2022.12.05 16:15', '2022.12.05 16:20'), --<--  9
        ( 17, 1,  11,  7, '2022.12.05 16:15', '2022.12.05 17:13'),
        ( 51, 2,  11,  2, '2022.12.05 16:15', '2022.12.05 16:17'),
        ( 23, 2,  12,  1, '2022.12.27 16:10', '2022.12.27 16:36'), --<-- 10
        ( 47, 1,  12,  2, '2022.12.27 16:10', '2022.12.27 16:13'),
        ( 66, 2,  13,  1, '2023.01.29 19:07', '2023.01.29 19:09'), --<--  4
        ( 62, 3,  14,  1, '2023.02.04 18:56', '2023.02.04 18:58'), --<-- 11
        ( 50, 2,  15,  1, '2023.02.04 21:47', '2023.02.04 21:49'), --<-- 12
        ( 72, 2,  16,  1, '2023.03.08 19:01', '2023.03.08 19:05'), --<-- 13
        ( 19, 3,  16,  2, '2023.03.08 19:01', '2023.03.08 20:00'),
        ( 66, 3,  16,  7, '2023.03.08 19:01', '2023.03.08 19:03'),
        ( 14, 1,  17,  1, '2023.03.14 20:15', '2023.03.14 20:40'), --<-- 14
        ( 68, 1,  17,  2, '2023.03.14 20:15', '2023.03.14 20:16'),
        ( 52, 1,  18,  1, '2023.03.17 16:57', '2023.03.17 16:59'), --<-- 15
        ( 52, 1,  19,  1, '2023.03.26 16:51', '2023.03.26 16:53'), --<-- 16
        ( 75, 3,  20,  1, '2023.04.06 19:35', '2023.04.06 19:40'), --<-- 17
        ( 24, 3,  20,  1, '2023.04.06 19:40', '2023.04.06 20:17'), ----------- przydział ze zwłoką
        ( 18, 2,  20,  2, '2023.04.06 19:35', '2023.04.06 20:25'),
        ( 50, 1,  20,  7, '2023.04.06 19:35', '2023.04.06 19:37'),
        ( 17, 2,  21,  1, '2023.05.30 18:34', '2023.05.30 19:30'), --<-- 12
        ( 11, 1,  21,  9, '2023.05.30 18:34', '2023.05.30 19:04'),
        ( 50, 2,  21,  1, '2023.05.30 18:34', '2023.05.30 18:36'),
        ( 41, 1,  22,  7, '2023.06.04 20:26', '2023.06.04 20:44'), --<-- 18
        ( 47, 2,  22,  1, '2023.06.04 20:26', '2023.06.04 20:28'),
        ( 67, 1,  23,  1, '2023.06.06 17:11', '2023.06.06 17:13'), --<-- 19
        ( 17, 2,  24,  1, '2023.06.10 16:47', '2023.06.10 17:25'), --<-- 20
        ( 74, 1,  24,  2, '2023.06.10 16:47', '2023.06.10 16:53'),
        ( 58, 1,  25,  1, '2023.07.28 17:48', '2023.07.28 17:51'), --<-- 12
        ( 63, 2,  26,  2, '2023.07.28 17:50', '2023.07.28 17:52'), --<-- 21
        (  5, 3,  26,  8, '2023.07.28 17:50', '2023.07.28 18:03'),
        ( 48, 1,  26,  1, '2023.07.28 17:50', '2023.07.28 17:53'),
        ( 20, 3,  27,  1, '2023.07.31 18:33', '2023.07.31 19:25'), --<-- 18
        ( 47, 3,  27,  2, '2023.07.31 18:33', '2023.07.31 18:36'),
        ( 67, 2,  28,  1, '2023.07.31 19:54', '2023.07.31 19:56'), --<-- 14
        ( 50, 3,  29,  1, '2023.08.02 17:29', '2023.08.02 17:32'), --<-- 22
        ( 67, 2,  30,  1, '2023.08.08 17:16', '2023.08.08 17:18'), --<-- 16
        ( 39, 2,  30,  7, '2023.08.08 17:16', '2023.08.08 17:30'),
        ( 47, 3,  30,  2, '2023.08.08 17:16', '2023.08.08 17:19'),
        ( 62, 2,  31,  1, '2023.09.03 16:02', '2023.09.03 16:04'), --<-- 23
        ( 54, 1,  32,  1, '2023.09.06 21:39', '2023.09.06 21:44'), --<-- 10
        ( 11, 3,  33,  9, '2024.01.22 15:58', '2024.01.22 16:28'), --<-- 12
        ( 24, 1,  33,  1, '2024.01.22 15:58', '2024.01.22 16:38'),
        ( 75, 3,  33,  2, '2024.01.22 15:58', '2024.01.22 16:03'),
        ( 49, 1,  34,  2, '2024.01.22 16:07', '2024.01.22 16:09'), --<-- 24
        (  5, 2,  35,  8, '2024.01.22 16:19', '2024.01.22 16:28'), --<-- 25
        ( 38, 2,  35,  7, '2024.01.22 16:19', '2024.01.22 16:28'),
        ( 52, 2,  35,  1, '2024.01.22 16:19', '2024.01.22 16:22'),
        ( 39, 1,  36,  7, '2024.01.22 16:44', '2024.01.22 16:57'), --<-- 26
        (  6, 2,  36,  1, '2024.01.22 16:44', '2024.01.22 16:56'),
        ( 46, 3,  36,  2, '2024.01.22 16:44', '2024.01.22 16:47'),
        ( 10, 3,  37,  9, '2024.01.22 17:09', '2024.01.22 17:23'), --<-- 27
        ( 48, 1,  37,  1, '2024.01.22 17:09', '2024.01.22 17:11'),
        ( 50, 1,  38,  1, '2024.01.22 17:21', '2024.01.22 17:24'), --<-- 28
        ( 65, 2,  39,  1, '2024.01.22 18:01', '2024.01.22 18:02'), --<-- 29
        ( 22, 2,  40,  1, '2024.01.22 18:14', '2024.01.22 19:11'), --<-- 30
        ( 56, 3,  40,  2, '2024.01.22 18:14', '2024.01.22 18:16');
END;



-- ******************************* WIDOKI ********************************** --



-------------------------------------------------------------------------------
-- Spis wszystkich wprowadzonych potraw
-------------------------------------------------------------------------------

CREATE VIEW ng.SpisPotraw AS
SELECT
    R.Nazwa AS Rodzaj,
    P.Nazwa AS Potrawa,
    P.Cena  AS Cena,
    K.Nazwa AS Kategoria
FROM ng.Potrawa AS P
INNER JOIN ng.Kategoria AS K
    ON P.KategoriaID = K.KategoriaID
INNER JOIN ng.Rodzaj AS R
    ON P.RodzajID = R.RodzajID;


-------------------------------------------------------------------------------
-- Wykaz wszystkich wprowadzonych potraw, rozszerzony o listy skladników
-------------------------------------------------------------------------------

CREATE VIEW ng.ListySkladnikow AS
SELECT
    P.Nazwa AS Potrawa,
    STRING_AGG(S.Nazwa, ', ') AS Skladniki,
    COUNT(S.SkladnikID) AS Ilosc
FROM ng.Potrawa AS P
INNER JOIN ng.Sklad AS A
    ON P.PotrawaID = A.PotrawaID
INNER JOIN ng.Skladnik AS S
    ON A.SkladnikID = S.SkladnikID
GROUP BY
    P.Nazwa;


-------------------------------------------------------------------------------
-- Wykaz wszystkich wprowadzonych potraw, rozszerzony o listy skladników 
-- oraz koszty materiałowe (wyliczają się przez mnożenie CenaJedn * IloscJedn)
-------------------------------------------------------------------------------

CREATE VIEW ng.KosztyMaterialowe AS
SELECT
    P.Nazwa AS Potrawa,
    STRING_AGG(S.Nazwa, ', ') AS Skladniki,
    CAST(SUM(S.CenaJedn * A.IloscJedn) AS DECIMAL(8,2)) AS Koszt
FROM ng.Potrawa AS P
INNER JOIN ng.Sklad AS A
    ON P.PotrawaID = A.PotrawaID
INNER JOIN ng.Skladnik AS S
    ON A.SkladnikID = S.SkladnikID
GROUP BY
    P.Nazwa;


-------------------------------------------------------------------------------
-- Pula potraw serwowanych
-- W zadaniu okreslono, że w grę wchodzą tylko potrawy, dla których restauracja
-- posiada przynajmniej 3 wyspecjalizowanych kucharzy.
-- Uwaga:  Słowo 'posiada' interpretuję tu jako fakt zatrudnienia tych osób,
--         a nie obecności ich wszystkich w pracy. W moim rozwiązaniu istnieje
--         tu pewna różnica, ponieważ kucharzom nadawany jest status. Jeśli to
--         komplikuje analizę - po prostu nadać wszystkim kucharzom status 'P'.
-------------------------------------------------------------------------------

CREATE VIEW ng.SerwowanePotrawyId AS
SELECT
    P.PotrawaID AS PotrawaID
FROM
    ng.Potrawa AS P
INNER JOIN ng.Umiejetnosc AS U
    ON P.PotrawaID = U.PotrawaID
INNER JOIN ng.Kucharz AS K
    ON U.KucharzID = K.KucharzID
GROUP BY
    P.PotrawaID
HAVING
    COUNT(K.KucharzID) >= 3;


-------------------------------------------------------------------------------
-- Pula potraw nieserwowanych
-------------------------------------------------------------------------------

CREATE VIEW ng.NieserwowanePotrawyId AS
SELECT
    PotrawaID
FROM
    ng.Potrawa
WHERE
    PotrawaID NOT IN (
        SELECT * 
        FROM ng.SerwowanePotrawyId
    );


------------------------------------------------------------------------------
-- Pula kucharzy na stanowiskach pracy
-------------------------------------------------------------------------------

CREATE VIEW ng.ObecniKucharzeId AS
SELECT
    KucharzID
FROM
    ng.Kucharz
WHERE
    Status LIKE 'P%';


------------------------------------------------------------------------------
-- Zbiorcza tabela z wykazem kucharzy na stanowiskach pracy, zdolnych wykonać
-- poszczególne potrawy serwowane w restauracji.
-------------------------------------------------------------------------------

CREATE VIEW ng.DoPotrawyKucharzeId AS
SELECT 
    S.PotrawaID,
    U.KucharzID
FROM 
    ng.SerwowanePotrawyId AS S
INNER JOIN 
    ng.Umiejetnosc AS U 
    ON S.PotrawaID = U.PotrawaID
INNER JOIN 
    ng.Kucharz AS K
    ON U.KucharzID = K.KucharzID
WHERE 
    K.Status LIKE 'P%';


------------------------------------------------------------------------------
-- Pula klientow, którzy nie odwiedzili restaurcji od ponad roku
-------------------------------------------------------------------------------

CREATE VIEW ng.DawniKlienciId AS
SELECT
    KlientID
FROM
    ng.Klient
WHERE 
    KlientID NOT IN (
        SELECT P.KlientID
        FROM ng.Posilek AS P
        WHERE P.DataZamowienia >= DATEADD(YEAR, -1, GETDATE())
    );
    -- Uwaga: Rozpatrujemy zbiór klientów, którzy nie występują w zamówieniach
    --        na przestrzeni ostatniego roku. To nie to samo co zbiór klientów,
    --        którzy wystąpili w zamówieniach sprzed roku!!!
    --        Nie chcemy przecież usunąć tych, którzy byli kiedyś i są nadal.


------------------------------------------------------------------------------
-- Ranking kucharzy w oparciu o liczbę skarg złożonych na wykonane przez nich
-- potrawy.
-------------------------------------------------------------------------------

CREATE VIEW ng.RankingKucharzy AS
SELECT 
    R.PotrawaID,
    R.KucharzID,
    ROW_NUMBER() OVER (PARTITION BY R.PotrawaID ORDER BY R.IloscSkarg DESC) AS Ranking
FROM (
    SELECT
        Z.PotrawaID,
        Z.KucharzID,
        COUNT(CASE WHEN Z.SkargaID IS NOT NULL THEN 1 END) AS IloscSkarg
    FROM
        ng.Zlecenie AS Z
    GROUP BY
        Z.PotrawaID, Z.KucharzID
) AS R;



-- *****************************  PROCEDURY ******************************** --


-------------------------------------------------------------------------------
-- Procedura dopisująca kucharza z jego listą specjalizacji
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.DodajKucharza
    @Nazwisko NVARCHAR(40),
    @Imie NVARCHAR(40),
    @Adres NVARCHAR(80),
    @Telefon NCHAR(16),
    @DataZatrudnienia DATE,
    @ListaPotrawCSV NVARCHAR(240)  -- rozdzielana przecinkami lista kluczy potraw
AS
BEGIN
    -- Dopisanie danych osobowych kucharza
    DECLARE @OsobaID INT;
    INSERT INTO ng.OsobaKucharz (Nazwisko, Imie, Adres, Telefon, DataZatrudnienia)
    VALUES (@Nazwisko,
            @Imie,
            @Adres,
            @Telefon,
            @DataZatrudnienia
    );
    SET @OsobaID = SCOPE_IDENTITY();

    -- Utworzenie encji kucharza ze statusem "pracuje"
    INSERT INTO ng.Kucharz (OsobaID, Status)
    VALUES (@OsobaID, 'P');

    -- Przetworzenie określonej przez kucharza listy potraw,
    -- i dodanie ich do tabeli umiejętności
    INSERT INTO ng.Umiejetnosc (KucharzID, PotrawaID)
    SELECT @OsobaID, CAST(VALUE AS INT)
    FROM STRING_SPLIT(@ListaPotrawCSV, ',');

    PRINT 'Kucharz dopisany.';
END;


-------------------------------------------------------------------------------
-- Procedura usuwająca dane osobowe i specjalizacje kucharza o podanym ID.
-- Uwaga: Encja Kucharz pozostaje - celowo!
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.UsunKucharza @KucharzID INT
AS
BEGIN
    -- Sprawdzenie, czy kucharz istnieje
    IF NOT EXISTS (SELECT 1 FROM ng.Kucharz WHERE KucharzID = @KucharzID)
    BEGIN
        PRINT 'Pracownik o podanym identyfikatorze nie istnieje.';
        RETURN;
    END
    -- Usunięcie kucharza z tablicy umiejętności
    DELETE FROM ng.Umiejetnosc
    WHERE KucharzID = @KucharzID;

    -- Rozerwanie powiązań encji kucharza z przeznaczonym do usunięcia rekordem
    -- w tabeli danych osobowych
    UPDATE ng.Kucharz 
    SET OsobaID = NULL
    WHERE KucharzID = @KucharzID;

    -- Usunięcie danych osobowych zwolnionego kucharza
    DELETE FROM ng.OsobaKucharz
    WHERE OsobaID = @KucharzID;

    PRINT 'Kucharz usunięty.';
END;


-------------------------------------------------------------------------------
-- Procedura dopisująca klienta
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.DodajKlienta
    @Nazwisko NVARCHAR(40),
    @Imie NVARCHAR(40),
    @Adres NVARCHAR(80),
    @Telefon NCHAR(16)
AS
BEGIN
    -- Dopisanie danych osobowych klienta
    DECLARE @OsobaID INT;
    INSERT INTO ng.OsobaKlient (Nazwisko, Imie, Adres, Telefon)
    VALUES (@Nazwisko,
            @Imie,
            @Adres,
            @Telefon
    );
    SET @OsobaID = SCOPE_IDENTITY();

    -- Utworzenie encji klienta
    INSERT INTO ng.Klient (OsobaID)
    VALUES (@OsobaID);

    PRINT 'Klient dopisany.';
END;


-------------------------------------------------------------------------------
-- Procedura dopisująca klienta anonimowego (bez danych osobowych)
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.DodajKlientaIncognito
AS
BEGIN
    -- Utworzenie encji klienta bez danych osobowych
    INSERT INTO ng.Klient (OsobaID)
    VALUES (NULL);
END;


-------------------------------------------------------------------------------
-- Procedura usuwająca dane osobowe klientów, którzy nie zjawili się od roku
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.UsunDawnychKlientow
AS
BEGIN
    -- Usunięcie danych osobowych klientów, którzy nie składali zamówienia
    -- od ponad roku
    DELETE FROM ng.OsobaKlient
    WHERE OsobaID IN (
        SELECT K.OsobaID
        FROM ng.DawniKlienciId AS D
        INNER JOIN ng.Klient AS K
        ON D.KlientID = K.KlientID
    )
    -- ... i wyzerowanie kluczy w encjach klientów, dla których dane osobowe
    -- zostały usunięte
    UPDATE ng.Klient
    SET OsobaID = NULL
    WHERE OsobaID IN (
        SELECT *
        FROM ng.DawniKlienciId 
    )

    PRINT 'Usunięto nieaktywnych klientów.';
END;


-------------------------------------------------------------------------------
-- Procedura dopisująca nowootwarty posiłek.
-- Posiłek to encja, która w świecie realnym ma odpowiednik 'kwitu z numerkiem'
-- łączy on zamówione przez klienta potrawy w jedno.  To, jakie zamówił potrawy
-- w ramach posiłku, wprowadzane jest w kolejnym kroku, tzn.odrębną procedurą.
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.DodajPosilek
    @KlientID INT,
    @DataZamowienia DATETIME
AS
BEGIN
    -- Dopisanie nowego posilku
    DECLARE @PosilekID INT;
    INSERT INTO ng.Posilek (KlientID, DataZamowienia)
    VALUES (@KlientID,
            @DataZamowienia
    );
    SET @PosilekID = SCOPE_IDENTITY();

    PRINT 'Zarejestrowano posilek:  ' + CAST(@PosilekID AS NVARCHAR(10));
END;


-------------------------------------------------------------------------------
-- Procedura dopisująca zlecenie na przyrządzenie konkretnej potrawy.
-- Wstępnie nie jest wiadome jeszcze jaki kucharz je zrealizuje.
-- Takimi sprawami zawiaduje 'szef kuchni', czyli ... odrębna procedura :P
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.OtworzZlecenie
    @PosilekID INT,
    @PotrawaID INT,
    @Porcje INT
AS
BEGIN
    -- Dopisanie nowego zlecenia
    INSERT INTO ng.Zlecenie (PosilekID, PotrawaID, Porcje)
    VALUES (@PosilekID, 
            @PotrawaID,
            @Porcje
    );
    PRINT 'Zlecenie otwarte.';
END;



-------------------------------------------------------------------------------
-- Procedura wyboru kucharza wyspecjalizowanego w przygotowaniu danej potrawy
-- i najlepszego w rankingu dla danej potrawy, z preferencją kucharza najmniej
-- obłożonego robotą.
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.SzefWybiera
    @ZlecenieID INT,
    @WybraniecID INT OUTPUT
AS
BEGIN
    -- 1. Wybieram pulę najlepszych kucharzy do potrawy w zleceniu
    DECLARE @DoPotrawyNajlepsi TABLE (
        KucharzID INT,
        Ranking INT
    );
    INSERT INTO @DoPotrawyNajlepsi
    SELECT 
        DK.KucharzID AS KucharzID,
        COALESCE(RK.Ranking, 0) AS Ranking
    FROM ng.DoPotrawyKucharzeId AS DK
    LEFT OUTER JOIN ng.RankingKucharzy AS RK 
        ON DK.PotrawaID = RK.PotrawaID 
       AND DK.KucharzID = RK.KucharzID
    WHERE DK.PotrawaID = (
        SELECT Z.PotrawaID 
        FROM ng.Zlecenie AS Z
        WHERE Z.ZlecenieID = @ZlecenieID
    );
    -- 2. Eliminuję z puli kucharzy ze statusem 'P9' (tzn. wykonujących
    --    posiłek pracochłonny)
    DECLARE @DoPotrawyDostepni TABLE (
        KucharzID INT,
        Ranking INT
    );
    INSERT INTO @DoPotrawyDostepni
    SELECT
        NK.KucharzID AS KucharzID,
        NK.Ranking AS Ranking
    FROM @DoPotrawyNajlepsi AS NK
    INNER JOIN ng.Kucharz AS K
        ON NK.KucharzID = K.KucharzID
    WHERE
        K.Status <> 'P9'
    ORDER BY 
        K.Status ASC,  --<-- preferuję kucharzy najmniej obciążonych robotą
        NK.Ranking ASC; --<-- a wśród nich wybieram tego, kto działa najlepiej

    -- 3. Zwracam ID wybranego kucharza
    SELECT TOP 1 @WybraniecID = KucharzID
    FROM @DoPotrawyDostepni;
END;


-------------------------------------------------------------------------------
-- Procedura przydziału podanego zlecenia. W encji Zlecenie wpisywana jest data
-- przydziału, a w encji Kucharz związanej z tym zleceniem inkrementowany jest
-- status (pełni on funkcję licznika obciążenia pracą).
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.SzefPrzydziela
    @ZlecenieID INT,
    @KucharzID INT,
    @DataPrzyjecia DATETIME
AS
BEGIN
    -- Zapisanie przydzielonego kucharza oraz daty przyjęcia zlecenia w encji
    UPDATE ng.Zlecenie 
    SET
        DataPrzyjecia = @DataPrzyjecia,
        KucharzID = @KucharzID
    WHERE
        ZlecenieID = @ZlecenieID;

    -- Inkrementacja licznika zadań kucharza, w tym ...
    -- ... a) ustalenie kategorii potrawy do wykonania
    DECLARE @Kategoria INT;
    SELECT @Kategoria = P.KategoriaID
    FROM ng.Zlecenie AS Z
    INNER JOIN ng.Potrawa AS P
        ON Z.PotrawaID = P.PotrawaID
    WHERE Z.ZlecenieID = @ZlecenieID;

    -- ... b) pobranie bieżącego statusu kucharza,
    DECLARE @Status CHAR(2);
    SELECT @Status = K.Status
    FROM ng.Kucharz AS K
    INNER JOIN ng.Zlecenie AS Z
        ON K.KucharzID = Z.KucharzID
    WHERE Z.ZlecenieID = @ZlecenieID;

    -- ... c) inkrementacja statusu, tzn.: ...
    IF @Kategoria = 2 
        -- ... kucharz zajmie się zadaniem z kategorii pracochłonnej
        --  więc od razu ustawiamy 'P9'
        SET @Status = 'P9';
    ELSE
        -- ... kucharz dostał zadanie w kategorii szybkiej
        -- tu badamy czy inkrementować ...
        IF LEN(@Status) = 2
        BEGIN
            DECLARE @Counter INT;
            SET @Counter = CAST(SUBSTRING(@Status, 2, 1) AS INT);
            IF @Counter < 9
            BEGIN
                SET @Counter = @Counter + 1;
                SET @Status = 'P' + CAST(@Counter AS CHAR(1));
            END
        END
        ELSE
            -- czy ustawić 'P1' (bo status wynosił 'P')
            SET @Status = 'P1'; 

    -- ... d) zapisanie statusu w encji kucharza
    UPDATE ng.Kucharz
    SET Status = @Status
    WHERE KucharzID = (
        SELECT KucharzID
        FROM ng.Zlecenie AS Z 
        WHERE Z.ZlecenieID = @ZlecenieID
    );

    PRINT 'Przydzielono zlecenie.';
END;


-------------------------------------------------------------------------------
-- Procedura odbioru podanego zlecenia. W encji Zlecenie wpisywana jest data
-- odbioru, a w encji Kucharz związanej z tym zleceniem dekrementowany jest
-- status (pełni on funkcję licznika obciążenia pracą).
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.SzefOdbiera
    @ZlecenieID INT,
    @DataOdbioru DATETIME
AS
BEGIN
    -- Wpisanie daty odbioru wykonanego zlecenia
    UPDATE ng.Zlecenie
    SET
        DataOdbioru = @DataOdbioru
    WHERE
        ZlecenieID = @ZlecenieID;

    -- Dekrementacja licznika zadań kucharza, w tym ...
    -- ... a) ustalenie kategorii wykonanej potrawy
    DECLARE @Kategoria INT;
    SELECT @Kategoria = P.KategoriaID
    FROM ng.Zlecenie AS Z
    INNER JOIN ng.Potrawa AS P
        ON Z.PotrawaID = P.PotrawaID
    WHERE Z.ZlecenieID = @ZlecenieID;

    -- ... b) pobranie bieżącego statusu kucharza,
    DECLARE @Status CHAR(2);
    SELECT @Status = K.Status
    FROM ng.Kucharz AS K
    INNER JOIN ng.Zlecenie AS Z
        ON K.KucharzID = Z.KucharzID
    WHERE Z.ZlecenieID = @ZlecenieID;

    -- ... c) dekrementacja statusu, tzn.: ...
    IF @Kategoria = 2 
        -- ... kucharz zakończył zadanie z kategorii pracochłonnej
        -- więc od razu ustawiamy 'P'
        SET @Status = 'P';
    ELSE
    BEGIN
        -- ... kucharz zakończył zadanie z kategorii szybkiej
        -- tu badamy czy dekrementować, ...
        DECLARE @Counter INT;
        SET @Counter = CAST(SUBSTRING(@Status, 2, 1) AS INT);
        IF @Counter > 1
        BEGIN
            SET @Counter = @Counter - 1;
            SET @Status = 'P' + CAST(@Counter AS CHAR(1));
        END
        ELSE
        -- ... czy od razu ustawić 'P' (bo status wynosił 'P1')
            SET @Status = 'P';
    END;

    -- ... d) zapisanie statusu w encji kucharza
    UPDATE ng.Kucharz
    SET Status = @Status
    WHERE KucharzID = (
        SELECT KucharzID
        FROM ng.Zlecenie AS Z 
        WHERE Z.ZlecenieID = @ZlecenieID
    );

    PRINT 'Odebrano zlecenie.';
END;


-------------------------------------------------------------------------------
-- Procedura listująca zamówione przez klienta potrawy i podliczająca
-- należność za posiłek.
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.PodliczPosilek
    @PosilekID INT
AS
BEGIN
    SELECT
        P.Nazwa AS Potrawa,
        Z.Porcje AS Porcje,
        P.Cena AS Cena,
        Z.Porcje * P.Cena AS Naleznosc
    FROM ng.Zlecenie AS Z
    INNER JOIN ng.Potrawa AS P 
        ON Z.PotrawaID = P.PotrawaID
    WHERE
        Z.PosilekID = @PosilekID;
END;


-------------------------------------------------------------------------------
-- Procedura rejestrująca skargę podanego klienta na określoną potrawę
-- w podanym posiłku. 
-- Traktujemy, że PosilekID to znany klientowi 'numerek', na który może on
-- się powołać wnosząc skargę, a felerną potrawę to oczywiście pamięta ;)
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.DodajSkarge
    @KlientID INT,
    @PosilekID INT,
    @PotrawaID INT,
    @Opis NVARCHAR(240)
AS
BEGIN
    -- Wyszukanie odpowiedniego zlecenia (zlecenia to encje w obiegu wewnętrznym 
    -- restauracji, nieznane klientowi) związanego z podanym klientem, posiłkiem
    -- (tj. numerkiem) i potrawą
    --
    DECLARE @ZlecenieID INT;
    SELECT @ZlecenieID = Z.ZlecenieID
    FROM ng.Zlecenie AS Z
        INNER JOIN ng.Posilek AS P ON Z.PosilekID = P.PosilekID
        INNER JOIN ng.Potrawa AS R ON Z.PotrawaID = R.PotrawaID
    WHERE 
        P.KlientID = @KlientID
    AND P.PosilekID = @PosilekID
    AND R.PotrawaID = @PotrawaID;

    -- Dopisanie skargi
    DECLARE @SkargaID INT;
    INSERT INTO ng.Skarga (KlientID, Opis)
    VALUES (@KlientID,
            @Opis
    );
    SET @SkargaID = SCOPE_IDENTITY();

    -- Zbudowanie powiązania Skarga <-> Zlecenie
    UPDATE ng.Zlecenie
    SET SkargaID = @SkargaID
    WHERE ZlecenieID = @ZlecenieID;

    PRINT 'Skarga dopisana.';
END;


-------------------------------------------------------------------------------
-- Procedura tworzy zestawienie posilkow zrealizowanych wadliwie - tzn. albo
-- klient zlozyl skargę na którąś z potraw, albo/oraz któraś potrawa została
-- przyrządzona z przekroczeniem LimitCzasu przyznanego dla potraw w danej
-- kategorii.
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.RetrospekcjaPosilkow
    @OdDaty DATETIME,
    @DoDaty DATETIME
AS
BEGIN
    SELECT 
        COALESCE(TSk.PosilekID, TPc.PosilekID) AS PosilekID,
        TSk.KucharzZeSkarga AS ZeSkargaKucharzID,
        TPc.KucharzPoCzasie AS PoCzasieKucharzID
    FROM (
        -- Zliczenie posiłków z powodu skargi 
        -- zlozonej na którąś z potraw
        SELECT
            P.PosilekID AS PosilekID,
            Z.KucharzID AS KucharzZeSkarga
        FROM ng.Posilek AS P
        INNER JOIN ng.Zlecenie AS Z
            ON P.PosilekID = Z.PosilekID
        WHERE
            P.DataZamowienia BETWEEN @OdDaty AND @DoDaty
        AND Z.SkargaID IS NOT NULL
    ) AS TSk
    FULL OUTER JOIN (
        -- Zliczenie posiłków z powodu przekroczenia czasu 
        -- przygotowania którejś z potraw
        SELECT
            P.PosilekID AS PosilekID,
            Z.KucharzID AS KucharzPoCzasie
        FROM ng.Posilek AS P
        INNER JOIN ng.Zlecenie AS Z
            ON P.PosilekID = Z.PosilekID
        INNER JOIN ng.Potrawa AS R
            ON Z.PotrawaID = R.PotrawaID
        INNER JOIN ng.Kategoria AS K
            ON R.KategoriaID = K.KategoriaID
        WHERE
            P.DataZamowienia BETWEEN @OdDaty AND @DoDaty
        AND DATEDIFF(MINUTE, Z.DataPrzyjecia, Z.DataOdbioru) > K.LimitCzasu
    ) AS TPc
    ON TSk.PosilekID = TPc.PosilekID;
END;



--- #### -- -- #### -- -- #### -- SPRAWDZONKO -- #### -- -- #### -- -- #### ---


CREATE PROCEDURE ng._Epizod1 AS
BEGIN
    -- Wstawiamy przykladowe dane
    EXEC ng.WstawDane;

    -- Sprawdźmy, jaki zespół mamy na pokładzie
    SELECT * FROM ng.OsobaKucharz;
END

-------------------------------------------------------------------------------

CREATE PROCEDURE ng._Epizod2 AS
BEGIN
    -- Przyjmijmy nową osobę do pracy
    EXEC ng.DodajKucharza 
        @Nazwisko = 'Obibok',
        @Imie = 'Jan',
        @Adres = 'Tarczyn, ul. Kuchenna 5',
        @Telefon = '22 345-67-89',
        @DataZatrudnienia = '2024-01-25',
        @ListaPotrawCSV = '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17';

    -- Sprawdźmy czy Pan Obibok pojawił się w wykazie
    SELECT * FROM ng.OsobaKucharz;
END

-------------------------------------------------------------------------------

CREATE PROCEDURE ng._Epizod3 AS
BEGIN
    -- Szef postanowił go jednak od razu zwolnić - w pierwszym dniu już podpadł
    DECLARE @KucharzID INT;

    SELECT @KucharzID = OsobaID 
    FROM ng.OsobaKucharz AS K
    WHERE
        K.Nazwisko = 'Obibok'
    AND K.Imie = 'Jan' ;

    EXEC ng.UsunKucharza @KucharzID;

    -- Sprawdźmy czy pechowy pracownik zniknął z rejestru
    SELECT * FROM ng.OsobaKucharz;
END

-------------------------------------------------------------------------------

CREATE PROCEDURE ng._Epizod4 AS
BEGIN
    -- Zjawia się klient, więc szybko trzeba dopisać go do naszej bazy
    EXEC ng.DodajKlienta 
        @Nazwisko = 'Niejadek',
        @Imie = 'Tadeusz',
        @Adres = '',
        @Telefon = '48 234-56-78';

    -- Sprawdźmy czy Tadek Niejadek zakotwiczył prawidłowo w rejestrze ;)
    SELECT * FROM ng.OsobaKlient;
END

-------------------------------------------------------------------------------

CREATE PROCEDURE ng._Epizod5 AS
BEGIN
    -- Po długim namyśle ...
    DECLARE @Teraz DATETIME = GETDATE();
    -- ... klient ...
    DECLARE @KlientID INT;
    SET @KlientID = (SELECT TOP 1 KlientID FROM ng.Klient ORDER BY KlientID DESC);
    -- ... złożył zamówienie ...
    EXEC ng.DodajPosilek
        @KlientID,
        @DataZamowienia = @Teraz;
    -- ... z numerkiem PosilekID ...
    DECLARE @PosilekID INT;
    SET @PosilekID = (SELECT TOP 1 PosilekID FROM ng.Posilek ORDER BY PosilekID DESC);

    DECLARE @Wybral INT;
    -- ... wybrał danie główne ...
    SELECT @Wybral = P.PotrawaID FROM ng.Potrawa AS P 
    WHERE P.Nazwa = 'Sznycel cielecy';
    EXEC ng.OtworzZlecenie
        @PosilekID, 
        @PotrawaID = @Wybral,
        @Porcje = 1;
    -- ... oraz deser ...
    SELECT @Wybral = P.PotrawaID FROM ng.Potrawa AS P 
    WHERE P.Nazwa = 'Lava cake';
    EXEC ng.OtworzZlecenie 
        @PosilekID, 
        @PotrawaID = @Wybral,
        @Porcje = 1;

    -- Zobaczmy czy zamówienie 'weszło w system', tzn.:
    -- ... z jaką datą i jaki 'numerek' został mu przydzielony (ID posiłku),
    SELECT * FROM ng.Posilek;
    -- ... oraz czy wszystkie potrawy są zarejestrowane wg życzenia klienta
    SELECT * FROM ng.Zlecenie;
END

-------------------------------------------------------------------------------

CREATE PROCEDURE ng._Epizod6 AS
BEGIN
    -- Teraz wkracza szef kuchni i niezwłocznie typuje kucharza do roboty!
    DECLARE @Teraz DATETIME = GETDATE();

    -- Stara się robić to inteligentnie i sprawiedliwie - tzn. wybiera kucharza, 
    -- który ma najmniej wpadek, no chyba, że jest spore obłożenie robotą w firmie
    -- to wtedy preferuje najmniej obciążonych, a wśród nich szuka tego najlepszego.

    DECLARE @Zlecenie1ID INT;
    SET @Zlecenie1ID = (SELECT TOP 1 ZlecenieID FROM ng.Zlecenie ORDER BY ZlecenieID DESC) -1;
    DECLARE @WybraniecID INT = NULL;
    EXEC ng.SzefWybiera
        @Zlecenie1ID,
        @WybraniecID = @WybraniecID OUTPUT;
    IF @WybraniecID IS NOT NULL
    BEGIN
        EXEC ng.SzefPrzydziela 
            @Zlecenie1ID, 
            @WybraniecID, 
            @Teraz
    END

    DECLARE @Zlecenie2ID INT;
    SET @Zlecenie2ID = (SELECT TOP 1 ZlecenieID FROM ng.Zlecenie ORDER BY ZlecenieID DESC);
    EXEC ng.SzefWybiera
        @Zlecenie2ID,
        @WybraniecID = @WybraniecID OUTPUT;
    IF @WybraniecID IS NOT NULL
    BEGIN
        EXEC ng.SzefPrzydziela 
            @Zlecenie2ID, 
            @WybraniecID, 
            @Teraz
    END
    
    -- Zobaczmy jakim specjalistom powierzono zlecenia:
    SELECT * FROM ng.Zlecenie;
END


-------------------------------------------------------------------------------

CREATE PROCEDURE ng._Epizod7 AS
BEGIN
    -- Zespół stanął na wysokości zadania - szef odebrał: ...
    DECLARE @Teraz DATETIME = GETDATE();

    -- ... posiłek 'pracochłonny' ...
    DECLARE @ZaPewienCzas1 DATETIME;
    DECLARE @Zlecenie1ID INT;
    SET @ZaPewienCzas1 = DATEADD(MINUTE, ROUND(RAND() * (35 -20) +20, 0), @Teraz)
    SET @Zlecenie1ID = (SELECT TOP 1 ZlecenieID FROM ng.Zlecenie ORDER BY ZlecenieID DESC) -1;
    EXEC ng.SzefOdbiera
        @Zlecenie1ID,
        @ZaPewienCzas1

    -- ... posiłek 'szybki' ...
    DECLARE @ZaPewienCzas2 DATETIME;
    DECLARE @Zlecenie2ID INT;
    SET @ZaPewienCzas2 = DATEADD(MINUTE, ROUND(RAND() * (17 -12) +12, 0), @Teraz)
    SET @Zlecenie2ID = (SELECT TOP 1 ZlecenieID FROM ng.Zlecenie ORDER BY ZlecenieID DESC);
    EXEC ng.SzefOdbiera
        @Zlecenie2ID,
        @ZaPewienCzas2
        
    -- Ciekawe jakie mieli czasy wykonania zlecen!?:
    SELECT * FROM ng.Zlecenie;
END


-------------------------------------------------------------------------------

CREATE PROCEDURE ng._Epizod8 AS
BEGIN
    -- No ale niestety,
    -- ... klient ...
    DECLARE @KlientID INT;
    SET @KlientID = (SELECT TOP 1 KlientID FROM ng.Klient ORDER BY KlientID DESC);
    -- ... nie dość, że nie dojadł posiłku ...
    DECLARE @PosilekID INT;
    SET @PosilekID = (SELECT TOP 1 PosilekID FROM ng.Posilek ORDER BY PosilekID DESC);
    -- ... to jeszcze złożył skargę ...
    EXEC ng.DodajSkarge 
        @KlientID = @KlientID,
        @PosilekID = @PosilekID,
        @PotrawaID = 45, -- ... na Lava cake
        @Opis = 'Ciastko za słodkie!';
        
    -- Obejrzyjmy o co mu chodzi i komu się za to oberwało!
    DECLARE @SkargaID INT;
    SET @SkargaID = (SELECT TOP 1 SkargaID FROM ng.Skarga ORDER BY SkargaID DESC);
    SELECT
        S.KlientID AS KlientID,
        S.Opis AS Skarga,
        Z.KucharzID AS Winowajca
    FROM
        ng.Zlecenie AS Z
    JOIN ng.Skarga AS S 
        ON Z.SkargaID = S.SkargaID;
END


--- #### -- -- #### -- -- #### -- K O N I E C -- #### -- -- #### -- -- #### ---




-------------------------------------------------------------------------------
-- Procedura usuwająca wszystkie dane i struktury z bazy danych
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.ZniszczStruktury AS
BEGIN
    DROP TABLE ng.Sklad;
    DROP TABLE ng.Skladnik;

    DROP TABLE ng.Ranking;
    DROP TABLE ng.Umiejetnosc;

    DROP TABLE ng.Zlecenie;
    DROP TABLE ng.Posilek;
    DROP TABLE ng.Skarga;

    DROP TABLE ng.Klient;
    DROP TABLE ng.OsobaKlient;

    DROP TABLE ng.Potrawa;
    DROP TABLE ng.Rodzaj;
    DROP TABLE ng.Kategoria;

    DROP TABLE ng.Kucharz;
    DROP TABLE ng.OsobaKucharz;
END


-------------------------------------------------------------------------------
-- Procedura usuwająca wszystkie widoki
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.ZniszczWidoki AS
BEGIN
    DROP VIEW ng.SpisPotraw;
    DROP VIEW ng.ListySkladnikow;
    DROP VIEW ng.KosztyMaterialowe;
    DROP VIEW ng.SerwowanePotrawyId;
    DROP VIEW ng.NieserwowanePotrawyId;
    DROP VIEW ng.ObecniKucharzeId;
    DROP VIEW ng.DoPotrawyKucharzeId;
    DROP VIEW ng.DawniKlienciId;
    DROP VIEW ng.RankingKucharzy;
END


-------------------------------------------------------------------------------
-- Procedura usuwająca wszystkie procedury
-------------------------------------------------------------------------------

CREATE PROCEDURE ng.ZniszczProcedury AS
BEGIN
    DROP PROCEDURE ng.DodajKucharza;
    DROP PROCEDURE ng.UsunKucharza;
    DROP PROCEDURE ng.DodajKlienta;
    DROP PROCEDURE ng.DodajKlientaIncognito;
    DROP PROCEDURE ng.UsunDawnychKlientow;
    DROP PROCEDURE ng.DodajPosilek;
    DROP PROCEDURE ng.OtworzZlecenie;
    DROP PROCEDURE ng.SzefWybiera;
    DROP PROCEDURE ng.SzefPrzydziela;
    DROP PROCEDURE ng.SzefOdbiera;
    DROP PROCEDURE ng.PodliczPosilek;
    DROP PROCEDURE ng.DodajSkarge;
    DROP PROCEDURE ng.RetrospekcjaPosilkow;

    DROP PROCEDURE ng.PrzygotujStruktury;
    DROP PROCEDURE ng.WstawDane;

    DROP PROCEDURE ng._Epizod1;
    DROP PROCEDURE ng._Epizod2;
    DROP PROCEDURE ng._Epizod3;
    DROP PROCEDURE ng._Epizod4;
    DROP PROCEDURE ng._Epizod5;
    DROP PROCEDURE ng._Epizod6;
    DROP PROCEDURE ng._Epizod7;
    DROP PROCEDURE ng._Epizod8;

    DROP PROCEDURE ng.ZniszczStruktury;
    DROP PROCEDURE ng.ZniszczWidoki;
    DROP PROCEDURE ng.ZniszczProcedury;
END
